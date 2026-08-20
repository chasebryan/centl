open Centl_chemistry_amount

let q_string value = `String (Q.to_string value)
let z_string value = `String (Z.to_string value)

let result_source_class_to_string = function
  | Unspecified -> "derived_from_unspecified"
  | Measured -> "derived_from_measured"
  | Declared_exact -> "derived_exact"

let source_fields source_class =
  [
    ("input_source_class", `String (source_class_to_string source_class));
    ("result_source_class", `String (result_source_class_to_string source_class));
    ("arithmetic_class", `String "exact_over_supplied_values");
  ]

let avogadro_fields value provenance =
  `Assoc
    [
      ("symbol", `String "N_A");
      ("value", q_string value);
      ("unit", `String "1/mol");
      ("source", `String "CENTL Physics");
      ("provenance", `String provenance);
      ("exact", `Bool true);
    ]

let entities_to_yojson conversion =
  `Assoc
    ([
       ("version", `Int 1);
       ("kind", `String "moles_to_entities");
       ("moles", q_string conversion.moles);
       ("moles_unit", `String "mol");
       ("entities", q_string conversion.entities);
       ("entities_integral", `Bool conversion.entities_integral);
       ( "entity_count_status",
         `String
           (if conversion.entities_integral then "integral_count"
            else "nonintegral_mathematical_equivalent") );
       ( "avogadro_constant",
         avogadro_fields conversion.avogadro_value conversion.avogadro_provenance );
     ]
    @ source_fields conversion.source_class)

let moles_to_yojson conversion =
  `Assoc
    ([
       ("version", `Int 1);
       ("kind", `String "entities_to_moles");
       ("entities", z_string conversion.entity_count);
       ("moles", q_string conversion.moles);
       ("moles_unit", `String "mol");
       ( "avogadro_constant",
         avogadro_fields conversion.avogadro_value conversion.avogadro_provenance );
     ]
    @ source_fields conversion.source_class)

let stoichiometry_to_yojson conversion =
  `Assoc
    ([
       ("version", `Int 1);
       ("kind", `String "stoichiometric_amount_conversion");
       ("equation", `String (Centl_chemistry.render_balanced conversion.balanced));
       ("source_species", `String conversion.source_species);
       ("target_species", `String conversion.target_species);
       ("source_coefficient", z_string conversion.source_coefficient);
       ("target_coefficient", z_string conversion.target_coefficient);
       ("source_moles", q_string conversion.source_moles);
       ("target_moles", q_string conversion.target_moles);
       ("unit", `String "mol");
       ( "reaction_evidence",
         Centl_chemistry_protocol.balance_to_yojson conversion.balanced );
     ]
    @ source_fields conversion.source_class)

let error_code = function
  | Invalid_amount _ -> "invalid_amount"
  | Negative_amount -> "negative_amount"
  | Invalid_entity_count _ -> "invalid_entity_count"
  | Negative_entity_count -> "negative_entity_count"
  | Avogadro_constant_unavailable _ -> "avogadro_constant_unavailable"
  | Avogadro_constant_not_exact -> "avogadro_constant_not_exact"
  | Reaction_error _ -> "reaction_error"
  | Species_not_found _ -> "species_not_found"
  | Species_ambiguous _ -> "species_ambiguous"

let error_to_yojson error =
  `Assoc
    [
      ("version", `Int 1);
      ("kind", `String "chemistry_amount_error");
      ("code", `String (error_code error));
      ("error", `String (error_message error));
    ]

let entities_request ?(source_class = Unspecified) text =
  match entities_from_moles_text ~source_class text with
  | Ok conversion -> Ok (entities_to_yojson conversion)
  | Error error -> Error (error_to_yojson error)

let moles_request ?(source_class = Unspecified) text =
  match moles_from_entities_text ~source_class text with
  | Ok conversion -> Ok (moles_to_yojson conversion)
  | Error error -> Error (error_to_yojson error)

let stoichiometry_request ?(source_class = Unspecified) ~reaction_text
    ~source_species ~source_moles ~target_species =
  match
    stoichiometric_moles_text ~source_class ~reaction_text ~source_species
      ~source_moles ~target_species
  with
  | Ok conversion -> Ok (stoichiometry_to_yojson conversion)
  | Error error -> Error (error_to_yojson error)
