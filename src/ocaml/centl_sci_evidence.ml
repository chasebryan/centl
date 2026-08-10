type event = {
  kind : string;
  detail : string;
}

type t = {
  input : string;
  normalized : string;
  mode : Centl_sci_interaction.mode;
  intent : Centl_sci_intent.classification;
  interpreter_path : string;
  status : Centl_sci_runtime.status;
  executor : string option;
  result : string;
  events : event list;
  workspace_revision : int option;
}

let event kind detail = { kind; detail }

let executor_of_outcome outcome =
  match outcome.Centl_sci_runtime.plan with
  | None -> None
  | Some plan -> Some (Centl_sci_runtime.executor_text plan.executor)

let result_of_outcome outcome =
  match outcome.Centl_sci_runtime.response with
  | Some response ->
      begin match Centl_sci_runtime.result_text response with
      | Some text -> text
      | None -> Centl_sci_present.human outcome
      end
  | None -> Centl_sci_present.human outcome

let collect ~input ~normalized ~mode ~interpreter_path ~outcome
    ~workspace_revision =
  let intent = Centl_sci_intent.classify ~mode normalized in
  let executor = executor_of_outcome outcome in
  let events =
    [ event "normalized" normalized;
      event "intent" (Centl_sci_intent.text intent.intent ^ ": " ^ intent.evidence) ]
    @
    (match executor with
    | None -> [ event "deferred" "no authoritative executor plan was available" ]
    | Some value -> [ event "routed" ("authoritative executor: " ^ value) ])
    @ [ event "executed" (Centl_sci_runtime.status_text outcome.Centl_sci_runtime.status) ]
  in
  {
    input;
    normalized;
    mode;
    intent;
    interpreter_path;
    status = outcome.Centl_sci_runtime.status;
    executor;
    result = result_of_outcome outcome;
    events;
    workspace_revision;
  }

let render evidence =
  let executor = match evidence.executor with None -> "none" | Some value -> value in
  let revision =
    match evidence.workspace_revision with
    | None -> "unavailable"
    | Some value -> string_of_int value
  in
  let event_lines =
    evidence.events
    |> List.map (fun value -> "    - " ^ value.kind ^ ": " ^ value.detail)
  in
  String.concat "\n"
    ([
       "Explanation";
       "  Understood as:";
       "    " ^ evidence.normalized;
       "  Mode:";
       "    " ^ Centl_sci_interaction.mode_text evidence.mode;
       "  Intent:";
       "    " ^ Centl_sci_intent.text evidence.intent.intent;
       "  Interpretation path:";
       "    " ^ evidence.interpreter_path;
       "  Authoritative executor:";
       "    " ^ executor;
       "  Status:";
       "    " ^ Centl_sci_runtime.status_text evidence.status;
       "  Workspace revision:";
       "    " ^ revision;
       "  Evidence events:";
     ]
    @ event_lines
    @ [ "  Result:"; "    " ^ evidence.result ])
