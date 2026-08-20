open Centl_multivariate_polynomial
open Centl_polynomial_square_free

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_factorization = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_square_free.error_message error)

let x = unwrap_poly (variable "x")

let linear_root root = add x (constant (Q.neg root))

let multiply_exn left right =
  match multiply left right with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let power_exn polynomial exponent =
  match power polynomial exponent with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let build unit specifications =
  specifications
  |> List.fold_left
       (fun result (factor, multiplicity) ->
         multiply_exn result (power_exn factor multiplicity))
       (constant unit)

let sorted_expected left multiplicity_left right multiplicity_right =
  if multiplicity_left < multiplicity_right then
    [ (multiplicity_left, left); (multiplicity_right, right) ]
  else [ (multiplicity_right, right); (multiplicity_left, left) ]

let check_case case unit root_left multiplicity_left root_right multiplicity_right =
  let left = linear_root root_left in
  let right = linear_root root_right in
  let polynomial =
    build unit [ (left, multiplicity_left); (right, multiplicity_right) ]
  in
  let result = unwrap_factorization (factorize ~variable:"x" polynomial) in
  Alcotest.(check string)
    (Printf.sprintf "unit case %d" case)
    (Q.to_string unit) (Q.to_string result.unit);
  let expected = sorted_expected left multiplicity_left right multiplicity_right in
  begin match (expected, result.factors) with
  | [ (m1, f1); (m2, f2) ], [ actual1; actual2 ] ->
      Alcotest.(check int)
        (Printf.sprintf "first multiplicity case %d" case)
        m1 actual1.multiplicity;
      Alcotest.(check bool)
        (Printf.sprintf "first factor case %d" case)
        true (equal f1 actual1.polynomial);
      Alcotest.(check int)
        (Printf.sprintf "second multiplicity case %d" case)
        m2 actual2.multiplicity;
      Alcotest.(check bool)
        (Printf.sprintf "second factor case %d" case)
        true (equal f2 actual2.polynomial)
  | _ -> Alcotest.fail "oracle expected exactly two multiplicity groups"
  end

let test_known_multiplicity_grid () =
  let roots = [ -5; -2; 0; 3; 7 ] in
  let seeds = [ 1; 2; 3; 4; 5 ] in
  let cases = ref 0 in
  List.iter
    (fun root ->
      List.iter
        (fun seed ->
          let left_root = Q.of_int root in
          let right_root = Q.of_int (root + seed + 7) in
          let left_multiplicity = 1 + (seed mod 3) in
          let right_multiplicity = 1 + ((seed + 1) mod 3) in
          let unit =
            if seed mod 2 = 0 then Q.of_int (seed + 1)
            else Q.make (Z.of_int (-(seed + 2))) (Z.of_int (seed + 1))
          in
          incr cases;
          check_case !cases unit left_root left_multiplicity right_root
            right_multiplicity)
        seeds)
    roots;
  Alcotest.(check int) "oracle cases" 25 !cases

let test_large_exact_root () =
  let huge = Z.add (Z.shift_left Z.one 4096) (Z.of_int 17) |> Q.of_bigint in
  let large_factor = linear_root huge in
  let small_factor = linear_root (Q.of_int 3) in
  let unit = Q.make (Z.of_int 5) (Z.of_int 7) in
  let polynomial = build unit [ (small_factor, 1); (large_factor, 2) ] in
  let division =
    { Centl_polynomial_division.default_limits with max_exact_bits = 30_000 }
  in
  let limits = { default_limits with division } in
  let result = unwrap_factorization (factorize ~limits ~variable:"x" polynomial) in
  Alcotest.(check string) "large unit" "5/7" (Q.to_string result.unit);
  begin match result.factors with
  | [ first; second ] ->
      Alcotest.(check int) "small multiplicity" 1 first.multiplicity;
      Alcotest.(check bool) "small factor" true (equal small_factor first.polynomial);
      Alcotest.(check int) "large multiplicity" 2 second.multiplicity;
      Alcotest.(check bool) "large factor" true (equal large_factor second.polynomial)
  | _ -> Alcotest.fail "large oracle expected two multiplicity groups"
  end

let () =
  Alcotest.run "centl polynomial square-free oracle"
    [
      ( "oracle",
        [
          Alcotest.test_case "25 known-multiplicity cases" `Quick
            test_known_multiplicity_grid;
          Alcotest.test_case "4096-bit exact root" `Quick test_large_exact_root;
        ] );
    ]
