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

let physics response = assoc "physics" response

let linear_request ?(duration_unit = "s") ~duration sphere1 sphere2 =
  request
    [
      ("action", `String "certify_linear_sphere_contact");
      ("sphere1", sphere1);
      ("sphere2", sphere2);
      ("duration", quantity duration duration_unit);
    ]

let test_capabilities_advertise_linear_contact () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let actions = list "actions" (physics response) in
  let action_names =
    List.map
      (function
        | `String value -> value
        | _ -> Alcotest.fail "capability action must be a string")
      actions
  in
  Alcotest.(check bool)
    "continuous certificate advertised" true
    (List.mem "certify_linear_sphere_contact" action_names)

let test_rational_crossing_certificate () =
  let response =
    linear_request ~duration:"3"
      (sphere ~id:"a" ~x:"0" ~y:"0" ~vx:"1")
      (sphere ~id:"b" ~x:"4" ~y:"0" ~vx:"0")
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let certificate = physics response in
  Alcotest.(check string)
    "kind" "linear_sphere_contact_certificate" (string "kind" certificate);
  Alcotest.(check bool) "exact" true (bool "exact" certificate);
  Alcotest.(check string)
    "status" "crossing_contact" (string "status" certificate);
  let polynomial = assoc "polynomial" certificate in
  Alcotest.(check string) "a" "1" (string "value" (assoc "a" polynomial));
  Alcotest.(check string) "b" "-8" (string "value" (assoc "b" polynomial));
  Alcotest.(check string) "c" "12" (string "value" (assoc "c" polynomial));
  let first = assoc "first_contact_time" certificate in
  Alcotest.(check string) "time kind" "rational" (string "kind" first);
  Alcotest.(check string) "first contact" "2" (string "value" (assoc "time" first));
  let trust = assoc "trust_boundary" certificate in
  Alcotest.(check bool) "no sampling" false (bool "time_sampling" trust);
  Alcotest.(check bool)
    "no float roots" false (bool "floating_point_root_finding" trust)

let test_irrational_crossing_certificate () =
  let response =
    linear_request ~duration:"3"
      (sphere ~id:"a" ~x:"0" ~y:"0" ~vx:"1")
      (sphere ~id:"b" ~x:"3" ~y:"1" ~vx:"0")
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let certificate = physics response in
  Alcotest.(check string)
    "status" "crossing_contact" (string "status" certificate);
  let first = assoc "first_contact_time" certificate in
  Alcotest.(check string)
    "algebraic kind" "quadratic_irrational" (string "kind" first);
  Alcotest.(check string)
    "discriminant" "12" (string "value" (assoc "discriminant" first));
  let bracket = assoc "rational_bracket" first in
  Alcotest.(check string) "lower" "0" (string "value" (assoc "lower" bracket));
  Alcotest.(check string) "upper" "3" (string "value" (assoc "upper" bracket))

let test_endpoint_crossing_not_tangent () =
  let response =
    linear_request ~duration:"2"
      (sphere ~id:"a" ~x:"0" ~y:"0" ~vx:"1")
      (sphere ~id:"b" ~x:"4" ~y:"0" ~vx:"0")
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let certificate = physics response in
  Alcotest.(check string)
    "endpoint is crossing" "crossing_contact" (string "status" certificate);
  Alcotest.(check string)
    "minimum zero" "0"
    (string "value" (assoc "minimum_clearance_squared" certificate));
  let first = assoc "first_contact_time" certificate in
  Alcotest.(check string) "first contact" "2" (string "value" (assoc "time" first))

let test_no_contact_uses_null_event () =
  let response =
    linear_request ~duration:"1"
      (sphere ~id:"a" ~x:"0" ~y:"0" ~vx:"1")
      (sphere ~id:"b" ~x:"4" ~y:"0" ~vx:"0")
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let certificate = physics response in
  Alcotest.(check string)
    "status" "no_contact_in_interval" (string "status" certificate);
  match assoc "first_contact_time" certificate with
  | `Null -> ()
  | _ -> Alcotest.fail "no-contact certificate must use null event time"

let test_duration_dimension_rejected () =
  let response =
    linear_request ~duration:"3" ~duration_unit:"m"
      (sphere ~id:"a" ~x:"0" ~y:"0" ~vx:"1")
      (sphere ~id:"b" ~x:"4" ~y:"0" ~vx:"0")
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  let error = assoc "error" response in
  Alcotest.(check string)
    "code" "invalid_physics_request" (string "code" error)

let test_unknown_field_rejected () =
  let response =
    request
      [
        ("action", `String "certify_linear_sphere_contact");
        ("sphere1", sphere ~id:"a" ~x:"0" ~y:"0" ~vx:"1");
        ("sphere2", sphere ~id:"b" ~x:"4" ~y:"0" ~vx:"0");
        ("duration", quantity "3" "s");
        ("approximate", `Bool true);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response)

let () =
  Alcotest.run "centl physics linear-contact protocol"
    [
      ( "linear-contact protocol",
        [
          Alcotest.test_case "capabilities" `Quick
            test_capabilities_advertise_linear_contact;
          Alcotest.test_case "rational crossing" `Quick
            test_rational_crossing_certificate;
          Alcotest.test_case "irrational crossing" `Quick
            test_irrational_crossing_certificate;
          Alcotest.test_case "endpoint crossing" `Quick
            test_endpoint_crossing_not_tangent;
          Alcotest.test_case "no contact" `Quick test_no_contact_uses_null_event;
          Alcotest.test_case "duration dimension" `Quick
            test_duration_dimension_rejected;
          Alcotest.test_case "unknown field" `Quick test_unknown_field_rejected;
        ] );
    ]
