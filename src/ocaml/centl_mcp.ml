include Centl_mcp_base

let physics_cursor = "centl-physics-v1"

let replace_field name value fields =
  if List.mem_assoc name fields then
    List.map
      (fun (field, current) ->
        if field = name then (field, value) else (field, current))
      fields
  else fields @ [ (name, value) ]

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

let tools_list_cursor fields =
  match List.assoc_opt "params" fields with
  | None -> Ok None
  | Some (`Assoc []) -> Ok None
  | Some (`Assoc [ ("cursor", `String cursor) ]) -> Ok (Some cursor)
  | Some (`Assoc [ ("cursor", _) ]) ->
      Error "tools/list cursor must be a string"
  | Some (`Assoc _) -> Error "tools/list accepts only cursor"
  | Some _ -> Error "tools/list params must be an object"

let physics_tools_page id =
  jsonrpc_result id (`Assoc [ ("tools", `List [ Centl_physics_mcp.tool () ]) ])

let tools_list ?(cancelled = Centl_engine.never_cancelled) state id fields =
  match tools_list_cursor fields with
  | Error message -> jsonrpc_error id (-32602) message
  | Ok None ->
      Centl_mcp_base.handle_request ~cancelled state id "tools/list" fields
      |> add_physics_cursor
  | Ok (Some cursor) when cursor = physics_cursor -> physics_tools_page id
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

let physics id arguments =
  let physics_state = Centl_physics_protocol.create () in
  Centl_physics_mcp.call physics_state arguments
  |> physics_tool_result |> jsonrpc_result id

let call_tool ?(cancelled = Centl_engine.never_cancelled) state id fields =
  match List.assoc_opt "params" fields with
  | Some (`Assoc parameters) ->
      begin match
        (List.assoc_opt "name" parameters, List.assoc_opt "arguments" parameters)
      with
      | Some (`String "centl_physics"), Some (`Assoc arguments) ->
          physics id arguments
      | Some (`String "centl_physics"), None ->
          jsonrpc_error id (-32602) "centl_physics requires arguments"
      | Some (`String "centl_physics"), Some _ ->
          jsonrpc_error id (-32602) "centl_physics arguments must be an object"
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
