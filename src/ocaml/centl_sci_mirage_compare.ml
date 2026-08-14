type change_kind = Preserved | Changed | Added | Removed

type observation_delta = {
  source : string;
  kind : change_kind;
  baseline : Centl_sci_mirage_fingerprint.observation option;
  candidate : Centl_sci_mirage_fingerprint.observation option;
}

type report = {
  baseline_fingerprint : string;
  candidate_fingerprint : string;
  preserved : int;
  changed : int;
  added : int;
  removed : int;
  deltas : observation_delta list;
  behavior_preserved : bool;
  core_preserved : bool;
}

let kind_text = function
  | Preserved -> "preserved"
  | Changed -> "changed"
  | Added -> "added"
  | Removed -> "removed"

let observation_equal left right =
  String.equal left.Centl_sci_mirage_fingerprint.status
    right.Centl_sci_mirage_fingerprint.status
  && String.equal left.Centl_sci_mirage_fingerprint.value_kind
       right.Centl_sci_mirage_fingerprint.value_kind
  && String.equal left.Centl_sci_mirage_fingerprint.text
       right.Centl_sci_mirage_fingerprint.text
  && String.equal left.Centl_sci_mirage_fingerprint.resolution
       right.Centl_sci_mirage_fingerprint.resolution

let index_observations observations =
  List.fold_left
    (fun acc observation ->
      (observation.Centl_sci_mirage_fingerprint.source, observation) :: acc)
    [] observations

let lookup source indexed = List.assoc_opt source indexed

let compare_reports ~baseline ~candidate =
  let baseline_index =
    index_observations baseline.Centl_sci_mirage_fingerprint.observations
  in
  let candidate_index =
    index_observations candidate.Centl_sci_mirage_fingerprint.observations
  in
  let sources =
    List.map fst baseline_index @ List.map fst candidate_index
    |> List.sort_uniq String.compare
  in
  let deltas =
    List.map
      (fun source ->
        match (lookup source baseline_index, lookup source candidate_index) with
        | Some left, Some right when observation_equal left right ->
            {
              source;
              kind = Preserved;
              baseline = Some left;
              candidate = Some right;
            }
        | Some left, Some right ->
            {
              source;
              kind = Changed;
              baseline = Some left;
              candidate = Some right;
            }
        | None, Some right ->
            { source; kind = Added; baseline = None; candidate = Some right }
        | Some left, None ->
            { source; kind = Removed; baseline = Some left; candidate = None }
        | None, None ->
            { source; kind = Preserved; baseline = None; candidate = None })
      sources
  in
  let count kind =
    List.fold_left
      (fun total delta -> if delta.kind = kind then total + 1 else total)
      0 deltas
  in
  let preserved = count Preserved in
  let changed = count Changed in
  let added = count Added in
  let removed = count Removed in
  {
    baseline_fingerprint = baseline.fingerprint;
    candidate_fingerprint = candidate.fingerprint;
    preserved;
    changed;
    added;
    removed;
    deltas;
    behavior_preserved = changed = 0 && added = 0 && removed = 0;
    core_preserved =
      List.for_all
        (fun delta ->
          (not
             (List.mem delta.source Centl_sci_mirage_fingerprint.default_corpus))
          || delta.kind = Preserved)
        deltas;
  }

let delta_to_json delta =
  `Assoc
    [
      ("source", `String delta.source); ("kind", `String (kind_text delta.kind));
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "semantic_fingerprint_comparison");
      ("baseline_fingerprint", `String report.baseline_fingerprint);
      ("candidate_fingerprint", `String report.candidate_fingerprint);
      ("preserved", `Int report.preserved);
      ("changed", `Int report.changed);
      ("added", `Int report.added);
      ("removed", `Int report.removed);
      ("behavior_preserved", `Bool report.behavior_preserved);
      ("core_preserved", `Bool report.core_preserved);
      ( "comparison_semantics",
        `String
          "comparison records observed corpus differences only; matching \
           fingerprints are not a proof of total program equivalence" );
      ("deltas", `List (List.map delta_to_json report.deltas));
    ]

let output_path fingerprint_path =
  if String.ends_with ~suffix:".fingerprint.json" fingerprint_path then
    String.sub fingerprint_path 0
      (String.length fingerprint_path - String.length ".fingerprint.json")
    ^ ".compare.json"
  else fingerprint_path ^ ".compare.json"

let construct fingerprint_path report =
  let path = output_path fingerprint_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  String.concat "\n"
    [
      "CENTL-MIRAGE semantic fingerprint comparison";
      "preserved observations: " ^ string_of_int report.preserved;
      "changed observations: " ^ string_of_int report.changed;
      "added observations: " ^ string_of_int report.added;
      "removed observations: " ^ string_of_int report.removed;
      ("behavior preserved on observed corpus: "
      ^ if report.behavior_preserved then "yes" else "no");
      ("core corpus preserved: " ^ if report.core_preserved then "yes" else "no");
      "total equivalence proof: no";
    ]
