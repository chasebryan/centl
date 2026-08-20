module String_map = Map.Make (String)

open Centl_chemistry_amount

type error =
  | Empty_composition
  | Too_many_species
  | Invalid_assignment of string
  | Duplicate_species of string
  | Formula_error of string * Centl_chemistry.error
  | Amount_error of string * Centl_chemistry_amount.error

type species_input = {
  formula_text : string;
  composition_key : string;
  atoms : (string * Z.t) list;
  moles : Q.t;
  entity_equivalent : Q.t;
  entity_equivalent_integral : bool;
}

type preflight = {
  source_class : source_class;
  species : species_input list;
  total_species_moles : Q.t;
  elemental_moles : (string * Q.t) list;
  avogadro_value : Q.t;
  avogadro_provenance : string;
}

let max_species = 128

let error_message = function
  | Empty_composition -> "CPS composition must contain at least one species"
  | Too_many_species -> "CPS composition exceeds the bounded species limit"
  | Invalid_assignment text ->
      Printf.sprintf "invalid CPS composition assignment %S; expected FORMULA=MOLES" text
  | Duplicate_species formula ->
      Printf.sprintf "CPS composition contains duplicate species %s under the current formula model" formula
  | Formula_error (formula, error) ->
      Printf.sprintf "invalid CPS species %s: %s" formula
        (Centl_chemistry.error_message error)
  | Amount_error (formula, error) ->
      Printf.sprintf "invalid CPS amount for %s: %s" formula
        (Centl_chemistry_amount.error_message error)

let composition_key formula =
  Centl_chemistry.formula_bindings formula
  |> List.map (fun (element, count) -> element ^ ":" ^ Z.to_string count)
  |> String.concat ";"

let parse_assignment text =
  match String.split_on_char '=' text with
  | [ raw_formula; raw_moles ] ->
      let formula_text = String.trim raw_formula in
      let moles_text = String.trim raw_moles in
      if formula_text = "" || moles_text = "" then Error (Invalid_assignment text)
      else
        begin
          match Centl_chemistry.parse_formula formula_text with
          | Error error -> Error (Formula_error (formula_text, error))
          | Ok formula ->
              begin
                match Centl_chemistry_amount.parse_nonnegative_q moles_text with
                | Error error -> Error (Amount_error (formula_text, error))
                | Ok moles -> Ok (formula_text, formula, moles)
              end
        end
  | _ -> Error (Invalid_assignment text)

let add_element_moles map element amount =
  let previous =
    match String_map.find_opt element map with
    | Some value -> value
    | None -> Q.zero
  in
  String_map.add element (Q.add previous amount) map

let preflight ?(source_class = Unspecified) assignments =
  if assignments = [] then Error Empty_composition
  else if List.length assignments > max_species then Error Too_many_species
  else
    match Centl_chemistry_amount.avogadro () with
    | Error error -> Error (Amount_error ("N_A", error))
    | Ok (avogadro_value, avogadro_provenance) ->
        let rec build seen reversed total_moles elemental = function
          | [] ->
              let species =
                List.sort
                  (fun left right ->
                    let by_key = String.compare left.composition_key right.composition_key in
                    if by_key <> 0 then by_key
                    else String.compare left.formula_text right.formula_text)
                  reversed
              in
              Ok
                {
                  source_class;
                  species;
                  total_species_moles = total_moles;
                  elemental_moles = String_map.bindings elemental;
                  avogadro_value;
                  avogadro_provenance;
                }
          | assignment :: rest ->
              begin
                match parse_assignment assignment with
                | Error _ as error -> error
                | Ok (formula_text, formula, moles) ->
                    let key = composition_key formula in
                    if String_map.mem key seen then Error (Duplicate_species formula_text)
                    else
                      let atoms = Centl_chemistry.formula_bindings formula in
                      let elemental =
                        List.fold_left
                          (fun map (element, count) ->
                            let amount = Q.mul moles (Q.of_bigint count) in
                            add_element_moles map element amount)
                          elemental atoms
                      in
                      let entity_equivalent = Q.mul moles avogadro_value in
                      let item =
                        {
                          formula_text;
                          composition_key = key;
                          atoms;
                          moles;
                          entity_equivalent;
                          entity_equivalent_integral =
                            Z.equal (Q.den entity_equivalent) Z.one;
                        }
                      in
                      build (String_map.add key Q.zero seen) (item :: reversed)
                        (Q.add total_moles moles) elemental rest
              end
        in
        build String_map.empty [] Q.zero String_map.empty assignments
