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

let int name json =
  match assoc name json with
  | `Int value -> value
  | _ -> Alcotest.fail ("expected integer field " ^ name)

let response = function
  | Some response -> response
  | None -> Alcotest.fail "expected MCP response"

let request ?(cancelled = Centl_engine.never_cancelled) state id method_name params =
  Centl_mcp.handle_json ~cancelled state
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
                [ ("name", `String "math-test"); ("version", `String "1") ] );
          ]));
  ignore
    (Centl_mcp.handle_json state
       (`Assoc
          [
            ("jsonrpc", `String "2.0");
            ("method", `String "notifications/initialized");
          ]))

let tool_call ?(cancelled = Centl_engine.never_cancelled) state id arguments =
  request ~cancelled state id "tools/call"
    (`Assoc
       [
         ("name", `String "centl_math");
         ("arguments", `Assoc arguments);
       ])

let structured response = assoc "structuredContent" (assoc "result" response)
let tool_is_error response = bool "isError" (assoc "result" response)

let matrix rows =
  `List
    (List.map
       (fun row -> `List (List.map (fun value -> `String value) row))
       rows)

let find_tool name tools =
  List.find_opt
    (function
      | `Assoc fields -> List.assoc_opt "name" fields = Some (`String name)
      | _ -> false)
    tools

let test_discovery_pagination () =
  let state = Centl_mcp.create () in
  initialize state;
  let first = request state 2 "tools/list" (`Assoc []) in
  let physics_cursor = string "nextCursor" (assoc "result" first) in
  Alcotest.(check string) "physics cursor" "centl-physics-v1" physics_cursor;
  let physics =
    request state 3 "tools/list"
      (`Assoc [ ("cursor", `String physics_cursor) ])
  in
  let math_cursor = string "nextCursor" (assoc "result" physics) in
  Alcotest.(check string) "math cursor" "centl-math-v1" math_cursor;
  let math =
    request state 4 "tools/list" (`Assoc [ ("cursor", `String math_cursor) ])
  in
  let tools =
    match assoc "tools" (assoc "result" math) with
    | `List tools -> tools
    | _ -> Alcotest.fail "tools must be an array"
  in
  begin match find_tool "centl_math" tools with
  | None -> Alcotest.fail "centl_math missing from paginated tools/list"
  | Some tool ->
      let annotations = assoc "annotations" tool in
      Alcotest.(check bool) "read only" true (bool "readOnlyHint" annotations);
      begin match assoc "inputSchema" tool with
      | `Assoc fields ->
          Alcotest.(check bool) "closed input variants" true
            (List.mem_assoc "oneOf" fields)
      | _ -> Alcotest.fail "math input schema must be an object"
      end;
      begin match assoc "outputSchema" tool with
      | `Assoc fields ->
          Alcotest.(check bool) "closed output variants" true
            (List.mem_assoc "oneOf" fields)
      | _ -> Alcotest.fail "math output schema must be an object"
      end
  end

let test_exact_matrix_call () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2
      [
        ("domain", `String "matrix");
        ( "request",
          `Assoc
            [
              ("action", `String "determinant");
              ("matrix", matrix [ [ "1"; "2" ]; [ "3"; "4" ] ]);
            ] );
      ]
  in
  Alcotest.(check bool) "tool success" false (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check bool) "protocol success" true (bool "ok" protocol);
  Alcotest.(check string) "domain" "matrix" (string "domain" protocol);
  Alcotest.(check string) "determinant" "-2"
    (string "numerator" (assoc "result" protocol))

let test_exact_complex_call () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    tool_call state 2
      [
        ("domain", `String "complex_rational");
        ( "request",
          `Assoc
            [
              ( "expression",
                `String "complex(1/3, 2/5) * complex(3, 0)" );
            ] );
      ]
  in
  Alcotest.(check bool) "tool success" false (tool_is_error response);
  let value = assoc "value" (structured response) in
  Alcotest.(check string) "real" "1"
    (string "numerator" (assoc "real" value));
  Alcotest.(check string) "imaginary" "6"
    (string "numerator" (assoc "imaginary" value));
  Alcotest.(check string) "imaginary denominator" "5"
    (string "denominator" (assoc "imaginary" value))

let test_strict_arguments () =
  let state = Centl_mcp.create () in
  initialize state;
  let invalid =
    tool_call state 2
      [
        ("domain", `String "capabilities");
        ("extra", `Bool true);
      ]
  in
  let error = assoc "error" invalid in
  Alcotest.(check int) "invalid argument" (-32602) (int "code" error)

let test_cancellation () =
  let state = Centl_mcp.create () in
  initialize state;
  let cancelled =
    tool_call ~cancelled:(fun () -> true) state 2
      [
        ("domain", `String "matrix");
        ( "request",
          `Assoc
            [
              ("action", `String "inverse");
              ("matrix", matrix [ [ "1"; "2" ]; [ "3"; "4" ] ]);
            ] );
      ]
  in
  Alcotest.(check bool) "tool error" true (tool_is_error cancelled);
  let protocol = structured cancelled in
  Alcotest.(check string) "cancelled code" "cancelled"
    (string "code" (assoc "error" protocol))

let test_deep_complex_cancellation () =
  let state = Centl_mcp.create () in
  initialize state;
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 10
  in
  let response =
    tool_call ~cancelled state 2
      [
        ("domain", `String "complex_rational");
        ( "request",
          `Assoc [ ("expression", `String "complex(1, 1)^65536") ] );
      ]
  in
  Alcotest.(check bool) "tool error" true (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check string) "domain" "complex_rational" (string "domain" protocol);
  Alcotest.(check string) "cancelled code" "cancelled"
    (string "code" (assoc "error" protocol));
  Alcotest.(check bool) "callback reached repeated squaring" true (!checks >= 10)

let test_server_limit_parity () =
  let evaluation =
    {
      Centl_protocol.default_server_limits.evaluation with
      max_exact_bits = 4;
    }
  in
  let limits =
    { Centl_protocol.default_server_limits with evaluation }
  in
  let state = Centl_mcp.create ~limits () in
  initialize state;
  let limited =
    tool_call state 2
      [
        ("domain", `String "complex_rational");
        ("request", `Assoc [ ("expression", `String "complex(17, 0)") ]);
      ]
  in
  Alcotest.(check bool) "tool error" true (tool_is_error limited);
  Alcotest.(check string) "resource limit" "resource_limit"
    (string "code" (assoc "error" (structured limited)))

let () =
  Alcotest.run "centl canonical mathematics mcp"
    [
      ( "mcp",
        [
          Alcotest.test_case "discovery pagination" `Quick
            test_discovery_pagination;
          Alcotest.test_case "matrix" `Quick test_exact_matrix_call;
          Alcotest.test_case "complex" `Quick test_exact_complex_call;
          Alcotest.test_case "strict arguments" `Quick test_strict_arguments;
          Alcotest.test_case "cancellation" `Quick test_cancellation;
          Alcotest.test_case "deep complex cancellation" `Quick
            test_deep_complex_cancellation;
          Alcotest.test_case "server limit parity" `Quick
            test_server_limit_parity;
        ] );
    ]
