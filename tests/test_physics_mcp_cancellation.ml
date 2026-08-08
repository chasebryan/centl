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

let response = function
  | Some response -> response
  | None -> Alcotest.fail "expected MCP response"

let initialize state =
  ignore
    (Centl_mcp.handle_json state
       (`Assoc
          [
            ("jsonrpc", `String "2.0");
            ("id", `Int 1);
            ("method", `String "initialize");
            ( "params",
              `Assoc
                [
                  ("protocolVersion", `String "2025-11-25");
                  ("capabilities", `Assoc []);
                  ( "clientInfo",
                    `Assoc
                      [
                        ("name", `String "physics-cancellation-test");
                        ("version", `String "1");
                      ] );
                ] );
          ]));
  ignore
    (Centl_mcp.handle_json state
       (`Assoc
          [
            ("jsonrpc", `String "2.0");
            ("method", `String "notifications/initialized");
          ]))

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

let tool_request id arguments =
  `Assoc
    [
      ("jsonrpc", `String "2.0");
      ("id", id);
      ("method", `String "tools/call");
      ( "params",
        `Assoc
          [ ("name", `String "centl_physics"); ("arguments", `Assoc arguments) ]
      );
    ]

let physics_request id =
  tool_request id
    [
      ("action", `String "simulate_particle");
      ( "particle",
        `Assoc
          [
            ("id", `String "body");
            ("mass", quantity "1" "kg");
            ("position", vector "0" "0" "0" "m");
            ("velocity", vector "1" "0" "0" "m/s");
          ] );
      ("forces", `List []);
      ("dt", quantity "1/100" "s");
      ("steps", `Int 100_000);
    ]

let test_physics_request_is_cancellable () =
  let id = `String "physics-1" in
  match Centl_mcp.cancellable_request_id (physics_request id) with
  | Some actual ->
      Alcotest.(check string)
        "request id" "physics-1"
        (match actual with
        | `String value -> value
        | _ -> Alcotest.fail "cancellable id changed type")
  | None -> Alcotest.fail "centl_physics was not classified as cancellable"

let test_cancelled_physics_response () =
  let state = Centl_mcp.create () in
  initialize state;
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 3
  in
  let response =
    Centl_mcp.handle_json ~cancelled state (physics_request (`Int 2))
    |> response
  in
  let result = assoc "result" response in
  let structured = assoc "structuredContent" result in
  let error = assoc "error" structured in
  Alcotest.(check string) "cancelled code" "cancelled" (string "code" error);
  Alcotest.(check bool)
    "MCP recognizes suppressed cancellation" true
    (Centl_mcp.cancelled_response (Some response));
  Alcotest.(check bool) "multiple checkpoints reached" true (!checks >= 3)

let test_cancelled_short_physics_response () =
  let state = Centl_mcp.create () in
  initialize state;
  let request =
    tool_request (`Int 3)
      [
        ("action", `String "convert");
        ("value", `String "100");
        ("from_unit", `String "cm");
        ("to_unit", `String "m");
      ]
  in
  let response =
    Centl_mcp.handle_json ~cancelled:(fun () -> true) state request |> response
  in
  let result = assoc "result" response in
  let structured = assoc "structuredContent" result in
  let error = assoc "error" structured in
  Alcotest.(check string)
    "short action cancelled code" "cancelled" (string "code" error);
  Alcotest.(check bool)
    "short action cancellation suppressed" true
    (Centl_mcp.cancelled_response (Some response))

let () =
  Alcotest.run "centl physics mcp cancellation"
    [
      ( "cancellation",
        [
          Alcotest.test_case "classification" `Quick
            test_physics_request_is_cancellable;
          Alcotest.test_case "cancelled response" `Quick
            test_cancelled_physics_response;
          Alcotest.test_case "cancelled short action" `Quick
            test_cancelled_short_physics_response;
        ] );
    ]
