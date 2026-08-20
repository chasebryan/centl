open Centl_chemistry

type provenance = {
  source : string;
  dataset_version : string;
  status : string;
}

type atomic_weight = {
  element : string;
  lower : Q.t;
  upper : Q.t;
  provenance : provenance;
}

type molar_mass = {
  formula : string;
  lower : Q.t;
  upper : Q.t;
  unit : string;
  exact : bool;
  provenance : provenance list;
}

type error =
  | Unsupported_element_data of string
  | Formula_error of Centl_chemistry.error

let error_message = function
  | Unsupported_element_data element ->
      "no versioned standard atomic-weight interval is admitted for " ^ element
  | Formula_error error -> error_message error

let data_source = "IUPAC-CIAAW Standard Atomic Weights 2021"
let data_version = "2021"

let q text = Q.of_string text

let interval element lower upper =
  {
    element;
    lower = q lower;
    upper = q upper;
    provenance =
      {
        source = data_source;
        dataset_version = data_version;
        status = "measured_interval";
      };
  }

let atomic_weight element =
  match element with
  | "H" -> Ok (interval "H" "1.00784" "1.00811")
  | "C" -> Ok (interval "C" "12.0096" "12.0116")
  | "N" -> Ok (interval "N" "14.00643" "14.00728")
  | "O" -> Ok (interval "O" "15.99903" "15.99977")
  | _ -> Error (Unsupported_element_data element)

let molar_mass formula_text =
  match parse_formula formula_text with
  | Error error -> Error (Formula_error error)
  | Ok formula ->
      let bindings = formula_bindings formula in
      let rec accumulate lower upper sources = function
        | [] ->
            Ok
              {
                formula = String.trim formula_text;
                lower;
                upper;
                unit = "g/mol";
                exact = false;
                provenance = List.rev sources;
              }
        | (element, count) :: rest ->
            begin
              match atomic_weight element with
              | Error _ as error -> error
              | Ok weight ->
                  let factor = Q.of_bigint count in
                  accumulate
                    (Q.add lower (Q.mul factor weight.lower))
                    (Q.add upper (Q.mul factor weight.upper))
                    (weight.provenance :: sources) rest
            end
      in
      accumulate Q.zero Q.zero [] bindings
