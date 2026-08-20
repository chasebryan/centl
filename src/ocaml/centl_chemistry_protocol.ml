open Centl_chemistry

let string_z value = `String (Z.to_string value)

let error_to_yojson error =
  `Assoc
    [
      ("version", `Int 1);
      ("kind", `String "chemistry_error");
      ("error", `String (error_message error));
    ]

let atoms_to_yojson ~formula_text formula =
  let atoms =
    formula_bindings formula
    |> List.map (fun (element, count) ->
           `Assoc [ ("element", `String element); ("count", string_z count) ])
  in
  `Assoc
    [
      ("version", `Int 1);
      ("kind", `String "chemical_formula");
      ("formula", `String formula_text);
      ("atoms", `List atoms);
    ]

let conservation_to_yojson item =
  `Assoc
    [
      ("element", `String item.element);
      ("reactants", string_z item.reactants);
      ("products", string_z item.products);
      ("verified", `Bool item.conserved);
    ]

let coefficients_to_yojson balanced =
  `Assoc
    [
      ( "reactants",
        `List (List.map (fun value -> string_z value) balanced.reactant_coefficients) );
      ( "products",
        `List (List.map (fun value -> string_z value) balanced.product_coefficients) );
    ]

let balance_to_yojson balanced =
  `Assoc
    [
      ("version", `Int 1);
      ("kind", `String "balanced_reaction");
      ("equation", `String (render_balanced balanced));
      ("coefficients", coefficients_to_yojson balanced);
      ( "conservation",
        `List (List.map conservation_to_yojson balanced.conservation) );
      ("verified", `Bool balanced.verified);
    ]

let atoms_request text =
  match parse_formula text with
  | Ok formula -> Ok (atoms_to_yojson ~formula_text:(String.trim text) formula)
  | Error error -> Error (error_to_yojson error)

let balance_request text =
  match balance text with
  | Ok balanced -> Ok (balance_to_yojson balanced)
  | Error error -> Error (error_to_yojson error)
