type interpretation_source = Fast_path | Model_cli | Model_server

type interpreter_error = {
  exit_code : int;
  human_message : string;
  detail_message : string;
  diagnostic : string;
}

let usage =
  "Usage: centl-sci [--mode MODE] [--server-url URL | --model MODEL.gguf] \
   [--details | --explain | --json] [--repl] 'mathematics or physics problem'"

let repl_version = "0.0.2-dev"

let env_or default name =
  match Sys.getenv_opt name with
  | Some value when value <> "" -> value
  | _ -> default

let read_stdin_problem () =
  let buffer = Buffer.create 1_024 in
  let rec loop count =
    match input_char stdin with
    | character ->
        if count >= Centl_sci_llama.max_problem_bytes then
          Error "problem exceeds the CENTL-SCi byte limit"
        else begin
          Buffer.add_char buffer character;
          loop (count + 1)
        end
    | exception End_of_file -> Ok (Buffer.contents buffer |> String.trim)
  in
  loop 0

let stdin_is_tty () =
  try Unix.isatty (Unix.descr_of_in_channel stdin)
  with Unix.Unix_error _ -> false

let source_text = function
  | Fast_path -> "fast"
  | Model_cli | Model_server -> "model"

let backend_text = function
  | Fast_path -> None
  | Model_cli -> Some "llama-cli"
  | Model_server -> Some "llama-server"

let with_interpreter_path source = function
  | `Assoc fields ->
      let fields = ("interpreter_path", `String (source_text source)) :: fields in
      let fields =
        match backend_text source with
        | None -> fields
        | Some backend -> ("interpreter_backend", `String backend) :: fields
      in
      `Assoc fields
  | json -> json

let contribution_or_exit action =
  match action with
  | Ok () -> ()
  | Error error ->
      Printf.eprintf "centl-sci: %s\n" (Centl_sci_contrib.string_of_error error);
      exit 2

let set_contribution_mode mode message =
  contribution_or_exit (Centl_sci_contrib.set_mode mode);
  print_endline message;
  exit 0

let show_contribution_status () =
  Printf.printf "mode=%s\n"
    (Centl_sci_contrib.mode_text (Centl_sci_contrib.load_mode ()));
  begin match Centl_sci_contrib.pending_path () with
  | Some path -> Printf.printf "pending=%s\n" path
  | None -> print_endline "pending=unavailable"
  end;
  print_endline "network_upload=false";
  exit 0

let export_contribution path =
  contribution_or_exit (Centl_sci_contrib.export_pending path);
  Printf.printf "CENTL-SCi contribution export: %s\n" path;
  print_endline "No data was uploaded. Review the exported file before sharing it.";
  exit 0

let clear_contribution () =
  contribution_or_exit (Centl_sci_contrib.clear_pending ());
  print_endline "CENTL-SCi pending contribution data cleared.";
  exit 0

let warn_contribution = function
  | Ok () -> ()
  | Error error ->
      Printf.eprintf "centl-sci: contribution capture warning: %s\n"
        (Centl_sci_contrib.string_of_error error)

let record_interpreter_error ~source ?backend ~problem ~code ~message () =
  warn_contribution
    (Centl_sci_contrib.record_interpreter_error ~source ?backend ~problem ~code
       ~message ())

let human_error ~details error =
  if details then
    String.concat "\n"
      [ error.human_message; ""; "Details:"; "  " ^ error.detail_message ]
  else error.human_message

let print_json_error error = Printf.eprintf "centl-sci: %s\n" error.diagnostic

let sci_history_path () =
  Option.map
    (fun path -> Filename.concat (Filename.dirname path) "sci-history.json")
    (Centl_history.default_path ())

let print_history history =
  match Centl_history.entries history with
  | [] -> print_endline "(history is empty)"
  | entries ->
      List.iteri
        (fun index entry -> Printf.printf "%4d  %s\n" (index + 1) entry)
        entries

let main () =
  let model = ref (Sys.getenv_opt "CENTL_SCI_MODEL") in
  let server_url = ref (Sys.getenv_opt "CENTL_SCI_SERVER_URL") in
  let llama_cli = ref (env_or "llama-cli" "CENTL_SCI_LLAMA_CLI") in
  let curl = ref (env_or "curl" "CENTL_SCI_CURL") in
  let json_output = ref false in
  let details_output = ref false in
  let force_model = ref false in
  let force_repl = ref false in
  let persistent_history = ref true in
  let initial_mode = ref Centl_sci_interaction.Hybrid in
  let anonymous = ref [] in
  let set_mode value =
    match Centl_sci_interaction.parse_mode value with
    | Ok mode -> initial_mode := mode
    | Error message -> raise (Arg.Bad message)
  in
  let options =
    [
      ( "--mode",
        Arg.String set_mode,
        "MODE interaction mode: math, physics, hybrid (default), or build" );
      ( "--model",
        Arg.String (fun value -> model := Some value),
        "PATH local GGUF model file for the cold reference backend" );
      ( "--server-url",
        Arg.String (fun value -> server_url := Some value),
        "URL loopback resident llama-server, for example http://127.0.0.1:8080" );
      ( "--llama-cli",
        Arg.Set_string llama_cli,
        "PATH llama.cpp llama-cli executable (default: llama-cli)" );
      ( "--curl",
        Arg.Set_string curl,
        "PATH curl executable used for loopback resident inference (default: curl)" );
      ("--details", Arg.Set details_output, "show concise scientific details");
      ("--explain", Arg.Set details_output, "show evidence-backed scientific details");
      ("--json", Arg.Set json_output, "emit the reproducible structured result");
      ( "--repl",
        Arg.Set force_repl,
        "start the live scientific problem interpreter even when stdin is not a TTY" );
      ( "--no-history",
        Arg.Clear persistent_history,
        "do not load or save durable CENTL-SCi input history" );
      ( "--force-model",
        Arg.Set force_model,
        "bypass deterministic interpretation; intended for model qualification/debugging" );
      ( "--contribution-off",
        Arg.Unit
          (fun () ->
            set_contribution_mode Centl_sci_contrib.Off
              "CENTL-SCi contribution mode: off. Existing pending data is not deleted."),
        "persistently disable local contribution capture (default)" );
      ( "--contribution-diagnostics",
        Arg.Unit
          (fun () ->
            set_contribution_mode Centl_sci_contrib.Diagnostics
              "CENTL-SCi contribution mode: diagnostics. Problem text is not captured; nothing is uploaded automatically."),
        "opt in to local metadata/error capture without problem text" );
      ( "--contribution-examples",
        Arg.Unit
          (fun () ->
            set_contribution_mode Centl_sci_contrib.Examples
              "CENTL-SCi contribution mode: examples. Raw problem text is captured locally and may contain sensitive information; nothing is uploaded automatically."),
        "opt in to local example capture including raw problem text" );
      ( "--contribution-status",
        Arg.Unit show_contribution_status,
        "show contribution mode and local pending-data path" );
      ( "--contribution-export",
        Arg.String export_contribution,
        "PATH export the pending local JSONL for explicit review/sharing" );
      ( "--contribution-clear",
        Arg.Unit clear_contribution,
        "delete pending local contribution data" );
      ("--color", Arg.Unit (fun () -> ()), "accepted for CLI compatibility");
      ("--no-color", Arg.Unit (fun () -> ()), "accepted for CLI compatibility");
      ("--color=auto", Arg.Unit (fun () -> ()), "accepted for CLI compatibility");
      ("--color=always", Arg.Unit (fun () -> ()), "accepted for CLI compatibility");
      ("--color=never", Arg.Unit (fun () -> ()), "accepted for CLI compatibility");
      ( "--version",
        Arg.Unit
          (fun () ->
            print_endline "CENTL-SCi 0.0.2-dev";
            exit 0),
        "print CENTL-SCi version" );
    ]
  in
  Arg.parse options (fun value -> anonymous := value :: !anonymous) usage;
  if !json_output && !details_output then begin
    Printf.eprintf "centl-sci: --details/--explain and --json are mutually exclusive\n";
    exit 2
  end;
  let model_interpret problem =
    match !server_url with
    | Some url when String.trim url <> "" ->
        let config = Centl_sci_server.default ~curl_executable:!curl ~base_url:url () in
        begin match Centl_sci_server.interpret config problem with
        | Error error ->
            record_interpreter_error ~source:"model" ~backend:"llama-server"
              ~problem ~code:error.code ~message:error.message ();
            Error
              {
                exit_code = 1;
                human_message = "CENTL-SCi could not interpret this problem.";
                detail_message = error.message;
                diagnostic = Centl_sci_server.string_of_error error;
              }
        | Ok ir -> Ok (Model_server, ir)
        end
    | _ ->
        let configured_model =
          match !model with
          | Some value when value <> "" -> Some value
          | _ -> None
        in
        begin match configured_model with
        | None ->
            let message = "no semantic model backend is configured" in
            record_interpreter_error ~source:"deferred" ~problem
              ~code:"semantic_inference_required" ~message ();
            Error
              {
                exit_code = 2;
                human_message = "CENTL-SCi cannot solve this problem yet.";
                detail_message =
                  "Semantic interpretation is required, but no local model backend is configured.";
                diagnostic =
                  "this problem requires semantic inference; configure --server-url/CENTL_SCI_SERVER_URL or --model/CENTL_SCI_MODEL";
              }
        | Some model_path ->
            let config =
              Centl_sci_llama.default ~executable:!llama_cli ~model:model_path ()
            in
            begin match Centl_sci_llama.interpret config problem with
            | Error error ->
                record_interpreter_error ~source:"model" ~backend:"llama-cli"
                  ~problem ~code:error.code ~message:error.message ();
                Error
                  {
                    exit_code = 1;
                    human_message = "CENTL-SCi could not interpret this problem.";
                    detail_message = error.message;
                    diagnostic = Centl_sci_llama.string_of_error error;
                  }
            | Ok ir -> Ok (Model_cli, ir)
            end
        end
  in
  let interpret mode problem =
    let normalized = Centl_sci_interaction.normalize mode problem in
    if !force_model then model_interpret normalized
    else
      match Centl_sci_fastpath.interpret normalized with
      | Some ir -> Ok (Fast_path, ir)
      | None ->
          begin match Centl_sci_interaction.clarification mode normalized with
          | Some message ->
              Error
                {
                  exit_code = 2;
                  human_message = message;
                  detail_message = "The request was classified but is not executable without more information.";
                  diagnostic = "clarification_required";
                }
          | None -> model_interpret normalized
          end
  in
  let execute_problem mode problem =
    match interpret mode problem with
    | Error error -> Error error
    | Ok (source, ir) ->
        let outcome = Centl_sci_runtime.execute ir in
        let contribution =
          match backend_text source with
          | None ->
              Centl_sci_contrib.record ~source:(source_text source) ~problem ~ir
                ~outcome ()
          | Some backend ->
              Centl_sci_contrib.record ~source:(source_text source) ~backend
                ~problem ~ir ~outcome ()
        in
        warn_contribution contribution;
        Ok (source, outcome)
  in
  let print_outcome ~problem ~source outcome =
    if !json_output then
      Centl_sci_runtime.to_json ~problem outcome
      |> with_interpreter_path source
      |> Yojson.Safe.pretty_to_string |> print_endline
    else if !details_output then
      Centl_sci_present.details outcome |> print_endline
    else Centl_sci_present.human outcome |> print_endline
  in
  let run_one problem =
    if problem = "" then begin
      Printf.eprintf "centl-sci: a mathematics or physics problem is required\n";
      exit 2
    end;
    match execute_problem !initial_mode problem with
    | Error error ->
        if !json_output then print_json_error error
        else human_error ~details:!details_output error |> print_endline;
        exit error.exit_code
    | Ok (source, outcome) ->
        print_outcome ~problem ~source outcome;
        begin match outcome.Centl_sci_runtime.status with
        | Centl_sci_runtime.Failed -> exit 1
        | _ -> ()
        end
  in
  let repl () =
    print_endline ("CENTL-SCi v" ^ repl_version);
    print_endline "Free for science.";
    print_newline ();
    let details = ref !details_output in
    let mode = ref !initial_mode in
    let persistent =
      !persistent_history
      && not (Centl_history.environment_disables_persistence ())
    in
    let history =
      Centl_history.create ~persistent ?path:(sci_history_path ()) ()
    in
    let help () =
      print_endline ":help               show session controls";
      print_endline ":mode               show current interaction mode";
      print_endline ":mode math          bias toward mathematics";
      print_endline ":mode physics       bias toward physics";
      print_endline ":mode hybrid        general scientific mode";
      print_endline ":mode build         system construction/extension mode";
      print_endline ":history            show input history";
      print_endline ":clear-history      clear input history";
      print_endline ":details on|off     toggle concise scientific details";
      print_endline ":explain on|off     alias for evidence-backed details";
      print_endline ":quit / :exit       exit"
    in
    let set_repl_mode value =
      match Centl_sci_interaction.parse_mode value with
      | Ok next ->
          mode := next;
          Printf.printf "Mode: %s\n" (Centl_sci_interaction.mode_text next)
      | Error message -> print_endline message
    in
    let rec loop () =
      let prompt = Centl_sci_interaction.prompt !mode in
      let candidates = Centl_sci_interaction.completion_candidates !mode in
      match
        Centl_editor.read_line ~prompt ~history ~candidates
          ~max_bytes:Centl_sci_llama.max_problem_bytes
      with
      | Centl_editor.End_of_input -> ()
      | Centl_editor.Interrupted -> loop ()
      | Centl_editor.Input_limit_exceeded ->
          print_endline "This problem exceeds the CENTL-SCi input limit.";
          loop ()
      | Centl_editor.Submitted line ->
          let problem = String.trim line in
          let command = String.lowercase_ascii problem in
          if problem <> "" then Centl_history.add history problem;
          if command = ":quit" || command = ":exit" then ()
          else if command = ":help" then begin
            help ();
            loop ()
          end
          else if command = ":mode" then begin
            Printf.printf "Mode: %s\n" (Centl_sci_interaction.mode_text !mode);
            loop ()
          end
          else if String.starts_with ~prefix:":mode " command then begin
            let value =
              String.sub command 6 (String.length command - 6) |> String.trim
            in
            set_repl_mode value;
            loop ()
          end
          else if command = ":history" then begin
            print_history history;
            loop ()
          end
          else if command = ":clear-history" then begin
            Centl_history.clear history;
            print_endline "History cleared.";
            loop ()
          end
          else if command = ":details on" || command = ":explain on" then begin
            details := true;
            print_endline "Explanation details on.";
            loop ()
          end
          else if command = ":details off" || command = ":explain off" then begin
            details := false;
            print_endline "Explanation details off.";
            loop ()
          end
          else if String.starts_with ~prefix:":" command then begin
            print_endline "Unknown session control. Use :help.";
            loop ()
          end
          else if problem = "" then loop ()
          else begin
            begin match execute_problem !mode problem with
            | Error error -> human_error ~details:!details error |> print_endline
            | Ok (_, outcome) ->
                if !details then
                  Centl_sci_present.details outcome |> print_endline
                else Centl_sci_present.human outcome |> print_endline
            end;
            loop ()
          end
    in
    loop ()
  in
  let arguments = List.rev !anonymous in
  match arguments with
  | _ :: _ when !force_repl ->
      Printf.eprintf "centl-sci: --repl does not accept a one-shot problem\n";
      exit 2
  | _ :: _ as values -> String.concat " " values |> String.trim |> run_one
  | [] when !force_repl ->
      if !json_output then begin
        Printf.eprintf "centl-sci: --json is not available in the human REPL\n";
        exit 2
      end;
      repl ()
  | [] when stdin_is_tty () ->
      if !json_output then begin
        Printf.eprintf
          "centl-sci: --json requires a problem or non-interactive standard input\n";
        exit 2
      end;
      repl ()
  | [] ->
      begin match read_stdin_problem () with
      | Error message ->
          Printf.eprintf "centl-sci: %s\n" message;
          exit 2
      | Ok problem -> run_one problem
      end
