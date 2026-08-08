(* Bounded, versioned verification receipts for CENTL math contracts.
   Receipts wrap a verification result with producer/build metadata suitable
   for audit and CI.

   Build identity comes only from values stamped into Centl_build at compile
   time from the extracted F* core snapshot and optional source commit. *)

type build_identity = {
  semantic_version : string;
  commit : string option;
  generated_core_hash : string option;
}

type receipt = {
  schema : int;
  kind : string;
  verification : Centl_verify.verification;
  dependencies : string list;
  limits : (string * Yojson.Safe.t) list;
  build : build_identity;
}

let schema_version = 1
let receipt_kind = "centl_verification_receipt"

let default_build () =
  {
    semantic_version = Centl_version.value;
    commit = Centl_build.commit;
    generated_core_hash = Centl_build.generated_core_hash;
  }

let limits_fields (limits : Centl_engine.evaluation_limits) =
  [
    ("max_source_bytes", `Int limits.max_source_bytes);
    ("max_expression_nodes", `Int limits.max_expression_nodes);
    ("max_exact_bits", `Int limits.max_exact_bits);
    ("max_integer_iterations", `Int limits.max_integer_iterations);
    ("max_result_bytes", `Int limits.max_result_bytes);
    ("max_bindings", `Int limits.max_bindings);
    ("max_precision_digits", `Int limits.max_precision_digits);
    ("max_working_bits", `Int limits.max_working_bits);
  ]

let make ?(build = default_build ())
    ?(limits = Centl_engine.default_evaluation_limits) verification =
  {
    schema = schema_version;
    kind = receipt_kind;
    verification;
    dependencies = Centl_verify.verification_dependencies verification;
    limits = limits_fields limits;
    build;
  }

let json_of_build (build : build_identity) =
  let fields = [ ("semantic_version", `String build.semantic_version) ] in
  let fields =
    match build.commit with
    | None -> fields
    | Some commit -> fields @ [ ("commit", `String commit) ]
  in
  let fields =
    match build.generated_core_hash with
    | None -> fields
    | Some digest -> fields @ [ ("generated_core_hash", `String digest) ]
  in
  `Assoc fields

let text_of_build (build : build_identity) =
  let field label = function
    | None -> label ^ "=unknown"
    | Some value -> label ^ "=" ^ value
  in
  String.concat " "
    [
      "version=" ^ build.semantic_version;
      field "commit" build.commit;
      field "generated_core_hash" build.generated_core_hash;
    ]

let json_of_receipt (receipt : receipt) =
  `Assoc
    [
      ("schema", `Int receipt.schema);
      ("kind", `String receipt.kind);
      ("verification", Centl_verify.json_of_verification receipt.verification);
      ( "dependencies",
        `List (List.map (fun name -> `String name) receipt.dependencies) );
      ("limits", `Assoc receipt.limits);
      ("build", json_of_build receipt.build);
      ( "producer",
        `Assoc
          [
            ("name", `String "centl"); ("version", `String Centl_version.value);
          ] );
    ]

let write_json_file path json =
  let channel = open_out path in
  Fun.protect
    ~finally:(fun () -> close_out channel)
    (fun () ->
      Yojson.Safe.pretty_to_channel channel json;
      output_char channel '\n')

let write_file path receipt = write_json_file path (json_of_receipt receipt)

let text_of_receipt (receipt : receipt) =
  let verification = receipt.verification in
  Printf.sprintf "receipt schema=%d verdict=%s scope=%s method=%s %s"
    receipt.schema
    (Centl_verify.verdict_name verification.verdict)
    verification.scope verification.method_
    (text_of_build receipt.build)
