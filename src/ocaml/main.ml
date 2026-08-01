type mode = Human | Json | Serve | Mcp
type color_mode = Auto | Always | Never

let version = Centl_version.value

type command = {
  mode : mode;
  color : color_mode;
  file : string option;
  expression_parts : string list;
}

let usage =
  "Usage: centl [--json|--serve|--mcp] [--syntax] [--color=auto|always|never] \
   [--file PATH] [EXPRESSION]"

let print_help () =
  print_endline "CENTL — exact mathematics, directly.";
  print_endline "";
  print_endline usage;
  print_endline "";
  print_endline "  centl EXPRESSION   calculate";
  print_endline "  centl              open the calculator";
  print_endline "  --file PATH        run a script";
  print_endline "  --syntax           list mathematical identifiers";
  print_endline "  --json [EXPR]      use the JSON interface";
  print_endline "  --serve            persistent stateful JSON Lines";
  print_endline "  --mcp              MCP server over standard I/O";
  print_endline "  --color=MODE       auto, always, or never";
  print_endline "  --version          show the version"

let print_repl_help () =
  print_endline "Enter mathematics directly, then press return.";
  print_endline ":syntax  list mathematical identifiers";
  print_endline ":quit    leave the calculator"

let parse_color_mode = function
  | "auto" -> Ok Auto
  | "always" -> Ok Always
  | "never" -> Ok Never
  | value -> Error ("unknown color mode " ^ value)

let select_mode command mode name =
  match command.mode with
  | Human -> Ok { command with mode }
  | _ -> Error ("use only one of --json, --serve, or --mcp; found " ^ name)

let parse_arguments arguments =
  let rec loop command = function
    | [] ->
        Ok { command with expression_parts = List.rev command.expression_parts }
    | "--help" :: _ ->
        print_help ();
        exit 0
    | "--version" :: _ ->
        print_endline ("centl " ^ version);
        exit 0
    | "--syntax" :: _ ->
        Centl_syntax.print stdout;
        exit 0
    | "--json" :: rest ->
        begin match select_mode command Json "--json" with
        | Ok command -> loop command rest
        | Error _ as error -> error
        end
    | "--serve" :: rest ->
        begin match select_mode command Serve "--serve" with
        | Ok command -> loop command rest
        | Error _ as error -> error
        end
    | "--mcp" :: rest ->
        begin match select_mode command Mcp "--mcp" with
        | Ok command -> loop command rest
        | Error _ as error -> error
        end
    | "--color" :: rest -> loop { command with color = Always } rest
    | "--no-color" :: rest -> loop { command with color = Never } rest
    | option :: rest when String.starts_with ~prefix:"--color=" option ->
        let value = String.sub option 8 (String.length option - 8) in
        begin match parse_color_mode value with
        | Ok color -> loop { command with color } rest
        | Error _ as error -> error
        end
    | "--file" :: path :: rest ->
        begin match command.file with
        | None -> loop { command with file = Some path } rest
        | Some _ -> Error "--file may be given only once"
        end
    | "--file" :: [] -> Error "--file requires a path"
    | "--" :: rest ->
        Ok
          {
            command with
            expression_parts = List.rev_append command.expression_parts rest;
          }
    | option :: _ when String.length option > 2 && String.sub option 0 2 = "--"
      ->
        Error ("unknown option " ^ option)
    | part :: rest ->
        loop
          { command with expression_parts = part :: command.expression_parts }
          rest
  in
  loop
    { mode = Human; color = Auto; file = None; expression_parts = [] }
    arguments

let print_json json =
  Yojson.Safe.to_channel stdout json;
  output_char stdout '\n';
  flush stdout

type queued_input =
  | Line_input of string
  | Oversized_input
  | Queue_overflow_input of string option

type queued_request = {
  input : queued_input;
  bytes : int;
  request_id : Yojson.Safe.t option;
  cancellation : bool Atomic.t;
}

type request_queue = {
  mutex : Mutex.t;
  ready : Condition.t;
  capacity : int;
  max_pending_bytes : int;
  pending : queued_request Queue.t;
  mutable pending_bytes : int;
  mutable active : queued_request option;
  mutable closed : bool;
  mutable reader_error : exn option;
}

let create_request_queue ~capacity ~max_pending_bytes =
  {
    mutex = Mutex.create ();
    ready = Condition.create ();
    capacity = max 1 capacity;
    max_pending_bytes = max 1 max_pending_bytes;
    pending = Queue.create ();
    pending_bytes = 0;
    active = None;
    closed = false;
    reader_error = None;
  }

let pending_byte_capacity max_request_bytes =
  if max_request_bytes > max_int / 256 then max_int else max_request_bytes * 256

let with_queue_lock queue action =
  Mutex.lock queue.mutex;
  Fun.protect ~finally:(fun () -> Mutex.unlock queue.mutex) action

let same_request_id left right = left = right

let request_matches target request =
  match request.request_id with
  | Some id -> same_request_id id target
  | None -> false

let cancel_request request = Atomic.set request.cancellation true

let enqueue queue ?target request =
  with_queue_lock queue (fun () ->
      Option.iter
        (fun target ->
          Option.iter
            (fun active ->
              if request_matches target active then cancel_request active)
            queue.active;
          Queue.iter
            (fun pending ->
              if request_matches target pending then cancel_request pending)
            queue.pending)
        target;
      if queue.closed then false
      else if
        Queue.length queue.pending >= queue.capacity
        || request.bytes > queue.max_pending_bytes - queue.pending_bytes
      then begin
        Option.iter cancel_request queue.active;
        Queue.iter cancel_request queue.pending;
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
          }
          queue.pending;
        queue.closed <- true;
        queue.reader_error <-
          Some (Failure "the pending machine-request queue reached its limit");
        Condition.broadcast queue.ready;
        false
      end
      else begin
        Queue.add request queue.pending;
        queue.pending_bytes <- queue.pending_bytes + request.bytes;
        Condition.signal queue.ready;
        true
      end)

let close_request_queue queue reader_error =
  with_queue_lock queue (fun () ->
      queue.closed <- true;
      queue.reader_error <- reader_error;
      Condition.broadcast queue.ready)

let take_request queue =
  with_queue_lock queue (fun () ->
      while Queue.is_empty queue.pending && not queue.closed do
        Condition.wait queue.ready queue.mutex
      done;
      if Queue.is_empty queue.pending then None
      else
        let request = Queue.take queue.pending in
        queue.pending_bytes <- queue.pending_bytes - request.bytes;
        queue.active <- Some request;
        Some request)

let complete_request queue =
  with_queue_lock queue (fun () -> queue.active <- None)

let cancellation_callback request =
  let checks = ref 0 in
  fun () ->
    incr checks;
    if !checks = 1 || !checks mod 64 = 0 then Thread.yield ();
    Atomic.get request.cancellation

let queued_request ~bytes input request_id =
  { input; bytes; request_id; cancellation = Atomic.make false }

let start_machine_reader ~max_bytes ~classify_id ~classify_cancellation queue =
  Thread.create
    (fun () ->
      let rec loop () =
        match Centl_protocol.read_line stdin max_bytes with
        | Centl_protocol.End -> close_request_queue queue None
        | Centl_protocol.Oversized ->
            if
              enqueue queue
                (queued_request ~bytes:max_bytes Oversized_input None)
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
                (queued_request ~bytes:(String.length line) (Line_input line)
                   request_id)
            then loop ()
      in
      try loop () with error -> close_request_queue queue (Some error))
    ()

let reader_succeeded queue =
  with_queue_lock queue (fun () -> Option.is_none queue.reader_error)

let ansi code text = Printf.sprintf "\027[%sm%s\027[0m" code text

let evaluate_human_in_session ~color session source =
  match Centl_engine.evaluate_in_session session source with
  | Ok result ->
      print_endline
        (if color then Centl_engine.colored_text_of_session_result result
         else Centl_engine.text_of_session_result result);
      true
  | Error error ->
      let message = "error: " ^ Centl_engine.error_text error in
      prerr_endline (if color then ansi "91" message else message);
      false

let evaluate_json source =
  let result = Centl_engine.evaluate source in
  print_json (Centl_engine.json_of_evaluation result);
  Result.is_ok result

let meaningful_line line =
  let line = String.trim line in
  if line = "" || line.[0] = '#' then None else Some line

let run_channel ~color mode name channel =
  let session = Centl_engine.create_session () in
  let rec lines number =
    match input_line channel with
    | line ->
        begin match meaningful_line line with
        | None -> lines (number + 1)
        | Some expression ->
            let succeeded =
              match mode with
              | Human -> evaluate_human_in_session ~color session expression
              | Json -> evaluate_json expression
              | Serve | Mcp -> assert false
            in
            if succeeded then lines (number + 1)
            else begin
              prerr_endline (Printf.sprintf "in %s, line %d" name number);
              false
            end
        end
    | exception End_of_file -> true
  in
  lines 1

let run_file ~color mode path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () -> run_channel ~color mode path channel)

let repl ~color () =
  let session = Centl_engine.create_session () in
  print_endline
    (Printf.sprintf "CENTL %s — exact mathematics and rigorous real enclosures"
       version);
  print_endline "Type :help for help or :quit to leave.";
  let rec loop () =
    print_string (if color then ansi "94" "centl> " else "centl> ");
    flush stdout;
    match read_line () with
    | exception End_of_file -> print_newline ()
    | line ->
        begin match String.trim line with
        | "" -> loop ()
        | ":quit" | ":q" -> ()
        | ":help" ->
            print_repl_help ();
            loop ()
        | ":syntax" ->
            Centl_syntax.print stdout;
            loop ()
        | expression ->
            ignore (evaluate_human_in_session ~color session expression);
            loop ()
        end
  in
  loop ()

let run_json_stream () =
  let rec lines all_ok =
    match input_line stdin with
    | line ->
        let response, ok =
          try
            let request = Yojson.Safe.from_string line in
            let response = Centl_engine.evaluate_request request in
            let ok =
              match response with
              | `Assoc fields -> List.assoc_opt "ok" fields = Some (`Bool true)
              | _ -> false
            in
            (response, ok)
          with Yojson.Json_error message ->
            (Centl_engine.invalid_request ("invalid JSON: " ^ message), false)
        in
        print_json response;
        lines (all_ok && ok)
    | exception End_of_file -> all_ok
  in
  lines true

let run_serve () =
  let state = Centl_protocol.create () in
  let limits = Centl_protocol.limits state in
  let queue =
    create_request_queue ~capacity:limits.max_requests
      ~max_pending_bytes:(pending_byte_capacity limits.max_request_bytes)
  in
  let reader =
    start_machine_reader
      ~max_bytes:(Centl_protocol.limits state).max_request_bytes
      ~classify_id:Centl_protocol.cancellable_request_id
      ~classify_cancellation:Centl_protocol.cancellation_target_of_json queue
  in
  let rec loop () =
    match take_request queue with
    | None -> ()
    | Some request ->
        let response =
          match request.input with
          | Line_input line ->
              Centl_protocol.handle_line
                ~cancelled:(cancellation_callback request)
                state line
          | Oversized_input -> Centl_protocol.oversized_line state
          | Queue_overflow_input line ->
              Centl_protocol.queue_overflow state line
        in
        complete_request queue;
        print_json response;
        loop ()
  in
  loop ();
  Thread.join reader;
  reader_succeeded queue

let run_mcp () =
  let state = Centl_mcp.create () in
  let protocol = Centl_mcp.protocol_state state in
  let limits = Centl_protocol.limits protocol in
  let queue =
    create_request_queue ~capacity:limits.max_requests
      ~max_pending_bytes:(pending_byte_capacity limits.max_request_bytes)
  in
  let reader =
    start_machine_reader
      ~max_bytes:(Centl_protocol.limits protocol).max_request_bytes
      ~classify_id:Centl_mcp.cancellable_request_id
      ~classify_cancellation:Centl_mcp.cancellation_target_of_json queue
  in
  let print_response = function
    | None -> ()
    | Some response -> print_json response
  in
  let rec loop () =
    match take_request queue with
    | None -> ()
    | Some request ->
        let response =
          match request.input with
          | Line_input line ->
              Centl_mcp.handle_line
                ~cancelled:(cancellation_callback request)
                state line
          | Oversized_input -> Centl_mcp.oversized_line state
          | Queue_overflow_input line -> Centl_mcp.queue_overflow line
        in
        complete_request queue;
        if not (Centl_mcp.cancelled_response response) then
          print_response response;
        loop ()
  in
  loop ();
  Thread.join reader;
  reader_succeeded queue

let () =
  let arguments = Array.to_list Sys.argv |> List.tl in
  match parse_arguments arguments with
  | Error message ->
      prerr_endline ("centl: " ^ message);
      prerr_endline usage;
      exit 2
  | Ok command ->
      let color =
        match (command.mode, command.color) with
        | (Json | Serve | Mcp), _ | Human, Never -> false
        | Human, Always -> true
        | Human, Auto ->
            Unix.isatty Unix.stdout
            && Option.is_none (Sys.getenv_opt "NO_COLOR")
            && Sys.getenv_opt "TERM" <> Some "dumb"
      in
      let expression = String.concat " " command.expression_parts in
      let ok =
        match (command.file, expression, command.mode) with
        | Some _, _, (Serve | Mcp) ->
            prerr_endline "centl: --serve and --mcp do not accept --file";
            false
        | None, expression, (Serve | Mcp) when expression <> "" ->
            prerr_endline "centl: --serve and --mcp do not accept an expression";
            false
        | Some _, expression, _ when expression <> "" ->
            prerr_endline "centl: use either --file or an expression, not both";
            false
        | Some path, _, mode ->
            begin try run_file ~color mode path
            with Sys_error message ->
              prerr_endline ("centl: " ^ message);
              false
            end
        | None, expression, Human when expression <> "" ->
            evaluate_human_in_session ~color
              (Centl_engine.create_session ())
              expression
        | None, expression, Json when expression <> "" ->
            evaluate_json expression
        | None, _, Json -> run_json_stream ()
        | None, _, Serve -> run_serve ()
        | None, _, Mcp -> run_mcp ()
        | None, _, Human when Unix.isatty Unix.stdin ->
            repl ~color ();
            true
        | None, _, Human -> run_channel ~color Human "standard input" stdin
      in
      if not ok then exit 2
