let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path =
  try Centl_sci_snapshot.remove_tree path with _ -> ()

let action ?(supported = true) ?blocking_reason ~id ~kind ~executor ~precondition () :
    Centl_sci_mirage_execution_plan.action =
  {
    action_id = id;
    candidate_id = "candidate:1";
    obligation_id = "obligation:1";
    kind;
    executor;
    precondition;
    executor_supported = supported;
    blocking_reason;
    state = "planned";
  }

let plan actions : Centl_sci_mirage_execution_plan.report =
  {
    candidates =
      [
        {
          Centl_sci_mirage_execution_plan.candidate_id = "candidate:1";
          transaction_fingerprint = String.make 64 'a';
          actions;
        };
      ];
    blocked_cells = [];
  }

let test_workspace_snapshot_executes () =
  let root = temp_dir "centl-mirage-evidence-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      Centl_sci_workspace.ensure workspace;
      let report =
        Centl_sci_mirage_evidence.execute workspace
          (plan
             [
               action ~id:"snapshot-action" ~kind:"rollback_available"
                 ~executor:"workspace_snapshot" ~precondition:"before_activation" ();
             ])
      in
      Alcotest.(check bool) "single passed action completes evidence cycle" true
        (Centl_sci_mirage_evidence.evidence_complete report);
      match report.receipts with
      | [ receipt ] ->
          Alcotest.(check string) "snapshot passes" "passed"
            (Centl_sci_mirage_evidence.receipt_state_text receipt.state);
          Alcotest.(check bool) "snapshot path exists" true
            (match receipt.snapshot_path with
            | Some path -> Sys.file_exists path
            | None -> false)
      | _ -> Alcotest.fail "expected one evidence receipt")

let test_snapshot_actions_share_one_cycle_snapshot () =
  let root = temp_dir "centl-mirage-evidence-shared-snapshot-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      Centl_sci_workspace.ensure workspace;
      let report =
        Centl_sci_mirage_evidence.execute workspace
          (plan
             [
               action ~id:"snapshot-action-1" ~kind:"rollback_available"
                 ~executor:"workspace_snapshot" ~precondition:"before_activation" ();
               action ~id:"snapshot-action-2" ~kind:"rollback_available"
                 ~executor:"workspace_snapshot" ~precondition:"before_activation" ();
             ])
      in
      match report.receipts with
      | [ first; second ] ->
          Alcotest.(check string) "first snapshot passes" "passed"
            (Centl_sci_mirage_evidence.receipt_state_text first.state);
          Alcotest.(check string) "second snapshot passes" "passed"
            (Centl_sci_mirage_evidence.receipt_state_text second.state);
          Alcotest.(check bool) "both obligations share one snapshot" true
            (match (first.snapshot_path, second.snapshot_path) with
            | Some left, Some right -> left = right
            | _ -> false);
          Alcotest.(check int) "one retained snapshot directory" 1
            (Array.length (Sys.readdir (Centl_sci_snapshot.snapshot_root workspace)))
      | _ -> Alcotest.fail "expected two evidence receipts")

let test_unimplemented_executor_stays_pending () =
  let root = temp_dir "centl-mirage-evidence-pending-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      let report =
        Centl_sci_mirage_evidence.execute workspace
          (plan
             [
               action ~id:"regression-action" ~kind:"mandatory_regression"
                 ~executor:"deterministic_regression_gate"
                 ~precondition:"candidate_materialized" ();
             ])
      in
      Alcotest.(check bool) "pending evidence is not complete" false
        (Centl_sci_mirage_evidence.evidence_complete report);
      match report.receipts with
      | [ receipt ] ->
          Alcotest.(check string) "not fabricated as executed" "pending"
            (Centl_sci_mirage_evidence.receipt_state_text receipt.state)
      | _ -> Alcotest.fail "expected one evidence receipt")

let test_unsupported_executor_is_blocked () =
  let root = temp_dir "centl-mirage-evidence-blocked-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      let report =
        Centl_sci_mirage_evidence.execute workspace
          (plan
             [
               action ~supported:false
                 ~blocking_reason:"requires a human product decision" ~id:"human-action"
                 ~kind:"clarification_required" ~executor:"human_resolution"
                 ~precondition:"blocking_requirement_resolved" ();
             ])
      in
      Alcotest.(check bool) "blocked evidence is not complete" false
        (Centl_sci_mirage_evidence.evidence_complete report);
      match report.receipts with
      | [ receipt ] ->
          Alcotest.(check string) "unsupported executor blocks" "blocked"
            (Centl_sci_mirage_evidence.receipt_state_text receipt.state)
      | _ -> Alcotest.fail "expected one evidence receipt")

let test_persisted_receipts_deny_activation () =
  let root = temp_dir "centl-mirage-evidence-json-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      Centl_sci_workspace.ensure workspace;
      let execution_path = Filename.concat root "design.execution-plan.json" in
      match
        Centl_sci_mirage_evidence.construct workspace execution_path
          (plan
             [
               action ~id:"snapshot-action" ~kind:"rollback_available"
                 ~executor:"workspace_snapshot" ~precondition:"before_activation" ();
             ])
      with
      | Error message -> Alcotest.fail message
      | Ok (path, _) ->
          let json = Yojson.Safe.from_file path in
          let open Yojson.Safe.Util in
          Alcotest.(check int) "passed count" 1
            (json |> member "passed_action_count" |> to_int);
          Alcotest.(check int) "pending count" 0
            (json |> member "pending_action_count" |> to_int);
          Alcotest.(check int) "blocked count" 0
            (json |> member "blocked_action_count" |> to_int);
          Alcotest.(check bool) "named evidence cycle is complete" true
            (json |> member "evidence_complete" |> to_bool);
          Alcotest.(check bool) "candidate remains inactive" false
            (json |> member "candidate_source_activated" |> to_bool);
          Alcotest.(check bool) "assurance remains unpromoted" false
            (json |> member "assurance_promoted" |> to_bool))

let () =
  Alcotest.run "CENTL-MIRAGE evidence execution"
    [
      ( "execution",
        [
          Alcotest.test_case "workspace snapshot" `Quick test_workspace_snapshot_executes;
          Alcotest.test_case "shared cycle snapshot" `Quick
            test_snapshot_actions_share_one_cycle_snapshot;
          Alcotest.test_case "unimplemented executor" `Quick
            test_unimplemented_executor_stays_pending;
          Alcotest.test_case "unsupported executor" `Quick
            test_unsupported_executor_is_blocked;
          Alcotest.test_case "persist receipts" `Quick
            test_persisted_receipts_deny_activation;
        ] );
    ]
