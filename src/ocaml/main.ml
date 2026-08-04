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
  print_endline "Incomplete statements continue on the next line.";
  print_endline
    "Use Tab to complete names and Up/Down to browse session history.";
  print_endline ":history        show history kept for this session";
  print_endline ":clear-history  clear session history";
  print_endline ":syntax         list mathematical identifiers";
  print_endline ":quit           leave the calculator"

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

type source_location = {
  line : int;
  column : int;
  text : string;
  prefix : string;
}

let expand_tabs text =
  let output = Buffer.create (String.length text) in
  let column = ref 0 in
  String.iter
    (fun character ->
      if character = '\t' then begin
        let spaces = 8 - (!column mod 8) in
        Buffer.add_string output (String.make spaces ' ');
        column := !column + spaces
      end
      else begin
        Buffer.add_char output character;
        incr column
      end)
    text;
  Buffer.contents output

let source_location source position =
  let position = max 0 (min position (String.length source)) in
  let rec find_line offset line line_start =
    if offset >= position then (line, line_start)
    else if source.[offset] = '\n' then
      find_line (offset + 1) (line + 1) (offset + 1)
    else find_line (offset + 1) line line_start
  in
  let line, line_start = find_line 0 1 0 in
  let rec find_end offset =
    if offset >= String.length source || source.[offset] = '\n' then offset
    else find_end (offset + 1)
  in
  let line_end = find_end line_start in
  let text = String.sub source line_start (line_end - line_start) in
  let prefix = String.sub source line_start (position - line_start) in
  { line; column = position - line_start + 1; text; prefix }

let diagnostic_text ?source_name ?(start_line = 1) source
    (error : Centl_engine.error) =
  match error.position with
  | None -> "error: " ^ error.message
  | Some position ->
      let location = source_location source position in
      let display_line = start_line + location.line - 1 in
      let heading =
        match source_name with
        | Some name ->
            Printf.sprintf "%s:%d:%d: error: %s" name display_line
              location.column error.message
        | None when location.line = 1 ->
            Printf.sprintf "error: %s at column %d" error.message
              location.column
        | None ->
            Printf.sprintf "error: %s at line %d, column %d" error.message
              location.line location.column
      in
      let line_number = string_of_int display_line in
      let gutter_width = String.length line_number in
      let caret_width = String.length (expand_tabs location.prefix) in
      let caret_padding = String.make caret_width ' ' in
      let context =
        Printf.sprintf "%*s | %s\n%*s | %s^" gutter_width line_number
          (expand_tabs location.text)
          gutter_width "" caret_padding
      in
      heading ^ "\n" ^ context

let evaluate_human_in_session ?source_name ?(start_line = 1) ~color session
    source =
  match Centl_engine.evaluate_in_session session source with
  | Ok result ->
      print_endline
        (if color then Centl_engine.colored_text_of_session_result result
         else Centl_engine.text_of_session_result result);
      true
  | Error error ->
      let message = diagnostic_text ?source_name ~start_line source error in
      prerr_endline (if color then ansi "91" message else message);
      false

let evaluate_json source =
  let result = Centl_engine.evaluate source in
  print_json (Centl_engine.json_of_evaluation result);
  Result.is_ok result

type statement_builder = {
  mutable lines : string list;
  mutable start_line : int;
  mutable source_bytes : int;
  mutable open_parentheses : int;
  mutable unmatched_closing : bool;
  mutable last_significant : char option;
}

type statement_progress = Ignored | Incomplete | Statement of string * int

let max_source_bytes = Centl_engine.default_evaluation_limits.max_source_bytes

let create_statement_builder () =
  {
    lines = [];
    start_line = 1;
    source_bytes = 0;
    open_parentheses = 0;
    unmatched_closing = false;
    last_significant = None;
  }

let builder_is_empty builder = builder.lines = []

let reset_statement_builder builder =
  builder.lines <- [];
  builder.source_bytes <- 0;
  builder.open_parentheses <- 0;
  builder.unmatched_closing <- false;
  builder.last_significant <- None

let statement_source builder = String.concat "\n" (List.rev builder.lines)

let scan_statement_structure builder line =
  String.iter
    (function
      | ' ' | '\t' | '\r' | '\n' -> ()
      | '(' ->
          builder.open_parentheses <- builder.open_parentheses + 1;
          builder.last_significant <- Some '('
      | ')' ->
          if builder.open_parentheses = 0 then builder.unmatched_closing <- true
          else builder.open_parentheses <- builder.open_parentheses - 1;
          builder.last_significant <- Some ')'
      | character -> builder.last_significant <- Some character)
    line

let statement_needs_more builder =
  (not builder.unmatched_closing)
  && (builder.open_parentheses > 0
     ||
     match builder.last_significant with
     | Some ('+' | '-' | '*' | '/' | '^' | '=' | '<' | '>') -> true
     | _ -> false)

let add_statement_line builder ~line_number line =
  let trimmed = String.trim line in
  if builder_is_empty builder && (trimmed = "" || trimmed.[0] = '#') then
    Ignored
  else begin
    if builder_is_empty builder then builder.start_line <- line_number;
    let line = if trimmed <> "" && trimmed.[0] = '#' then "" else line in
    if builder.lines <> [] then builder.source_bytes <- builder.source_bytes + 1;
    builder.lines <- line :: builder.lines;
    builder.source_bytes <- builder.source_bytes + String.length line;
    scan_statement_structure builder line;
    if builder.source_bytes < max_source_bytes && statement_needs_more builder
    then Incomplete
    else begin
      let source = statement_source builder in
      let start_line = builder.start_line in
      reset_statement_builder builder;
      Statement (source, start_line)
    end
  end

let remaining_statement_bytes builder =
  let separator_bytes = if builder_is_empty builder then 0 else 1 in
  max 0 (max_source_bytes - builder.source_bytes - separator_bytes)

let finish_statement builder =
  if builder_is_empty builder then None
  else
    let source = statement_source builder in
    let start_line = builder.start_line in
    reset_statement_builder builder;
    Some (source, start_line)

let run_channel ~color mode name channel =
  let session = Centl_engine.create_session () in
  let builder = create_statement_builder () in
  let evaluate source start_line =
    match mode with
    | Human ->
        evaluate_human_in_session ~source_name:name ~start_line ~color session
          source
    | Json -> evaluate_json source
    | Serve | Mcp -> assert false
  in
  let rec lines number =
    match Centl_protocol.read_line channel max_source_bytes with
    | Centl_protocol.Line line ->
        begin match add_statement_line builder ~line_number:number line with
        | Ignored | Incomplete -> lines (number + 1)
        | Statement (source, start_line) ->
            if evaluate source start_line then lines (number + 1) else false
        end
    | Centl_protocol.Oversized ->
        prerr_endline
          (Printf.sprintf
             "%s:%d: error: the expression exceeds the source-byte limit" name
             number);
        false
    | Centl_protocol.End ->
        begin match finish_statement builder with
        | None -> true
        | Some (source, start_line) -> evaluate source start_line
        end
  in
  lines 1

let run_file ~color mode path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () -> run_channel ~color mode path channel)

type history = { mutable newest_first : string list }

let create_history () = { newest_first = [] }

let rec take count values =
  if count <= 0 then []
  else
    match values with
    | [] -> []
    | value :: rest -> value :: take (count - 1) rest

let add_history history line =
  if String.length line <= max_source_bytes && String.trim line <> "" then
    match history.newest_first with
    | previous :: _ when previous = line -> ()
    | _ -> history.newest_first <- take 1_000 (line :: history.newest_first)

let history_in_order history = List.rev history.newest_first

type edited_line =
  | Submitted of string
  | Input_limit_exceeded
  | End_of_input
  | Interrupted

let terminal_write text =
  output_string stdout text;
  flush stdout

type editor_buffer = { storage : Bytes.t; mutable used : int }

let create_editor_buffer max_bytes =
  { storage = Bytes.create (max 0 max_bytes); used = 0 }

let editor_capacity buffer = Bytes.length buffer.storage
let editor_length buffer = buffer.used
let editor_text buffer = Bytes.sub_string buffer.storage 0 buffer.used
let editor_get buffer index = Bytes.get buffer.storage index

let editor_set_text buffer text =
  let length = String.length text in
  if length > editor_capacity buffer then false
  else begin
    Bytes.blit_string text 0 buffer.storage 0 length;
    buffer.used <- length;
    true
  end

let editor_append buffer character =
  if buffer.used >= editor_capacity buffer then false
  else begin
    Bytes.set buffer.storage buffer.used character;
    buffer.used <- buffer.used + 1;
    true
  end

let editor_insert buffer offset character =
  if buffer.used >= editor_capacity buffer then false
  else begin
    Bytes.blit buffer.storage offset buffer.storage (offset + 1)
      (buffer.used - offset);
    Bytes.set buffer.storage offset character;
    buffer.used <- buffer.used + 1;
    true
  end

let editor_delete_before buffer offset =
  if offset <= 0 then false
  else begin
    Bytes.blit buffer.storage offset buffer.storage (offset - 1)
      (buffer.used - offset);
    buffer.used <- buffer.used - 1;
    true
  end

let editor_delete_at buffer offset =
  if offset >= buffer.used then false
  else begin
    Bytes.blit buffer.storage (offset + 1) buffer.storage offset
      (buffer.used - offset - 1);
    buffer.used <- buffer.used - 1;
    true
  end

let editor_delete_prefix buffer finish =
  if finish <= 0 then false
  else begin
    Bytes.blit buffer.storage finish buffer.storage 0 (buffer.used - finish);
    buffer.used <- buffer.used - finish;
    true
  end

let editor_replace_span buffer start finish replacement =
  let replacement_length = String.length replacement in
  let new_length = buffer.used - (finish - start) + replacement_length in
  if new_length > editor_capacity buffer then false
  else begin
    Bytes.blit buffer.storage finish buffer.storage
      (start + replacement_length)
      (buffer.used - finish);
    Bytes.blit_string replacement 0 buffer.storage start replacement_length;
    buffer.used <- new_length;
    true
  end

let save_cursor = "\027[s"
let restore_cursor = "\027[u"

let paint_line_to_end prompt line =
  (* Repaint from a saved prompt anchor so wrapped rows are cleared without
     guessing the terminal width or moving left across line boundaries. *)
  terminal_write (restore_cursor ^ "\027[J");
  terminal_write prompt;
  terminal_write (editor_text line)

let redraw_line prompt line cursor =
  paint_line_to_end prompt line;
  if cursor < editor_length line then begin
    terminal_write restore_cursor;
    terminal_write prompt;
    terminal_write (Bytes.sub_string line.storage 0 cursor)
  end

let identifier_character character =
  (character >= 'a' && character <= 'z')
  || (character >= 'A' && character <= 'Z')
  || (character >= '0' && character <= '9')
  || character = '_'

let completion_span line cursor =
  let rec find_start offset =
    if offset > 0 && identifier_character (editor_get line (offset - 1)) then
      find_start (offset - 1)
    else offset
  in
  let rec find_end offset =
    if
      offset < editor_length line
      && identifier_character (editor_get line offset)
    then find_end (offset + 1)
    else offset
  in
  let identifier_start = find_start cursor in
  let start =
    if identifier_start > 0 && editor_get line (identifier_start - 1) = ':' then
      identifier_start - 1
    else identifier_start
  in
  (start, find_end cursor)

let common_prefix left right =
  let limit = min (String.length left) (String.length right) in
  let rec length index =
    if index < limit && left.[index] = right.[index] then length (index + 1)
    else index
  in
  String.sub left 0 (length 0)

let complete_line ~prompt ~candidates line cursor =
  let start, finish = completion_span line !cursor in
  let prefix = Bytes.sub_string line.storage start (!cursor - start) in
  let matches =
    List.filter (String.starts_with ~prefix) candidates
    |> List.sort_uniq String.compare
  in
  let replace replacement =
    if editor_replace_span line start finish replacement then begin
      cursor := start + String.length replacement;
      redraw_line prompt line !cursor;
      true
    end
    else begin
      terminal_write "\007";
      false
    end
  in
  match matches with
  | [] ->
      terminal_write "\007";
      false
  | [ candidate ] -> replace candidate
  | first :: rest ->
      let shared = List.fold_left common_prefix first rest in
      if String.length shared > String.length prefix then replace shared
      else begin
        paint_line_to_end prompt line;
        terminal_write
          ("\r\n" ^ String.concat "  " matches ^ "\r\n" ^ save_cursor);
        redraw_line prompt line !cursor;
        false
      end

let read_raw_line ~prompt ~history ~candidates ~max_bytes
    (original : Unix.terminal_io) =
  let raw =
    {
      original with
      c_icanon = false;
      c_echo = false;
      c_echoe = false;
      c_echok = false;
      c_echonl = false;
      c_isig = false;
      c_ixon = false;
      c_icrnl = false;
      c_vmin = 1;
      c_vtime = 0;
    }
  in
  Unix.tcsetattr Unix.stdin Unix.TCSANOW raw;
  Fun.protect
    ~finally:(fun () ->
      try Unix.tcsetattr Unix.stdin Unix.TCSANOW original with _ -> ())
    (fun () ->
      let line = create_editor_buffer max_bytes in
      let cursor = ref 0 in
      let overflowed = ref false in
      let entries = Array.of_list (history_in_order history) in
      let history_index = ref (Array.length entries) in
      let draft = ref "" in
      let input_byte = Bytes.create 1 in
      let rec read_raw_character () =
        try
          if Unix.read Unix.stdin input_byte 0 1 = 0 then None
          else Some (Bytes.get input_byte 0)
        with
        | Unix.Unix_error (Unix.EINTR, _, _) -> read_raw_character ()
        | Unix.Unix_error (Unix.EIO, _, _) -> None
      in
      let input_character () =
        match read_raw_character () with
        | Some character -> character
        | None -> raise End_of_file
      in
      let set_line value =
        if editor_set_text line value then begin
          cursor := String.length value;
          overflowed := false;
          redraw_line prompt line !cursor;
          true
        end
        else begin
          terminal_write "\007";
          false
        end
      in
      let older_history () =
        if !history_index > 0 then
          let target = !history_index - 1 in
          if String.length entries.(target) > editor_capacity line then
            terminal_write "\007"
          else begin
            if !history_index = Array.length entries then
              draft := editor_text line;
            if set_line entries.(target) then history_index := target
          end
        else terminal_write "\007"
      in
      let newer_history () =
        if !history_index < Array.length entries then begin
          let target = !history_index + 1 in
          let value =
            if target = Array.length entries then !draft else entries.(target)
          in
          if set_line value then history_index := target
        end
        else terminal_write "\007"
      in
      let delete_left () =
        if editor_delete_before line !cursor then begin
          decr cursor;
          overflowed := false;
          redraw_line prompt line !cursor
        end
      in
      let delete_at_cursor () =
        if editor_delete_at line !cursor then begin
          overflowed := false;
          redraw_line prompt line !cursor
        end
      in
      let end_of_input () =
        paint_line_to_end prompt line;
        terminal_write "\r\n";
        if !overflowed then Input_limit_exceeded
        else if editor_length line = 0 then End_of_input
        else Submitted (editor_text line)
      in
      let read_escape_character () =
        try
          let readable, _, _ = Unix.select [ Unix.stdin ] [] [] 0.05 in
          if readable = [] then `Timeout
          else
            match read_raw_character () with
            | Some character -> `Character character
            | None -> `End
        with Unix.Unix_error (Unix.EINTR, _, _) -> `Timeout
      in
      let escape_sequence () =
        match read_escape_character () with
        | `End -> true
        | `Timeout -> false
        | `Character '[' ->
            begin match read_escape_character () with
            | `End -> true
            | `Timeout -> false
            | `Character 'A' ->
                older_history ();
                false
            | `Character 'B' ->
                newer_history ();
                false
            | `Character 'C' ->
                if !cursor < editor_length line then begin
                  incr cursor;
                  redraw_line prompt line !cursor
                end;
                false
            | `Character 'D' ->
                if !cursor > 0 then begin
                  decr cursor;
                  redraw_line prompt line !cursor
                end;
                false
            | `Character 'H' ->
                cursor := 0;
                redraw_line prompt line !cursor;
                false
            | `Character 'F' ->
                cursor := editor_length line;
                redraw_line prompt line !cursor;
                false
            | `Character '3' ->
                begin match read_escape_character () with
                | `End -> true
                | `Timeout -> false
                | `Character '~' ->
                    delete_at_cursor ();
                    false
                | `Character _ -> false
                end
            | `Character _ -> false
            end
        | `Character 'O' ->
            begin match read_escape_character () with
            | `End -> true
            | `Timeout -> false
            | `Character 'H' ->
                cursor := 0;
                redraw_line prompt line !cursor;
                false
            | `Character 'F' ->
                cursor := editor_length line;
                redraw_line prompt line !cursor;
                false
            | `Character _ -> false
            end
        | `Character _ -> false
      in
      let reject_character () =
        if not !overflowed then begin
          overflowed := true;
          terminal_write "\007"
        end
      in
      let insert_character character =
        if !cursor = editor_length line then
          begin if editor_append line character then begin
            incr cursor;
            output_char stdout character;
            flush stdout
          end
          else reject_character ()
          end
        else if editor_insert line !cursor character then begin
          incr cursor;
          redraw_line prompt line !cursor
        end
        else reject_character ()
      in
      let rec edit () =
        match input_character () with
        | '\r' | '\n' ->
            paint_line_to_end prompt line;
            terminal_write "\r\n";
            if !overflowed then Input_limit_exceeded
            else Submitted (editor_text line)
        | '\003' ->
            paint_line_to_end prompt line;
            terminal_write "^C\r\n";
            Interrupted
        | '\004' when editor_length line = 0 ->
            terminal_write "\r\n";
            End_of_input
        | '\004' ->
            delete_at_cursor ();
            edit ()
        | '\001' ->
            cursor := 0;
            redraw_line prompt line !cursor;
            edit ()
        | '\005' ->
            cursor := editor_length line;
            redraw_line prompt line !cursor;
            edit ()
        | '\t' ->
            if complete_line ~prompt ~candidates line cursor then
              overflowed := false;
            edit ()
        | '\012' ->
            redraw_line prompt line !cursor;
            edit ()
        | '\016' ->
            older_history ();
            edit ()
        | '\014' ->
            newer_history ();
            edit ()
        | '\008' | '\127' ->
            delete_left ();
            edit ()
        | '\021' ->
            if editor_delete_prefix line !cursor then overflowed := false;
            cursor := 0;
            redraw_line prompt line !cursor;
            edit ()
        | '\027' -> if escape_sequence () then end_of_input () else edit ()
        | character when Char.code character < 32 -> edit ()
        | character ->
            insert_character character;
            edit ()
        | exception End_of_file -> end_of_input ()
      in
      terminal_write (save_cursor ^ prompt);
      edit ())

let read_canonical_line ~max_bytes prompt =
  terminal_write prompt;
  match Centl_protocol.read_line stdin max_bytes with
  | Centl_protocol.Line line -> Submitted line
  | Centl_protocol.Oversized -> Input_limit_exceeded
  | Centl_protocol.End -> End_of_input

let read_edited_line ~prompt ~history ~candidates ~max_bytes =
  if
    Sys.win32
    || (not (Unix.isatty Unix.stdout))
    || Sys.getenv_opt "TERM" = Some "dumb"
  then read_canonical_line ~max_bytes prompt
  else
    try
      let original = Unix.tcgetattr Unix.stdin in
      read_raw_line ~prompt ~history ~candidates ~max_bytes original
    with Unix.Unix_error _ | Invalid_argument _ ->
      read_canonical_line ~max_bytes prompt

let repl_commands =
  [ ":help"; ":history"; ":clear-history"; ":syntax"; ":quit"; ":q" ]

let completion_candidates (session : Centl_engine.session) =
  repl_commands @ Centl_syntax.completion_names @ List.map fst session.bindings
  |> List.sort_uniq String.compare

type repl_input =
  | Repl_command of string
  | Repl_statement of string
  | Repl_final_statement of string
  | Repl_input_limit
  | Repl_interrupted
  | Repl_end

let history_entry_of_source source =
  source |> String.split_on_char '\n' |> List.map String.trim
  |> String.concat " "

let read_repl_input ~color session history =
  let builder = create_statement_builder () in
  let line_number = ref 1 in
  let rec read () =
    let prompt_text =
      if builder_is_empty builder then "centl> " else "....> "
    in
    let prompt = if color then ansi "94" prompt_text else prompt_text in
    let candidates = completion_candidates session in
    let max_bytes = remaining_statement_bytes builder in
    match read_edited_line ~prompt ~history ~candidates ~max_bytes with
    | Interrupted ->
        reset_statement_builder builder;
        Repl_interrupted
    | Input_limit_exceeded ->
        reset_statement_builder builder;
        Repl_input_limit
    | End_of_input ->
        begin match finish_statement builder with
        | None -> Repl_end
        | Some (source, _) ->
            add_history history (history_entry_of_source source);
            Repl_final_statement source
        end
    | Submitted line ->
        let trimmed = String.trim line in
        if builder_is_empty builder && String.starts_with ~prefix:":" trimmed
        then begin
          add_history history trimmed;
          Repl_command trimmed
        end
        else
          let current_line = !line_number in
          incr line_number;
          begin match
            add_statement_line builder ~line_number:current_line line
          with
          | Ignored | Incomplete -> read ()
          | Statement (source, _) ->
              add_history history (history_entry_of_source source);
              Repl_statement source
          end
  in
  read ()

let print_history history =
  match history_in_order history with
  | [] -> print_endline "(history is empty)"
  | entries ->
      List.iteri
        (fun index entry -> Printf.printf "%4d  %s\n" (index + 1) entry)
        entries

let repl ~color () =
  let session = Centl_engine.create_session () in
  let history = create_history () in
  print_endline
    (Printf.sprintf "CENTL %s — exact mathematics and rigorous real enclosures"
       version);
  print_endline "Type :help for help or :quit to leave.";
  let rec loop () =
    match read_repl_input ~color session history with
    | Repl_end -> ()
    | Repl_interrupted -> loop ()
    | Repl_input_limit ->
        prerr_endline "error: the expression exceeds the source-byte limit";
        loop ()
    | Repl_statement source ->
        ignore (evaluate_human_in_session ~color session source);
        loop ()
    | Repl_final_statement source ->
        ignore (evaluate_human_in_session ~color session source)
    | Repl_command (":quit" | ":q") -> ()
    | Repl_command ":help" ->
        print_repl_help ();
        loop ()
    | Repl_command ":syntax" ->
        Centl_syntax.print stdout;
        loop ()
    | Repl_command ":history" ->
        print_history history;
        loop ()
    | Repl_command ":clear-history" ->
        history.newest_first <- [];
        print_endline "Session history cleared.";
        loop ()
    | Repl_command command ->
        prerr_endline ("unknown command " ^ command ^ "; type :help for help");
        loop ()
  in
  loop ()

let run_json_stream () =
  let max_request_bytes =
    Centl_protocol.default_server_limits.max_request_bytes
  in
  let rec lines all_ok =
    match Centl_protocol.read_line stdin max_request_bytes with
    | Centl_protocol.Line line ->
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
    | Centl_protocol.Oversized ->
        print_json
          (Centl_protocol.json_error "resource_limit"
             "the request exceeds the byte limit");
        lines false
    | Centl_protocol.End -> all_ok
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
