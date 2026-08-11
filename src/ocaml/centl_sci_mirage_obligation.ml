type kind =
  | Candidate_parses
  | Mandatory_regression
  | Provenance_complete
  | Rollback_available
  | Reuse_attempted
  | Trust_boundary_explicit
  | Core_validation
  | Clarification_required
  | Conflict_resolution_required
  | Policy_boundary

type obligation = {
  id : string;
  cell_id : int;
  kind : kind;
  mandatory : bool;
  blocks_candidate : bool;
  claim : string;
}

type report = { obligations : obligation list; blocked_cells : int list }

let kind_text = function
  | Candidate_parses -> "candidate_parses"
  | Mandatory_regression -> "mandatory_regression"
  | Provenance_complete -> "provenance_complete"
  | Rollback_available -> "rollback_available"
  | Reuse_attempted -> "reuse_attempted"
  | Trust_boundary_explicit -> "trust_boundary_explicit"
  | Core_validation -> "core_validation"
  | Clarification_required -> "clarification_required"
  | Conflict_resolution_required -> "conflict_resolution_required"
  | Policy_boundary -> "policy_boundary"

let make ~cell_id ~kind ~blocks_candidate claim =
  {
    id = Printf.sprintf "cell:%d:%s" cell_id (kind_text kind);
    cell_id;
    kind;
    mandatory = true;
    blocks_candidate;
    claim;
  }

let common_candidate_obligations cell_id =
  [
    make ~cell_id ~kind:Candidate_parses ~blocks_candidate:false
      "the candidate must pass the authoritative parser/build validation for \
       its implementation layer";
    make ~cell_id ~kind:Mandatory_regression ~blocks_candidate:false
      "the candidate must pass the relevant deterministic regression gates \
       before activation";
    make ~cell_id ~kind:Provenance_complete ~blocks_candidate:false
      "the candidate must retain attribution to the source requirement and \
       resulting workspace revision";
    make ~cell_id ~kind:Rollback_available ~blocks_candidate:false
      "a reversible workspace state must exist before the candidate can be \
       activated";
  ]

let obligations_for_gap (gap : Centl_sci_mirage_goal.gap) =
  let cell_id = gap.cell_id in
  match gap.status with
  | Centl_sci_mirage_goal.Satisfied -> []
  | Centl_sci_mirage_goal.Composable ->
      common_candidate_obligations cell_id
      @ [
          make ~cell_id ~kind:Reuse_attempted ~blocks_candidate:false
            "MIRAGE must attempt composition from the matched existing \
             capabilities before synthesizing a new implementation";
        ]
  | Centl_sci_mirage_goal.Alias_or_wrapper ->
      common_candidate_obligations cell_id
      @ [
          make ~cell_id ~kind:Reuse_attempted ~blocks_candidate:false
            "the candidate must preserve the existing capability semantics and \
             limit the delta to the requested alias or wrapper behavior";
        ]
  | Centl_sci_mirage_goal.Extension_required ->
      common_candidate_obligations cell_id
      @ [
          make ~cell_id ~kind:Trust_boundary_explicit ~blocks_candidate:false
            "the new downstream extension must carry an explicit local \
             assurance boundary and must not inherit verified-core assurance";
        ]
  | Centl_sci_mirage_goal.Core_change_required ->
      common_candidate_obligations cell_id
      @ [
          make ~cell_id ~kind:Trust_boundary_explicit ~blocks_candidate:false
            "the core-change candidate must identify any changed trust \
             boundary without promoting generated code to verified-core \
             assurance";
          make ~cell_id ~kind:Core_validation ~blocks_candidate:false
            "the isolated core candidate must pass the full relevant core \
             verification and regression gates before admission";
        ]
  | Centl_sci_mirage_goal.Ambiguous ->
      [
        make ~cell_id ~kind:Clarification_required ~blocks_candidate:true
          "candidate synthesis is blocked until the unresolved source question \
           is answered without inventing missing intent";
      ]
  | Centl_sci_mirage_goal.Conflicting ->
      [
        make ~cell_id ~kind:Conflict_resolution_required ~blocks_candidate:true
          "candidate synthesis is blocked until the conflicting hard \
           requirements are explicitly resolved";
      ]
  | Centl_sci_mirage_goal.Unsupported_by_policy ->
      [
        make ~cell_id ~kind:Policy_boundary ~blocks_candidate:true
          "candidate synthesis is blocked by an explicit policy boundary and \
           cannot be bypassed by the generator";
      ]

let build (graph : Centl_sci_mirage_goal.graph) =
  let obligations = List.concat_map obligations_for_gap graph.gaps in
  let blocked_cells =
    obligations
    |> List.filter (fun obligation -> obligation.blocks_candidate)
    |> List.map (fun obligation -> obligation.cell_id)
    |> List.sort_uniq compare
  in
  { obligations; blocked_cells }

let obligation_to_json obligation =
  `Assoc
    [
      ("id", `String obligation.id);
      ("cell_id", `Int obligation.cell_id);
      ("kind", `String (kind_text obligation.kind));
      ("mandatory", `Bool obligation.mandatory);
      ("blocks_candidate", `Bool obligation.blocks_candidate);
      ("claim", `String obligation.claim);
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "evidence_obligations");
      ("obligation_count", `Int (List.length report.obligations));
      ("candidate_blocked", `Bool (report.blocked_cells <> []));
      ( "blocked_cells",
        `List (List.map (fun id -> `Int id) report.blocked_cells) );
      ("obligations", `List (List.map obligation_to_json report.obligations));
    ]

let output_path goal_path =
  if String.ends_with ~suffix:".goals.json" goal_path then
    String.sub goal_path 0
      (String.length goal_path - String.length ".goals.json")
    ^ ".obligations.json"
  else goal_path ^ ".obligations.json"

let construct goal_path graph =
  let report = build graph in
  let path = output_path goal_path in
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
      "CENTL-MIRAGE evidence obligations";
      "obligations: " ^ string_of_int (List.length report.obligations);
      "candidate-blocked cells: " ^ blocked;
      "assurance promoted: no";
    ]
