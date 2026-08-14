let test_composes_existing_gcd () =
  match Centl_sci_mirage_compose.compose_text "compute gcd of 48 and 18" with
  | Some ("exact_expression", expression) ->
      Alcotest.(check string) "composed expression" "gcd(48, 18)" expression
  | _ -> Alcotest.fail "expected existing gcd composition"

let test_does_not_invent_unrelated_prose () =
  Alcotest.(check bool)
    "unrelated prose is not composed" true
    (Option.is_none
       (Centl_sci_mirage_compose.compose_text
          "write a novel about desert travel"))

let () =
  Alcotest.run "CENTL-MIRAGE composition"
    [
      ( "compose",
        [
          Alcotest.test_case "gcd" `Quick test_composes_existing_gcd;
          Alcotest.test_case "no invention" `Quick
            test_does_not_invent_unrelated_prose;
        ] );
    ]
