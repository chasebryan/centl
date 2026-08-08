let assoc name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.fail ("missing JSON field " ^ name)
      end
  | _ -> Alcotest.fail "expected JSON object"

let string name json =
  match assoc name json with
  | `String value -> value
  | _ -> Alcotest.fail ("expected string field " ^ name)

let bool name json =
  match assoc name json with
  | `Bool value -> value
  | _ -> Alcotest.fail ("expected boolean field " ^ name)

let response = function
  | Some response -> response
  | None -> Alcotest.fail "expected MCP response"

let request state id method_name params =
  Centl_mcp.handle_json state
    (`Assoc
       [
         ("jsonrpc", `String "2.0");
         ("id", `Int id);
         ("method", `String method_name);
         ("params", params);
       ])
  |> response

let initialize state =
  ignore
    (request state 1 "initialize"
       (`Assoc
          [
            ("protocolVersion", `String "2025-11-25");
            ("capabilities", `Assoc []);
            ( "clientInfo",
              `Assoc
                [ ("name", `String "physics-test"); ("version", `String "1") ]
            );
          ]));
  match
    Centl_mcp.handle_json state
      (`Assoc
         [
           ("jsonrpc", `String "2.0");
           ("method", `String "notifications/initialized");
         ])
  with
  | None -> ()
  | Some _ ->
      Alcotest.fail "initialized notification must not return a response"

let tool_call state id name arguments =
  request state id "tools/call"
    (`Assoc [ ("name", `String name); ("arguments", `Assoc arguments) ])

let structured response = assoc "structuredContent" (assoc "result" response)
let tool_is_error response = bool "isError" (assoc "result" response)

let quantity value unit_symbol =
  `Assoc [ ("value", `String value); ("unit", `String unit_symbol) ]

let vector x y z unit_symbol =
  `Assoc
    [
      ("x", `String x);
      ("y", `String y);
      ("z", `String z);
      ("unit", `String unit_symbol);
    ]

let particle () =
  `Assoc
    [
      ("id", `String "body");
      ("mass", quantity "2" "kg");
      ("position", vector "0" "0" "10" "m");
      ("velocity", vector "1" "0" "0" "m/s");
    ]

let test_tool_discovery () =
  let state = Centl_mcp.create () in
  initialize state;
  let first_page = request state 2 "tools/list" (`Assoc []) in
  let first_result = assoc "result" first_page in
  let first_tools =
    match assoc "tools" first_result with
    | `List tools -> tools
    | _ -> Alcotest.fail "tools must be an array"
  in
  Alcotest.(check int) "compatibility page size" 8 (List.length first_tools);
  let cursor = string "nextCursor" first_result in
  let second_page =
    request state 3 "tools/list" (`Assoc [ ("cursor", `String cursor) ])
  in
  let tools =
    match assoc "tools" (assoc "result" second_page) with
    | `List tools -> tools
    | _ -> Alcotest.fail "second tools page must be an array"
  in
  Alcotest.(check int) "physics page size" 1 (List.length tools);
  let physics =
    List.find_opt
      (fun tool ->
        match tool with
        | `Assoc fields ->
            List.assoc_opt "name" fields = Some (`String "centl_physics")
        | _ -> false)
      tools
  in
  match physics with
  | None -> Alcotest.fail "centl_physics missing from paginated tools/list"
  | Some tool ->
      let annotations = assoc "annotations" tool in
      Alcotest.(check bool) "read only" true (bool "readOnlyHint" annotations);
      Alcotest.(check bool)
        "idempotent" true
        (bool "idempotentHint" annotations);
      begin match assoc "inputSchema" tool with
      | `Assoc fields ->
          Alcotest.(check bool)
            "closed action variants" true
            (List.mem_assoc "oneOf" fields)
      | _ -> Alcotest.fail "physics input schema must be an object"
      end;
      begin match assoc "outputSchema" tool with
      | `Assoc fields ->
          Alcotest.(check bool)
            "closed output variants" true
            (List.mem_assoc "oneOf" fields)
      | _ -> Alcotest.fail "physics output schema must be an object"
      end

let test_exact_conversion () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2 "centl_physics"
      [
        ("action", `String "convert");
        ("value", `String "100");
        ("from_unit", `String "cm");
        ("to_unit", `String "m");
      ]
  in
  Alcotest.(check bool) "tool success" false (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check bool) "protocol success" true (bool "ok" protocol);
  let physics = assoc "physics" protocol in
  Alcotest.(check string) "converted value" "1" (string "result" physics)

let test_gravity_simulation () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2 "centl_physics"
      [
        ("action", `String "simulate_particle");
        ("particle", particle ());
        ( "forces",
          `List
            [
              `Assoc
                [
                  ("kind", `String "uniform_gravity");
                  ("acceleration", vector "0" "0" "-10" "m/s^2");
                ];
            ] );
        ("dt", quantity "1/10" "s");
        ("steps", `Int 10);
      ]
  in
  Alcotest.(check bool) "tool success" false (tool_is_error response);
  let physics = assoc "physics" (structured response) in
  let final = assoc "final" physics in
  let position = assoc "position" final in
  let velocity = assoc "velocity" final in
  Alcotest.(check string) "z" "9/2" (string "z" position);
  Alcotest.(check string) "vz" "-10" (string "z" velocity)

let test_unsupported_force_is_tool_error () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2 "centl_physics"
      [
        ("action", `String "simulate_particle");
        ("particle", particle ());
        ( "forces",
          `List [ `Assoc [ ("kind", `String "inverse_square_gravity") ] ] );
        ("dt", quantity "1/10" "s");
        ("steps", `Int 1);
      ]
  in
  Alcotest.(check bool) "tool error" true (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check bool) "protocol failure" false (bool "ok" protocol);
  let error = assoc "error" protocol in
  Alcotest.(check string)
    "error code" "invalid_physics_request" (string "code" error)

let test_math_tool_still_delegates () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2 "centl_compute" [ ("expression", `String "0.1 + 0.2") ]
  in
  Alcotest.(check bool) "math tool success" false (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check bool) "math protocol success" true (bool "ok" protocol);
  let value = assoc "value" protocol in
  Alcotest.(check string) "math result" "3/10" (string "text" value)

let () =
  Alcotest.run "centl physics mcp"
    [
      ( "mcp",
        [
          Alcotest.test_case "tool discovery" `Quick test_tool_discovery;
          Alcotest.test_case "exact conversion" `Quick test_exact_conversion;
          Alcotest.test_case "gravity simulation" `Quick test_gravity_simulation;
          Alcotest.test_case "unsupported force" `Quick
            test_unsupported_force_is_tool_error;
          Alcotest.test_case "math delegation" `Quick
            test_math_tool_still_delegates;
        ] );
    ]
