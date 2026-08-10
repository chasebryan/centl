let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path =
  try Centl_sci_snapshot.remove_tree path with _ -> ()

let cell id kind text : Centl_sci_mirage_goal.spec_cell =
  { id; kind; text; start_line = id; end_line = id }

let build_readiness workspace =
  let graph =
    Centl_sci_mirage_goal.build workspace
      [ cell 1 "DIRECTIVE" "Implement quasar_flux_tensorization" ]
  in
  let obligations = Centl_sci_mirage_obligation.build graph in
  let candidates = Centl_sci_mirage_candidate.build graph obligations in
  Centl_sci_mirage_readiness.build obligations candidates

let build_report workspace =
  build_readiness workspace |> Centl_sci_mirage_execution_plan.build

let test_plan_contains_pending_work () =
  let root = temp_dir "centl-mirage-plan-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      let report = build_report workspace in
      match report.Centl_sci_mirage_execution_plan.candidates with
      | [ candidate ] ->
          Alcotest.(check bool) "has planned work" true
            (candidate.actions <> []);
          Alcotest.(check bool) "all actions planned" true
            (List.for_all
               (fun action -> String.equal action.Centl_sci_mirage_execution_plan.state "planned")
               candidate.actions);
          Alcotest.(check bool) "all actions have identities" true
            (List.for_all
               (fun action -> String.length action.Centl_sci_mirage_execution_plan.action_id = 64)
               candidate.actions);
          Alcotest.(check bool) "all actions name executors" true
            (List.for_all
               (fun action ->
                 not
                   (String.equal action.Centl_sci_mirage_execution_plan.executor
                      "unsupported_evidence_executor"))
               candidate.actions);
          Alcotest.(check bool) "all actions name preconditions" true
            (List.for_all
               (fun action ->
                 not
                   (String.equal action.Centl_sci_mirage_execution_plan.precondition
                      "explicit_executor_required"))
               candidate.actions);
          Alcotest.(check bool) "known obligations have supported executors" true
            (List.for_all
               (fun action -> action.Centl_sci_mirage_execution_plan.executor_supported)
               candidate.actions)
      | _ -> Alcotest.fail "expected one candidate")

let test_action_identity_is_deterministic_and_transaction_bound () =
  let make transaction_fingerprint =
    Centl_sci_mirage_execution_plan.action_id
      ~candidate_id:"candidate:cell:1:downstream_extension"
      ~transaction_fingerprint ~obligation_id:"obligation:1:candidate_parses"
      ~kind:"candidate_parses"
  in
  let first = make "transaction-a" in
  let second = make "transaction-a" in
  let changed = make "transaction-b" in
  Alcotest.(check string) "same transaction produces same action identity" first second;
  Alcotest.(check bool) "transaction drift changes action identity" true
    (not (String.equal first changed))

let test_execution_contracts_are_explicit () =
  let parser_executor, parser_precondition =
    Centl_sci_mirage_execution_plan.execution_contract "candidate_parses"
  in
  Alcotest.(check string) "parser executor" "candidate_parser_or_build" parser_executor;
  Alcotest.(check string) "parser precondition" "candidate_materialized" parser_precondition;
  let rollback_executor, rollback_precondition =
    Centl_sci_mirage_execution_plan.execution_contract "rollback_available"
  in
  Alcotest.(check string) "rollback executor" "workspace_snapshot" rollback_executor;
  Alcotest.(check string) "rollback precondition" "before_activation" rollback_precondition

let test_unsupported_executor_is_blocked () =
  let executor, precondition =
    Centl_sci_mirage_execution_plan.execution_contract "future_unimplemented_evidence"
  in
  let supported, reason = Centl_sci_mirage_execution_plan.executor_support executor in
  Alcotest.(check string) "unsupported executor" "unsupported_evidence_executor" executor;
  Alcotest.(check string) "explicit executor precondition" "explicit_executor_required"
    precondition;
  Alcotest.(check bool) "unsupported executor is not runnable" false supported;
  Alcotest.(check bool) "blocking reason is retained" true (Option.is_some reason)

let test_artifact_denies_execution () =
  let root = temp_dir "centl-mirage-plan-file-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      let readiness = build_readiness workspace in
      match
        Centl_sci_mirage_execution_plan.construct
          (Filename.concat root "design.readiness.json") readiness
      with
      | Error message -> Alcotest.fail message
      | Ok (path, _) ->
          let text = Yojson.Safe.from_file path |> Yojson.Safe.to_string in
          Alcotest.(check bool) "execution not performed" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"execution_performed\":false" text));
          Alcotest.(check bool) "assurance unchanged" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"assurance_promoted\":false" text));
          Alcotest.(check bool) "action identity semantics persisted" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"action_identity_semantics\"" text));
          Alcotest.(check bool) "executor semantics persisted" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"execution_contract_semantics\"" text));
          Alcotest.(check bool) "executor persisted" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"executor\":\"candidate_parser_or_build\"" text));
          Alcotest.(check bool) "executor support persisted" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"executor_supported\":true" text)))

let () =
  Alcotest.run "CENTL-MIRAGE execution plan"
    [
      ( "planning",
        [
          Alcotest.test_case "pending work is planned" `Quick test_plan_contains_pending_work;
          Alcotest.test_case "action identity is transaction-bound" `Quick
            test_action_identity_is_deterministic_and_transaction_bound;
          Alcotest.test_case "execution contracts are explicit" `Quick
            test_execution_contracts_are_explicit;
          Alcotest.test_case "unsupported executors remain blocked" `Quick
            test_unsupported_executor_is_blocked;
          Alcotest.test_case "artifact does not claim execution" `Quick
            test_artifact_denies_execution;
        ] );
    ]
