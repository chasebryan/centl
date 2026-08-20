open Centl_chemistry

let string_z value = `String (Z.to_string value)

let error_code = function
  | Empty_formula -> "empty_formula"
  | Formula_too_long -> "formula_too_long"
  | Nesting_too_deep -> "nesting_too_deep"
  | Unexpected_character _ -> "unexpected_character"
  | Unclosed_group -> "unclosed_group"
  | Empty_group -> "empty_group"
  | Invalid_subscript _ -> "invalid_subscript"
  | Unknown_element _ -> "unknown_element"
  | Empty_species -> "empty_species"
  | Invalid_coefficient _ -> "invalid_coefficient"
  | Reaction_too_long -> "reaction_too_long"
  | Missing_arrow -> "missing_arrow"
  | Multiple_arrows -> "multiple_arrows"
  | Empty_reaction_side _ -> "empty_reaction_side"
  | Too_many_species -> "too_many_species"
  | No_elements -> "no_elements"
  | Impossible_balance -> "impossible_balance"
  | Underdetermined_balance _ -> "underdetermined_balance"
  | Zero_coefficient -> "zero_coefficient"
  | Mixed_sign_coefficients -> "mixed_sign_coefficients"
  | Matrix_failure _ -> "matrix_failure"

let error_to_yojson error =
  `Assoc
    [
      ("version", `Int 1);
      ("kind", `String "chemistry_error");
      ("code", `String (error_code error));
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

let species_column_to_yojson species =
  `Assoc
    [
      ("formula", `String species.formula_text);
      ("input_coefficient", string_z species.input_coefficient);
    ]

let stoichiometric_evidence_to_yojson balanced =
  let elements, matrix = stoichiometric_matrix_exn balanced.reaction in
  let rows =
    Centl_matrix.to_rows matrix
    |> List.map (fun row -> `List (List.map (fun value -> `String (Q.to_string value)) row))
  in
  `Assoc
    [
      ("elements", `List (List.map (fun element -> `String element) elements));
      ( "columns",
        `Assoc
          [
            ( "reactants",
              `List (List.map species_column_to_yojson balanced.reaction.reactants) );
            ( "products",
              `List (List.map species_column_to_yojson balanced.reaction.products) );
          ] );
      ("matrix", `List rows);
      ("sign_convention", `String "reactants_positive_products_negative");
    ]

let balance_to_yojson balanced =
  `Assoc
    [
      ("version", `Int 1);
      ("kind", `String "balanced_reaction");
      ("equation", `String (render_balanced balanced));
      ("coefficients", coefficients_to_yojson balanced);
      ("stoichiometric_evidence", stoichiometric_evidence_to_yojson balanced);
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

