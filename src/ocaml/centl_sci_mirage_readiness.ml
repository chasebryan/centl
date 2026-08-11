type state = Structurally_established | Execution_required

type check = {
  obligation_id : string;
  cell_id : int;
  kind : string;
  state : state;
  rationale : string;
}

type candidate_readiness = {
  candidate_id : string;
  transaction_fingerprint : string;
  checks : check list;
  execution_required : bool;
  assurance_promoted : bool;
}

type report = {
  candidates : candidate_readiness list;
  blocked_cells : int list;
}

let state_text = function
  | Structurally_established -> "structurally_established"
  | Execution_required -> "execution_required"

let obligation_for_id (obligations : Centl_sci_mirage_obligation.report) id =
  List.find_opt
    (fun obligation ->
      String.equal obligation.Centl_sci_mirage_obligation.id id)
    obligations.obligations

let materialization_for_candidate
    (materialization : Centl_sci_mirage_materialize.report) candidate_id =
  List.find_opt
    (fun item ->
      String.equal item.Centl_sci_mirage_materialize.candidate_id candidate_id)
    materialization.items

let candidate_parse_readiness materialization =
  match materialization with
  | Some item
    when item.Centl_sci_mirage_materialize.state
         = Centl_sci_mirage_materialize.Materialized_source
         && item.parser_validated ->
      ( Structurally_established,
        "candidate materialization produced CENTL source and the authoritative \
         parser accepted that exact staged source; this establishes syntax \
         only, not mathematical correctness or regression success" )
  | Some item
    when item.Centl_sci_mirage_materialize.state
         = Centl_sci_mirage_materialize.Declarative_reuse ->
      ( Structurally_established,
        "the candidate is a declarative composition of existing capabilities \
         and introduces no generated CENTL source requiring a parser gate at \
         this stage" )
  | Some item
    when item.Centl_sci_mirage_materialize.state
         = Centl_sci_mirage_materialize.Blocked ->
      ( Execution_required,
        "candidate materialization is blocked; no successful authoritative \
         parser result exists for an activatable source candidate" )
  | Some _ ->
      ( Execution_required,
        "candidate materialization does not contain a successful authoritative \
         parser result" )
  | None ->
      ( Execution_required,
        "no transaction-bound candidate materialization record is available \
         for parser readiness" )

let check_of_obligation (candidate : Centl_sci_mirage_candidate.candidate)
    materialization (obligation : Centl_sci_mirage_obligation.obligation) =
  let open Centl_sci_mirage_obligation in
  let state, rationale =
    match obligation.kind with
    | Provenance_complete ->
        ( Structurally_established,
          "candidate identity is bound to the originating specification cell; \
           runtime revision attribution remains an activation concern" )
    | Reuse_attempted
      when match candidate.strategy with
           | Centl_sci_mirage_candidate.Compose_existing
           | Centl_sci_mirage_candidate.Alias_or_wrapper ->
               candidate.capability_inputs <> []
           | Centl_sci_mirage_candidate.Downstream_extension
           | Centl_sci_mirage_candidate.Isolated_core_patch ->
               false ->
        ( Structurally_established,
          "the staged candidate is explicitly based on matched existing \
           capabilities" )
    | Trust_boundary_explicit ->
        ( Structurally_established,
          "the staged candidate carries an explicit non-promotion assurance \
           statement" )
    | Candidate_parses -> candidate_parse_readiness materialization
    | Mandatory_regression ->
        ( Execution_required,
          "the relevant deterministic regression gates have not yet been \
           executed" )
    | Rollback_available ->
        ( Execution_required,
          "a reversible pre-activation workspace snapshot must still be \
           established" )
    | Reuse_attempted ->
        ( Execution_required,
          "reuse/composition evidence is not yet sufficient for this candidate"
        )
    | Core_validation ->
        ( Execution_required,
          "full relevant core verification and regression gates have not yet \
           been executed" )
    | Clarification_required | Conflict_resolution_required | Policy_boundary ->
        ( Execution_required,
          "this blocking obligation must be resolved before a candidate may \
           advance" )
  in
  {
    obligation_id = obligation.id;
    cell_id = obligation.cell_id;
    kind = kind_text obligation.kind;
    state;
    rationale;
  }

let readiness_for_candidate obligations materialization
    (candidate : Centl_sci_mirage_candidate.candidate) =
  let materialization =
    materialization_for_candidate materialization candidate.id
  in
  let checks =
    candidate.obligation_ids
    |> List.filter_map (fun id ->
        match obligation_for_id obligations id with
        | None -> None
        | Some obligation ->
            Some (check_of_obligation candidate materialization obligation))
  in
  let execution_required =
    List.exists (fun check -> check.state = Execution_required) checks
  in
  {
    candidate_id = candidate.id;
    transaction_fingerprint = candidate.transaction_fingerprint;
    checks;
    execution_required;
    assurance_promoted = false;
  }

let build (obligations : Centl_sci_mirage_obligation.report)
    (candidates : Centl_sci_mirage_candidate.report)
    (materialization : Centl_sci_mirage_materialize.report) =
  {
    candidates =
      List.map
        (readiness_for_candidate obligations materialization)
        candidates.candidates;
    blocked_cells = candidates.blocked_cells;
  }

let check_to_json check =
  `Assoc
    [
      ("obligation_id", `String check.obligation_id);
      ("cell_id", `Int check.cell_id);
      ("kind", `String check.kind);
      ("state", `String (state_text check.state));
      ("rationale", `String check.rationale);
    ]

let candidate_to_json candidate =
  `Assoc
    [
      ("candidate_id", `String candidate.candidate_id);
      ("transaction_fingerprint_algorithm", `String "sha256");
      ("transaction_fingerprint", `String candidate.transaction_fingerprint);
      ("execution_required", `Bool candidate.execution_required);
      ("admissible", `Bool false);
      ("assurance_promoted", `Bool candidate.assurance_promoted);
      ("checks", `List (List.map check_to_json candidate.checks));
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 2);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "candidate_evidence_readiness");
      ("candidate_count", `Int (List.length report.candidates));
      ( "blocked_cells",
        `List (List.map (fun id -> `Int id) report.blocked_cells) );
      ("workspace_mutated", `Bool false);
      ("assurance_promoted", `Bool false);
      ( "materialization_evidence_semantics",
        `String
          "readiness consumes transaction-bound candidate materialization \
           evidence; an authoritative parser success establishes syntax only, \
           while blocked or missing materialization keeps parser readiness \
           pending" );
      ( "admissibility_semantics",
        `String
          "readiness is not full validation; candidates remain inadmissible \
           until every remaining mandatory execution obligation is actually \
           discharged" );
      ("candidates", `List (List.map candidate_to_json report.candidates));
    ]

let output_path candidates_path =
  if String.ends_with ~suffix:".candidates.json" candidates_path then
    String.sub candidates_path 0
      (String.length candidates_path - String.length ".candidates.json")
    ^ ".readiness.json"
  else candidates_path ^ ".readiness.json"

let construct candidates_path obligations candidates materialization =
  let report = build obligations candidates materialization in
  let path = output_path candidates_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  let execution_required =
    report.candidates
    |> List.filter (fun candidate -> candidate.execution_required)
    |> List.length
  in
  String.concat "\n"
    [
      "CENTL-MIRAGE candidate evidence readiness";
      "candidates: " ^ string_of_int (List.length report.candidates);
      "candidates requiring execution: " ^ string_of_int execution_required;
      "materialization parser evidence: consumed when transaction-bound and \
       successful";
      "workspace mutated: no";
      "assurance promoted: no";
      "admissible candidates: none until mandatory execution obligations are \
       discharged";
    ]
