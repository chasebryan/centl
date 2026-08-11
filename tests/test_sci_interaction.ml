let test_unicode_and_polite_recovery () =
  let normalized =
    Centl_sci_interaction.normalize Centl_sci_interaction.Math
      "Could you please INTERGRATE x² with respect to x?"
  in
  Alcotest.(check string)
    "unicode/typo/polite recovery" "integrate x^2 with respect to x?"
    (String.lowercase_ascii normalized)

let test_root_canonicalization () =
  let normalized =
    Centl_sci_interaction.normalize Centl_sci_interaction.Math
      "Find the roots of x^2 - 5*x + 6"
  in
  Alcotest.(check string)
    "roots become solve-zero request" "solve x^2 - 5*x + 6 equals zero"
    normalized

let test_how_many_conversion () =
  let normalized =
    Centl_sci_interaction.normalize Centl_sci_interaction.Phys
      "How many meters are exactly 2.5 kilometers?"
  in
  Alcotest.(check string)
    "question conversion canonical form" "convert 2.5 kilometers to meters"
    normalized;
  match Centl_sci_fastpath.interpret normalized with
  | Some (Centl_sci_ir.Unit_conversion data) ->
      Alcotest.(check string) "value" "2.5" data.value;
      Alcotest.(check string) "source" "km" data.from_unit;
      Alcotest.(check string) "target" "m" data.to_unit
  | _ ->
      Alcotest.fail "canonical how-many conversion did not reach unit fast path"

let test_how_many_are_in_conversion () =
  let normalized =
    Centl_sci_interaction.normalize Centl_sci_interaction.Phys
      "How many seconds are in 3 minutes."
  in
  Alcotest.(check string)
    "are-in conversion canonical form" "convert 3 minutes to seconds" normalized

let test_build_completion_surface () =
  let completions =
    Centl_sci_interaction.completion_candidates Centl_sci_interaction.Build
  in
  List.iter
    (fun candidate ->
      Alcotest.(check bool)
        (candidate ^ " completion")
        true
        (List.mem candidate completions))
    [
      "assurance";
      "audit";
      "capabilities";
      "export";
      "import";
      "package";
      "revisions";
      "validate";
    ]

let test_physics_completion_surface () =
  let completions =
    Centl_sci_interaction.completion_candidates Centl_sci_interaction.Phys
  in
  List.iter
    (fun candidate ->
      Alcotest.(check bool)
        (candidate ^ " completion")
        true
        (List.mem candidate completions))
    [ "constant"; "k_B"; "N_A"; "g0"; "simulate" ]

let capability_names query =
  Centl_sci_capabilities.search query
  |> List.map (fun capability -> capability.name)

let test_caramels_capability_discovery () =
  Alcotest.(check bool)
    "import reuses portability" true
    (List.mem "workspace portability"
       (capability_names "import workspace bundle"));
  Alcotest.(check bool)
    "audit reuses workspace audit" true
    (List.mem "workspace audit" (capability_names "audit workspace"));
  Alcotest.(check bool)
    "dependency graph is discoverable" true
    (List.mem "extension dependency graph"
       (capability_names "show extension dependency graph"));
  Alcotest.(check bool)
    "assurance explanation is discoverable" true
    (List.mem "assurance explanation" (capability_names "explain assurance"));
  Alcotest.(check bool)
    "revision history is discoverable" true
    (List.mem "workspace revision history"
       (capability_names "show revision history"));
  Alcotest.(check bool)
    "function creation reuses English-to-CENTL" true
    (List.mem "English-to-CENTL extension"
       (capability_names "create function for a local extension"));
  Alcotest.(check bool)
    "approximation reuses verified approximation" true
    (List.mem "approx" (capability_names "approximate to significant digits"))

let () =
  Alcotest.run "CENTL-SCi Caramels interaction"
    [
      ( "normalization",
        [
          Alcotest.test_case "unicode/polite recovery" `Quick
            test_unicode_and_polite_recovery;
          Alcotest.test_case "root canonicalization" `Quick
            test_root_canonicalization;
          Alcotest.test_case "how-many conversion" `Quick
            test_how_many_conversion;
          Alcotest.test_case "how-many are-in conversion" `Quick
            test_how_many_are_in_conversion;
        ] );
      ( "completion",
        [
          Alcotest.test_case "BUILD surface" `Quick
            test_build_completion_surface;
          Alcotest.test_case "physics surface" `Quick
            test_physics_completion_surface;
        ] );
      ( "capabilities",
        [
          Alcotest.test_case "Caramels runtime discovery" `Quick
            test_caramels_capability_discovery;
        ] );
    ]
