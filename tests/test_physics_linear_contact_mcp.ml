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
                  ("name", `String "linear-contact-test");
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

let vector x y z unit_symbol =
  `Assoc
    [
      ("x", `String x);
      ("y", `String y);
      ("z", `String z);
      ("unit", `String unit_symbol);
    ]

let sphere ~id ~x ~y ~vx =
  `Assoc
    [
      ( "particle",
        `Assoc
          [
            ("id", `String id);
            ("mass", quantity "1" "kg");
            ("position", vector x y "0" "m");
            ("velocity", vector vx "0" "0" "m/s");
          ] );
      ("radius", quantity "1" "m");
    ]

let arguments ?(duration_unit = "s") ~duration sphere1 sphere2 =
  [
    ("action", `String "certify_linear_sphere_contact");
    ("sphere1", sphere1);
    ("sphere2", sphere2);
    ("duration", quantity duration duration_unit);
  ]

let test_rational_certificate_through_mcp () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2
      (arguments ~duration:"3"
         (sphere ~id:"a" ~x:"0" ~y:"0" ~vx:"1")
         (sphere ~id:"b" ~x:"4" ~y:"0" ~vx:"0"))
  in
  Alcotest.(check bool) "tool success" false (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check bool) "protocol success" true (bool "ok" protocol);
  let certificate = assoc "physics" protocol in
  Alcotest.(check string)
    "status" "crossing_contact"
    (string "status" certificate);
  let first = assoc "first_contact_time" certificate in
  Alcotest.(check string) "kind" "rational" (string "kind" first);
  Alcotest.(check string) "time" "2" (string "value" (assoc "time" first))

let test_irrational_certificate_through_mcp () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2
      (arguments ~duration:"3"
         (sphere ~id:"a" ~x:"0" ~y:"0" ~vx:"1")
         (sphere ~id:"b" ~x:"3" ~y:"1" ~vx:"0"))
  in
  Alcotest.(check bool) "tool success" false (tool_is_error response);
  let certificate = assoc "physics" (structured response) in
  let first = assoc "first_contact_time" certificate in
  Alcotest.(check string)
    "algebraic kind" "quadratic_irrational" (string "kind" first);
  let bracket = assoc "rational_bracket" first in
  Alcotest.(check string) "lower" "0" (string "value" (assoc "lower" bracket));
  Alcotest.(check string) "upper" "3" (string "value" (assoc "upper" bracket))

let test_invalid_duration_is_tool_error () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2
      (arguments ~duration:"3" ~duration_unit:"m"
         (sphere ~id:"a" ~x:"0" ~y:"0" ~vx:"1")
         (sphere ~id:"b" ~x:"4" ~y:"0" ~vx:"0"))
  in
  Alcotest.(check bool) "tool error" true (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check bool) "protocol failure" false (bool "ok" protocol)

let test_strict_linear_contact_arguments () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2
      (arguments ~duration:"3"
         (sphere ~id:"a" ~x:"0" ~y:"0" ~vx:"1")
         (sphere ~id:"b" ~x:"4" ~y:"0" ~vx:"0")
      @ [ ("approximate", `Bool true) ])
  in
  let error = assoc "error" response in
  match assoc "code" error with
  | `Int -32602 -> ()
  | _ -> Alcotest.fail "unknown continuous-contact argument must be rejected"

let () =
  Alcotest.run "centl physics linear-contact mcp"
    [
      ( "linear-contact mcp",
        [
          Alcotest.test_case "rational certificate" `Quick
            test_rational_certificate_through_mcp;
          Alcotest.test_case "irrational certificate" `Quick
            test_irrational_certificate_through_mcp;
          Alcotest.test_case "invalid duration" `Quick
            test_invalid_duration_is_tool_error;
          Alcotest.test_case "strict arguments" `Quick
            test_strict_linear_contact_arguments;
        ] );
    ]
