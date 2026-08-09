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
                [ ("name", `String "contact-test"); ("version", `String "1") ]
            );
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

let vector x y z unit_symbol =
  `Assoc
    [
      ("x", `String x);
      ("y", `String y);
      ("z", `String z);
      ("unit", `String unit_symbol);
    ]

let sphere ~id ~x ~vx =
  `Assoc
    [
      ( "particle",
        `Assoc
          [
            ("id", `String id);
            ("mass", quantity "1" "kg");
            ("position", vector x "0" "0" "m");
            ("velocity", vector vx "0" "0" "m/s");
          ] );
      ("radius", quantity "1" "m");
    ]

let test_analysis_through_mcp () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2
      [
        ("action", `String "analyze_sphere_contacts");
        ( "spheres",
          `List [ sphere ~id:"a" ~x:"0" ~vx:"0"; sphere ~id:"b" ~x:"2" ~vx:"0" ]
        );
      ]
  in
  Alcotest.(check bool) "tool success" false (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check bool) "protocol success" true (bool "ok" protocol);
  let physics = assoc "physics" protocol in
  Alcotest.(check string)
    "kind" "sphere_contact_analysis" (string "kind" physics)

let test_deferred_is_not_tool_error () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2
      [
        ("action", `String "resolve_isolated_elastic_sphere_contacts");
        ( "spheres",
          `List
            [ sphere ~id:"a" ~x:"0" ~vx:"1"; sphere ~id:"b" ~x:"1" ~vx:"-1" ] );
      ]
  in
  Alcotest.(check bool)
    "deferred is valid tool result" false (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check bool) "protocol success" true (bool "ok" protocol);
  let physics = assoc "physics" protocol in
  Alcotest.(check string) "decision" "deferred" (string "decision" physics);
  Alcotest.(check string) "reason" "overlap_detected" (string "reason" physics)

let test_strict_contact_arguments () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2
      [
        ("action", `String "analyze_sphere_contacts");
        ("spheres", `List []);
        ("guess", `Bool true);
      ]
  in
  let error = assoc "error" response in
  match assoc "code" error with
  | `Int -32602 -> ()
  | _ -> Alcotest.fail "unknown contact argument must be rejected"

let test_capabilities_through_mcp () =
  let state = Centl_mcp.create () in
  initialize state;
  let response = tool_call state 2 [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "tool success" false (tool_is_error response);
  let physics = assoc "physics" (structured response) in
  let limits = assoc "limits" physics in
  match assoc "max_contact_pairs" limits with
  | `Int 4_096 -> ()
  | _ -> Alcotest.fail "MCP capabilities must advertise max_contact_pairs"

let () =
  Alcotest.run "centl physics contact mcp"
    [
      ( "contact mcp",
        [
          Alcotest.test_case "analysis" `Quick test_analysis_through_mcp;
          Alcotest.test_case "deferred verdict" `Quick
            test_deferred_is_not_tool_error;
          Alcotest.test_case "strict arguments" `Quick
            test_strict_contact_arguments;
          Alcotest.test_case "capabilities" `Quick test_capabilities_through_mcp;
        ] );
    ]
