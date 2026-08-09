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
                        ("name", `String "collision-3d-test");
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

let particle id mass (px, py, pz) (vx, vy, vz) =
  `Assoc
    [
      ("id", `String id);
      ("mass", quantity mass "kg");
      ("position", vector px py pz "m");
      ("velocity", vector vx vy vz "m/s");
    ]

let test_3d_collision_tool_call () =
  let state = Centl_mcp.create () in
  initialize state;
  let request =
    `Assoc
      [
        ("jsonrpc", `String "2.0");
        ("id", `Int 2);
        ("method", `String "tools/call");
        ( "params",
          `Assoc
            [
              ("name", `String "centl_physics");
              ( "arguments",
                `Assoc
                  [
                    ("action", `String "elastic_collision_3d_at_contact");
                    ( "particle1",
                      particle "p1" "1" ("0", "0", "0") ("1", "0", "0") );
                    ( "particle2",
                      particle "p2" "1" ("1", "1", "0") ("0", "0", "0") );
                  ] );
            ] );
      ]
  in
  let response = Centl_mcp.handle_json state request |> response in
  let result = assoc "result" response in
  Alcotest.(check bool) "tool success" false (bool "isError" result);
  let structured = assoc "structuredContent" result in
  let physics = assoc "physics" structured in
  Alcotest.(check string)
    "kind" "elastic_collision_3d_at_contact" (string "kind" physics);
  Alcotest.(check string) "status" "resolved" (string "status" physics);
  Alcotest.(check string)
    "contact assumption" "caller_supplied_contact_with_distinct_centers"
    (string "contact_assumption" physics);
  let v1 = assoc "velocity" (assoc "particle1_final" physics) in
  let v2 = assoc "velocity" (assoc "particle2_final" physics) in
  Alcotest.(check string) "v1 x" "1/2" (string "x" v1);
  Alcotest.(check string) "v1 y" "-1/2" (string "y" v1);
  Alcotest.(check string) "v2 x" "1/2" (string "x" v2);
  Alcotest.(check string) "v2 y" "1/2" (string "y" v2)

let () =
  Alcotest.run "centl exact 3D collision MCP"
    [
      ( "mcp",
        [
          Alcotest.test_case "exact 3D contact collision" `Quick
            test_3d_collision_tool_call;
        ] );
    ]
