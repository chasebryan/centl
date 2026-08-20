open Centl_multivariate_polynomial
open Centl_polynomial_gcd

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_gcd = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_gcd.error_message error)

let q_int value = Q.of_int value
let x = unwrap_poly (variable "x")
let x2 = unwrap_poly (power x 2)

let linear constant = add x (constant (q_int constant))

let monic_quadratic a b =
  add x2 (add (scale (q_int a) x) (constant (q_int b)))

let multiply_exn left right = unwrap_poly (multiply left right)

let bezout_witness ~left ~right ~c ~d =
  let denominator = q_int (c - d) in
  let alpha = Q.inv denominator in
  add (scale alpha left) (scale (Q.neg alpha) right)

let divides divisor dividend =
  match Centl_polynomial_division.divide ~variable:"x" dividend divisor with
  | Ok division -> is_zero division.remainder
  | Error error ->
      Alcotest.fail (Centl_polynomial_division.error_message error)

let test_constructed_grid () =
  let quadratic_a = [ -2; -1; 0; 1; 2 ] in
  let seeds = [ 1; 2; 3; 4; 5 ] in
  let cases = ref 0 in
  List.iter
    (fun a ->
      List.iter
        (fun seed ->
          incr cases;
          let g = monic_quadratic a (seed + 2) in
          let c = seed - 3 in
          let d = seed + 4 in
          let left = multiply_exn g (linear c) in
          let right = multiply_exn g (linear d) in
          let actual = unwrap_gcd (gcd ~variable:"x" left right) in
          Alcotest.(check bool)
            (Printf.sprintf "known gcd case %d" !cases)
            true (equal g actual);
          Alcotest.(check bool)
            (Printf.sprintf "gcd divides left case %d" !cases)
            true (divides actual left);
          Alcotest.(check bool)
            (Printf.sprintf "gcd divides right case %d" !cases)
            true (divides actual right);
          let bezout = bezout_witness ~left ~right ~c ~d in
          Alcotest.(check bool)
            (Printf.sprintf "independent Bezout witness case %d" !cases)
            true (equal g bezout))
        seeds)
    quadratic_a;
  Alcotest.(check int) "constructed oracle cases" 25 !cases

let test_large_exact_common_factor () =
  let huge = Z.add (Z.shift_left Z.one 4096) (Z.of_int 29) |> Q.of_bigint in
  let g = add x (constant huge) in
  let left = multiply_exn g (linear 3) in
  let right = multiply_exn g (linear 8) in
  let division_limits =
    {
      Centl_polynomial_division.default_limits with
      max_exact_bits = 40_000;
      max_work = 1_000_000;
    }
  in
  let limits = { default_limits with division = division_limits } in
  let actual = unwrap_gcd (gcd ~limits ~variable:"x" left right) in
  Alcotest.(check bool) "4096-bit exact gcd" true (equal g actual);
  let bezout = bezout_witness ~left ~right ~c:3 ~d:8 in
  Alcotest.(check bool) "4096-bit Bezout witness" true (equal g bezout)

let () =
  Alcotest.run "centl polynomial gcd oracle"
    [
      ( "oracle",
        [
          Alcotest.test_case "25 constructed gcd/Bezout cases" `Quick
            test_constructed_grid;
          Alcotest.test_case "4096-bit exact common factor" `Quick
            test_large_exact_common_factor;
        ] );
    ]
