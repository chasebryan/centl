open Centl_physics
open Centl_physics_world

let q = Q.of_string

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let body ~id ~mass ~position:(px, py, pz) ~velocity:(vx, vy, vz) =
  particle ~id
    ~mass:(quantity (q mass) "kg")
    ~position:(vector3 ~unit_symbol:"m" (q px) (q py) (q pz))
    ~velocity:(vector3 ~unit_symbol:"m/s" (q vx) (q vy) (q vz))

let sphere_body ~id ~position ~radius =
  sphere
    ~particle:(body ~id ~mass:"1" ~position ~velocity:("0", "0", "0"))
    ~radius:(quantity (q radius) "m")

let test_world_diagnostics () =
  let p1 =
    body ~id:"p1" ~mass:"2" ~position:("0", "0", "0")
      ~velocity:("1", "0", "0")
  in
  let p2 =
    body ~id:"p2" ~mass:"1" ~position:("1", "0", "0")
      ~velocity:("-2", "0", "0")
  in
  let world = world [ p1; p2 ] in
  let momentum = world_momentum world in
  check_q "total momentum x" Q.zero momentum.x;
  check_q "total momentum y" Q.zero momentum.y;
  check_q "total kinetic energy" (q "3")
    (world_kinetic_energy world).si_value

let test_world_rejects_duplicate_ids () =
  let p1 =
    body ~id:"same" ~mass:"1" ~position:("0", "0", "0")
      ~velocity:("0", "0", "0")
  in
  let p2 =
    body ~id:"same" ~mass:"1" ~position:("1", "0", "0")
      ~velocity:("0", "0", "0")
  in
  match world [ p1; p2 ] with
  | _ -> Alcotest.fail "duplicate world ids must be rejected"
  | exception Physics_error _ -> ()

let test_world_step_is_exact_and_ordered () =
  let p1 =
    body ~id:"p1" ~mass:"1" ~position:("0", "0", "0")
      ~velocity:("0", "0", "0")
  in
  let p2 =
    body ~id:"p2" ~mass:"3" ~position:("2", "0", "0")
      ~velocity:("1", "0", "0")
  in
  let gravity =
    uniform_gravity (vector3 ~unit_symbol:"m/s^2" Q.zero (q "-10") Q.zero)
  in
  let stepped =
    step_world_symplectic_euler ~dt:(quantity (q "1/10") "s")
      ~forces:[ gravity ] (world [ p1; p2 ])
  in
  match stepped.particles with
  | [ final1; final2 ] ->
      Alcotest.(check string) "first id preserved" "p1" final1.id;
      Alcotest.(check string) "second id preserved" "p2" final2.id;
      check_q "p1 vy" (q "-1") final1.velocity.y;
      check_q "p1 y" (q "-1/10") final1.position.y;
      check_q "p2 x" (q "21/10") final2.position.x;
      check_q "p2 vy" (q "-1") final2.velocity.y
  | _ -> Alcotest.fail "world step must preserve particle count and order"

let check_relation message expected contact =
  Alcotest.(check string) message expected
    (contact_relation_to_string contact.relation)

let test_exact_sphere_contact_relations () =
  let first = sphere_body ~id:"a" ~position:("0", "0", "0") ~radius:"1" in
  let touching =
    sphere_body ~id:"b" ~position:("2", "0", "0") ~radius:"1"
  in
  let separated =
    sphere_body ~id:"c" ~position:("3", "0", "0") ~radius:"1"
  in
  let overlapping =
    sphere_body ~id:"d" ~position:("1", "0", "0") ~radius:"1"
  in
  let touching_contact = classify_sphere_contact first touching in
  check_relation "touching" "touching" touching_contact;
  check_q "touching distance squared" (q "4")
    touching_contact.distance_squared.si_value;
  check_q "touching radius sum squared" (q "4")
    touching_contact.radius_sum_squared.si_value;
  check_relation "separated" "separated"
    (classify_sphere_contact first separated);
  check_relation "overlapping" "overlapping"
    (classify_sphere_contact first overlapping)

let test_fractional_touching_without_square_root () =
  let first =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~radius:"1/2"
  in
  let second =
    sphere_body ~id:"b" ~position:("3/2", "0", "0") ~radius:"1"
  in
  let contact = classify_sphere_contact first second in
  check_relation "fractional touching" "touching" contact;
  check_q "fractional distance squared" (q "9/4") contact.distance_squared.si_value;
  check_q "fractional radius sum squared" (q "9/4")
    contact.radius_sum_squared.si_value

let test_pair_order_is_deterministic () =
  let a = sphere_body ~id:"a" ~position:("0", "0", "0") ~radius:"1" in
  let b = sphere_body ~id:"b" ~position:("2", "0", "0") ~radius:"1" in
  let c = sphere_body ~id:"c" ~position:("5", "0", "0") ~radius:"1" in
  let contacts = classify_sphere_contacts (sphere_world [ a; b; c ]) in
  let pairs =
    List.map
      (fun contact -> contact.particle1_id ^ contact.particle2_id)
      contacts
  in
  Alcotest.(check (list string)) "pair order" [ "ab"; "ac"; "bc" ] pairs;
  let touching = touching_contacts (sphere_world [ a; b; c ]) in
  Alcotest.(check int) "one exact touching pair" 1 (List.length touching)

let () =
  Alcotest.run "centl deterministic physics world"
    [
      ( "world",
        [
          Alcotest.test_case "exact diagnostics" `Quick test_world_diagnostics;
          Alcotest.test_case "duplicate ids" `Quick test_world_rejects_duplicate_ids;
          Alcotest.test_case "exact ordered step" `Quick
            test_world_step_is_exact_and_ordered;
          Alcotest.test_case "sphere contact relations" `Quick
            test_exact_sphere_contact_relations;
          Alcotest.test_case "fractional touching" `Quick
            test_fractional_touching_without_square_root;
          Alcotest.test_case "deterministic pair order" `Quick
            test_pair_order_is_deterministic;
        ] );
    ]
