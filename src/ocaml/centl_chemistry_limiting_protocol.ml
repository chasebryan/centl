open Centl_chemistry_limiting

let q_string value = `String (Q.to_string value)

let source_fields source_class =
  [
    ( "input_source_class",
      `String (Centl_chemistry_amount.source_class_to_string source_class) );
    ( "result_source_class",
      `String
        (Centl_chemistry_amount_protocol.result_source_class_to_string source_class) );
    ("arithmetic_class", `String "exact_over_supplied_values");
  ]

let amount_pair_to_yojson (species, moles) =
  `Assoc
    [
      ("species", `String species);
      ("moles", q_string moles);
      ("unit", `String "mol");
    ]

let input_to_yojson input =
  `Assoc
    [
      ("species", `String input.species);
      ("moles", q_string input.moles);
      ("unit", `String "mol");
    ]

let result_to_yojson result =
  `Assoc
    ([
       ("version", `Int 1);
       ("kind", `String "limiting_reagent_amount_result");
       ("equation", `String (Centl_chemistry.render_balanced result.balanced));
       ("inputs", `List (List.map input_to_yojson result.inputs));
       ("extent_moles", q_string result.extent_moles);
       ( "limiting_species",
         `List (List.map (fun species -> `String species) result.limiting_species) );
       ("co_limiting", `Bool (List.length result.limiting_species > 1));
       ( "remaining_reactants",
         `List (List.map amount_pair_to_yojson result.remaining_reactants) );
       ( "theoretical_products",
         `List (List.map amount_pair_to_yojson result.theoretical_products) );
       ( "reaction_evidence",
         Centl_chemistry_protocol.balance_to_yojson result.balanced );
       ( "scope",
         `String
           "amount_of_substance_only_no_molar_mass_or_measured_mass_conversion" );
     ]
    @ source_fields result.source_class)

let error_code = function
  | Invalid_assignment _ -> "invalid_assignment"
  | Duplicate_reactant_amount _ -> "duplicate_reactant_amount"
  | Missing_reactant_amount _ -> "missing_reactant_amount"
  | Not_a_reactant _ -> "not_a_reactant"
  | Ambiguous_reactant_formula _ -> "ambiguous_reactant_formula"
  | Amount_error _ -> "amount_error"
  | Reaction_error _ -> "reaction_error"

let error_to_yojson error =
  `Assoc
    [
      ("version", `Int 1);
      ("kind", `String "chemistry_limiting_error");
      ("code", `String (error_code error));
      ("error", `String (error_message error));
    ]

let request ?(source_class = Centl_chemistry_amount.Unspecified) ~reaction_text
    assignments =
  match solve ~source_class ~reaction_text assignments with
  | Ok result -> Ok (result_to_yojson result)
  | Error error -> Error (error_to_yojson error)

