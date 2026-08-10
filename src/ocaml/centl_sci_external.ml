type invocation = {
  response : Yojson.Safe.t;
  assurance : string;
  program : string;
}

type error =
  | Request_too_large of int
  | Response_too_large of int
  | Spawn_failed of string
  | Protocol_error of string
  | Process_failed of string

let default_max_request_bytes = 1_048_576
let default_max_response_bytes = 1_048_576

let process_status_text = function
  | Unix.WEXITED code -> Printf.sprintf "exited with status %d" code
  | Unix.WSIGNALED signal -> Printf.sprintf "terminated by signal %d" signal
  | Unix.WSTOPPED signal -> Printf.sprintf "stopped by signal %d" signal

let error_text = function
  | Request_too_large bytes ->
      Printf.sprintf
        "external adapter request exceeds the default %d-byte limit: %d bytes"
        default_max_request_bytes bytes
  | Response_too_large bytes ->
      Printf.sprintf
        "external adapter response exceeds the default %d-byte limit: %d bytes"
        default_max_response_bytes bytes
  | Spawn_failed message -> "could not start external adapter: " ^ message
  | Protocol_error message -> "external adapter protocol error: " ^ message
  | Process_failed message -> "external adapter process failed: " ^ message

let invoke ?(max_request_bytes = default_max_request_bytes)
    ?(max_response_bytes = default_max_response_bytes) ~program ~argv request =
  let request_text = Yojson.Safe.to_string request in
  let request_bytes = String.length request_text in
  if request_bytes > max_request_bytes then Error (Request_too_large request_bytes)
  else
    try
      let command = Array.of_list (program :: argv) in
      let channels =
        Unix.open_process_args_full program command (Unix.environment ())
      in
      let stdout_channel, stdin_channel, _stderr_channel = channels in
      output_string stdin_channel request_text;
      output_char stdin_channel '\n';
      flush stdin_channel;
      let response_line = input_line stdout_channel in
      let response_bytes = String.length response_line in
      if response_bytes > max_response_bytes then (
        ignore (Unix.close_process_full channels);
        Error (Response_too_large response_bytes))
      else
        let parsed =
          try Ok (Yojson.Safe.from_string response_line)
          with Yojson.Json_error message -> Error (Protocol_error message)
        in
        let status = Unix.close_process_full channels in
        match (status, parsed) with
        | Unix.WEXITED 0, Ok (`Assoc _ as response) ->
            Ok { response; assurance = "external_backend"; program }
        | Unix.WEXITED 0, Ok _ ->
            Error (Protocol_error "response must be a JSON object")
        | Unix.WEXITED 0, Error error -> Error error
        | _, _ -> Error (Process_failed (process_status_text status))
    with
    | Sys_error message -> Error (Spawn_failed message)
    | Unix.Unix_error (_, _, message) -> Error (Spawn_failed message)
    | End_of_file ->
        Error
          (Protocol_error "adapter closed stdout before one JSONL response")
