open Centl_physics

let q = Q.of_string

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let expect_physics_error message f =
  match f () with
  | () -> Alcotest.fail (message ^ ": expected Physics_error")
  | exception Physics_error _ -> ()

let test_units_and_dimensions () =
  let distance = quantity (q "100") "cm" in
  check_q "100 cm = 1 m" Q.one (convert distance "m");
  let energy = quantity (q "2.5") "J" in
  check_q "joule round-trip" (q "5/2") (convert energy "J");
  expect_physics_error "length + time rejected" (fun () ->
      ignore (quantity_add (quantity Q.one "m") (quantity Q.one "s")))

let test_vectors () =
  let a = vector3 ~unit_symbol:"m" (q "1") (q "2") (q "3") in
  let b = vector3 ~unit_symbol:"m" (q "4") (q "5") (q "6") in
  let dot = vector_dot a b in
  check_q "dot product" (q "32") dot.si_value;
  Alcotest.(check string)
    "dot dimension" "m^2"
    (dimension_to_string dot.quantity_dimension)

let test_exact_gravity_simulation () =
  let body =
    particle ~id:"test"
      ~mass:(quantity (q "2") "kg")
      ~position:(vector3 ~unit_symbol:"m" Q.zero Q.zero (q "10"))
      ~velocity:(vector3 ~unit_symbol:"m/s" Q.one Q.zero Q.zero)
  in
  let gravity =
    uniform_gravity (vector3 ~unit_symbol:"m/s^2" Q.zero Q.zero (q "-10"))
  in
  let trajectory =
    simulate ~steps:10 ~dt:(quantity (q "1/10") "s") ~forces:[ gravity ] body
  in
  Alcotest.(check int)
    "trajectory includes initial state" 11 (List.length trajectory);
  let final = final_state trajectory in
  check_q "x after one second" Q.one final.position.x;
  check_q "z after symplectic steps" (q "9/2") final.position.z;
  check_q "vx unchanged" Q.one final.velocity.x;
  check_q "vz after one second" (q "-10") final.velocity.z

let test_force_models_and_energy () =
  let body =
    particle ~id:"energy"
      ~mass:(quantity (q "2") "kg")
      ~position:(vector3 ~unit_symbol:"m" (q "3") Q.zero Q.zero)
      ~velocity:(vector3 ~unit_symbol:"m/s" (q "3") (q "4") Q.zero)
  in
  check_q "kinetic energy" (q "25") (convert (kinetic_energy body) "J");
  let spring =
    hooke_force
      ~anchor:(vector3 ~unit_symbol:"m" Q.zero Q.zero Q.zero)
      ~stiffness:(quantity (q "2") "N/m")
  in
  let force = spring body in
  check_q "spring force x" (q "-6") force.x;
  check_q "spring potential" (q "9")
    (convert
       (spring_potential
          ~anchor:(vector3 ~unit_symbol:"m" Q.zero Q.zero Q.zero)
          ~stiffness:(quantity (q "2") "N/m")
          body)
       "J")

let test_elastic_collision () =
  let v1, v2 =
    elastic_collision_1d
      ~mass1:(quantity (q "2") "kg")
      ~velocity1:(quantity (q "3") "m/s")
      ~mass2:(quantity Q.one "kg")
      ~velocity2:(quantity (q "-1") "m/s")
  in
  check_q "v1 final" (q "1/3") (convert v1 "m/s");
  check_q "v2 final" (q "13/3") (convert v2 "m/s");
  let initial_momentum = q "5" in
  let final_momentum =
    Q.add (Q.mul (q "2") (convert v1 "m/s")) (convert v2 "m/s")
  in
  check_q "momentum conserved" initial_momentum final_momentum;
  let initial_ke = q "19/2" in
  let final_ke =
    Q.add
      (Q.mul (convert v1 "m/s") (convert v1 "m/s"))
      (Q.mul (q "1/2") (Q.mul (convert v2 "m/s") (convert v2 "m/s")))
  in
  check_q "kinetic energy conserved" initial_ke final_ke

let test_constants () =
  let c = constant "c" in
  check_q "speed of light exact" (q "299792458")
    (convert c.constant_value "m/s");
  Alcotest.(check bool) "constant exact" true c.exact_value

let () =
  Alcotest.run "centl physics"
    [
      ( "physics",
        [
          Alcotest.test_case "units and dimensions" `Quick
            test_units_and_dimensions;
          Alcotest.test_case "vectors" `Quick test_vectors;
          Alcotest.test_case "exact gravity simulation" `Quick
            test_exact_gravity_simulation;
          Alcotest.test_case "force models and energy" `Quick
            test_force_models_and_energy;
          Alcotest.test_case "elastic collision" `Quick test_elastic_collision;
          Alcotest.test_case "constants" `Quick test_constants;
        ] );
    ]
