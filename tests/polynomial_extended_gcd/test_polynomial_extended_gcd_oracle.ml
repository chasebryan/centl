open Centl_multivariate_polynomial
open Centl_polynomial_extended_gcd

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_extended = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_extended_gcd.error_message error)

let multiply_exn left right =
  match multiply left right with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let linear scalar =
  add (unwrap_poly (term Q.one [ ("x", 1) ])) (constant scalar)

let bezout_value left right certificate =
  add
    (multiply_exn certificate.left_coefficient left)
    (multiply_exn certificate.right_coefficient right)

let independent_witness c d left right =
  let alpha = Q.inv (Q.sub c d) in
  add (scale alpha left) (scale (Q.neg alpha) right)

let check_case case g c d =
  let left = multiply_exn g (linear c) in
  let right = multiply_exn g (linear d) in
  let oracle = independent_witness c d left right in
  Alcotest.(check bool)
    (Printf.sprintf "independent witness case %d" case)
    true (equal g oracle);
  let certificate = unwrap_extended (extended_gcd ~variable:"x" left right) in
  Alcotest.(check bool)
    (Printf.sprintf "gcd case %d" case)
    true (equal g certificate.gcd);
  Alcotest.(check bool)
    (Printf.sprintf "returned bezout case %d" case)
    true (equal g (bezout_value left right certificate))

let test_known_factor_grid () =
  let common_constants = [ -3; -1; 0; 2; 5 ] in
  let seeds = [ 1; 2; 3; 4; 5 ] in
  let cases = ref 0 in
  List.iter
    (fun common ->
      let g = linear (Q.of_int common) in
      List.iter
        (fun seed ->
          let c = Q.of_int (seed + 1) in
          let d = Q.of_int (seed + 7) in
          incr cases;
          check_case !cases g c d)
        seeds)
    common_constants;
  Alcotest.(check int) "oracle cases" 25 !cases

let test_large_exact_certificate () =
  let huge = Z.add (Z.shift_left Z.one 4096) (Z.of_int 17) |> Q.of_bigint in
  let g = linear huge in
  let c = Q.of_int 3 in
  let d = Q.of_int 8 in
  let left = multiply_exn g (linear c) in
  let right = multiply_exn g (linear d) in
  Alcotest.(check bool) "large independent witness" true
    (equal g (independent_witness c d left right));
  let division =
    { Centl_polynomial_division.default_limits with max_exact_bits = 20_000 }
  in
  let limits = { default_limits with division } in
  let certificate =
    unwrap_extended (extended_gcd ~limits ~variable:"x" left right)
  in
  Alcotest.(check bool) "large gcd" true (equal g certificate.gcd);
  Alcotest.(check bool) "large returned bezout" true
    (equal g (bezout_value left right certificate))

let () =
  Alcotest.run "centl polynomial extended gcd oracle"
    [
      ( "oracle",
        [
          Alcotest.test_case "25 known-factor certificates" `Quick
            test_known_factor_grid;
          Alcotest.test_case "4096-bit exact certificate" `Quick
            test_large_exact_certificate;
        ] );
    ]
