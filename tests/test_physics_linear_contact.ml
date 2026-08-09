open Centl_physics
open Centl_physics_world
open Centl_physics_linear_contact

let q = Q.of_string

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let check_status message expected certificate =
  Alcotest.(check string)
    message expected
    (linear_contact_status_to_string certificate.status)

let body ~id ~position:(px, py, pz) ~velocity:(vx, vy, vz) =
  particle ~id ~mass:(quantity Q.one "kg")
    ~position:(vector3 ~unit_symbol:"m" (q px) (q py) (q pz))
    ~velocity:(vector3 ~unit_symbol:"m/s" (q vx) (q vy) (q vz))

let sphere_body ?(radius = "1") ~id ~position ~velocity =
  sphere
    ~particle:(body ~id ~position ~velocity)
    ~radius:(quantity (q radius) "m")

let duration value = quantity (q value) "s"

let test_rational_crossing_time () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("4", "0", "0") ~velocity:("0", "0", "0")
  in
  let certificate =
    certify_linear_sphere_contact ~duration:(duration "3") a b
  in
  check_status "crossing" "crossing_contact" certificate;
  check_q "a coefficient" Q.one certificate.polynomial_a.si_value;
  check_q "b coefficient" (q "-8") certificate.polynomial_b.si_value;
  check_q "c coefficient" (q "12") certificate.polynomial_c.si_value;
  check_q "closest time is interval end" (q "3")
    certificate.closest_time.si_value;
  check_q "minimum clearance squared" (q "-3")
    certificate.minimum_clearance_squared.si_value;
  begin match certificate.first_contact_time with
  | Some (Rational_contact_time time) ->
      check_q "first contact" (q "2") time.si_value
  | _ -> Alcotest.fail "expected rational first-contact time"
  end

let test_crossing_exactly_at_interval_end () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("4", "0", "0") ~velocity:("0", "0", "0")
  in
  let certificate =
    certify_linear_sphere_contact ~duration:(duration "2") a b
  in
  check_status "endpoint crossing" "crossing_contact" certificate;
  check_q "endpoint minimum is zero" Q.zero
    certificate.minimum_clearance_squared.si_value;
  begin match certificate.discriminant with
  | Some discriminant ->
      check_q "endpoint discriminant" (q "16") discriminant.si_value
  | None -> Alcotest.fail "endpoint crossing must expose a discriminant"
  end;
  begin match certificate.first_contact_time with
  | Some (Rational_contact_time time) ->
      check_q "endpoint first contact" (q "2") time.si_value
  | _ -> Alcotest.fail "endpoint crossing must report exact time two"
  end

let test_exact_tangent_contact () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("2", "2", "0") ~velocity:("0", "0", "0")
  in
  let certificate =
    certify_linear_sphere_contact ~duration:(duration "3") a b
  in
  check_status "tangent" "tangent_contact" certificate;
  check_q "tangent time" (q "2") certificate.closest_time.si_value;
  check_q "zero minimum clearance" Q.zero
    certificate.minimum_clearance_squared.si_value;
  begin match certificate.first_contact_time with
  | Some (Rational_contact_time time) ->
      check_q "tangent contact time" (q "2") time.si_value
  | _ -> Alcotest.fail "tangent time must remain rational"
  end

let test_irrational_quadratic_contact_time () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("3", "1", "0") ~velocity:("0", "0", "0")
  in
  let certificate =
    certify_linear_sphere_contact ~duration:(duration "3") a b
  in
  check_status "crossing" "crossing_contact" certificate;
  check_q "closest time" (q "3") certificate.closest_time.si_value;
  check_q "minimum clearance" (q "-3")
    certificate.minimum_clearance_squared.si_value;
  begin match certificate.discriminant with
  | Some discriminant -> check_q "discriminant" (q "12") discriminant.si_value
  | None -> Alcotest.fail "crossing must expose a discriminant"
  end;
  begin match certificate.first_contact_time with
  | Some
      (Quadratic_irrational_contact_time
         { discriminant; bracket_lower; bracket_upper; _ }) ->
      check_q "algebraic discriminant" (q "12") discriminant.si_value;
      check_q "lower bracket" Q.zero bracket_lower.si_value;
      check_q "upper bracket" (q "3") bracket_upper.si_value
  | _ -> Alcotest.fail "expected an explicit quadratic-irrational contact time"
  end

let test_short_interval_certifies_no_contact () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("4", "0", "0") ~velocity:("0", "0", "0")
  in
  let certificate =
    certify_linear_sphere_contact ~duration:(duration "1") a b
  in
  check_status "no contact" "no_contact_in_interval" certificate;
  check_q "closest sampled interval endpoint" Q.one
    certificate.closest_time.si_value;
  check_q "positive clearance certificate" (q "5")
    certificate.minimum_clearance_squared.si_value;
  Alcotest.(check bool)
    "no contact time" true
    (certificate.first_contact_time = None)

let test_parallel_miss_certifies_no_contact () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("0", "3", "0") ~velocity:("0", "0", "0")
  in
  let certificate =
    certify_linear_sphere_contact ~duration:(duration "10") a b
  in
  check_status "parallel miss" "no_contact_in_interval" certificate;
  check_q "closest at start" Q.zero certificate.closest_time.si_value;
  check_q "positive clearance" (q "5")
    certificate.minimum_clearance_squared.si_value

let test_stationary_separation () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("0", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("3", "0", "0") ~velocity:("0", "0", "0")
  in
  let certificate =
    certify_linear_sphere_contact ~duration:(duration "10") a b
  in
  check_status "stationary separated" "no_contact_in_interval" certificate;
  Alcotest.(check bool)
    "no discriminant needed" true
    (certificate.discriminant = None)

let test_touching_at_start () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("-1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("2", "0", "0") ~velocity:("1", "0", "0")
  in
  let certificate =
    certify_linear_sphere_contact ~duration:(duration "5") a b
  in
  check_status "touching start" "touching_at_start" certificate;
  begin match certificate.first_contact_time with
  | Some (Rational_contact_time time) ->
      check_q "contact at zero" Q.zero time.si_value
  | _ -> Alcotest.fail "touching start must report exact time zero"
  end

let test_initial_overlap () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("0", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("1", "0", "0") ~velocity:("0", "0", "0")
  in
  let certificate =
    certify_linear_sphere_contact ~duration:(duration "5") a b
  in
  check_status "overlap" "initially_overlapping" certificate;
  check_q "negative initial clearance" (q "-3")
    certificate.polynomial_c.si_value

let test_distinct_ids_required () =
  let a =
    sphere_body ~id:"same" ~position:("0", "0", "0")
      ~velocity:("0", "0", "0")
  in
  let b =
    sphere_body ~id:"same" ~position:("3", "0", "0")
      ~velocity:("0", "0", "0")
  in
  match certify_linear_sphere_contact ~duration:(duration "1") a b with
  | _ -> Alcotest.fail "same-id contact pair must be rejected"
  | exception Physics_error "linear contact pair requires distinct particle ids" -> ()
  | exception Physics_error message ->
      Alcotest.fail ("unexpected error: " ^ message)

let test_duration_dimension_required () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("0", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("3", "0", "0") ~velocity:("0", "0", "0")
  in
  match certify_linear_sphere_contact ~duration:(quantity Q.one "m") a b with
  | _ -> Alcotest.fail "non-time duration must be rejected"
  | exception Physics_error _ -> ()

let test_negative_duration_rejected () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("0", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("3", "0", "0") ~velocity:("0", "0", "0")
  in
  match certify_linear_sphere_contact ~duration:(duration "-1") a b with
  | _ -> Alcotest.fail "negative duration must be rejected"
  | exception Physics_error "linear contact duration must be nonnegative" -> ()
  | exception Physics_error message ->
      Alcotest.fail ("unexpected error: " ^ message)

let () =
  Alcotest.run "centl certified linear contact"
    [
      ( "continuous linear contact",
        [
          Alcotest.test_case "rational crossing" `Quick
            test_rational_crossing_time;
          Alcotest.test_case "endpoint crossing" `Quick
            test_crossing_exactly_at_interval_end;
          Alcotest.test_case "tangent" `Quick test_exact_tangent_contact;
          Alcotest.test_case "irrational crossing" `Quick
            test_irrational_quadratic_contact_time;
          Alcotest.test_case "short interval" `Quick
            test_short_interval_certifies_no_contact;
          Alcotest.test_case "parallel miss" `Quick
            test_parallel_miss_certifies_no_contact;
          Alcotest.test_case "stationary separated" `Quick
            test_stationary_separation;
          Alcotest.test_case "touching start" `Quick test_touching_at_start;
          Alcotest.test_case "initial overlap" `Quick test_initial_overlap;
          Alcotest.test_case "distinct ids" `Quick test_distinct_ids_required;
          Alcotest.test_case "duration dimension" `Quick
            test_duration_dimension_required;
          Alcotest.test_case "negative duration" `Quick
            test_negative_duration_rejected;
        ] );
    ]
