let test_unicode_and_polite_recovery () =
  let normalized =
    Centl_sci_interaction.normalize Centl_sci_interaction.Math
      "Could you please INTERGRATE x² with respect to x?"
  in
  Alcotest.(check string) "unicode/typo/polite recovery"
    "integrate x^2 with respect to x?" (String.lowercase_ascii normalized)

let test_root_canonicalization () =
  let normalized =
    Centl_sci_interaction.normalize Centl_sci_interaction.Math
      "Find the roots of x^2 - 5*x + 6"
  in
  Alcotest.(check string) "roots become solve-zero request"
    "solve x^2 - 5*x + 6 equals zero" normalized

let test_how_many_conversion () =
  let normalized =
    Centl_sci_interaction.normalize Centl_sci_interaction.Phys
      "How many meters are exactly 2.5 kilometers?"
  in
  Alcotest.(check string) "question conversion canonical form"
    "convert 2.5 kilometers to meters" normalized;
  match Centl_sci_fastpath.interpret normalized with
  | Some (Centl_sci_ir.Unit_conversion data) ->
      Alcotest.(check string) "value" "2.5" data.value;
      Alcotest.(check string) "source" "km" data.from_unit;
      Alcotest.(check string) "target" "m" data.to_unit
  | _ -> Alcotest.fail "canonical how-many conversion did not reach unit fast path"

let test_how_many_are_in_conversion () =
  let normalized =
    Centl_sci_interaction.normalize Centl_sci_interaction.Phys
      "How many seconds are in 3 minutes."
  in
  Alcotest.(check string) "are-in conversion canonical form"
    "convert 3 minutes to seconds" normalized

let test_build_completion_surface () =
  let completions =
    Centl_sci_interaction.completion_candidates Centl_sci_interaction.Build
  in
  List.iter
    (fun candidate ->
      Alcotest.(check bool) (candidate ^ " completion") true
        (List.mem candidate completions))
    [ "audit"; "capabilities"; "export"; "import"; "package"; "validate" ]

let test_physics_completion_surface () =
  let completions =
    Centl_sci_interaction.completion_candidates Centl_sci_interaction.Phys
  in
  List.iter
    (fun candidate ->
      Alcotest.(check bool) (candidate ^ " completion") true
        (List.mem candidate completions))
    [ "constant"; "k_B"; "N_A"; "g0"; "simulate" ]

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
    ]
