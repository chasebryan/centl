type rank =
  | Parsed
  | Type_dimension_checked
  | Example_tested
  | Property_tested
  | Regression_tested
  | Differential_tested
  | Verifier_discharged
  | Formally_verified

type claim = {
  claim_id : string;
  candidate_id : string;
  rank : rank;
  established : bool;
  scope : string;
  evidence : string;
}

type candidate_lattice = {
  candidate_id : string;
  strongest_established : rank option;
  claims : claim list;
}

type report = { candidates : candidate_lattice list }

let rank_text = function
  | Parsed -> "parsed"
  | Type_dimension_checked -> "type_dimension_checked"
  | Example_tested -> "example_tested"
  | Property_tested -> "property_tested"
  | Regression_tested -> "regression_tested"
  | Differential_tested -> "differential_tested"
  | Verifier_discharged -> "verifier_discharged"
  | Formally_verified -> "formally_verified"

let rank_order = function
  | Parsed -> 0
  | Type_dimension_checked -> 1
  | Example_tested -> 2
  | Property_tested -> 3
  | Regression_tested -> 4
  | Differential_tested -> 5
  | Verifier_discharged -> 6
  | Formally_verified -> 7

let claim ~candidate_id ~rank ~established ~scope evidence =
  {
    claim_id =
      Printf.sprintf "%s:%s:%s" candidate_id (rank_text rank)
        (if established then "established" else "absent");
    candidate_id;
    rank;
    established;
    scope;
    evidence;
  }

let receipts_for evidence candidate_id =
  List.filter
    (fun (receipt : Centl_sci_mirage_evidence.receipt) ->
      String.equal receipt.candidate_id candidate_id)
    evidence.Centl_sci_mirage_evidence.receipts

let passed_kind receipts kind =
  List.exists
    (fun (receipt : Centl_sci_mirage_evidence.receipt) ->
      receipt.state = Centl_sci_mirage_evidence.Passed && receipt.kind = kind)
    receipts

let cegis_valid cegis candidate_id =
  List.exists
    (fun trial ->
      String.equal trial.Centl_sci_mirage_cegis.candidate_id candidate_id
      && trial.state = Centl_sci_mirage_cegis.Valid
      && trial.examples_checked > 0)
    cegis.Centl_sci_mirage_cegis.trials

let property_established properties candidate_id =
  List.exists
    (fun (property : Centl_sci_mirage_metamorphic.property) ->
      String.equal property.candidate_id candidate_id
      && property.status = Centl_sci_mirage_metamorphic.Established)
    properties

let strongest claims =
  claims
  |> List.filter (fun claim -> claim.established)
  |> List.fold_left
       (fun acc claim ->
         match acc with
         | None -> Some claim.rank
         | Some rank when rank_order claim.rank > rank_order rank ->
             Some claim.rank
         | Some _ as acc -> acc)
       None

let lattice_for evidence cegis compare properties
    (candidate : Centl_sci_mirage_candidate.candidate) =
  let receipts = receipts_for evidence candidate.id in
  let parsed = passed_kind receipts "candidate_parses" in
  let examples = cegis_valid cegis candidate.id in
  let properties_ok = property_established properties candidate.id in
  let regression =
    passed_kind receipts "mandatory_regression"
    || compare.Centl_sci_mirage_compare.behavior_preserved
       && candidate.strategy = Centl_sci_mirage_candidate.Compose_existing
  in
  let claims =
    [
      claim ~candidate_id:candidate.id ~rank:Parsed ~established:parsed
        ~scope:"syntax" "authoritative parser or declarative reuse";
      claim ~candidate_id:candidate.id ~rank:Type_dimension_checked
        ~established:parsed ~scope:"syntax"
        "parser acceptance is the current type/dimension proxy for native \
         CENTL source";
      claim ~candidate_id:candidate.id ~rank:Example_tested
        ~established:examples ~scope:"extracted examples"
        "CEGIS example verification";
      claim ~candidate_id:candidate.id ~rank:Property_tested
        ~established:properties_ok ~scope:"metamorphic"
        "checked metamorphic properties";
      claim ~candidate_id:candidate.id ~rank:Regression_tested
        ~established:regression ~scope:"corpus"
        "fingerprint preservation or regression executor";
      claim ~candidate_id:candidate.id ~rank:Differential_tested
        ~established:false ~scope:"independent oracle"
        "no independent Julia/Nemo differential was executed in this cycle";
      claim ~candidate_id:candidate.id ~rank:Verifier_discharged
        ~established:false ~scope:"local verifier"
        "no separate verifier discharge beyond example/property checks";
      claim ~candidate_id:candidate.id ~rank:Formally_verified
        ~established:false ~scope:"verified core"
        "generated material never inherits formally verified-core status";
    ]
  in
  {
    candidate_id = candidate.id;
    strongest_established = strongest claims;
    claims;
  }

let build evidence cegis compare properties
    (candidates : Centl_sci_mirage_candidate.report) =
  {
    candidates =
      List.map
        (lattice_for evidence cegis compare properties)
        candidates.candidates;
  }

let claim_to_json claim =
  `Assoc
    [
      ("claim_id", `String claim.claim_id);
      ("candidate_id", `String claim.candidate_id);
      ("rank", `String (rank_text claim.rank));
      ("established", `Bool claim.established);
      ("scope", `String claim.scope);
      ("evidence", `String claim.evidence);
    ]

let candidate_to_json candidate =
  `Assoc
    [
      ("candidate_id", `String candidate.candidate_id);
      ( "strongest_established",
        match candidate.strongest_established with
        | None -> `Null
        | Some rank -> `String (rank_text rank) );
      ("claims", `List (List.map claim_to_json candidate.claims));
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "evidence_lattice");
      ("candidate_count", `Int (List.length report.candidates));
      ( "lattice_semantics",
        `String
          "ranks are claim-local; a higher established rank does not prove \
           unrelated properties or promote verified-core assurance" );
      ("candidates", `List (List.map candidate_to_json report.candidates));
    ]

let output_path evidence_path =
  if String.ends_with ~suffix:".evidence.json" evidence_path then
    String.sub evidence_path 0
      (String.length evidence_path - String.length ".evidence.json")
    ^ ".lattice.json"
  else evidence_path ^ ".lattice.json"

let construct evidence_path evidence cegis compare properties candidates =
  let report = build evidence cegis compare properties candidates in
  let path = output_path evidence_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  String.concat "\n"
    [
      "CENTL-MIRAGE evidence lattice";
      "candidates: " ^ string_of_int (List.length report.candidates);
      "formally verified generated code: no";
    ]
