open Centl_chemistry_limiting

let unwrap = function
  | Ok value -> value
  | Error error -> Alcotest.failf "unexpected limiting error: %s" (error_message error)

let check_q label expected actual =
  Alcotest.(check string) label expected (Q.to_string actual)

let find_amount species pairs =
  match List.assoc_opt species pairs with
  | Some value -> value
  | None -> Alcotest.failf "missing amount for %s" species

let test_single_limiter () =
  let result =
    unwrap
      (solve ~source_class:Centl_chemistry_amount.Measured
         ~reaction_text:"H2 + O2 -> H2O" [ "H2=3"; "O2=1" ])
  in
  Alcotest.(check string) "equation" "2 H2 + O2 -> 2 H2O"
    (Centl_chemistry.render_balanced result.balanced);
  check_q "extent" "1" result.extent_moles;
  Alcotest.(check (list string)) "limiter" [ "O2" ] result.limiting_species;
  check_q "H2 remaining" "1" (find_amount "H2" result.remaining_reactants);
  check_q "O2 remaining" "0" (find_amount "O2" result.remaining_reactants);
  check_q "H2O theoretical" "2" (find_amount "H2O" result.theoretical_products)

let test_colimiting_tie () =
  let result =
    unwrap (solve ~reaction_text:"H2 + O2 -> H2O" [ "H2=2"; "O2=1" ])
  in
  check_q "extent" "1" result.extent_moles;
  Alcotest.(check (list string)) "co-limiting" [ "H2"; "O2" ]
    result.limiting_species;
  check_q "H2 remaining" "0" (find_amount "H2" result.remaining_reactants);
  check_q "O2 remaining" "0" (find_amount "O2" result.remaining_reactants)

let test_assignment_order_deterministic () =
  let first =
    unwrap (solve ~reaction_text:"H2 + O2 -> H2O" [ "H2=3"; "O2=1" ])
  in
  let second =
    unwrap (solve ~reaction_text:"H2 + O2 -> H2O" [ "O2=1"; "H2=3" ])
  in
  let input_species result = List.map (fun input -> input.species) result.inputs in
  Alcotest.(check (list string)) "canonical input order" [ "H2"; "O2" ]
    (input_species first);
  Alcotest.(check (list string)) "same order" (input_species first)
    (input_species second);
  Alcotest.(check (list (pair string string))) "same leftovers"
    (List.map (fun (s, q) -> (s, Q.to_string q)) first.remaining_reactants)
    (List.map (fun (s, q) -> (s, Q.to_string q)) second.remaining_reactants)

let test_missing_reactant () =
  match solve ~reaction_text:"H2 + O2 -> H2O" [ "H2=2" ] with
  | Error (Missing_reactant_amount "O2") -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "missing reactant was accepted"

let test_extra_reactant () =
  match
    solve ~reaction_text:"H2 + O2 -> H2O"
      [ "H2=2"; "O2=1"; "CH4=1" ]
  with
  | Error (Not_a_reactant "CH4") -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "extra reactant was accepted"

let test_duplicate_assignment () =
  match
    solve ~reaction_text:"H2 + O2 -> H2O" [ "H2=2"; "H2=3"; "O2=1" ]
  with
  | Error (Duplicate_reactant_amount "H2") -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "duplicate reactant amount was accepted"

let () =
  Alcotest.run "CENTL Chemistry limiting reagent"
    [
      ( "solver",
        [
          Alcotest.test_case "single limiter" `Quick test_single_limiter;
          Alcotest.test_case "co-limiting tie" `Quick test_colimiting_tie;
          Alcotest.test_case "assignment order" `Quick
            test_assignment_order_deterministic;
        ] );
      ( "refusals",
        [
          Alcotest.test_case "missing reactant" `Quick test_missing_reactant;
          Alcotest.test_case "extra reactant" `Quick test_extra_reactant;
          Alcotest.test_case "duplicate assignment" `Quick test_duplicate_assignment;
        ] );
    ]
