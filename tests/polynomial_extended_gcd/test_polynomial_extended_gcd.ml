open Centl_multivariate_polynomial
open Centl_polynomial_extended_gcd

let q text = Q.of_string text

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_extended = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_extended_gcd.error_message error)

let termq coefficient powers = unwrap_poly (term (q coefficient) powers)
let xterm coefficient exponent = termq coefficient [ ("x", exponent) ]

let check_poly message expected actual =
  Alcotest.(check bool) message true (equal expected actual)

let multiply_exn left right =
  match multiply left right with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let bezout_value left right certificate =
  add
    (multiply_exn certificate.left_coefficient left)
    (multiply_exn certificate.right_coefficient right)

let check_certificate message left right expected certificate =
  check_poly (message ^ " gcd") expected certificate.gcd;
  check_poly (message ^ " bezout") expected
    (bezout_value left right certificate)

let test_common_linear_factor () =
  let left = sub (xterm "1" 3) one in
  let right = sub (xterm "1" 2) one in
  let expected = sub (xterm "1" 1) one in
  let certificate = unwrap_extended (extended_gcd ~variable:"x" left right) in
  check_certificate "common factor" left right expected certificate

let test_rational_coefficients () =
  let factor = add (xterm "1" 1) (constant (q "1/2")) in
  let left = scale (q "3/5") (multiply_exn factor (add (xterm "1" 1) one)) in
  let right = scale (q "-7/11") (multiply_exn factor (add (xterm "1" 1) (constant (q "2")))) in
  let certificate = unwrap_extended (extended_gcd ~variable:"x" left right) in
  check_certificate "rational" left right factor certificate

let test_coprime_certificate () =
  let left = add (xterm "1" 2) one in
  let right = add (xterm "1" 1) one in
  let certificate = unwrap_extended (extended_gcd ~variable:"x" left right) in
  check_certificate "coprime" left right one certificate

let test_zero_conventions () =
  let both = unwrap_extended (extended_gcd ~variable:"x" zero zero) in
  check_poly "zero-zero gcd" zero both.gcd;
  check_poly "zero-zero left witness" zero both.left_coefficient;
  check_poly "zero-zero right witness" zero both.right_coefficient;
  let left = scale (q "-2") (add (xterm "1" 1) one) in
  let expected = add (xterm "1" 1) one in
  let left_only = unwrap_extended (extended_gcd ~variable:"x" left zero) in
  check_certificate "left zero partner" left zero expected left_only;
  let right_only = unwrap_extended (extended_gcd ~variable:"x" zero left) in
  check_certificate "right zero partner" zero left expected right_only

let test_mixed_variable_rejection () =
  let left = add (xterm "1" 2) one in
  let right = unwrap_poly (term Q.one [ ("y", 1) ]) in
  match extended_gcd ~variable:"x" left right with
  | Error (Mixed_variable "y") -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "mixed-variable extended gcd input must be rejected"

let test_euclid_step_limit () =
  let left = add (xterm "1" 4) (add (xterm "1" 1) one) in
  let right = add (xterm "1" 3) (add (xterm "1" 1) one) in
  let limits = { default_limits with max_euclid_steps = 1 } in
  match extended_gcd ~limits ~variable:"x" left right with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "extended Euclid must hit max_euclid_steps=1"

let test_shared_work_limit () =
  let left = add (xterm "1" 5) (add (xterm "2" 2) one) in
  let right = add (xterm "1" 4) (add (xterm "3" 1) one) in
  let division =
    { Centl_polynomial_division.default_limits with max_work = 24 }
  in
  let limits = { default_limits with division } in
  match extended_gcd ~limits ~variable:"x" left right with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "remainder and witness work must share one budget"

let test_exact_bit_limit () =
  let huge = Z.shift_left Z.one 128 |> Q.of_bigint in
  let left = add (xterm "1" 1) (constant huge) in
  let division =
    { Centl_polynomial_division.default_limits with max_exact_bits = 32 }
  in
  let limits = { default_limits with division } in
  match extended_gcd ~limits ~variable:"x" left one with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "oversized exact input must be refused"

let test_mid_chain_cancellation () =
  let left = add (xterm "1" 9) (add (xterm "2" 4) one) in
  let right = add (xterm "1" 7) (add (xterm "3" 2) one) in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 20
  in
  begin match extended_gcd ~cancelled ~variable:"x" left right with
  | Error Cancelled -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "extended gcd should cancel after witness work begins"
  end;
  Alcotest.(check bool) "multiple checkpoints" true (!checks >= 20)

let () =
  Alcotest.run "centl polynomial extended gcd"
    [
      ( "extended-gcd",
        [
          Alcotest.test_case "common linear factor" `Quick
            test_common_linear_factor;
          Alcotest.test_case "rational coefficients" `Quick
            test_rational_coefficients;
          Alcotest.test_case "coprime certificate" `Quick
            test_coprime_certificate;
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
