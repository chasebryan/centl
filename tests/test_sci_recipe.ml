let test_lookup_by_phrase () =
  match Centl_sci_recipe.lookup_request "make a kinetic energy function" with
  | None -> Alcotest.fail "expected kinetic energy recipe"
  | Some recipe ->
      Alcotest.(check string) "name" "kinetic_energy" recipe.name;
      Alcotest.(check string)
        "body" "1/2 * mass * velocity^2" recipe.implementation

let test_harmonic_mean_is_exact () =
  match Centl_sci_recipe.lookup "harmonic mean" with
  | None -> Alcotest.fail "expected harmonic mean"
  | Some recipe ->
      Alcotest.(check string)
        "source" "harmonic_mean(a, b) = 2 / ((1/a) + (1/b))"
        (Centl_sci_recipe.source recipe)

let test_unknown_is_not_invented () =
  Alcotest.(check bool)
    "no invented gravity constant" true
    (Option.is_none
       (Centl_sci_recipe.lookup_request "make a gravitational constant function"))

let () =
  Alcotest.run "CENTL-SCi exact recipes"
    [
      ( "recipes",
        [
          Alcotest.test_case "kinetic energy phrase" `Quick
            test_lookup_by_phrase;
          Alcotest.test_case "harmonic mean" `Quick test_harmonic_mean_is_exact;
          Alcotest.test_case "unknown refused" `Quick
            test_unknown_is_not_invented;
        ] );
    ]
