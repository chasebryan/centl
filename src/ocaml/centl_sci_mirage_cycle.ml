type t = {
  ingest : Centl_sci_mirage.ingest_result;
  goal_path : string;
  graph : Centl_sci_mirage_goal.graph;
  obligations_path : string;
  obligations : Centl_sci_mirage_obligation.report;
  candidates_path : string;
  candidates : Centl_sci_mirage_candidate.report;
  materialization_path : string;
  materialization : Centl_sci_mirage_materialize.report;
  readiness_path : string;
  readiness : Centl_sci_mirage_readiness.report;
  execution_plan_path : string;
  execution_plan : Centl_sci_mirage_execution_plan.report;
  cegis_path : string;
  cegis : Centl_sci_mirage_cegis.report;
  fingerprint_path : string;
  fingerprint : Centl_sci_mirage_fingerprint.report;
  compare_path : string;
  compare : Centl_sci_mirage_compare.report;
  evidence_path : string;
  evidence : Centl_sci_mirage_evidence.report;
  admission_path : string;
  admission : Centl_sci_mirage_admission.report;
  review_path : string;
  review : Centl_sci_mirage_review.report;
  acceptance_path : string;
  acceptance : Centl_sci_mirage_accept.report;
  rewrite_path : string;
  rewrite : Centl_sci_mirage_rewrite.report;
  properties_path : string;
  properties : Centl_sci_mirage_metamorphic.report;
  lattice_path : string;
  lattice : Centl_sci_mirage_lattice.report;
  rank_path : string;
  rank : Centl_sci_mirage_rank.report;
  compose_path : string;
  compose : Centl_sci_mirage_compose.report;
  proposals_path : string;
  proposals : Centl_sci_mirage_propose.report;
  progress : Centl_sci_mirage_progress.t;
  policy : Centl_sci_mirage_policy.t;
  termination : string;
  next_phase : string;
}

let fail message = Error message

let receipt_counts (evidence : Centl_sci_mirage_evidence.report) =
  List.fold_left
    (fun (passed, pending, blocked)
         (receipt : Centl_sci_mirage_evidence.receipt) ->
      match receipt.state with
      | Centl_sci_mirage_evidence.Passed -> (passed + 1, pending, blocked)
      | Centl_sci_mirage_evidence.Pending -> (passed, pending + 1, blocked)
      | Centl_sci_mirage_evidence.Blocked -> (passed, pending, blocked + 1))
    (0, 0, 0) evidence.Centl_sci_mirage_evidence.receipts

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

let termination_of ~graph ~obligations
    ~(evidence : Centl_sci_mirage_evidence.report)
    ~(admission : Centl_sci_mirage_admission.report) ~open_questions =
  if obligations.Centl_sci_mirage_obligation.blocked_cells <> [] then
    "remaining goals require explicit human resolution"
  else if
    List.exists
      (fun (receipt : Centl_sci_mirage_evidence.receipt) ->
        receipt.state = Centl_sci_mirage_evidence.Blocked)
      evidence.Centl_sci_mirage_evidence.receipts
  then
    "no admissible improvement is available until blocked evidence is resolved"
  else if open_questions then
    "remaining goals require user information that cannot be inferred safely"
  else if
    graph.Centl_sci_mirage_goal.gaps
    |> List.for_all (fun gap ->
        gap.Centl_sci_mirage_goal.status = Centl_sci_mirage_goal.Satisfied)
    && graph.gaps <> []
  then "all active requirements are satisfied"
  else if
    List.exists
      (fun (candidate : Centl_sci_mirage_admission.candidate_admission) ->
        candidate.state = Centl_sci_mirage_admission.Admissible)
      admission.candidates
  then "admissible candidates are ready for explicit review"
  else "no admissible improvement is found within the configured local budget"

let next_phase_of ~obligations ~evidence_blocked ~evidence_pending
    ~admission_blocked ~admission_pending ~admission_admissible =
  if obligations.Centl_sci_mirage_obligation.blocked_cells <> [] then
    "resolve_blocking_requirements"
  else if evidence_blocked > 0 then "resolve_blocked_evidence"
  else if evidence_pending > 0 then "execute_remaining_candidate_evidence"
  else if admission_blocked > 0 then "resolve_candidate_admission"
  else if admission_pending > 0 then "reassess_candidate_admission"
  else if admission_admissible > 0 then "review_admissible_candidates"
  else "cycle_complete"

let record_active (cycle : t) =
  let evidence_passed, evidence_pending, evidence_blocked =
    receipt_counts cycle.evidence
  in
  let admission_admissible, admission_pending, admission_blocked =
    admission_counts cycle.admission
  in
  Centl_sci_workspace.atomic_write_json cycle.ingest.active_path
    (`Assoc
       [
         ("schema_version", `Int 4);
         ("system", `String "CENTL-MIRAGE");
         ("status", `String "active");
         ("phase", `String "candidate_review_prepared");
         ("next_phase", `String cycle.next_phase);
         ("termination", `String cycle.termination);
         ( "autonomy_policy",
           `String (Centl_sci_mirage_policy.level_text cycle.policy.level) );
         ("source_digest", `String cycle.ingest.source_digest);
         ("source_stored_path", `String cycle.ingest.stored_path);
         ("specification_ir", `String cycle.ingest.spec_path);
         ("development_plan", `String cycle.ingest.plan_path);
         ("goal_graph", `String cycle.goal_path);
         ("evidence_obligations", `String cycle.obligations_path);
         ("candidate_transactions", `String cycle.candidates_path);
         ("candidate_materialization", `String cycle.materialization_path);
         ("candidate_evidence_readiness", `String cycle.readiness_path);
         ("candidate_evidence_execution_plan", `String cycle.execution_plan_path);
         ("cegis_search", `String cycle.cegis_path);
         ("semantic_fingerprint", `String cycle.fingerprint_path);
         ("semantic_fingerprint_comparison", `String cycle.compare_path);
         ("candidate_evidence_receipts", `String cycle.evidence_path);
         ("candidate_admission_assessment", `String cycle.admission_path);
         ("candidate_review_manifest", `String cycle.review_path);
         ("candidate_acceptance", `String cycle.acceptance_path);
         ("equality_saturation", `String cycle.rewrite_path);
         ("metamorphic_properties", `String cycle.properties_path);
         ("evidence_lattice", `String cycle.lattice_path);
         ("pareto_ranking", `String cycle.rank_path);
         ("native_ast_composition", `String cycle.compose_path);
         ("deterministic_proposals", `String cycle.proposals_path);
         ("progress", Centl_sci_mirage_progress.to_json cycle.progress);
         ("core_preserved", `Bool cycle.compare.core_preserved);
         ("workspace_revision", `Int cycle.ingest.revision);
         ("goal_nodes", `Int (List.length cycle.graph.nodes));
         ("goal_edges", `Int (List.length cycle.graph.edges));
         ("goal_gaps", `Int (List.length cycle.graph.gaps));
         ("conflicts", `Int (List.length cycle.graph.conflicts));
         ( "evidence_obligation_count",
           `Int (List.length cycle.obligations.obligations) );
         ( "candidate_transaction_count",
           `Int (List.length cycle.candidates.candidates) );
         ( "materialization_item_count",
           `Int (List.length cycle.materialization.items) );
         ("cegis_example_count", `Int (List.length cycle.cegis.examples));
         ("cegis_trial_count", `Int (List.length cycle.cegis.trials));
         ("fingerprint", `String cycle.fingerprint.fingerprint);
         ("behavior_preserved", `Bool cycle.compare.behavior_preserved);
         ( "evidence_receipt_count",
           `Int (List.length cycle.evidence.Centl_sci_mirage_evidence.receipts)
         );
         ("evidence_passed_count", `Int evidence_passed);
         ("evidence_pending_count", `Int evidence_pending);
         ("evidence_blocked_count", `Int evidence_blocked);
         ( "admission_candidate_count",
           `Int (List.length cycle.admission.candidates) );
         ("admission_admissible_count", `Int admission_admissible);
         ("admission_pending_count", `Int admission_pending);
         ("admission_blocked_count", `Int admission_blocked);
         ("review_candidate_count", `Int (List.length cycle.review.candidates));
         ("candidate_source_activated", `Bool cycle.acceptance.workspace_mutated);
         ("assurance_promoted", `Bool false);
         ("network_required", `Bool false);
       ])

let run workspace path =
  let ( let* ) = Result.bind in
  let* ingest = Centl_sci_mirage.ingest workspace path in
  let* policy = Centl_sci_mirage_policy.load workspace in
  let* goal_path, graph =
    Centl_sci_mirage_goal.analyze workspace ingest.spec_path
  in
  let* obligations_path, obligations =
    Centl_sci_mirage_obligation.construct goal_path graph
  in
  let* candidates_path, candidates =
    Centl_sci_mirage_candidate.construct obligations_path graph obligations
  in
  let* compose_path, compose =
    Centl_sci_mirage_compose.construct candidates_path candidates
  in
  let* proposals_path, proposals =
    Centl_sci_mirage_propose.construct ingest.spec_path graph
  in
  let* materialization_path, materialization =
    Centl_sci_mirage_materialize.construct candidates_path candidates
  in
  let* readiness_path, readiness =
    Centl_sci_mirage_readiness.construct candidates_path obligations candidates
      materialization
  in
  let* execution_plan_path, execution_plan =
    Centl_sci_mirage_execution_plan.construct readiness_path readiness
  in
  let* cegis_path, cegis =
    Centl_sci_mirage_cegis.construct materialization_path graph candidates
      materialization
  in
  let* rewrite_path, rewrite =
    Centl_sci_mirage_rewrite.construct materialization_path materialization
  in
  let* properties_path, properties =
    Centl_sci_mirage_metamorphic.construct cegis_path cegis
  in
  let baseline = Centl_sci_mirage_fingerprint.observe_default () in
  let definitions =
    List.filter_map
      (fun item -> item.Centl_sci_mirage_materialize.source)
      materialization.items
  in
  let extras =
    List.map (fun example -> example.Centl_sci_mirage_cegis.left) cegis.examples
  in
  let fingerprint =
    Centl_sci_mirage_fingerprint.observe_with_definitions definitions
      (Centl_sci_mirage_fingerprint.default_corpus @ extras)
  in
  let* fingerprint_path, fingerprint =
    Centl_sci_mirage_fingerprint.construct ingest.spec_path fingerprint
  in
  let compare =
    Centl_sci_mirage_compare.compare_reports ~baseline ~candidate:fingerprint
  in
  let* compare_path, compare =
    Centl_sci_mirage_compare.construct fingerprint_path compare
  in
  let context =
    {
      Centl_sci_mirage_evidence.candidates = Some candidates;
      materialization = Some materialization;
      cegis = Some cegis;
      compare = Some compare;
    }
  in
  let* evidence_path, evidence =
    Centl_sci_mirage_evidence.construct ~context workspace execution_plan_path
      execution_plan
  in
  let* admission_path, admission =
    Centl_sci_mirage_admission.construct evidence_path execution_plan evidence
  in
  let* review_path, review =
    Centl_sci_mirage_review.construct admission_path admission
  in
  let acceptance =
    Centl_sci_mirage_accept.assess workspace policy candidates materialization
      evidence admission
  in
  let* acceptance_path, acceptance =
    Centl_sci_mirage_accept.construct review_path acceptance
  in
  let* lattice_path, lattice =
    Centl_sci_mirage_lattice.construct evidence_path evidence cegis compare
      properties.properties candidates
  in
  let* rank_path, rank =
    Centl_sci_mirage_rank.construct lattice_path lattice materialization
      candidates admission
  in
  let progress =
    Centl_sci_mirage_progress.of_cycle ~graph ~obligations ~admission
      ~metamorphic:properties ~lattice
  in
  let evidence_passed, evidence_pending, evidence_blocked =
    receipt_counts evidence
  in
  let admission_admissible, admission_pending, admission_blocked =
    admission_counts admission
  in
  let open_questions =
    List.exists
      (fun (node : Centl_sci_mirage_goal.node) ->
        node.kind = Centl_sci_mirage_goal.Open_question)
      graph.nodes
  in
  let cycle =
    {
      ingest;
      goal_path;
      graph;
      obligations_path;
      obligations;
      candidates_path;
      candidates;
      materialization_path;
      materialization;
      readiness_path;
      readiness;
      execution_plan_path;
      execution_plan;
      cegis_path;
      cegis;
      fingerprint_path;
      fingerprint;
      compare_path;
      compare;
      evidence_path;
      evidence;
      admission_path;
      admission;
      review_path;
      review;
      acceptance_path;
      acceptance;
      rewrite_path;
      rewrite;
      properties_path;
      properties;
      lattice_path;
      lattice;
      rank_path;
      rank;
      compose_path;
      compose;
      proposals_path;
      proposals;
      progress;
      policy;
      termination =
        termination_of ~graph ~obligations ~evidence ~admission ~open_questions;
      next_phase =
        next_phase_of ~obligations ~evidence_blocked ~evidence_pending
          ~admission_blocked ~admission_pending ~admission_admissible;
    }
  in
  let _ = evidence_passed in
  try
    record_active cycle;
    Ok cycle
  with Sys_error message | Unix.Unix_error (_, _, message) -> fail message

let assoc name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let string_field name json =
  match assoc name json with Some (`String value) -> Some value | _ -> None

let read_json path =
  try Ok (Yojson.Safe.from_file path) with
  | Sys_error message -> Error message
  | Yojson.Json_error message -> Error message

let active_string workspace field =
  let path = Centl_sci_mirage.active_path workspace in
  if not (Sys.file_exists path) then Error "CENTL-MIRAGE has no active cycle"
  else
    match read_json path with
    | Error _ as error -> error
    | Ok json -> (
        match string_field field json with
        | Some value -> Ok value
        | None -> Error ("active cycle is missing " ^ field))

let continue workspace =
  let ( let* ) = Result.bind in
  let* stored_path = active_string workspace "source_stored_path" in
  if not (Sys.file_exists stored_path) then
    Error ("active cycle source is missing: " ^ stored_path)
  else run workspace stored_path

let strategy_of_text = function
  | "compose_existing" -> Some Centl_sci_mirage_candidate.Compose_existing
  | "alias_or_wrapper" -> Some Centl_sci_mirage_candidate.Alias_or_wrapper
  | "downstream_extension" ->
      Some Centl_sci_mirage_candidate.Downstream_extension
  | "isolated_core_patch" -> Some Centl_sci_mirage_candidate.Isolated_core_patch
  | _ -> None

let load_candidate path candidate_id =
  match read_json path with
  | Error _ as error -> error
  | Ok json -> (
      match assoc "candidates" json with
      | Some (`List values) ->
          let rec loop = function
            | [] -> Error ("unknown MIRAGE candidate: " ^ candidate_id)
            | value :: rest ->
                if string_field "id" value = Some candidate_id then
                  match
                    ( string_field "strategy" value,
                      string_field "transaction_fingerprint" value )
                  with
                  | Some strategy_text, Some fingerprint -> (
                      match strategy_of_text strategy_text with
                      | None -> Error "candidate strategy is unreadable"
                      | Some strategy ->
                          Ok
                            {
                              Centl_sci_mirage_candidate.id = candidate_id;
                              cell_id = 0;
                              source_requirement = "";
                              strategy;
                              state = Planned;
                              capability_inputs = [];
                              obligation_ids = [];
                              assurance = "";
                              mutates_workspace = false;
                              transaction_fingerprint = fingerprint;
                            })
                  | _ -> Error "candidate record is missing required fields"
                else loop rest
          in
          loop values
      | _ -> Error "candidate transactions artifact is missing candidates")

let load_materialization path =
  match read_json path with
  | Error _ as error -> error
  | Ok json -> (
      match assoc "items" json with
      | Some (`List values) ->
          let items =
            List.filter_map
              (fun value ->
                match
                  ( string_field "candidate_id" value,
                    string_field "transaction_fingerprint" value,
                    string_field "strategy" value,
                    string_field "state" value,
                    string_field "rationale" value,
                    string_field "materialization_fingerprint" value )
                with
                | ( Some candidate_id,
                    Some transaction_fingerprint,
                    Some strategy,
                    Some state_text,
                    Some rationale,
                    Some materialization_fingerprint ) ->
                    let state =
                      match state_text with
                      | "materialized_source" ->
                          Centl_sci_mirage_materialize.Materialized_source
                      | "declarative_reuse" -> Declarative_reuse
                      | _ -> Blocked
                    in
                    Some
                      {
                        Centl_sci_mirage_materialize.candidate_id;
                        transaction_fingerprint;
                        strategy;
                        state;
                        source = string_field "source" value;
                        source_sha256 = string_field "source_sha256" value;
                        parser_validated =
                          (match assoc "parser_validated" value with
                          | Some (`Bool value) -> value
                          | _ -> false);
                        rationale;
                        materialization_fingerprint;
                      }
                | _ -> None)
              values
          in
          Ok { Centl_sci_mirage_materialize.items; blocked_cells = [] }
      | _ -> Error "materialization artifact is missing items")

let load_admission path candidate_id =
  match read_json path with
  | Error _ as error -> error
  | Ok json -> (
      match assoc "candidates" json with
      | Some (`List values) ->
          let rec loop = function
            | [] -> Error ("unknown MIRAGE candidate: " ^ candidate_id)
            | value :: rest ->
                if string_field "candidate_id" value = Some candidate_id then
                  let state =
                    match string_field "state" value with
                    | Some "admissible" -> Centl_sci_mirage_admission.Admissible
                    | Some "blocked" -> Blocked
                    | _ -> Pending
                  in
                  Ok
                    {
                      Centl_sci_mirage_admission.candidate_id;
                      transaction_fingerprint =
                        Option.value ~default:(String.make 64 '0')
                          (string_field "transaction_fingerprint" value);
                      state;
                      expected_action_count = 0;
                      passed_action_count = 0;
                      pending_action_count = 0;
                      blocked_action_count = 0;
                      exact_action_coverage = false;
                      receipt_fingerprints = [];
                      rationale =
                        Option.value ~default:""
                          (string_field "rationale" value);
                    }
                else loop rest
          in
          loop values
      | _ -> Error "admission artifact is missing candidates")

let empty_evidence =
  { Centl_sci_mirage_evidence.receipts = []; blocked_cells = [] }

let accept_from_active workspace candidate_id =
  let ( let* ) = Result.bind in
  let* policy = Centl_sci_mirage_policy.load workspace in
  let* candidates_path = active_string workspace "candidate_transactions" in
  let* materialization_path =
    active_string workspace "candidate_materialization"
  in
  let* admission_path =
    active_string workspace "candidate_admission_assessment"
  in
  let* candidate = load_candidate candidates_path candidate_id in
  let* materialization = load_materialization materialization_path in
  let* admission = load_admission admission_path candidate_id in
  let candidates =
    {
      Centl_sci_mirage_candidate.candidates = [ candidate ];
      blocked_cells = [];
    }
  in
  Ok
    (Centl_sci_mirage_accept.decide_one workspace policy candidates
       materialization empty_evidence admission)

let render cycle =
  String.concat "\n"
    [
      Centl_sci_mirage.render_ingest cycle.ingest;
      "";
      "Goal graph: " ^ cycle.goal_path;
      Centl_sci_mirage_goal.render cycle.graph;
      "";
      "Evidence obligations: " ^ cycle.obligations_path;
      Centl_sci_mirage_obligation.render cycle.obligations;
      "";
      "Candidate transactions: " ^ cycle.candidates_path;
      Centl_sci_mirage_candidate.render cycle.candidates;
      "";
      "Candidate materialization: " ^ cycle.materialization_path;
      Centl_sci_mirage_materialize.render cycle.materialization;
      "";
      "Candidate evidence readiness: " ^ cycle.readiness_path;
      Centl_sci_mirage_readiness.render cycle.readiness;
      "";
      "Candidate evidence execution plan: " ^ cycle.execution_plan_path;
      Centl_sci_mirage_execution_plan.render cycle.execution_plan;
      "";
      "CEGIS search: " ^ cycle.cegis_path;
      Centl_sci_mirage_cegis.render cycle.cegis;
      "";
      "Semantic fingerprint: " ^ cycle.fingerprint_path;
      Centl_sci_mirage_fingerprint.render cycle.fingerprint;
      "";
      "Semantic fingerprint comparison: " ^ cycle.compare_path;
      Centl_sci_mirage_compare.render cycle.compare;
      "";
      "Candidate evidence receipts: " ^ cycle.evidence_path;
      Centl_sci_mirage_evidence.render cycle.evidence;
      "";
      "Candidate admission assessment: " ^ cycle.admission_path;
      Centl_sci_mirage_admission.render cycle.admission;
      "";
      "Candidate review manifest: " ^ cycle.review_path;
      Centl_sci_mirage_review.render cycle.review;
      "";
      "Candidate acceptance: " ^ cycle.acceptance_path;
      Centl_sci_mirage_accept.render cycle.acceptance;
      "";
      "Equality saturation: " ^ cycle.rewrite_path;
      Centl_sci_mirage_rewrite.render cycle.rewrite;
      "";
      "Metamorphic properties: " ^ cycle.properties_path;
      Centl_sci_mirage_metamorphic.render cycle.properties;
      "";
      "Evidence lattice: " ^ cycle.lattice_path;
      Centl_sci_mirage_lattice.render cycle.lattice;
      "";
      "Pareto ranking: " ^ cycle.rank_path;
      Centl_sci_mirage_rank.render cycle.rank;
      "";
      Centl_sci_mirage_progress.render cycle.progress;
      "";
      "Native AST composition: " ^ cycle.compose_path;
      Centl_sci_mirage_compose.render cycle.compose;
      "";
      "Deterministic proposals: " ^ cycle.proposals_path;
      Centl_sci_mirage_propose.render cycle.proposals;
      "";
      "Autonomy policy: "
      ^ Centl_sci_mirage_policy.level_text cycle.policy.level;
      "Termination: " ^ cycle.termination;
      "Next phase: " ^ cycle.next_phase;
      "Network/paid AI required: no.";
    ]
