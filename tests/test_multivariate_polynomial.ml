open Centl_multivariate_polynomial

let q = Q.of_string

let unwrap = function
  | Ok value -> value
  | Error error -> Alcotest.fail (error_message error)

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let check_poly message expected actual =
  Alcotest.(check bool) message true (equal expected actual)

let x = unwrap (variable "x")
let y = unwrap (variable "y")
let z = unwrap (variable "z")

let termq coefficient powers = unwrap (term (q coefficient) powers)

let test_canonicalization () =
  let combined = termq "3/2" [ ("y", 0); ("x", 1); ("x", 2) ] in
  check_poly "duplicate powers combine" (termq "3/2" [ ("x", 3) ]) combined;
  Alcotest.(check int) "one term" 1 (term_count combined);
  check_poly "zero coefficient disappears" zero
    (unwrap (term Q.zero [ ("x", 99) ]));
  begin match term Q.one [ ("", 1) ] with
  | Error Empty_variable -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "empty variable should fail"
  end;
  begin match term Q.one [ ("x", -1) ] with
  | Error (Negative_exponent ("x", -1)) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "negative exponent should fail"
  end

let test_ring_arithmetic () =
  let x_plus_y = add x y in
  let square = unwrap (power x_plus_y 2) in
  let expected =
    add (termq "1" [ ("x", 2) ])
      (add (termq "2" [ ("x", 1); ("y", 1) ])
         (termq "1" [ ("y", 2) ]))
  in
  check_poly "(x+y)^2" expected square;
  let a = add (scale (q "2") x) (add y (constant (q "3/5"))) in
  let b = sub z (scale (q "7/3") y) in
  let c = add x (constant (q "-2")) in
  check_poly "addition commutative" (add a b) (add b a);
  check_poly "addition associative" (add (add a b) c) (add a (add b c));
  check_poly "multiplication commutative" (unwrap (multiply a b))
    (unwrap (multiply b a));
  check_poly "distributive" (unwrap (multiply a (add b c)))
    (add (unwrap (multiply a b)) (unwrap (multiply a c)))

let test_coefficients_variables_degree () =
  let polynomial =
    add (termq "5/7" [ ("z", 2); ("x", 1) ])
      (add (termq "-3" [ ("y", 4) ]) (constant (q "2")))
  in
  check_q "coefficient" (q "5/7")
    (unwrap (coefficient polynomial [ ("x", 1); ("z", 2) ]));
  check_q "missing coefficient" Q.zero
    (unwrap (coefficient polynomial [ ("x", 9) ]));
  Alcotest.(check (list string)) "variables" [ "x"; "y"; "z" ]
    (variables polynomial);
  begin match total_degree polynomial with
  | Some degree -> Alcotest.(check int) "total degree" 4 degree
  | None -> Alcotest.fail "nonzero polynomial must have a degree"
  end;
  Alcotest.(check bool) "zero degree undefined" true (Option.is_none (total_degree zero))

let test_derivative () =
  let polynomial =
    add (termq "1" [ ("x", 2); ("y", 1) ])
      (add (scale (q "3") y) (termq "5/2" [ ("x", 1) ]))
  in
  let derivative_x = unwrap (derivative "x" polynomial) in
  let expected =
    add (termq "2" [ ("x", 1); ("y", 1) ]) (constant (q "5/2"))
  in
  check_poly "partial derivative" expected derivative_x;
  check_poly "absent variable derivative" zero
    (unwrap (derivative "z" polynomial))

let test_rational_substitution () =
  let polynomial =
    add (termq "1" [ ("x", 2); ("y", 1) ])
      (add (termq "3" [ ("y", 1) ]) (termq "2" [ ("x", 1); ("z", 1) ]))
  in
  let substituted =
    unwrap (substitute_rationals [ ("x", q "2"); ("z", q "-1/2") ] polynomial)
  in
  check_poly "partial rational substitution"
    (add (scale (q "7") y) (constant (q "-2"))) substituted;
  begin match substitute_rationals [ ("x", Q.one); ("x", Q.zero) ] polynomial with
  | Error (Duplicate_substitution "x") -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "duplicate substitution should fail"
  end

let test_power_boundaries () =
  begin match power zero 0 with
  | Error Undefined_zero_power -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "0^0 should fail"
  end;
  begin match power x (-1) with
  | Error (Negative_power (-1)) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "negative polynomial power should fail"
  end;
  check_poly "x^0" one (unwrap (power x 0));
  check_poly "zero multiplier" zero (unwrap (multiply zero (add x y)))

let () =
  Alcotest.run "centl exact multivariate polynomials"
    [
      ( "polynomial",
        [
          Alcotest.test_case "canonicalization" `Quick test_canonicalization;
          Alcotest.test_case "ring arithmetic" `Quick test_ring_arithmetic;
          Alcotest.test_case "coefficients variables degree" `Quick
            test_coefficients_variables_degree;
          Alcotest.test_case "derivative" `Quick test_derivative;
          Alcotest.test_case "rational substitution" `Quick
            test_rational_substitution;
          Alcotest.test_case "power boundaries" `Quick test_power_boundaries;
        ] );
    ]
