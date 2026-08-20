open Centl_multivariate_polynomial
open Centl_polynomial_square_free

let q text = Q.of_string text

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_factorization = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_square_free.error_message error)

let x = unwrap_poly (variable "x")
let linear constant_term = add x (constant (q constant_term))

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

let test_repeated_multiplicities () =
  let x_minus_one = linear "-1" in
  let x_plus_two = linear "2" in
  let polynomial =
    scale (q "2")
      (multiply_exn (power_exn x_minus_one 2) (power_exn x_plus_two 3))
  in
  let result = unwrap_factorization (factorize ~variable:"x" polynomial) in
  Alcotest.(check string) "unit" "2" (Q.to_string result.unit);
  begin match result.factors with
  | [ first; second ] ->
      Alcotest.(check int) "first multiplicity" 2 first.multiplicity;
      check_poly "first factor" x_minus_one first.polynomial;
      Alcotest.(check int) "second multiplicity" 3 second.multiplicity;
      check_poly "second factor" x_plus_two second.polynomial
  | _ -> Alcotest.fail "expected multiplicity-2 and multiplicity-3 factors"
  end;
  check_poly "reconstruction" polynomial (reconstruct result)

let test_mixed_single_and_repeated () =
  let x_plus_three = linear "3" in
  let x_minus_one = linear "-1" in
  let polynomial =
    scale (q "-3/5")
      (multiply_exn x_plus_three (power_exn x_minus_one 2))
  in
  let result = unwrap_factorization (factorize ~variable:"x" polynomial) in
  Alcotest.(check string) "unit" "-3/5" (Q.to_string result.unit);
  begin match result.factors with
  | [ first; second ] ->
      Alcotest.(check int) "single multiplicity" 1 first.multiplicity;
      check_poly "single factor" x_plus_three first.polynomial;
      Alcotest.(check int) "repeated multiplicity" 2 second.multiplicity;
      check_poly "repeated factor" x_minus_one second.polynomial
  | _ -> Alcotest.fail "expected multiplicity-1 and multiplicity-2 factors"
  end;
  check_poly "reconstruction" polynomial (reconstruct result)

let test_square_free_input () =
  let polynomial = scale (q "4/7") (sub (power_exn x 2) one) in
  let result = unwrap_factorization (factorize ~variable:"x" polynomial) in
  Alcotest.(check string) "unit" "4/7" (Q.to_string result.unit);
  begin match result.factors with
  | [ factor ] ->
      Alcotest.(check int) "multiplicity" 1 factor.multiplicity;
      check_poly "monic factor" (sub (power_exn x 2) one) factor.polynomial
  | _ -> Alcotest.fail "square-free input must return one multiplicity-1 factor"
  end;
  check_poly "reconstruction" polynomial (reconstruct result)

let test_constant () =
  let polynomial = constant (q "-7/3") in
  let result = unwrap_factorization (factorize ~variable:"x" polynomial) in
  Alcotest.(check string) "constant unit" "-7/3" (Q.to_string result.unit);
  Alcotest.(check int) "no factors" 0 (List.length result.factors);
  check_poly "constant reconstruction" polynomial (reconstruct result)

let test_zero_refusal () =
  match factorize ~variable:"x" zero with
  | Error Zero_polynomial -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "zero polynomial factorization must be refused"

let test_mixed_variable_refusal () =
  let y = unwrap_poly (variable "y") in
  match factorize ~variable:"x" (add x y) with
  | Error (Mixed_variable "y") -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "mixed-variable factorization must be refused"

let test_factor_step_limit () =
  let polynomial = power_exn (linear "-1") 3 in
  let limits = { default_limits with max_factor_steps = 1 } in
  match factorize ~limits ~variable:"x" polynomial with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "multiplicity-3 input must hit max_factor_steps=1"

let test_shared_work_limit () =
  let polynomial =
    multiply_exn (power_exn (linear "-1") 2) (power_exn (linear "2") 3)
  in
  let division =
    { Centl_polynomial_division.default_limits with max_work = 24 }
  in
  let limits = { default_limits with division } in
  match factorize ~limits ~variable:"x" polynomial with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "derivative, gcd, division, and factor work must share one budget"

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

let test_mid_chain_cancellation () =
  let polynomial =
    multiply_exn (power_exn (linear "-1") 4) (power_exn (linear "2") 3)
  in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 24
  in
  begin match factorize ~cancelled ~variable:"x" polynomial with
  | Error Cancelled -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "square-free factorization should cancel mid-chain"
  end;
  Alcotest.(check bool) "multiple checkpoints" true (!checks >= 24)

let () =
  Alcotest.run "centl polynomial square-free factorization"
    [
      ( "square-free",
        [
          Alcotest.test_case "repeated multiplicities" `Quick
            test_repeated_multiplicities;
          Alcotest.test_case "mixed single and repeated" `Quick
            test_mixed_single_and_repeated;
          Alcotest.test_case "already square-free" `Quick test_square_free_input;
          Alcotest.test_case "constant" `Quick test_constant;
          Alcotest.test_case "zero refusal" `Quick test_zero_refusal;
          Alcotest.test_case "mixed variable" `Quick test_mixed_variable_refusal;
          Alcotest.test_case "factor step limit" `Quick test_factor_step_limit;
          Alcotest.test_case "shared work limit" `Quick test_shared_work_limit;
          Alcotest.test_case "exact bit limit" `Quick test_exact_bit_limit;
          Alcotest.test_case "mid-chain cancellation" `Quick
            test_mid_chain_cancellation;
        ] );
    ]
