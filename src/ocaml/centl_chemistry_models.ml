type error =
  | Invalid_value of string
  | Nonpositive_value of string
  | Constant_error of Centl_chemistry_constants.error

type concentration = {
  moles : Q.t;
  volume_l : Q.t;
  value : Q.t;
  unit : string;
  arithmetic_class : string;
}

type dilution = {
  initial_concentration : Q.t;
  initial_volume_l : Q.t;
  final_volume_l : Q.t;
  final_concentration : Q.t;
  unit : string;
  arithmetic_class : string;
}

type percent_yield = {
  actual : Q.t;
  theoretical : Q.t;
  percentage : Q.t;
  unit : string;
  arithmetic_class : string;
}

type ideal_gas_pressure = {
  moles : Q.t;
  temperature_k : Q.t;
  volume_m3 : Q.t;
  pressure_pa : Q.t;
  gas_model : string;
  constant_provenance : string;
}

type electrochemical_charge = {
  electron_moles : Q.t;
  charge_c : Q.t;
  constant_provenance : string;
}

let error_message = function
  | Invalid_value text -> "invalid chemistry value: " ^ text
  | Nonpositive_value name -> name ^ " must be positive"
  | Constant_error error ->
      Centl_chemistry_constants.error_message error

let nonnegative name value =
  if Z.equal (Q.den value) Z.zero then Error (Invalid_value (name ^ " is not finite"))
  else if Q.compare value Q.zero < 0 then Error (Invalid_value (name ^ " < 0"))
  else Ok ()

let positive name value =
  if Q.compare value Q.zero <= 0 then Error (Nonpositive_value name)
  else Ok ()

let concentration ~moles ~volume_l =
  match nonnegative "moles" moles, positive "volume" volume_l with
  | Ok (), Ok () ->
      Ok
        {
          moles;
          volume_l;
          value = Q.div moles volume_l;
          unit = "mol/L";
          arithmetic_class = "exact_over_supplied_values";
        }
  | Error error, _ | _, Error error -> Error error

let dilution ~initial_concentration ~initial_volume_l ~final_volume_l =
  match
    nonnegative "initial concentration" initial_concentration,
    positive "initial volume" initial_volume_l,
    positive "final volume" final_volume_l
  with
  | Ok (), Ok (), Ok () ->
      Ok
        {
          initial_concentration;
          initial_volume_l;
          final_volume_l;
          final_concentration =
            Q.div
              (Q.mul initial_concentration initial_volume_l)
              final_volume_l;
          unit = "mol/L";
          arithmetic_class = "exact_over_supplied_values";
        }
  | Error error, _, _ | _, Error error, _ | _, _, Error error ->
      Error error

let theoretical_yield ~actual ~theoretical =
  match nonnegative "actual yield" actual, positive "theoretical yield" theoretical with
  | Ok (), Ok () ->
      Ok
        {
          actual;
          theoretical;
          percentage = Q.mul (Q.of_int 100) (Q.div actual theoretical);
          unit = "%";
          arithmetic_class = "exact_over_supplied_values";
        }
  | Error error, _ | _, Error error -> Error error

let ideal_gas_pressure ~moles ~temperature_k ~volume_m3 =
  match
    nonnegative "moles" moles,
    positive "temperature" temperature_k,
    positive "volume" volume_m3,
    Centl_chemistry_constants.constant "R"
  with
  | Ok (), Ok (), Ok (), Ok gas_constant ->
      Ok
        {
          moles;
          temperature_k;
          volume_m3;
          pressure_pa =
            Q.div
              (Q.mul (Q.mul moles gas_constant.value) temperature_k)
              volume_m3;
          gas_model = "ideal_gas";
          constant_provenance = gas_constant.provenance;
        }
  | Error error, _, _, _ | _, Error error, _, _ | _, _, Error error, _ ->
      Error error
  | _, _, _, Error error -> Error (Constant_error error)

let charge_from_electron_moles electron_moles =
  match nonnegative "electron moles" electron_moles,
        Centl_chemistry_constants.constant "F" with
  | Ok (), Ok faraday ->
      Ok
        {
          electron_moles;
          charge_c = Q.mul electron_moles faraday.value;
          constant_provenance = faraday.provenance;
        }
  | Error error, _ -> Error error
  | _, Error error -> Error (Constant_error error)
