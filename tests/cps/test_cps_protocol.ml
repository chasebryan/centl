open Centl_cps_protocol
open Yojson.Safe.Util

let unwrap = function
  | Ok json -> json
  | Error json ->
      Alcotest.failf "unexpected CPS protocol error: %s"
        (Yojson.Safe.to_string json)

let test_preflight_certificate () =
  let json =
    unwrap
      (request ~source_class:Centl_chemistry_amount.Measured
         [ "O2=1"; "H2=3" ])
  in
  Alcotest.(check string) "kind" "cps_composition_preflight"
    (json |> member "kind" |> to_string);
  Alcotest.(check bool) "validated" true
    (json |> member "composition_validated" |> to_bool);
  Alcotest.(check string) "input source" "measured"
    (json |> member "input_source_class" |> to_string);
  Alcotest.(check string) "result source" "derived_from_measured"
    (json |> member "result_source_class" |> to_string);
  Alcotest.(check string) "arithmetic" "exact_over_supplied_values"
    (json |> member "arithmetic_class" |> to_string);
  let species = json |> member "species" |> to_list in
  Alcotest.(check int) "species count" 2 (List.length species);
  let first = List.hd species in
  Alcotest.(check string) "canonical first formula" "H2"
    (first |> member "formula" |> to_string);
  Alcotest.(check string) "canonical key" "H:2"
    (first |> member "composition_key" |> to_string);
  Alcotest.(check string) "total moles" "4"
    (json |> member "total_species_moles" |> to_string);
  let inventory = json |> member "elemental_inventory" |> to_list in
  let h = List.hd inventory in
  Alcotest.(check string) "first element" "H"
    (h |> member "element" |> to_string);
  Alcotest.(check string) "H atom moles" "6"
    (h |> member "atom_moles" |> to_string);
  Alcotest.(check string) "N_A source" "CENTL Physics"
    (json |> member "avogadro_constant" |> member "source" |> to_string);
  Alcotest.(check string) "reaction model" "not_provided"
    (json |> member "reaction_model" |> member "status" |> to_string);
  Alcotest.(check string) "thermodynamics" "not_evaluated"
    (json |> member "thermodynamics" |> member "status" |> to_string);
  Alcotest.(check string) "kinetics" "not_evaluated"
    (json |> member "kinetics" |> member "status" |> to_string);
  Alcotest.(check string) "phase/pressure" "not_evaluated"
    (json |> member "phase_pressure" |> member "status" |> to_string);
  Alcotest.(check string) "safety evidence" "not_evaluated"
    (json |> member "safety_evidence" |> member "status" |> to_string);
  Alcotest.(check string) "prediction" "not_performed"
    (json |> member "prediction" |> member "status" |> to_string)

let test_duplicate_protocol () =
  match request [ "H2O=1"; "OH2=1" ] with
  | Ok json ->
      Alcotest.failf "unexpected success: %s" (Yojson.Safe.to_string json)
  | Error json ->
      Alcotest.(check string) "kind" "cps_preflight_error"
        (json |> member "kind" |> to_string);
      Alcotest.(check string) "code" "duplicate_species"
        (json |> member "code" |> to_string)

let () =
  Alcotest.run "CENTL CPS preflight protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "certificate" `Quick test_preflight_certificate;
          Alcotest.test_case "duplicate refusal" `Quick test_duplicate_protocol;
        ] );
    ]

