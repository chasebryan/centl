open Centl_multivariate_polynomial
open Centl_polynomial_division

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_division = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_division.error_message error)

let q_int value = Q.of_int value

let polynomial_of_coefficients coefficients =
  coefficients
  |> List.mapi (fun exponent coefficient ->
         unwrap_poly (term coefficient [ ("x", exponent) ]))
  |> List.fold_left add zero

let synthetic_divide_linear a coefficients =
  match coefficients with
  | [ c0; c1; c2; c3 ] ->
      let q2 = c3 in
      let q1 = Q.add c2 (Q.mul a q2) in
      let q0 = Q.add c1 (Q.mul a q1) in
      let remainder = Q.add c0 (Q.mul a q0) in
      ([ q0; q1; q2 ], remainder)
  | _ -> Alcotest.fail "oracle expects exactly cubic coefficient vectors"

let check_case case a coefficients =
  let dividend = polynomial_of_coefficients coefficients in
  let divisor =
    add (polynomial_of_coefficients [ Q.neg a ])
      (polynomial_of_coefficients [ Q.zero; Q.one ])
  in
  let expected_quotient_coefficients, expected_remainder =
    synthetic_divide_linear a coefficients
  in
  let expected_quotient =
    polynomial_of_coefficients expected_quotient_coefficients
  in
  let expected_remainder = polynomial_of_coefficients [ expected_remainder ] in
  let division = unwrap_division (divide ~variable:"x" dividend divisor) in
  Alcotest.(check bool)
    (Printf.sprintf "oracle quotient case %d" case)
    true (equal expected_quotient division.quotient);
  Alcotest.(check bool)
    (Printf.sprintf "oracle remainder case %d" case)
    true (equal expected_remainder division.remainder)

let test_synthetic_grid () =
  let roots = [ -2; -1; 0; 1; 2 ] in
  let seeds = [ 1; 2; 3; 4; 5 ] in
  let cases = ref 0 in
  List.iter
    (fun root ->
      List.iter
        (fun seed ->
          incr cases;
          let coefficients =
            [
              q_int (seed - 3);
              q_int ((2 * seed) - root);
              q_int (root - seed);
              q_int (seed + 1);
            ]
          in
          check_case !cases (q_int root) coefficients)
        seeds)
    roots;
  Alcotest.(check int) "synthetic cases" 25 !cases

let test_large_exact_factor () =
  let huge = Z.add (Z.shift_left Z.one 4096) (Z.of_int 17) |> Q.of_bigint in
  let quotient =
    add (polynomial_of_coefficients [ Q.one ])
      (polynomial_of_coefficients [ Q.zero; huge ])
  in
  let divisor =
    add (polynomial_of_coefficients [ Q.of_int (-1) ])
      (polynomial_of_coefficients [ Q.zero; Q.one ])
  in
  let dividend = unwrap_poly (multiply divisor quotient) in
  let limits = { default_limits with max_exact_bits = 20_000 } in
  let division =
    unwrap_division (divide ~limits ~variable:"x" dividend divisor)
  in
  Alcotest.(check bool) "large exact quotient" true
    (equal quotient division.quotient);
  Alcotest.(check bool) "large exact remainder" true
    (equal zero division.remainder)

let () =
  Alcotest.run "centl polynomial division oracle"
    [
      ( "oracle",
        [
          Alcotest.test_case "25 synthetic linear divisions" `Quick
            test_synthetic_grid;
          Alcotest.test_case "4096-bit exact factor" `Quick
            test_large_exact_factor;
        ] );
    ]
