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

let power variable exponent =
  `Assoc [ ("variable", `String variable); ("exponent", `Int exponent) ]

let term coefficient powers =
  `Assoc [ ("coefficient", `String coefficient); ("powers", `List powers) ]

let polynomial terms = `Assoc [ ("terms", `List terms) ]

let source () =
  polynomial
    [
      term "16" [];
      term "-8" [ power "x" 1 ];
      term "-20" [ power "x" 2 ];
      term "2" [ power "x" 3 ];
      term "8" [ power "x" 4 ];
      term "2" [ power "x" 5 ];
    ]

let factorize_request () =
  [
    ("action", `String "factorize");
    ("variable", `String "x");
    ("polynomial", source ());
  ]

let public_math ?id ?(cancelled = Centl_engine.never_cancelled) state domain request =
  let id_fields = match id with None -> [] | Some id -> [ ("id", id) ] in
  Centl_protocol.handle_json ~cancelled state
    (`Assoc
       ([ ("version", `Int 1); ("op", `String "math") ] @ id_fields
       @ [ ("domain", `String domain); ("request", `Assoc request) ]))

let rec json_contains_string expected = function
  | `String value -> String.equal expected value
  | `Assoc fields ->
      List.exists (fun (_, value) -> json_contains_string expected value) fields
  | `List values -> List.exists (json_contains_string expected) values
  | _ -> false

let test_public_factorize () =
  let state = Centl_protocol.create () in
  let response =
    public_math ~id:(`String "square-free-public") state "polynomial_square_free"
      (factorize_request ())
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "square-free-public" (string "id" response);
  Alcotest.(check string) "domain" "polynomial_square_free"
    (string "domain" response);
  Alcotest.(check string) "classification" "exact"
    (string "classification" (assoc "provenance" response));
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_square_free_factorization"
    (string "kind" result);
  Alcotest.(check int) "factor count" 2 (int "factor_count" result);
  Alcotest.(check string) "unit" "2" (string "text" (assoc "unit" result));
  begin match assoc "factors" result with
  | `List [ first; second ] ->
      Alcotest.(check int) "multiplicity 2" 2 (int "multiplicity" first);
      Alcotest.(check int) "multiplicity 3" 3 (int "multiplicity" second)
  | _ -> Alcotest.fail "expected two public multiplicity groups"
  end

let test_public_capabilities () =
  let state = Centl_protocol.create () in
  let response =
    Centl_protocol.handle_json state
      (`Assoc
         [
           ("version", `Int 1);
           ("op", `String "math");
           ("domain", `String "capabilities");
         ])
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check bool) "square-free advertised" true
    (json_contains_string "polynomial_square_free" (assoc "result" response))

let test_public_zero_refusal () =
  let state = Centl_protocol.create () in
  let response =
    public_math state "polynomial_square_free"
      [
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", polynomial []);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "zero code" "zero_polynomial"
    (string "code" (assoc "error" response))

let test_public_mixed_variable () =
  let state = Centl_protocol.create () in
  let response =
    public_math state "polynomial_square_free"
      [
        ("action", `String "factorize");
        ("variable", `String "x");
        ( "polynomial",
          polynomial
            [
              term "1" [ power "x" 1 ];
              term "1" [ power "y" 1 ];
            ] );
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "mixed code" "invalid_request"
    (string "code" (assoc "error" response))

let test_public_result_limit () =
  let evaluation =
    Centl_engine.{ default_evaluation_limits with max_result_bytes = 256 }
  in
  let limits = Centl_protocol.{ default_server_limits with evaluation } in
  let state = Centl_protocol.create ~limits () in
  let response =
    public_math state "polynomial_square_free" (factorize_request ())
  in
  Alcotest.(check bool) "refused" false (bool "ok" response);
  Alcotest.(check string) "resource code" "resource_limit"
    (string "code" (assoc "error" response))

let deep_source () =
  polynomial
    [
      term "16" [];
      term "-8" [ power "x" 1 ];
      term "-20" [ power "x" 2 ];
      term "2" [ power "x" 3 ];
      term "8" [ power "x" 4 ];
      term "2" [ power "x" 5 ];
    ]

let test_public_deep_cancellation () =
  let state = Centl_protocol.create () in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 24
  in
  let response =
    public_math ~id:(`String "square-free-cancel") ~cancelled state
      "polynomial_square_free"
      [
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", deep_source ());
      ]
  in
  Alcotest.(check bool) "cancelled" false (bool "ok" response);
  Alcotest.(check string) "id" "square-free-cancel" (string "id" response);
  Alcotest.(check string) "domain" "polynomial_square_free"
    (string "domain" response);
  Alcotest.(check string) "cancel code" "cancelled"
    (string "code" (assoc "error" response));
  Alcotest.(check bool) "callback reached factorization core" true (!checks >= 24)

let mcp_response = function
  | Some response -> response
  | None -> Alcotest.fail "expected MCP response"

let mcp_request ?(cancelled = Centl_engine.never_cancelled) state id method_name params =
  Centl_mcp.handle_json ~cancelled state
    (`Assoc
       [
         ("jsonrpc", `String "2.0");
         ("id", `Int id);
         ("method", `String method_name);
         ("params", params);
       ])
  |> mcp_response

let initialize state =
  ignore
    (mcp_request state 1 "initialize"
       (`Assoc
          [
            ("protocolVersion", `String "2025-11-25");
            ("capabilities", `Assoc []);
            ( "clientInfo",
              `Assoc
                [
                  ("name", `String "polynomial-square-free-test");
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

let mcp_call ?(cancelled = Centl_engine.never_cancelled) state id request =
  mcp_request ~cancelled state id "tools/call"
    (`Assoc
       [
         ("name", `String "centl_math");
         ( "arguments",
           `Assoc
             [
               ("domain", `String "polynomial_square_free");
               ("request", `Assoc request);
             ] );
       ])

let structured response = assoc "structuredContent" (assoc "result" response)
let tool_is_error response = bool "isError" (assoc "result" response)

let test_mcp_schema_and_factorization () =
  let tool = Centl_math_mcp.tool () in
  Alcotest.(check bool) "domain in closed schema" true
    (json_contains_string "polynomial_square_free" (assoc "inputSchema" tool));
  let state = Centl_mcp.create () in
  initialize state;
  let response = mcp_call state 2 (factorize_request ()) in
  Alcotest.(check bool) "tool success" false (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check bool) "protocol success" true (bool "ok" protocol);
  Alcotest.(check string) "domain" "polynomial_square_free"
    (string "domain" protocol);
  let result = assoc "result" protocol in
  Alcotest.(check int) "factor count" 2 (int "factor_count" result)

let test_mcp_nested_strictness () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    mcp_call state 2 (factorize_request () @ [ ("irreducible", `Bool true) ])
  in
  Alcotest.(check bool) "tool error" true (tool_is_error response);
  Alcotest.(check string) "invalid request" "invalid_request"
    (string "code" (assoc "error" (structured response)))

let test_mcp_zero_refusal () =
  let state = Centl_mcp.create () in
  initialize state;
  let response =
    mcp_call state 2
      [
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", polynomial []);
      ]
  in
  Alcotest.(check bool) "tool error" true (tool_is_error response);
  Alcotest.(check string) "zero code" "zero_polynomial"
    (string "code" (assoc "error" (structured response)))

let test_mcp_deep_cancellation () =
  let state = Centl_mcp.create () in
  initialize state;
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 24
  in
  let response =
    mcp_call ~cancelled state 2
      [
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", deep_source ());
      ]
  in
  Alcotest.(check bool) "tool error" true (tool_is_error response);
  let protocol = structured response in
  Alcotest.(check string) "domain" "polynomial_square_free"
    (string "domain" protocol);
  Alcotest.(check string) "cancelled" "cancelled"
    (string "code" (assoc "error" protocol));
  Alcotest.(check bool) "callback reached factorization core" true (!checks >= 24)

let test_mcp_result_limit_parity () =
  let evaluation =
    {
      Centl_protocol.default_server_limits.evaluation with
      max_result_bytes = 256;
    }
  in
  let limits = { Centl_protocol.default_server_limits with evaluation } in
  let state = Centl_mcp.create ~limits () in
  initialize state;
  let response = mcp_call state 2 (factorize_request ()) in
  Alcotest.(check bool) "tool error" true (tool_is_error response);
  Alcotest.(check string) "resource limit" "resource_limit"
    (string "code" (assoc "error" (structured response)))

let () =
  Alcotest.run "centl polynomial square-free public surfaces"
    [
      ( "surfaces",
        [
          Alcotest.test_case "JSONL factorize" `Quick test_public_factorize;
          Alcotest.test_case "JSONL capabilities" `Quick test_public_capabilities;
          Alcotest.test_case "JSONL zero refusal" `Quick test_public_zero_refusal;
          Alcotest.test_case "JSONL mixed variable" `Quick
            test_public_mixed_variable;
          Alcotest.test_case "JSONL result limit" `Quick test_public_result_limit;
          Alcotest.test_case "JSONL deep cancellation" `Quick
            test_public_deep_cancellation;
          Alcotest.test_case "MCP schema and factorization" `Quick
            test_mcp_schema_and_factorization;
          Alcotest.test_case "MCP nested strictness" `Quick
            test_mcp_nested_strictness;
          Alcotest.test_case "MCP zero refusal" `Quick test_mcp_zero_refusal;
          Alcotest.test_case "MCP deep cancellation" `Quick
            test_mcp_deep_cancellation;
          Alcotest.test_case "MCP result limit parity" `Quick
            test_mcp_result_limit_parity;
        ] );
    ]
