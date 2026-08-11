type state = Materialized_source | Declarative_reuse | Blocked

type item = {
  candidate_id : string;
  transaction_fingerprint : string;
  strategy : string;
  state : state;
  source : string option;
  source_sha256 : string option;
  parser_validated : bool;
  rationale : string;
  materialization_fingerprint : string;
}

type report = {
  items : item list;
  blocked_cells : int list;
}

let state_text = function
  | Materialized_source -> "materialized_source"
  | Declarative_reuse -> "declarative_reuse"
  | Blocked -> "blocked"

let generated_source = function
  | Centl_sci_codegen.Generated (Centl_sci_codegen.Function { source; _ }) -> Some source
  | Centl_sci_codegen.Generated (Centl_sci_codegen.Value { source; _ }) -> Some source
  | Centl_sci_codegen.Not_generated | Centl_sci_codegen.Needs_clarification _ -> None

let materialization_identity_material ~candidate_id ~transaction_fingerprint ~strategy
    ~state ~source_sha256 ~parser_validated ~rationale =
  `Assoc
    [
      ("identity_schema_version", `Int 1);
      ("candidate_id", `String candidate_id);
      ("transaction_fingerprint", `String transaction_fingerprint);
      ("strategy", `String strategy);
      ("state", `String (state_text state));
      ("source_sha256", match source_sha256 with None -> `Null | Some value -> `String value);
      ("parser_validated", `Bool parser_validated);
      ("rationale", `String rationale);
    ]
  |> Yojson.Safe.to_string

let make_item candidate state source parser_validated rationale =
  let strategy = Centl_sci_mirage_candidate.strategy_text candidate.Centl_sci_mirage_candidate.strategy in
  let source_sha256 = Option.map Centl_sha256.hex_string source in
  let materialization_fingerprint =
    materialization_identity_material ~candidate_id:candidate.id
      ~transaction_fingerprint:candidate.transaction_fingerprint ~strategy ~state
      ~source_sha256 ~parser_validated ~rationale
    |> Centl_sha256.hex_string
  in
  {
    candidate_id = candidate.id;
    transaction_fingerprint = candidate.transaction_fingerprint;
    strategy;
    state;
    source;
    source_sha256;
    parser_validated;
    rationale;
    materialization_fingerprint;
  }

let materialize_generated candidate =
  match Centl_sci_codegen.generate candidate.Centl_sci_mirage_candidate.source_requirement with
  | Centl_sci_codegen.Generated change ->
      begin match generated_source (Centl_sci_codegen.Generated change) with
      | None ->
          make_item candidate Blocked None false
            "the deterministic SCi generator returned no materializable CENTL source"
      | Some source ->
          begin match Centl_parser.parse_statement_located source with
          | Ok _ ->
              make_item candidate Materialized_source (Some source) true
                "deterministic SCi code generation produced CENTL source and the authoritative parser accepted it; the source is staged only and has not been activated"
          | Error error ->
              make_item candidate Blocked (Some source) false
                (Printf.sprintf
                   "generated CENTL source failed authoritative parsing at byte %d: %s"
                   error.position error.message)
          end
      end
  | Centl_sci_codegen.Needs_clarification message ->
      make_item candidate Blocked None false
        ("deterministic materialization requires clarification: " ^ message)
  | Centl_sci_codegen.Not_generated ->
      make_item candidate Blocked None false
        "the existing deterministic SCi generator cannot lower this requirement without guessing"

let materialize_candidate candidate =
  match candidate.Centl_sci_mirage_candidate.strategy with
  | Centl_sci_mirage_candidate.Compose_existing ->
      if candidate.capability_inputs = [] then
        make_item candidate Blocked None false
          "composition was selected but no existing capability inputs are available"
      else
        make_item candidate Declarative_reuse None false
          "the candidate is a non-mutating composition of already identified capabilities; no new source is required at this stage"
  | Centl_sci_mirage_candidate.Alias_or_wrapper
  | Centl_sci_mirage_candidate.Downstream_extension -> materialize_generated candidate
  | Centl_sci_mirage_candidate.Isolated_core_patch ->
      make_item candidate Blocked None false
        "MIRAGE does not synthesize or apply verified-core patches from an underspecified requirement; an isolated core candidate needs an explicit implementation before core validation can begin"

let build (candidates : Centl_sci_mirage_candidate.report) =
  {
    items = List.map materialize_candidate candidates.candidates;
    blocked_cells = candidates.blocked_cells;
  }

let item_to_json item =
  `Assoc
    [
      ("candidate_id", `String item.candidate_id);
      ("transaction_fingerprint", `String item.transaction_fingerprint);
      ("strategy", `String item.strategy);
      ("state", `String (state_text item.state));
      ("source", match item.source with None -> `Null | Some value -> `String value);
      ("source_sha256", match item.source_sha256 with None -> `Null | Some value -> `String value);
      ("parser_validated", `Bool item.parser_validated);
      ("rationale", `String item.rationale);
      ("materialization_fingerprint_algorithm", `String "sha256");
      ("materialization_fingerprint", `String item.materialization_fingerprint);
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "candidate_materialization");
      ("blocked_cells", `List (List.map (fun id -> `Int id) report.blocked_cells));
      ("workspace_mutated", `Bool false);
      ("candidate_activated", `Bool false);
      ("assurance_promoted", `Bool false);
      ("network_required", `Bool false);
      ( "materialization_semantics",
        `String
          "materialization may stage deterministic CENTL source or a declarative reuse plan; parser acceptance establishes syntax only and does not establish mathematical correctness, regression success, activation safety, or verified-core assurance" );
      ("items", `List (List.map item_to_json report.items));
    ]

let output_path candidates_path =
  if String.ends_with ~suffix:".candidates.json" candidates_path then
    String.sub candidates_path 0
      (String.length candidates_path - String.length ".candidates.json")
    ^ ".materialization.json"
  else candidates_path ^ ".materialization.json"

let construct candidates_path candidates =
  let report = build candidates in
  let path = output_path candidates_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  let materialized =
    List.fold_left
      (fun total item -> if item.state = Materialized_source then total + 1 else total)
      0 report.items
  in
  let declarative =
    List.fold_left
      (fun total item -> if item.state = Declarative_reuse then total + 1 else total)
      0 report.items
  in
  let blocked =
    List.fold_left
      (fun total item -> if item.state = Blocked then total + 1 else total)
      0 report.items
  in
  String.concat "\n"
    [
      "CENTL-MIRAGE candidate materialization";
      "materialized CENTL source candidates: " ^ string_of_int materialized;
      "declarative reuse candidates: " ^ string_of_int declarative;
      "materialization-blocked candidates: " ^ string_of_int blocked;
      "workspace mutated: no";
      "candidate activated: no";
      "assurance promoted: no";
    ]
