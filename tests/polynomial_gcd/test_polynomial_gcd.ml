open Centl_multivariate_polynomial
open Centl_polynomial_gcd

let q text = Q.of_string text

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_gcd = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_gcd.error_message error)

let termq coefficient powers = unwrap_poly (term (q coefficient) powers)
let xterm coefficient exponent = termq coefficient [ ("x", exponent) ]

let check_poly message expected actual =
  Alcotest.(check bool) message true (equal expected actual)

let divides divisor dividend =
  if is_zero divisor then is_zero dividend
  else
    match Centl_polynomial_division.divide ~variable:"x" dividend divisor with
    | Ok division -> is_zero division.remainder
    | Error _ -> false

let test_common_linear_factor () =
  let left = sub (xterm "1" 3) one in
  let right = sub (xterm "1" 2) one in
  let result = unwrap_gcd (gcd ~variable:"x" left right) in
  let expected = sub (xterm "1" 1) one in
  check_poly "gcd x-1" expected result;
  Alcotest.(check bool) "divides left" true (divides result left);
  Alcotest.(check bool) "divides right" true (divides result right)

let test_content_and_sign_normalization () =
  let factor = sub (xterm "1" 1) one in
  let left = scale (q "-2") factor in
  let right = scale (q "4") factor in
  let result = unwrap_gcd (gcd ~variable:"x" left right) in
  check_poly "monic sign/content normalization" factor result

let test_rational_coefficients () =
  let left =
    add (xterm "1/2" 2) (constant (q "-1/2"))
  in
  let right = add (xterm "3/4" 1) (constant (q "-3/4")) in
  let expected = sub (xterm "1" 1) one in
  check_poly "rational gcd" expected
    (unwrap_gcd (gcd ~variable:"x" left right))

let test_coprime () =
  let left = add (xterm "1" 2) one in
  let right = add (xterm "1" 1) one in
  let result = unwrap_gcd (gcd ~variable:"x" left right) in
  check_poly "coprime gcd one" one result;
  begin match coprime ~variable:"x" left right with
  | Ok true -> ()
  | Ok false -> Alcotest.fail "coprime helper returned false"
  | Error error -> Alcotest.fail (error_message error)
  end

let test_zero_conventions () =
  check_poly "gcd(0,0)=0" zero (unwrap_gcd (gcd ~variable:"x" zero zero));
  let input = add (xterm "2" 1) (constant (q "2")) in
  let expected = add (xterm "1" 1) one in
  check_poly "gcd(a,0)=monic(a)" expected
    (unwrap_gcd (gcd ~variable:"x" input zero));
  check_poly "gcd(0,a)=monic(a)" expected
    (unwrap_gcd (gcd ~variable:"x" zero input))

let test_mixed_variable_rejection () =
  let left = add (xterm "1" 2) one in
  let right = unwrap_poly (term Q.one [ ("y", 1) ]) in
  match gcd ~variable:"x" left right with
  | Error (Mixed_variable "y") -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "mixed-variable gcd input must be rejected"

let test_euclid_step_limit () =
  let left = add (xterm "1" 4) (add (xterm "1" 1) one) in
  let right = add (xterm "1" 3) (add (xterm "1" 1) one) in
  let limits = { default_limits with max_euclid_steps = 1 } in
  match gcd ~limits ~variable:"x" left right with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "multi-step Euclidean chain must hit max_euclid_steps=1"

let test_shared_work_limit () =
  let left = add (xterm "1" 4) one in
  let right = add (xterm "1" 3) one in
  let division =
    { Centl_polynomial_division.default_limits with max_work = 8 }
  in
  let limits = { default_limits with division } in
  match gcd ~limits ~variable:"x" left right with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "shared validation/division work must hit the request budget"

let test_exact_bit_limit () =
  let huge = Z.shift_left Z.one 128 |> Q.of_bigint in
  let left = add (xterm "1" 1) (constant huge) in
  let division =
    { Centl_polynomial_division.default_limits with max_exact_bits = 32 }
  in
  let limits = { default_limits with division } in
  match gcd ~limits ~variable:"x" left one with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "oversized exact input must be refused"

let test_mid_chain_cancellation () =
  let left = add (xterm "1" 9) (add (xterm "2" 4) one) in
  let right = add (xterm "1" 7) (add (xterm "3" 2) one) in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 14
  in
  begin match gcd ~cancelled ~variable:"x" left right with
  | Error Cancelled -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "gcd should cancel after the chain begins"
  end;
  Alcotest.(check bool) "multiple cancellation checkpoints" true (!checks >= 14)

let () =
  Alcotest.run "centl polynomial gcd"
    [
      ( "gcd",
        [
          Alcotest.test_case "common linear factor" `Quick
            test_common_linear_factor;
          Alcotest.test_case "content and sign normalization" `Quick
            test_content_and_sign_normalization;
          Alcotest.test_case "rational coefficients" `Quick
            test_rational_coefficients;
          Alcotest.test_case "coprime" `Quick test_coprime;
          Alcotest.test_case "zero conventions" `Quick test_zero_conventions;
          Alcotest.test_case "mixed variable" `Quick
            test_mixed_variable_rejection;
          Alcotest.test_case "Euclidean step limit" `Quick
            test_euclid_step_limit;
          Alcotest.test_case "shared work limit" `Quick test_shared_work_limit;
          Alcotest.test_case "exact bit limit" `Quick test_exact_bit_limit;
          Alcotest.test_case "mid-chain cancellation" `Quick
            test_mid_chain_cancellation;
        ] );
    ]
