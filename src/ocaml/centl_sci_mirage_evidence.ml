type receipt_state = Passed | Pending | Blocked

type receipt = {
  action_id : string;
  candidate_id : string;
  obligation_id : string;
  kind : string;
  executor : string;
  state : receipt_state;
  evidence : string;
  snapshot_path : string option;
}

type report = {
  receipts : receipt list;
  blocked_cells : int list;
}

type snapshot_evidence =
  | Snapshot_not_required
  | Snapshot_ready of string
  | Snapshot_failed of string

let receipt_state_text = function
  | Passed -> "passed"
  | Pending -> "pending"
  | Blocked -> "blocked"

let receipt_counts (report : report) =
  List.fold_left
    (fun (passed, pending, blocked) (receipt : receipt) ->
      match receipt.state with
      | Passed -> (passed + 1, pending, blocked)
      | Pending -> (passed, pending + 1, blocked)
      | Blocked -> (passed, pending, blocked + 1))
    (0, 0, 0) report.receipts

let evidence_complete (report : report) =
  let _, pending, blocked = receipt_counts report in
  report.receipts <> [] && pending = 0 && blocked = 0 && report.blocked_cells = []

let action_requires_snapshot (action : Centl_sci_mirage_execution_plan.action) =
  action.executor = "workspace_snapshot" && action.precondition = "before_activation"

let prepare_snapshot workspace (plan : Centl_sci_mirage_execution_plan.report) =
  let required =
    List.exists
      (fun (candidate : Centl_sci_mirage_execution_plan.candidate_plan) ->
        List.exists action_requires_snapshot candidate.actions)
      plan.candidates
  in
  if not required then Snapshot_not_required
  else
    match Centl_sci_snapshot.create workspace with
    | Ok path -> Snapshot_ready path
    | Error message -> Snapshot_failed message

let execute_action snapshot (action : Centl_sci_mirage_execution_plan.action) =
  match action.executor with
  | "workspace_snapshot" when action.precondition = "before_activation" ->
      begin
        match snapshot with
        | Snapshot_ready path ->
            {
              action_id = action.action_id;
              candidate_id = action.candidate_id;
              obligation_id = action.obligation_id;
              kind = action.kind;
              executor = action.executor;
              state = Passed;
              evidence =
                "a reversible local workspace snapshot was created once for this evidence cycle before candidate activation and is shared by all rollback obligations in the cycle";
              snapshot_path = Some path;
            }
        | Snapshot_failed message ->
            {
              action_id = action.action_id;
              candidate_id = action.candidate_id;
              obligation_id = action.obligation_id;
              kind = action.kind;
              executor = action.executor;
              state = Blocked;
              evidence = "workspace snapshot failed: " ^ message;
              snapshot_path = None;
            }
        | Snapshot_not_required ->
            {
              action_id = action.action_id;
              candidate_id = action.candidate_id;
              obligation_id = action.obligation_id;
              kind = action.kind;
              executor = action.executor;
              state = Blocked;
              evidence = "workspace snapshot action was not included in the prepared evidence cycle";
              snapshot_path = None;
            }
      end
  | _ when not action.executor_supported ->
      {
        action_id = action.action_id;
        candidate_id = action.candidate_id;
        obligation_id = action.obligation_id;
        kind = action.kind;
        executor = action.executor;
        state = Blocked;
        evidence =
          (match action.blocking_reason with
          | Some reason -> reason
          | None -> "the planned evidence executor is unavailable");
        snapshot_path = None;
      }
  | _ ->
      {
        action_id = action.action_id;
        candidate_id = action.candidate_id;
        obligation_id = action.obligation_id;
        kind = action.kind;
        executor = action.executor;
        state = Pending;
        evidence =
          "the executor contract is known, but this MIRAGE phase does not yet execute that validation mechanism";
        snapshot_path = None;
      }

let execute_candidate snapshot
    (candidate : Centl_sci_mirage_execution_plan.candidate_plan) =
  List.map (execute_action snapshot) candidate.actions

let execute workspace (plan : Centl_sci_mirage_execution_plan.report) =
  let snapshot = prepare_snapshot workspace plan in
  {
    receipts = List.concat_map (execute_candidate snapshot) plan.candidates;
    blocked_cells = plan.blocked_cells;
  }

let receipt_to_json (receipt : receipt) =
  `Assoc
    [
      ("action_id", `String receipt.action_id);
      ("candidate_id", `String receipt.candidate_id);
      ("obligation_id", `String receipt.obligation_id);
      ("kind", `String receipt.kind);
      ("executor", `String receipt.executor);
      ("state", `String (receipt_state_text receipt.state));
      ("evidence", `String receipt.evidence);
      ( "snapshot_path",
        match receipt.snapshot_path with None -> `Null | Some path -> `String path );
    ]

let to_json (report : report) =
  let passed, pending, blocked = receipt_counts report in
  `Assoc
    [
      ("schema_version", `Int 3);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "candidate_evidence_execution_receipts");
      ("blocked_cells", `List (List.map (fun id -> `Int id) report.blocked_cells));
      ("passed_action_count", `Int passed);
      ("pending_action_count", `Int pending);
      ("blocked_action_count", `Int blocked);
      ("evidence_complete", `Bool (evidence_complete report));
      ("candidate_source_activated", `Bool false);
      ("assurance_promoted", `Bool false);
      ( "execution_semantics",
        `String
          "a passed receipt records only the named evidence action; evidence_complete means every action emitted in this execution cycle passed and no source cells are blocked, but it does not imply candidate admissibility, mathematical correctness beyond those named obligations, activation, or verified-core status; rollback obligations in one evidence cycle share at most one newly created workspace snapshot" );
      ("receipts", `List (List.map receipt_to_json report.receipts));
    ]

let output_path execution_plan_path =
  if String.ends_with ~suffix:".execution-plan.json" execution_plan_path then
    String.sub execution_plan_path 0
      (String.length execution_plan_path - String.length ".execution-plan.json")
    ^ ".evidence.json"
  else execution_plan_path ^ ".evidence.json"

let construct workspace execution_plan_path plan =
  let report = execute workspace plan in
  let path = output_path execution_plan_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render (report : report) =
  let passed, pending, blocked = receipt_counts report in
  String.concat "\n"
    [
      "CENTL-MIRAGE evidence execution receipts";
      "passed actions: " ^ string_of_int passed;
      "pending actions: " ^ string_of_int pending;
      "blocked actions: " ^ string_of_int blocked;
      "evidence cycle complete: " ^ (if evidence_complete report then "yes" else "no");
      "workspace snapshots created per evidence cycle: at most one";
      "candidate source activated: no";
      "assurance promoted: no";
    ]
