type scaffold_kind = Python_adapter | Native_extension

let kind_text = function
  | Python_adapter -> "python_adapter"
  | Native_extension -> "native_extension"

let assurance = function
  | Python_adapter -> "external_backend"
  | Native_extension -> "unverified_generated_extension"

let write_text_file path text =
  let channel = open_out_bin path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel text)

let scaffold workspace ~kind ~name ~target ~summary =
  if not (Centl_sci_workspace.valid_extension_name name) then
    Error "extension names may contain only letters, digits, '.', '-', and '_'"
  else
    let kind_text = kind_text kind in
    let assurance = assurance kind in
    let root = Filename.concat workspace.Centl_sci_workspace.generated ("scaffolds/" ^ name) in
    let source_file, test_file, source_text, test_text =
      match kind with
      | Python_adapter ->
          ( "adapter.py",
            "validate.py",
            String.concat "\n"
              [
                "#!/usr/bin/env python3";
                "\"\"\"Generated CENTL-SCi external adapter scaffold.";
                "";
                "Contract: JSONL over stdin/stdout. This file is intentionally inactive";
                "until the user implements and validates the named external boundary.";
                "\"\"\"";
                "";
                "import json";
                "import sys";
                "";
                "TARGET = " ^ Printf.sprintf "%S" target;
                "";
                "def main() -> int:";
                "    for line in sys.stdin:";
                "        request = json.loads(line)";
                "        response = {";
                "            \"status\": \"not_implemented\",";
                "            \"target\": TARGET,";
                "            \"request\": request,";
                "            \"assurance\": \"external_backend\",";
                "        }";
                "        print(json.dumps(response, separators=(\",\", \":\")), flush=True)";
                "    return 0";
                "";
                "if __name__ == \"__main__\":";
                "    raise SystemExit(main())";
                "";
              ],
            String.concat "\n"
              [
                "#!/usr/bin/env python3";
                "\"\"\"Structural validation placeholder for the generated adapter.\"\"\"";
                "";
                "from pathlib import Path";
                "";
                "root = Path(__file__).resolve().parent";
                "assert (root / \"adapter.py\").is_file()";
                "assert (root / \"scaffold.json\").is_file()";
                "print(\"adapter scaffold structure: ok\")";
                "";
              ] )
      | Native_extension ->
          ( "extension.c",
            "validate.sh",
            String.concat "\n"
              [
                "/* Generated CENTL-SCi native extension scaffold.";
                " * This is intentionally not wired into CENTL's verified/native loader.";
                " * Define and validate a stable ABI before activation.";
                " */";
                "#include <stddef.h>";
                "";
                "const char *centl_generated_extension_target(void) {";
                "  return " ^ Printf.sprintf "%S" target ^ ";";
                "}";
                "";
              ],
            String.concat "\n"
              [
                "#!/bin/sh";
                "set -eu";
                "test -f \"$(dirname \"$0\")/extension.c\"";
                "test -f \"$(dirname \"$0\")/scaffold.json\"";
                "printf '%s\\n' 'native extension scaffold structure: ok'";
                "";
              ] )
    in
    try
      Centl_sci_workspace.ensure workspace;
      Centl_sci_workspace.ensure_directory root;
      write_text_file (Filename.concat root source_file) source_text;
      write_text_file (Filename.concat root test_file) test_text;
      let contract =
        `Assoc
          [
            ("schema_version", `Int 1);
            ("centl_sci_version", `String "0.0.2-Caramels");
            ("name", `String name);
            ("kind", `String kind_text);
            ("target", `String target);
            ("summary", `String summary);
            ("source", `String source_file);
            ("test", `String test_file);
            ("transport", `String "jsonl_stdio");
            ("activation", `String "explicit_after_validation");
            ("assurance", `String assurance);
            ("verified_core_modified", `Bool false);
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
      |> List.map (fun (item : Centl_sci_extensions.manifest) ->
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