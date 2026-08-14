type composition = {
  cell_id : int;
  candidate_id : string;
  kind : string;
  expression : string;
  rationale : string;
}

type report = { compositions : composition list }

let strip_directive text =
  let prefixes =
    [
      "centl should ";
      "the system should ";
      "we need to ";
      "please ";
      "implement ";
      "add support for ";
      "support ";
    ]
  in
  let rec loop text = function
    | [] -> String.trim text
    | prefix :: rest -> (
        match Centl_sci_codegen.extract_after_prefix_ci prefix text with
        | Some value -> loop value []
        | None -> loop text rest)
  in
  loop text prefixes

let expression_of_ir = function
  | Centl_sci_ir.Exact_expression { expression; _ } ->
      Some ("exact_expression", expression)
  | Centl_sci_ir.Polynomial_equation { left; right; variable; _ } ->
      Some ("solve", Printf.sprintf "solve(%s = %s, %s)" left right variable)
  | Centl_sci_ir.Verification_claim { left; relation; right; _ } ->
      Some
        ( "verify",
          Printf.sprintf "verify --left %s --relation %s --right %s" left
            relation right )
  | _ -> None

let compose_text text =
  let candidates = [ String.trim text; strip_directive text ] in
  let rec loop = function
    | [] -> None
    | text :: rest when text = "" -> loop rest
    | text :: rest -> (
        match Centl_sci_fastpath.interpret text with
        | Some ir -> (
            match expression_of_ir ir with
            | Some value -> Some value
            | None -> loop rest)
        | None -> loop rest)
  in
  loop candidates

let composition_of_candidate (candidate : Centl_sci_mirage_candidate.candidate)
    =
  match compose_text candidate.source_requirement with
  | None -> None
  | Some (kind, expression) ->
      Some
        {
          cell_id = candidate.cell_id;
          candidate_id = candidate.id;
          kind;
          expression;
          rationale =
            "existing CENTL operations compose this requirement without a new \
             implementation";
        }

let build (candidates : Centl_sci_mirage_candidate.report) =
  {
    compositions =
      List.filter_map composition_of_candidate candidates.candidates;
  }

let composition_to_json composition =
  `Assoc
    [
      ("cell_id", `Int composition.cell_id);
      ("candidate_id", `String composition.candidate_id);
      ("kind", `String composition.kind);
      ("expression", `String composition.expression);
      ("rationale", `String composition.rationale);
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "native_ast_composition");
      ("composition_count", `Int (List.length report.compositions));
      ( "composition_semantics",
        `String
          "a composition is a reuse of existing CENTL operations; it is not a \
           new implementation and does not promote assurance" );
      ("compositions", `List (List.map composition_to_json report.compositions));
    ]

let output_path candidates_path =
  if String.ends_with ~suffix:".candidates.json" candidates_path then
    String.sub candidates_path 0
      (String.length candidates_path - String.length ".candidates.json")
    ^ ".compose.json"
  else candidates_path ^ ".compose.json"

let construct candidates_path candidates =
  let report = build candidates in
  let path = output_path candidates_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  String.concat "\n"
    [
      "CENTL-MIRAGE native AST composition";
      "composed requirements: "
      ^ string_of_int (List.length report.compositions);
      "new implementations invented: no";
    ]
