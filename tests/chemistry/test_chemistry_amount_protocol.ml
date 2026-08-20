open Centl_chemistry_amount_protocol
open Yojson.Safe.Util

let unwrap = function
  | Ok json -> json
  | Error json ->
      Alcotest.failf "unexpected amount protocol error: %s"
        (Yojson.Safe.to_string json)

let test_entities_protocol () =
  let json =
    unwrap
      (entities_request ~source_class:Centl_chemistry_amount.Declared_exact "1")
  in
  Alcotest.(check string) "kind" "moles_to_entities"
    (json |> member "kind" |> to_string);
  Alcotest.(check string) "source" "declared_exact"
    (json |> member "source_class" |> to_string);
  Alcotest.(check string) "entities" "602214076000000000000000"
    (json |> member "entities" |> to_string);
  Alcotest.(check bool) "integral" true
    (json |> member "entities_integral" |> to_bool);
  Alcotest.(check string) "N_A source" "CENTL Physics"
    (json |> member "avogadro_constant" |> member "source" |> to_string);
  Alcotest.(check bool) "N_A exact" true
    (json |> member "avogadro_constant" |> member "exact" |> to_bool)

let test_stoich_protocol () =
  let json =
    unwrap
      (stoichiometry_request ~source_class:Centl_chemistry_amount.Measured
         ~reaction_text:"C2H6 + O2 -> CO2 + H2O" ~source_species:"C2H6"
         ~source_moles:"3" ~target_species:"CO2")
  in
  Alcotest.(check string) "kind" "stoichiometric_amount_conversion"
    (json |> member "kind" |> to_string);
  Alcotest.(check string) "source" "measured"
    (json |> member "source_class" |> to_string);
  Alcotest.(check string) "equation"
    "2 C2H6 + 7 O2 -> 4 CO2 + 6 H2O"
    (json |> member "equation" |> to_string);
  Alcotest.(check string) "target moles" "6"
    (json |> member "target_moles" |> to_string);
  Alcotest.(check bool) "nested verification" true
    (json |> member "reaction_evidence" |> member "verified" |> to_bool)

let test_error_protocol () =
  match moles_request "1/2" with
  | Ok json ->
      Alcotest.failf "unexpected success: %s" (Yojson.Safe.to_string json)
  | Error json ->
      Alcotest.(check string) "kind" "chemistry_amount_error"
        (json |> member "kind" |> to_string);
      Alcotest.(check string) "code" "invalid_entity_count"
        (json |> member "code" |> to_string)

let () =
  Alcotest.run "CENTL Chemistry amount protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "entities" `Quick test_entities_protocol;
          Alcotest.test_case "stoichiometry" `Quick test_stoich_protocol;
          Alcotest.test_case "error" `Quick test_error_protocol;
        ] );
    ]
