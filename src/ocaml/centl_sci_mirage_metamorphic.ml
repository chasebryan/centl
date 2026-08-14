type kind = Determinism | Exactness | Substitution | Homogeneity
type status = Established | Hypothesis | Refuted

type property = {
  property_id : string;
  candidate_id : string;
  kind : kind;
  statement : string;
  status : status;
  evidence : string;
}

type report = { properties : property list }

let kind_text = function
  | Determinism -> "determinism"
  | Exactness -> "exactness"
  | Substitution -> "equality_substitution"
  | Homogeneity -> "homogeneity"

let status_text = function
  | Established -> "established"
  | Hypothesis -> "hypothesis"
  | Refuted -> "refuted"

let evaluate_text session source =
  match Centl_engine.evaluate_in_session_detailed session source with
  | Ok outcome -> (
      match outcome.result with
      | Centl_engine.Session_value value ->
          Ok (Centl_engine.text_of_value value, value)
      | Centl_engine.Defined_value (_, value) ->
          Ok (Centl_engine.text_of_value value, value)
      | Centl_engine.Defined_function (name, _, _) ->
          Error ("definition rather than value: " ^ name))
  | Error error -> Error (Centl_engine.error_text error)

let load_source session = function
  | None -> Ok ()
  | Some source -> (
      match Centl_engine.evaluate_in_session_detailed session source with
      | Ok _ -> Ok ()
      | Error error -> Error (Centl_engine.error_text error))

let rewrite_first_number source =
  let rec loop index =
    if index >= String.length source then None
    else
      match source.[index] with
      | '0' .. '9' ->
          let rec digits finish =
            if finish < String.length source then
              match source.[finish] with
              | '0' .. '9' -> digits (finish + 1)
              | _ -> finish
            else finish
          in
          let finish = digits (index + 1) in
          let number = String.sub source index (finish - index) in
          if number = "0" then loop finish
          else
            Some
              (String.sub source 0 index ^ "(" ^ number ^ "+0)"
              ^ String.sub source finish (String.length source - finish))
      | _ -> loop (index + 1)
  in
  loop 0

let session_for source =
  let session = Centl_engine.create_session () in
  match load_source session source with
  | Ok () -> Some session
  | Error _ -> None

let check_determinism candidate_id source example =
  match session_for source with
  | None ->
      {
        property_id = candidate_id ^ ":determinism";
        candidate_id;
        kind = Determinism;
        statement = example.Centl_sci_mirage_cegis.left ^ " is deterministic";
        status = Hypothesis;
        evidence = "candidate source could not be loaded for property testing";
      }
  | Some session -> (
      match
        ( evaluate_text session example.Centl_sci_mirage_cegis.left,
          evaluate_text session example.left )
      with
      | Ok (first, _), Ok (second, _) when String.equal first second ->
          {
            property_id = candidate_id ^ ":determinism";
            candidate_id;
            kind = Determinism;
            statement = example.left ^ " is deterministic";
            status = Established;
            evidence = "two independent evaluations produced " ^ first;
          }
      | Ok (first, _), Ok (second, _) ->
          {
            property_id = candidate_id ^ ":determinism";
            candidate_id;
            kind = Determinism;
            statement = example.left ^ " is deterministic";
            status = Refuted;
            evidence = first ^ " versus " ^ second;
          }
      | Error message, _ | _, Error message ->
          {
            property_id = candidate_id ^ ":determinism";
            candidate_id;
            kind = Determinism;
            statement = example.left ^ " is deterministic";
            status = Hypothesis;
            evidence = message;
          })

let check_exactness candidate_id source example =
  match session_for source with
  | None ->
      {
        property_id = candidate_id ^ ":exactness";
        candidate_id;
        kind = Exactness;
        statement = example.Centl_sci_mirage_cegis.left ^ " remains exact";
        status = Hypothesis;
        evidence = "candidate source could not be loaded for property testing";
      }
  | Some session -> (
      match evaluate_text session example.left with
      | Ok (_, Centl_engine.Real_enclosure _) ->
          {
            property_id = candidate_id ^ ":exactness";
            candidate_id;
            kind = Exactness;
            statement = example.left ^ " remains exact";
            status = Refuted;
            evidence = "evaluation returned a real enclosure";
          }
      | Ok (text, _) ->
          {
            property_id = candidate_id ^ ":exactness";
            candidate_id;
            kind = Exactness;
            statement = example.left ^ " remains exact";
            status = Established;
            evidence = "evaluation produced exact value " ^ text;
          }
      | Error message ->
          {
            property_id = candidate_id ^ ":exactness";
            candidate_id;
            kind = Exactness;
            statement = example.left ^ " remains exact";
            status = Hypothesis;
            evidence = message;
          })

let check_substitution candidate_id source example =
  match rewrite_first_number example.Centl_sci_mirage_cegis.left with
  | None ->
      {
        property_id = candidate_id ^ ":substitution";
        candidate_id;
        kind = Substitution;
        statement = "equal rational rewrites preserve " ^ example.left;
        status = Hypothesis;
        evidence = "no nonzero numeral was available to rewrite";
      }
  | Some mutated -> (
      match session_for source with
      | None ->
          {
            property_id = candidate_id ^ ":substitution";
            candidate_id;
            kind = Substitution;
            statement = mutated ^ " equals " ^ example.left;
            status = Hypothesis;
            evidence = "candidate source could not be loaded";
          }
      | Some session -> (
          match
            (evaluate_text session example.left, evaluate_text session mutated)
          with
          | Ok (left, _), Ok (right, _) when String.equal left right ->
              {
                property_id = candidate_id ^ ":substitution";
                candidate_id;
                kind = Substitution;
                statement = mutated ^ " equals " ^ example.left;
                status = Established;
                evidence = "both evaluations produced " ^ left;
              }
          | Ok (left, _), Ok (right, _) ->
              {
                property_id = candidate_id ^ ":substitution";
                candidate_id;
                kind = Substitution;
                statement = mutated ^ " equals " ^ example.left;
                status = Refuted;
                evidence = left ^ " versus " ^ right;
              }
          | Error message, _ | _, Error message ->
              {
                property_id = candidate_id ^ ":substitution";
                candidate_id;
                kind = Substitution;
                statement = mutated ^ " equals " ^ example.left;
                status = Hypothesis;
                evidence = message;
              }))

let properties_for_trial examples (trial : Centl_sci_mirage_cegis.trial) =
  match (trial.state, examples) with
  | Centl_sci_mirage_cegis.Valid, example :: _ when trial.examples_checked > 0
    ->
      [
        check_determinism trial.candidate_id trial.source example;
        check_exactness trial.candidate_id trial.source example;
        check_substitution trial.candidate_id trial.source example;
      ]
  | _ -> []

let run (cegis : Centl_sci_mirage_cegis.report) =
  {
    properties =
      List.concat_map (properties_for_trial cegis.examples) cegis.trials;
  }

let property_to_json property =
  `Assoc
    [
      ("property_id", `String property.property_id);
      ("candidate_id", `String property.candidate_id);
      ("kind", `String (kind_text property.kind));
      ("statement", `String property.statement);
      ("status", `String (status_text property.status));
      ("evidence", `String property.evidence);
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "metamorphic_properties");
      ("property_count", `Int (List.length report.properties));
      ( "property_semantics",
        `String
          "established properties were checked by CENTL evaluation; hypotheses \
           remain unproven; no property inherits verified-core assurance" );
      ("properties", `List (List.map property_to_json report.properties));
    ]

let output_path cegis_path =
  if String.ends_with ~suffix:".cegis.json" cegis_path then
    String.sub cegis_path 0
      (String.length cegis_path - String.length ".cegis.json")
    ^ ".properties.json"
  else cegis_path ^ ".properties.json"

let construct cegis_path cegis =
  let report = run cegis in
  let path = output_path cegis_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  let established, hypothesis, refuted =
    List.fold_left
      (fun (established, hypothesis, refuted) property ->
        match property.status with
        | Established -> (established + 1, hypothesis, refuted)
        | Hypothesis -> (established, hypothesis + 1, refuted)
        | Refuted -> (established, hypothesis, refuted + 1))
      (0, 0, 0) report.properties
  in
  String.concat "\n"
    [
      "CENTL-MIRAGE metamorphic properties";
      "established: " ^ string_of_int established;
      "hypotheses: " ^ string_of_int hypothesis;
      "refuted: " ^ string_of_int refuted;
      "assurance promoted: no";
    ]
