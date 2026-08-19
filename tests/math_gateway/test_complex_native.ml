let unwrap_parse source =
  match Centl_parser.parse source with
  | Ok expression -> expression
  | Error error -> Alcotest.fail error.message

let q text = Q.of_string text

let test_not_complex () =
  let expression = unwrap_parse "1/2 + 1/3" in
  match Centl_complex_native.evaluate expression with
  | Centl_complex_native.Not_complex -> ()
  | Centl_complex_native.Exact value ->
      Alcotest.fail ("ordinary rational misclassified: " ^ Centl_complex_rational.to_string value)
  | Centl_complex_native.Refused error ->
      Alcotest.fail (Centl_complex_rational.error_message error)

let test_exact_mixed_expression () =
  let expression =
    unwrap_parse "1/2 + complex(1/3, 2/5) * complex(3, 0)"
  in
  match Centl_complex_native.evaluate expression with
  | Centl_complex_native.Exact value ->
      Alcotest.(check string) "real" (Q.to_string (q "3/2"))
        (Q.to_string value.real);
      Alcotest.(check string) "imaginary" (Q.to_string (q "6/5"))
        (Q.to_string value.imaginary);
      Alcotest.(check bool) "has exact bits" true
        (Centl_complex_native.exact_bits (Centl_complex_native.Exact value) > 0)
  | Centl_complex_native.Not_complex -> Alcotest.fail "complex expression was missed"
  | Centl_complex_native.Refused error ->
      Alcotest.fail (Centl_complex_rational.error_message error)

let test_exact_functions () =
  let expression = unwrap_parse "conj(complex(3/4, -5/6))" in
  match Centl_complex_native.evaluate expression with
  | Centl_complex_native.Exact value ->
      Alcotest.(check string) "real" "3/4" (Q.to_string value.real);
      Alcotest.(check string) "imaginary" "5/6" (Q.to_string value.imaginary)
  | Centl_complex_native.Not_complex -> Alcotest.fail "conjugate was missed"
  | Centl_complex_native.Refused error ->
      Alcotest.fail (Centl_complex_rational.error_message error)

let test_explicit_refusal () =
  let expression = unwrap_parse "complex(sqrt(2), 0)" in
  match Centl_complex_native.evaluate expression with
  | Centl_complex_native.Refused Centl_complex_rational.Unsupported_exact_expression -> ()
  | Centl_complex_native.Refused error ->
      Alcotest.fail ("unexpected refusal: " ^ Centl_complex_rational.error_message error)
  | Centl_complex_native.Not_complex -> Alcotest.fail "complex request was missed"
  | Centl_complex_native.Exact value ->
      Alcotest.fail ("irrational component was incorrectly admitted: " ^ Centl_complex_rational.to_string value)

let test_division_by_zero () =
  let expression = unwrap_parse "complex(1, 2) / complex(0, 0)" in
  match Centl_complex_native.evaluate expression with
  | Centl_complex_native.Refused Centl_complex_rational.Division_by_zero -> ()
  | Centl_complex_native.Refused error ->
      Alcotest.fail ("unexpected refusal: " ^ Centl_complex_rational.error_message error)
  | Centl_complex_native.Not_complex -> Alcotest.fail "complex request was missed"
  | Centl_complex_native.Exact value ->
      Alcotest.fail ("division by zero returned " ^ Centl_complex_rational.to_string value)

let () =
  Alcotest.run "centl native exact complex bridge"
    [
      ( "bridge",
        [
          Alcotest.test_case "ordinary rational is not complex" `Quick test_not_complex;
          Alcotest.test_case "mixed exact expression" `Quick test_exact_mixed_expression;
          Alcotest.test_case "exact functions" `Quick test_exact_functions;
          Alcotest.test_case "irrational component refusal" `Quick test_explicit_refusal;
          Alcotest.test_case "division by zero" `Quick test_division_by_zero;
        ] );
    ]
