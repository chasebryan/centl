open Centl_chemistry_limiting_protocol
open Yojson.Safe.Util

let unwrap = function
  | Ok json -> json
  | Error json ->
      Alcotest.failf "unexpected limiting protocol error: %s"
        (Yojson.Safe.to_string json)

let test_limiting_protocol () =
  let json =
    unwrap
      (request ~source_class:Centl_chemistry_amount.Measured
         ~reaction_text:"H2 + O2 -> H2O" [ "O2=1"; "H2=3" ])
  in
  Alcotest.(check string) "kind" "limiting_reagent_amount_result"
    (json |> member "kind" |> to_string);
  Alcotest.(check string) "input source" "measured"
    (json |> member "input_source_class" |> to_string);
  Alcotest.(check string) "result source" "derived_from_measured"
    (json |> member "result_source_class" |> to_string);
  Alcotest.(check string) "equation" "2 H2 + O2 -> 2 H2O"
    (json |> member "equation" |> to_string);
  Alcotest.(check string) "extent" "1"
    (json |> member "extent_moles" |> to_string);
  Alcotest.(check (list string)) "limiter" [ "O2" ]
    (json |> member "limiting_species" |> to_list |> List.map to_string);
  Alcotest.(check bool) "not co-limiting" false
    (json |> member "co_limiting" |> to_bool);
  let inputs = json |> member "inputs" |> to_list in
  Alcotest.(check string) "first canonical input" "H2"
    (List.hd inputs |> member "species" |> to_string);
  let products = json |> member "theoretical_products" |> to_list in
  let water = List.hd products in
  Alcotest.(check string) "product" "H2O"
    (water |> member "species" |> to_string);
  Alcotest.(check string) "product moles" "2"
    (water |> member "moles" |> to_string);
  Alcotest.(check bool) "reaction verified" true
    (json |> member "reaction_evidence" |> member "verified" |> to_bool)

let test_colimiting_protocol () =
  let json =
    unwrap (request ~reaction_text:"H2 + O2 -> H2O" [ "H2=2"; "O2=1" ])
  in
  Alcotest.(check bool) "co-limiting" true
    (json |> member "co_limiting" |> to_bool);
  Alcotest.(check (list string)) "limiters" [ "H2"; "O2" ]
    (json |> member "limiting_species" |> to_list |> List.map to_string)

let test_missing_protocol () =
  match request ~reaction_text:"H2 + O2 -> H2O" [ "H2=2" ] with
  | Ok json ->
      Alcotest.failf "unexpected success: %s" (Yojson.Safe.to_string json)
  | Error json ->
      Alcotest.(check string) "kind" "chemistry_limiting_error"
        (json |> member "kind" |> to_string);
      Alcotest.(check string) "code" "missing_reactant_amount"
        (json |> member "code" |> to_string)

let () =
  Alcotest.run "CENTL Chemistry limiting protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "limiter" `Quick test_limiting_protocol;
          Alcotest.test_case "co-limiter" `Quick test_colimiting_protocol;
          Alcotest.test_case "missing" `Quick test_missing_protocol;
        ] );
    ]

