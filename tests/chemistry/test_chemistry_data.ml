let unwrap = function
  | Ok value -> value
  | Error error ->
      Alcotest.fail (Centl_chemistry_data.error_message error)

let test_water_interval () =
  let result = unwrap (Centl_chemistry_data.molar_mass "H2O") in
  Alcotest.(check string) "lower bound" "1801471/100000"
    (Q.to_string result.lower);
  Alcotest.(check string) "upper bound" "1801599/100000"
    (Q.to_string result.upper);
  Alcotest.(check bool) "not exact" false result.exact;
  Alcotest.(check string) "dataset version" "2021"
    (List.hd result.provenance).dataset_version

let test_unsupported_data_refusal () =
  match Centl_chemistry_data.molar_mass "NaCl" with
  | Error (Centl_chemistry_data.Unsupported_element_data _) -> ()
  | Error error ->
      Alcotest.fail (Centl_chemistry_data.error_message error)
  | Ok _ -> Alcotest.fail "unsupported atomic-weight data was accepted"

let () =
  Alcotest.run "CENTL Chemistry data"
    [
      ( "molar mass",
        [
          Alcotest.test_case "water interval" `Quick test_water_interval;
          Alcotest.test_case "unsupported refusal" `Quick
            test_unsupported_data_refusal;
        ] );
    ]
