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
  session_revision : int;
  definitions : Yojson.Safe.t;
  resolved_claim : Yojson.Safe.t;
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

let resolved_claim_of_verification (verification : Centl_verify.verification) =
  let side fallback = function
    | None -> fallback
    | Some value -> value.Centl_verify.text
  in
  let claim = verification.claim in
  Centl_verify.json_of_claim
    {
      claim with
      left = side claim.left verification.evidence.left;
      right = side claim.right verification.evidence.right;
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
    ?(limits = Centl_engine.default_evaluation_limits) session verification =
  let dependencies = Centl_verify.verification_dependencies verification in
  {
    schema = schema_version;
    kind = receipt_kind;
    verification;
    session_revision = Centl_engine.session_revision session;
    definitions = Centl_engine.json_of_session_dependencies session dependencies;
    resolved_claim = resolved_claim_of_verification verification;
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
      ("resolved_claim", receipt.resolved_claim);
      ( "session",
        `Assoc
          [
            ("revision", `Int receipt.session_revision);
            ("definitions", receipt.definitions);
          ] );
      ("limits", `Assoc receipt.limits);
      ("build", json_of_build receipt.build);
      ("protocol_version", `Int 1);
      ( "producer",
        `Assoc
          [
            ("name", `String "centl"); ("version", `String Centl_version.value);
          ] );
    ]

let maximum_receipt_bytes = 1_048_576

let serialize_bounded json =
  let text = Yojson.Safe.pretty_to_string json ^ "\n" in
  if String.length text > maximum_receipt_bytes then
    Error
      (Printf.sprintf "receipt exceeds the %d-byte metadata limit"
         maximum_receipt_bytes)
  else Ok text

let write_json_file path json =
  match serialize_bounded json with
  | Error _ as error -> error
  | Ok text ->
      begin try
        let directory = Filename.dirname path in
        let temporary =
          Filename.temp_file ~temp_dir:directory ".centl-receipt-" ".tmp"
        in
        let channel = open_out_bin temporary in
        begin try
          Fun.protect
            ~finally:(fun () -> close_out channel)
            (fun () -> output_string channel text);
          Unix.rename temporary path;
          Ok ()
        with exn ->
          begin try Sys.remove temporary with Sys_error _ -> ()
          end;
          Error (Printexc.to_string exn)
        end
      with exn -> Error (Printexc.to_string exn)
      end

let write_file path receipt = write_json_file path (json_of_receipt receipt)

let json_of_collection ~path receipts =
  `Assoc
    [
      ("schema", `Int schema_version);
      ("kind", `String "centl_check_receipt");
      ("path", `String path);
      ("receipts", `List (List.map json_of_receipt receipts));
      ( "producer",
        `Assoc
          [
            ("name", `String "centl"); ("version", `String Centl_version.value);
          ] );
    ]

let write_collection path ~contract_path receipts =
  write_json_file path (json_of_collection ~path:contract_path receipts)

let text_of_receipt (receipt : receipt) =
  let verification = receipt.verification in
  Printf.sprintf "receipt schema=%d verdict=%s scope=%s method=%s %s"
    receipt.schema
    (Centl_verify.verdict_name verification.verdict)
    verification.scope verification.method_
    (text_of_build receipt.build)
