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

let request fields =
  let state = Centl_physics_protocol.create () in
  Centl_physics_server.handle_json state
    (`Assoc (("version", `Int 1) :: fields))

let test_capability_advertised () =
  let response = request [ ("action", `String "capabilities") ] in
  let physics = assoc "physics" response in
  match assoc "actions" physics with
  | `List actions ->
      Alcotest.(check bool)
        "3D action advertised" true
        (List.mem (`String "elastic_collision_3d_at_contact") actions)
  | _ -> Alcotest.fail "actions must be an array"

let collision_request p1 p2 =
  request
    [
      ("action", `String "elastic_collision_3d_at_contact");
      ("particle1", p1);
      ("particle2", p2);
    ]

let test_head_on_protocol_response () =
  let response =
    collision_request
      (particle "p1" "2" ("-1", "0", "0") ("3", "0", "0"))
      (particle "p2" "1" ("1", "0", "0") ("-1", "0", "0"))
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let physics = assoc "physics" response in
  Alcotest.(check string)
    "kind" "elastic_collision_3d_at_contact" (string "kind" physics);
  Alcotest.(check string) "status" "resolved" (string "status" physics);
  Alcotest.(check string)
    "contact assumption" "caller_supplied_distinct_centers"
    (string "contact_assumption" physics);
  let v1 = assoc "velocity" (assoc "particle1_final" physics) in
  let v2 = assoc "velocity" (assoc "particle2_final" physics) in
  Alcotest.(check string) "v1 x" "1/3" (string "x" v1);
  Alcotest.(check string) "v2 x" "13/3" (string "x" v2);
  let invariants = assoc "invariants" physics in
  Alcotest.(check bool) "momentum" true (bool "momentum" invariants);
  Alcotest.(check bool) "energy" true (bool "kinetic_energy" invariants)

let test_separating_protocol_response () =
  let response =
    collision_request
      (particle "p1" "1" ("-1", "0", "0") ("-1", "0", "0"))
      (particle "p2" "1" ("1", "0", "0") ("1", "0", "0"))
  in
  let physics = assoc "physics" response in
  Alcotest.(check string)
    "status" "separating_or_stationary" (string "status" physics);
  let v1 = assoc "velocity" (assoc "particle1_final" physics) in
  Alcotest.(check string) "unchanged v1" "-1" (string "x" v1)

let test_coincident_centers_are_error () =
  let response =
    collision_request
      (particle "p1" "1" ("0", "0", "0") ("1", "0", "0"))
      (particle "p2" "1" ("0", "0", "0") ("-1", "0", "0"))
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  let error = assoc "error" response in
  Alcotest.(check string)
    "error code" "invalid_physics_request" (string "code" error)

let () =
  Alcotest.run "centl exact 3D collision protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "capability" `Quick test_capability_advertised;
          Alcotest.test_case "head-on" `Quick test_head_on_protocol_response;
          Alcotest.test_case "separating" `Quick
            test_separating_protocol_response;
          Alcotest.test_case "coincident centers" `Quick
            test_coincident_centers_are_error;
        ] );
    ]
