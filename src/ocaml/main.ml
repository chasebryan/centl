type mode = Human | Json | Serve | Mcp
type color_mode = Auto | Always | Never

let version = Centl_version.value

type command = {
  mode : mode;
  color : color_mode;
  persistent_history : bool;
  file : string option;
  expression_parts : string list;
}

let usage =
  "Usage: centl [options] [EXPRESSION] | centl verify ... | centl check FILE"

let print_help () =
  print_endline "CENTL - exact mathematics, directly.";
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
  print_endline "  --no-history       do not load or save durable history";
  print_endline "  --color=MODE       auto, always, or never";
  print_endline "  --version          show the version";
  print_endline "";
  print_endline "  centl verify --left L --relation R --right Rhs";
  print_endline "      [--variable x:rational] [--json]";
  print_endline
    "                      check a structured claim (exit 0 only if verified)";
  print_endline "  centl check FILE [--json]  check contract assertions";
  print_endline
    "  assert(LEFT REL RIGHT)   calculator claim form (host-checked)"

let print_repl_help () =
  print_endline "Enter mathematics directly, then press return.";
  print_endline "Incomplete statements continue on the next line.";
  print_endline
    "Use Tab to complete names and Up/Down to browse calculator history.";
  print_endline ":history        show calculator history";
  print_endline ":clear-history  clear calculator history";
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
    | "--no-history" :: rest ->
        loop { command with persistent_history = false } rest
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
    {
      mode = Human;
      color = Auto;
      persistent_history = true;
      file = None;
      expression_parts = [];
    }
    arguments

let print_json json =
  Yojson.Safe.to_channel stdout json;
  output_char stdout '\n';
  flush stdout

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

let assert_claim_fields source =
  match Centl_parser.parse_statement_located source with
  | Error error ->
      Error
        {
          Centl_engine.code = "syntax_error";
          message = error.message;
          position = Some error.position;
        }
  | Ok located ->
      begin match located.statement with
      | Centl_parser.Assert { left_source; relation; right_source; variable } ->
          let fields =
            [
              ("left", `String left_source);
              ("relation", `String relation);
              ("right", `String right_source);
            ]
          in
          let fields =
            match variable with
            | None -> fields
            | Some name ->
                fields
                @ [
                    ( "variables",
                      `List
                        [
                          `Assoc
                            [
                              ("name", `String name);
                              ("domain", `String "rational");
                            ];
                        ] );
                  ]
          in
          Ok fields
      | _ ->
          Error
            {
              Centl_engine.code = "invalid_request";
              message = "not an assert statement";
              position = None;
            }
      end

let run_assert_statement session source =
  match assert_claim_fields source with
  | Error _ as error -> error
  | Ok fields -> Centl_verify.verify session fields

let is_assert_source source =
  let trimmed = String.trim source in
  let length = String.length trimmed in
  if length < 7 || String.sub trimmed 0 6 <> "assert" then false
  else
    let rec next_non_space index =
      if index >= length then None
      else
        match trimmed.[index] with
        | ' ' | '\t' | '\r' | '\n' -> next_non_space (index + 1)
        | character -> Some character
    in
    next_non_space 6 = Some '('

(* Statement evaluation outcomes map to CLI exits:
   Success -> 0, Claim_failed (refuted/unknown/invalid) -> 1, Failed -> 2. *)
type statement_result = Success | Claim_failed | Failed

let statement_result_exit = function
  | Success -> 0
  | Claim_failed -> 1
  | Failed -> 2

let statement_result_ok = function
  | Success -> true
  | Claim_failed | Failed -> false

let evaluate_human_in_session ?source_name ?(start_line = 1) ~color session
    source =
  if is_assert_source source then
    begin match run_assert_statement session source with
    | Ok verification ->
        print_endline (Centl_verify.text_of_verification verification);
        if verification.verdict = Centl_verify.Verified then Success
        else Claim_failed
    | Error error ->
        let message = diagnostic_text ?source_name ~start_line source error in
        prerr_endline (if color then ansi "91" message else message);
        Failed
    end
  else
    match Centl_engine.evaluate_in_session_detailed session source with
    | Ok result ->
        print_endline
          (if color then Centl_engine.colored_text_of_session_outcome result
           else Centl_engine.text_of_session_outcome result);
        Success
    | Error error ->
        let message = diagnostic_text ?source_name ~start_line source error in
        prerr_endline (if color then ansi "91" message else message);
        Failed

let evaluate_json source =
  if is_assert_source source then
    begin match assert_claim_fields source with
    | Ok fields ->
        let state = Centl_protocol.create () in
        let line =
          Yojson.Safe.to_string
            (`Assoc (("version", `Int 1) :: ("op", `String "verify") :: fields))
        in
        let response = Centl_protocol.handle_line state line in
        print_json response;
        begin match response with
        | `Assoc response_fields ->
            begin match
              ( List.assoc_opt "ok" response_fields,
                List.assoc_opt "verification" response_fields )
            with
            | Some (`Bool true), Some (`Assoc verification_fields) ->
                begin match List.assoc_opt "verdict" verification_fields with
                | Some (`String "verified") -> Success
                | Some (`String ("refuted" | "unknown" | "invalid")) ->
                    Claim_failed
                | _ -> Failed
                end
            | _ -> Failed
            end
        | _ -> Failed
        end
    | Error error ->
        print_json (Centl_engine.json_of_detailed_evaluation (Error error));
        Failed
    end
  else
    let result = Centl_engine.evaluate_detailed source in
    print_json (Centl_engine.json_of_detailed_evaluation result);
    if Result.is_ok result then Success else Failed

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
            begin match evaluate source start_line with
            | Success -> lines (number + 1)
            | result -> result
            end
        end
    | Centl_protocol.Oversized ->
        prerr_endline
          (Printf.sprintf
             "%s:%d: error: the expression exceeds the source-byte limit" name
             number);
        Failed
    | Centl_protocol.End ->
        begin match finish_statement builder with
        | None -> Success
        | Some (source, start_line) -> evaluate source start_line
        end
  in
  lines 1

let run_file ~color mode path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () -> run_channel ~color mode path channel)

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
      let entries = Array.of_list (Centl_history.entries history) in
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
            Centl_history.add history (history_entry_of_source source);
            Repl_final_statement source
        end
    | Submitted line ->
        let trimmed = String.trim line in
        if builder_is_empty builder && String.starts_with ~prefix:":" trimmed
        then begin
          Centl_history.add history trimmed;
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
              Centl_history.add history (history_entry_of_source source);
              Repl_statement source
          end
  in
  read ()

let print_history history =
  match Centl_history.entries history with
  | [] -> print_endline "(history is empty)"
  | entries ->
      List.iteri
        (fun index entry -> Printf.printf "%4d  %s\n" (index + 1) entry)
        entries

let repl ~color ~persistent_history () =
  let session = Centl_engine.create_session () in
  let persistent =
    persistent_history
    && not (Centl_history.environment_disables_persistence ())
  in
  let history = Centl_history.create ~persistent () in
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
        ignore
          (evaluate_human_in_session ~color session source : statement_result);
        loop ()
    | Repl_final_statement source ->
        ignore
          (evaluate_human_in_session ~color session source : statement_result)
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
        Centl_history.clear history;
        print_endline "History cleared.";
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
  let open Centl_request_queue in
  let state = Centl_protocol.create () in
  let limits = Centl_protocol.limits state in
  let queue =
    create ~capacity:limits.max_requests
      ~max_pending_bytes:(pending_byte_capacity limits.max_request_bytes)
  in
  let reader =
    start_reader ~channel:stdin
      ~max_bytes:(Centl_protocol.limits state).max_request_bytes
      ~classify_id:Centl_protocol.cancellable_request_id
      ~classify_cancellation:Centl_protocol.cancellation_target_of_json queue
  in
  let rec loop () =
    match take queue with
    | None -> ()
    | Some request ->
        let response =
          match input request with
          | Line_input line ->
              Centl_protocol.handle_line
                ~cancelled:(cancellation_callback request)
                state line
          | Oversized_input -> Centl_protocol.oversized_line state
          | Queue_overflow_input line ->
              Centl_protocol.queue_overflow state line
        in
        complete queue;
        print_json response;
        loop ()
  in
  loop ();
  Thread.join reader;
  reader_succeeded queue

let run_mcp () =
  let open Centl_request_queue in
  let state = Centl_mcp.create () in
  let protocol = Centl_mcp.protocol_state state in
  let limits = Centl_protocol.limits protocol in
  let queue =
    create ~capacity:limits.max_requests
      ~max_pending_bytes:(pending_byte_capacity limits.max_request_bytes)
  in
  let reader =
    start_reader ~channel:stdin
      ~max_bytes:(Centl_protocol.limits protocol).max_request_bytes
      ~classify_id:Centl_mcp.cancellable_request_id
      ~classify_cancellation:Centl_mcp.cancellation_target_of_json queue
  in
  let print_response = function
    | None -> ()
    | Some response -> print_json response
  in
  let rec loop () =
    match take queue with
    | None -> ()
    | Some request ->
        let response =
          match input request with
          | Line_input line ->
              Centl_mcp.handle_line
                ~cancelled:(cancellation_callback request)
                state line
          | Oversized_input -> Centl_mcp.oversized_line state
          | Queue_overflow_input line -> Centl_mcp.queue_overflow line
        in
        complete queue;
        if not (Centl_mcp.cancelled_response response) then
          print_response response;
        loop ()
  in
  loop ();
  Thread.join reader;
  reader_succeeded queue

let verify_exit_code = function
  | Centl_verify.Verified -> 0
  | Centl_verify.Refuted | Centl_verify.Unknown | Centl_verify.Invalid -> 1

let verification_response_exit_code = function
  | `Assoc fields ->
      begin match List.assoc_opt "ok" fields with
      | Some (`Bool false) -> 2
      | Some (`Bool true) ->
          begin match List.assoc_opt "verification" fields with
          | Some (`Assoc verification) ->
              begin match List.assoc_opt "verdict" verification with
              | Some (`String "verified") -> 0
              | Some (`String ("refuted" | "unknown" | "invalid")) -> 1
              | _ -> 2
              end
          | _ -> 2
          end
      | _ -> 2
      end
  | _ -> 2

let parse_variable_spec = function
  | value ->
      begin match String.split_on_char ':' value with
      | [ name; domain ] when name <> "" && domain <> "" -> Ok (name, domain)
      | [ name ] when name <> "" -> Ok (name, "rational")
      | _ -> Error ("invalid --variable " ^ value ^ " (expected name:rational)")
      end

let parse_verify_arguments arguments =
  let rec loop left relation right variable json = function
    | [] -> Ok (left, relation, right, variable, json)
    | "--json" :: rest -> loop left relation right variable true rest
    | "--left" :: value :: rest ->
        loop (Some value) relation right variable json rest
    | "--relation" :: value :: rest ->
        loop left (Some value) right variable json rest
    | "--right" :: value :: rest ->
        loop left relation (Some value) variable json rest
    | "--variable" :: value :: rest ->
        begin match parse_variable_spec value with
        | Ok variable -> loop left relation right (Some variable) json rest
        | Error _ as error -> error
        end
    | "--left" :: [] | "--relation" :: [] | "--right" :: [] | "--variable" :: []
      ->
        Error "verify options require a value"
    | option :: _ when String.starts_with ~prefix:"--" option ->
        Error ("unknown verify option " ^ option)
    | other :: _ -> Error ("unexpected verify argument " ^ other)
  in
  match loop None None None None false arguments with
  | Error _ as error -> error
  | Ok (Some left, Some relation, Some right, variable, json) ->
      Ok (left, relation, right, variable, json)
  | Ok _ -> Error "verify requires --left, --relation, and --right"

let run_verify arguments =
  match parse_verify_arguments arguments with
  | Error message ->
      prerr_endline ("centl: " ^ message);
      prerr_endline
        "Usage: centl verify --left EXPR --relation REL --right EXPR \
         [--variable name:rational] [--json]";
      exit 2
  | Ok (left, relation, right, variable, as_json) ->
      let fields =
        [
          ("left", `String left);
          ("relation", `String relation);
          ("right", `String right);
        ]
      in
      let fields =
        match variable with
        | None -> fields
        | Some (name, domain) ->
            fields
            @ [
                ( "variables",
                  `List
                    [
                      `Assoc
                        [ ("name", `String name); ("domain", `String domain) ];
                    ] );
              ]
      in
      if as_json then begin
        let state = Centl_protocol.create () in
        let line =
          Yojson.Safe.to_string
            (`Assoc (("version", `Int 1) :: ("op", `String "verify") :: fields))
        in
        let response = Centl_protocol.handle_line state line in
        print_json response;
        exit (verification_response_exit_code response)
      end
      else
        begin match
          Centl_verify.verify (Centl_engine.create_session ()) fields
        with
        | Error error ->
            prerr_endline ("centl: " ^ Centl_engine.error_text error);
            exit 2
        | Ok verification ->
            print_endline (Centl_verify.text_of_verification verification);
            exit (verify_exit_code verification.verdict)
        end

type check_line =
  | Check_define of { line_number : int; definition : string }
  | Check_assert of {
      line_number : int;
      left : string;
      relation : string;
      right : string;
      variable : (string * string) option;
    }

let parse_check_line line_number line =
let trimmed = String.trim line in
if trimmed = "" || String.starts_with ~prefix:"#" trimmed then None
else
  let parts = trimmed |> String.split_on_char '|' |> List.map String.trim in
  if List.exists (( = ) "") parts then
    failwith
      ("line " ^ string_of_int line_number
     ^ ": contract fields must not be empty")
  else
    begin match parts with
    | [ "define"; definition ] ->
        Some (Check_define { line_number; definition })
    | [ relation; left; right ] ->
        Some
          (Check_assert
             { line_number; left; relation; right; variable = None })
    | [ relation; left; right; variable ] ->
        begin match parse_variable_spec variable with
        | Ok variable ->
            Some
              (Check_assert
                 {
                   line_number;
                   left;
                   relation;
                   right;
                   variable = Some variable;
                 })
        | Error message ->
            failwith
              ("line " ^ string_of_int line_number ^ ": " ^ message)
        end
    | _ ->
        failwith
          ("line " ^ string_of_int line_number
         ^ ": expected define | DEF or RELATION | LEFT | RIGHT [| \
            VAR[:rational]]")
    end

let read_check_file path =
  let max_bytes = Centl_engine.default_evaluation_limits.max_source_bytes in
  let file_size = (Unix.LargeFile.stat path).st_size in
  if Int64.compare file_size (Int64.of_int max_bytes) > 0 then
    failwith
      (Printf.sprintf "contract exceeds the %d-byte source limit" max_bytes);
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () ->
      let rec loop line_number acc =
        match Centl_protocol.read_line channel max_bytes with
        | Centl_protocol.Line line ->
            let acc =
              match parse_check_line line_number line with
              | None -> acc
              | Some assertion -> assertion :: acc
            in
            loop (line_number + 1) acc
        | Centl_protocol.Oversized ->
            failwith
              (Printf.sprintf "line %d exceeds the %d-byte source limit"
                 line_number max_bytes)
        | Centl_protocol.End -> List.rev acc
      in
      loop 1 [])

let parse_check_arguments arguments =
  let rec loop path as_json = function
    | [] -> Ok (path, as_json)
    | "--json" :: rest -> loop path true rest
    | option :: _ when String.starts_with ~prefix:"--" option ->
        Error ("unknown check option " ^ option)
    | value :: rest ->
        begin match path with
        | None -> loop (Some value) as_json rest
        | Some _ -> Error ("unexpected check argument " ^ value)
        end
  in
  match loop None false arguments with
  | Error _ as error -> error
  | Ok (Some path, as_json) -> Ok (path, as_json)
  | Ok (None, _) -> Error "check requires a contract file path"

let run_check arguments =
  match parse_check_arguments arguments with
  | Error message ->
      prerr_endline ("centl: " ^ message);
      prerr_endline "Usage: centl check FILE [--json]";
      exit 2
  | Ok (path, as_json) ->
      begin try
        let lines = read_check_file path in
        if
          not
            (List.exists
               (function Check_assert _ -> true | Check_define _ -> false)
               lines)
        then begin
          let validation_session = Centl_engine.create_session () in
          let rec validate_definitions = function
            | [] ->
                prerr_endline ("centl: no assertions in " ^ path);
                exit 2
            | Check_assert _ :: rest -> validate_definitions rest
            | Check_define { line_number; definition } :: rest ->
                begin match
                  Centl_engine.evaluate_in_session_outcome_with_limits
                    ~intent:Centl_engine.Define_only
                    Centl_engine.default_evaluation_limits validation_session
                    definition
                with
                | Ok _ -> validate_definitions rest
                | Error error ->
                    Printf.printf "line %d: ERROR %s\n" line_number
                      (Centl_engine.error_text error);
                    exit 2
                end
          in
          validate_definitions lines
        end;
        let session = Centl_engine.create_session () in
        let failures = ref 0 in
        let operational_failure = ref false in
        let results = ref [] in
        List.iter
          (fun line ->
            match line with
            | Check_define { line_number; definition } ->
                begin match
                  Centl_engine.evaluate_in_session_outcome_with_limits
                    ~intent:Centl_engine.Define_only
                    Centl_engine.default_evaluation_limits session definition
                with
                | Error error ->
                    incr failures;
                    operational_failure := true;
                    let entry =
                      `Assoc
                        [
                          ("line", `Int line_number);
                          ("kind", `String "define");
                          ("ok", `Bool false);
                          ("error", Centl_engine.json_of_error error);
                        ]
                    in
                    results := entry :: !results;
                    if not as_json then
                      Printf.printf "line %d: ERROR %s\n" line_number
                        (Centl_engine.error_text error)
                | Ok _ ->
                    let entry =
                      `Assoc
                        [
                          ("line", `Int line_number);
                          ("kind", `String "define");
                          ("ok", `Bool true);
                          ("definition", `String definition);
                        ]
                    in
                    results := entry :: !results;
                    if not as_json then
                      Printf.printf "line %d: defined\n" line_number
                end
            | Check_assert assertion ->
                let fields =
                  [
                    ("left", `String assertion.left);
                    ("relation", `String assertion.relation);
                    ("right", `String assertion.right);
                  ]
                in
                let fields =
                  match assertion.variable with
                  | None -> fields
                  | Some (name, domain) ->
                      fields
                      @ [
                          ( "variables",
                            `List
                              [
                                `Assoc
                                  [
                                    ("name", `String name);
                                    ("domain", `String domain);
                                  ];
                              ] );
                        ]
                in
                begin match Centl_verify.verify session fields with
                | Error error ->
                    incr failures;
                    operational_failure := true;
                    let entry =
                      `Assoc
                        [
                          ("line", `Int assertion.line_number);
                          ("kind", `String "assert");
                          ("ok", `Bool false);
                          ("error", Centl_engine.json_of_error error);
                        ]
                    in
                    results := entry :: !results;
                    if not as_json then
                      Printf.printf "line %d: ERROR %s\n" assertion.line_number
                        (Centl_engine.error_text error)
                | Ok verification ->
                    let verdict =
                      Centl_verify.verdict_name verification.verdict
                    in
                    if verification.verdict <> Centl_verify.Verified then
                      incr failures;
                    let entry =
                      `Assoc
                        [
                          ("line", `Int assertion.line_number);
                          ("kind", `String "assert");
                          ("ok", `Bool true);
                          ( "verification",
                            Centl_verify.json_of_verification verification );
                        ]
                    in
                    results := entry :: !results;
                    if not as_json then
                      Printf.printf "line %d: %s\n" assertion.line_number
                        verdict
                end)
          lines;
        if as_json then
          print_json
            (`Assoc
               [
                 ("version", `Int 1);
                 ("ok", `Bool (!failures = 0));
                 ("path", `String path);
                 ("failures", `Int !failures);
                 ("results", `List (List.rev !results));
               ]);
        if !operational_failure then exit 2
        else if !failures = 0 then exit 0
        else exit 1
      with
      | Sys_error message ->
          prerr_endline ("centl: " ^ message);
          exit 2
      | Failure message ->
          prerr_endline ("centl: " ^ message);
          exit 2
      end

let () =
  let arguments = Array.to_list Sys.argv |> List.tl in
  match arguments with
  | "verify" :: verify_arguments -> run_verify verify_arguments
  | "check" :: check_arguments -> run_check check_arguments
  | _ ->
      begin match parse_arguments arguments with
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
          let result =
            match (command.file, expression, command.mode) with
            | Some _, _, (Serve | Mcp) ->
                prerr_endline "centl: --serve and --mcp do not accept --file";
                Failed
            | None, expression, (Serve | Mcp) when expression <> "" ->
                prerr_endline
                  "centl: --serve and --mcp do not accept an expression";
                Failed
            | Some _, expression, _ when expression <> "" ->
                prerr_endline
                  "centl: use either --file or an expression, not both";
                Failed
            | Some path, _, mode ->
                begin try run_file ~color mode path
                with Sys_error message ->
                  prerr_endline ("centl: " ^ message);
                  Failed
                end
            | None, expression, Human when expression <> "" ->
                evaluate_human_in_session ~color
                  (Centl_engine.create_session ())
                  expression
            | None, expression, Json when expression <> "" ->
                evaluate_json expression
            | None, _, Json -> if run_json_stream () then Success else Failed
            | None, _, Serve -> if run_serve () then Success else Failed
            | None, _, Mcp -> if run_mcp () then Success else Failed
            | None, _, Human when Unix.isatty Unix.stdin ->
                repl ~color ~persistent_history:command.persistent_history ();
                Success
            | None, _, Human -> run_channel ~color Human "standard input" stdin
          in
          exit (statement_result_exit result)
      end
