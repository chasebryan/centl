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

let request fields =
  let state = Centl_physics_protocol.create () in
  Centl_physics_server.handle_json state
    (`Assoc (("version", `Int 1) :: fields))

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

let test_capabilities () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let physics = assoc "physics" response in
  Alcotest.(check string) "kind" "physics_capabilities" (string "kind" physics);
  let limits = assoc "limits" physics in
  Alcotest.(check int) "step limit" 100_000 (int "max_steps" limits)

let test_exact_conversion () =
  let response =
    request
      [
        ("id", `String "conversion");
        ("action", `String "convert");
        ("value", `String "100");
        ("from_unit", `String "cm");
        ("to_unit", `String "m");
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "conversion" (string "id" response);
  let physics = assoc "physics" response in
  Alcotest.(check string) "exact result" "1" (string "result" physics);
  Alcotest.(check bool) "exact flag" true (bool "exact" physics)

let test_dimension_failure () =
  let response =
    request
      [
        ("action", `String "convert");
        ("value", `String "1");
        ("from_unit", `String "m");
        ("to_unit", `String "s");
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  let error = assoc "error" response in
  Alcotest.(check string)
    "error code" "invalid_physics_request" (string "code" error)

let test_gravity_simulation () =
  let response =
    request
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
        ("include_trajectory", `Bool true);
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let physics = assoc "physics" response in
  Alcotest.(check string)
    "kind" "particle_simulation" (string "kind" physics);
  Alcotest.(check string)
    "integrator" "symplectic_euler" (string "integrator" physics);
  let final = assoc "final" physics in
  let position = assoc "position" final in
  let velocity = assoc "velocity" final in
  Alcotest.(check string) "x" "1" (string "x" position);
  Alcotest.(check string) "z" "9/2" (string "z" position);
  Alcotest.(check string) "vx" "1" (string "x" velocity);
  Alcotest.(check string) "vz" "-10" (string "z" velocity);
  match assoc "trajectory" physics with
  | `List states -> Alcotest.(check int) "trajectory states" 11 (List.length states)
  | _ -> Alcotest.fail "trajectory must be an array"

let test_collision_invariants () =
  let response =
    request
      [
        ("action", `String "elastic_collision_1d");
        ("mass1", quantity "2" "kg");
        ("velocity1", quantity "3" "m/s");
        ("mass2", quantity "1" "kg");
        ("velocity2", quantity "-1" "m/s");
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let physics = assoc "physics" response in
  let v1 = assoc "velocity1_final" physics in
  let v2 = assoc "velocity2_final" physics in
  Alcotest.(check string) "v1" "1/3" (string "value" v1);
  Alcotest.(check string) "v2" "13/3" (string "value" v2);
  let invariants = assoc "invariants" physics in
  Alcotest.(check bool) "momentum" true (bool "momentum" invariants);
  Alcotest.(check bool) "energy" true (bool "kinetic_energy" invariants)

let test_unsupported_force () =
  let response =
    request
      [
        ("action", `String "simulate_particle");
        ("particle", particle ());
        ( "forces",
          `List [ `Assoc [ ("kind", `String "inverse_square_gravity") ] ] );
        ("dt", quantity "1/10" "s");
        ("steps", `Int 1);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  let error = assoc "error" response in
  Alcotest.(check string)
    "error code" "invalid_physics_request" (string "code" error)

let test_trajectory_limit () =
  let response =
    request
      [
        ("action", `String "simulate_particle");
        ("particle", particle ());
        ("forces", `List []);
        ("dt", quantity "1/100" "s");
        ("steps", `Int 4_097);
        ("include_trajectory", `Bool true);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response)

let () =
  Alcotest.run "centl physics protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "capabilities" `Quick test_capabilities;
          Alcotest.test_case "exact conversion" `Quick test_exact_conversion;
          Alcotest.test_case "dimension failure" `Quick test_dimension_failure;
          Alcotest.test_case "gravity simulation" `Quick test_gravity_simulation;
          Alcotest.test_case "collision invariants" `Quick test_collision_invariants;
          Alcotest.test_case "unsupported force" `Quick test_unsupported_force;
          Alcotest.test_case "trajectory limit" `Quick test_trajectory_limit;
        ] );
    ]
