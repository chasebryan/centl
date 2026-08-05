open Centl_request_queue
module Queue_test = Centl_request_queue.For_testing

let check_bool label expected actual =
  Alcotest.(check bool) label expected actual

let check_int label expected actual = Alcotest.(check int) label expected actual

let take_exn queue =
  match take queue with
  | Some request -> request
  | None -> Alcotest.fail "expected a queued request"

let check_line label expected request =
  match Centl_request_queue.input request with
  | Line_input actual -> Alcotest.(check string) label expected actual
  | Oversized_input -> Alcotest.failf "%s: received oversized input" label
  | Queue_overflow_input _ ->
      Alcotest.failf "%s: received the queue-overflow marker" label

let check_id label expected request =
  Alcotest.(check (option string))
    label expected
    (Option.map Yojson.Safe.to_string (Queue_test.request_id request))

let fifo_and_byte_accounting () =
  let queue = create ~capacity:3 ~max_pending_bytes:20 in
  let first = request ~bytes:3 (Line_input "one") (Some (`String "first")) in
  let second = request ~bytes:4 (Line_input "four") (Some (`Int 2)) in
  check_bool "enqueue first" true (enqueue queue first);
  check_bool "enqueue second" true (enqueue queue second);
  let queued = Queue_test.snapshot queue in
  check_int "two pending requests" 2 queued.pending_count;
  check_int "pending byte sum" 7 queued.pending_bytes;
  let first_taken = take_exn queue in
  check_line "FIFO first" "one" first_taken;
  check_id "first id" (Some {|"first"|}) first_taken;
  let after_first = Queue_test.snapshot queue in
  check_int "one request remains" 1 after_first.pending_count;
  check_int "taken bytes leave accounting" 4 after_first.pending_bytes;
  check_bool "active request is recorded" true
    (Option.is_some after_first.active);
  complete queue;
  let second_taken = take_exn queue in
  check_line "FIFO second" "four" second_taken;
  check_id "integer id" (Some "2") second_taken;
  complete queue;
  close queue None;
  check_bool "closed empty queue ends" true (Option.is_none (take queue));
  check_int "large request byte capacity saturates safely" max_int
    (pending_byte_capacity max_int);
  check_int "invalid negative request bytes cannot underflow capacity" 256
    (pending_byte_capacity min_int)

let cancellation_by_string_and_integer_id () =
  let queue = create ~capacity:8 ~max_pending_bytes:1_024 in
  let active = request ~bytes:6 (Line_input "active") (Some (`String "job")) in
  let pending = request ~bytes:7 (Line_input "pending") (Some (`Int 42)) in
  let wide_integer =
    request ~bytes:12 (Line_input "wide-pending")
      (Some (`Intlit "9223372036854775808"))
  in
  check_bool "enqueue active" true (enqueue queue active);
  ignore (take_exn queue);
  check_bool "enqueue pending" true (enqueue queue pending);
  check_bool "enqueue wide integer" true (enqueue queue wide_integer);
  let stop_string =
    request ~bytes:11 (Line_input "stop-string") (Some (`String "stop-1"))
  in
  check_bool "enqueue string cancellation" true
    (enqueue queue ~target:(`String "job") stop_string);
  check_bool "active string id cancelled" true (Queue_test.cancelled active);
  let stop_integer =
    request ~bytes:8 (Line_input "stop-int") (Some (`String "stop-2"))
  in
  check_bool "enqueue integer cancellation" true
    (enqueue queue ~target:(`Int 42) stop_integer);
  check_bool "pending integer id cancelled" true (Queue_test.cancelled pending);
  let stop_wide_integer =
    request ~bytes:12 (Line_input "stop-wide") (Some (`String "stop-3"))
  in
  check_bool "enqueue Intlit cancellation" true
    (enqueue queue ~target:(`Intlit "9223372036854775808") stop_wide_integer);
  check_bool "pending Intlit id cancelled" true
    (Queue_test.cancelled wide_integer);
  check_bool "callback observes cancellation" true
    ((cancellation_callback active) ());
  complete queue;
  close queue None

let cancellation_reserved_admission () =
  let queue = create ~capacity:1 ~max_pending_bytes:3 in
  let target = request ~bytes:3 (Line_input "job") (Some (`String "job")) in
  check_bool "fill normal capacity" true (enqueue queue target);
  let cancellation =
    request ~bytes:64 (Line_input "cancel") (Some (`String "stop"))
  in
  check_bool "cancellation bypasses saturated capacity and bytes" true
    (enqueue queue ~target:(`String "job") cancellation);
  let admitted = Queue_test.snapshot queue in
  check_int "one bounded emergency slot" 2 admitted.pending_count;
  check_int "only ordinary work consumes request capacity" 1
    admitted.ordinary_pending_count;
  check_int "ordinary bytes remain within their budget" 3 admitted.pending_bytes;
  check_int "emergency bytes are accounted separately" 64
    admitted.emergency_bytes;
  check_bool "queue remains open" false admitted.closed;
  check_bool "queued target is cancelled" true (Queue_test.cancelled target);
  ignore (take_exn queue);
  complete queue;
  let stop = take_exn queue in
  check_bool "emergency admission is identified" true
    (Queue_test.emergency_admission stop);
  complete queue;
  close queue None

let maximal_byte_accounting () =
  let queue = create ~capacity:1 ~max_pending_bytes:max_int in
  let ordinary =
    request ~bytes:max_int (Line_input "ordinary") (Some (`String "job"))
  in
  let emergency =
    request ~bytes:max_int (Line_input "emergency") (Some (`String "stop"))
  in
  check_bool "maximum ordinary byte count is admitted" true
    (enqueue queue ordinary);
  check_bool "maximum emergency byte count cannot overflow ordinary count" true
    (enqueue queue ~target:(`String "job") emergency);
  let full = Queue_test.snapshot queue in
  check_int "maximum ordinary bytes remain exact" max_int full.pending_bytes;
  check_int "maximum emergency bytes remain exact" max_int full.emergency_bytes;
  ignore (take_exn queue);
  complete queue;
  let after_ordinary = Queue_test.snapshot queue in
  check_int "ordinary byte count drains exactly" 0 after_ordinary.pending_bytes;
  check_int "emergency bytes remain exact" max_int
    after_ordinary.emergency_bytes;
  ignore (take_exn queue);
  complete queue;
  let empty = Queue_test.snapshot queue in
  check_int "emergency byte count drains exactly" 0 empty.emergency_bytes;
  close queue None

let emergency_slot_is_single () =
  let queue = create ~capacity:1 ~max_pending_bytes:1 in
  let ordinary = request ~bytes:1 (Line_input "job") (Some (`String "job")) in
  let first = request ~bytes:1 (Line_input "first-cancel") None in
  let second = request ~bytes:1 (Line_input "second-cancel") None in
  check_bool "ordinary capacity filled" true (enqueue queue ordinary);
  check_bool "first emergency cancellation admitted" true
    (enqueue queue ~target:(`String "job") first);
  check_bool "second emergency cancellation overloads" false
    (enqueue queue ~target:(`String "other-job") second);
  let terminal = Queue_test.snapshot queue in
  check_bool "second emergency closes the queue" true terminal.closed;
  check_int "ordinary, emergency, and one marker" 3 terminal.pending_count;
  check_int "ordinary accounting remains bounded" 1 terminal.pending_bytes;
  check_int "one emergency remains separately bounded" 1
    terminal.emergency_bytes

let overflow_is_ordered_and_unique () =
  let queue = create ~capacity:2 ~max_pending_bytes:100 in
  let active = request ~bytes:1 (Line_input "active") (Some (`String "a")) in
  let first = request ~bytes:3 (Line_input "one") (Some (`String "one")) in
  let second = request ~bytes:3 (Line_input "two") (Some (`String "two")) in
  let triggering =
    request ~bytes:4 (Line_input "boom") (Some (`String "overflow"))
  in
  check_bool "enqueue active" true (enqueue queue active);
  ignore (take_exn queue);
  check_bool "enqueue first pending" true (enqueue queue first);
  check_bool "enqueue second pending" true (enqueue queue second);
  check_bool "overflow closes admission" false (enqueue queue triggering);
  check_bool "active request cancelled" true (Queue_test.cancelled active);
  check_bool "first pending request cancelled" true (Queue_test.cancelled first);
  check_bool "second pending request cancelled" true
    (Queue_test.cancelled second);
  let overflowed = Queue_test.snapshot queue in
  check_bool "overflow closes queue" true overflowed.closed;
  check_bool "overflow records reader failure" true
    (Option.is_some overflowed.reader_error);
  check_int "pending requests plus one marker" 3 overflowed.pending_count;
  check_int "marker consumes no pending bytes" 6 overflowed.pending_bytes;
  let late = request ~bytes:1 (Line_input "late") None in
  check_bool "closed queue rejects later input" false (enqueue queue late);
  check_int "later input cannot add a second marker" 3
    (Queue_test.snapshot queue).pending_count;
  complete queue;
  let first_taken = take_exn queue in
  check_line "first request remains ordered" "one" first_taken;
  complete queue;
  let second_taken = take_exn queue in
  check_line "second request remains ordered" "two" second_taken;
  complete queue;
  let marker = take_exn queue in
  begin match Centl_request_queue.input marker with
  | Queue_overflow_input (Some line) ->
      Alcotest.(check string) "marker retains triggering line" "boom" line
  | Queue_overflow_input None -> Alcotest.fail "overflow marker lost its line"
  | Line_input _ | Oversized_input ->
      Alcotest.fail "expected the ordered overflow marker"
  end;
  check_bool "overflow marker itself is runnable" false
    (Queue_test.cancelled marker);
  complete queue;
  check_bool "exactly one overflow marker" true (Option.is_none (take queue));
  check_bool "overflow is a reader failure" false (reader_succeeded queue)

let close_wakes_a_waiter () =
  let queue = create ~capacity:1 ~max_pending_bytes:1 in
  let result = Atomic.make 0 in
  let waiter =
    Thread.create
      (fun () ->
        Atomic.set result (match take queue with None -> 1 | Some _ -> 2))
      ()
  in
  let rec wait_until_blocked attempts =
    if (Queue_test.snapshot queue).waiting = 1 then ()
    else if attempts = 0 then Alcotest.fail "take did not block on the queue"
    else begin
      Thread.yield ();
      wait_until_blocked (attempts - 1)
    end
  in
  wait_until_blocked 10_000;
  close queue None;
  Thread.join waiter;
  check_int "close wakes blocked take" 1 (Atomic.get result);
  check_bool "orderly close succeeds" true (reader_succeeded queue)

let write_lines channel lines =
  List.iter
    (fun line ->
      output_string channel line;
      output_char channel '\n')
    lines;
  flush channel

let with_pipe action =
  let input_descriptor, output_descriptor = Unix.pipe () in
  let input = Unix.in_channel_of_descr input_descriptor in
  let output = Unix.out_channel_of_descr output_descriptor in
  Fun.protect
    ~finally:(fun () ->
      close_in_noerr input;
      close_out_noerr output)
    (fun () -> action input output)

let reader_error_is_retained () =
  with_pipe (fun input output ->
      let queue = create ~capacity:2 ~max_pending_bytes:100 in
      let classify_id _ = failwith "reader classifier failed" in
      let reader =
        start_reader ~channel:input ~max_bytes:100 ~classify_id
          ~classify_cancellation:(fun _ -> None)
          queue
      in
      write_lines output [ {|{"valid":"json"}|} ];
      close_out output;
      Thread.join reader;
      let ended = Queue_test.snapshot queue in
      check_bool "reader error closes queue" true ended.closed;
      check_bool "reader exception is retained" true
        (match ended.reader_error with
        | Some (Failure message) -> message = "reader classifier failed"
        | Some _ | None -> false);
      close queue None;
      check_bool "later orderly close preserves reader error" true
        (Option.is_some (Queue_test.snapshot queue).reader_error);
      check_bool "reader error reports failure" false (reader_succeeded queue))

let reader_classifies_pipe_input () =
  with_pipe (fun input output ->
      let queue = create ~capacity:8 ~max_pending_bytes:1_024 in
      let reader =
        start_reader ~channel:input ~max_bytes:128
          ~classify_id:Centl_protocol.cancellable_request_id
          ~classify_cancellation:Centl_protocol.cancellation_target_of_json
          queue
      in
      let evaluation =
        {|{"version":1,"id":"job","expression":"sum(k, k = 1, 10)"}|}
      in
      let cancellation =
        {|{"version":1,"id":"stop","op":"cancel","target":"job"}|}
      in
      write_lines output [ evaluation; cancellation; String.make 129 'x' ];
      close_out output;
      Thread.join reader;
      check_bool "pipe reader reached EOF cleanly" true (reader_succeeded queue);
      let queued = Queue_test.snapshot queue in
      check_bool "EOF closes queue" true queued.closed;
      check_int "line, cancellation, oversized" 3 queued.pending_count;
      check_int "all classified bytes are accounted"
        (String.length evaluation + String.length cancellation + 128)
        queued.pending_bytes;
      let job = take_exn queue in
      check_line "evaluation line" evaluation job;
      check_id "classified job id" (Some {|"job"|}) job;
      check_bool "later pipe cancellation marks job" true
        (Queue_test.cancelled job);
      complete queue;
      let stop = take_exn queue in
      check_line "cancellation line" cancellation stop;
      check_id "cancellations are not evaluation jobs" None stop;
      complete queue;
      let oversized = take_exn queue in
      begin match Centl_request_queue.input oversized with
      | Oversized_input -> ()
      | Line_input _ | Queue_overflow_input _ ->
          Alcotest.fail "reader did not classify oversized input"
      end;
      check_int "oversized input is bounded in accounting" 128
        (Queue_test.bytes oversized);
      complete queue;
      check_bool "closed reader queue drains" true (Option.is_none (take queue)))

let read_all_lines channel =
  let rec loop reversed =
    match input_line channel with
    | line -> loop (line :: reversed)
    | exception End_of_file -> List.rev reversed
  in
  loop []

let json_field name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let serve_process_cancellation () =
  let executable =
    match Sys.getenv_opt "CENTL_TEST_EXECUTABLE" with
    | Some path -> path
    | None -> Alcotest.fail "missing CENTL_TEST_EXECUTABLE"
  in
  let child_stdout, child_stdin, child_stderr =
    Unix.open_process_args_full executable
      [| executable; "--serve" |]
      (Unix.environment ())
  in
  let evaluation =
    {|{"version":1,"id":"job","expression":"sum(k^2, k = 1, 100000)"}|}
  in
  let cancellation =
    {|{"version":1,"id":"stop","op":"cancel","target":"job"}|}
  in
  write_lines child_stdin [ evaluation; cancellation ];
  close_out child_stdin;
  let output = read_all_lines child_stdout in
  let errors = read_all_lines child_stderr in
  let status =
    Unix.close_process_full (child_stdout, child_stdin, child_stderr)
  in
  Alcotest.(check (list string)) "serve writes no diagnostics" [] errors;
  check_bool "serve exits successfully" true
    (match status with Unix.WEXITED 0 -> true | _ -> false);
  Alcotest.(check int)
    "cancelled request and acknowledgement" 2 (List.length output);
  let responses = List.map Yojson.Safe.from_string output in
  begin match responses with
  | [ cancelled_response; acknowledgement ] ->
      Alcotest.(check (option string))
        "cancelled response id" (Some "job")
        (match json_field "id" cancelled_response with
        | Some (`String id) -> Some id
        | _ -> None);
      Alcotest.(check (option string))
        "cooperative cancellation code" (Some "cancelled")
        (match json_field "error" cancelled_response with
        | Some (`Assoc error) ->
            begin match List.assoc_opt "code" error with
            | Some (`String code) -> Some code
            | _ -> None
            end
        | _ -> None);
      Alcotest.(check (option string))
        "cancellation acknowledgement id" (Some "stop")
        (match json_field "id" acknowledgement with
        | Some (`String id) -> Some id
        | _ -> None);
      check_bool "cancellation acknowledgement succeeds" true
        (json_field "ok" acknowledgement = Some (`Bool true))
  | _ -> Alcotest.fail "serve returned an unexpected response sequence"
  end

let () =
  Alcotest.run "request queue"
    [
      ( "queue",
        [
          Alcotest.test_case "FIFO and byte accounting" `Quick
            fifo_and_byte_accounting;
          Alcotest.test_case "string and integer cancellation" `Quick
            cancellation_by_string_and_integer_id;
          Alcotest.test_case "reserved cancellation admission" `Quick
            cancellation_reserved_admission;
          Alcotest.test_case "maximum byte accounting" `Quick
            maximal_byte_accounting;
          Alcotest.test_case "single emergency slot" `Quick
            emergency_slot_is_single;
          Alcotest.test_case "ordered unique overflow" `Quick
            overflow_is_ordered_and_unique;
          Alcotest.test_case "close wakes waiter" `Quick close_wakes_a_waiter;
        ] );
      ( "reader",
        [
          Alcotest.test_case "reader error" `Quick reader_error_is_retained;
          Alcotest.test_case "pipe classification" `Quick
            reader_classifies_pipe_input;
          Alcotest.test_case "serve cancellation process" `Quick
            serve_process_cancellation;
        ] );
    ]
