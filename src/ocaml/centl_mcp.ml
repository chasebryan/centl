include Centl_mcp_base

let physics_cursor = "centl-physics-v1"
let math_cursor = "centl-math-v1"

let extension_cancellable_request_id tool_name = function
  | `Assoc fields ->
      begin match
        ( List.assoc_opt "jsonrpc" fields,
          List.assoc_opt "id" fields,
          List.assoc_opt "method" fields,
          List.assoc_opt "params" fields )
      with
      | ( Some (`String "2.0"),
          Some ((`String _ | `Int _ | `Intlit _) as id),
          Some (`String "tools/call"),
          Some (`Assoc parameters) ) ->
          begin match List.assoc_opt "name" parameters with
          | Some (`String name) when String.equal name tool_name -> Some id
          | _ -> None
          end
      | _ -> None
      end
  | _ -> None

let physics_cancellable_request_id json =
  extension_cancellable_request_id "centl_physics" json

let math_cancellable_request_id json =
  extension_cancellable_request_id "centl_math" json

let cancellable_request_id json =
  match Centl_mcp_base.cancellable_request_id json with
  | Some _ as id -> id
  | None ->
      begin match physics_cancellable_request_id json with
      | Some _ as id -> id
      | None -> math_cancellable_request_id json
      end

let replace_field name value fields =
  if List.mem_assoc name fields then
    List.map
      (fun (field, current) ->
        if field = name then (field, value) else (field, current))
      fields
  else fields @ [ (name, value) ]

let remove_field name fields =
  List.filter (fun (field, _) -> not (String.equal field name)) fields

let add_physics_cursor = function
  | `Assoc response_fields as response ->
      begin match List.assoc_opt "result" response_fields with
      | Some (`Assoc result_fields) ->
          let result_fields =
            replace_field "nextCursor" (`String physics_cursor) result_fields
          in
          `Assoc (replace_field "result" (`Assoc result_fields) response_fields)
      | _ -> response
      end
  | response -> response

let legacy_capabilities_response = function
  | `Assoc response_fields as response ->
      begin match List.assoc_opt "capabilities" response_fields with
      | Some (`Assoc capabilities) ->
          let capabilities = remove_field "p0_math_gateway" capabilities in
          `Assoc
            (replace_field "capabilities" (`Assoc capabilities) response_fields)
      | _ -> response
      end
  | response -> response

let tools_list_cursor fields =
  match List.assoc_opt "params" fields with
  | None -> Ok None
  | Some (`Assoc parameters) ->
      begin match
        List.find_opt
          (fun (name, _) -> not (List.mem name [ "cursor"; "_meta" ]))
          parameters
      with
      | Some (name, _) -> Error ("unknown tools/list parameter " ^ name)
      | None ->
          begin match List.assoc_opt "_meta" parameters with
          | Some (`Assoc _) | None ->
              begin match List.assoc_opt "cursor" parameters with
              | None -> Ok None
              | Some (`String cursor) -> Ok (Some cursor)
              | Some _ -> Error "tools/list cursor must be a string"
              end
          | Some _ -> Error "tools/list _meta must be an object"
          end
      end
  | Some _ -> Error "tools/list params must be an object"

let physics_tools_page id =
  jsonrpc_result id
    (`Assoc
       [
         ("tools", `List [ Centl_physics_mcp.tool () ]);
         ("nextCursor", `String math_cursor);
       ])

let math_tools_page id =
  jsonrpc_result id (`Assoc [ ("tools", `List [ Centl_math_mcp.tool () ]) ])

let tools_list ?(cancelled = Centl_engine.never_cancelled) state id fields =
  match tools_list_cursor fields with
  | Error message -> jsonrpc_error id (-32602) message
  | Ok None ->
      Centl_mcp_base.handle_request ~cancelled state id "tools/list" fields
      |> add_physics_cursor
  | Ok (Some cursor) when cursor = physics_cursor -> physics_tools_page id
  | Ok (Some cursor) when cursor = math_cursor -> math_tools_page id
  | Ok (Some _) -> jsonrpc_error id (-32602) "unknown tools/list cursor"

let physics_tool_result response =
  `Assoc
    [
      ( "content",
        `List
          [
            `Assoc
              [
                ("type", `String "text");
                ("text", `String (Centl_physics_server.text response));
              ];
          ] );
      ("structuredContent", response);
      ("isError", `Bool (not (Centl_physics_mcp.ok response)));
    ]

let math_tool_result response =
  `Assoc
    [
      ( "content",
        `List
          [
            `Assoc
              [
                ("type", `String "text");
                ("text", `String (Centl_math_mcp.text response));
              ];
          ] );
      ("structuredContent", response);
      ("isError", `Bool (not (Centl_math_mcp.ok response)));
    ]

let physics ?(cancelled = Centl_engine.never_cancelled) id arguments =
  let physics_state = Centl_physics_protocol.create () in
  Centl_physics_mcp.call ~cancelled physics_state arguments
  |> physics_tool_result |> jsonrpc_result id

let math ?(cancelled = Centl_engine.never_cancelled) state id arguments =
  let limits =
    Centl_protocol.math_gateway_limits (Centl_mcp_base.protocol_state state)
  in
  Centl_math_mcp.call ~limits ~cancelled arguments
  |> math_tool_result |> jsonrpc_result id

let legacy_capabilities state id arguments =
  if arguments <> [] then
    jsonrpc_error id (-32602) "centl_capabilities accepts no arguments"
  else
    Centl_protocol.handle_json (Centl_mcp_base.protocol_state state)
      (`Assoc [ ("version", `Int 1); ("op", `String "describe") ])
    |> legacy_capabilities_response
    |> Centl_mcp_base.tool_result |> jsonrpc_result id

let call_tool ?(cancelled = Centl_engine.never_cancelled) state id fields =
  match List.assoc_opt "params" fields with
  | Some (`Assoc parameters) ->
      begin match
        (List.assoc_opt "name" parameters, List.assoc_opt "arguments" parameters)
      with
      | Some (`String "centl_physics"), Some (`Assoc arguments) ->
          begin match Centl_physics_mcp.validate_arguments arguments with
          | Ok () -> physics ~cancelled id arguments
          | Error message -> jsonrpc_error id (-32602) message
          end
      | Some (`String "centl_physics"), None ->
          jsonrpc_error id (-32602) "centl_physics requires arguments"
      | Some (`String "centl_physics"), Some _ ->
          jsonrpc_error id (-32602) "centl_physics arguments must be an object"
      | Some (`String "centl_math"), Some (`Assoc arguments) ->
          begin match Centl_math_mcp.validate_arguments arguments with
          | Ok () -> math ~cancelled state id arguments
          | Error message -> jsonrpc_error id (-32602) message
          end
      | Some (`String "centl_math"), None ->
          jsonrpc_error id (-32602) "centl_math requires arguments"
      | Some (`String "centl_math"), Some _ ->
          jsonrpc_error id (-32602) "centl_math arguments must be an object"
      | Some (`String "centl_capabilities"), Some (`Assoc arguments) ->
          legacy_capabilities state id arguments
      | Some (`String "centl_capabilities"), None ->
          legacy_capabilities state id []
      | _ -> Centl_mcp_base.call_tool ~cancelled state id fields
      end
  | _ -> Centl_mcp_base.call_tool ~cancelled state id fields

let handle_request ?(cancelled = Centl_engine.never_cancelled) state id
    method_name fields =
  match method_name with
  | "initialize" | "ping" ->
      Centl_mcp_base.handle_request ~cancelled state id method_name fields
  | _ when not state.initialized ->
      Centl_mcp_base.handle_request ~cancelled state id method_name fields
  | "tools/list" -> tools_list ~cancelled state id fields
  | "tools/call" -> call_tool ~cancelled state id fields
  | _ -> Centl_mcp_base.handle_request ~cancelled state id method_name fields

let handle_json ?(cancelled = Centl_engine.never_cancelled) state = function
  | `Assoc fields ->
      begin match
        (List.assoc_opt "jsonrpc" fields, List.assoc_opt "method" fields)
      with
      | Some (`String "2.0"), Some (`String method_name) ->
          begin match request_id fields with
          | Error message -> Some (jsonrpc_error `Null (-32600) message)
          | Ok (Some id) ->
              Some (handle_request ~cancelled state id method_name fields)
          | Ok None ->
              handle_notification state method_name;
              None
          end
      | _ -> Some (jsonrpc_error `Null (-32600) "invalid JSON-RPC request")
      end
  | _ -> Some (jsonrpc_error `Null (-32600) "invalid JSON-RPC request")

let handle_line ?(cancelled = Centl_engine.never_cancelled) state line =
  try
    let json = Yojson.Safe.from_string line in
    if Option.is_some (cancellation_target_of_json json) then
      handle_json ~cancelled state json
    else if Centl_protocol.admit state.protocol then
      handle_json ~cancelled state json
    else
      match json with
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
    if Centl_protocol.admit state.protocol then
      Some (jsonrpc_error `Null (-32700) "parse error")
    else
      Some
        (jsonrpc_error `Null (-32000)
           "the process has reached its request limit")
