open Centl_multivariate_polynomial
open Centl_polynomial_division

let q text = Q.of_string text

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_division = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_division.error_message error)

let termq coefficient powers = unwrap_poly (term (q coefficient) powers)
let xterm coefficient exponent = termq coefficient [ ("x", exponent) ]

let check_poly message expected actual =
  Alcotest.(check bool) message true (equal expected actual)

let reconstruct divisor division =
  match multiply divisor division.quotient with
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)
  | Ok product -> add product division.remainder

let test_exact_factor_division () =
  let dividend = sub (xterm "1" 3) one in
  let divisor = sub (xterm "1" 1) one in
  let division = unwrap_division (divide ~variable:"x" dividend divisor) in
  let expected = add (xterm "1" 2) (add (xterm "1" 1) one) in
  check_poly "quotient" expected division.quotient;
  check_poly "remainder zero" zero division.remainder;
  check_poly "reconstruction" dividend (reconstruct divisor division)

let test_nonzero_remainder () =
  let dividend = add (xterm "1" 3) (add (xterm "2" 1) one) in
  let divisor = add (xterm "1" 2) one in
  let division = unwrap_division (divide ~variable:"x" dividend divisor) in
  check_poly "quotient x" (xterm "1" 1) division.quotient;
  check_poly "remainder x+1" (add (xterm "1" 1) one) division.remainder;
  check_poly "reconstruction" dividend (reconstruct divisor division)

let test_rational_coefficients () =
  let dividend =
    add (xterm "1/2" 2) (add (xterm "3/4" 1) (constant (q "1")))
  in
  let divisor = add (xterm "1/2" 1) (constant (q "1/4")) in
  let division = unwrap_division (divide ~variable:"x" dividend divisor) in
  check_poly "quotient x+1" (add (xterm "1" 1) one) division.quotient;
  check_poly "remainder 3/4" (constant (q "3/4")) division.remainder;
  check_poly "reconstruction" dividend (reconstruct divisor division)

let test_constant_divisor () =
  let dividend = add (xterm "3" 2) (add (xterm "-5" 1) (constant (q "7"))) in
  let divisor = constant (q "2") in
  let division = unwrap_division (divide ~variable:"x" dividend divisor) in
  check_poly "constant quotient" (scale (q "1/2") dividend) division.quotient;
  check_poly "constant remainder" zero division.remainder

let test_zero_dividend () =
  let divisor = add (xterm "1" 1) one in
  let division = unwrap_division (divide ~variable:"x" zero divisor) in
  check_poly "zero quotient" zero division.quotient;
  check_poly "zero remainder" zero division.remainder

let test_zero_divisor () =
  match divide ~variable:"x" one zero with
  | Error Division_by_zero -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "zero divisor must be rejected"

let test_mixed_variable_rejection () =
  let dividend = add (xterm "1" 2) one in
  let divisor = unwrap_poly (term (q "1") [ ("y", 1) ]) in
  match divide ~variable:"x" dividend divisor with
  | Error (Mixed_variable "y") -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "mixed-variable divisor must be rejected"

let test_step_limit () =
  let dividend = add (xterm "1" 4) one in
  let divisor = add (xterm "1" 1) one in
  let limits = { default_limits with max_steps = 1 } in
  match divide ~limits ~variable:"x" dividend divisor with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "multi-step division must hit max_steps=1"

let test_work_limit () =
  let dividend = add (xterm "1" 3) one in
  let divisor = add (xterm "1" 1) one in
  let limits = { default_limits with max_work = 1 } in
  match divide ~limits ~variable:"x" dividend divisor with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "validation and leading scans must consume work"

let test_exact_bit_limit () =
  let huge = Z.shift_left Z.one 64 |> Q.of_bigint in
  let dividend = constant huge in
  let limits = { default_limits with max_exact_bits = 16 } in
  match divide ~limits ~variable:"x" dividend one with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "oversized exact input must be refused"

let test_mid_work_cancellation () =
  let dividend = add (xterm "1" 12) (add (xterm "3" 7) one) in
  let divisor = add (xterm "1" 2) (add (xterm "1" 1) one) in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 10
  in
  begin match divide ~cancelled ~variable:"x" dividend divisor with
  | Error Cancelled -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "division should cancel after work begins"
  end;
  Alcotest.(check bool) "multiple checkpoints reached" true (!checks >= 10)

let () =
  Alcotest.run "centl polynomial division"
    [
      ( "division",
        [
          Alcotest.test_case "exact factor division" `Quick
            test_exact_factor_division;
          Alcotest.test_case "nonzero remainder" `Quick test_nonzero_remainder;
          Alcotest.test_case "rational coefficients" `Quick
            test_rational_coefficients;
          Alcotest.test_case "constant divisor" `Quick test_constant_divisor;
          Alcotest.test_case "zero dividend" `Quick test_zero_dividend;
          Alcotest.test_case "zero divisor" `Quick test_zero_divisor;
          Alcotest.test_case "mixed variable" `Quick test_mixed_variable_rejection;
          Alcotest.test_case "step limit" `Quick test_step_limit;
          Alcotest.test_case "work limit" `Quick test_work_limit;
          Alcotest.test_case "exact bit limit" `Quick test_exact_bit_limit;
          Alcotest.test_case "mid-work cancellation" `Quick
            test_mid_work_cancellation;
        ] );
    ]
