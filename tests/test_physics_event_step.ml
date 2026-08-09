open Centl_physics
open Centl_physics_collision
open Centl_physics_world
open Centl_physics_linear_contact
open Centl_physics_event_step

let q value = Q.of_string value

let time value = quantity (q value) "s"

let body ~id ~x ~y ~vx ~vy =
  let particle =
    particle ~id ~mass:(quantity (q "1") "kg")
      ~position:(vector3 ~unit_symbol:"m" (q x) (q y) Q.zero)
      ~velocity:(vector3 ~unit_symbol:"m/s" (q vx) (q vy) Q.zero)
  in
  sphere ~particle ~radius:(quantity (q "1") "m")

let check_q label expected actual =
  Alcotest.(check string) label expected (Q.to_string actual)

let check_vector_x label expected vector = check_q label expected vector.x
let check_vector_y label expected vector = check_q label expected vector.y

let completed = function
  | Completed result -> result
  | Deferred result ->
      Alcotest.fail
        ("expected completed event step, got deferred: "
        ^ event_step_deferred_reason_to_string result.reason)

let deferred = function
  | Deferred result -> result
  | Completed _ -> Alcotest.fail "expected deferred event step"

let response_status result =
  match result.response_status with
  | Some status -> contact_status_to_string status
  | None -> Alcotest.fail "expected contact response status"

let event_time result =
  match result.event_time with
  | Some value -> value
  | None -> Alcotest.fail "expected exact event time"

let contact_evidence result =
  match result.contact_evidence with
  | Some value -> value
  | None -> Alcotest.fail "expected exact contact evidence"

let check_preserved_identity initial final =
  Alcotest.(check string) "id" initial.particle.id final.particle.id;
  check_q "mass" (Q.to_string initial.particle.mass.si_value)
    final.particle.mass.si_value;
  check_q "radius" (Q.to_string initial.radius.si_value) final.radius.si_value

let test_no_contact_advances_full_duration () =
  let sphere1 = body ~id:"a" ~x:"0" ~y:"0" ~vx:"1" ~vy:"0" in
  let sphere2 = body ~id:"b" ~x:"10" ~y:"0" ~vx:"0" ~vy:"0" in
  let result =
    evolve_linear_sphere_pair_through_contact ~duration:(time "2") sphere1 sphere2
    |> completed
  in
  Alcotest.(check string)
    "certificate" "no_contact_in_interval"
    (linear_contact_status_to_string result.certificate.status);
  Alcotest.(check bool) "no event" true (Option.is_none result.event_time);
  Alcotest.(check bool) "no response" true (Option.is_none result.response_status);
  check_vector_x "sphere1 x" "2" result.final_sphere1.particle.position;
  check_vector_x "sphere2 x" "10" result.final_sphere2.particle.position;
  Alcotest.(check bool) "state changed" true result.state_changed;
  Alcotest.(check bool) "momentum" true result.momentum_conserved;
  Alcotest.(check bool) "kinetic energy" true result.kinetic_energy_conserved

let test_rational_crossing_resolves_and_advances_remainder () =
  let sphere1 = body ~id:"a" ~x:"0" ~y:"0" ~vx:"1" ~vy:"0" in
  let sphere2 = body ~id:"b" ~x:"4" ~y:"0" ~vx:"0" ~vy:"0" in
  let result =
    evolve_linear_sphere_pair_through_contact ~duration:(time "3") sphere1 sphere2
    |> completed
  in
  Alcotest.(check string)
    "certificate" "crossing_contact"
    (linear_contact_status_to_string result.certificate.status);
  check_q "event time" "2" (event_time result).si_value;
  Alcotest.(check string) "response" "resolved" (response_status result);
  Alcotest.(check string)
    "at-event relation" "touching"
    (contact_relation_to_string (contact_evidence result).relation);
  let contact1 = Option.get result.contact_sphere1 in
  let contact2 = Option.get result.contact_sphere2 in
  check_vector_x "contact sphere1 x" "2" contact1.particle.position;
  check_vector_x "contact sphere2 x" "4" contact2.particle.position;
  check_vector_x "final sphere1 x" "2" result.final_sphere1.particle.position;
  check_vector_x "final sphere2 x" "5" result.final_sphere2.particle.position;
  check_q "final sphere1 vx" "0" result.final_sphere1.particle.velocity.x;
  check_q "final sphere2 vx" "1" result.final_sphere2.particle.velocity.x;
  check_preserved_identity sphere1 result.final_sphere1;
  check_preserved_identity sphere2 result.final_sphere2;
  Alcotest.(check bool) "momentum" true result.momentum_conserved;
  Alcotest.(check bool) "kinetic energy" true result.kinetic_energy_conserved

let test_touching_at_start_approaching_resolves_immediately () =
  let sphere1 = body ~id:"a" ~x:"0" ~y:"0" ~vx:"1" ~vy:"0" in
  let sphere2 = body ~id:"b" ~x:"2" ~y:"0" ~vx:"0" ~vy:"0" in
  let result =
    evolve_linear_sphere_pair_through_contact ~duration:(time "1") sphere1 sphere2
    |> completed
  in
  Alcotest.(check string)
    "certificate" "touching_at_start"
    (linear_contact_status_to_string result.certificate.status);
  check_q "event time" "0" (event_time result).si_value;
  Alcotest.(check string) "response" "resolved" (response_status result);
  check_vector_x "final sphere1 x" "0" result.final_sphere1.particle.position;
  check_vector_x "final sphere2 x" "3" result.final_sphere2.particle.position;
  Alcotest.(check bool) "momentum" true result.momentum_conserved;
  Alcotest.(check bool) "kinetic energy" true result.kinetic_energy_conserved

let test_touching_at_start_separating_does_not_impulse () =
  let sphere1 = body ~id:"a" ~x:"0" ~y:"0" ~vx:"0" ~vy:"0" in
  let sphere2 = body ~id:"b" ~x:"2" ~y:"0" ~vx:"1" ~vy:"0" in
  let result =
    evolve_linear_sphere_pair_through_contact ~duration:(time "1") sphere1 sphere2
    |> completed
  in
  check_q "event time" "0" (event_time result).si_value;
  Alcotest.(check string)
    "response" "separating_or_stationary" (response_status result);
  check_vector_x "final sphere1 x" "0" result.final_sphere1.particle.position;
  check_vector_x "final sphere2 x" "3" result.final_sphere2.particle.position;
  check_q "sphere1 vx" "0" result.final_sphere1.particle.velocity.x;
  check_q "sphere2 vx" "1" result.final_sphere2.particle.velocity.x

let test_tangent_contact_has_no_impulse () =
  let sphere1 = body ~id:"a" ~x:"0" ~y:"0" ~vx:"1" ~vy:"0" in
  let sphere2 = body ~id:"b" ~x:"3" ~y:"2" ~vx:"0" ~vy:"0" in
  let result =
    evolve_linear_sphere_pair_through_contact ~duration:(time "4") sphere1 sphere2
    |> completed
  in
  Alcotest.(check string)
    "certificate" "tangent_contact"
    (linear_contact_status_to_string result.certificate.status);
  check_q "event time" "3" (event_time result).si_value;
  Alcotest.(check string)
    "response" "separating_or_stationary" (response_status result);
  Alcotest.(check string)
    "at-event relation" "touching"
    (contact_relation_to_string (contact_evidence result).relation);
  check_vector_x "final sphere1 x" "4" result.final_sphere1.particle.position;
  check_vector_y "final sphere1 y" "0" result.final_sphere1.particle.position;
  check_vector_x "final sphere2 x" "3" result.final_sphere2.particle.position;
  check_vector_y "final sphere2 y" "2" result.final_sphere2.particle.position;
  Alcotest.(check bool) "momentum" true result.momentum_conserved;
  Alcotest.(check bool) "kinetic energy" true result.kinetic_energy_conserved

let test_irrational_crossing_defers_without_mutation () =
  let sphere1 = body ~id:"a" ~x:"0" ~y:"0" ~vx:"1" ~vy:"0" in
  let sphere2 = body ~id:"b" ~x:"3" ~y:"1" ~vx:"0" ~vy:"0" in
  let result =
    evolve_linear_sphere_pair_through_contact ~duration:(time "3") sphere1 sphere2
    |> deferred
  in
  Alcotest.(check string)
    "reason" "quadratic_irrational_event_time"
    (event_step_deferred_reason_to_string result.reason);
  Alcotest.(check string)
    "certificate" "crossing_contact"
    (linear_contact_status_to_string result.certificate.status);
  begin match result.certificate.first_contact_time with
  | Some (Quadratic_irrational_contact_time evidence) ->
      check_q "discriminant" "12" evidence.discriminant.si_value;
      check_q "bracket lower" "0" evidence.bracket_lower.si_value;
      check_q "bracket upper" "3" evidence.bracket_upper.si_value
  | _ -> Alcotest.fail "expected quadratic-irrational event evidence"
  end;
  Alcotest.(check bool) "sphere1 unchanged" true (sphere_equal sphere1 result.sphere1);
  Alcotest.(check bool) "sphere2 unchanged" true (sphere_equal sphere2 result.sphere2)

let test_initial_overlap_defers_without_mutation () =
  let sphere1 = body ~id:"a" ~x:"0" ~y:"0" ~vx:"1" ~vy:"0" in
  let sphere2 = body ~id:"b" ~x:"1" ~y:"0" ~vx:"0" ~vy:"0" in
  let result =
    evolve_linear_sphere_pair_through_contact ~duration:(time "1") sphere1 sphere2
    |> deferred
  in
  Alcotest.(check string)
    "reason" "initial_overlap"
    (event_step_deferred_reason_to_string result.reason);
  Alcotest.(check string)
    "certificate" "initially_overlapping"
    (linear_contact_status_to_string result.certificate.status);
  Alcotest.(check bool) "sphere1 unchanged" true (sphere_equal sphere1 result.sphere1);
  Alcotest.(check bool) "sphere2 unchanged" true (sphere_equal sphere2 result.sphere2)

let test_zero_duration_separated_is_unchanged_completion () =
  let sphere1 = body ~id:"a" ~x:"0" ~y:"0" ~vx:"1" ~vy:"0" in
  let sphere2 = body ~id:"b" ~x:"4" ~y:"0" ~vx:"0" ~vy:"0" in
  let result =
    evolve_linear_sphere_pair_through_contact ~duration:(time "0") sphere1 sphere2
    |> completed
  in
  Alcotest.(check string)
    "certificate" "no_contact_in_interval"
    (linear_contact_status_to_string result.certificate.status);
  Alcotest.(check bool) "state unchanged" false result.state_changed;
  Alcotest.(check bool) "sphere1 unchanged" true
    (sphere_equal sphere1 result.final_sphere1);
  Alcotest.(check bool) "sphere2 unchanged" true
    (sphere_equal sphere2 result.final_sphere2);
  Alcotest.(check bool) "momentum" true result.momentum_conserved;
  Alcotest.(check bool) "kinetic energy" true result.kinetic_energy_conserved

let () =
  Alcotest.run "centl physics rational contact event step"
    [
      ( "event step",
        [
          Alcotest.test_case "no contact" `Quick test_no_contact_advances_full_duration;
          Alcotest.test_case "rational crossing" `Quick
            test_rational_crossing_resolves_and_advances_remainder;
          Alcotest.test_case "touching start approaching" `Quick
            test_touching_at_start_approaching_resolves_immediately;
          Alcotest.test_case "touching start separating" `Quick
            test_touching_at_start_separating_does_not_impulse;
          Alcotest.test_case "tangent" `Quick test_tangent_contact_has_no_impulse;
          Alcotest.test_case "irrational crossing deferred" `Quick
            test_irrational_crossing_defers_without_mutation;
          Alcotest.test_case "initial overlap deferred" `Quick
            test_initial_overlap_defers_without_mutation;
          Alcotest.test_case "zero duration" `Quick
            test_zero_duration_separated_is_unchanged_completion;
        ] );
    ]
