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

let list name json =
  match assoc name json with
  | `List values -> values
  | _ -> Alcotest.fail ("expected array field " ^ name)

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

let particle ~id ~x ~vx =
  `Assoc
    [
      ("id", `String id);
      ("mass", quantity "1" "kg");
      ("position", vector x "0" "0" "m");
      ("velocity", vector vx "0" "0" "m/s");
    ]

let sphere ~id ~x ~vx =
  `Assoc
    [
      ("particle", particle ~id ~x ~vx);
      ("radius", quantity "1" "m");
    ]

let sphere_velocity_x state id =
  let spheres = list "spheres" state in
  let sphere =
    List.find_opt
      (fun sphere -> string "id" (assoc "particle" sphere) = id)
      spheres
  in
  match sphere with
  | None -> Alcotest.fail ("missing sphere " ^ id)
  | Some sphere ->
      let particle = assoc "particle" sphere in
      string "x" (assoc "velocity" particle)

let physics response = assoc "physics" response

let test_capabilities_advertise_contacts () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let physics = physics response in
  let actions =
    match assoc "actions" physics with
    | `List values ->
        List.map
          (function
            | `String value -> value
            | _ -> Alcotest.fail "capability action must be a string")
          values
    | _ -> Alcotest.fail "capability actions must be an array"
  in
  Alcotest.(check bool)
    "analysis advertised" true
    (List.mem "analyze_sphere_contacts" actions);
  Alcotest.(check bool)
    "resolver advertised" true
    (List.mem "resolve_isolated_elastic_sphere_contacts" actions);
  let limits = assoc "limits" physics in
  Alcotest.(check int) "contact pair ceiling" 4_096 (int "max_contact_pairs" limits)

let test_exact_contact_analysis () =
  let response =
    request
      [
        ("action", `String "analyze_sphere_contacts");
        ( "spheres",
          `List
            [
              sphere ~id:"a" ~x:"0" ~vx:"1";
              sphere ~id:"b" ~x:"2" ~vx:"-1";
              sphere ~id:"c" ~x:"5" ~vx:"0";
            ] );
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let physics = physics response in
  Alcotest.(check string)
    "kind" "sphere_contact_analysis" (string "kind" physics);
  Alcotest.(check bool) "exact" true (bool "exact" physics);
  let summary = assoc "summary" physics in
  Alcotest.(check int) "pairs" 3 (int "pair_count" summary);
  Alcotest.(check int) "separated" 2 (int "separated" summary);
  Alcotest.(check int) "touching" 1 (int "touching" summary);
  Alcotest.(check int) "overlapping" 0 (int "overlapping" summary);
  match list "active_contacts" physics with
  | [ contact ] ->
      Alcotest.(check string) "first id" "a" (string "particle1_id" contact);
      Alcotest.(check string) "second id" "b" (string "particle2_id" contact);
      Alcotest.(check string) "relation" "touching" (string "relation" contact);
      Alcotest.(check string)
        "distance squared" "4" (string "value" (assoc "distance_squared" contact));
      Alcotest.(check string)
        "radius sum squared" "4"
        (string "value" (assoc "radius_sum_squared" contact))
  | _ -> Alcotest.fail "expected exactly one active contact"

let test_isolated_contact_resolution () =
  let response =
    request
      [
        ("action", `String "resolve_isolated_elastic_sphere_contacts");
        ( "spheres",
          `List
            [
              sphere ~id:"a" ~x:"0" ~vx:"1";
              sphere ~id:"b" ~x:"2" ~vx:"-1";
              sphere ~id:"c" ~x:"6" ~vx:"3";
            ] );
      ]
  in
  Alcotest.(check bool) "protocol success" true (bool "ok" response);
  let physics = physics response in
  Alcotest.(check string) "decision" "completed" (string "decision" physics);
  Alcotest.(check bool) "world changed" true (bool "world_changed" physics);
  let invariants = assoc "invariants" physics in
  Alcotest.(check bool) "momentum" true (bool "momentum" invariants);
  Alcotest.(check bool) "energy" true (bool "kinetic_energy" invariants);
  let final_world = assoc "world" physics in
  Alcotest.(check string) "a velocity" "-1" (sphere_velocity_x final_world "a");
  Alcotest.(check string) "b velocity" "1" (sphere_velocity_x final_world "b");
  Alcotest.(check string) "c velocity" "3" (sphere_velocity_x final_world "c");
  match list "pair_resolutions" physics with
  | [ pair ] -> Alcotest.(check string) "resolved" "resolved" (string "status" pair)
  | _ -> Alcotest.fail "expected exactly one pair resolution"

let test_overlap_is_valid_deferred_verdict () =
  let response =
    request
      [
        ("action", `String "resolve_isolated_elastic_sphere_contacts");
        ( "spheres",
          `List
            [
              sphere ~id:"a" ~x:"0" ~vx:"1";
              sphere ~id:"b" ~x:"1" ~vx:"-1";
            ] );
      ]
  in
  Alcotest.(check bool) "deferred is protocol success" true (bool "ok" response);
  let physics = physics response in
  Alcotest.(check string) "decision" "deferred" (string "decision" physics);
  Alcotest.(check string) "reason" "overlap_detected" (string "reason" physics);
  Alcotest.(check bool) "unchanged" false (bool "world_changed" physics);
  Alcotest.(check int) "one overlap" 1 (List.length (list "overlaps" physics));
  let world = assoc "world" physics in
  Alcotest.(check string) "a unchanged" "1" (sphere_velocity_x world "a");
  Alcotest.(check string) "b unchanged" "-1" (sphere_velocity_x world "b")

let test_shared_contact_is_valid_deferred_verdict () =
  let response =
    request
      [
        ("action", `String "resolve_isolated_elastic_sphere_contacts");
        ( "spheres",
          `List
            [
              sphere ~id:"a" ~x:"0" ~vx:"1";
              sphere ~id:"b" ~x:"2" ~vx:"0";
              sphere ~id:"c" ~x:"4" ~vx:"-1";
            ] );
      ]
  in
  Alcotest.(check bool) "deferred is protocol success" true (bool "ok" response);
  let physics = physics response in
  Alcotest.(check string)
    "reason" "ambiguous_simultaneous_contacts" (string "reason" physics);
  begin match list "ambiguous_particle_ids" physics with
  | [ `String "b" ] -> ()
  | _ -> Alcotest.fail "only b should be ambiguous"
  end;
  Alcotest.(check int)
    "two touching contacts" 2 (List.length (list "touching_contacts" physics))

let test_duplicate_ids_rejected () =
  let response =
    request
      [
        ("action", `String "analyze_sphere_contacts");
        ( "spheres",
          `List
            [ sphere ~id:"same" ~x:"0" ~vx:"0"; sphere ~id:"same" ~x:"3" ~vx:"0" ] );
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response)

let test_contact_pair_limit () =
  let spheres =
    List.init 92 (fun index ->
        sphere ~id:(Printf.sprintf "s%d" index)
          ~x:(string_of_int (index * 3)) ~vx:"0")
  in
  let response =
    request
      [
        ("action", `String "analyze_sphere_contacts");
        ("spheres", `List spheres);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  let error = assoc "error" response in
  Alcotest.(check string)
    "code" "invalid_physics_request" (string "code" error)

let () =
  Alcotest.run "centl physics contact protocol"
    [
      ( "contact protocol",
        [
          Alcotest.test_case "capabilities" `Quick
            test_capabilities_advertise_contacts;
          Alcotest.test_case "exact analysis" `Quick test_exact_contact_analysis;
          Alcotest.test_case "isolated resolution" `Quick
            test_isolated_contact_resolution;
          Alcotest.test_case "overlap deferred" `Quick
            test_overlap_is_valid_deferred_verdict;
          Alcotest.test_case "shared contact deferred" `Quick
            test_shared_contact_is_valid_deferred_verdict;
          Alcotest.test_case "duplicate ids" `Quick test_duplicate_ids_rejected;
          Alcotest.test_case "pair limit" `Quick test_contact_pair_limit;
        ] );
    ]
