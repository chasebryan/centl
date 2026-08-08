open Centl_physics
open Centl_physics_collision

let q = Q.of_string

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let body ~id ~mass ~position:(px, py, pz) ~velocity:(vx, vy, vz) =
  particle ~id ~mass:(quantity (q mass) "kg")
    ~position:(vector3 ~unit_symbol:"m" (q px) (q py) (q pz))
    ~velocity:(vector3 ~unit_symbol:"m/s" (q vx) (q vy) (q vz))

let vector_equal a b =
  Q.equal a.x b.x && Q.equal a.y b.y && Q.equal a.z b.z

let total_momentum a b = vector_add (momentum a) (momentum b)
let total_energy a b = quantity_add (kinetic_energy a) (kinetic_energy b)

let check_invariants initial1 initial2 final1 final2 =
  Alcotest.(check bool)
    "momentum conserved" true
    (vector_equal
       (total_momentum initial1 initial2)
       (total_momentum final1 final2));
  check_q "kinetic energy conserved"
    (total_energy initial1 initial2).si_value
    (total_energy final1 final2).si_value

let test_head_on_matches_1d () =
  let p1 =
    body ~id:"p1" ~mass:"2" ~position:("-1", "0", "0")
      ~velocity:("3", "0", "0")
  in
  let p2 =
    body ~id:"p2" ~mass:"1" ~position:("1", "0", "0")
      ~velocity:("-1", "0", "0")
  in
  let result = elastic_collision_3d_at_contact p1 p2 in
  Alcotest.(check string)
    "resolved" "resolved" (contact_status_to_string result.status);
  check_q "v1 x" (q "1/3") result.particle1.velocity.x;
  check_q "v2 x" (q "13/3") result.particle2.velocity.x;
  check_q "v1 y" Q.zero result.particle1.velocity.y;
  check_q "v2 z" Q.zero result.particle2.velocity.z;
  check_invariants p1 p2 result.particle1 result.particle2

let test_oblique_exact_response () =
  let p1 =
    body ~id:"p1" ~mass:"1" ~position:("0", "0", "0")
      ~velocity:("1", "0", "0")
  in
  let p2 =
    body ~id:"p2" ~mass:"1" ~position:("1", "1", "0")
      ~velocity:("0", "0", "0")
  in
  let result = elastic_collision_3d_at_contact p1 p2 in
  check_q "p1 vx" (q "1/2") result.particle1.velocity.x;
  check_q "p1 vy" (q "-1/2") result.particle1.velocity.y;
  check_q "p2 vx" (q "1/2") result.particle2.velocity.x;
  check_q "p2 vy" (q "1/2") result.particle2.velocity.y;
  check_invariants p1 p2 result.particle1 result.particle2

let test_separating_particles_receive_no_impulse () =
  let p1 =
    body ~id:"p1" ~mass:"1" ~position:("-1", "0", "0")
      ~velocity:("-1", "0", "0")
  in
  let p2 =
    body ~id:"p2" ~mass:"1" ~position:("1", "0", "0")
      ~velocity:("1", "0", "0")
  in
  let result = elastic_collision_3d_at_contact p1 p2 in
  Alcotest.(check string)
    "no impulse" "separating_or_stationary"
    (contact_status_to_string result.status);
  Alcotest.(check bool)
    "p1 velocity unchanged" true
    (vector_equal p1.velocity result.particle1.velocity);
  Alcotest.(check bool)
    "p2 velocity unchanged" true
    (vector_equal p2.velocity result.particle2.velocity)

let test_coincident_centers_rejected () =
  let p1 =
    body ~id:"p1" ~mass:"1" ~position:("0", "0", "0")
      ~velocity:("1", "0", "0")
  in
  let p2 =
    body ~id:"p2" ~mass:"1" ~position:("0", "0", "0")
      ~velocity:("-1", "0", "0")
  in
  match elastic_collision_3d_at_contact p1 p2 with
  | _ -> Alcotest.fail "coincident centers must be rejected"
  | exception Physics_error _ -> ()

let () =
  Alcotest.run "centl exact 3D collision"
    [
      ( "collision",
        [
          Alcotest.test_case "head-on matches 1D" `Quick
            test_head_on_matches_1d;
          Alcotest.test_case "oblique exact response" `Quick
            test_oblique_exact_response;
          Alcotest.test_case "separating no impulse" `Quick
            test_separating_particles_receive_no_impulse;
          Alcotest.test_case "coincident centers" `Quick
            test_coincident_centers_rejected;
        ] );
    ]
