type server_limits = {
  max_request_bytes : int;
  max_requests : int;
  evaluation : Centl_engine.evaluation_limits;
}

let default_server_limits =
  {
    max_request_bytes = 65_536;
    max_requests = 10_000;
    evaluation = Centl_engine.default_evaluation_limits;
  }

type state = {
  session : Centl_engine.session;
  limits : server_limits;
  mutable requests : int;
}

let create ?(limits = default_server_limits) () =
  { session = Centl_engine.create_session (); limits; requests = 0 }

let session state = state.session
let limits state = state.limits

let json_error code message =
  Centl_engine.json_of_evaluation (Error { code; message; position = None })

let rec insert_after_version id = function
  | [] -> [ ("id", id) ]
  | (("version", _) as version) :: rest -> version :: ("id", id) :: rest
  | field :: rest -> field :: insert_after_version id rest

let with_id id = function
  | `Assoc fields ->
      begin match id with
      | None -> `Assoc fields
      | Some id -> `Assoc (insert_after_version id fields)
      end
  | json -> json

let with_session state = function
  | `Assoc fields ->
      `Assoc
        (fields
        @ [
            ( "session",
              `Assoc
                [
                  ( "definitions",
                    `Int (Centl_engine.session_binding_count state.session) );
                  ("requests", `Int state.requests);
                ] );
          ])
  | json -> json

let response state ?id json = json |> with_id id |> with_session state

let invalid state ?id message =
  response state ?id (json_error "invalid_request" message)

let resource_failure state ?id message =
  response state ?id (json_error "resource_limit" message)

let admit state =
  if state.requests >= state.limits.max_requests then false
  else begin
    state.requests <- state.requests + 1;
    true
  end

let request_id fields =
  match List.assoc_opt "id" fields with
  | None -> Ok None
  | Some ((`String _ | `Int _ | `Intlit _) as id) -> Ok (Some id)
  | Some _ -> Error "id must be a string or integer"

let bounded_int fields name ~minimum ~maximum ~default =
  match List.assoc_opt name fields with
  | None -> Ok default
  | Some (`Int value) when value >= minimum && value <= maximum -> Ok value
  | Some _ ->
      Error
        (Printf.sprintf "limits.%s must be an integer between %d and %d" name
           minimum maximum)

let request_limits state fields =
  let ( let* ) result next = Result.bind result next in
  match List.assoc_opt "limits" fields with
  | None -> Ok state.limits.evaluation
  | Some (`Assoc requested) ->
      let allowed =
        [
          "max_source_bytes";
          "max_expression_nodes";
          "max_exact_bits";
          "max_integer_iterations";
          "max_bindings";
          "max_precision_digits";
          "max_working_bits";
        ]
      in
      begin match
        List.find_opt (fun (name, _) -> not (List.mem name allowed)) requested
      with
      | Some (name, _) -> Error ("unknown limit " ^ name)
      | None ->
          let ceiling = state.limits.evaluation in
          let* max_source_bytes =
            bounded_int requested "max_source_bytes" ~minimum:1
              ~maximum:ceiling.max_source_bytes
              ~default:ceiling.max_source_bytes
          in
          let* max_expression_nodes =
            bounded_int requested "max_expression_nodes" ~minimum:1
              ~maximum:ceiling.max_expression_nodes
              ~default:ceiling.max_expression_nodes
          in
          let* max_exact_bits =
            bounded_int requested "max_exact_bits" ~minimum:1
              ~maximum:ceiling.max_exact_bits ~default:ceiling.max_exact_bits
          in
          let* max_integer_iterations =
            bounded_int requested "max_integer_iterations" ~minimum:1
              ~maximum:ceiling.max_integer_iterations
              ~default:ceiling.max_integer_iterations
          in
          let* max_bindings =
            bounded_int requested "max_bindings" ~minimum:0
              ~maximum:ceiling.max_bindings ~default:ceiling.max_bindings
          in
          let* max_precision_digits =
            bounded_int requested "max_precision_digits" ~minimum:1
              ~maximum:ceiling.max_precision_digits
              ~default:ceiling.max_precision_digits
          in
          let* max_working_bits =
            bounded_int requested "max_working_bits" ~minimum:64
              ~maximum:ceiling.max_working_bits
              ~default:ceiling.max_working_bits
          in
          Ok
            {
              Centl_engine.max_source_bytes;
              max_expression_nodes;
              max_exact_bits;
              max_integer_iterations;
              max_bindings;
              max_precision_digits;
              max_working_bits;
            }
      end
  | Some _ -> Error "limits must be an object"

let operation fields =
  match List.assoc_opt "op" fields with
  | None -> Ok "evaluate"
  | Some (`String operation) -> Ok operation
  | Some _ -> Error "op must be a string"

let session_result state id evaluation =
  Centl_engine.json_of_session_evaluation evaluation |> response state ?id

let describe state id =
  let evaluation = state.limits.evaluation in
  response state ?id
    (`Assoc
       [
         ("version", `Int 1);
         ("ok", `Bool true);
         ( "capabilities",
           `Assoc
             [
               ("transport", `String "jsonl");
               ("stateful", `Bool true);
               ( "operations",
                 `List
                   (List.map
                      (fun operation -> `String operation)
                      [ "evaluate"; "reset"; "describe"; "ping" ]) );
               ( "limits",
                 `Assoc
                   [
                     ("max_request_bytes", `Int state.limits.max_request_bytes);
                     ("max_requests", `Int state.limits.max_requests);
                     ("max_source_bytes", `Int evaluation.max_source_bytes);
                     ( "max_expression_nodes",
                       `Int evaluation.max_expression_nodes );
                     ("max_exact_bits", `Int evaluation.max_exact_bits);
                     ( "max_integer_iterations",
                       `Int evaluation.max_integer_iterations );
                     ("max_bindings", `Int evaluation.max_bindings);
                     ( "max_precision_digits",
                       `Int evaluation.max_precision_digits );
                     ("max_working_bits", `Int evaluation.max_working_bits);
                   ] );
             ] );
       ])

let evaluate state id fields =
  match (List.assoc_opt "expression" fields, request_limits state fields) with
  | Some (`String expression), Ok limits ->
      Centl_engine.evaluate_in_session_with_limits limits state.session
        expression
      |> session_result state id
  | Some (`String _), Error message -> invalid state ?id message
  | None, _ -> invalid state ?id "missing expression"
  | Some _, _ -> invalid state ?id "expression must be a string"

let reset state id fields =
  if Option.is_some (List.assoc_opt "expression" fields) then
    invalid state ?id "reset does not accept an expression"
  else begin
    Centl_engine.reset_session state.session;
    response state ?id
      (`Assoc [ ("version", `Int 1); ("ok", `Bool true); ("reset", `Bool true) ])
  end

let ping state id =
  response state ?id
    (`Assoc [ ("version", `Int 1); ("ok", `Bool true); ("pong", `Bool true) ])

let handle_json state = function
  | `Assoc fields ->
      begin match request_id fields with
      | Error message -> invalid state message
      | Ok id ->
          begin match List.assoc_opt "version" fields with
          | Some (`Int 1) ->
              begin match operation fields with
              | Error message -> invalid state ?id message
              | Ok "evaluate" -> evaluate state id fields
              | Ok "reset" -> reset state id fields
              | Ok "describe" -> describe state id
              | Ok "ping" -> ping state id
              | Ok name -> invalid state ?id ("unknown operation " ^ name)
              end
          | Some (`Int _) -> invalid state ?id "unsupported protocol version"
          | _ -> invalid state ?id "version must be 1"
          end
      end
  | _ -> invalid state "request must be a JSON object"

let handle_line state line =
  if admit state then
    try Yojson.Safe.from_string line |> handle_json state
    with Yojson.Json_error message ->
      invalid state ("invalid JSON: " ^ message)
  else
    let id =
      try
        match Yojson.Safe.from_string line with
        | `Assoc fields ->
            begin match request_id fields with Ok id -> id | Error _ -> None
            end
        | _ -> None
      with Yojson.Json_error _ -> None
    in
    resource_failure state ?id "the process has reached its request limit"

let oversized_line state =
  if not (admit state) then
    resource_failure state "the process has reached its request limit"
  else resource_failure state "the request exceeds the byte limit"

let ok = function
  | `Assoc fields -> List.assoc_opt "ok" fields = Some (`Bool true)
  | _ -> false

let text = function
  | `Assoc fields ->
      begin match List.assoc_opt "value" fields with
      | Some (`Assoc value) ->
          begin match List.assoc_opt "text" value with
          | Some (`String text) -> text
          | _ -> Yojson.Safe.to_string (`Assoc fields)
          end
      | _ ->
          begin match List.assoc_opt "error" fields with
          | Some (`Assoc error) ->
              begin match List.assoc_opt "message" error with
              | Some (`String message) -> message
              | _ -> Yojson.Safe.to_string (`Assoc fields)
              end
          | _ -> Yojson.Safe.to_string (`Assoc fields)
          end
      end
  | json -> Yojson.Safe.to_string json

type input = End | Line of string | Oversized

let read_line channel max_bytes =
  let buffer = Buffer.create (min max_bytes 4_096) in
  let rec read length oversized =
    match input_char channel with
    | '\n' -> if oversized then Oversized else Line (Buffer.contents buffer)
    | character ->
        if length < max_bytes then Buffer.add_char buffer character;
        read (length + 1) (oversized || length >= max_bytes)
    | exception End_of_file ->
        if length = 0 && not oversized then End
        else if oversized then Oversized
        else Line (Buffer.contents buffer)
  in
  read 0 false
