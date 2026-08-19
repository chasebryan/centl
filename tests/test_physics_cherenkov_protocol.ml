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

let request fields =
  let state = Centl_physics_protocol.create () in
  Centl_physics_server.handle_json state
    (`Assoc (("version", `Int 1) :: fields))

let quantity value unit_symbol =
  `Assoc [ ("value", `String value); ("unit", `String unit_symbol) ]

let test_emission_certificate () =
  let response =
    request
      [
        ("action", `String "cherenkov");
        ("refractive_index", `String "4/3");
        ("speed", quantity "1349066061/5" "m/s");
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let physics = assoc "physics" response in
  Alcotest.(check string)
    "kind" "cherenkov_radiation_certificate" (string "kind" physics);
  Alcotest.(check string) "status" "emission" (string "status" physics);
  Alcotest.(check bool) "emits" true (bool "emits" physics);
  Alcotest.(check string) "beta" "9/10" (string "beta" physics);
  Alcotest.(check string)
    "threshold beta" "3/4" (string "threshold_beta" physics);
  Alcotest.(check string)
    "beta*n" "6/5" (string "beta_times_refractive_index" physics);
  let angle = assoc "cone_angle" physics in
  Alcotest.(check string) "angle kind" "symbolic_arccos" (string "kind" angle);
  Alcotest.(check string) "cosine" "5/6" (string "cosine" angle);
  Alcotest.(check string)
    "theta" "acos(5/6)" (string "symbolic_radians" angle)

let test_threshold_has_no_cone () =
  let response =
    request
      [
        ("action", `String "cherenkov");
        ("refractive_index", `String "4/3");
        ("speed", quantity "449688687/2" "m/s");
      ]
  in
  let physics = assoc "physics" response in
  Alcotest.(check string) "status" "threshold" (string "status" physics);
  Alcotest.(check bool) "emits" false (bool "emits" physics);
  match assoc "cone_angle" physics with
  | `Null -> ()
  | _ -> Alcotest.fail "threshold must not claim a radiation cone"

let test_invalid_inputs () =
  let zero_index =
    request
      [
        ("action", `String "cherenkov");
        ("refractive_index", `String "0");
        ("speed", quantity "1" "m/s");
      ]
  in
  Alcotest.(check bool) "zero index fails" false (bool "ok" zero_index);
  let wrong_dimension =
    request
      [
        ("action", `String "cherenkov");
        ("refractive_index", `String "4/3");
        ("speed", quantity "1" "m");
      ]
  in
  Alcotest.(check bool) "wrong dimension fails" false
    (bool "ok" wrong_dimension)

let test_capabilities_advertise_cherenkov () =
  let response = request [ ("action", `String "capabilities") ] in
  let physics = assoc "physics" response in
  match assoc "actions" physics with
  | `List actions ->
      Alcotest.(check bool) "cherenkov advertised" true
        (List.exists (function `String "cherenkov" -> true | _ -> false) actions)
  | _ -> Alcotest.fail "actions must be an array"

let () =
  Alcotest.run "centl physics Cherenkov protocol"
    [
      ( "Cherenkov protocol",
        [
          Alcotest.test_case "emission certificate" `Quick
            test_emission_certificate;
          Alcotest.test_case "strict threshold" `Quick
            test_threshold_has_no_cone;
          Alcotest.test_case "invalid inputs" `Quick test_invalid_inputs;
          Alcotest.test_case "capabilities" `Quick
            test_capabilities_advertise_cherenkov;
        ] );
    ]
