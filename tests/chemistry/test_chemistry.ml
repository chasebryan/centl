open Centl_chemistry

let unwrap = function
  | Ok value -> value
  | Error error -> Alcotest.failf "unexpected chemistry error: %s" (error_message error)

let check_count formula symbol expected =
  Alcotest.(check string) symbol expected (Z.to_string (atom_count formula symbol))

let test_formula_water () =
  let formula = unwrap (parse_formula "H2O") in
  check_count formula "H" "2";
  check_count formula "O" "1"

let test_formula_nested_group () =
  let formula = unwrap (parse_formula "Ca(OH)2") in
  check_count formula "Ca" "1";
  check_count formula "O" "2";
  check_count formula "H" "2"

let test_formula_deeper_group () =
  let formula = unwrap (parse_formula "Al2(SO4)3") in
  check_count formula "Al" "2";
  check_count formula "S" "3";
  check_count formula "O" "12"

let test_unknown_element () =
  match parse_formula "Xx2" with
  | Error (Unknown_element "Xx") -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "unknown element was accepted"

let test_zero_subscript () =
  match parse_formula "H0" with
  | Error (Invalid_subscript "0") -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "zero subscript was accepted"

let test_unclosed_group () =
  match parse_formula "Ca(OH2" with
  | Error Unclosed_group -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "unclosed group was accepted"

let test_formula_length_limit () =
  let formula = String.make (max_formula_length + 1) 'H' in
  match parse_formula formula with
  | Error Formula_too_long -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "overlong formula was accepted"

let test_subscript_digit_limit () =
  let formula = "H" ^ String.make (max_subscript_digits + 1) '9' in
  match parse_formula formula with
  | Error (Invalid_subscript _) -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "overlong subscript was accepted"

let test_nesting_limit () =
  let depth = max_nesting_depth + 1 in
  let formula = String.make depth '(' ^ "H" ^ String.make depth ')' in
  match parse_formula formula with
  | Error Nesting_too_deep -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "overdeep formula was accepted"

let test_multiple_arrows () =
  match parse_reaction "H2 -> H2 -> H2" with
  | Error Multiple_arrows -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "multiple reaction arrows were accepted"

let check_balance input expected =
  let balanced = unwrap (balance input) in
  Alcotest.(check string) "canonical equation" expected (render_balanced balanced);
  Alcotest.(check bool) "verified" true balanced.verified;
  List.iter
    (fun item ->
      Alcotest.(check bool) ("conserved " ^ item.element) true item.conserved;
      Alcotest.(check string) ("count " ^ item.element)
        (Z.to_string item.reactants) (Z.to_string item.products))
    balanced.conservation

let test_balance_iron_oxide () =
  check_balance "Fe + O2 -> Fe2O3" "4 Fe + 3 O2 -> 2 Fe2O3"

let test_balance_ethane () =
  check_balance "C2H6 + O2 -> CO2 + H2O"
    "2 C2H6 + 7 O2 -> 4 CO2 + 6 H2O"

let test_balance_permanganate_hcl () =
  check_balance "KMnO4 + HCl -> KCl + MnCl2 + H2O + Cl2"
    "2 KMnO4 + 16 HCl -> 2 KCl + 2 MnCl2 + 8 H2O + 5 Cl2"

let test_existing_coefficients_canonicalize () =
  check_balance "8 Fe + 6 O2 -> 4 Fe2O3" "4 Fe + 3 O2 -> 2 Fe2O3"

let test_impossible_balance () =
  match balance "H2 -> O2" with
  | Error Impossible_balance -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok balanced ->
      Alcotest.failf "impossible reaction was balanced as %s" (render_balanced balanced)

let test_underdetermined_balance () =
  match balance "H2 + O2 -> H2O + H2O2" with
  | Error (Underdetermined_balance dimension) ->
      Alcotest.(check int) "nullspace dimension" 2 dimension
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok balanced ->
      Alcotest.failf "underdetermined reaction was admitted as %s"
        (render_balanced balanced)

let test_deterministic_replay () =
  let input = "KMnO4 + HCl -> KCl + MnCl2 + H2O + Cl2" in
  let first = unwrap (balance input) |> render_balanced in
  let second = unwrap (balance input) |> render_balanced in
  Alcotest.(check string) "repeat result" first second

let () =
  Alcotest.run "CENTL Chemistry"
    [
      ( "formula",
        [
          Alcotest.test_case "water" `Quick test_formula_water;
          Alcotest.test_case "nested group" `Quick test_formula_nested_group;
          Alcotest.test_case "deeper group" `Quick test_formula_deeper_group;
          Alcotest.test_case "unknown element refusal" `Quick test_unknown_element;
          Alcotest.test_case "zero subscript refusal" `Quick test_zero_subscript;
          Alcotest.test_case "unclosed group refusal" `Quick test_unclosed_group;
          Alcotest.test_case "formula length limit" `Quick test_formula_length_limit;
          Alcotest.test_case "subscript digit limit" `Quick test_subscript_digit_limit;
          Alcotest.test_case "nesting limit" `Quick test_nesting_limit;
        ] );
      ( "reaction parser",
        [ Alcotest.test_case "multiple arrows" `Quick test_multiple_arrows ] );
      ( "balancing",
        [
          Alcotest.test_case "iron oxide" `Quick test_balance_iron_oxide;
          Alcotest.test_case "ethane combustion" `Quick test_balance_ethane;
          Alcotest.test_case "permanganate hydrochloric acid" `Quick
            test_balance_permanganate_hcl;
          Alcotest.test_case "canonicalize supplied coefficients" `Quick
            test_existing_coefficients_canonicalize;
          Alcotest.test_case "impossible refusal" `Quick test_impossible_balance;
          Alcotest.test_case "underdetermined refusal" `Quick
            test_underdetermined_balance;
          Alcotest.test_case "deterministic replay" `Quick test_deterministic_replay;
        ] );
    ]
