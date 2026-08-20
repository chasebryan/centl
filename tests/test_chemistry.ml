open Centl_chemistry

let expect_ok = function
  | Ok value -> value
  | Error error -> Alcotest.fail (error_message error)

let test_atoms () =
  Alcotest.(check (list (pair string int))) "nested atoms"
    [("Ca", 1); ("H", 2); ("O", 2)]
    (expect_ok (parse_formula "Ca(OH)2"));
  Alcotest.(check (list (pair string int))) "nested hydrate"
    [("Al", 2); ("O", 12); ("S", 3)]
    (expect_ok (parse_formula "Al2(SO4)3"))

let test_balance () =
  let balanced = expect_ok (balance "Fe + O2 -> Fe2O3") in
  Alcotest.(check (list int)) "iron oxide coefficients"
    [4; 3; 2] balanced.coefficients;
  List.iter (fun evidence ->
    Alcotest.(check int) evidence.element evidence.reactant_atoms
      evidence.product_atoms)
    balanced.evidence;
  let balanced = expect_ok (balance "C2H6 + O2 -> CO2 + H2O") in
  Alcotest.(check (list int)) "combustion coefficients"
    [2; 7; 4; 6] balanced.coefficients

let test_rejections () =
  match parse_formula "Xx2" with
  | Error (Unknown_element "Xx") -> ()
  | _ -> Alcotest.fail "unknown element was accepted";
  match balance "H2 -> H2 + H2" with
  | Error (Duplicate_species "H2") -> ()
  | _ -> Alcotest.fail "duplicate species was accepted"

let () =
  Alcotest.run "centl chemistry"
    [("chemistry",
      [ Alcotest.test_case "formula atom counts" `Quick test_atoms;
        Alcotest.test_case "exact reaction balancing" `Quick test_balance;
        Alcotest.test_case "malformed input rejection" `Quick test_rejections ])]