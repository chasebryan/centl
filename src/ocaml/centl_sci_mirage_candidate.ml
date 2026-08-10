type strategy =
  | Compose_existing
  | Alias_or_wrapper
  | Downstream_extension
  | Isolated_core_patch

type state = Planned

type candidate = {
  id : string;
  cell_id : int;
  strategy : strategy;
  state : state;
  capability_inputs : string list;
  obligation_ids : string list;
  assurance : string;
  mutates_workspace : bool;
}

type report = {
  candidates : candidate list;
  blocked_cells : int list;
}

let strategy_text = function
  | Compose_existing -> "compose_existing"
  | Alias_or_wrapper -> "alias_or_wrapper"
  | Downstream_extension -> "downstream_extension"
  | Isolated_core_patch -> "isolated_core_patch"

let state_text = function Planned -> "planned"

let strategy_of_gap_status = function
  | Centl_sci_mirage_goal.Composable -> Some Compose_existing
  | Centl_sci_mirage_goal.Alias_or_wrapper -> Some Alias_or_wrapper
  | Centl_sci_mirage_goal.Extension_required -> Some Downstream_extension
  | Centl_sci_mirage_goal.Core_change_required -> Some Isolated_core_patch
  | Centl_sci_mirage_goal.Satisfied
  | Centl_sci_mirage_goal.Ambiguous
  | Centl_sci_mirage_goal.Conflicting
  | Centl_sci_mirage_goal.Unsupported_by_policy -> None

let assurance_text = function
  | Compose_existing ->
      "planned composition only; matched capabilities retain their own assurance and no new assurance is inferred"
  | Alias_or_wrapper ->
      "planned wrapper only; existing capability semantics must be preserved and no assurance is promoted"
  | Downstream_extension ->
      "planned local downstream extension; generated code is unverified until its mandatory obligations are discharged"
  | Isolated_core_patch ->
      "planned isolated core candidate; generated code is not verified core unless the full relevant core gates establish that claim"

let obligations_for_cell (report : Centl_sci_mirage_obligation.report) cell_id =
  report.obligations
  |> List.filter (fun obligation -> obligation.Centl_sci_mirage_obligation.cell_id = cell_id)
  |> List.map (fun obligation -> obligation.Centl_sci_mirage_obligation.id)

let candidate_of_gap obligations (gap : Centl_sci_mirage_goal.gap) =
  match strategy_of_gap_status gap.status with
  | None -> None
  | Some strategy ->
      Some
        {
          id = Printf.sprintf "candidate:cell:%d:%s" gap.cell_id (strategy_text strategy);
          cell_id = gap.cell_id;
          strategy;
          state = Planned;
          capability_inputs = gap.capability_matches;
          obligation_ids = obligations_for_cell obligations gap.cell_id;
          assurance = assurance_text strategy;
          mutates_workspace = false;
        }

let build (graph : Centl_sci_mirage_goal.graph)
    (obligations : Centl_sci_mirage_obligation.report) =
  let blocked_cells = obligations.blocked_cells in
  let candidates =
    graph.gaps
    |> List.filter (fun gap -> not (List.mem gap.Centl_sci_mirage_goal.cell_id blocked_cells))
    |> List.filter_map (candidate_of_gap obligations)
  in
  { candidates; blocked_cells }

let json_strings values = `List (List.map (fun value -> `String value) values)

let candidate_to_json candidate =
  `Assoc
    [
      ("id", `String candidate.id);
      ("cell_id", `Int candidate.cell_id);
      ("strategy", `String (strategy_text candidate.strategy));
      ("state", `String (state_text candidate.state));
      ("capability_inputs", json_strings candidate.capability_inputs);
      ("obligation_ids", json_strings candidate.obligation_ids);
      ("assurance", `String candidate.assurance);
      ("mutates_workspace", `Bool candidate.mutates_workspace);
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "candidate_transactions");
      ("candidate_count", `Int (List.length report.candidates));
      ("candidate_blocked", `Bool (report.blocked_cells <> []));
      ("blocked_cells", `List (List.map (fun id -> `Int id) report.blocked_cells));
      ("workspace_mutated", `Bool false);
      ("assurance_promoted", `Bool false);
      ("candidates", `List (List.map candidate_to_json report.candidates));
    ]

let output_path obligation_path =
  if String.ends_with ~suffix:".obligations.json" obligation_path then
    String.sub obligation_path 0
      (String.length obligation_path - String.length ".obligations.json")
    ^ ".candidates.json"
  else obligation_path ^ ".candidates.json"

let construct obligation_path graph obligations =
  let report = build graph obligations in
  let path = output_path obligation_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  let blocked =
    match report.blocked_cells with
    | [] -> "none"
    | values -> String.concat ", " (List.map string_of_int values)
  in
  String.concat "\n"
    [
      "CENTL-MIRAGE candidate transactions";
      "planned candidates: " ^ string_of_int (List.length report.candidates);
      "candidate-blocked cells: " ^ blocked;
      "workspace mutated: no";
      "assurance promoted: no";
    ]
