type state = Admissible | Pending | Blocked

type candidate_admission = {
  candidate_id : string;
  transaction_fingerprint : string;
  state : state;
  expected_action_count : int;
  passed_action_count : int;
  pending_action_count : int;
  blocked_action_count : int;
  exact_action_coverage : bool;
  receipt_fingerprints : string list;
  rationale : string;
}

type report = {
  candidates : candidate_admission list;
  blocked_cells : int list;
}

let state_text = function
  | Admissible -> "admissible"
  | Pending -> "pending"
  | Blocked -> "blocked"

let receipts_for_candidate (evidence : Centl_sci_mirage_evidence.report) candidate_id =
  List.filter
    (fun (receipt : Centl_sci_mirage_evidence.receipt) ->
      String.equal receipt.candidate_id candidate_id)
    evidence.receipts

let sorted_unique values = List.sort_uniq String.compare values

let exact_action_coverage
    (candidate : Centl_sci_mirage_execution_plan.candidate_plan)
    receipts =
  let expected =
    candidate.actions
    |> List.map (fun (action : Centl_sci_mirage_execution_plan.action) -> action.action_id)
    |> sorted_unique
  in
  let observed =
    receipts
    |> List.map (fun (receipt : Centl_sci_mirage_evidence.receipt) -> receipt.action_id)
    |> sorted_unique
  in
  expected = observed && List.length expected = List.length candidate.actions
  && List.length observed = List.length receipts

let receipt_counts receipts =
  List.fold_left
    (fun (passed, pending, blocked) (receipt : Centl_sci_mirage_evidence.receipt) ->
      match receipt.state with
      | Centl_sci_mirage_evidence.Passed -> (passed + 1, pending, blocked)
      | Centl_sci_mirage_evidence.Pending -> (passed, pending + 1, blocked)
      | Centl_sci_mirage_evidence.Blocked -> (passed, pending, blocked + 1))
    (0, 0, 0) receipts

let assess_candidate blocked_cells evidence
    (candidate : Centl_sci_mirage_execution_plan.candidate_plan) =
  let receipts = receipts_for_candidate evidence candidate.candidate_id in
  let passed, pending, blocked = receipt_counts receipts in
  let exact_coverage = exact_action_coverage candidate receipts in
  let expected = List.length candidate.actions in
  let state, rationale =
    if blocked_cells <> [] then
      ( Blocked,
        "source-level MIRAGE blockers remain unresolved; candidate admission is prohibited" )
    else if expected = 0 then
      ( Pending,
        "the candidate has no executable evidence actions in this cycle; MIRAGE does not infer admission from structural readiness alone" )
    else if not exact_coverage then
      ( Blocked,
        "evidence receipts do not exactly cover the transaction-bound planned action identities" )
    else if blocked > 0 then
      (Blocked, "one or more mandatory evidence actions are explicitly blocked")
    else if pending > 0 then
      (Pending, "one or more mandatory evidence actions remain pending execution")
    else if passed = expected then
      ( Admissible,
        "every transaction-bound planned evidence action has a passed receipt for this cycle; this permits only downstream admission consideration, not activation or assurance promotion" )
    else
      (Pending, "mandatory evidence accounting is incomplete")
  in
  {
    candidate_id = candidate.candidate_id;
    transaction_fingerprint = candidate.transaction_fingerprint;
    state;
    expected_action_count = expected;
    passed_action_count = passed;
    pending_action_count = pending;
    blocked_action_count = blocked;
    exact_action_coverage = exact_coverage;
    receipt_fingerprints =
      List.map
        (fun (receipt : Centl_sci_mirage_evidence.receipt) -> receipt.receipt_fingerprint)
        receipts;
    rationale;
  }

let assess (plan : Centl_sci_mirage_execution_plan.report)
    (evidence : Centl_sci_mirage_evidence.report) =
  {
    candidates = List.map (assess_candidate plan.blocked_cells evidence) plan.candidates;
    blocked_cells = plan.blocked_cells;
  }

let candidate_to_json (candidate : candidate_admission) =
  `Assoc
    [
      ("candidate_id", `String candidate.candidate_id);
      ("transaction_fingerprint", `String candidate.transaction_fingerprint);
      ("state", `String (state_text candidate.state));
      ("expected_action_count", `Int candidate.expected_action_count);
      ("passed_action_count", `Int candidate.passed_action_count);
      ("pending_action_count", `Int candidate.pending_action_count);
      ("blocked_action_count", `Int candidate.blocked_action_count);
      ("exact_action_coverage", `Bool candidate.exact_action_coverage);
      ( "receipt_fingerprints",
        `List (List.map (fun value -> `String value) candidate.receipt_fingerprints) );
      ("candidate_source_activated", `Bool false);
      ("assurance_promoted", `Bool false);
      ("rationale", `String candidate.rationale);
    ]

let to_json (report : report) =
  let admissible_count =
    List.fold_left
      (fun total candidate -> if candidate.state = Admissible then total + 1 else total)
      0 report.candidates
  in
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "candidate_admission_assessment");
      ("candidate_count", `Int (List.length report.candidates));
      ("admissible_candidate_count", `Int admissible_count);
      ("blocked_cells", `List (List.map (fun id -> `Int id) report.blocked_cells));
      ("candidate_source_activated", `Bool false);
      ("assurance_promoted", `Bool false);
      ( "admission_semantics",
        `String
          "admissible means only that every transaction-bound action planned for the candidate in this evidence cycle has exact receipt coverage and a passed state with no source-level blockers; it does not activate source, promote assurance, prove verified-core correctness, or replace an explicit activation policy" );
      ("candidates", `List (List.map candidate_to_json report.candidates));
    ]

let output_path evidence_path =
  if String.ends_with ~suffix:".evidence.json" evidence_path then
    String.sub evidence_path 0
      (String.length evidence_path - String.length ".evidence.json")
    ^ ".admission.json"
  else evidence_path ^ ".admission.json"

let construct evidence_path plan evidence =
  let report = assess plan evidence in
  let path = output_path evidence_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render (report : report) =
  let admissible, pending, blocked =
    List.fold_left
      (fun (admissible, pending, blocked) candidate ->
        match candidate.state with
        | Admissible -> (admissible + 1, pending, blocked)
        | Pending -> (admissible, pending + 1, blocked)
        | Blocked -> (admissible, pending, blocked + 1))
      (0, 0, 0) report.candidates
  in
  String.concat "\n"
    [
      "CENTL-MIRAGE candidate admission assessment";
      "admissible candidates: " ^ string_of_int admissible;
      "pending candidates: " ^ string_of_int pending;
      "blocked candidates: " ^ string_of_int blocked;
      "exact action/receipt coverage required: yes";
      "candidate source activated: no";
      "assurance promoted: no";
    ]
