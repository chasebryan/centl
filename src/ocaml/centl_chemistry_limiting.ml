module String_map = Map.Make (String)

open Centl_chemistry
open Centl_chemistry_amount

type error =
  | Invalid_assignment of string
  | Duplicate_reactant_amount of string
  | Missing_reactant_amount of string
  | Not_a_reactant of string
  | Ambiguous_reactant_formula of string
  | Amount_error of Centl_chemistry_amount.error
  | Reaction_error of Centl_chemistry.error

type reactant_input = { species : string; moles : Q.t }

type limiting_result = {
  source_class : source_class;
  balanced : balanced_reaction;
  inputs : reactant_input list;
  extent_moles : Q.t;
  limiting_species : string list;
  remaining_reactants : (string * Q.t) list;
  theoretical_products : (string * Q.t) list;
}

let error_message = function
  | Invalid_assignment text ->
      Printf.sprintf "invalid reactant amount assignment %S; expected FORMULA=MOLES" text
  | Duplicate_reactant_amount species ->
      Printf.sprintf "reactant amount supplied more than once for %s" species
  | Missing_reactant_amount species ->
      Printf.sprintf "missing reactant amount for %s" species
  | Not_a_reactant species ->
      Printf.sprintf "%s is not a reactant in the balanced reaction" species
  | Ambiguous_reactant_formula species ->
      Printf.sprintf "reactant formula %s occurs more than once in the reaction" species
  | Amount_error error -> Centl_chemistry_amount.error_message error
  | Reaction_error error -> Centl_chemistry.error_message error

let parse_assignment text =
  match String.split_on_char '=' text with
  | [ raw_species; raw_amount ] ->
      let species = String.trim raw_species in
      let amount_text = String.trim raw_amount in
      if species = "" || amount_text = "" then Error (Invalid_assignment text)
      else
        begin
          match Centl_chemistry_amount.parse_nonnegative_q amount_text with
          | Error error -> Error (Amount_error error)
          | Ok moles -> Ok { species; moles }
        end
  | _ -> Error (Invalid_assignment text)

let parse_assignments texts =
  let rec loop map reversed = function
    | [] -> Ok (map, List.rev reversed)
    | text :: rest ->
        begin
          match parse_assignment text with
          | Error _ as error -> error
          | Ok input ->
              if String_map.mem input.species map then
                Error (Duplicate_reactant_amount input.species)
              else
                loop (String_map.add input.species input.moles map)
                  (input :: reversed) rest
        end
  in
  loop String_map.empty [] texts

let reactant_coefficients balanced =
  try
    Ok
      (List.map2
         (fun species coefficient -> (species.formula_text, coefficient))
         balanced.reaction.reactants balanced.reactant_coefficients)
  with Invalid_argument _ ->
    Error (Reaction_error (Matrix_failure "reactant coefficient length mismatch"))

let ensure_unique_reactant_formulas pairs =
  let rec loop seen = function
    | [] -> Ok ()
    | (species, _) :: rest ->
        if String_map.mem species seen then Error (Ambiguous_reactant_formula species)
        else loop (String_map.add species Q.zero seen) rest
  in
  loop String_map.empty pairs

let validate_assignments expected supplied =
  let expected_map =
    List.fold_left
      (fun map (species, _) -> String_map.add species true map)
      String_map.empty expected
  in
  let extra =
    String_map.bindings supplied
    |> List.find_opt (fun (species, _) -> not (String_map.mem species expected_map))
  in
  match extra with
  | Some (species, _) -> Error (Not_a_reactant species)
  | None ->
      begin
        match List.find_opt (fun (species, _) -> not (String_map.mem species supplied)) expected with
        | Some (species, _) -> Error (Missing_reactant_amount species)
        | None -> Ok ()
      end

let minimum values =
  match values with
  | [] -> invalid_arg "minimum"
  | first :: rest ->
      List.fold_left (fun current value -> if Q.compare value current < 0 then value else current) first rest

let solve ?(source_class = Unspecified) ~reaction_text assignments =
  match Centl_chemistry.balance reaction_text with
  | Error error -> Error (Reaction_error error)
  | Ok balanced ->
      begin
        match reactant_coefficients balanced with
        | Error _ as error -> error
        | Ok coefficients ->
            begin
              match ensure_unique_reactant_formulas coefficients with
              | Error _ as error -> error
              | Ok () ->
                  begin
                    match parse_assignments assignments with
                    | Error _ as error -> error
                    | Ok (supplied, inputs) ->
                        begin
                          match validate_assignments coefficients supplied with
                          | Error _ as error -> error
                          | Ok () ->
                              let candidate_extents =
                                List.map
                                  (fun (species, coefficient) ->
                                    let amount = String_map.find species supplied in
                                    ( species,
                                      Q.div amount (Q.of_bigint coefficient) ))
                                  coefficients
                              in
                              let extent_moles =
                                minimum (List.map snd candidate_extents)
                              in
                              let limiting_species =
                                candidate_extents
                                |> List.filter_map (fun (species, extent) ->
                                       if Q.equal extent extent_moles then Some species
                                       else None)
                              in
                              let remaining_reactants =
                                List.map
                                  (fun (species, coefficient) ->
                                    let initial = String_map.find species supplied in
                                    let consumed =
                                      Q.mul (Q.of_bigint coefficient) extent_moles
                                    in
                                    (species, Q.sub initial consumed))
                                  coefficients
                              in
                              let theoretical_products =
                                try
                                  List.map2
                                    (fun species coefficient ->
                                      ( species.formula_text,
                                        Q.mul (Q.of_bigint coefficient) extent_moles ))
                                    balanced.reaction.products
                                    balanced.product_coefficients
                                with Invalid_argument _ ->
                                  raise
                                    (Chemistry_error
                                       (Matrix_failure
                                          "product coefficient length mismatch"))
                              in
                              Ok
                                {
                                  source_class;
                                  balanced;
                                  inputs;
                                  extent_moles;
                                  limiting_species;
                                  remaining_reactants;
                                  theoretical_products;
                                }
                        end
                  end
            end
      end
