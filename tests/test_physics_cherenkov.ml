open Centl_physics
open Centl_physics_cherenkov

let q = Q.of_string

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let expect_physics_error message f =
  match f () with
  | () -> Alcotest.fail (message ^ ": expected Physics_error")
  | exception Physics_error _ -> ()

let speed_for_beta beta =
  let c = convert (constant "c").constant_value "m/s" in
  quantity (Q.mul beta c) "m/s"

let test_emission_certificate () =
  let certificate =
    certify_cherenkov ~refractive_index:(q "4/3")
      ~speed:(speed_for_beta (q "9/10"))
  in
  Alcotest.(check string)
    "status" "emission"
    (cherenkov_status_to_string certificate.status);
  Alcotest.(check bool) "emits" true (cherenkov_emits certificate);
  check_q "beta" (q "9/10") certificate.beta;
  check_q "threshold beta" (q "3/4") certificate.threshold_beta;
  check_q "beta*n" (q "6/5") certificate.beta_times_refractive_index;
  check_q "threshold speed" (q "449688687/2")
    (convert certificate.threshold_speed "m/s");
  match certificate.cone_angle with
  | None -> Alcotest.fail "emission must carry an exact cone-angle relation"
  | Some angle ->
      check_q "cos(theta)" (q "5/6") angle.cosine;
      Alcotest.(check string)
        "symbolic theta" "acos(5/6)" angle.radians_symbolic

let test_threshold_is_strict () =
  let certificate =
    certify_cherenkov ~refractive_index:(q "4/3")
      ~speed:(speed_for_beta (q "3/4"))
  in
  Alcotest.(check string)
    "status" "threshold"
    (cherenkov_status_to_string certificate.status);
  Alcotest.(check bool) "does not emit at strict threshold" false
    (cherenkov_emits certificate);
  Alcotest.(check bool) "no cone at threshold" true
    (Option.is_none certificate.cone_angle)

let test_below_threshold () =
  let certificate =
    certify_cherenkov ~refractive_index:(q "4/3")
      ~speed:(speed_for_beta (q "1/2"))
  in
  Alcotest.(check string)
    "status" "below_threshold"
    (cherenkov_status_to_string certificate.status);
  Alcotest.(check bool) "does not emit" false (cherenkov_emits certificate)

let test_input_validation () =
  expect_physics_error "zero refractive index rejected" (fun () ->
      ignore
        (certify_cherenkov ~refractive_index:Q.zero
           ~speed:(quantity Q.one "m/s")));
  expect_physics_error "negative speed rejected" (fun () ->
      ignore
        (certify_cherenkov ~refractive_index:(q "4/3")
           ~speed:(quantity (q "-1") "m/s")));
  expect_physics_error "non-velocity rejected" (fun () ->
      ignore
        (certify_cherenkov ~refractive_index:(q "4/3")
           ~speed:(quantity Q.one "m")))

let () =
  Alcotest.run "centl physics Cherenkov"
    [
      ( "Cherenkov",
        [
          Alcotest.test_case "emission certificate" `Quick
            test_emission_certificate;
          Alcotest.test_case "strict threshold" `Quick test_threshold_is_strict;
          Alcotest.test_case "below threshold" `Quick test_below_threshold;
          Alcotest.test_case "input validation" `Quick test_input_validation;
        ] );
    ]
