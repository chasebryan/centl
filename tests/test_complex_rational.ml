open Centl_complex_rational

let q = Q.of_string

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let check_complex message expected_real expected_imaginary actual =
  check_q (message ^ " real") expected_real actual.real;
  check_q (message ^ " imaginary") expected_imaginary actual.imaginary

let expect_error message expected = function
  | Ok _ -> Alcotest.fail (message ^ ": expected error")
  | Error actual ->
      Alcotest.(check string)
        message (error_message expected) (error_message actual)

let test_field_arithmetic () =
  let a = make (q "1/2") (q "2/3") in
  let b = make (q "3/4") (q "-5/6") in
  check_complex "addition" (q "5/4") (q "-1/6") (add a b);
  check_complex "subtraction" (q "-1/4") (q "3/2") (sub a b);
  check_complex "multiplication" (q "67/72") (q "1/12") (mul a b);
  let quotient =
    match div a b with
    | Ok value -> value
    | Error error -> Alcotest.fail (error_message error)
  in
  check_complex "division reconstruction" a.real a.imaginary (mul quotient b)

let test_boundaries () =
  let z = make (q "7/5") (q "-11/13") in
  expect_error "division by zero" Division_by_zero (div z zero);
  expect_error "zero to zero" Undefined_zero_power (pow zero Z.zero);
  expect_error "negative zero power" Division_by_zero
    (pow zero (Z.of_int (-1)));
  begin match pow z Z.zero with
  | Ok value -> check_complex "nonzero power zero" Q.one Q.zero value
  | Error error -> Alcotest.fail (error_message error)
  end

let test_integer_powers () =
  let z = make (q "1") (q "1") in
  begin match pow z (Z.of_int 3) with
  | Ok value -> check_complex "positive power" (q "-2") (q "2") value
  | Error error -> Alcotest.fail (error_message error)
  end;
  begin match pow z (Z.of_int (-1)) with
  | Ok value -> check_complex "negative power" (q "1/2") (q "-1/2") value
  | Error error -> Alcotest.fail (error_message error)
  end

let test_conjugation_and_norm () =
  let z = make (q "3/5") (q "-4/7") in
  let conjugated = conjugate z in
  check_complex "conjugate" (q "3/5") (q "4/7") conjugated;
  check_complex "conjugate involution" z.real z.imaginary
    (conjugate conjugated);
  let product = mul z conjugated in
  check_q "z*conj(z) real = norm2" (norm2 z) product.real;
  check_q "z*conj(z) imaginary = 0" Q.zero product.imaginary

let test_field_identities () =
  let samples =
    [
      make (q "0") (q "1");
      make (q "1/2") (q "-2/3");
      make (q "-5/7") (q "3/11");
      make (q "13/17") (q "19/23");
    ]
  in
  List.iter
    (fun a ->
      List.iter
        (fun b ->
          check_complex "addition commutative" (add a b).real (add a b).imaginary
            (add b a);
          check_complex "multiplication commutative" (mul a b).real
            (mul a b).imaginary (mul b a);
          List.iter
            (fun c ->
              check_complex "addition associative" (add (add a b) c).real
                (add (add a b) c).imaginary (add a (add b c));
              check_complex "multiplication associative" (mul (mul a b) c).real
                (mul (mul a b) c).imaginary (mul a (mul b c));
              check_complex "distributive" (mul a (add b c)).real
                (mul a (add b c)).imaginary
                (add (mul a b) (mul a c)))
            samples)
        samples)
    samples

let lit numerator denominator =
  Centl_Core.Literal (Z.of_int numerator, Z.of_int denominator)

let complex_expression () =
  Centl_Core.Function ("complex", [ lit 1 2; lit 2 3 ])

let test_expression_evaluator () =
  let z = complex_expression () in
  let w =
    Centl_Core.Function ("complex", [ lit 3 4; Centl_Core.Negate (lit 5 6) ])
  in
  let expression = Centl_Core.Binary (Centl_Core.Multiply, z, w) in
  begin match evaluate_expression expression with
  | None -> Alcotest.fail "complex trigger was not detected"
  | Some (Error error) -> Alcotest.fail (error_message error)
  | Some (Ok value) ->
      check_complex "expression multiplication" (q "67/72") (q "1/12") value
  end;
  begin match evaluate_expression (Centl_Core.Function ("norm2", [ z ])) with
  | Some (Ok value) -> check_complex "norm2 expression" (q "25/36") Q.zero value
  | Some (Error error) -> Alcotest.fail (error_message error)
  | None -> Alcotest.fail "norm2 trigger was not detected"
  end;
  Alcotest.(check bool)
    "ordinary rational expression does not hijack core evaluator" true
    (Option.is_none
       (evaluate_expression
          (Centl_Core.Binary (Centl_Core.Add, lit 1 2, lit 1 3))))

let test_cancellation () =
  let z = make Q.one Q.one in
  expect_error "direct power cancellation" Cancelled
    (pow ~cancelled:(fun () -> true) z (Z.of_int 100));
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 4
  in
  expect_error "mid-power cancellation" Cancelled
    (pow ~cancelled z (Z.of_int 65_536));
  Alcotest.(check bool) "power reached repeated squaring" true (!checks >= 4);
  begin match
    evaluate_expression ~cancelled:(fun () -> true) (complex_expression ())
  with
  | Some (Error Cancelled) -> ()
  | Some (Error error) -> Alcotest.fail (error_message error)
  | Some (Ok _) -> Alcotest.fail "cancelled evaluation should not succeed"
  | None -> Alcotest.fail "complex trigger was not detected"
  end

let test_evaluation_limits () =
  let power_limits =
    { default_evaluation_limits with max_power_exponent = 2 }
  in
  let powered = Centl_Core.Power (complex_expression (), Z.of_int 3) in
  begin match evaluate_expression ~limits:power_limits powered with
  | Some (Error (Resource_limit _)) -> ()
  | Some (Error error) -> Alcotest.fail (error_message error)
  | Some (Ok _) -> Alcotest.fail "oversized exponent should be refused"
  | None -> Alcotest.fail "complex trigger was not detected"
  end;
  let work_limits = { default_evaluation_limits with max_work = 1 } in
  begin match evaluate_expression ~limits:work_limits (complex_expression ()) with
  | Some (Error (Resource_limit _)) -> ()
  | Some (Error error) -> Alcotest.fail (error_message error)
  | Some (Ok _) -> Alcotest.fail "work-limited evaluation should be refused"
  | None -> Alcotest.fail "complex trigger was not detected"
  end;
  let bit_limits = { default_evaluation_limits with max_exact_bits = 4 } in
  let large = Centl_Core.Function ("complex", [ lit 17 1; lit 0 1 ]) in
  begin match evaluate_expression ~limits:bit_limits large with
  | Some (Error (Resource_limit _)) -> ()
  | Some (Error error) -> Alcotest.fail (error_message error)
  | Some (Ok _) -> Alcotest.fail "bit-limited evaluation should be refused"
  | None -> Alcotest.fail "complex trigger was not detected"
  end;
  let growth_limits = { default_evaluation_limits with max_exact_bits = 32 } in
  let growth_base =
    Centl_Core.Function ("complex", [ lit 3 1; lit 4 1 ])
  in
  let growth = Centl_Core.Power (growth_base, Z.of_int 32) in
  begin match evaluate_expression ~limits:growth_limits growth with
  | Some (Error (Resource_limit _)) -> ()
  | Some (Error error) -> Alcotest.fail (error_message error)
  | Some (Ok _) -> Alcotest.fail "power growth should trip the bit ceiling"
  | None -> Alcotest.fail "complex trigger was not detected"
  end

let test_large_exact_field_identity () =
  let huge = Z.add (Z.shift_left Z.one 4_096) (Z.of_int 19) in
  let denominator = Z.sub huge (Z.of_int 2) in
  let z =
    make (Q.make huge denominator)
      (Q.make (Z.add huge Z.one) (Z.add denominator (Z.of_int 6)))
  in
  begin match div z z with
  | Error error -> Alcotest.fail (error_message error)
  | Ok value -> check_complex "4096-bit z/z" Q.one Q.zero value
  end

let test_rendering () =
  Alcotest.(check string)
    "positive imaginary" "1/2 + 3/4*i" (text (make (q "1/2") (q "3/4")));
  Alcotest.(check string)
    "negative imaginary" "1/2 - 3/4*i" (text (make (q "1/2") (q "-3/4")));
  Alcotest.(check string) "pure i" "i" (text (make Q.zero Q.one));
  Alcotest.(check string) "negative i" "-i" (text (make Q.zero Q.minus_one));
  Alcotest.(check string) "pure real" "7/9" (text (make (q "7/9") Q.zero))

let () =
  Alcotest.run "centl exact complex rationals"
    [
      ( "complex-rational",
        [
          Alcotest.test_case "field arithmetic" `Quick test_field_arithmetic;
          Alcotest.test_case "boundaries" `Quick test_boundaries;
          Alcotest.test_case "integer powers" `Quick test_integer_powers;
          Alcotest.test_case "conjugation and norm" `Quick
            test_conjugation_and_norm;
          Alcotest.test_case "field identities" `Quick test_field_identities;
          Alcotest.test_case "expression evaluator" `Quick
            test_expression_evaluator;
          Alcotest.test_case "cancellation" `Quick test_cancellation;
          Alcotest.test_case "evaluation limits" `Quick test_evaluation_limits;
          Alcotest.test_case "4096-bit identity" `Quick
            test_large_exact_field_identity;
          Alcotest.test_case "rendering" `Quick test_rendering;
        ] );
    ]
