let q text = Q.of_string text

let test_reaction_enthalpy () =
  let inputs =
    [
      {
        Centl_chemistry_thermo.species = "H2";
        value = q "0";
        source_class = "reference";
      };
      { species = "O2"; value = q "0"; source_class = "reference" };
      { species = "H2O"; value = q "-286"; source_class = "reference" };
    ]
  in
  match
    Centl_chemistry_thermo.calculate ~reaction_text:"H2 + O2 -> H2O" inputs
  with
  | Error error ->
      Alcotest.fail (Centl_chemistry_thermo.error_message error)
  | Ok result ->
      Alcotest.(check string) "balanced equation" "2 H2 + O2 -> 2 H2O"
        result.equation;
      Alcotest.(check string) "delta H" "-572" (Q.to_string result.value);
      Alcotest.(check bool) "reaction verified" true result.verified

let test_missing_data_refusal () =
  let inputs =
    [
      {
        Centl_chemistry_thermo.species = "H2";
        value = q "0";
        source_class = "reference";
      };
    ]
  in
  match
    Centl_chemistry_thermo.calculate ~reaction_text:"H2 + O2 -> H2O" inputs
  with
  | Error (Centl_chemistry_thermo.Missing_enthalpy _) -> ()
  | Error error ->
      Alcotest.fail (Centl_chemistry_thermo.error_message error)
  | Ok _ -> Alcotest.fail "missing thermochemical data was accepted"

let () =
  Alcotest.run "CENTL Chemistry thermochemistry"
    [
      ( "thermochemistry",
        [
          Alcotest.test_case "reaction enthalpy" `Quick test_reaction_enthalpy;
          Alcotest.test_case "missing data refusal" `Quick
            test_missing_data_refusal;
        ] );
    ]
