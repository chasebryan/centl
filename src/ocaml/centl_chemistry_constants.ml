type error = Physics_error of string

type derived_constant = {
  symbol : string;
  value : Q.t;
  unit : string;
  definition : string;
  provenance : string;
}

let error_message = function
  | Physics_error message -> message

let physical_value symbol unit =
  try
    let constant = Centl_physics.constant symbol in
    if not constant.exact_value then
      Error (Physics_error (symbol ^ " is not marked exact"))
    else Ok (Centl_physics.convert constant.constant_value unit)
  with Centl_physics.Physics_error message ->
    Error (Physics_error message)

let derive symbol value unit definition =
  {
    symbol;
    value;
    unit;
    definition;
    provenance = "derived-exact from CENTL Physics SI defining constants";
  }

let constant symbol =
  match symbol with
  | "R" ->
      begin
        match physical_value "N_A" "1/mol", physical_value "k_B" "J/K" with
        | Ok avogadro, Ok boltzmann ->
            Ok
              (derive "R" (Q.mul avogadro boltzmann) "J/(mol*K)"
                 "R = N_A * k_B")
        | Error error, _ | _, Error error -> Error error
      end
  | "F" ->
      begin
        match physical_value "N_A" "1/mol", physical_value "e" "C" with
        | Ok avogadro, Ok charge ->
            Ok
              (derive "F" (Q.mul avogadro charge) "C/mol"
                 "F = N_A * e")
        | Error error, _ | _, Error error -> Error error
      end
  | _ -> Error (Physics_error ("unsupported chemistry constant: " ^ symbol))
