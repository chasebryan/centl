let test_natural_equation () =
  Alcotest.(check bool)
    "natural solve equation" true
    (match
       Centl_sci_hint.classify
         "Solve x squared minus 5 x plus 6 equals zero for x."
     with
    | Centl_sci_hint.Polynomial_equation -> true
    | _ -> false)

let test_general_text () =
  Alcotest.(check bool)
    "general text stays unconstrained" true
    (match Centl_sci_hint.classify "Explain why the sky is blue." with
    | Centl_sci_hint.Any -> true
    | _ -> false)

let test_solve_without_relation () =
  Alcotest.(check bool)
    "ambiguous solve stays unconstrained" true
    (match Centl_sci_hint.classify "Solve this puzzle for me." with
    | Centl_sci_hint.Any -> true
    | _ -> false)

let () =
  Alcotest.run "centl-sci-hint"
    [
      ( "classification",
        [
          Alcotest.test_case "natural equation" `Quick test_natural_equation;
          Alcotest.test_case "general text" `Quick test_general_text;
          Alcotest.test_case "ambiguous solve" `Quick test_solve_without_relation;
        ] );
    ]
