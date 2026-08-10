let layer_text request =
  Centl_sci_build_plan.plan request |> fun plan ->
  Centl_sci_build_plan.layer_text plan.layer

let test_native_centl_classification () =
  Alcotest.(check string) "native CENTL"
    "native CENTL module/package"
    (layer_text "add a local function for orbital_period")

let test_external_adapter_classification () =
  Alcotest.(check string) "external adapter"
    "controlled external adapter"
    (layer_text "add a Python telescope adapter for astropy")

let test_native_extension_classification () =
  Alcotest.(check string) "native extension"
    "generated native extension"
    (layer_text "add a Rust sparse matrix backend")

let test_core_patch_classification () =
  Alcotest.(check string) "core patch"
    "downstream CENTL core patch"
    (layer_text "modify the CENTL parser to support a new operator")

let test_upstream_classification () =
  Alcotest.(check string) "upstream contribution"
    "upstream contribution preparation"
    (layer_text "prepare this extension for upstream contribution")

let test_assurance_catalog_render () =
  let output =
    Centl_sci_build_plan.plan "assurance levels"
    |> Centl_sci_build_plan.render
  in
  Alcotest.(check bool) "assurance catalog visible" true
    (Option.is_some
       (Centl_sci_interaction.find_substring
          ~needle:"not a single numeric ranking" output))

let test_capability_reuse_is_in_plan () =
  let plan = Centl_sci_build_plan.plan "add integration support" in
  Alcotest.(check bool) "existing integration capability appears" true
    (List.exists
       (fun value ->
         Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"integrate" value))
       plan.reusable_capabilities)

let () =
  Alcotest.run "CENTL-SCi Caramels BUILD planning"
    [
      ( "classification",
        [
          Alcotest.test_case "native CENTL" `Quick
            test_native_centl_classification;
          Alcotest.test_case "external adapter" `Quick
            test_external_adapter_classification;
          Alcotest.test_case "native extension" `Quick
            test_native_extension_classification;
          Alcotest.test_case "core patch" `Quick
            test_core_patch_classification;
          Alcotest.test_case "upstream" `Quick
            test_upstream_classification;
        ] );
      ( "reuse and trust",
        [
          Alcotest.test_case "assurance catalog" `Quick
            test_assurance_catalog_render;
          Alcotest.test_case "reuse before invention" `Quick
            test_capability_reuse_is_in_plan;
        ] );
    ]
