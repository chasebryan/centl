open Centl_chemistry_protocol
open Yojson.Safe.Util

let unwrap_json = function
  | Ok json -> json
  | Error json ->
      Alcotest.failf "unexpected protocol error: %s" (Yojson.Safe.to_string json)

let test_atoms_json () =
  let json = unwrap_json (atoms_request "Ca(OH)2") in
  Alcotest.(check int) "version" 1 (json |> member "version" |> to_int);
  Alcotest.(check string) "kind" "chemical_formula"
    (json |> member "kind" |> to_string);
  let atoms = json |> member "atoms" |> to_list in
  let pairs =
    List.map
      (fun item ->
        (item |> member "element" |> to_string, item |> member "count" |> to_string))
      atoms
  in
  Alcotest.(check (list (pair string string))) "deterministic atoms"
    [ ("Ca", "1"); ("H", "2"); ("O", "2") ] pairs

let test_balance_json () =
  let json = unwrap_json (balance_request "Fe + O2 -> Fe2O3") in
  Alcotest.(check string) "kind" "balanced_reaction"
    (json |> member "kind" |> to_string);
  Alcotest.(check string) "equation" "4 Fe + 3 O2 -> 2 Fe2O3"
    (json |> member "equation" |> to_string);
  Alcotest.(check bool) "verified" true (json |> member "verified" |> to_bool);
  let reactants =
    json |> member "coefficients" |> member "reactants" |> to_list
    |> List.map to_string
  in
  let products =
    json |> member "coefficients" |> member "products" |> to_list
    |> List.map to_string
  in
  Alcotest.(check (list string)) "reactant coefficients" [ "4"; "3" ] reactants;
  Alcotest.(check (list string)) "product coefficients" [ "2" ] products;
  let evidence = json |> member "stoichiometric_evidence" in
  let elements = evidence |> member "elements" |> to_list |> List.map to_string in
  Alcotest.(check (list string)) "element rows" [ "Fe"; "O" ] elements;
  let rows = evidence |> member "matrix" |> to_list in
  let matrix = List.map (fun row -> row |> to_list |> List.map to_string) rows in
  Alcotest.(check (list (list string))) "exact matrix"
    [ [ "1"; "0"; "-2" ]; [ "0"; "2"; "-3" ] ] matrix

let test_error_json () =
  match balance_request "H2 + O2 -> H2O + H2O2" with
  | Ok json -> Alcotest.failf "unexpected success: %s" (Yojson.Safe.to_string json)
  | Error json ->
      Alcotest.(check string) "kind" "chemistry_error"
        (json |> member "kind" |> to_string);
      Alcotest.(check string) "stable code" "underdetermined_balance"
        (json |> member "code" |> to_string)

let () =
  Alcotest.run "CENTL Chemistry protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "atoms" `Quick test_atoms_json;
          Alcotest.test_case "balance" `Quick test_balance_json;
          Alcotest.test_case "error" `Quick test_error_json;
        ] );
    ]
