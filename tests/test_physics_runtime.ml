open Centl_physics

let body () =
  particle ~id:"body" ~mass:(quantity Q.one "kg")
    ~position:(vector3 ~unit_symbol:"m" Q.zero Q.zero Q.zero)
    ~velocity:(vector3 ~unit_symbol:"m/s" Q.one Q.zero Q.zero)

let test_final_only_execution () =
  let dt = quantity (Q.of_string "1/100") "s" in
  let final, trajectory =
    Centl_physics_jsonl.run_simulation ~include_trajectory:false ~steps:10_000
      ~dt ~forces:[] (body ())
  in
  begin match trajectory with
  | None -> ()
  | Some _ -> Alcotest.fail "final-only execution materialized a trajectory"
  end;
  Alcotest.(check string) "final x" "100" (Q.to_string final.position.x);
  Alcotest.(check string) "final vx" "1" (Q.to_string final.velocity.x)

let test_trajectory_execution () =
  let dt = quantity Q.one "s" in
  let final, trajectory =
    Centl_physics_jsonl.run_simulation ~include_trajectory:true ~steps:3 ~dt
      ~forces:[] (body ())
  in
  Alcotest.(check string) "final x" "3" (Q.to_string final.position.x);
  match trajectory with
  | Some states -> Alcotest.(check int) "states" 4 (List.length states)
  | None -> Alcotest.fail "trajectory execution did not retain states"

let test_cooperative_cancellation () =
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 3
  in
  let dt = quantity (Q.of_string "1/100") "s" in
  begin try
    ignore
      (Centl_physics_jsonl.run_simulation ~cancelled ~include_trajectory:false
         ~steps:100_000 ~dt ~forces:[] (body ()));
    Alcotest.fail "cancelled simulation completed"
  with Centl_physics_jsonl.Physics_cancelled -> ()
  end;
  Alcotest.(check bool) "multiple cancellation checkpoints" true (!checks >= 3)

let () =
  Alcotest.run "centl physics runtime"
    [
      ( "runtime",
        [
          Alcotest.test_case "final-only execution" `Quick
            test_final_only_execution;
          Alcotest.test_case "trajectory execution" `Quick
            test_trajectory_execution;
          Alcotest.test_case "cooperative cancellation" `Quick
            test_cooperative_cancellation;
        ] );
    ]
