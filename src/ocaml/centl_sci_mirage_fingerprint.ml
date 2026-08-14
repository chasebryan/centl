type observation = {
  source : string;
  status : string;
  value_kind : string;
  text : string;
  resolution : string;
}

type report = {
  corpus_id : string;
  observations : observation list;
  fingerprint : string;
  intended_behavior_change : bool;
}

let schema_version = 1

let default_corpus =
  [
    "0.1 + 0.2";
    "1/3 + 1/6";
    "2^8";
    "diff(x^3 + 2*x + 1, x)";
    "substitute(x^2 + 1, x = 3)";
    "solve(x^2 - 5*x + 6 = 0, x)";
    "integrate(x^2, x = 0, 3)";
    "gcd(48, 18)";
  ]

let value_kind = function
  | Centl_engine.Integer _ -> "exact_integer"
  | Centl_engine.Rational _ -> "exact_rational"
  | Centl_engine.Symbolic _ -> "exact_symbolic"
  | Centl_engine.Exact_sequence _ -> "exact_sequence"
  | Centl_engine.Real_enclosure _ -> "real_enclosure"
  | Centl_engine.Equation_result _ -> "equation_result"

let observation_of_error source error =
  {
    source;
    status = "error";
    value_kind = error.Centl_engine.code;
    text = Centl_engine.error_text error;
    resolution = "error";
  }

let observe_source source =
  match Centl_engine.evaluate_detailed source with
  | Ok outcome ->
      {
        source;
        status = "ok";
        value_kind = value_kind outcome.value;
        text = Centl_engine.text_of_value outcome.value;
        resolution =
          Centl_engine.resolution_status_code outcome.resolution.status;
      }
  | Error error -> observation_of_error source error

let observe_source_in_session session source =
  match
    Centl_engine.compute_in_session_outcome_with_limits
      Centl_engine.default_evaluation_limits session source
  with
  | Ok outcome -> (
      match outcome.result with
      | Centl_engine.Session_value value ->
          {
            source;
            status = "ok";
            value_kind = value_kind value;
            text = Centl_engine.text_of_value value;
            resolution =
              Centl_engine.resolution_status_code outcome.resolution.status;
          }
      | Centl_engine.Defined_value _ | Centl_engine.Defined_function _ ->
          {
            source;
            status = "error";
            value_kind = "definition_not_allowed";
            text = "fingerprint corpus observations are compute-only";
            resolution = "error";
          })
  | Error error -> observation_of_error source error

let load_definition session source =
  match Centl_engine.evaluate_in_session_detailed session source with
  | Ok _ -> Ok ()
  | Error error -> Error (Centl_engine.error_text error)

let observe_sources sources = List.map observe_source sources

let observation_to_json observation =
  `Assoc
    [
      ("source", `String observation.source);
      ("status", `String observation.status);
      ("value_kind", `String observation.value_kind);
      ("text", `String observation.text);
      ("resolution", `String observation.resolution);
    ]

let normalized_material observations =
  let observations =
    List.sort
      (fun left right -> String.compare left.source right.source)
      observations
  in
  `Assoc
    [
      ("fingerprint_schema_version", `Int schema_version);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "semantic_fingerprint");
      ("observations", `List (List.map observation_to_json observations));
    ]
  |> Yojson.Safe.to_string

let fingerprint_of observations =
  Centl_sha256.hex_string (normalized_material observations)

let corpus_id sources =
  sources |> List.sort String.compare |> String.concat "\n"
  |> Centl_sha256.hex_string

let observe_with_definitions ?(intended_behavior_change = false) definitions
    sources =
  let session = Centl_engine.create_session () in
  List.iter
    (fun definition -> ignore (load_definition session definition))
    definitions;
  let observations = List.map (observe_source_in_session session) sources in
  {
    corpus_id = corpus_id sources;
    observations;
    fingerprint = fingerprint_of observations;
    intended_behavior_change;
  }

let observe ?(intended_behavior_change = false) sources =
  let observations = observe_sources sources in
  {
    corpus_id = corpus_id sources;
    observations;
    fingerprint = fingerprint_of observations;
    intended_behavior_change;
  }

let observe_default () = observe default_corpus

let to_json report =
  `Assoc
    [
      ("schema_version", `Int schema_version);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "semantic_fingerprint");
      ("corpus_id", `String report.corpus_id);
      ("observation_count", `Int (List.length report.observations));
      ("fingerprint_algorithm", `String "sha256");
      ("fingerprint", `String report.fingerprint);
      ("intended_behavior_change", `Bool report.intended_behavior_change);
      ( "fingerprint_semantics",
        `String
          "a semantic fingerprint hashes normalized deterministic \
           observations; it is evidence of observed behavior, not a proof of \
           total equivalence or verified-core correctness" );
      ("observations", `List (List.map observation_to_json report.observations));
    ]

let output_path spec_path =
  if String.ends_with ~suffix:".spec.json" spec_path then
    String.sub spec_path 0 (String.length spec_path - String.length ".spec.json")
    ^ ".fingerprint.json"
  else spec_path ^ ".fingerprint.json"

let construct spec_path report =
  let path = output_path spec_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  String.concat "\n"
    [
      "CENTL-MIRAGE semantic fingerprint";
      "observations: " ^ string_of_int (List.length report.observations);
      "fingerprint: " ^ report.fingerprint;
      ("intended behavior change: "
      ^ if report.intended_behavior_change then "yes" else "no");
      "equivalence proof: no";
    ]
