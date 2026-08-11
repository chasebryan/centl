type event = { kind : string; detail : string }

type t = {
  input : string;
  normalized : string;
  mode : Centl_sci_interaction.mode;
  intent : Centl_sci_intent.classification;
  interpreter_path : string;
  domain : string;
  problem_class : string;
  operation : string;
  assumptions : string list;
  status : Centl_sci_runtime.status;
  executor : string option;
  execution_request : string option;
  result : string;
  events : event list;
  workspace_revision : int option;
}

let event kind detail = { kind; detail }

let executor_of_outcome outcome =
  match outcome.Centl_sci_runtime.plan with
  | None -> None
  | Some plan -> Some (Centl_sci_runtime.executor_text plan.executor)

let execution_request_of_outcome outcome =
  match outcome.Centl_sci_runtime.plan with
  | None -> None
  | Some plan -> Some (Yojson.Safe.to_string plan.request)

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
  let ir = outcome.Centl_sci_runtime.ir in
  let executor = executor_of_outcome outcome in
  let execution_request = execution_request_of_outcome outcome in
  let assumptions = Centl_sci_ir.assumptions ir in
  let events =
    [
      event "normalized" normalized;
      event "intent"
        (Centl_sci_intent.text intent.intent ^ ": " ^ intent.evidence);
      event "typed_ir"
        (Printf.sprintf "%s/%s/%s" (Centl_sci_ir.domain ir)
           (Centl_sci_ir.problem_class ir)
           (Centl_sci_ir.operation ir));
    ]
    @ (match assumptions with
      | [] -> [ event "assumptions" "none introduced by the interpreter" ]
      | values -> [ event "assumptions" (String.concat "; " values) ])
    @ (match executor with
      | None ->
          [ event "deferred" "no authoritative executor plan was available" ]
      | Some value -> [ event "routed" ("authoritative executor: " ^ value) ])
    @ [
        event "executed"
          (Centl_sci_runtime.status_text outcome.Centl_sci_runtime.status);
      ]
  in
  {
    input;
    normalized;
    mode;
    intent;
    interpreter_path;
    domain = Centl_sci_ir.domain ir;
    problem_class = Centl_sci_ir.problem_class ir;
    operation = Centl_sci_ir.operation ir;
    assumptions;
    status = outcome.Centl_sci_runtime.status;
    executor;
    execution_request;
    result = result_of_outcome outcome;
    events;
    workspace_revision;
  }

let render evidence =
  let executor =
    match evidence.executor with None -> "none" | Some value -> value
  in
  let execution_request =
    match evidence.execution_request with None -> "none" | Some value -> value
  in
  let revision =
    match evidence.workspace_revision with
    | None -> "unavailable"
    | Some value -> string_of_int value
  in
  let assumptions =
    match evidence.assumptions with
    | [] -> "none introduced"
    | values -> String.concat "; " values
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
       "  Typed problem:";
       "    domain=" ^ evidence.domain ^ ", class=" ^ evidence.problem_class
       ^ ", operation=" ^ evidence.operation;
       "  Interpreter assumptions:";
       "    " ^ assumptions;
       "  Interpretation path:";
       "    " ^ evidence.interpreter_path;
       "  Authoritative executor:";
       "    " ^ executor;
       "  Executor request:";
       "    " ^ execution_request;
       "  Status:";
       "    " ^ Centl_sci_runtime.status_text evidence.status;
       "  Workspace revision:";
       "    " ^ revision;
       "  Evidence events:";
     ]
    @ event_lines
    @ [ "  Result:"; "    " ^ evidence.result ])
