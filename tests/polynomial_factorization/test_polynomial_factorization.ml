open Centl_multivariate_polynomial
open Centl_polynomial_factorization

let q text = Q.of_string text

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_factorization = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_factorization.error_message error)

let x = unwrap_poly (variable "x")
let y = unwrap_poly (variable "y")

let multiply_exn left right =
  match multiply left right with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let power_exn polynomial exponent =
  match power polynomial exponent with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let check_poly message expected actual =
  Alcotest.(check bool) message true (equal expected actual)

let reconstruct factorization =
  factorization.factors
  |> List.fold_left
       (fun result factor ->
         multiply_exn result (power_exn factor.polynomial factor.multiplicity))
       (constant factorization.unit)

let polynomial_of_coefficients coefficients =
  coefficients
  |> List.mapi (fun exponent coefficient ->
         if Q.equal coefficient Q.zero then zero
         else if exponent = 0 then constant coefficient
         else unwrap_poly (term coefficient [ ("x", exponent) ]))
  |> List.fold_left add zero

let integer_polynomial coefficients =
  polynomial_of_coefficients (List.map (fun value -> Q.of_int value) coefficients)

let monic_linear numerator denominator =
  add x (constant (Q.make (Z.of_int numerator) (Z.of_int denominator)))

let factor_polynomials result =
  List.map (fun factor -> (factor.multiplicity, factor.polynomial)) result.factors

let check_factor_list message expected actual =
  Alcotest.(check int) (message ^ " count") (List.length expected) (List.length actual);
  List.iter2
    (fun (expected_multiplicity, expected_polynomial) factor ->
      Alcotest.(check int) (message ^ " multiplicity") expected_multiplicity
        factor.multiplicity;
      check_poly (message ^ " factor") expected_polynomial factor.polynomial)
    expected actual

let test_nonmonic_rational_repeated () =
  let linear = integer_polynomial [ 1; 2 ] in
  let quadratic = integer_polynomial [ 1; 1; 3 ] in
  let polynomial =
    scale (q "5/7")
      (multiply_exn (power_exn linear 2) quadratic)
  in
  let result = unwrap_factorization (factorize ~variable:"x" polynomial) in
  Alcotest.(check string) "unit" "60/7" (Q.to_string result.unit);
  let expected_linear = monic_linear 1 2 in
  let expected_quadratic =
    polynomial_of_coefficients [ q "1/3"; q "1/3"; Q.one ]
  in
  check_factor_list "nonmonic rational"
    [ (2, expected_linear); (1, expected_quadratic) ] result.factors;
  check_poly "exact reconstruction" polynomial (reconstruct result)

let test_complete_elementary_factorization () =
  let polynomial = sub (power_exn x 4) one in
  let result = unwrap_factorization (factorize ~variable:"x" polynomial) in
  check_factor_list "x^4-1"
    [
      (1, add x (constant (q "-1")));
      (1, add x one);
      (1, add (power_exn x 2) one);
    ]
    result.factors;
  check_poly "x^4-1 reconstruction" polynomial (reconstruct result)

let test_eisenstein_cubic_irreducible () =
  let polynomial = integer_polynomial [ 2; 2; 0; 1 ] in
  let result = unwrap_factorization (factorize ~variable:"x" polynomial) in
  check_factor_list "Eisenstein cubic" [ (1, polynomial) ] result.factors;
  check_poly "cubic reconstruction" polynomial (reconstruct result)

let test_eisenstein_quartic_irreducible () =
  let polynomial = integer_polynomial [ 2; 2; 0; 0; 1 ] in
  let result = unwrap_factorization (factorize ~variable:"x" polynomial) in
  check_factor_list "Eisenstein quartic" [ (1, polynomial) ] result.factors;
  check_poly "quartic reconstruction" polynomial (reconstruct result)

let test_constant () =
  let polynomial = constant (q "-7/3") in
  let result = unwrap_factorization (factorize ~variable:"x" polynomial) in
  Alcotest.(check string) "constant unit" "-7/3" (Q.to_string result.unit);
  Alcotest.(check int) "constant factors" 0 (List.length result.factors);
  check_poly "constant reconstruction" polynomial (reconstruct result)

let test_zero_refusal () =
  match factorize ~variable:"x" zero with
  | Error Zero_polynomial -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "zero polynomial factorization must be refused"

let test_mixed_variable_refusal () =
  match factorize ~variable:"x" (add x y) with
  | Error (Mixed_variable "y") -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "mixed-variable factorization must be refused"

let test_degree_limit () =
  let polynomial = integer_polynomial [ 2; 2; 0; 1 ] in
  let limits = { default_limits with max_degree = 2 } in
  match factorize ~limits ~variable:"x" polynomial with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "degree ceiling must refuse the cubic"

let test_candidate_limit_does_not_claim_irreducible () =
  let polynomial = add (power_exn x 2) one in
  let limits = { default_limits with max_candidates = 1 } in
  match factorize ~limits ~variable:"x" polynomial with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "incomplete candidate search must not imply irreducibility"

let test_divisor_trial_limit_does_not_claim_irreducible () =
  let polynomial = integer_polynomial [ 6; 1; 1 ] in
  let limits = { default_limits with max_divisor_trials = 1 } in
  match factorize ~limits ~variable:"x" polynomial with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "incomplete divisor search must not imply irreducibility"

let test_retained_divisor_limit () =
  let polynomial = integer_polynomial [ 12; 1; 1 ] in
  let limits = { default_limits with max_divisors_per_value = 2 } in
  match factorize ~limits ~variable:"x" polynomial with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "retained divisor ceiling must refuse oversized divisor lists"

let test_exact_bit_limit () =
  let huge = Z.shift_left Z.one 128 |> Q.of_bigint in
  let polynomial = add x (constant huge) in
  let division =
    { Centl_polynomial_division.default_limits with max_exact_bits = 32 }
  in
  let limits = { default_limits with division } in
  match factorize ~limits ~variable:"x" polynomial with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "oversized exact input must be refused"

let test_deterministic_ordering () =
  let polynomial =
    multiply_exn
      (power_exn (integer_polynomial [ 1; 2 ]) 2)
      (multiply_exn (integer_polynomial [ -1; 1 ])
         (integer_polynomial [ 1; 0; 1 ]))
  in
  let left = unwrap_factorization (factorize ~variable:"x" polynomial) in
  let right = unwrap_factorization (factorize ~variable:"x" polynomial) in
  Alcotest.(check string) "same unit" (Q.to_string left.unit) (Q.to_string right.unit);
  let left_factors = factor_polynomials left in
  let right_factors = factor_polynomials right in
  Alcotest.(check int) "same factor count" (List.length left_factors)
    (List.length right_factors);
  List.iter2
    (fun (lm, lp) (rm, rp) ->
      Alcotest.(check int) "same multiplicity" lm rm;
      check_poly "same ordered factor" lp rp)
    left_factors right_factors

let test_mid_search_cancellation () =
  let polynomial =
    multiply_exn
      (integer_polynomial [ 2; 2; 0; 1 ])
      (integer_polynomial [ 2; 2; 0; 0; 1 ])
  in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 20
  in
  begin match factorize ~cancelled ~variable:"x" polynomial with
  | Error Cancelled -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "factorization should cancel during exact search"
  end;
  Alcotest.(check bool) "multiple checkpoints" true (!checks >= 20)

let () =
  Alcotest.run "centl rational polynomial factorization"
    [
      ( "factorization",
        [
          Alcotest.test_case "nonmonic rational repeated" `Quick
            test_nonmonic_rational_repeated;
          Alcotest.test_case "x^4-1 complete" `Quick
            test_complete_elementary_factorization;
          Alcotest.test_case "Eisenstein cubic irreducible" `Quick
            test_eisenstein_cubic_irreducible;
          Alcotest.test_case "Eisenstein quartic irreducible" `Quick
            test_eisenstein_quartic_irreducible;
          Alcotest.test_case "constant" `Quick test_constant;
          Alcotest.test_case "zero refusal" `Quick test_zero_refusal;
          Alcotest.test_case "mixed variable refusal" `Quick
            test_mixed_variable_refusal;
          Alcotest.test_case "degree limit" `Quick test_degree_limit;
          Alcotest.test_case "candidate limit refuses" `Quick
            test_candidate_limit_does_not_claim_irreducible;
          Alcotest.test_case "divisor trial limit refuses" `Quick
            test_divisor_trial_limit_does_not_claim_irreducible;
          Alcotest.test_case "retained divisor limit" `Quick
            test_retained_divisor_limit;
          Alcotest.test_case "exact bit limit" `Quick test_exact_bit_limit;
          Alcotest.test_case "deterministic ordering" `Quick
            test_deterministic_ordering;
          Alcotest.test_case "mid-search cancellation" `Quick
            test_mid_search_cancellation;
        ] );
    ]
