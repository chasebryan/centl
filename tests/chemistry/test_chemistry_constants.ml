let unwrap = function
  | Ok value -> value
  | Error error ->
      Alcotest.fail (Centl_chemistry_constants.error_message error)

let test_derived_constants () =
  let gas = unwrap (Centl_chemistry_constants.constant "R") in
  let faraday = unwrap (Centl_chemistry_constants.constant "F") in
  Alcotest.(check string) "gas definition" "R = N_A * k_B" gas.definition;
  Alcotest.(check string) "faraday definition" "F = N_A * e"
    faraday.definition;
  Alcotest.(check bool) "gas is positive" true
    (Q.compare gas.value Q.zero > 0);
  Alcotest.(check bool) "faraday is positive" true
    (Q.compare faraday.value Q.zero > 0);
  Alcotest.(check bool) "gas provenance" true
    (String.length gas.provenance > 0)

let test_unsupported_constant () =
  match Centl_chemistry_constants.constant "c" with
  | Error _ -> ()
  | Ok _ -> Alcotest.fail "unsupported chemistry constant was accepted"

let () =
  Alcotest.run "CENTL Chemistry constants"
    [
      ( "constants",
        [
          Alcotest.test_case "derived constants" `Quick test_derived_constants;
          Alcotest.test_case "unsupported refusal" `Quick
            test_unsupported_constant;
        ] );
    ]
