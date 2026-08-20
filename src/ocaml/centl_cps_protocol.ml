open Centl_cps

let q_string value = `String (Q.to_string value)
let z_string value = `String (Z.to_string value)

let source_fields source_class =
  [
    ( "input_source_class",
      `String (Centl_chemistry_amount.source_class_to_string source_class) );
    ( "result_source_class",
      `String
        (Centl_chemistry_amount_protocol.result_source_class_to_string source_class) );
    ("arithmetic_class", `String "exact_over_supplied_values");
  ]

let atom_to_yojson (element, count) =
  `Assoc [ ("element", `String element); ("count", z_string count) ]

let species_to_yojson item =
  `Assoc
    [
      ("formula", `String item.formula_text);
      ("composition_key", `String item.composition_key);
      ("moles", q_string item.moles);
      ("unit", `String "mol");
      ("atoms_per_entity", `List (List.map atom_to_yojson item.atoms));
      ("entity_equivalent", q_string item.entity_equivalent);
      ("entity_equivalent_integral", `Bool item.entity_equivalent_integral);
      ( "entity_count_status",
        `String
          (if item.entity_equivalent_integral then "integral_count"
           else "nonintegral_mathematical_equivalent") );
    ]

let elemental_moles_to_yojson (element, moles) =
  `Assoc
    [
      ("element", `String element);
      ("atom_moles", q_string moles);
      ("unit", `String "mol");
    ]

let not_evaluated reason =
  `Assoc [ ("status", `String "not_evaluated"); ("reason", `String reason) ]

let not_provided reason =
  `Assoc [ ("status", `String "not_provided"); ("reason", `String reason) ]

let preflight_to_yojson result =
  `Assoc
    ([
       ("version", `Int 1);
       ("kind", `String "cps_composition_preflight");
       ("composition_validated", `Bool true);
       ("species_count", `Int (List.length result.species));
       ("species", `List (List.map species_to_yojson result.species));
       ("total_species_moles", q_string result.total_species_moles);
       ( "elemental_inventory",
         `List (List.map elemental_moles_to_yojson result.elemental_moles) );
       ( "avogadro_constant",
         `Assoc
           [
             ("symbol", `String "N_A");
             ("value", q_string result.avogadro_value);
             ("unit", `String "1/mol");
             ("source", `String "CENTL Physics");
             ("provenance", `String result.avogadro_provenance);
             ("exact", `Bool true);
           ] );
       ( "reaction_model",
         not_provided
           "preflight validates composition only; no reaction or product set was supplied" );
       ( "thermodynamics",
         not_evaluated "no admitted thermodynamic model was invoked" );
       ("kinetics", not_evaluated "no admitted kinetic model was invoked");
       ( "phase_pressure",
         not_evaluated "no admitted phase or pressure model was invoked" );
       ( "safety_evidence",
         not_evaluated "no versioned safety/property evidence source was loaded" );
       ( "measurement_uncertainty",
         not_provided "no measurement uncertainty budget was supplied" );
       ( "prediction",
         `Assoc
           [
             ("status", `String "not_performed");
             ( "reason",
               `String
                 "composition preflight does not infer reactions or physical outcomes" );
           ] );
     ]
    @ source_fields result.source_class)

let error_code = function
  | Empty_composition -> "empty_composition"
  | Too_many_species -> "too_many_species"
  | Invalid_assignment _ -> "invalid_assignment"
  | Duplicate_species _ -> "duplicate_species"
  | Formula_error _ -> "formula_error"
  | Amount_error _ -> "amount_error"

let error_to_yojson error =
  `Assoc
    [
      ("version", `Int 1);
      ("kind", `String "cps_preflight_error");
      ("code", `String (error_code error));
      ("error", `String (error_message error));
    ]

let request ?(source_class = Centl_chemistry_amount.Unspecified) assignments =
  match preflight ~source_class assignments with
  | Ok result -> Ok (preflight_to_yojson result)
  | Error error -> Error (error_to_yojson error)

