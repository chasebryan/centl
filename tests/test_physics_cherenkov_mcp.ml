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
                [
                  ("name", `String "cherenkov-test");
                  ("version", `String "1");
                ] );
          ]));
  ignore
    (Centl_mcp.handle_json state
       (`Assoc
          [
            ("jsonrpc", `String "2.0");
            ("method", `String "notifications/initialized");
          ]))

let tool_call state id arguments =
  request state id "tools/call"
    (`Assoc
       [ ("name", `String "centl_physics"); ("arguments", `Assoc arguments) ])

let structured response = assoc "structuredContent" (assoc "result" response)
let tool_is_error response = bool "isError" (assoc "result" response)

let quantity value unit_symbol =
  `Assoc [ ("value", `String value); ("unit", `String unit_symbol) ]

let cherenkov_arguments () =
  [
    ("action", `String "cherenkov");
    ("refractive_index", `String "4/3");
    ("speed", quantity "1349066061/5" "m/s");
  ]

let test_cherenkov_through_mcp () =
  let state = Centl_mcp.create () in
  initialize state;
  let response = tool_call state 2 (cherenkov_arguments ()) in
  Alcotest.(check bool) "tool success" false (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check bool) "protocol success" true (bool "ok" protocol);
  let certificate = assoc "physics" protocol in
  Alcotest.(check string) "status" "emission" (string "status" certificate);
  Alcotest.(check string) "beta" "9/10" (string "beta" certificate);
  let angle = assoc "cone_angle" certificate in
  Alcotest.(check string) "cos(theta)" "5/6" (string "cosine" angle);
  Alcotest.(check string)
    "symbolic theta" "acos(5/6)" (string "symbolic_radians" angle)

let test_invalid_dimension_is_tool_error () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2
      [
        ("action", `String "cherenkov");
        ("refractive_index", `String "4/3");
        ("speed", quantity "1" "m");
      ]
  in
  Alcotest.(check bool) "tool error" true (tool_is_error response);
  Alcotest.(check bool) "protocol failure" false
    (bool "ok" (structured response))

let test_strict_arguments () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2 (cherenkov_arguments () @ [ ("approximate", `Bool true) ])
  in
  let error = assoc "error" response in
  match assoc "code" error with
  | `Int -32602 -> ()
  | _ -> Alcotest.fail "unknown Cherenkov argument must be rejected"

let () =
  Alcotest.run "centl physics Cherenkov mcp"
    [
      ( "Cherenkov mcp",
        [
          Alcotest.test_case "exact certificate" `Quick test_cherenkov_through_mcp;
          Alcotest.test_case "invalid dimension" `Quick
            test_invalid_dimension_is_tool_error;
          Alcotest.test_case "strict arguments" `Quick test_strict_arguments;
        ] );
    ]
