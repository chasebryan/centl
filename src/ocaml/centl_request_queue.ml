type queued_input =
  | Line_input of string
  | Oversized_input
  | Queue_overflow_input of string option

type queued_request = {
  input : queued_input;
  bytes : int;
  request_id : Yojson.Safe.t option;
  cancellation : bool Atomic.t;
  emergency_admission : bool;
}

type request_queue = {
  mutex : Mutex.t;
  ready : Condition.t;
  capacity : int;
  max_pending_bytes : int;
  pending : queued_request Queue.t;
  mutable ordinary_pending_count : int;
  mutable pending_bytes : int;
  mutable active : queued_request option;
  mutable emergency_pending : bool;
  mutable emergency_bytes : int;
  mutable waiting : int;
  mutable closed : bool;
  mutable reader_error : exn option;
}

let create ~capacity ~max_pending_bytes =
  {
    mutex = Mutex.create ();
    ready = Condition.create ();
    capacity = max 1 capacity;
    max_pending_bytes = max 1 max_pending_bytes;
    pending = Queue.create ();
    ordinary_pending_count = 0;
    pending_bytes = 0;
    active = None;
    emergency_pending = false;
    emergency_bytes = 0;
    waiting = 0;
    closed = false;
    reader_error = None;
  }

let pending_byte_capacity max_request_bytes =
  let max_request_bytes = max 1 max_request_bytes in
  if max_request_bytes > max_int / 256 then max_int else max_request_bytes * 256

let with_lock (queue : request_queue) action =
  Mutex.lock queue.mutex;
  Fun.protect ~finally:(fun () -> Mutex.unlock queue.mutex) action

let same_request_id left right = left = right

let request_matches target request =
  match request.request_id with
  | Some id -> same_request_id id target
  | None -> false

let cancel request = Atomic.set request.cancellation true
let cancelled request = Atomic.get request.cancellation
let input request = request.input

let add_pending (queue : request_queue) request =
  Queue.add request queue.pending;
  if request.emergency_admission then begin
    queue.emergency_pending <- true;
    queue.emergency_bytes <- request.bytes
  end
  else begin
    queue.ordinary_pending_count <- queue.ordinary_pending_count + 1;
    queue.pending_bytes <- queue.pending_bytes + request.bytes
  end;
  Condition.signal queue.ready

let overflow (queue : request_queue) request =
  Option.iter cancel queue.active;
  Queue.iter cancel queue.pending;
  let line =
    match request.input with
    | Line_input line -> Some line
    | Oversized_input | Queue_overflow_input _ -> None
  in
  Queue.add
    {
      request with
      input = Queue_overflow_input line;
      bytes = 0;
      cancellation = Atomic.make false;
      emergency_admission = false;
    }
    queue.pending;
  queue.closed <- true;
  queue.reader_error <-
    Some (Failure "the pending machine-request queue reached its limit");
  Condition.broadcast queue.ready

let enqueue (queue : request_queue) ?target request =
  with_lock queue (fun () ->
      Option.iter
        (fun target ->
          Option.iter
            (fun active -> if request_matches target active then cancel active)
            queue.active;
          Queue.iter
            (fun pending ->
              if request_matches target pending then cancel pending)
            queue.pending)
        target;
      if queue.closed then false
      else
        (* Classification applies cancellation immediately, so one valid
           cancellation must remain admissible even when ordinary pending
           work has filled the queue.  At most one such request is pending
           outside the normal count/byte budget. *)
        let over_limit =
          queue.ordinary_pending_count >= queue.capacity
          || queue.pending_bytes > queue.max_pending_bytes
          || request.bytes > queue.max_pending_bytes - queue.pending_bytes
        in
        if not over_limit then begin
          add_pending queue request;
          true
        end
        else if Option.is_some target && not queue.emergency_pending then begin
          add_pending queue { request with emergency_admission = true };
          true
        end
        else begin
          overflow queue request;
          false
        end)

let close (queue : request_queue) error =
  with_lock queue (fun () ->
      queue.closed <- true;
      begin match (queue.reader_error, error) with
      | None, Some error -> queue.reader_error <- Some error
      | None, None | Some _, _ -> ()
      end;
      Condition.broadcast queue.ready)

let take (queue : request_queue) =
  with_lock queue (fun () ->
      while Queue.is_empty queue.pending && not queue.closed do
        queue.waiting <- queue.waiting + 1;
        Fun.protect
          ~finally:(fun () -> queue.waiting <- queue.waiting - 1)
          (fun () -> Condition.wait queue.ready queue.mutex)
      done;
      if Queue.is_empty queue.pending then None
      else
        let request = Queue.take queue.pending in
        if request.emergency_admission then begin
          queue.emergency_pending <- false;
          queue.emergency_bytes <- 0
        end
        else
          begin match request.input with
          | Queue_overflow_input _ -> ()
          | Line_input _ | Oversized_input ->
              queue.ordinary_pending_count <- queue.ordinary_pending_count - 1;
              queue.pending_bytes <- queue.pending_bytes - request.bytes
          end;
        queue.active <- Some request;
        Some request)

let complete (queue : request_queue) =
  with_lock queue (fun () -> queue.active <- None)

let cancellation_callback request =
  let checks = ref 0 in
  fun () ->
    incr checks;
    if !checks = 1 || !checks mod 64 = 0 then Thread.yield ();
    cancelled request

let request ~bytes input request_id =
  {
    input;
    bytes = max 0 bytes;
    request_id;
    cancellation = Atomic.make false;
    emergency_admission = false;
  }

let start_reader ~channel ~max_bytes ~classify_id ~classify_cancellation queue =
  Thread.create
    (fun () ->
      let rec loop () =
        match Centl_protocol.read_line channel max_bytes with
        | Centl_protocol.End -> close queue None
        | Centl_protocol.Oversized ->
            if enqueue queue (request ~bytes:max_bytes Oversized_input None)
            then loop ()
        | Centl_protocol.Line line ->
            let json =
              try Some (Yojson.Safe.from_string line)
              with Yojson.Json_error _ -> None
            in
            let request_id = Option.bind json classify_id in
            let target = Option.bind json classify_cancellation in
            if
              enqueue queue ?target
                (request ~bytes:(String.length line) (Line_input line)
                   request_id)
            then loop ()
      in
      try loop () with error -> close queue (Some error))
    ()

let reader_succeeded (queue : request_queue) =
  with_lock queue (fun () -> Option.is_none queue.reader_error)

module For_testing = struct
  type snapshot = {
    pending_count : int;
    ordinary_pending_count : int;
    pending_bytes : int;
    emergency_bytes : int;
    active : queued_request option;
    waiting : int;
    closed : bool;
    reader_error : exn option;
  }

  let snapshot (queue : request_queue) =
    with_lock queue (fun () ->
        {
          pending_count = Queue.length queue.pending;
          ordinary_pending_count = queue.ordinary_pending_count;
          pending_bytes = queue.pending_bytes;
          emergency_bytes = queue.emergency_bytes;
          active = queue.active;
          waiting = queue.waiting;
          closed = queue.closed;
          reader_error = queue.reader_error;
        })

  let request_id request = request.request_id
  let bytes request = request.bytes
  let cancelled = cancelled
  let emergency_admission request = request.emergency_admission
end
