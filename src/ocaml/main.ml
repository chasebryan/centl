type mode = Human | Json

type command = {
  mode : mode;
  file : string option;
  expression_parts : string list;
}

let usage = "Usage: centl [--json] [--file PATH] [EXPRESSION]"

let print_help () =
  print_endline "CENTL — a calculator first, a language when needed.";
  print_endline "";
  print_endline usage;
  print_endline "";
  print_endline "  centl '0.1 + 0.2'       evaluate an expression";
  print_endline "  centl --file sums.centl evaluate a line-oriented script";
  print_endline "  centl --json '1/3'      emit a versioned JSON result";
  print_endline "  centl --json            read JSON requests from stdin";
  print_endline "  centl                   start the calculator"

let parse_arguments arguments =
  let rec loop command = function
    | [] ->
        Ok { command with expression_parts = List.rev command.expression_parts }
    | "--help" :: _ ->
        print_help ();
        exit 0
    | "--version" :: _ ->
        print_endline "centl 0.1.0-dev";
        exit 0
    | "--json" :: rest -> loop { command with mode = Json } rest
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
  loop { mode = Human; file = None; expression_parts = [] } arguments

let print_json json =
  Yojson.Safe.to_channel stdout json;
  output_char stdout '\n';
  flush stdout

let evaluate_human source =
  match Centl_engine.evaluate source with
  | Ok value ->
      print_endline (Centl_engine.text_of_value value);
      true
  | Error error ->
      prerr_endline ("error: " ^ Centl_engine.error_text error);
      false

let evaluate_json source =
  let result = Centl_engine.evaluate source in
  print_json (Centl_engine.json_of_evaluation result);
  Result.is_ok result

let evaluate mode source =
  match mode with
  | Human -> evaluate_human source
  | Json -> evaluate_json source

let meaningful_line line =
  let line = String.trim line in
  if line = "" || line.[0] = '#' then None else Some line

let run_channel mode name channel =
  let rec lines number =
    match input_line channel with
    | line ->
        begin match meaningful_line line with
        | None -> lines (number + 1)
        | Some expression ->
            if evaluate mode expression then lines (number + 1)
            else begin
              prerr_endline (Printf.sprintf "in %s, line %d" name number);
              false
            end
        end
    | exception End_of_file -> true
  in
  lines 1

let run_file mode path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () -> run_channel mode path channel)

let repl () =
  print_endline "CENTL 0.1.0-dev — exact arithmetic";
  print_endline "Type :help for help or :quit to leave.";
  let rec loop () =
    print_string "centl> ";
    flush stdout;
    match read_line () with
    | exception End_of_file -> print_newline ()
    | line ->
        begin match String.trim line with
        | "" -> loop ()
        | ":quit" | ":q" -> ()
        | ":help" ->
            print_endline
              "Enter an exact expression using +, -, *, /, and parentheses.";
            loop ()
        | expression ->
            ignore (evaluate_human expression);
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
      let expression = String.concat " " command.expression_parts in
      let ok =
        match (command.file, expression, command.mode) with
        | Some _, expression, _ when expression <> "" ->
            prerr_endline "centl: use either --file or an expression, not both";
            false
        | Some path, _, mode ->
            begin try run_file mode path
            with Sys_error message ->
              prerr_endline ("centl: " ^ message);
              false
            end
        | None, expression, mode when expression <> "" ->
            evaluate mode expression
        | None, _, Json -> run_json_stream ()
        | None, _, Human when Unix.isatty Unix.stdin ->
            repl ();
            true
        | None, _, Human -> run_channel Human "standard input" stdin
      in
      if not ok then exit 2
