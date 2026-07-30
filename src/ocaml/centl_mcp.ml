let protocol_version = "2025-11-25"

let supported_versions =
  [ "2025-11-25"; "2025-06-18"; "2025-03-26"; "2024-11-05" ]

type state = {
  protocol : Centl_protocol.state;
  mutable negotiated : string option;
  mutable initialized : bool;
}

let create ?limits () =
  {
    protocol = Centl_protocol.create ?limits ();
    negotiated = None;
    initialized = false;
  }

let protocol_state state = state.protocol

let jsonrpc_result id result =
  `Assoc [ ("jsonrpc", `String "2.0"); ("id", id); ("result", result) ]

let jsonrpc_error id code message =
  `Assoc
    [
      ("jsonrpc", `String "2.0");
      ("id", id);
      ("error", `Assoc [ ("code", `Int code); ("message", `String message) ]);
    ]

let request_id fields =
  match List.assoc_opt "id" fields with
  | Some ((`String _ | `Int _ | `Intlit _) as id) -> Ok (Some id)
  | Some _ -> Error "id must be a string or integer"
  | None -> Ok None

let tool_output_schema =
  `Assoc
    [
      ("type", `String "object");
      ( "properties",
        `Assoc
          [
            ("version", `Assoc [ ("type", `String "integer") ]);
            ("ok", `Assoc [ ("type", `String "boolean") ]);
            ("value", `Assoc [ ("type", `String "object") ]);
            ("error", `Assoc [ ("type", `String "object") ]);
            ("session", `Assoc [ ("type", `String "object") ]);
          ] );
      ("required", `List [ `String "version"; `String "ok"; `String "session" ]);
      ("additionalProperties", `Bool true);
    ]

let limits_schema =
  let integer minimum maximum description =
    `Assoc
      [
        ("type", `String "integer");
        ("minimum", `Int minimum);
        ("maximum", `Int maximum);
        ("description", `String description);
      ]
  in
  let limits = Centl_protocol.default_server_limits.evaluation in
  `Assoc
    [
      ("type", `String "object");
      ("additionalProperties", `Bool false);
      ( "properties",
        `Assoc
          [
            ( "max_source_bytes",
              integer 1 limits.max_source_bytes
                "Maximum UTF-8 source bytes for this calculation." );
            ( "max_expression_nodes",
              integer 1 limits.max_expression_nodes
                "Maximum expression nodes after session expansion." );
            ( "max_exact_bits",
              integer 1 limits.max_exact_bits
                "Maximum estimated bits in an exact result." );
            ( "max_integer_iterations",
              integer 1 limits.max_integer_iterations
                "Maximum iterations for factorial, combinatorics, or sequences."
            );
            ( "max_bindings",
              integer 0 limits.max_bindings
                "Maximum immutable definitions in this session." );
            ( "max_precision_digits",
              integer 1 limits.max_precision_digits
                "Maximum requested significant decimal digits." );
            ( "max_working_bits",
              integer 64 limits.max_working_bits
                "Maximum Arb working precision in bits." );
          ] );
    ]

let calculate_tool =
  `Assoc
    [
      ("name", `String "centl_calculate");
      ("title", `String "Calculate with CENTL");
      ( "description",
        `String
          "Evaluate exact mathematics or define an immutable session value or \
           function. Approximation is rigorous and explicit." );
      ( "inputSchema",
        `Assoc
          [
            ("type", `String "object");
            ("additionalProperties", `Bool false);
            ( "properties",
              `Assoc
                [
                  ( "expression",
                    `Assoc
                      [
                        ("type", `String "string");
                        ( "description",
                          `String "A CENTL expression or definition." );
                      ] );
                  ("limits", limits_schema);
                ] );
            ("required", `List [ `String "expression" ]);
          ] );
      ("outputSchema", tool_output_schema);
      ( "annotations",
        `Assoc
          [
            ("readOnlyHint", `Bool false);
            ("destructiveHint", `Bool false);
            ("idempotentHint", `Bool false);
            ("openWorldHint", `Bool false);
          ] );
    ]

let reset_tool =
  `Assoc
    [
      ("name", `String "centl_reset");
      ("title", `String "Reset CENTL session");
      ("description", `String "Forget every definition in this CENTL process.");
      ( "inputSchema",
        `Assoc
          [
            ("type", `String "object");
            ("properties", `Assoc []);
            ("additionalProperties", `Bool false);
          ] );
      ("outputSchema", tool_output_schema);
      ( "annotations",
        `Assoc
          [
            ("readOnlyHint", `Bool false);
            ("destructiveHint", `Bool true);
            ("idempotentHint", `Bool true);
            ("openWorldHint", `Bool false);
          ] );
    ]

let initialize state id fields =
  if Option.is_some state.negotiated then
    jsonrpc_error id (-32600) "CENTL is already initialized"
  else
    match List.assoc_opt "params" fields with
    | Some (`Assoc parameters) ->
        begin match
          ( List.assoc_opt "protocolVersion" parameters,
            List.assoc_opt "capabilities" parameters,
            List.assoc_opt "clientInfo" parameters )
        with
        | Some (`String requested), Some (`Assoc _), Some (`Assoc client_info)
          when match
                 ( List.assoc_opt "name" client_info,
                   List.assoc_opt "version" client_info )
               with
               | Some (`String _), Some (`String _) -> true
               | _ -> false ->
            let negotiated =
              if List.mem requested supported_versions then requested
              else protocol_version
            in
            state.negotiated <- Some negotiated;
            jsonrpc_result id
              (`Assoc
                 [
                   ("protocolVersion", `String negotiated);
                   ( "capabilities",
                     `Assoc
                       [ ("tools", `Assoc [ ("listChanged", `Bool false) ]) ] );
                   ( "serverInfo",
                     `Assoc
                       [
                         ("name", `String "centl");
                         ("title", `String "CENTL exact mathematics");
                         ("version", `String Centl_version.value);
                       ] );
                   ( "instructions",
                     `String
                       "Use centl_calculate for exact, symbolic, or rigorously \
                        enclosed mathematics. Definitions persist until \
                        centl_reset or process exit." );
                 ])
        | _ ->
            jsonrpc_error id (-32602)
              "initialize requires protocolVersion, capabilities, and \
               clientInfo"
        end
    | _ -> jsonrpc_error id (-32602) "initialize requires params"

let tool_result protocol_response =
  let succeeded = Centl_protocol.ok protocol_response in
  `Assoc
    [
      ( "content",
        `List
          [
            `Assoc
              [
                ("type", `String "text");
                ("text", `String (Centl_protocol.text protocol_response));
              ];
          ] );
      ("structuredContent", protocol_response);
      ("isError", `Bool (not succeeded));
    ]

let calculate state id arguments =
  let unknown =
    List.find_opt
      (fun (name, _) -> not (List.mem name [ "expression"; "limits" ]))
      arguments
  in
  match (unknown, List.assoc_opt "expression" arguments) with
  | Some (name, _), _ ->
      jsonrpc_error id (-32602) ("unknown centl_calculate argument " ^ name)
  | None, Some (`String expression) ->
      let fields =
        [ ("version", `Int 1); ("expression", `String expression) ]
      in
      let fields =
        match List.assoc_opt "limits" arguments with
        | None -> fields
        | Some limits -> fields @ [ ("limits", limits) ]
      in
      Centl_protocol.handle_json state.protocol (`Assoc fields)
      |> tool_result |> jsonrpc_result id
  | None, _ -> jsonrpc_error id (-32602) "centl_calculate requires expression"

let reset state id arguments =
  if arguments <> [] then
    jsonrpc_error id (-32602) "centl_reset accepts no arguments"
  else
    Centl_protocol.handle_json state.protocol
      (`Assoc [ ("version", `Int 1); ("op", `String "reset") ])
    |> tool_result |> jsonrpc_result id

let call_tool state id fields =
  match List.assoc_opt "params" fields with
  | Some (`Assoc parameters) ->
      begin match
        (List.assoc_opt "name" parameters, List.assoc_opt "arguments" parameters)
      with
      | Some (`String "centl_calculate"), Some (`Assoc arguments) ->
          calculate state id arguments
      | Some (`String "centl_calculate"), None ->
          jsonrpc_error id (-32602) "centl_calculate requires arguments"
      | Some (`String "centl_reset"), Some (`Assoc arguments) ->
          reset state id arguments
      | Some (`String "centl_reset"), None -> reset state id []
      | Some (`String name), _ ->
          jsonrpc_error id (-32602) ("unknown tool " ^ name)
      | _ -> jsonrpc_error id (-32602) "tools/call requires a tool name"
      end
  | _ -> jsonrpc_error id (-32602) "tools/call requires params"

let handle_request state id method_name fields =
  match method_name with
  | "initialize" -> initialize state id fields
  | "ping" -> jsonrpc_result id (`Assoc [])
  | _ when not state.initialized ->
      jsonrpc_error id (-32002) "CENTL is not initialized"
  | "tools/list" ->
      jsonrpc_result id
        (`Assoc [ ("tools", `List [ calculate_tool; reset_tool ]) ])
  | "tools/call" -> call_tool state id fields
  | _ -> jsonrpc_error id (-32601) ("method not found: " ^ method_name)

let handle_notification state method_name =
  match method_name with
  | "notifications/initialized" when Option.is_some state.negotiated ->
      state.initialized <- true
  | _ -> ()

let handle_json state = function
  | `Assoc fields ->
      begin match
        (List.assoc_opt "jsonrpc" fields, List.assoc_opt "method" fields)
      with
      | Some (`String "2.0"), Some (`String method_name) ->
          begin match request_id fields with
          | Error message -> Some (jsonrpc_error `Null (-32600) message)
          | Ok (Some id) -> Some (handle_request state id method_name fields)
          | Ok None ->
              handle_notification state method_name;
              None
          end
      | _ -> Some (jsonrpc_error `Null (-32600) "invalid JSON-RPC request")
      end
  | _ -> Some (jsonrpc_error `Null (-32600) "invalid JSON-RPC request")

let handle_line state line =
  if Centl_protocol.admit state.protocol then
    try Yojson.Safe.from_string line |> handle_json state
    with Yojson.Json_error _ ->
      Some (jsonrpc_error `Null (-32700) "parse error")
  else
    try
      match Yojson.Safe.from_string line with
      | `Assoc fields ->
          begin match request_id fields with
          | Ok None -> None
          | Ok (Some id) ->
              Some
                (jsonrpc_error id (-32000)
                   "the process has reached its request limit")
          | Error message -> Some (jsonrpc_error `Null (-32600) message)
          end
      | _ -> Some (jsonrpc_error `Null (-32600) "invalid JSON-RPC request")
    with Yojson.Json_error _ ->
      Some (jsonrpc_error `Null (-32700) "parse error")

let oversized_line state =
  ignore (Centl_protocol.admit state.protocol);
  Some (jsonrpc_error `Null (-32600) "the request exceeds the byte limit")
