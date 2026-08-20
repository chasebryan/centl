open Centl_chemistry

type error =
  | Invalid_amount of string
  | Negative_amount
  | Invalid_entity_count of string
  | Negative_entity_count
  | Avogadro_constant_unavailable of string
  | Avogadro_constant_not_exact
  | Reaction_error of Centl_chemistry.error
  | Species_not_found of string
  | Species_ambiguous of string

type entity_conversion = {
  moles : Q.t;
  entities : Q.t;
  entities_integral : bool;
  avogadro_value : Q.t;
  avogadro_provenance : string;
}

type mole_conversion = {
  entity_count : Z.t;
  moles : Q.t;
  avogadro_value : Q.t;
  avogadro_provenance : string;
}

type stoichiometric_amount = {
  balanced : balanced_reaction;
  source_species : string;
  target_species : string;
  source_coefficient : Z.t;
  target_coefficient : Z.t;
  source_moles : Q.t;
  target_moles : Q.t;
}

let error_message = function
  | Invalid_amount text -> Printf.sprintf "invalid amount-of-substance value %S" text
  | Negative_amount -> "amount of substance must be non-negative"
  | Invalid_entity_count text ->
      Printf.sprintf "invalid specified-entity count %S (must be an integer)" text
  | Negative_entity_count -> "specified-entity count must be non-negative"
  | Avogadro_constant_unavailable message ->
      "Avogadro constant unavailable from CENTL Physics: " ^ message
  | Avogadro_constant_not_exact ->
      "CENTL Physics Avogadro constant is not marked exact"
  | Reaction_error error -> Centl_chemistry.error_message error
  | Species_not_found formula ->
      Printf.sprintf "species %s does not occur in the balanced reaction" formula
  | Species_ambiguous formula ->
      Printf.sprintf "species %s occurs more than once in the reaction" formula

let parse_nonnegative_q text =
  let value =
    try Ok (Q.of_string text)
    with Invalid_argument _ | Failure _ | Division_by_zero -> Error (Invalid_amount text)
  in
  match value with
  | Error _ as error -> error
  | Ok value when Q.compare value Q.zero < 0 -> Error Negative_amount
  | Ok value -> Ok value

let parse_nonnegative_z text =
  let value =
    try Ok (Z.of_string text) with Invalid_argument _ -> Error (Invalid_entity_count text)
  in
  match value with
  | Error _ as error -> error
  | Ok value when Z.sign value < 0 -> Error Negative_entity_count
  | Ok value -> Ok value

let avogadro () =
  try
    let constant = Centl_physics.constant "N_A" in
    if not constant.exact_value then Error Avogadro_constant_not_exact
    else
      Ok
        ( Centl_physics.convert constant.constant_value "1/mol",
          constant.provenance )
  with Centl_physics.Physics_error message ->
    Error (Avogadro_constant_unavailable message)

let entities_from_moles moles =
  if Q.compare moles Q.zero < 0 then Error Negative_amount
  else
    match avogadro () with
    | Error _ as error -> error
    | Ok (avogadro_value, avogadro_provenance) ->
        let entities = Q.mul moles avogadro_value in
        Ok
          {
            moles;
            entities;
            entities_integral = Z.equal (Q.den entities) Z.one;
            avogadro_value;
            avogadro_provenance;
          }

let entities_from_moles_text text =
  match parse_nonnegative_q text with
  | Error _ as error -> error
  | Ok moles -> entities_from_moles moles

let moles_from_entities entity_count =
  if Z.sign entity_count < 0 then Error Negative_entity_count
  else
    match avogadro () with
    | Error _ as error -> error
    | Ok (avogadro_value, avogadro_provenance) ->
        Ok
          {
            entity_count;
            moles = Q.div (Q.of_bigint entity_count) avogadro_value;
            avogadro_value;
            avogadro_provenance;
          }

let moles_from_entities_text text =
  match parse_nonnegative_z text with
  | Error _ as error -> error
  | Ok count -> moles_from_entities count

let coefficient_matches balanced formula =
  let add_side species coefficients reversed =
    try
      List.fold_left2
        (fun acc item coefficient ->
          if String.equal item.formula_text formula then coefficient :: acc else acc)
        reversed species coefficients
    with Invalid_argument _ -> reversed
  in
  let matches =
    add_side balanced.reaction.reactants balanced.reactant_coefficients []
  in
  add_side balanced.reaction.products balanced.product_coefficients matches

let unique_coefficient balanced formula =
  match coefficient_matches balanced formula with
  | [] -> Error (Species_not_found formula)
  | [ coefficient ] -> Ok coefficient
  | _ -> Error (Species_ambiguous formula)

let stoichiometric_moles ~reaction_text ~source_species ~source_moles
    ~target_species =
  if Q.compare source_moles Q.zero < 0 then Error Negative_amount
  else
    match Centl_chemistry.balance reaction_text with
    | Error error -> Error (Reaction_error error)
    | Ok balanced ->
        begin
          match unique_coefficient balanced source_species with
          | Error _ as error -> error
          | Ok source_coefficient ->
              begin
                match unique_coefficient balanced target_species with
                | Error _ as error -> error
                | Ok target_coefficient ->
                    let ratio =
                      Q.div (Q.of_bigint target_coefficient)
                        (Q.of_bigint source_coefficient)
                    in
                    Ok
                      {
                        balanced;
                        source_species;
                        target_species;
                        source_coefficient;
                        target_coefficient;
                        source_moles;
                        target_moles = Q.mul source_moles ratio;
                      }
              end
        end

let stoichiometric_moles_text ~reaction_text ~source_species ~source_moles
    ~target_species =
  match parse_nonnegative_q source_moles with
  | Error _ as error -> error
  | Ok amount ->
      stoichiometric_moles ~reaction_text ~source_species ~source_moles:amount
        ~target_species
