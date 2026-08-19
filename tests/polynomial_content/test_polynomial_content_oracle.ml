open Centl_multivariate_polynomial
open Centl_polynomial_content

let q = Q.make

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_content = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_content.error_message error)

let positive_lcm left right =
  let gcd = Z.gcd left right in
  Z.abs (Z.mul (Z.divexact left gcd) right)

let oracle_content coefficients =
  let denominator =
    List.fold_left
      (fun accumulator coefficient -> positive_lcm accumulator (Q.den coefficient))
      Z.one coefficients
  in
  let numerator =
    List.fold_left
      (fun accumulator coefficient ->
        let integerized =
          Z.mul (Q.num coefficient) (Z.divexact denominator (Q.den coefficient))
        in
        Z.gcd accumulator (Z.abs integerized))
      Z.zero coefficients
  in
  Q.make numerator denominator

let build_polynomial coefficients =
  coefficients
  |> List.mapi (fun exponent coefficient ->
         unwrap_poly (term coefficient [ ("x", exponent) ]))
  |> List.fold_left add zero

let check_case case coefficients =
  let polynomial = build_polynomial coefficients in
  let decomposition = unwrap_content (decompose polynomial) in
  let expected = oracle_content coefficients in
  Alcotest.(check string)
    (Printf.sprintf "oracle content case %d" case)
    (Q.to_string expected) (Q.to_string decomposition.content);
  Alcotest.(check bool)
    (Printf.sprintf "reconstruction case %d" case)
    true
    (equal polynomial (scale decomposition.content decomposition.primitive_part));
  let primitive_coefficients =
    bindings decomposition.primitive_part |> List.map snd
  in
  List.iter
    (fun coefficient ->
      Alcotest.(check string) "primitive denominator" "1"
        (Z.to_string (Q.den coefficient)))
    primitive_coefficients;
  let gcd =
    List.fold_left
      (fun accumulator coefficient ->
        Z.gcd accumulator (Z.abs (Q.num coefficient)))
      Z.zero primitive_coefficients
  in
  Alcotest.(check string) "primitive coefficient gcd" "1" (Z.to_string gcd)

let test_oracle_grid () =
  let numerators = [ -7; -3; -1; 1; 2; 5; 11 ] in
  let denominators = [ 1; 2; 3; 5; 7 ] in
  let cases = ref 0 in
  List.iter
    (fun a ->
      List.iter
        (fun b ->
          let d1 = List.nth denominators ((abs a + abs b) mod 5) in
          let d2 = List.nth denominators ((abs (a * 2) + abs b + 1) mod 5) in
          let d3 = List.nth denominators ((abs a + abs (b * 3) + 2) mod 5) in
          let c = if a + b = 0 then 1 else a + b in
          incr cases;
          check_case !cases
            [
              q (Z.of_int a) (Z.of_int d1);
              q (Z.of_int b) (Z.of_int d2);
              q (Z.of_int c) (Z.of_int d3);
            ])
        numerators)
    numerators;
  Alcotest.(check int) "oracle cases" 49 !cases

let test_large_exact_denominators () =
  let p = Z.sub (Z.shift_left Z.one 257) Z.one in
  let r = Z.sub (Z.shift_left Z.one 263) Z.one in
  let coefficients =
    [
      q (Z.of_int 6) p;
      q (Z.of_int (-9)) r;
      q (Z.of_int 15) (Z.mul p r);
    ]
  in
  let polynomial = build_polynomial coefficients in
  let decomposition = unwrap_content (decompose polynomial) in
  Alcotest.(check string) "large exact oracle"
    (Q.to_string (oracle_content coefficients))
    (Q.to_string decomposition.content);
  Alcotest.(check bool) "large exact reconstruction" true
    (equal polynomial (scale decomposition.content decomposition.primitive_part))

let () =
  Alcotest.run "centl polynomial content oracle"
    [
      ( "oracle",
        [
          Alcotest.test_case "49 deterministic rational cases" `Quick
            test_oracle_grid;
          Alcotest.test_case "large exact denominators" `Quick
            test_large_exact_denominators;
        ] );
    ]
