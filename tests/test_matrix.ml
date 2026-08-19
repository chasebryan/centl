open Centl_matrix

let q = Q.of_string

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let matrix rows =
  match of_rows (List.map (List.map q) rows) with
  | Ok value -> value
  | Error error -> Alcotest.fail (error_message error)

let vector values = Array.of_list (List.map q values)

let check_matrix message expected actual =
  if not (equal expected actual) then
    Alcotest.fail
      (Printf.sprintf "%s: matrices differ" message)

let expect_error message predicate = function
  | Ok _ -> Alcotest.fail (message ^ ": expected error")
  | Error error ->
      if not (predicate error) then
        Alcotest.fail (message ^ ": unexpected error: " ^ error_message error)

let test_construction_and_indexing () =
  expect_error "empty matrix" (( = ) Empty_matrix) (of_rows []);
  expect_error "empty row" (( = ) Empty_row) (of_rows [ [] ]);
  expect_error "ragged" (( = ) Ragged_rows)
    (of_rows [ [ Q.one ]; [ Q.one; Q.zero ] ]);
  let a = matrix [ [ "1/2"; "2" ]; [ "3"; "4/5" ] ] in
  Alcotest.(check (pair int int)) "dimensions" (2, 2) (dimensions a);
  check_q "indexed value" (q "4/5") (get_exn a 1 1);
  expect_error "index" (( = ) Index_out_of_bounds) (get a 2 0)

let test_basic_arithmetic () =
  let a = matrix [ [ "1"; "2" ]; [ "3"; "4" ] ] in
  let b = matrix [ [ "5"; "6" ]; [ "7"; "8" ] ] in
  let sum =
    match add a b with Ok value -> value | Error error -> Alcotest.fail (error_message error)
  in
  check_matrix "addition" (matrix [ [ "6"; "8" ]; [ "10"; "12" ] ]) sum;
  let product =
    match multiply a b with
    | Ok value -> value
    | Error error -> Alcotest.fail (error_message error)
  in
  check_matrix "multiplication"
    (matrix [ [ "19"; "22" ]; [ "43"; "50" ] ])
    product;
  check_matrix "scalar multiplication"
    (matrix [ [ "1/2"; "1" ]; [ "3/2"; "2" ] ])
    (scale (q "1/2") a);
  check_matrix "transpose" (matrix [ [ "1"; "3" ]; [ "2"; "4" ] ])
    (transpose a);
  begin match trace a with
  | Ok value -> check_q "trace" (q "5") value
  | Error error -> Alcotest.fail (error_message error)
  end;
  let incompatible = matrix [ [ "1"; "2"; "3" ] ] in
  expect_error "addition shape"
    (function Shape_mismatch _ -> true | _ -> false)
    (add a incompatible)

let test_determinant () =
  let a = matrix [ [ "1"; "2" ]; [ "3"; "4" ] ] in
  begin match determinant a with
  | Ok value -> check_q "2x2 determinant" (q "-2") value
  | Error error -> Alcotest.fail (error_message error)
  end;
  let c = matrix [ [ "1"; "2"; "3" ]; [ "0"; "1"; "4" ]; [ "5"; "6"; "0" ] ] in
  begin match determinant c with
  | Ok value -> check_q "3x3 determinant" Q.one value
  | Error error -> Alcotest.fail (error_message error)
  end;
  let b = matrix [ [ "5"; "6" ]; [ "7"; "8" ] ] in
  let ab =
    match multiply a b with Ok value -> value | Error error -> Alcotest.fail (error_message error)
  in
  let det matrix =
    match determinant matrix with
    | Ok value -> value
    | Error error -> Alcotest.fail (error_message error)
  in
  check_q "determinant multiplicative" (Q.mul (det a) (det b)) (det ab)

let test_rref_rank_and_nullspace () =
  let singular = matrix [ [ "1"; "2"; "3" ]; [ "2"; "4"; "6" ] ] in
  let reduced = rref singular in
  check_matrix "rref"
    (matrix [ [ "1"; "2"; "3" ]; [ "0"; "0"; "0" ] ])
    reduced.matrix;
  Alcotest.(check (list int)) "pivot columns" [ 0 ] reduced.pivot_columns;
  Alcotest.(check int) "rank" 1 (rank singular);
  check_matrix "rref idempotent" reduced.matrix (rref reduced.matrix).matrix;
  let basis = nullspace singular in
  Alcotest.(check int) "nullity" 2 (List.length basis);
  let expected = [ vector [ "-2"; "1"; "0" ]; vector [ "-3"; "0"; "1" ] ] in
  List.iter2
    (fun wanted actual ->
      Alcotest.(check bool) "basis vector" true (vector_equal wanted actual);
      match multiply_vector singular actual with
      | Ok product ->
          Alcotest.(check bool) "A*v = 0" true
            (vector_equal (Array.make singular.rows Q.zero) product)
      | Error error -> Alcotest.fail (error_message error))
    expected basis

let test_inverse () =
  let a = matrix [ [ "1"; "2" ]; [ "3"; "4" ] ] in
  let inverse_a =
    match inverse a with
    | Ok value -> value
    | Error error -> Alcotest.fail (error_message error)
  in
  check_matrix "inverse exact"
    (matrix [ [ "-2"; "1" ]; [ "3/2"; "-1/2" ] ])
    inverse_a;
  let product =
    match multiply a inverse_a with
    | Ok value -> value
    | Error error -> Alcotest.fail (error_message error)
  in
  let identity =
    match identity 2 with Ok value -> value | Error error -> Alcotest.fail (error_message error)
  in
  check_matrix "inverse reconstruction" identity product;
  expect_error "singular inverse" (( = ) Singular_matrix)
    (inverse (matrix [ [ "1"; "2" ]; [ "2"; "4" ] ]))

let test_linear_solve () =
  let a = matrix [ [ "1"; "2" ]; [ "3"; "4" ] ] in
  begin match solve a (vector [ "5"; "11" ]) with
  | Ok (Unique solution) ->
      Alcotest.(check bool) "unique solution" true
        (vector_equal (vector [ "1"; "2" ]) solution)
  | Ok _ -> Alcotest.fail "expected unique solution"
  | Error error -> Alcotest.fail (error_message error)
  end;
  let singular = matrix [ [ "1"; "1" ]; [ "2"; "2" ] ] in
  begin match solve singular (vector [ "1"; "3" ]) with
  | Ok No_solution -> ()
  | Ok _ -> Alcotest.fail "expected no solution"
  | Error error -> Alcotest.fail (error_message error)
  end;
  begin match solve singular (vector [ "1"; "2" ]) with
  | Ok (Infinite { particular; nullspace_basis }) ->
      Alcotest.(check bool) "particular" true
        (vector_equal (vector [ "1"; "0" ]) particular);
      Alcotest.(check int) "basis count" 1 (List.length nullspace_basis);
      let basis = List.hd nullspace_basis in
      Alcotest.(check bool) "basis" true
        (vector_equal (vector [ "-1"; "1" ]) basis);
      begin match multiply_vector singular particular with
      | Ok product ->
          Alcotest.(check bool) "particular reconstructs rhs" true
            (vector_equal (vector [ "1"; "2" ]) product)
      | Error error -> Alcotest.fail (error_message error)
      end;
      begin match multiply_vector singular basis with
      | Ok product ->
          Alcotest.(check bool) "basis is null" true
            (vector_equal (vector [ "0"; "0" ]) product)
      | Error error -> Alcotest.fail (error_message error)
      end
  | Ok _ -> Alcotest.fail "expected infinite solution family"
  | Error error -> Alcotest.fail (error_message error)
  end;
  expect_error "rhs shape" (( = ) Right_hand_side_length_mismatch)
    (solve a (vector [ "1" ]))

let () =
  Alcotest.run "centl exact rational matrices"
    [
      ( "matrix",
        [
          Alcotest.test_case "construction and indexing" `Quick
            test_construction_and_indexing;
          Alcotest.test_case "basic arithmetic" `Quick test_basic_arithmetic;
          Alcotest.test_case "determinant" `Quick test_determinant;
          Alcotest.test_case "rref rank nullspace" `Quick
            test_rref_rank_and_nullspace;
          Alcotest.test_case "inverse" `Quick test_inverse;
          Alcotest.test_case "linear solve" `Quick test_linear_solve;
        ] );
    ]
