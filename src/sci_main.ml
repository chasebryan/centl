let usage =
  "Usage: centl-sci --model MODEL.gguf [--llama-cli PATH] [--json] \
   'mathematics or physics problem'"

let env_or default name =
  match Sys.getenv_opt name with
  | Some value when value <> "" -> value
  | _ -> default

let read_stdin_problem () =
  let buffer = Buffer.create 1_024 in
  let rec loop count =
    match input_char stdin with
    | character ->
        if count >= Centl_sci_llama.max_problem_bytes then begin
          Printf.eprintf "centl-sci: problem exceeds the CENTL-SCi byte limit\n";
          exit 2
        end;
        Buffer.add_char buffer character;
        loop (count + 1)
    | exception End_of_file -> Buffer.contents buffer |> String.trim
  in
  loop 0

let () =
  let model = ref (Sys.getenv_opt "CENTL_SCI_MODEL") in
  let llama_cli = ref (env_or "llama-cli" "CENTL_SCI_LLAMA_CLI") in
  let json_output = ref false in
  let anonymous = ref [] in
  let options =
    [
      ( "--model",
        Arg.String (fun value -> model := Some value),
        "PATH local GGUF model file" );
      ( "--llama-cli",
        Arg.Set_string llama_cli,
        "PATH llama.cpp llama-cli executable (default: llama-cli)" );
      ("--json", Arg.Set json_output, "emit the reproducible structured result");
      ( "--version",
        Arg.Unit
          (fun () ->
            print_endline "CENTL-SCi 0.0.1";
            exit 0),
        "print CENTL-SCi version" );
    ]
  in
  Arg.parse options (fun value -> anonymous := value :: !anonymous) usage;
  let problem =
    match List.rev !anonymous with
    | [] -> read_stdin_problem ()
    | values -> String.concat " " values |> String.trim
  in
  let model =
    match !model with
    | Some value when value <> "" -> value
    | _ ->
        Printf.eprintf
          "centl-sci: a local model is required; use --model or CENTL_SCI_MODEL\n";
        exit 2
  in
  let config = Centl_sci_llama.default ~executable:!llama_cli ~model () in
  match Centl_sci_llama.interpret config problem with
  | Error error ->
      Printf.eprintf "centl-sci: %s\n" (Centl_sci_llama.string_of_error error);
      exit 1
  | Ok ir ->
      let outcome = Centl_sci_runtime.execute ir in
      if !json_output then
        Centl_sci_runtime.to_json ~problem outcome
        |> Yojson.Safe.pretty_to_string |> print_endline
      else Centl_sci_runtime.human ~problem outcome |> print_endline;
      begin match outcome.status with
      | Centl_sci_runtime.Failed -> exit 1
      | _ -> ()
      end
