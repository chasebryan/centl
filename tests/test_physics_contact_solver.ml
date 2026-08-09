open Centl_physics
open Centl_physics_collision
open Centl_physics_world
open Centl_physics_contact_solver

let q = Q.of_string

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let body ~id ~position:(px, py, pz) ~velocity:(vx, vy, vz) =
  particle ~id ~mass:(quantity Q.one "kg")
    ~position:(vector3 ~unit_symbol:"m" (q px) (q py) (q pz))
    ~velocity:(vector3 ~unit_symbol:"m/s" (q vx) (q vy) (q vz))

let sphere_body ~id ~position ~velocity =
  sphere ~particle:(body ~id ~position ~velocity) ~radius:(quantity Q.one "m")

let sphere_by_id_exn state id =
  match
    List.find_opt
      (fun sphere -> String.equal sphere.particle.id id)
      state.spheres
  with
  | Some sphere -> sphere
  | None -> Alcotest.fail ("missing sphere: " ^ id)

let pair_key (pair : pair_resolution) = pair.particle1_id ^ pair.particle2_id

let check_pair_status message expected (pair : pair_resolution) =
  Alcotest.(check string)
    message expected
    (contact_status_to_string pair.status)

let test_single_touching_pair_resolves () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("2", "0", "0") ~velocity:("-1", "0", "0")
  in
  match resolve_isolated_elastic_touching_contacts (sphere_world [ a; b ]) with
  | Deferred _ -> Alcotest.fail "isolated touching pair must resolve"
  | Completed result ->
      Alcotest.(check bool) "momentum conserved" true result.momentum_conserved;
      Alcotest.(check bool)
        "energy conserved" true result.kinetic_energy_conserved;
      Alcotest.(check int)
        "one pair response" 1
        (List.length result.pair_resolutions);
      let pair = List.hd result.pair_resolutions in
      Alcotest.(check string) "pair ids" "ab" (pair_key pair);
      check_pair_status "pair resolved" "resolved" pair;
      let final_a = sphere_by_id_exn result.world "a" in
      let final_b = sphere_by_id_exn result.world "b" in
      check_q "a vx exchanged" (q "-1") final_a.particle.velocity.x;
      check_q "b vx exchanged" (q "1") final_b.particle.velocity.x;
      check_q "a position unchanged" Q.zero final_a.particle.position.x;
      check_q "b position unchanged" (q "2") final_b.particle.position.x

let test_touching_separating_pair_has_no_impulse () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("-1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("2", "0", "0") ~velocity:("1", "0", "0")
  in
  match resolve_isolated_elastic_touching_contacts (sphere_world [ a; b ]) with
  | Deferred _ -> Alcotest.fail "separating touching pair is still unambiguous"
  | Completed result ->
      let pair = List.hd result.pair_resolutions in
      check_pair_status "no impulse" "separating_or_stationary" pair;
      check_q "a vx unchanged" (q "-1")
        (sphere_by_id_exn result.world "a").particle.velocity.x;
      check_q "b vx unchanged" (q "1")
        (sphere_by_id_exn result.world "b").particle.velocity.x

let test_separated_world_completes_without_pairs () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("3", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("3", "0", "0") ~velocity:("-2", "0", "0")
  in
  match resolve_isolated_elastic_touching_contacts (sphere_world [ a; b ]) with
  | Deferred _ -> Alcotest.fail "separated world must not defer"
  | Completed result ->
      Alcotest.(check int)
        "no pair responses" 0
        (List.length result.pair_resolutions);
      Alcotest.(check bool) "momentum conserved" true result.momentum_conserved;
      Alcotest.(check bool)
        "energy conserved" true result.kinetic_energy_conserved;
      check_q "a vx unchanged" (q "3")
        (sphere_by_id_exn result.world "a").particle.velocity.x

let test_overlap_defers_unchanged () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("1", "0", "0") ~velocity:("-1", "0", "0")
  in
  let initial = sphere_world [ a; b ] in
  match resolve_isolated_elastic_touching_contacts initial with
  | Completed _ -> Alcotest.fail "overlap must defer the whole operation"
  | Deferred (returned, Overlap_detected overlaps) ->
      Alcotest.(check int) "one overlap" 1 (List.length overlaps);
      check_q "a vx unchanged" (q "1")
        (sphere_by_id_exn returned "a").particle.velocity.x;
      check_q "b vx unchanged" (q "-1")
        (sphere_by_id_exn returned "b").particle.velocity.x
  | Deferred (_, Ambiguous_simultaneous_contacts _) ->
      Alcotest.fail "overlap must take precedence over ambiguity"

let test_shared_touching_particle_defers () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("2", "0", "0") ~velocity:("0", "0", "0")
  in
  let c =
    sphere_body ~id:"c" ~position:("4", "0", "0") ~velocity:("-1", "0", "0")
  in
  match
    resolve_isolated_elastic_touching_contacts (sphere_world [ a; b; c ])
  with
  | Completed _ -> Alcotest.fail "shared simultaneous contact must defer"
  | Deferred (_, Overlap_detected _) -> Alcotest.fail "no pair overlaps"
  | Deferred (returned, Ambiguous_simultaneous_contacts ids) ->
      Alcotest.(check (list string))
        "only shared particle is ambiguous" [ "b" ] ids;
      check_q "shared particle unchanged" Q.zero
        (sphere_by_id_exn returned "b").particle.velocity.x

let test_two_disjoint_touching_pairs_resolve () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("1", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("2", "0", "0") ~velocity:("-1", "0", "0")
  in
  let c =
    sphere_body ~id:"c" ~position:("10", "0", "0") ~velocity:("3", "0", "0")
  in
  let d =
    sphere_body ~id:"d" ~position:("12", "0", "0") ~velocity:("1", "0", "0")
  in
  match
    resolve_isolated_elastic_touching_contacts (sphere_world [ a; b; c; d ])
  with
  | Deferred _ -> Alcotest.fail "disjoint touching matching must resolve"
  | Completed result ->
      let pair_keys = List.map pair_key result.pair_resolutions in
      Alcotest.(check (list string))
        "deterministic pair order" [ "ab"; "cd" ] pair_keys;
      Alcotest.(check bool)
        "world momentum conserved" true result.momentum_conserved;
      Alcotest.(check bool)
        "world energy conserved" true result.kinetic_energy_conserved;
      check_q "a vx" (q "-1")
        (sphere_by_id_exn result.world "a").particle.velocity.x;
      check_q "b vx" (q "1")
        (sphere_by_id_exn result.world "b").particle.velocity.x;
      check_q "c vx" (q "1")
        (sphere_by_id_exn result.world "c").particle.velocity.x;
      check_q "d vx" (q "3")
        (sphere_by_id_exn result.world "d").particle.velocity.x

let test_overlap_precedes_contact_ambiguity () =
  let a =
    sphere_body ~id:"a" ~position:("0", "0", "0") ~velocity:("0", "0", "0")
  in
  let b =
    sphere_body ~id:"b" ~position:("1", "0", "0") ~velocity:("0", "0", "0")
  in
  let c =
    sphere_body ~id:"c" ~position:("3", "0", "0") ~velocity:("0", "0", "0")
  in
  let d =
    sphere_body ~id:"d" ~position:("5", "0", "0") ~velocity:("0", "0", "0")
  in
  match
    resolve_isolated_elastic_touching_contacts (sphere_world [ a; b; c; d ])
  with
  | Completed _ -> Alcotest.fail "overlap must defer"
  | Deferred (_, Overlap_detected overlaps) ->
      Alcotest.(check int) "one penetrating pair" 1 (List.length overlaps)
  | Deferred (_, Ambiguous_simultaneous_contacts _) ->
      Alcotest.fail "penetration must be reported before contact ambiguity"

let () =
  Alcotest.run "centl isolated contact composition"
    [
      ( "contact composition",
        [
          Alcotest.test_case "single pair resolves" `Quick
            test_single_touching_pair_resolves;
          Alcotest.test_case "separating pair no impulse" `Quick
            test_touching_separating_pair_has_no_impulse;
          Alcotest.test_case "separated world" `Quick
            test_separated_world_completes_without_pairs;
          Alcotest.test_case "overlap defers" `Quick
            test_overlap_defers_unchanged;
          Alcotest.test_case "shared touching particle defers" `Quick
            test_shared_touching_particle_defers;
          Alcotest.test_case "two disjoint pairs" `Quick
            test_two_disjoint_touching_pairs_resolve;
          Alcotest.test_case "overlap precedence" `Quick
            test_overlap_precedes_contact_ambiguity;
        ] );
    ]
