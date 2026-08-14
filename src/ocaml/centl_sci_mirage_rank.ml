type scores = {
  candidate_id : string;
  strategy : string;
  semantic_delta : int;
  evidence_rank : int;
  requirement_coverage : int;
  complexity : int;
  dominated : bool;
}

type report = { frontier : string list; scores : scores list }

let semantic_delta = function
  | Centl_sci_mirage_candidate.Compose_existing -> 0
  | Centl_sci_mirage_candidate.Alias_or_wrapper -> 1
  | Centl_sci_mirage_candidate.Downstream_extension -> 2
  | Centl_sci_mirage_candidate.Isolated_core_patch -> 3

let evidence_rank lattice candidate_id =
  match
    List.find_opt
      (fun (candidate : Centl_sci_mirage_lattice.candidate_lattice) ->
        String.equal candidate.candidate_id candidate_id)
      lattice.Centl_sci_mirage_lattice.candidates
  with
  | None -> 0
  | Some candidate -> (
      match candidate.strongest_established with
      | None -> 0
      | Some rank -> Centl_sci_mirage_lattice.rank_order rank + 1)

let complexity materialization candidate_id =
  match
    List.find_opt
      (fun item ->
        String.equal item.Centl_sci_mirage_materialize.candidate_id candidate_id)
      materialization.Centl_sci_mirage_materialize.items
  with
  | Some item -> (
      match item.source with None -> 0 | Some source -> String.length source)
  | None -> 0

let no_worse left right =
  left.requirement_coverage >= right.requirement_coverage
  && left.evidence_rank >= right.evidence_rank
  && left.semantic_delta <= right.semantic_delta
  && left.complexity <= right.complexity

let strictly_better left right =
  no_worse left right
  && (left.requirement_coverage > right.requirement_coverage
     || left.evidence_rank > right.evidence_rank
     || left.semantic_delta < right.semantic_delta
     || left.complexity < right.complexity)

let score lattice materialization
    (candidate : Centl_sci_mirage_candidate.candidate) =
  {
    candidate_id = candidate.id;
    strategy = Centl_sci_mirage_candidate.strategy_text candidate.strategy;
    semantic_delta = semantic_delta candidate.strategy;
    evidence_rank = evidence_rank lattice candidate.id;
    requirement_coverage = 1;
    complexity = complexity materialization candidate.id;
    dominated = false;
  }

let mark_dominated scores =
  List.map
    (fun score ->
      let dominated =
        List.exists
          (fun other ->
            (not (String.equal other.candidate_id score.candidate_id))
            && strictly_better other score)
          scores
      in
      { score with dominated })
    scores

let compare_tie left right =
  let delta = compare left.semantic_delta right.semantic_delta in
  if delta <> 0 then delta
  else
    let evidence = compare right.evidence_rank left.evidence_rank in
    if evidence <> 0 then evidence
    else
      let coverage =
        compare right.requirement_coverage left.requirement_coverage
      in
      if coverage <> 0 then coverage
      else compare left.complexity right.complexity

let build lattice materialization
    (candidates : Centl_sci_mirage_candidate.report)
    (admission : Centl_sci_mirage_admission.report) =
  let admissible_ids =
    admission.candidates
    |> List.filter_map (fun candidate ->
        if
          candidate.Centl_sci_mirage_admission.state
          = Centl_sci_mirage_admission.Admissible
        then Some candidate.candidate_id
        else None)
  in
  let scores =
    candidates.candidates
    |> List.filter (fun candidate ->
        List.mem candidate.Centl_sci_mirage_candidate.id admissible_ids)
    |> List.map (score lattice materialization)
    |> mark_dominated |> List.sort compare_tie
  in
  {
    frontier =
      scores
      |> List.filter (fun score -> not score.dominated)
      |> List.map (fun score -> score.candidate_id);
    scores;
  }

let score_to_json score =
  `Assoc
    [
      ("candidate_id", `String score.candidate_id);
      ("strategy", `String score.strategy);
      ("semantic_delta", `Int score.semantic_delta);
      ("evidence_rank", `Int score.evidence_rank);
      ("requirement_coverage", `Int score.requirement_coverage);
      ("complexity", `Int score.complexity);
      ("dominated", `Bool score.dominated);
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "pareto_ranking");
      ("frontier", `List (List.map (fun value -> `String value) report.frontier));
      ( "ranking_semantics",
        `String
          "a Pareto frontier among admissible candidates; tie-breaking prefers \
           smaller semantic delta, then stronger evidence, then lower \
           complexity; ranking is not a reward score that can admit a blocked \
           candidate" );
      ("scores", `List (List.map score_to_json report.scores));
    ]

let output_path lattice_path =
  if String.ends_with ~suffix:".lattice.json" lattice_path then
    String.sub lattice_path 0
      (String.length lattice_path - String.length ".lattice.json")
    ^ ".rank.json"
  else lattice_path ^ ".rank.json"

let construct lattice_path lattice materialization candidates admission =
  let report = build lattice materialization candidates admission in
  let path = output_path lattice_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  String.concat "\n"
    [
      "CENTL-MIRAGE Pareto ranking";
      "admissible scored: " ^ string_of_int (List.length report.scores);
      ("frontier: "
      ^
      match report.frontier with
      | [] -> "none"
      | values -> String.concat ", " values);
      "admission override: no";
    ]
