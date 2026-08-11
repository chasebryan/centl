let contains needle text =
  Option.is_some (Centl_sci_interaction.find_substring ~needle text)

let test_catalog_is_not_numeric_ranking () =
  let rendered = Centl_sci_assurance.render_catalog () in
  Alcotest.(check bool)
    "locally tested documented" true
    (contains "locally_tested_extension" rendered);
  Alcotest.(check bool)
    "external backend documented" true
    (contains "external_backend" rendered);
  Alcotest.(check bool)
    "generated documented" true
    (contains "unverified_generated_extension" rendered);
  Alcotest.(check bool)
    "not a numeric ranking" true
    (contains "not a single numeric ranking" rendered)

let test_local_manifest_does_not_claim_core () =
  let manifest : Centl_sci_extensions.manifest =
    {
      name = "tau";
      kind = "native_centl";
      enabled = true;
      assurance = "locally_tested_extension";
      source = "modules/tau.centl";
      summary = "local test";
      provenance = "generated from a downstream BUILD request";
      dependencies = [];
      tests = [];
      workspace_revision = 3;
      recorded_at_unix = None;
    }
  in
  let rendered = Centl_sci_assurance.render_manifest manifest in
  Alcotest.(check bool)
    "provenance visible" true
    (contains "generated from a downstream BUILD request" rendered);
  Alcotest.(check bool)
    "verified core explicitly excluded" true
    (contains "verified-core assurance" rendered);
  Alcotest.(check bool)
    "inspection does not promote" true
    (contains "does not change the extension or promote its assurance" rendered)

let test_unknown_assurance_is_preserved_without_inference () =
  let manifest : Centl_sci_extensions.manifest =
    {
      name = "legacy";
      kind = "native_centl";
      enabled = false;
      assurance = "legacy_custom_label";
      source = "modules/legacy.centl";
      summary = "legacy";
      provenance = "imported legacy manifest";
      dependencies = [];
      tests = [];
      workspace_revision = 1;
      recorded_at_unix = None;
    }
  in
  let rendered = Centl_sci_assurance.render_manifest manifest in
  Alcotest.(check bool)
    "unknown label preserved" true
    (contains "legacy_custom_label" rendered);
  Alcotest.(check bool)
    "no inferred guarantee" true
    (contains "does not infer additional guarantees" rendered)

let () =
  Alcotest.run "CENTL-SCi Caramels assurance"
    [
      ( "explanation",
        [
          Alcotest.test_case "catalog semantics" `Quick
            test_catalog_is_not_numeric_ranking;
          Alcotest.test_case "local manifest boundary" `Quick
            test_local_manifest_does_not_claim_core;
          Alcotest.test_case "unknown label" `Quick
            test_unknown_assurance_is_preserved_without_inference;
        ] );
    ]
