let intent_name classification =
  Centl_sci_intent.text classification.Centl_sci_intent.intent

let check_intent expected mode input =
  let actual = Centl_sci_intent.classify ~mode input |> intent_name in
  Alcotest.(check string) input expected actual

let test_math_intents () =
  check_intent "equation_solving" Centl_sci_interaction.Hybrid
    "find the roots of x squared minus 5x plus 6";
  check_intent "unit_conversion" Centl_sci_interaction.Phys
    "change 2.5 kilometers into meters";
  check_intent "differentiation" Centl_sci_interaction.Math
    "derivative of x squared";
  check_intent "integration" Centl_sci_interaction.Math "integrate x squared"

let test_concrete_math_intents () =
  check_intent "arithmetic" Centl_sci_interaction.Math "what is ten factorial";
  check_intent "sequence" Centl_sci_interaction.Math
    "what is the tenth fibonacci number";
  check_intent "sequence" Centl_sci_interaction.Math
    "list the squares from 1 to 5";
  check_intent "geometry" Centl_sci_interaction.Math
    "what is the area of a circle with radius 3";
  check_intent "geometry" Centl_sci_interaction.Math
    "find the distance between (0, 0) and (3, 4)"

let test_build_intents () =
  check_intent "system_extension" Centl_sci_interaction.Build
    "add nautical miles";
  check_intent "program_creation" Centl_sci_interaction.Build
    "create a kinetic energy function";
  check_intent "system_inspection" Centl_sci_interaction.Build
    "show me what I changed";
  check_intent "system_modification" Centl_sci_interaction.Build
    "disable my turbulence package"

let test_root_canonicalization () =
  let input = "roots of x squared minus 5x plus 6" in
  let classification =
    Centl_sci_intent.classify ~mode:Centl_sci_interaction.Math input
  in
  let actual = Centl_sci_intent.canonicalize classification input in
  Alcotest.(check string)
    "roots imply equality to zero" "solve x squared minus 5x plus 6 equals zero"
    actual

let () =
  Alcotest.run "centl-sci-intent"
    [
      ( "routing",
        [
          Alcotest.test_case "math and physics" `Quick test_math_intents;
          Alcotest.test_case "concrete math" `Quick test_concrete_math_intents;
          Alcotest.test_case "build" `Quick test_build_intents;
          Alcotest.test_case "root canonicalization" `Quick
            test_root_canonicalization;
        ] );
    ]
