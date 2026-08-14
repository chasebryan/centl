type decision = Accepted | Rejected | Held

type candidate_decision = {
  candidate_id : string;
  decision : decision;
  rationale : string;
  activated : bool;
  activation_path : string option;
  rollback_snapshot : string option;
}

type report = {
  policy : string;
  decisions : candidate_decision list;
  workspace_mutated : bool;
  assurance_promoted : bool;
}

let decision_text = function
  | Accepted -> "accepted"
  | Rejected -> "rejected"
  | Held -> "held"

let write_text path content =
  Centl_sci_workspace.with_atomic_output path (fun channel ->
      output_string channel content;
      output_char channel '\n')

let extension_name source =
  match Centl_parser.parse_statement_located source with
  | Ok located -> (
      match located.statement with
      | Centl_parser.Define_function (name, _, _)
      | Centl_parser.Define_value (name, _) ->
          Some name
      | _ -> None)
  | Error _ -> None

let materialization_for report candidate_id =
  List.find_opt
    (fun item ->
      String.equal item.Centl_sci_mirage_materialize.candidate_id candidate_id)
    report.Centl_sci_mirage_materialize.items

let candidate_for report candidate_id =
  List.find_opt
    (fun candidate ->
      String.equal candidate.Centl_sci_mirage_candidate.id candidate_id)
    report.Centl_sci_mirage_candidate.candidates

let snapshot_for evidence candidate_id =
  evidence.Centl_sci_mirage_evidence.receipts
  |> List.find_opt (fun (receipt : Centl_sci_mirage_evidence.receipt) ->
      String.equal receipt.candidate_id candidate_id
      && receipt.executor = "workspace_snapshot"
      && receipt.state = Centl_sci_mirage_evidence.Passed)
  |> Option.map (fun receipt -> receipt.Centl_sci_mirage_evidence.snapshot_path)
  |> Option.join

let activate workspace ~name ~source ~candidate_id ~transaction_fingerprint =
  let relative = "modules/" ^ name ^ ".centl" in
  let path =
    Filename.concat workspace.Centl_sci_workspace.modules_dir (name ^ ".centl")
  in
  if Sys.file_exists path then
    Error ("refusing to overwrite existing local module: " ^ path)
  else
    try
      Centl_sci_workspace.ensure workspace;
      write_text path source;
      match
        Centl_sci_workspace.write_manifest_detailed workspace ~name
          ~enabled:true ~assurance:Centl_sci_workspace.Unverified_generated
          ~source:relative
          ~summary:("MIRAGE-admitted downstream candidate " ^ candidate_id)
          ~kind:"native_centl"
          ~provenance:
            ("CENTL-MIRAGE candidate " ^ candidate_id ^ " fingerprint "
           ^ transaction_fingerprint)
          ~dependencies:[] ~tests:[]
      with
      | Error message -> Error message
      | Ok _ -> Ok path
    with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let decide_one workspace policy candidates materialization evidence
    (admission : Centl_sci_mirage_admission.candidate_admission) =
  let candidate = candidate_for candidates admission.candidate_id in
  let snapshot = snapshot_for evidence admission.candidate_id in
  match (admission.state, candidate) with
  | Centl_sci_mirage_admission.Blocked, _ ->
      {
        candidate_id = admission.candidate_id;
        decision = Rejected;
        rationale = "admission is blocked; acceptance is prohibited";
        activated = false;
        activation_path = None;
        rollback_snapshot = snapshot;
      }
  | Centl_sci_mirage_admission.Pending, _ ->
      {
        candidate_id = admission.candidate_id;
        decision = Held;
        rationale = "admission is still pending mandatory evidence";
        activated = false;
        activation_path = None;
        rollback_snapshot = snapshot;
      }
  | Centl_sci_mirage_admission.Admissible, None ->
      {
        candidate_id = admission.candidate_id;
        decision = Held;
        rationale =
          "admissible assessment has no matching candidate transaction";
        activated = false;
        activation_path = None;
        rollback_snapshot = snapshot;
      }
  | Centl_sci_mirage_admission.Admissible, Some candidate ->
      if
        not
          (Centl_sci_mirage_policy.permits_activation policy candidate.strategy)
      then
        {
          candidate_id = admission.candidate_id;
          decision = Held;
          rationale =
            "the active autonomy policy does not permit activation of this \
             candidate; explicit later acceptance remains required";
          activated = false;
          activation_path = None;
          rollback_snapshot = snapshot;
        }
      else
        begin match candidate.strategy with
        | Centl_sci_mirage_candidate.Compose_existing ->
            {
              candidate_id = admission.candidate_id;
              decision = Accepted;
              rationale =
                "admissible composition reuses existing capabilities; no new \
                 source is activated";
              activated = false;
              activation_path = None;
              rollback_snapshot = snapshot;
            }
        | Centl_sci_mirage_candidate.Isolated_core_patch ->
            {
              candidate_id = admission.candidate_id;
              decision = Held;
              rationale =
                "isolated core patches cannot be activated by MIRAGE without \
                 the full relevant core gates";
              activated = false;
              activation_path = None;
              rollback_snapshot = snapshot;
            }
        | Centl_sci_mirage_candidate.Alias_or_wrapper
        | Centl_sci_mirage_candidate.Downstream_extension -> (
            match materialization_for materialization candidate.id with
            | Some item
              when item.state = Centl_sci_mirage_materialize.Materialized_source
              -> (
                match item.source with
                | None ->
                    {
                      candidate_id = admission.candidate_id;
                      decision = Held;
                      rationale =
                        "materialization recorded no source to activate";
                      activated = false;
                      activation_path = None;
                      rollback_snapshot = snapshot;
                    }
                | Some source -> (
                    match extension_name source with
                    | None ->
                        {
                          candidate_id = admission.candidate_id;
                          decision = Held;
                          rationale =
                            "activated source must be a CENTL value or \
                             function definition";
                          activated = false;
                          activation_path = None;
                          rollback_snapshot = snapshot;
                        }
                    | Some name -> (
                        match
                          activate workspace ~name ~source
                            ~candidate_id:candidate.id
                            ~transaction_fingerprint:
                              candidate.transaction_fingerprint
                        with
                        | Error message ->
                            {
                              candidate_id = admission.candidate_id;
                              decision = Held;
                              rationale = "activation failed: " ^ message;
                              activated = false;
                              activation_path = None;
                              rollback_snapshot = snapshot;
                            }
                        | Ok path ->
                            {
                              candidate_id = admission.candidate_id;
                              decision = Accepted;
                              rationale =
                                "admissible downstream candidate activated as \
                                 an unverified generated local extension";
                              activated = true;
                              activation_path = Some path;
                              rollback_snapshot = snapshot;
                            })))
            | _ ->
                {
                  candidate_id = admission.candidate_id;
                  decision = Held;
                  rationale =
                    "no materialized parser-validated source is available to \
                     activate";
                  activated = false;
                  activation_path = None;
                  rollback_snapshot = snapshot;
                })
        end

let assess ?(activate = false) workspace policy candidates materialization
    evidence (admission : Centl_sci_mirage_admission.report) =
  let decisions =
    if not activate then
      List.map
        (fun (candidate : Centl_sci_mirage_admission.candidate_admission) ->
          {
            candidate_id = candidate.candidate_id;
            decision =
              (match candidate.state with
              | Centl_sci_mirage_admission.Admissible -> Held
              | Centl_sci_mirage_admission.Pending -> Held
              | Centl_sci_mirage_admission.Blocked -> Rejected);
            rationale =
              "cycle assessment never activates source; use an explicit accept \
               under a permitting policy";
            activated = false;
            activation_path = None;
            rollback_snapshot = snapshot_for evidence candidate.candidate_id;
          })
        admission.candidates
    else
      List.map
        (decide_one workspace policy candidates materialization evidence)
        admission.candidates
  in
  {
    policy = Centl_sci_mirage_policy.level_text policy.level;
    decisions;
    workspace_mutated =
      List.exists (fun decision -> decision.activated) decisions;
    assurance_promoted = false;
  }

let accept_one workspace policy candidates materialization evidence admission
    candidate_id =
  match
    List.find_opt
      (fun (candidate : Centl_sci_mirage_admission.candidate_admission) ->
        String.equal candidate.candidate_id candidate_id)
      admission.Centl_sci_mirage_admission.candidates
  with
  | None -> Error ("unknown MIRAGE candidate: " ^ candidate_id)
  | Some candidate ->
      Ok
        (decide_one workspace policy candidates materialization evidence
           candidate)

let reject_one candidate_id =
  {
    candidate_id;
    decision = Rejected;
    rationale = "explicit human rejection recorded; no source was activated";
    activated = false;
    activation_path = None;
    rollback_snapshot = None;
  }

let decision_to_json decision =
  `Assoc
    [
      ("candidate_id", `String decision.candidate_id);
      ("decision", `String (decision_text decision.decision));
      ("rationale", `String decision.rationale);
      ("activated", `Bool decision.activated);
      ( "activation_path",
        match decision.activation_path with
        | None -> `Null
        | Some path -> `String path );
      ( "rollback_snapshot",
        match decision.rollback_snapshot with
        | None -> `Null
        | Some path -> `String path );
      ("assurance_promoted", `Bool false);
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "candidate_acceptance");
      ("policy", `String report.policy);
      ("workspace_mutated", `Bool report.workspace_mutated);
      ("assurance_promoted", `Bool false);
      ("network_required", `Bool false);
      ( "acceptance_semantics",
        `String
          "acceptance records a local policy decision; activation never \
           promotes verified-core assurance and never publishes" );
      ("decisions", `List (List.map decision_to_json report.decisions));
    ]

let output_path review_path =
  if String.ends_with ~suffix:".review.json" review_path then
    String.sub review_path 0
      (String.length review_path - String.length ".review.json")
    ^ ".acceptance.json"
  else review_path ^ ".acceptance.json"

let construct review_path report =
  let path = output_path review_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  let accepted, held, rejected =
    List.fold_left
      (fun (accepted, held, rejected) decision ->
        match decision.decision with
        | Accepted -> (accepted + 1, held, rejected)
        | Held -> (accepted, held + 1, rejected)
        | Rejected -> (accepted, held, rejected + 1))
      (0, 0, 0) report.decisions
  in
  String.concat "\n"
    [
      "CENTL-MIRAGE candidate acceptance";
      "policy: " ^ report.policy;
      "accepted: " ^ string_of_int accepted;
      "held: " ^ string_of_int held;
      "rejected: " ^ string_of_int rejected;
      ("workspace mutated: " ^ if report.workspace_mutated then "yes" else "no");
      "assurance promoted: no";
    ]
