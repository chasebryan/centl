type candidate_review = {
  candidate_id : string;
  transaction_fingerprint : string;
  receipt_fingerprints : string list;
  review_fingerprint : string;
  decision_required : string;
}

type report = {
  candidates : candidate_review list;
  omitted_candidate_count : int;
}

let fingerprint_material candidate_id transaction_fingerprint receipt_fingerprints =
  String.concat "\n"
    ([ "CENTL-MIRAGE-REVIEW-v1"; candidate_id; transaction_fingerprint ]
    @ List.sort String.compare receipt_fingerprints)

let review_of_admission
    (candidate : Centl_sci_mirage_admission.candidate_admission) =
  let review_fingerprint =
    fingerprint_material candidate.candidate_id candidate.transaction_fingerprint
      candidate.receipt_fingerprints
    |> Centl_sha256.hex_string
  in
  {
    candidate_id = candidate.candidate_id;
    transaction_fingerprint = candidate.transaction_fingerprint;
    receipt_fingerprints = candidate.receipt_fingerprints;
    review_fingerprint;
    decision_required =
      "explicit human acceptance is required before any activation mechanism may be considered";
  }

let prepare (admission : Centl_sci_mirage_admission.report) =
  let candidates =
    List.filter_map
      (fun (candidate : Centl_sci_mirage_admission.candidate_admission) ->
        match candidate.state with
        | Centl_sci_mirage_admission.Admissible -> Some (review_of_admission candidate)
        | Centl_sci_mirage_admission.Pending | Centl_sci_mirage_admission.Blocked -> None)
      admission.candidates
  in
  {
    candidates;
    omitted_candidate_count = List.length admission.candidates - List.length candidates;
  }

let candidate_to_json candidate =
  `Assoc
    [
      ("candidate_id", `String candidate.candidate_id);
      ("transaction_fingerprint", `String candidate.transaction_fingerprint);
      ( "receipt_fingerprints",
        `List (List.map (fun value -> `String value) candidate.receipt_fingerprints) );
      ("review_fingerprint", `String candidate.review_fingerprint);
      ("decision_required", `String candidate.decision_required);
      ("human_accepted", `Bool false);
      ("candidate_source_activated", `Bool false);
      ("assurance_promoted", `Bool false);
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "candidate_review_manifest");
      ("review_candidate_count", `Int (List.length report.candidates));
      ("omitted_candidate_count", `Int report.omitted_candidate_count);
      ("human_acceptance_required", `Bool true);
      ("candidate_source_activated", `Bool false);
      ("assurance_promoted", `Bool false);
      ( "review_semantics",
        `String
          "this manifest exposes only candidates already assessed admissible for explicit human review; review fingerprints bind transaction and evidence receipt identities, but do not establish mathematical correctness, activate source, or promote assurance" );
      ("candidates", `List (List.map candidate_to_json report.candidates));
    ]

let output_path admission_path =
  if String.ends_with ~suffix:".admission.json" admission_path then
    String.sub admission_path 0
      (String.length admission_path - String.length ".admission.json")
    ^ ".review.json"
  else admission_path ^ ".review.json"

let construct admission_path admission =
  let report = prepare admission in
  let path = output_path admission_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  String.concat "\n"
    [
      "CENTL-MIRAGE candidate review manifest";
      "review candidates: " ^ string_of_int (List.length report.candidates);
      "omitted non-admissible candidates: " ^ string_of_int report.omitted_candidate_count;
      "human acceptance required: yes";
      "candidate source activated: no";
      "assurance promoted: no";
    ]
