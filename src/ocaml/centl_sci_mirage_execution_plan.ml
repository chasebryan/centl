type action = {
  action_id : string;
  candidate_id : string;
  obligation_id : string;
  kind : string;
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

let action_identity_material ~candidate_id ~transaction_fingerprint ~obligation_id
    ~kind =
  `Assoc
    [
      ("identity_schema_version", `Int 1);
      ("candidate_id", `String candidate_id);
      ("transaction_fingerprint", `String transaction_fingerprint);
      ("obligation_id", `String obligation_id);
      ("kind", `String kind);
    ]
  |> Yojson.Safe.to_string

let action_id ~candidate_id ~transaction_fingerprint ~obligation_id ~kind =
  action_identity_material ~candidate_id ~transaction_fingerprint ~obligation_id ~kind
  |> Centl_sha256.hex_string

let action_of_check candidate_id transaction_fingerprint
    (check : Centl_sci_mirage_readiness.check) =
  if check.state = Centl_sci_mirage_readiness.Execution_required then
    Some
      {
        action_id =
          action_id ~candidate_id ~transaction_fingerprint
            ~obligation_id:check.obligation_id ~kind:check.kind;
        candidate_id;
        obligation_id = check.obligation_id;
        kind = check.kind;
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
      ("schema_version", `Int 2);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "candidate_evidence_execution_plan");
      ("blocked_cells", `List (List.map (fun id -> `Int id) report.blocked_cells));
      ("execution_performed", `Bool false);
      ("workspace_mutated", `Bool false);
      ("assurance_promoted", `Bool false);
      ( "action_identity_semantics",
        `String
          "action IDs bind candidate transaction identity to one unresolved evidence obligation; identity is not evidence that the action executed or passed" );
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
      "action identities: deterministic and transaction-bound";
      "execution performed: no";
      "workspace mutated: no";
      "assurance promoted: no";
    ]
