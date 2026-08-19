open Centl_multivariate_polynomial

let q = Q.of_string

let unwrap = function
  | Ok value -> value
  | Error error -> Alcotest.fail (error_message error)

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let check_poly message expected actual =
  Alcotest.(check bool) message true (equal expected actual)

let x = unwrap (variable "x")
let y = unwrap (variable "y")
let z = unwrap (variable "z")

let termq coefficient powers = unwrap (term (q coefficient) powers)

let test_canonicalization () =
  let combined = termq "3/2" [ ("y", 0); ("x", 1); ("x", 2) ] in
  check_poly "duplicate powers combine" (termq "3/2" [ ("x", 3) ]) combined;
  Alcotest.(check int) "one term" 1 (term_count combined);
  check_poly "zero coefficient disappears" zero
    (unwrap (term Q.zero [ ("x", 99) ]));
  begin match term Q.one [ ("", 1) ] with
  | Error Empty_variable -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "empty variable should fail"
  end;
  begin match term Q.one [ ("x", -1) ] with
  | Error (Negative_exponent ("x", -1)) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "negative exponent should fail"
  end

let test_ring_arithmetic () =
  let x_plus_y = add x y in
  let square = unwrap (power x_plus_y 2) in
  let expected =
    add (termq "1" [ ("x", 2) ])
      (add (termq "2" [ ("x", 1); ("y", 1) ])
         (termq "1" [ ("y", 2) ]))
  in
  check_poly "(x+y)^2" expected square;
  let a = add (scale (q "2") x) (add y (constant (q "3/5"))) in
  let b = sub z (scale (q "7/3") y) in
  let c = add x (constant (q "-2")) in
  check_poly "addition commutative" (add a b) (add b a);
  check_poly "addition associative" (add (add a b) c) (add a (add b c));
  check_poly "multiplication commutative" (unwrap (multiply a b))
    (unwrap (multiply b a));
  check_poly "distributive" (unwrap (multiply a (add b c)))
    (add (unwrap (multiply a b)) (unwrap (multiply a c)))

let test_coefficients_variables_degree () =
  let polynomial =
    add (termq "5/7" [ ("z", 2); ("x", 1) ])
      (add (termq "-3" [ ("y", 4) ]) (constant (q "2")))
  in
  check_q "coefficient" (q "5/7")
    (unwrap (coefficient polynomial [ ("x", 1); ("z", 2) ]));
  check_q "missing coefficient" Q.zero
    (unwrap (coefficient polynomial [ ("x", 9) ]));
  Alcotest.(check (list string)) "variables" [ "x"; "y"; "z" ]
    (variables polynomial);
  begin match total_degree polynomial with
  | Some degree -> Alcotest.(check int) "total degree" 4 degree
  | None -> Alcotest.fail "nonzero polynomial must have a degree"
  end;
  Alcotest.(check bool) "zero degree undefined" true
    (Option.is_none (total_degree zero))

let test_coefficient_array () =
  let polynomial =
    add (constant (q "3"))
      (add (termq "-2" [ ("x", 1) ])
         (add (termq "5/7" [ ("x", 2); ("y", 1) ])
            (termq "11" [ ("y", 1) ])))
  in
  let array = unwrap (coefficient_array ~max_coefficients:64 polynomial) in
  Alcotest.(check (list string)) "canonical variables" [ "x"; "y" ]
    array.variables;
  Alcotest.(check (list int)) "shape" [ 3; 2 ] array.shape;
  let expected = List.map q [ "3"; "11"; "-2"; "0"; "0"; "5/7" ] in
  Alcotest.(check int) "dense length" 6 (Array.length array.coefficients);
  List.iteri
    (fun index expected ->
      check_q (Printf.sprintf "coefficient[%d]" index) expected
        array.coefficients.(index))
    expected;
  let scalar = unwrap (coefficient_array ~max_coefficients:1 (constant (q "9/4"))) in
  Alcotest.(check (list string)) "scalar variables" [] scalar.variables;
  Alcotest.(check (list int)) "scalar shape" [] scalar.shape;
  check_q "scalar coefficient" (q "9/4") scalar.coefficients.(0);
  begin match coefficient_array ~max_coefficients:5 polynomial with
  | Error Dense_coefficient_array_too_large -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "dense coefficient limit should refuse six entries"
  end;
  begin match
    coefficient_array ~cancelled:(fun () -> true) ~max_coefficients:64 polynomial
  with
  | Error Cancelled -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "coefficient-array construction should cancel"
  end

let test_derivative () =
  let polynomial =
    add (termq "1" [ ("x", 2); ("y", 1) ])
      (add (scale (q "3") y) (termq "5/2" [ ("x", 1) ]))
  in
  let derivative_x = unwrap (derivative "x" polynomial) in
  let expected =
    add (termq "2" [ ("x", 1); ("y", 1) ]) (constant (q "5/2"))
  in
  check_poly "partial derivative" expected derivative_x;
  check_poly "absent variable derivative" zero
    (unwrap (derivative "z" polynomial))

let test_rational_substitution () =
  let polynomial =
    add (termq "1" [ ("x", 2); ("y", 1) ])
      (add (termq "3" [ ("y", 1) ])
         (termq "2" [ ("x", 1); ("z", 1) ]))
  in
  let substituted =
    unwrap
      (substitute_rationals
         [ ("x", q "2"); ("z", q "-1/2") ]
         polynomial)
  in
  check_poly "partial rational substitution"
    (add (scale (q "7") y) (constant (q "-2"))) substituted;
  begin match
    substitute_rationals [ ("x", Q.one); ("x", Q.zero) ] polynomial
  with
  | Error (Duplicate_substitution "x") -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "duplicate substitution should fail"
  end

let test_power_boundaries () =
  begin match power zero 0 with
  | Error Undefined_zero_power -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "0^0 should fail"
  end;
  begin match power x (-1) with
  | Error (Negative_power (-1)) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "negative polynomial power should fail"
  end;
  check_poly "x^0" one (unwrap (power x 0));
  check_poly "zero multiplier" zero (unwrap (multiply zero (add x y)))

let test_total_degree_overflow () =
  begin match term Q.one [ ("x", max_int); ("y", 1) ] with
  | Error (Exponent_overflow marker)
    when String.equal marker total_degree_marker ->
      ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "overflowing total degree must be rejected"
  end;
  let huge_x = unwrap (term Q.one [ ("x", max_int) ]) in
  begin match multiply huge_x y with
  | Error (Exponent_overflow marker)
    when String.equal marker total_degree_marker ->
      ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "multiplication must preserve the degree invariant"
  end

let expect_cancelled label = function
  | Error Cancelled -> ()
  | Error error -> Alcotest.fail (label ^ ": " ^ error_message error)
  | Ok _ -> Alcotest.fail (label ^ " should cancel")

let test_cancellation () =
  let polynomial = add (power x 4 |> unwrap) (power y 4 |> unwrap) in
  expect_cancelled "multiply"
    (multiply ~cancelled:(fun () -> true) polynomial polynomial);
  expect_cancelled "power"
    (power ~cancelled:(fun () -> true) (add x y) 8);
  expect_cancelled "derivative"
    (derivative ~cancelled:(fun () -> true) "x" polynomial);
  expect_cancelled "substitution"
    (substitute_rationals ~cancelled:(fun () -> true)
       [ ("x", q "2") ] polynomial)

type oracle_key = int * int * int
type oracle = (oracle_key * Q.t) list

let oracle_add_term key coefficient polynomial =
  let rec loop reversed = function
    | [] ->
        if Q.equal coefficient Q.zero then List.rev reversed
        else List.rev ((key, coefficient) :: reversed)
    | (candidate, existing) :: rest when candidate = key ->
        let combined = Q.add existing coefficient in
        if Q.equal combined Q.zero then List.rev_append reversed rest
        else List.rev_append reversed ((key, combined) :: rest)
    | entry :: rest -> loop (entry :: reversed) rest
  in
  loop [] polynomial

let oracle_multiply left right =
  List.fold_left
    (fun result ((lx, ly, lz), lc) ->
      List.fold_left
        (fun result ((rx, ry, rz), rc) ->
          oracle_add_term (lx + rx, ly + ry, lz + rz) (Q.mul lc rc) result)
        result right)
    [] left

let oracle_sorted polynomial =
  List.sort (fun (left, _) (right, _) -> Stdlib.compare left right) polynomial

let exponent variable monomial =
  match List.assoc_opt variable monomial with None -> 0 | Some value -> value

let centl_as_oracle polynomial =
  bindings polynomial
  |> List.map (fun (monomial, coefficient) ->
         ( ( exponent "x" monomial,
             exponent "y" monomial,
             exponent "z" monomial ),
           coefficient ))
  |> oracle_sorted

let polynomial_of_oracle terms =
  List.fold_left
    (fun polynomial ((x, y, z), coefficient) ->
      let powers =
        [ ("x", x); ("y", y); ("z", z) ]
        |> List.filter (fun (_, exponent) -> exponent <> 0)
      in
      add polynomial (unwrap (term coefficient powers)))
    zero terms

let check_oracle message expected actual =
  let expected = oracle_sorted expected in
  let actual = oracle_sorted actual in
  let render terms =
    terms
    |> List.map (fun ((x, y, z), coefficient) ->
           Printf.sprintf "(%d,%d,%d):%s" x y z (Q.to_string coefficient))
    |> String.concat ";"
  in
  Alcotest.(check string) message (render expected) (render actual)

let test_independent_oracle () =
  let left_oracle =
    [
      ((2, 0, 1), q "3/5");
      ((0, 1, 0), q "-7/3");
      ((0, 0, 0), q "11/13");
      ((1, 1, 0), q "5");
    ]
  in
  let right_oracle =
    [
      ((1, 0, 0), q "2/7");
      ((0, 2, 0), q "3");
      ((0, 0, 1), q "-4/9");
      ((0, 0, 0), q "-1/2");
    ]
  in
  let expected = oracle_multiply left_oracle right_oracle in
  let actual =
    unwrap
      (multiply (polynomial_of_oracle left_oracle)
         (polynomial_of_oracle right_oracle))
  in
  check_oracle "independent sparse multiplication" expected (centl_as_oracle actual);
  let dense = unwrap (coefficient_array ~max_coefficients:256 actual) in
  Alcotest.(check (list string)) "oracle dense variables" [ "x"; "y"; "z" ]
    dense.variables;
  let expected_shape = [ 4; 4; 3 ] in
  Alcotest.(check (list int)) "oracle dense shape" expected_shape dense.shape;
  let expected_dense = Array.make (4 * 4 * 3) Q.zero in
  List.iter
    (fun ((x, y, z), coefficient) ->
      expected_dense.(((x * 4) + y) * 3 + z) <- coefficient)
    expected;
  Array.iteri
    (fun index expected ->
      check_q (Printf.sprintf "oracle dense[%d]" index) expected
        dense.coefficients.(index))
    expected_dense

let () =
  Alcotest.run "centl exact multivariate polynomials"
    [
      ( "polynomial",
        [
          Alcotest.test_case "canonicalization" `Quick test_canonicalization;
          Alcotest.test_case "ring arithmetic" `Quick test_ring_arithmetic;
          Alcotest.test_case "coefficients variables degree" `Quick
            test_coefficients_variables_degree;
          Alcotest.test_case "coefficient array" `Quick test_coefficient_array;
          Alcotest.test_case "derivative" `Quick test_derivative;
          Alcotest.test_case "rational substitution" `Quick
            test_rational_substitution;
          Alcotest.test_case "power boundaries" `Quick test_power_boundaries;
          Alcotest.test_case "total degree overflow" `Quick
            test_total_degree_overflow;
          Alcotest.test_case "cancellation" `Quick test_cancellation;
          Alcotest.test_case "independent oracle" `Quick test_independent_oracle;
        ] );
    ]
