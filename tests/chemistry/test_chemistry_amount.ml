open Centl_chemistry_amount

let unwrap = function
  | Ok value -> value
  | Error error -> Alcotest.failf "unexpected amount error: %s" (error_message error)

let check_q label expected actual =
  Alcotest.(check string) label expected (Q.to_string actual)

let test_one_mole_entities () =
  let result = unwrap (entities_from_moles_text ~source_class:Declared_exact "1") in
  Alcotest.(check string) "source" "declared_exact"
    (source_class_to_string result.source_class);
  check_q "moles" "1" result.moles;
  check_q "entities" "602214076000000000000000" result.entities;
  Alcotest.(check bool) "integral" true result.entities_integral;
  check_q "N_A" "602214076000000000000000" result.avogadro_value;
  Alcotest.(check string) "provenance" "SI defining constant"
    result.avogadro_provenance

let test_avogadro_round_trip () =
  let result =
    unwrap (moles_from_entities_text "602214076000000000000000")
  in
  Alcotest.(check string) "default source" "unspecified"
    (source_class_to_string result.source_class);
  check_q "one mole" "1" result.moles

let test_fractional_mole_entities () =
  let result = unwrap (entities_from_moles_text "1/3") in
  check_q "entities" "602214076000000000000000/3" result.entities;
  Alcotest.(check bool) "not integral" false result.entities_integral

let test_stoichiometric_amount () =
  let result =
    unwrap
      (stoichiometric_moles_text ~source_class:Measured
         ~reaction_text:"C2H6 + O2 -> CO2 + H2O" ~source_species:"C2H6"
         ~source_moles:"3" ~target_species:"CO2")
  in
  Alcotest.(check string) "source" "measured"
    (source_class_to_string result.source_class);
  Alcotest.(check string) "canonical reaction"
    "2 C2H6 + 7 O2 -> 4 CO2 + 6 H2O"
    (Centl_chemistry.render_balanced result.balanced);
  Alcotest.(check string) "source coefficient" "2"
    (Z.to_string result.source_coefficient);
  Alcotest.(check string) "target coefficient" "4"
    (Z.to_string result.target_coefficient);
  check_q "source amount" "3" result.source_moles;
  check_q "target amount" "6" result.target_moles;
  Alcotest.(check bool) "reaction verified" true result.balanced.verified

let test_species_not_found () =
  match
    stoichiometric_moles_text ~reaction_text:"H2 + O2 -> H2O"
      ~source_species:"CH4" ~source_moles:"1" ~target_species:"H2O"
  with
  | Error (Species_not_found "CH4") -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "missing species was accepted"

let test_negative_amount_refusal () =
  match entities_from_moles_text "-1" with
  | Error Negative_amount -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "negative amount was accepted"

let test_noninteger_entity_refusal () =
  match moles_from_entities_text "1/2" with
  | Error (Invalid_entity_count "1/2") -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "noninteger entity count was accepted"

let () =
  Alcotest.run "CENTL Chemistry amount"
    [
      ( "Avogadro",
        [
          Alcotest.test_case "one mole" `Quick test_one_mole_entities;
          Alcotest.test_case "round trip" `Quick test_avogadro_round_trip;
          Alcotest.test_case "fractional mole" `Quick test_fractional_mole_entities;
        ] );
      ( "stoichiometry",
        [
          Alcotest.test_case "amount ratio" `Quick test_stoichiometric_amount;
          Alcotest.test_case "species missing" `Quick test_species_not_found;
        ] );
      ( "refusals",
        [
          Alcotest.test_case "negative amount" `Quick test_negative_amount_refusal;
          Alcotest.test_case "noninteger entities" `Quick
            test_noninteger_entity_refusal;
        ] );
    ]
