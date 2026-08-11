let action action_id =
  {
    Centl_sci_mirage_execution_plan.action_id;
    candidate_id = "candidate-1";
    obligation_id = "obligation-1";
    kind = "mandatory_regression";
    executor = "deterministic_regression_gate";
    precondition = "candidate_materialized";
    executor_supported = true;
    blocking_reason = None;
    state = "planned";
  }

let plan action blocked_cells =
  {
    Centl_sci_mirage_execution_plan.candidates =
      [
        {
          candidate_id = "candidate-1";
          transaction_fingerprint = String.make 64 'a';
          actions = [ action ];
        };
      ];
    blocked_cells;
  }

let evidence receipt =
  { Centl_sci_mirage_evidence.receipts = [ receipt ]; blocked_cells = [] }

let only_candidate report =
  match report.Centl_sci_mirage_admission.candidates with
  | [ candidate ] -> candidate
  | _ -> Alcotest.fail "expected exactly one admission candidate"

let test_all_passed_is_admissible () =
  let action = action (String.make 64 '1') in
  let receipt =
    Centl_sci_mirage_evidence.make_receipt action Centl_sci_mirage_evidence.Passed
      "deterministic regression gate passed" None
  in
  let candidate =
    Centl_sci_mirage_admission.assess (plan action []) (evidence receipt)
    |> only_candidate
  in
  Alcotest.(check string) "state" "admissible"
    (Centl_sci_mirage_admission.state_text candidate.state);
  Alcotest.(check bool) "exact coverage" true candidate.exact_action_coverage;
  Alcotest.(check int) "passed" 1 candidate.passed_action_count

let test_pending_stays_pending () =
  let action = action (String.make 64 '2') in
  let receipt =
    Centl_sci_mirage_evidence.make_receipt action Centl_sci_mirage_evidence.Pending
      "validator has not run" None
  in
  let candidate =
    Centl_sci_mirage_admission.assess (plan action []) (evidence receipt)
    |> only_candidate
  in
  Alcotest.(check string) "state" "pending"
    (Centl_sci_mirage_admission.state_text candidate.state)

let test_receipt_identity_mismatch_blocks () =
  let planned = action (String.make 64 '3') in
  let other = action (String.make 64 '4') in
  let receipt =
    Centl_sci_mirage_evidence.make_receipt other Centl_sci_mirage_evidence.Passed
      "unrelated action passed" None
  in
  let candidate =
    Centl_sci_mirage_admission.assess (plan planned []) (evidence receipt)
    |> only_candidate
  in
  Alcotest.(check string) "state" "blocked"
    (Centl_sci_mirage_admission.state_text candidate.state);
  Alcotest.(check bool) "exact coverage" false candidate.exact_action_coverage

let test_source_block_prevents_admission () =
  let action = action (String.make 64 '5') in
  let receipt =
    Centl_sci_mirage_evidence.make_receipt action Centl_sci_mirage_evidence.Passed
      "deterministic regression gate passed" None
  in
  let candidate =
    Centl_sci_mirage_admission.assess (plan action [ 7 ]) (evidence receipt)
    |> only_candidate
  in
  Alcotest.(check string) "state" "blocked"
    (Centl_sci_mirage_admission.state_text candidate.state)

let test_json_denies_activation_and_promotion () =
  let action = action (String.make 64 '6') in
  let receipt =
    Centl_sci_mirage_evidence.make_receipt action Centl_sci_mirage_evidence.Passed
      "deterministic regression gate passed" None
  in
  let json =
    Centl_sci_mirage_admission.assess (plan action []) (evidence receipt)
    |> Centl_sci_mirage_admission.to_json
  in
  let open Yojson.Safe.Util in
  Alcotest.(check bool) "source activation" false
    (json |> member "candidate_source_activated" |> to_bool);
  Alcotest.(check bool) "assurance promotion" false
    (json |> member "assurance_promoted" |> to_bool)

let () =
  Alcotest.run "CENTL-SCi MIRAGE admission"
    [
      ( "admission",
        [
          Alcotest.test_case "all passed" `Quick test_all_passed_is_admissible;
          Alcotest.test_case "pending" `Quick test_pending_stays_pending;
          Alcotest.test_case "identity mismatch" `Quick
            test_receipt_identity_mismatch_blocks;
          Alcotest.test_case "source block" `Quick test_source_block_prevents_admission;
          Alcotest.test_case "non activation" `Quick
            test_json_denies_activation_and_promotion;
        ] );
    ]
