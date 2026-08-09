type error = { code : string; message : string }

type config = {
  curl_executable : string;
  base_url : string;
  max_tokens : int;
  timeout_seconds : int;
}

let fail code message = Error { code; message }
let string_of_error error = error.code ^ ": " ^ error.message
let max_response_bytes = 65_536

let default ?(curl_executable = "curl") ?(max_tokens = 512)
    ?(timeout_seconds = 300) ~base_url () =
  { curl_executable; base_url; max_tokens; timeout_seconds }

let strip_trailing_slash text =
  let rec finish length =
    if length > 0 && text.[length - 1] = '/' then finish (length - 1) else length
  in
  let length = finish (String.length text) in
  String.sub text 0 length

let parse_loopback_port prefix url =
  if not (String.starts_with ~prefix url) then None
  else
    let suffix =
      String.sub url (String.length prefix) (String.length url - String.length prefix)
    in
    if suffix = "" || not (String.for_all (function '0' .. '9' -> true | _ -> false) suffix)
    then None
    else
      try
        let port = int_of_string suffix in
        if port >= 1 && port <= 65_535 then Some port else None
      with Failure _ -> None

let valid_loopback_url url =
  let url = strip_trailing_slash (String.trim url) in
  match parse_loopback_port "http://127.0.0.1:" url with
  | Some _ -> true
  | None -> Option.is_some (parse_loopback_port "http://localhost:" url)

let validate_config config =
  if config.curl_executable = "" then
    fail "invalid_configuration" "empty curl executable path"
  else if not (valid_loopback_url config.base_url) then
    fail "invalid_configuration"
      "resident inference URL must be loopback http://127.0.0.1:PORT or http://localhost:PORT"
  else if config.max_tokens <= 0 || config.max_tokens > 1_024 then
    fail "invalid_configuration" "max_tokens must be between 1 and 1024"
  else if config.timeout_seconds <= 0 || config.timeout_seconds > 3_600 then
    fail "invalid_configuration" "timeout_seconds must be between 1 and 3600"
  else Ok ()

let request_json config problem =
  `Assoc
    [
      ("prompt", `String (Centl_sci_llama.prompt problem));
      ("n_predict", `Int config.max_tokens);
      ("temperature", `Float 0.0);
      ("seed", `Int 0);
      ("grammar", `String Centl_sci_schema.llama_grammar);
      ("cache_prompt", `Bool true);
      ("stream", `Bool false);
    ]

let endpoint config = strip_trailing_slash config.base_url ^ "/completion"

let argv config problem =
  let body = Yojson.Safe.to_string (request_json config problem) in
  [|
    config.curl_executable;
    "--silent";
    "--show-error";
    "--fail-with-body";
    "--connect-timeout";
    "5";
    "--max-time";
    string_of_int config.timeout_seconds;
    "--header";
    "Content-Type: application/json";
    "--request";
    "POST";
    "--data-binary";
    body;
    endpoint config;
  |]

let read_bounded channel =
  let buffer = Buffer.create 8_192 in
  let bytes = ref 0 in
  let oversized = ref false in
  let chunk = Bytes.create 4_096 in
  let rec loop () =
    match input channel chunk 0 (Bytes.length chunk) with
    | 0 ->
        if !oversized then
          fail "resource_limit" "resident inference response exceeds byte limit"
        else Ok (Buffer.contents buffer)
    | count ->
        if !bytes + count > max_response_bytes then oversized := true
        else if not !oversized then begin
          Buffer.add_subbytes buffer chunk 0 count;
          bytes := !bytes + count
        end;
        loop ()
  in
  loop ()

let status_message = function
  | Unix.WEXITED code -> Printf.sprintf "curl exited with status %d" code
  | Unix.WSIGNALED signal -> Printf.sprintf "curl terminated by signal %d" signal
  | Unix.WSTOPPED signal -> Printf.sprintf "curl stopped by signal %d" signal

let parse_response text =
  try
    match Yojson.Safe.from_string text with
    | `Assoc fields ->
        begin match List.assoc_opt "content" fields with
        | Some (`String content) ->
            begin match Centl_sci_ir.of_string content with
            | Ok ir -> Ok ir
            | Error error ->
                fail error.code
                  ("resident model produced invalid CENTL-SCi IR: " ^ error.message)
            end
        | Some _ -> fail "invalid_model_output" "resident response content must be a string"
        | None -> fail "invalid_model_output" "resident response is missing content"
        end
    | _ -> fail "invalid_model_output" "resident response must be a JSON object"
  with Yojson.Json_error message ->
    fail "invalid_model_output" ("invalid resident response JSON: " ^ message)

let interpret config problem =
  match validate_config config with
  | Error _ as error -> error
  | Ok () ->
      if String.length problem = 0 then fail "invalid_problem" "problem must not be empty"
      else if String.length problem > Centl_sci_llama.max_problem_bytes then
        fail "resource_limit" "problem exceeds the CENTL-SCi byte limit"
      else
        let args = argv config problem in
        begin try
          let channel = Unix.open_process_args_in config.curl_executable args in
          let output = read_bounded channel in
          let status = Unix.close_process_in channel in
          match (output, status) with
          | Error _ as error, _ -> error
          | Ok _, (Unix.WEXITED 0) ->
              begin match output with Ok text -> parse_response text | Error _ -> assert false end
          | Ok _, status -> fail "inference_failed" (status_message status)
        with Unix.Unix_error (code, function_name, argument) ->
          fail "inference_failed"
            (Printf.sprintf "%s(%s): %s" function_name argument
               (Unix.error_message code))
        end
