let usage () =
  String.concat "\n"
    [
      "Usage:";
      "  centl-mirage start PATH";
      "  centl-mirage ingest PATH";
      "  centl-mirage analyze SPEC_IR.json";
      "  centl-mirage status";
      "";
      "CENTL-MIRAGE is the local self-development engine for CENTL-SCi.";
    ]

let workspace_or_exit () =
  match Centl_sci_workspace.default () with
  | Some workspace -> workspace
  | None ->
      prerr_endline
        "centl-mirage: no local workspace is available; set CENTL_WORKSPACE or \
         HOME";
      exit 2

let ingest_with workspace path =
  match Centl_sci_mirage.ingest workspace path with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let ingest path =
  let workspace = workspace_or_exit () in
  let result = ingest_with workspace path in
  print_endline (Centl_sci_mirage.render_ingest result)

let analyze_with workspace spec_path =
  match Centl_sci_mirage_goal.analyze workspace spec_path with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let analyze spec_path =
  let workspace = workspace_or_exit () in
  let path, graph = analyze_with workspace spec_path in
  Printf.printf "Goal graph: %s\n%s\n" path (Centl_sci_mirage_goal.render graph)

let obligations_with goal_path graph =
  match Centl_sci_mirage_obligation.construct goal_path graph with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let candidates_with obligations_path graph obligations =
  match
    Centl_sci_mirage_candidate.construct obligations_path graph obligations
  with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let materialization_with candidates_path candidates =
  match Centl_sci_mirage_materialize.construct candidates_path candidates with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let readiness_with candidates_path obligations candidates materialization =
  match
    Centl_sci_mirage_readiness.construct candidates_path obligations candidates
      materialization
  with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let execution_plan_with readiness_path readiness =
  match Centl_sci_mirage_execution_plan.construct readiness_path readiness with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let evidence_with workspace execution_plan_path execution_plan =
  match
    Centl_sci_mirage_evidence.construct workspace execution_plan_path
      execution_plan
  with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let admission_with evidence_path execution_plan evidence =
  match
    Centl_sci_mirage_admission.construct evidence_path execution_plan evidence
  with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let receipt_counts (evidence : Centl_sci_mirage_evidence.report) =
  List.fold_left
    (fun (passed, pending, blocked)
         (receipt : Centl_sci_mirage_evidence.receipt) ->
      match receipt.state with
      | Centl_sci_mirage_evidence.Passed -> (passed + 1, pending, blocked)
      | Centl_sci_mirage_evidence.Pending -> (passed, pending + 1, blocked)
      | Centl_sci_mirage_evidence.Blocked -> (passed, pending, blocked + 1))
    (0, 0, 0) evidence.receipts

let admission_counts (admission : Centl_sci_mirage_admission.report) =
  List.fold_left
    (fun (admissible, pending, blocked)
         (candidate : Centl_sci_mirage_admission.candidate_admission) ->
      match candidate.state with
      | Centl_sci_mirage_admission.Admissible ->
          (admissible + 1, pending, blocked)
      | Centl_sci_mirage_admission.Pending -> (admissible, pending + 1, blocked)
      | Centl_sci_mirage_admission.Blocked -> (admissible, pending, blocked + 1))
    (0, 0, 0) admission.candidates

let record_candidate_phase result goal_path graph obligations_path obligations
    candidates_path candidates materialization_path materialization
    readiness_path readiness execution_plan_path execution_plan evidence_path
    evidence admission_path admission =
  let evidence_passed, evidence_pending, evidence_blocked =
    receipt_counts evidence
  in
  let admission_admissible, admission_pending, admission_blocked =
    admission_counts admission
  in
  Centl_sci_workspace.atomic_write_json result.Centl_sci_mirage.active_path
    (`Assoc
       [
         ("schema_version", `Int 3);
         ("system", `String "CENTL-MIRAGE");
         ("status", `String "active");
         ("phase", `String "candidate_admission_assessed");
         ( "next_phase",
           `String
             (if obligations.Centl_sci_mirage_obligation.blocked_cells <> []
              then "resolve_blocking_requirements"
              else if evidence_blocked > 0 then "resolve_blocked_evidence"
              else if evidence_pending > 0 then
                "execute_remaining_candidate_evidence"
              else if admission_blocked > 0 then "resolve_candidate_admission"
              else if admission_pending > 0 then "reassess_candidate_admission"
              else "review_admissible_candidates") );
         ("source_digest", `String result.source_digest);
         ("source_stored_path", `String result.stored_path);
         ("specification_ir", `String result.spec_path);
         ("development_plan", `String result.plan_path);
         ("goal_graph", `String goal_path);
         ("evidence_obligations", `String obligations_path);
         ("candidate_transactions", `String candidates_path);
         ("candidate_materialization", `String materialization_path);
         ("candidate_evidence_readiness", `String readiness_path);
         ("candidate_evidence_execution_plan", `String execution_plan_path);
         ("candidate_evidence_receipts", `String evidence_path);
         ("candidate_admission_assessment", `String admission_path);
         ("workspace_revision", `Int result.revision);
         ("goal_nodes", `Int (List.length graph.Centl_sci_mirage_goal.nodes));
         ("goal_edges", `Int (List.length graph.edges));
         ("goal_gaps", `Int (List.length graph.gaps));
         ("conflicts", `Int (List.length graph.conflicts));
         ( "evidence_obligation_count",
           `Int
             (List.length obligations.Centl_sci_mirage_obligation.obligations)
         );
         ( "candidate_transaction_count",
           `Int (List.length candidates.Centl_sci_mirage_candidate.candidates)
         );
         ( "materialization_item_count",
           `Int (List.length materialization.Centl_sci_mirage_materialize.items)
         );
         ( "readiness_candidate_count",
           `Int (List.length readiness.Centl_sci_mirage_readiness.candidates) );
         ( "execution_plan_candidate_count",
           `Int
             (List.length
                execution_plan.Centl_sci_mirage_execution_plan.candidates) );
         ("evidence_receipt_count", `Int (List.length evidence.receipts));
         ("evidence_passed_count", `Int evidence_passed);
         ("evidence_pending_count", `Int evidence_pending);
         ("evidence_blocked_count", `Int evidence_blocked);
         ("admission_candidate_count", `Int (List.length admission.candidates));
         ("admission_admissible_count", `Int admission_admissible);
         ("admission_pending_count", `Int admission_pending);
         ("admission_blocked_count", `Int admission_blocked);
         ( "candidate_blocked",
           `Bool (obligations.Centl_sci_mirage_obligation.blocked_cells <> [])
         );
         ( "blocked_cells",
           `List
             (List.map
                (fun id -> `Int id)
                obligations.Centl_sci_mirage_obligation.blocked_cells) );
         ("candidate_source_activated", `Bool false);
         ("evidence_execution_performed", `Bool (evidence.receipts <> []));
         ( "workspace_mutated",
           `Bool
             (List.exists
                (fun (receipt : Centl_sci_mirage_evidence.receipt) ->
                  receipt.state = Centl_sci_mirage_evidence.Passed
                  && receipt.executor = "workspace_snapshot")
                evidence.receipts) );
         ("assurance_promoted", `Bool false);
         ("network_required", `Bool false);
       ])

let start path =
  let workspace = workspace_or_exit () in
  let result = ingest_with workspace path in
  let goal_path, graph = analyze_with workspace result.spec_path in
  let obligations_path, obligations = obligations_with goal_path graph in
  let candidates_path, candidates =
    candidates_with obligations_path graph obligations
  in
  let materialization_path, materialization =
    materialization_with candidates_path candidates
  in
  let readiness_path, readiness =
    readiness_with candidates_path obligations candidates materialization
  in
  let execution_plan_path, execution_plan =
    execution_plan_with readiness_path readiness
  in
  let evidence_path, evidence =
    evidence_with workspace execution_plan_path execution_plan
  in
  let admission_path, admission =
    admission_with evidence_path execution_plan evidence
  in
  record_candidate_phase result goal_path graph obligations_path obligations
    candidates_path candidates materialization_path materialization
    readiness_path readiness execution_plan_path execution_plan evidence_path
    evidence admission_path admission;
  print_endline (Centl_sci_mirage.render_ingest result);
  Printf.printf "Goal graph: %s\n%s\n" goal_path
    (Centl_sci_mirage_goal.render graph);
  Printf.printf "Evidence obligations: %s\n%s\n" obligations_path
    (Centl_sci_mirage_obligation.render obligations);
  Printf.printf "Candidate transactions: %s\n%s\n" candidates_path
    (Centl_sci_mirage_candidate.render candidates);
  Printf.printf "Candidate materialization: %s\n%s\n" materialization_path
    (Centl_sci_mirage_materialize.render materialization);
  Printf.printf "Candidate evidence readiness: %s\n%s\n" readiness_path
    (Centl_sci_mirage_readiness.render readiness);
  Printf.printf "Candidate evidence execution plan: %s\n%s\n"
    execution_plan_path
    (Centl_sci_mirage_execution_plan.render execution_plan);
  Printf.printf "Candidate evidence receipts: %s\n%s\n" evidence_path
    (Centl_sci_mirage_evidence.render evidence);
  Printf.printf "Candidate admission assessment: %s\n%s\n" admission_path
    (Centl_sci_mirage_admission.render admission);
  if obligations.blocked_cells <> [] then
    print_endline
      "MIRAGE staged only non-mutating candidate transactions and halted \
       candidate synthesis for blocked source cells. Evidence execution and \
       admission assessment do not override those source-level blocks."
  else
    print_endline
      "MIRAGE staged candidate transactions, conservatively materialized only \
       deterministic local lowering, consumed parser evidence, created \
       reversible pre-activation workspace snapshots where required, left \
       unexecuted validators explicitly pending, and assessed admission only \
       from exact transaction-bound evidence receipts. No candidate source was \
       activated and no assurance was promoted."

let status () =
  let workspace = workspace_or_exit () in
  print_endline (Centl_sci_mirage.status workspace)

let main () =
  match Array.to_list Sys.argv with
  | [ _; "status" ] -> status ()
  | _ :: "start" :: path_parts when path_parts <> [] ->
      start (String.concat " " path_parts)
  | _ :: "ingest" :: path_parts when path_parts <> [] ->
      ingest (String.concat " " path_parts)
  | _ :: "analyze" :: path_parts when path_parts <> [] ->
      analyze (String.concat " " path_parts)
  | [ _; "--version" ] -> print_endline "CENTL-MIRAGE development bootstrap"
  | _ ->
      prerr_endline (usage ());
      exit 2

let () = main ()
