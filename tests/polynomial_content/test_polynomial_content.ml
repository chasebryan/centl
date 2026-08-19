open Centl_multivariate_polynomial
open Centl_polynomial_content

let q text = Q.of_string text

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_content = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_content.error_message error)

let termq coefficient powers = unwrap_poly (term (q coefficient) powers)

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string (q expected)) (Q.to_string actual)

let check_poly message expected actual =
  Alcotest.(check bool) message true (equal expected actual)

let gcd_of_primitive_coefficients polynomial =
  bindings polynomial
  |> List.fold_left
       (fun gcd (_, coefficient) ->
         if not (Z.equal (Q.den coefficient) Z.one) then
           Alcotest.fail "primitive part must have integer coefficients";
         Z.gcd gcd (Z.abs (Q.num coefficient)))
       Z.zero

let test_exact_decomposition () =
  let polynomial =
    add (termq "6/35" [ ("x", 2) ])
      (add (termq "-9/14" [ ("x", 1); ("y", 1) ])
         (termq "3/10" []))
  in
  let decomposition = unwrap_content (decompose polynomial) in
  check_q "content" "3/70" decomposition.content;
  let expected =
    add (termq "4" [ ("x", 2) ])
      (add (termq "-15" [ ("x", 1); ("y", 1) ]) (termq "7" []))
  in
  check_poly "primitive part" expected decomposition.primitive_part;
  check_poly "reconstruction" polynomial
    (scale decomposition.content decomposition.primitive_part);
  Alcotest.(check string) "primitive gcd" "1"
    (Z.to_string (gcd_of_primitive_coefficients decomposition.primitive_part))

let test_zero_convention () =
  let decomposition = unwrap_content (decompose zero) in
  check_q "content zero" "0" decomposition.content;
  check_poly "primitive zero" zero decomposition.primitive_part

let test_negative_constant_sign () =
  let polynomial = constant (q "-6/35") in
  let decomposition = unwrap_content (decompose polynomial) in
  check_q "positive content" "6/35" decomposition.content;
  check_poly "sign retained by primitive part" (constant (q "-1"))
    decomposition.primitive_part

let test_integral_primitive_input () =
  let polynomial =
    add (termq "2" [ ("x", 1) ])
      (add (termq "3" [ ("y", 1) ]) (termq "5" []))
  in
  let decomposition = unwrap_content (decompose polynomial) in
  check_q "unit content" "1" decomposition.content;
  check_poly "unchanged primitive" polynomial decomposition.primitive_part

let test_term_limit () =
  let polynomial = add (termq "1" [ ("x", 1) ]) (termq "1" [ ("y", 1) ]) in
  let limits = { default_limits with max_terms = 1 } in
  match decompose ~limits polynomial with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "two-term polynomial must hit max_terms=1"

let test_work_limit () =
  let polynomial = add (termq "1/2" [ ("x", 1) ]) (termq "1/3" [ ("y", 1) ]) in
  let limits = { default_limits with max_work = 1 } in
  match decompose ~limits polynomial with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "two-term denominator pass must hit max_work=1"

let test_exact_bit_limit () =
  let polynomial = constant (Q.of_bigint (Z.shift_left Z.one 32)) in
  let limits = { default_limits with max_exact_bits = 16 } in
  match decompose ~limits polynomial with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "oversized exact input must be refused"

let test_mid_work_cancellation () =
  let polynomial =
    add (termq "1/2" [ ("x", 2) ])
      (add (termq "1/3" [ ("y", 2) ]) (termq "1/5" []))
  in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 4
  in
  begin match decompose ~cancelled polynomial with
  | Error Cancelled -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "decomposition should cancel after work begins"
  end;
  Alcotest.(check bool) "multiple checkpoints reached" true (!checks >= 4)

let () =
  Alcotest.run "centl polynomial content"
    [
      ( "content",
        [
          Alcotest.test_case "exact decomposition" `Quick test_exact_decomposition;
          Alcotest.test_case "zero convention" `Quick test_zero_convention;
          Alcotest.test_case "negative constant sign" `Quick
            test_negative_constant_sign;
          Alcotest.test_case "primitive input" `Quick test_integral_primitive_input;
          Alcotest.test_case "term limit" `Quick test_term_limit;
          Alcotest.test_case "work limit" `Quick test_work_limit;
          Alcotest.test_case "exact bit limit" `Quick test_exact_bit_limit;
          Alcotest.test_case "mid-work cancellation" `Quick
            test_mid_work_cancellation;
        ] );
    ]
