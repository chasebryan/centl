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

let receipt_state_text = function
  | Passed -> "passed"
  | Pending -> "pending"
  | Blocked -> "blocked"

let execute_action workspace (action : Centl_sci_mirage_execution_plan.action) =
  match action.executor with
  | "workspace_snapshot" when action.precondition = "before_activation" ->
      begin
        match Centl_sci_snapshot.create workspace with
        | Ok path ->
            {
              action_id = action.action_id;
              candidate_id = action.candidate_id;
              obligation_id = action.obligation_id;
              kind = action.kind;
              executor = action.executor;
              state = Passed;
              evidence =
                "a reversible local workspace snapshot was created before candidate activation";
              snapshot_path = Some path;
            }
        | Error message ->
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

let execute_candidate workspace
    (candidate : Centl_sci_mirage_execution_plan.candidate_plan) =
  List.map (execute_action workspace) candidate.actions

let execute workspace (plan : Centl_sci_mirage_execution_plan.report) =
  {
    receipts = List.concat_map (execute_candidate workspace) plan.candidates;
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
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "candidate_evidence_execution_receipts");
      ("blocked_cells", `List (List.map (fun id -> `Int id) report.blocked_cells));
      ("candidate_source_activated", `Bool false);
      ("assurance_promoted", `Bool false);
      ( "execution_semantics",
        `String
          "a passed receipt records only the named evidence action; it does not imply candidate admissibility, mathematical correctness, regression success, activation, or verified-core status" );
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
  let passed, pending, blocked =
    List.fold_left
      (fun (passed, pending, blocked) (receipt : receipt) ->
        match receipt.state with
        | Passed -> (passed + 1, pending, blocked)
        | Pending -> (passed, pending + 1, blocked)
        | Blocked -> (passed, pending, blocked + 1))
      (0, 0, 0) report.receipts
  in
  String.concat "\n"
    [
      "CENTL-MIRAGE evidence execution receipts";
      "passed actions: " ^ string_of_int passed;
      "pending actions: " ^ string_of_int pending;
      "blocked actions: " ^ string_of_int blocked;
      "candidate source activated: no";
      "assurance promoted: no";
    ]
