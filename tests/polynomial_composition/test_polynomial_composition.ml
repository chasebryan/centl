open Centl_multivariate_polynomial
open Centl_polynomial_composition

let q = Q.of_int

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_comp = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_composition.error_message error)

let termi coefficient powers = unwrap_poly (term (q coefficient) powers)
let variable_i name = unwrap_poly (variable name)
let u = variable_i "u"
let v = variable_i "v"
let x = variable_i "x"
let y = variable_i "y"

let check_poly message expected actual =
  Alcotest.(check bool) message true (equal expected actual)

let test_exact_expansion () =
  let source =
    add (termi 3 [ ("x", 2); ("y", 1) ])
      (add (termi (-2) [ ("y", 1) ]) (constant (q 5)))
  in
  let replacement_x = add u one in
  let result =
    unwrap_comp (compose [ ("x", replacement_x); ("y", v) ] source)
  in
  let expected =
    add (termi 3 [ ("u", 2); ("v", 1) ])
      (add (termi 6 [ ("u", 1); ("v", 1) ])
         (add (termi 1 [ ("v", 1) ]) (constant (q 5))))
  in
  check_poly "3*(u+1)^2*v-2*v+5" expected result

let test_simultaneous_not_sequential () =
  let source = sub x y in
  let result = unwrap_comp (compose [ ("x", y); ("y", x) ] source) in
  check_poly "simultaneous x<->y" (sub y x) result

let test_unsubstituted_large_exponent_is_carried () =
  let source = termi 1 [ ("x", 5_000) ] in
  let result = unwrap_comp (compose [ ("y", add u v) ] source) in
  check_poly "unsubstituted x^5000" source result

let test_substituted_power_limit () =
  let source = termi 1 [ ("x", 1_001) ] in
  match compose [ ("x", add u v) ] source with
  | Error (Power_exponent_limit ("x", 1_001)) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "substituted exponent must hit the composition ceiling"

let test_intermediate_term_ceiling () =
  let source = termi 1 [ ("x", 4) ] in
  let limits = { default_limits with max_terms = 4 } in
  match compose ~limits [ ("x", add u v) ] source with
  | Error (Resource_limit _) -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "(u+v)^4 has five terms and must hit max_terms=4"

let test_duplicate_substitution () =
  match compose [ ("x", u); ("x", v) ] x with
  | Error (Duplicate_substitution "x") -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "duplicate polynomial substitution must be refused"

let test_mid_work_cancellation () =
  let source =
    add (termi 1 [ ("x", 12) ]) (termi 1 [ ("y", 8) ])
  in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 8
  in
  begin match compose ~cancelled [ ("x", add u v); ("y", sub u v) ] source with
  | Error Cancelled -> ()
  | Error error -> Alcotest.fail (error_message error)
  | Ok _ -> Alcotest.fail "composition should cancel after work begins"
  end;
  Alcotest.(check bool) "multiple cancellation checkpoints" true (!checks >= 8)

let () =
  Alcotest.run "centl polynomial composition"
    [
      ( "composition",
        [
          Alcotest.test_case "exact expansion" `Quick test_exact_expansion;
          Alcotest.test_case "simultaneous semantics" `Quick
            test_simultaneous_not_sequential;
          Alcotest.test_case "unsubstituted large exponent" `Quick
            test_unsubstituted_large_exponent_is_carried;
          Alcotest.test_case "substituted power limit" `Quick
            test_substituted_power_limit;
          Alcotest.test_case "intermediate term ceiling" `Quick
            test_intermediate_term_ceiling;
          Alcotest.test_case "duplicate substitution" `Quick
            test_duplicate_substitution;
          Alcotest.test_case "mid-work cancellation" `Quick
            test_mid_work_cancellation;
        ] );
    ]
