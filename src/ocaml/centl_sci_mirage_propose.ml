type kind = Program | Name | Test

type proposal = {
  cell_id : int;
  kind : kind;
  text : string;
  authority : string;
}

type report = { proposals : proposal list }

let kind_text = function
  | Program -> "program"
  | Name -> "name"
  | Test -> "test"

let authority =
  "deterministic extraction from the source cell; not model authority and not \
   mathematical assurance"

let proposal_of_cell (cell : Centl_sci_mirage.cell) =
  match Centl_sci_codegen.generate cell.text with
  | Centl_sci_codegen.Generated (Centl_sci_codegen.Function { source; _ })
  | Centl_sci_codegen.Generated (Centl_sci_codegen.Value { source; _ }) ->
      Some { cell_id = cell.id; kind = Program; text = source; authority }
  | _ -> None

let proposals_of_spec_cells cells =
  cells
  |> List.filter_map (fun (cell : Centl_sci_mirage_goal.spec_cell) ->
      let local : Centl_sci_mirage.cell =
        {
          id = cell.id;
          kind = Centl_sci_mirage.Context;
          text = cell.text;
          start_line = cell.start_line;
          end_line = cell.end_line;
        }
      in
      proposal_of_cell local)

let build (graph : Centl_sci_mirage_goal.graph) =
  let cells =
    graph.nodes
    |> List.filter_map (fun (node : Centl_sci_mirage_goal.node) ->
        match node.source_cell with
        | None -> None
        | Some id ->
            Some
              {
                Centl_sci_mirage_goal.id;
                kind = Centl_sci_mirage_goal.node_kind_text node.kind;
                text = node.label;
                start_line = 0;
                end_line = 0;
              })
  in
  { proposals = proposals_of_spec_cells cells }

let proposal_to_json proposal =
  `Assoc
    [
      ("cell_id", `Int proposal.cell_id);
      ("kind", `String (kind_text proposal.kind));
      ("text", `String proposal.text);
      ("authority", `String proposal.authority);
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "deterministic_proposals");
      ("proposal_count", `Int (List.length report.proposals));
      ( "proposal_semantics",
        `String
          "proposals are deterministic extractions; they never bypass the \
           parser, never confer truth, and never promote assurance" );
      ("proposals", `List (List.map proposal_to_json report.proposals));
    ]

let output_path spec_path =
  if String.ends_with ~suffix:".spec.json" spec_path then
    String.sub spec_path 0 (String.length spec_path - String.length ".spec.json")
    ^ ".proposals.json"
  else spec_path ^ ".proposals.json"

let construct spec_path graph =
  let report = build graph in
  let path = output_path spec_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  String.concat "\n"
    [
      "CENTL-MIRAGE deterministic proposals";
      "proposals: " ^ string_of_int (List.length report.proposals);
      "model authority: none";
    ]
