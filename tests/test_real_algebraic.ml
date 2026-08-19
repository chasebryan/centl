open Centl_real_algebraic

let q = Q.of_string
let z = Z.of_int

let unwrap = function
  | Ok value -> value
  | Error error -> Alcotest.fail (error_message error)

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let check_z_array message expected actual =
  Alcotest.(check (array string)) message
    (Array.map Z.to_string expected) (Array.map Z.to_string actual)

let sqrt2_polynomial = [| z (-2); Z.zero; Z.one |]

let multiply_z_polynomials left right =
  if Array.length left = 0 || Array.length right = 0 then [||]
  else
    let result = Array.make (Array.length left + Array.length right - 1) Z.zero in
    Array.iteri
      (fun i left_coefficient ->
        Array.iteri
          (fun j right_coefficient ->
            result.(i + j) <-
              Z.add result.(i + j)
                (Z.mul left_coefficient right_coefficient))
          right)
      left;
    result

let polynomial_with_integer_roots roots =
  List.fold_left
    (fun polynomial root ->
      multiply_z_polynomials polynomial [| Z.neg (z root); Z.one |])
    [| Z.one |] roots

let test_normalization () =
  let normalized =
    unwrap (normalize_integer_polynomial [| z 4; Z.zero; z (-2) |])
  in
  check_z_array "primitive and positive leading"
    [| z (-2); Z.zero; Z.one |] normalized;
  begin match normalize_integer_polynomial [||] with
  | Error Zero_polynomial -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "empty polynomial should fail"
  end;
  begin match normalize_integer_polynomial [| z 7 |] with
  | Error Constant_polynomial -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "constant polynomial should fail"
  end

let test_root_counts () =
  Alcotest.(check int) "sqrt2 positive root" 1
    (unwrap (root_count sqrt2_polynomial (q "1") (q "2")));
  Alcotest.(check int) "sqrt2 negative root" 1
    (unwrap (root_count sqrt2_polynomial (q "-2") (q "-1")));
  Alcotest.(check int) "both sqrt2 roots" 2
    (unwrap (root_count sqrt2_polynomial (q "-2") (q "2")));
  Alcotest.(check int) "no sqrt2 root" 0
    (unwrap (root_count sqrt2_polynomial (q "2") (q "3")))

let test_certificate_admission () =
  let positive =
    unwrap (make ~polynomial:sqrt2_polynomial ~lower:(q "1") ~upper:(q "2"))
  in
  check_z_array "stored normalized polynomial" sqrt2_polynomial positive.polynomial;
  check_q "lower" (q "1") positive.lower;
  check_q "upper" (q "2") positive.upper;
  begin match make ~polynomial:sqrt2_polynomial ~lower:(q "-2") ~upper:(q "2") with
  | Error (Root_count_mismatch 2) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "two-root interval should fail"
  end;
  begin match make ~polynomial:[| z (-1); Z.one |] ~lower:(q "1") ~upper:(q "2") with
  | Error Endpoint_is_root -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "endpoint root should fail"
  end;
  begin match make ~polynomial:[| Z.one; z (-2); Z.one |] ~lower:(q "0") ~upper:(q "2") with
  | Error Non_square_free -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "repeated-root polynomial should fail"
  end

let test_exact_refinement () =
  let certificate =
    unwrap (make ~polynomial:sqrt2_polynomial ~lower:(q "1") ~upper:(q "2"))
  in
  let initial_width = width certificate in
  begin match refine certificate 12 with
  | Rational_root _ -> Alcotest.fail "sqrt2 must not become rational"
  | Isolating_interval refined ->
      Alcotest.(check bool) "width decreased" true
        (Q.compare (width refined) initial_width < 0);
      Alcotest.(check int) "refined interval still isolates one root" 1
        (unwrap (root_count refined.polynomial refined.lower refined.upper));
      Alcotest.(check bool) "positive interval" true
        (Q.compare refined.lower Q.zero > 0)
  end;
  let rational =
    unwrap
      (make ~polynomial:[| z (-3); Z.one |] ~lower:(q "2") ~upper:(q "4"))
  in
  begin match refine_once rational with
  | Rational_root value -> check_q "midpoint exact root" (q "3") value
  | Isolating_interval _ -> Alcotest.fail "expected exact rational midpoint root"
  end

let test_square_free_and_text () =
  Alcotest.(check bool) "sqrt2 square-free" true (is_square_free sqrt2_polynomial);
  Alcotest.(check bool) "repeated root not square-free" false
    (is_square_free [| Z.one; z (-2); Z.one |]);
  let certificate =
    unwrap (make ~polynomial:sqrt2_polynomial ~lower:(q "1") ~upper:(q "2"))
  in
  Alcotest.(check bool) "text nonempty" true (String.length (text certificate) > 0);
  Alcotest.(check bool) "exact bit accounting" true (exact_bits certificate > 0)

let test_sturm_many_distinct_roots () =
  let roots = [ -11; -7; -3; -1; 2; 5; 9; 14 ] in
  let polynomial = polynomial_with_integer_roots roots in
  Alcotest.(check bool) "constructed polynomial square-free" true
    (is_square_free polynomial);
  Alcotest.(check int) "all roots counted" 8
    (unwrap (root_count polynomial (q "-20") (q "20")));
  Alcotest.(check int) "interior roots counted" 3
    (unwrap (root_count polynomial (q "-2") (q "8")));
  Alcotest.(check int) "empty gap counted" 0
    (unwrap (root_count polynomial (q "10") (q "13")));
  let five =
    unwrap (make ~polynomial ~lower:(q "3") ~upper:(q "7"))
  in
  begin match refine_once five with
  | Rational_root root -> check_q "exact midpoint root" (q "5") root
  | Isolating_interval _ -> Alcotest.fail "integer midpoint root must be exact"
  end

let test_sturm_tight_rational_endpoints () =
  let denominator = Z.pow (z 2) 120 in
  let epsilon = Q.make Z.one denominator in
  let lower = Q.add Q.one epsilon in
  let upper = Q.sub (Q.of_int 2) epsilon in
  Alcotest.(check int) "tight rational interval isolates sqrt2" 1
    (unwrap (root_count sqrt2_polynomial lower upper));
  let certificate =
    unwrap (make ~polynomial:sqrt2_polynomial ~lower ~upper)
  in
  begin match refine certificate 32 with
  | Rational_root _ -> Alcotest.fail "sqrt2 remains irrational"
  | Isolating_interval refined ->
      Alcotest.(check int) "tight refinement preserves root" 1
        (unwrap (root_count refined.polynomial refined.lower refined.upper));
      Alcotest.(check bool) "width strictly contracts" true
        (Q.compare (width refined) (width certificate) < 0)
  end

let () =
  Alcotest.run "centl real algebraic root certificates"
    [
      ( "algebraic",
        [
          Alcotest.test_case "normalization" `Quick test_normalization;
          Alcotest.test_case "root counts" `Quick test_root_counts;
          Alcotest.test_case "certificate admission" `Quick test_certificate_admission;
          Alcotest.test_case "exact refinement" `Quick test_exact_refinement;
          Alcotest.test_case "square-free and text" `Quick test_square_free_and_text;
          Alcotest.test_case "many distinct roots" `Quick
            test_sturm_many_distinct_roots;
          Alcotest.test_case "tight rational endpoints" `Quick
            test_sturm_tight_rational_endpoints;
        ] );
    ]
