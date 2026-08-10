type polarity = Positive | Negative

type node_kind =
  | Requirement
  | Hard_invariant
  | Acceptance_criterion
  | Example_case
  | Non_goal
  | Open_question
  | Context_note
  | Capability

type edge_kind = Refines | Constrains | Conflicts_with | Candidate_satisfied_by

type gap_status =
  | Satisfied
  | Composable
  | Alias_or_wrapper
  | Extension_required
  | Core_change_required
  | Ambiguous
  | Conflicting
  | Unsupported_by_policy

type spec_cell = { id : int; kind : string; text : string; start_line : int; end_line : int }
type node = { id : string; kind : node_kind; label : string; source_cell : int option }
type edge = { source : string; target : string; kind : edge_kind }
type gap = { cell_id : int; status : gap_status; capability_matches : string list; reason : string }
type graph = { nodes : node list; edges : edge list; gaps : gap list; conflicts : (int * int) list }

let node_kind_text = function
  | Requirement -> "requirement" | Hard_invariant -> "invariant"
  | Acceptance_criterion -> "acceptance_criterion" | Example_case -> "example"
  | Non_goal -> "non_goal" | Open_question -> "open_question"
  | Context_note -> "context" | Capability -> "capability"

let edge_kind_text = function
  | Refines -> "refines" | Constrains -> "constrains"
  | Conflicts_with -> "conflicts_with" | Candidate_satisfied_by -> "candidate_satisfied_by"

let gap_status_text = function
  | Satisfied -> "SATISFIED" | Composable -> "COMPOSABLE"
  | Alias_or_wrapper -> "ALIAS_OR_WRAPPER" | Extension_required -> "EXTENSION_REQUIRED"
  | Core_change_required -> "CORE_CHANGE_REQUIRED" | Ambiguous -> "AMBIGUOUS"
  | Conflicting -> "CONFLICTING" | Unsupported_by_policy -> "UNSUPPORTED_BY_POLICY"

let assoc_field name = function `Assoc fields -> List.assoc_opt name fields | _ -> None
let int_field name json = match assoc_field name json with Some (`Int value) -> Some value | _ -> None
let string_field name json = match assoc_field name json with Some (`String value) -> Some value | _ -> None

let parse_cell = function
  | `Assoc _ as json ->
      begin match int_field "id" json, string_field "kind" json, string_field "text" json,
                  int_field "start_line" json, int_field "end_line" json with
      | Some id, Some kind, Some text, Some start_line, Some end_line ->
          Ok { id; kind; text; start_line; end_line }
      | _ -> Error "MIRAGE specification cell is missing required fields"
      end
  | _ -> Error "MIRAGE specification cell must be an object"

let parse_cells json =
  match assoc_field "cells" json with
  | Some (`List values) ->
      let rec loop acc = function
        | [] -> Ok (List.rev acc)
        | value :: rest ->
            begin match parse_cell value with
            | Error _ as error -> error
            | Ok cell -> loop (cell :: acc) rest
            end
      in loop [] values
  | _ -> Error "MIRAGE specification IR does not contain a cells array"

let cell_node_kind kind =
  match String.uppercase_ascii kind with
  | "DIRECTIVE" -> Requirement | "INVARIANT" -> Hard_invariant
  | "ACCEPTANCE" -> Acceptance_criterion | "EXAMPLE" -> Example_case
  | "NON_GOAL" -> Non_goal | "QUESTION" -> Open_question | _ -> Context_note

let cell_node_id id = "cell:" ^ string_of_int id
let capability_node_id name = "capability:" ^ name
let lower text = String.lowercase_ascii (String.trim text)
let contains needle text = Option.is_some (Centl_sci_interaction.find_substring ~needle text)
let negative_phrases = [ "must not"; "shall not"; "should not"; "do not"; "don't"; "never"; "without" ]

let polarity (cell : spec_cell) =
  if String.uppercase_ascii cell.kind = "NON_GOAL" then Negative
  else if List.exists (fun phrase -> contains phrase (lower cell.text)) negative_phrases then Negative
  else Positive

let stop_words =
  [ "add"; "allow"; "and"; "are"; "build"; "centl"; "create"; "does"; "enable";
    "implement"; "make"; "must"; "need"; "never"; "not"; "shall"; "should"; "support";
    "system"; "the"; "this"; "user"; "users"; "want"; "with"; "without" ]

let semantic_tokens text =
  Centl_sci_capabilities.words text
  |> List.filter (fun word -> not (List.mem word stop_words))
  |> List.sort_uniq String.compare

let intersection left right = List.filter (fun value -> List.mem value right) left |> List.sort_uniq String.compare
let overlap_coefficient left right =
  let denominator = min (List.length left) (List.length right) in
  if denominator = 0 then 0.0
  else float_of_int (List.length (intersection left right)) /. float_of_int denominator

let hard_cell (cell : spec_cell) =
  match String.uppercase_ascii cell.kind with
  | "DIRECTIVE" | "INVARIANT" | "NON_GOAL" -> true | _ -> false

let likely_conflict (left : spec_cell) (right : spec_cell) =
  hard_cell left && hard_cell right && polarity left <> polarity right
  && let left_tokens = semantic_tokens left.text in
     let right_tokens = semantic_tokens right.text in
     let shared = intersection left_tokens right_tokens in
     List.length shared >= 2 && overlap_coefficient left_tokens right_tokens >= 0.75

let conflicts (cells : spec_cell list) =
  let rec outer acc = function
    | [] -> List.rev acc
    | left :: rest ->
        let acc = List.fold_left (fun acc right ->
          if likely_conflict left right then (left.id, right.id) :: acc else acc) acc rest in
        outer acc rest
  in outer [] cells

let capability_set workspace =
  Centl_sci_capabilities.builtins
  @ Centl_sci_capabilities.local_extension_capabilities workspace
  @ Centl_sci_capabilities.local_package_capabilities workspace

let capability_matches workspace request =
  let request_words = Centl_sci_capabilities.words request in
  capability_set workspace
  |> List.map (fun capability -> Centl_sci_capabilities.score request_words capability, capability)
  |> List.filter (fun (score, _) -> score > 0)
  |> List.sort (fun (left_score, left) (right_score, right) ->
       let by_score = compare right_score left_score in
       if by_score <> 0 then by_score else String.compare left.name right.name)
  |> List.map snd

let is_alias_request text =
  let text = lower text in
  List.exists (fun token -> contains token text) [ "alias"; "wrapper"; "shortcut"; "synonym"; "rename" ]

let cell_is_conflicting conflict_pairs id =
  List.exists (fun (left, right) -> left = id || right = id) conflict_pairs

let gap_for_cell workspace conflict_pairs (cell : spec_cell) =
  let kind = String.uppercase_ascii cell.kind in
  if kind = "QUESTION" then
    Some { cell_id = cell.id; status = Ambiguous; capability_matches = [];
           reason = "the source document contains an unresolved question" }
  else if kind <> "DIRECTIVE" && kind <> "INVARIANT" then None
  else if cell_is_conflicting conflict_pairs cell.id then
    Some { cell_id = cell.id; status = Conflicting; capability_matches = [];
           reason = "a conservatively matched hard requirement has opposite polarity" }
  else
    let matches = capability_matches workspace cell.text in
    let match_names = List.map (fun capability -> capability.Centl_sci_capabilities.name) matches in
    let plan = Centl_sci_build_plan.plan cell.text in
    let status, reason = match plan.layer with
      | Centl_sci_build_plan.Core_patch -> Core_change_required,
          "the existing BUILD planner identifies this objective as a trusted/core implementation change"
      | _ when is_alias_request cell.text && matches <> [] -> Alias_or_wrapper,
          "existing capabilities appear reusable; the requested semantic delta is primarily naming or wrapping"
      | _ when matches <> [] -> Composable,
          "one or more existing capabilities overlap the objective; MIRAGE must attempt composition before synthesis"
      | _ -> Extension_required,
          "no existing capability matched strongly enough to justify treating the objective as already available"
    in Some { cell_id = cell.id; status; capability_matches = match_names; reason }

let nearest_objective (cells : spec_cell list) before_id =
  cells |> List.filter (fun cell -> cell.id < before_id && match String.uppercase_ascii cell.kind with
    | "DIRECTIVE" | "INVARIANT" -> true | _ -> false) |> List.rev |> List.hd_opt

let cell_edges (cells : spec_cell list) =
  cells |> List.filter_map (fun cell -> match String.uppercase_ascii cell.kind with
    | "ACCEPTANCE" | "EXAMPLE" -> Option.map (fun objective ->
        { source = cell_node_id cell.id; target = cell_node_id objective.id; kind = Refines })
        (nearest_objective cells cell.id)
    | "NON_GOAL" -> Option.map (fun objective ->
        { source = cell_node_id cell.id; target = cell_node_id objective.id; kind = Constrains })
        (nearest_objective cells cell.id)
    | _ -> None)

let conflict_edges pairs = List.map (fun (left, right) ->
  { source = cell_node_id left; target = cell_node_id right; kind = Conflicts_with }) pairs

let capability_edges workspace (cells : spec_cell list) =
  cells |> List.filter (fun cell -> match String.uppercase_ascii cell.kind with
    | "DIRECTIVE" | "INVARIANT" -> true | _ -> false)
  |> List.concat_map (fun cell -> capability_matches workspace cell.text |> List.map (fun capability ->
       { source = cell_node_id cell.id; target = capability_node_id capability.name;
         kind = Candidate_satisfied_by }))

let cell_nodes (cells : spec_cell list) = List.map (fun cell ->
  { id = cell_node_id cell.id; kind = cell_node_kind cell.kind; label = cell.text; source_cell = Some cell.id }) cells

let capability_nodes workspace (cells : spec_cell list) =
  cells |> List.concat_map (fun cell -> capability_matches workspace cell.text)
  |> List.sort_uniq (fun left right -> String.compare left.Centl_sci_capabilities.name right.name)
  |> List.map (fun capability -> { id = capability_node_id capability.name; kind = Capability;
       label = Centl_sci_capabilities.render capability; source_cell = None })

let build workspace (cells : spec_cell list) =
  let conflicts = conflicts cells in
  let gaps = List.filter_map (gap_for_cell workspace conflicts) cells in
  let nodes = cell_nodes cells @ capability_nodes workspace cells in
  let edges = cell_edges cells @ conflict_edges conflicts @ capability_edges workspace cells in
  { nodes; edges; gaps; conflicts }

let node_to_json (node : node) = `Assoc [ ("id", `String node.id);
  ("kind", `String (node_kind_text node.kind)); ("label", `String node.label);
  ("source_cell", match node.source_cell with None -> `Null | Some id -> `Int id) ]
let edge_to_json (edge : edge) = `Assoc [ ("source", `String edge.source); ("target", `String edge.target);
  ("kind", `String (edge_kind_text edge.kind)) ]
let gap_to_json (gap : gap) = `Assoc [ ("cell_id", `Int gap.cell_id); ("status", `String (gap_status_text gap.status));
  ("capability_matches", `List (List.map (fun value -> `String value) gap.capability_matches)); ("reason", `String gap.reason) ]

let to_json (graph : graph) = `Assoc [ ("schema_version", `Int 1); ("system", `String "CENTL-MIRAGE");
  ("graph_kind", `String "goal_and_capability_gap_graph"); ("nodes", `List (List.map node_to_json graph.nodes));
  ("edges", `List (List.map edge_to_json graph.edges)); ("gaps", `List (List.map gap_to_json graph.gaps));
  ("conflicts", `List (List.map (fun (left, right) -> `List [ `Int left; `Int right ]) graph.conflicts)) ]

let read_spec path = try Ok (Yojson.Safe.from_file path) with
  | Sys_error message -> Error message
  | Yojson.Json_error message -> Error ("invalid MIRAGE specification IR: " ^ message)
let output_path spec_path = if String.ends_with ~suffix:".spec.json" spec_path then
  String.sub spec_path 0 (String.length spec_path - String.length ".spec.json") ^ ".goals.json"
  else spec_path ^ ".goals.json"

let analyze workspace spec_path = match read_spec spec_path with
  | Error _ as error -> error
  | Ok json -> begin match parse_cells json with
      | Error _ as error -> error
      | Ok cells -> let graph = build workspace cells in let path = output_path spec_path in
          begin try Centl_sci_workspace.atomic_write_json path (to_json graph); Ok (path, graph)
          with Sys_error message | Unix.Unix_error (_, _, message) -> Error message end
    end

let render_gap (gap : gap) =
  let matches = match gap.capability_matches with [] -> "none" | values -> String.concat ", " values in
  Printf.sprintf "cell %d: %s — matches: %s — %s" gap.cell_id (gap_status_text gap.status) matches gap.reason

let render (graph : graph) =
  let lines = [ "CENTL-MIRAGE goal graph"; "nodes: " ^ string_of_int (List.length graph.nodes);
    "edges: " ^ string_of_int (List.length graph.edges); "conflicts: " ^ string_of_int (List.length graph.conflicts); "gaps:" ]
    @ match graph.gaps with [] -> [ "  none" ] | values -> List.map (fun gap -> "  " ^ render_gap gap) values in
  String.concat "\n" lines
