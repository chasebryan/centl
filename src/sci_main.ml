type color_mode = Auto | Always | Never
type interpretation_source = Fast_path | Model

let usage =
  "Usage: centl-sci [--model MODEL.gguf] [--llama-cli PATH] [--json] \
   [--color=MODE] 'mathematics or physics problem'"

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

let color_enabled = function
  | Always -> true
  | Never -> false
  | Auto ->
      Sys.getenv_opt "NO_COLOR" = None
      && Unix.isatty (Unix.descr_of_out_channel stdout)

let ansi enabled code text =
  if enabled then Printf.sprintf "\027[%sm%s\027[0m" code text else text

let after prefix line =
  String.sub line (String.length prefix) (String.length line - String.length prefix)
  |> String.trim

let source_text = function Fast_path -> "fast" | Model -> "model"

let brand_header color =
  let title =
    ansi color "1;97;44" " CENTL-SCi " ^ ansi color "1;94" "  //  FCF"
  in
  String.concat "\n"
    [
      title;
      ansi color "96" "Free Computation Foundation"
      ^ ansi color "90" "  //  Free for science.";
    ]

let render_line color line =
  if String.starts_with ~prefix:"Status: established" line then
    ansi color "1;32" "OK>" ^ " " ^ ansi color "1;32" "ESTABLISHED"
  else if String.starts_with ~prefix:"Status: unresolved" line then
    ansi color "1;33" "WAIT>" ^ " " ^ ansi color "1;33" "UNRESOLVED"
  else if String.starts_with ~prefix:"Status: unsupported" line then
    ansi color "1;33" "WAIT>" ^ " " ^ ansi color "1;33" "UNSUPPORTED"
  else if String.starts_with ~prefix:"Status: failed" line then
    ansi color "1;31" "ERR>" ^ " " ^ ansi color "1;31" "FAILED"
  else if String.starts_with ~prefix:"Result:" line then
    ansi color "1;94" "=>" ^ " " ^ ansi color "1;97" (after "Result:" line)
  else if String.starts_with ~prefix:"Interpretation:" line then
    ansi color "1;96" "IR>" ^ " " ^ after "Interpretation:" line
  else if String.starts_with ~prefix:"Interpreter assumptions:" line then
    ansi color "1;96" "AS>" ^ " " ^ after "Interpreter assumptions:" line
  else if String.starts_with ~prefix:"CENTL resolution:" line then
    ansi color "1;96" "RS>" ^ " " ^ after "CENTL resolution:" line
  else if String.starts_with ~prefix:"CENTL provenance:" line then
    ansi color "1;96" "PV>" ^ " " ^ ansi color "90" (after "CENTL provenance:" line)
  else if String.starts_with ~prefix:"Reason:" line then
    ansi color "1;33" "WHY>" ^ " " ^ after "Reason:" line
  else line

let branded_human ~color ~problem ~source outcome =
  let body =
    Centl_sci_runtime.human ~problem outcome |> String.split_on_char '\n'
    |> List.map (render_line color) |> String.concat "\n"
  in
  let source_line =
    ansi color "1;96" "RT>" ^ " "
    ^ ansi color (match source with Fast_path -> "1;32" | Model -> "1;94")
        (String.uppercase_ascii (source_text source))
  in
  String.concat "\n"
    [
      brand_header color;
      "";
      ansi color "1;94" "SCI>" ^ " " ^ ansi color "97" problem;
      source_line;
      "";
      body;
    ]

let with_interpreter_path source = function
  | `Assoc fields ->
      `Assoc (("interpreter_path", `String (source_text source)) :: fields)
  | json -> json

let () =
  let model = ref (Sys.getenv_opt "CENTL_SCI_MODEL") in
  let llama_cli = ref (env_or "llama-cli" "CENTL_SCI_LLAMA_CLI") in
  let json_output = ref false in
  let force_model = ref false in
  let color = ref Auto in
  let anonymous = ref [] in
  let options =
    [
      ( "--model",
        Arg.String (fun value -> model := Some value),
        "PATH local GGUF model file; required only when the fast path cannot admit the problem" );
      ( "--llama-cli",
        Arg.Set_string llama_cli,
        "PATH llama.cpp llama-cli executable (default: llama-cli)" );
      ("--json", Arg.Set json_output, "emit the reproducible structured result");
      ( "--force-model",
        Arg.Set force_model,
        "bypass deterministic interpretation; intended for model qualification/debugging" );
      ("--color", Arg.Unit (fun () -> color := Always), "force ANSI color");
      ("--no-color", Arg.Unit (fun () -> color := Never), "disable ANSI color");
      ("--color=auto", Arg.Unit (fun () -> color := Auto), "automatic ANSI color");
      ( "--color=always",
        Arg.Unit (fun () -> color := Always),
        "force ANSI color" );
      ( "--color=never",
        Arg.Unit (fun () -> color := Never),
        "disable ANSI color" );
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
  let model_interpret () =
    let model =
      match !model with
      | Some value when value <> "" -> value
      | _ ->
          Printf.eprintf
            "centl-sci: this problem requires the semantic model; use --model or CENTL_SCI_MODEL\n";
          exit 2
    in
    let config = Centl_sci_llama.default ~executable:!llama_cli ~model () in
    match Centl_sci_llama.interpret config problem with
    | Error error ->
        Printf.eprintf "centl-sci: %s\n" (Centl_sci_llama.string_of_error error);
        exit 1
    | Ok ir -> (Model, ir)
  in
  let source, ir =
    if !force_model then model_interpret ()
    else
      match Centl_sci_fastpath.interpret problem with
      | Some ir -> (Fast_path, ir)
      | None -> model_interpret ()
  in
  let outcome = Centl_sci_runtime.execute ir in
  if !json_output then
    Centl_sci_runtime.to_json ~problem outcome
    |> with_interpreter_path source |> Yojson.Safe.pretty_to_string
    |> print_endline
  else
    branded_human ~color:(color_enabled !color) ~problem ~source outcome
    |> print_endline;
  begin match outcome.status with
  | Centl_sci_runtime.Failed -> exit 1
  | _ -> ()
  end
