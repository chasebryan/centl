let error_json error =
  Error
    (`Assoc
      [
        ("version", `Int 1);
        ("kind", `String "chemistry_error");
        ("code", `String "model_error");
        ("error", `String (Centl_chemistry_models.error_message error));
      ])

let parse text =
  try Ok (Q.of_string text)
  with Invalid_argument _ | Failure _ | Division_by_zero ->
    Error (Centl_chemistry_models.Invalid_value text)

let concentration_request moles volume =
  match parse moles, parse volume with
  | Ok moles, Ok volume ->
      begin
        match Centl_chemistry_models.concentration ~moles ~volume_l:volume with
        | Error error -> error_json error
        | Ok result ->
            Ok
              (`Assoc
                [
                  ("version", `Int 1);
                  ("kind", `String "concentration");
                  ("value", `String (Q.to_string result.value));
                  ("unit", `String result.unit);
                  ("arithmetic_class", `String result.arithmetic_class);
                ])
      end
  | Error error, _ | _, Error error -> error_json error

let dilution_request concentration initial_volume final_volume =
  match parse concentration, parse initial_volume, parse final_volume with
  | Ok concentration, Ok initial_volume, Ok final_volume ->
      begin
        match
          Centl_chemistry_models.dilution ~initial_concentration:concentration
            ~initial_volume_l:initial_volume ~final_volume_l:final_volume
        with
        | Error error -> error_json error
        | Ok result ->
            Ok
              (`Assoc
                [
                  ("version", `Int 1);
                  ("kind", `String "dilution");
                  ("value", `String (Q.to_string result.final_concentration));
                  ("unit", `String result.unit);
                  ("arithmetic_class", `String result.arithmetic_class);
                ])
      end
  | Error error, _, _ | _, Error error, _ | _, _, Error error -> error_json error

let yield_request actual theoretical =
  match parse actual, parse theoretical with
  | Ok actual, Ok theoretical ->
      begin
        match Centl_chemistry_models.theoretical_yield ~actual ~theoretical with
        | Error error -> error_json error
        | Ok result ->
            Ok
              (`Assoc
                [
                  ("version", `Int 1);
                  ("kind", `String "percent_yield");
                  ("value", `String (Q.to_string result.percentage));
                  ("unit", `String result.unit);
                  ("arithmetic_class", `String result.arithmetic_class);
                ])
      end
  | Error error, _ | _, Error error -> error_json error
