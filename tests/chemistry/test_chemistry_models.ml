let q text = Q.of_string text

let unwrap = function
  | Ok value -> value
  | Error error ->
      Alcotest.fail (Centl_chemistry_models.error_message error)

let test_concentration_and_dilution () =
  let concentration =
    unwrap
      (Centl_chemistry_models.concentration ~moles:(q "1")
         ~volume_l:(q "2"))
  in
  Alcotest.(check string) "concentration" "1/2"
    (Q.to_string concentration.value);
  let dilution =
    unwrap
      (Centl_chemistry_models.dilution ~initial_concentration:(q "1")
         ~initial_volume_l:(q "2") ~final_volume_l:(q "4"))
  in
  Alcotest.(check string) "dilution" "1/2"
    (Q.to_string dilution.final_concentration)

let test_yield () =
  let result =
    unwrap
      (Centl_chemistry_models.theoretical_yield ~actual:(q "3")
         ~theoretical:(q "4"))
  in
  Alcotest.(check string) "percent yield" "75"
    (Q.to_string result.percentage)

let test_model_provenance () =
  let gas =
    unwrap
      (Centl_chemistry_models.ideal_gas_pressure ~moles:(q "1")
         ~temperature_k:(q "273") ~volume_m3:(q "1"))
  in
  let charge =
    unwrap (Centl_chemistry_models.charge_from_electron_moles (q "1"))
  in
  Alcotest.(check string) "gas model" "ideal_gas" gas.gas_model;
  Alcotest.(check bool) "gas positive" true
    (Q.compare gas.pressure_pa Q.zero > 0);
  Alcotest.(check bool) "charge positive" true
    (Q.compare charge.charge_c Q.zero > 0)

let test_refusals () =
  match
    Centl_chemistry_models.concentration ~moles:(q "1") ~volume_l:Q.zero
  with
  | Error (Centl_chemistry_models.Nonpositive_value "volume") -> ()
  | Error error ->
      Alcotest.fail (Centl_chemistry_models.error_message error)
  | Ok _ -> Alcotest.fail "zero-volume concentration was accepted"

let () =
  Alcotest.run "CENTL Chemistry models"
    [
      ( "models",
        [
          Alcotest.test_case "concentration and dilution" `Quick
            test_concentration_and_dilution;
          Alcotest.test_case "yield" `Quick test_yield;
          Alcotest.test_case "model provenance" `Quick test_model_provenance;
          Alcotest.test_case "refusals" `Quick test_refusals;
        ] );
    ]
