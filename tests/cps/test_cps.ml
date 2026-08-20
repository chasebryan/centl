open Centl_cps

let unwrap = function
  | Ok value -> value
  | Error error -> Alcotest.failf "unexpected CPS error: %s" (error_message error)

let check_q label expected actual =
  Alcotest.(check string) label expected (Q.to_string actual)

let find_element element items =
  match List.assoc_opt element items with
  | Some value -> value
  | None -> Alcotest.failf "missing elemental inventory for %s" element

let test_measured_preflight () =
  let result =
    unwrap
      (preflight ~source_class:Centl_chemistry_amount.Measured
         [ "O2=1"; "H2=3" ])
  in
  Alcotest.(check string) "source" "measured"
    (Centl_chemistry_amount.source_class_to_string result.source_class);
  Alcotest.(check int) "species count" 2 (List.length result.species);
  Alcotest.(check (list string)) "canonical species order" [ "H2"; "O2" ]
    (List.map (fun (item : species_input) -> item.formula_text) result.species);
  Alcotest.(check (list string)) "canonical keys" [ "H:2"; "O:2" ]
    (List.map (fun (item : species_input) -> item.composition_key) result.species);
  check_q "total species moles" "4" result.total_species_moles;
  check_q "H atom moles" "6" (find_element "H" result.elemental_moles);
  check_q "O atom moles" "2" (find_element "O" result.elemental_moles);
  let hydrogen = List.hd result.species in
  check_q "H2 entity equivalent" "1806642228000000000000000"
    hydrogen.entity_equivalent;
  Alcotest.(check bool) "H2 entity count integral" true
    hydrogen.entity_equivalent_integral;
  check_q "N_A" "602214076000000000000000" result.avogadro_value;
  Alcotest.(check string) "N_A provenance" "SI defining constant"
    result.avogadro_provenance

let test_assignment_order_deterministic () =
  let first = unwrap (preflight [ "H2=3"; "O2=1" ]) in
  let second = unwrap (preflight [ "O2=1"; "H2=3" ]) in
  let render result =
    List.map
      (fun (item : species_input) ->
        item.composition_key ^ "=" ^ Q.to_string item.moles)
      result.species
  in
  Alcotest.(check (list string)) "canonical replay" (render first) (render second);
  Alcotest.(check (list (pair string string))) "elemental replay"
    (List.map (fun (e, q) -> (e, Q.to_string q)) first.elemental_moles)
    (List.map (fun (e, q) -> (e, Q.to_string q)) second.elemental_moles)

let test_equivalent_formula_duplicate () =
  match preflight [ "H2O=1"; "OH2=1" ] with
  | Error (Duplicate_species "OH2") -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "composition-equivalent duplicate was accepted"

let test_invalid_formula () =
  match preflight [ "Xx2=1" ] with
  | Error (Formula_error ("Xx2", Centl_chemistry.Unknown_element "Xx")) -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "invalid formula was accepted"

let test_negative_amount () =
  match preflight [ "H2=-1" ] with
  | Error (Amount_error ("H2", Centl_chemistry_amount.Negative_amount)) -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "negative CPS amount was accepted"

let test_species_limit () =
  let assignments =
    List.init (max_species + 1) (fun index -> "H=" ^ string_of_int index)
  in
  match preflight assignments with
  | Error Too_many_species -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "oversized CPS composition was accepted"

let () =
  Alcotest.run "CENTL CPS preflight"
    [
      ( "preflight",
        [
          Alcotest.test_case "measured composition" `Quick test_measured_preflight;
          Alcotest.test_case "assignment order" `Quick
            test_assignment_order_deterministic;
        ] );
      ( "refusals",
        [
          Alcotest.test_case "equivalent duplicate" `Quick
            test_equivalent_formula_duplicate;
          Alcotest.test_case "invalid formula" `Quick test_invalid_formula;
          Alcotest.test_case "negative amount" `Quick test_negative_amount;
          Alcotest.test_case "species limit" `Quick test_species_limit;
        ] );
    ]
