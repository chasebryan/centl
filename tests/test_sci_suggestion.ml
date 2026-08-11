let require label = function
  | Some value -> value
  | None -> Alcotest.fail ("missing suggestion: " ^ label)

let contains needle text =
  Option.is_some (Centl_sci_interaction.find_substring ~needle text)

let test_build_lexical_completion () =
  let input = "capab" in
  let suggestion =
    Centl_sci_suggestion.suggest ~mode:Centl_sci_interaction.Build input
      (String.length input)
    |> require "BUILD capabilities lexical completion"
  in
  Alcotest.(check bool)
    "lexical" true
    (suggestion.category = Centl_sci_suggestion.Lexical);
  Alcotest.(check bool) "safe to accept" true suggestion.safe_to_accept;
  Alcotest.(check string)
    "replacement" "capabilities" suggestion.replacement_text

let test_constant_structural_hint_is_not_committed () =
  let input = "constant" in
  let suggestion =
    Centl_sci_suggestion.suggest ~mode:Centl_sci_interaction.Phys input
      (String.length input)
    |> require "constant catalog hint"
  in
  Alcotest.(check bool)
    "structural" true
    (suggestion.category = Centl_sci_suggestion.Structural);
  Alcotest.(check bool) "not auto-accepted" false suggestion.safe_to_accept;
  Alcotest.(check bool)
    "catalog appears" true
    (contains "k_B" suggestion.display_text
    && contains "g0" suggestion.display_text);
  Alcotest.(check bool)
    "alternatives recorded" true
    (List.mem "N_A" suggestion.alternatives)

let test_approximation_structural_hint () =
  let input = "approximate pi" in
  let suggestion =
    Centl_sci_suggestion.suggest ~mode:Centl_sci_interaction.Math input
      (String.length input)
    |> require "approximation digit hint"
  in
  Alcotest.(check bool) "noncommitted" false suggestion.safe_to_accept;
  Alcotest.(check bool)
    "digit target" true
    (contains "significant digits" suggestion.display_text)

let test_verification_needs_relation () =
  let input = "verify x squared" in
  let suggestion =
    Centl_sci_suggestion.suggest ~mode:Centl_sci_interaction.Math input
      (String.length input)
    |> require "verification relation hint"
  in
  Alcotest.(check bool)
    "claim relation missing" true
    (List.mem "claim relation" suggestion.missing_slots);
  Alcotest.(check bool) "not auto-accepted" false suggestion.safe_to_accept

let test_build_validation_needs_name () =
  let input = "validate" in
  let suggestion =
    Centl_sci_suggestion.suggest ~mode:Centl_sci_interaction.Build input
      (String.length input)
    |> require "BUILD validation target hint"
  in
  Alcotest.(check bool)
    "name missing" true
    (List.mem "extension or package name" suggestion.missing_slots)

let test_mechanics_lists_missing_slots () =
  let input = "simulate a particle with mass 2 kg" in
  let suggestion =
    Centl_sci_suggestion.suggest ~mode:Centl_sci_interaction.Phys input
      (String.length input)
    |> require "mechanics missing-slot hint"
  in
  Alcotest.(check bool)
    "position missing" true
    (List.mem "position" suggestion.missing_slots);
  Alcotest.(check bool)
    "gravity missing" true
    (List.mem "gravity" suggestion.missing_slots);
  Alcotest.(check bool) "not auto-accepted" false suggestion.safe_to_accept

let () =
  Alcotest.run "CENTL-SCi Caramels suggestions"
    [
      ( "suggestions",
        [
          Alcotest.test_case "BUILD lexical completion" `Quick
            test_build_lexical_completion;
          Alcotest.test_case "constant catalog hint" `Quick
            test_constant_structural_hint_is_not_committed;
          Alcotest.test_case "approximation hint" `Quick
            test_approximation_structural_hint;
          Alcotest.test_case "verification relation hint" `Quick
            test_verification_needs_relation;
          Alcotest.test_case "BUILD validation target" `Quick
            test_build_validation_needs_name;
          Alcotest.test_case "mechanics missing slots" `Quick
            test_mechanics_lists_missing_slots;
        ] );
    ]
