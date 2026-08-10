type action = {
  action_id : string;
  candidate_id : string;
  obligation_id : string;
  kind : string;
  executor : string;
  precondition : string;
  state : string;
}

type candidate_plan = {
  candidate_id : string;
  transaction_fingerprint : string;
  actions : action list;
}

type report = {
  candidates : candidate_plan list;
  blocked_cells : int list;
}

let execution_contract kind =
  match kind with
  | "candidate_parses" -> ("candidate_parser_or_build", "candidate_materialized")
  | "mandatory_regression" ->
      ("deterministic_regression_gate", "candidate_materialized")
  | "rollback_available" -> ("workspace_snapshot", "before_activation")
  | "reuse_attempted" -> ("capability_discovery", "candidate_staged")
  | "core_validation" -> ("relevant_core_validation", "candidate_materialized")
  | "clarification_required" | "conflict_resolution_required" | "policy_boundary" ->
      ("human_resolution", "blocking_requirement_resolved")
  | _ -> ("unsupported_evidence_executor", "explicit_executor_required")

let action_identity_material ~candidate_id ~transaction_fingerprint ~obligation_id
    ~kind =
  let executor, precondition = execution_contract kind in
  `Assoc
    [
      ("identity_schema_version", `Int 2);
      ("candidate_id", `String candidate_id);
      ("transaction_fingerprint", `String transaction_fingerprint);
      ("obligation_id", `String obligation_id);
      ("kind", `String kind);
      ("executor", `String executor);
      ("precondition", `String precondition);
    ]
  |> Yojson.Safe.to_string

let action_id ~candidate_id ~transaction_fingerprint ~obligation_id ~kind =
  action_identity_material ~candidate_id ~transaction_fingerprint ~obligation_id ~kind
  |> Centl_sha256.hex_string

let action_of_check candidate_id transaction_fingerprint
    (check : Centl_sci_mirage_readiness.check) =
  if check.state = Centl_sci_mirage_readiness.Execution_required then
    let executor, precondition = execution_contract check.kind in
    Some
      {
        action_id =
          action_id ~candidate_id ~transaction_fingerprint
            ~obligation_id:check.obligation_id ~kind:check.kind;
        candidate_id;
        obligation_id = check.obligation_id;
        kind = check.kind;
        executor;
        precondition;
        state = "planned";
      }
  else None

let plan_candidate (candidate : Centl_sci_mirage_readiness.candidate_readiness) =
  {
    candidate_id = candidate.candidate_id;
    transaction_fingerprint = candidate.transaction_fingerprint;
    actions =
      List.filter_map
        (action_of_check candidate.candidate_id candidate.transaction_fingerprint)
        candidate.checks;
  }

let build (readiness : Centl_sci_mirage_readiness.report) =
  {
    candidates = List.map plan_candidate readiness.candidates;
    blocked_cells = readiness.blocked_cells;
  }

let action_to_json (action : action) =
  `Assoc
    [
      ("action_id_algorithm", `String "sha256");
      ("action_id", `String action.action_id);
      ("candidate_id", `String action.candidate_id);
      ("obligation_id", `String action.obligation_id);
      ("kind", `String action.kind);
      ("executor", `String action.executor);
      ("precondition", `String action.precondition);
      ("state", `String action.state);
    ]

let candidate_to_json (candidate : candidate_plan) =
  `Assoc
    [
      ("candidate_id", `String candidate.candidate_id);
      ("transaction_fingerprint", `String candidate.transaction_fingerprint);
      ("actions", `List (List.map action_to_json candidate.actions));
    ]

let to_json (report : report) =
  `Assoc
    [
      ("schema_version", `Int 3);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "candidate_evidence_execution_plan");
      ("blocked_cells", `List (List.map (fun id -> `Int id) report.blocked_cells));
      ("execution_performed", `Bool false);
      ("workspace_mutated", `Bool false);
      ("assurance_promoted", `Bool false);
      ( "action_identity_semantics",
        `String
          "action IDs bind candidate transaction identity, unresolved evidence obligation, executor, and precondition; identity is not evidence that the action executed or passed" );
      ( "execution_contract_semantics",
        `String
          "executor names identify the required local validation mechanism; preconditions must hold before execution and no executor is represented as having run in this artifact" );
      ("candidates", `List (List.map candidate_to_json report.candidates));
    ]

let output_path readiness_path =
  if String.ends_with ~suffix:".readiness.json" readiness_path then
    String.sub readiness_path 0
      (String.length readiness_path - String.length ".readiness.json")
    ^ ".execution-plan.json"
  else readiness_path ^ ".execution-plan.json"

let construct readiness_path readiness =
  let report = build readiness in
  let path = output_path readiness_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render (report : report) =
  let actions =
    report.candidates
    |> List.fold_left (fun total candidate -> total + List.length candidate.actions) 0
  in
  String.concat "\n"
    [
      "CENTL-MIRAGE evidence execution plan";
      "planned actions: " ^ string_of_int actions;
      "action identities: deterministic, transaction-bound, and executor-bound";
      "execution performed: no";
      "workspace mutated: no";
      "assurance promoted: no";
    ]
