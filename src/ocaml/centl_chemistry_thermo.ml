type error =
  | Reaction_error of Centl_chemistry.error
  | Invalid_enthalpy of string
  | Missing_enthalpy of string
  | Duplicate_enthalpy of string
  | Negative_temperature_not_relevant

type enthalpy_input = {
  species : string;
  value : Q.t;
  source_class : string;
}

type reaction_enthalpy = {
  equation : string;
  value : Q.t;
  unit : string;
  source_class : string;
  arithmetic_class : string;
  inputs : enthalpy_input list;
  verified : bool;
}

let error_message = function
  | Reaction_error error -> Centl_chemistry.error_message error
  | Invalid_enthalpy text -> Printf.sprintf "invalid enthalpy %S" text
  | Missing_enthalpy species -> "missing enthalpy for species " ^ species
  | Duplicate_enthalpy species -> "duplicate enthalpy for species " ^ species
  | Negative_temperature_not_relevant -> "temperature is not used by this model"

let parse_enthalpy text =
  try
    let value = Q.of_string text in
    if Z.equal (Q.den value) Z.zero then Error (Invalid_enthalpy text)
    else Ok value
  with Invalid_argument _ | Failure _ | Division_by_zero ->
    Error (Invalid_enthalpy text)

let find_unique species inputs =
  match List.filter (fun item -> String.equal item.species species) inputs with
  | [] -> Error (Missing_enthalpy species)
  | [ item ] -> Ok item
  | _ -> Error (Duplicate_enthalpy species)

let calculate ~reaction_text inputs =
  match Centl_chemistry.balance reaction_text with
  | Error error -> Error (Reaction_error error)
  | Ok balanced ->
      let rec check seen = function
        | [] -> Ok ()
        | item :: rest ->
            if List.mem item.species seen then
              Error (Duplicate_enthalpy item.species)
            else check (item.species :: seen) rest
      in
      begin
        match check [] inputs with
        | Error error -> Error error
        | Ok () ->
            let all_species =
              balanced.reaction.reactants @ balanced.reaction.products
            in
            let rec lookup reversed = function
              | [] -> Ok (List.rev reversed)
              | (species : Centl_chemistry.species) :: rest ->
                  begin
                    match find_unique species.formula_text inputs with
                    | Error error -> Error error
                    | Ok item -> lookup (item :: reversed) rest
                  end
            in
            begin
              match lookup [] all_species with
              | Error error -> Error error
              | Ok resolved ->
                  let reactant_count =
                    List.length balanced.reaction.reactants
                  in
                  let rec split count values left =
                    if count = 0 then (List.rev left, values)
                    else
                      match values with
                      | [] -> (List.rev left, [])
                      | value :: rest ->
                          split (count - 1) rest (value :: left)
                  in
                  let reactant_inputs, product_inputs =
                    split reactant_count resolved []
                  in
                  let weighted coefficients values =
                    List.fold_left2
                      (fun total coefficient (item : enthalpy_input) ->
                        Q.add total
                          (Q.mul (Q.of_bigint coefficient) item.value))
                      Q.zero coefficients values
                  in
                  let reactants =
                    weighted balanced.reactant_coefficients reactant_inputs
                  in
                  let products =
                    weighted balanced.product_coefficients product_inputs
                  in
                  Ok
                    {
                      equation = Centl_chemistry.render_balanced balanced;
                      value = Q.sub products reactants;
                      unit = "supplied enthalpy units per balanced reaction";
                      source_class = "derived_from_supplied_data";
                      arithmetic_class = "exact_over_supplied_values";
                      inputs;
                      verified = balanced.verified;
                    }
            end
      end
