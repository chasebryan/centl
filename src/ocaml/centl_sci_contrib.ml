type mode = Off | Diagnostics | Examples

type error = { code : string; message : string }

let fail code message = Error { code; message }
let string_of_error error = error.code ^ ": " ^ error.message

let mode_text = function
  | Off -> "off"
  | Diagnostics -> "diagnostics"
  | Examples -> "examples"

let mode_of_string text =
  match String.lowercase_ascii (String.trim text) with
  | "off" -> Some Off
  | "diagnostics" -> Some Diagnostics
  | "examples" -> Some Examples
  | _ -> None

let home () =
  match Sys.getenv_opt "HOME" with
  | Some value when String.trim value <> "" -> Some value
  | _ -> None

let base_dir env_name fallback_suffix =
  match Sys.getenv_opt env_name with
  | Some value when String.trim value <> "" -> Some value
  | _ -> Option.map (fun root -> Filename.concat root fallback_suffix) (home ())

let config_dir () =
  Option.map (fun root -> Filename.concat root "centl-sci")
    (base_dir "XDG_CONFIG_HOME" ".config")

let state_dir () =
  Option.map (fun root -> Filename.concat root "centl-sci/contributions")
    (base_dir "XDG_STATE_HOME" ".local/state")

let config_path () = Option.map (fun dir -> Filename.concat dir "contribution.json") (config_dir ())
let pending_path () = Option.map (fun dir -> Filename.concat dir "pending.jsonl") (state_dir ())

let rec ensure_dir path =
  if Sys.file_exists path then Ok ()
  else
    let parent = Filename.dirname path in
    let parent_result = if parent = path then Ok () else ensure_dir parent in
    match parent_result with
    | Error _ as error -> error
    | Ok () ->
        begin
          try
            Unix.mkdir path 0o700;
            Ok ()
          with
          | Unix.Unix_error (Unix.EEXIST, _, _) -> Ok ()
          | Unix.Unix_error (code, function_name, argument) ->
              fail "contribution_io"
                (Printf.sprintf "%s(%s): %s" function_name argument
                   (Unix.error_message code))
        end

let write_private path text =
  match ensure_dir (Filename.dirname path) with
  | Error _ as error -> error
  | Ok () ->
      begin
        try
          let temp = path ^ ".tmp" in
          let descriptor =
            Unix.openfile temp [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC ] 0o600
          in
          let channel = Unix.out_channel_of_descr descriptor in
          output_string channel text;
          close_out channel;
          Unix.rename temp path;
          Ok ()
        with Unix.Unix_error (code, function_name, argument) ->
          fail "contribution_io"
            (Printf.sprintf "%s(%s): %s" function_name argument
               (Unix.error_message code))
      end

let set_mode mode =
  match config_path () with
  | None -> fail "contribution_configuration" "HOME/XDG_CONFIG_HOME is unavailable"
  | Some path ->
      let payload =
        `Assoc
          [
            ("schema_version", `Int 1);
            ("mode", `String (mode_text mode));
            ("network_upload", `Bool false);
          ]
        |> Yojson.Safe.pretty_to_string
      in
      write_private path (payload ^ "\n")

let load_mode () =
  match config_path () with
  | None -> Off
  | Some path ->
      if not (Sys.file_exists path) then Off
      else
        begin
          try
            match Yojson.Safe.from_file path with
            | `Assoc fields ->
                begin match List.assoc_opt "mode" fields with
                | Some (`String text) -> Option.value (mode_of_string text) ~default:Off
                | _ -> Off
                end
            | _ -> Off
          with _ -> Off
        end

let append_private path json =
  match ensure_dir (Filename.dirname path) with
  | Error _ as error -> error
  | Ok () ->
      begin
        try
          let descriptor =
            Unix.openfile path [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_APPEND ] 0o600
          in
          Unix.fchmod descriptor 0o600;
          let channel = Unix.out_channel_of_descr descriptor in
          output_string channel (Yojson.Safe.to_string json);
          output_char channel '\n';
          close_out channel;
          Ok ()
        with Unix.Unix_error (code, function_name, argument) ->
          fail "contribution_io"
            (Printf.sprintf "%s(%s): %s" function_name argument
               (Unix.error_message code))
      end

let common_fields ~mode ~source ?backend ~problem =
  [
    ("schema_version", `Int 1);
    ("recorded_unix_seconds", `Float (Unix.gettimeofday ()));
    ("sci_version", `String "0.0.1");
    ("capture_mode", `String (mode_text mode));
    ("network_upload", `Bool false);
    ("interpreter_path", `String source);
    ("problem_bytes", `Int (String.length problem));
  ]
  @ match backend with None -> [] | Some value -> [ ("interpreter_backend", `String value) ]

let diagnostics_json ~source ?backend ~problem ~ir ~outcome =
  let fields =
    common_fields ~mode:Diagnostics ~source ?backend ~problem
    @ [
        ("domain", `String (Centl_sci_ir.domain ir));
        ("problem_class", `String (Centl_sci_ir.problem_class ir));
        ("operation", `String (Centl_sci_ir.operation ir));
        ("status", `String (Centl_sci_runtime.status_text outcome.Centl_sci_runtime.status));
      ]
  in
  `Assoc fields

let examples_json ~source ?backend ~problem ~ir ~outcome =
  let fields =
    common_fields ~mode:Examples ~source ?backend ~problem
    @ [
        ("contains_user_problem_text", `Bool true);
        ("problem", `String problem);
        ("interpretation", Centl_sci_ir.to_json ir);
        ("status", `String (Centl_sci_runtime.status_text outcome.Centl_sci_runtime.status));
      ]
  in
  let fields =
    match outcome.Centl_sci_runtime.response with
    | None -> fields
    | Some response -> fields @ [ ("centl_response", response) ]
  in
  `Assoc fields

let record ~source ?backend ~problem ~ir ~outcome () =
  match load_mode () with
  | Off -> Ok ()
  | mode ->
      begin match pending_path () with
      | None -> fail "contribution_configuration" "HOME/XDG_STATE_HOME is unavailable"
      | Some path ->
          let json =
            match mode with
            | Off -> assert false
            | Diagnostics -> diagnostics_json ~source ?backend ~problem ~ir ~outcome
            | Examples -> examples_json ~source ?backend ~problem ~ir ~outcome
          in
          append_private path json
      end

let error_json ~mode ~source ?backend ~problem ~code ~message =
  let fields =
    common_fields ~mode ~source ?backend ~problem
    @ [
        ("event", `String "interpreter_error");
        ("error_code", `String code);
        ("error_message", `String message);
      ]
  in
  let fields =
    match mode with
    | Examples ->
        fields
        @ [ ("contains_user_problem_text", `Bool true); ("problem", `String problem) ]
    | Diagnostics | Off -> fields
  in
  `Assoc fields

let record_interpreter_error ~source ?backend ~problem ~code ~message () =
  match load_mode () with
  | Off -> Ok ()
  | mode ->
      begin match pending_path () with
      | None -> fail "contribution_configuration" "HOME/XDG_STATE_HOME is unavailable"
      | Some path -> append_private path (error_json ~mode ~source ?backend ~problem ~code ~message)
      end

let copy_file source destination =
  match ensure_dir (Filename.dirname destination) with
  | Error _ as error -> error
  | Ok () ->
      begin
        try
          let input = open_in_bin source in
          let descriptor =
            Unix.openfile destination [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC ] 0o600
          in
          let output = Unix.out_channel_of_descr descriptor in
          let buffer = Bytes.create 16_384 in
          let rec loop () =
            match input input buffer 0 (Bytes.length buffer) with
            | 0 -> ()
            | count ->
                output output buffer 0 count;
                loop ()
          in
          loop ();
          close_in input;
          close_out output;
          Ok ()
        with
        | Sys_error message -> fail "contribution_io" message
        | Unix.Unix_error (code, function_name, argument) ->
            fail "contribution_io"
              (Printf.sprintf "%s(%s): %s" function_name argument
                 (Unix.error_message code))
      end

let export_pending destination =
  match pending_path () with
  | None -> fail "contribution_configuration" "HOME/XDG_STATE_HOME is unavailable"
  | Some source ->
      if not (Sys.file_exists source) then fail "contribution_empty" "no pending contribution data"
      else copy_file source destination

let clear_pending () =
  match pending_path () with
  | None -> fail "contribution_configuration" "HOME/XDG_STATE_HOME is unavailable"
  | Some path ->
      if not (Sys.file_exists path) then Ok ()
      else
        begin
          try
            Unix.unlink path;
            Ok ()
          with Unix.Unix_error (code, function_name, argument) ->
            fail "contribution_io"
              (Printf.sprintf "%s(%s): %s" function_name argument
                 (Unix.error_message code))
        end
