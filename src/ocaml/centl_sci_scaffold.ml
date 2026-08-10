type scaffold_kind = Python_adapter | Native_extension

let safe_name name =
  let name = String.trim name in
  Centl_sci_workspace.valid_extension_name name

let write_text_file path text =
  let temporary = path ^ ".tmp" in
  let channel =
    open_out_gen [ Open_wronly; Open_creat; Open_trunc; Open_text ] 0o600 temporary
  in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel text; flush channel);
  Unix.rename temporary path

let scaffold_root workspace =
  Filename.concat workspace.Centl_sci_workspace.generated "scaffolds"

let python_adapter_stub name target =
  String.concat "\n"
    [
      "#!/usr/bin/env python3";
      "\"\"\"Generated inactive CENTL-SCi adapter scaffold.";
      "";
      "This file is not trusted or enabled by generation alone.";
      "Implement the narrow contract, test it, then explicitly enable the extension.";
      "\"\"\"";
      "import json";
      "import sys";
      "";
      "ADAPTER_NAME = " ^ Printf.sprintf "%S" name;
      "TARGET = " ^ Printf.sprintf "%S" target;
      "";
      "def handle(request):";
      "    return {";
      "        \"ok\": False,";
      "        \"error\": {";
      "            \"code\": \"adapter_unimplemented\",";
      "            \"message\": f\"{ADAPTER_NAME} has not been implemented or validated\",";
      "        },";
      "    }";
      "";
      "for raw in sys.stdin:";
      "    raw = raw.strip()";
      "    if not raw:";
      "        continue";
      "    try:";
      "        request = json.loads(raw)";
      "        response = handle(request)";
      "    except Exception as exc:";
      "        response = {\"ok\": False, \"error\": {\"code\": \"adapter_error\", \"message\": str(exc)}}";
      "    print(json.dumps(response, separators=(\",\", \":\")), flush=True)";
      "";
    ]

let python_test_stub name =
  String.concat "\n"
    [
      "# Generated first-pass test placeholder for " ^ name;
      "# Replace with contract and adversarial tests before enabling the adapter.";
      "def test_adapter_is_not_silently_trusted():";
      "    assert True";
      "";
    ]

let native_stub name target =
  String.concat "\n"
    [
      "(* Generated inactive CENTL-SCi native extension scaffold.";
      "   Name: " ^ name;
      "   Target: " ^ target;
      "   This source is unverified generated code and is not linked automatically. *)";
      "";
      "type request = Yojson.Safe.t";
      "type response = Yojson.Safe.t";
      "";
      "let handle (_request : request) : response =";
      "  `Assoc";
      "    [";
      "      (\"ok\", `Bool false);";
      "      (\"error\", `Assoc [ (\"code\", `String \"extension_unimplemented\");";
      "                              (\"message\", `String \"generated native extension is not implemented or validated\") ]);";
      "    ]";
      "";
    ]

let create workspace ~kind ~name ~target =
  if not (safe_name name) then Error "invalid scaffold name"
  else
    try
      Centl_sci_workspace.ensure workspace;
      let root = Filename.concat (scaffold_root workspace) name in
      Centl_sci_workspace.ensure_directory root;
      let kind_text, assurance, summary, source_file, test_file =
        match kind with
        | Python_adapter ->
            write_text_file (Filename.concat root "adapter.py")
              (python_adapter_stub name target);
            write_text_file (Filename.concat root "test_adapter.py")
              (python_test_stub name);
            ( "python_adapter",
              Centl_sci_workspace.External_backend,
              "Controlled Python interoperability scaffold",
              "adapter.py",
              "test_adapter.py" )
        | Native_extension ->
            write_text_file (Filename.concat root "extension.ml")
              (native_stub name target);
            write_text_file (Filename.concat root "TESTING.md")
              "# Validation required\n\nAdd deterministic interface, negative, resource-limit, and trust-boundary tests before enabling this generated native extension.\n";
            ( "native_extension",
              Centl_sci_workspace.Unverified_generated,
              "Generated native extension scaffold",
              "extension.ml",
              "TESTING.md" )
      in
      let contract =
        `Assoc
          [
            ("schema_version", `Int 1);
            ("name", `String name);
            ("kind", `String kind_text);
            ("target", `String target);
            ("transport", `String "jsonl_stdio");
            ("activation", `String "explicit_after_validation");
            ("result_assurance", `String (Centl_sci_workspace.assurance_text assurance));
            ("source", `String source_file);
            ("test", `String test_file);
            ("network_access", `String "not_granted_by_scaffold");
            ("filesystem_access", `String "not_granted_by_scaffold");
          ]
      in
      write_text_file (Filename.concat root "scaffold.json")
        (Yojson.Safe.pretty_to_string contract ^ "\n");
      write_text_file (Filename.concat root "README.md")
        (String.concat "\n"
           [
             "# " ^ name;
             "";
             "Generated by CENTL-SCi v0.0.2-Caramels BUILD mode.";
             "";
             "Kind: " ^ kind_text;
             "Target: " ^ target;
             "Transport: JSONL over standard I/O";
             "";
             "This scaffold is intentionally inactive until its adapter/native boundary is implemented and validated.";
             "Generation grants no network or filesystem privileges and does not change verified CENTL core assurance.";
             "External/generated results must remain visibly distinguished from verified-core computation.";
             "";
           ]);
      begin match
        Centl_sci_workspace.write_manifest_detailed workspace ~name ~enabled:false
          ~assurance ~source:("generated/scaffolds/" ^ name ^ "/scaffold.json")
          ~summary ~kind:kind_text
          ~provenance:"generated by CENTL-SCi v0.0.2-Caramels BUILD scaffold"
          ~dependencies:[ target ]
          ~tests:[ "generated/scaffolds/" ^ name ^ "/" ^ test_file ]
      with
      | Error message -> Error message
      | Ok revision -> Ok (root, revision)
      end
    with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let prepare_upstream workspace =
  try
    Centl_sci_workspace.ensure workspace;
    let revision = Centl_sci_workspace.read_revision workspace in
    let path =
      Filename.concat workspace.generated
        (Printf.sprintf "upstream-contribution-r%d.md" revision)
    in
    let extension_lines =
      Centl_sci_extensions.list workspace
      |> List.map (fun item ->
             Printf.sprintf "- `%s` — enabled=%b — assurance=`%s` — source=`%s`"
               item.name item.enabled item.assurance item.source)
    in
    let body =
      String.concat "\n"
        ([
           "# CENTL downstream contribution preparation";
           "";
           "Generated by CENTL-SCi v0.0.2-Caramels.";
           "";
           Printf.sprintf "Workspace: `%s`" workspace.root;
           Printf.sprintf "Workspace revision: `%d`" revision;
           "";
           "## Local extensions";
           "";
         ]
        @ (if extension_lines = [] then [ "- None" ] else extension_lines)
        @ [
            "";
            "## Required human/upstream review";
            "";
            "- isolate the changes intended for publication";
            "- review assurance and trust-boundary claims";
            "- run the quality gates relevant to the touched implementation layers";
            "- update tests and documentation";
            "- prepare Git commits/PR only after explicit user choice";
            "";
          ])
    in
    write_text_file path body;
    Ok path
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message
