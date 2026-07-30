type mode = Human | Json
type color_mode = Auto | Always | Never

let version = "0.7.0"

type command = {
  mode : mode;
  color : color_mode;
  file : string option;
  expression_parts : string list;
}

let usage =
  "Usage: centl [--json] [--syntax] [--color=auto|always|never] [--file PATH] \
   [EXPRESSION]"

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
    | "--json" :: rest -> loop { command with mode = Json } rest
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
    (Printf.sprintf
       "CENTL %s — exact mathematics and rigorous real enclosures" version);
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
        | Json, _ | Human, Never -> false
        | Human, Always -> true
        | Human, Auto ->
            Unix.isatty Unix.stdout
            && Option.is_none (Sys.getenv_opt "NO_COLOR")
            && Sys.getenv_opt "TERM" <> Some "dumb"
      in
      let expression = String.concat " " command.expression_parts in
      let ok =
        match (command.file, expression, command.mode) with
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
        | None, _, Human when Unix.isatty Unix.stdin ->
            repl ~color ();
            true
        | None, _, Human -> run_channel ~color Human "standard input" stdin
      in
      if not ok then exit 2
