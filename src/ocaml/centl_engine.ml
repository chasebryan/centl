type exact_value = Integer of Z.t | Rational of Z.t * Z.t
type error = { code : string; message : string; position : int option }
type evaluation = (exact_value, error) result

let value_from_core numerator denominator =
  if Z.sign denominator <= 0 then
    Error
      {
        code = "core_contract_violation";
        message = "the verified core returned a nonpositive denominator";
        position = None;
      }
  else if not (Z.equal (Z.gcd (Z.abs numerator) denominator) Z.one) then
    Error
      {
        code = "core_contract_violation";
        message = "the verified core returned an unreduced rational";
        position = None;
      }
  else if Z.equal denominator Z.one then Ok (Integer numerator)
  else Ok (Rational (numerator, denominator))

let evaluate source =
  match Centl_parser.parse source with
  | Error parse_error ->
      Error
        {
          code = "syntax_error";
          message = parse_error.message;
          position = Some parse_error.position;
        }
  | Ok expression ->
      begin match Centl_Core.evaluate expression with
      | Centl_Core.Success value ->
          value_from_core value.numerator value.denominator
      | Centl_Core.Failure Centl_Core.ZeroDenominator ->
          Error
            {
              code = "zero_denominator";
              message = "a literal denominator cannot be zero";
              position = None;
            }
      | Centl_Core.Failure Centl_Core.DivisionByZero ->
          Error
            {
              code = "division_by_zero";
              message = "division by zero";
              position = None;
            }
      end

let text_of_value = function
  | Integer value -> Z.to_string value
  | Rational (numerator, denominator) ->
      Z.to_string numerator ^ "/" ^ Z.to_string denominator

let error_text error =
  match error.position with
  | None -> error.message
  | Some position ->
      Printf.sprintf "%s at column %d" error.message (position + 1)

let json_of_value = function
  | Integer value ->
      `Assoc
        [
          ("kind", `String "integer");
          ("exact", `Bool true);
          ("value", `String (Z.to_string value));
          ("text", `String (Z.to_string value));
        ]
  | Rational (numerator, denominator) ->
      let text = Z.to_string numerator ^ "/" ^ Z.to_string denominator in
      `Assoc
        [
          ("kind", `String "rational");
          ("exact", `Bool true);
          ("numerator", `String (Z.to_string numerator));
          ("denominator", `String (Z.to_string denominator));
          ("text", `String text);
        ]

let json_of_evaluation = function
  | Ok value ->
      `Assoc
        [
          ("version", `Int 1); ("ok", `Bool true); ("value", json_of_value value);
        ]
  | Error error ->
      let fields =
        [ ("code", `String error.code); ("message", `String error.message) ]
      in
      let fields =
        match error.position with
        | None -> fields
        | Some position -> ("position", `Int position) :: fields
      in
      `Assoc
        [ ("version", `Int 1); ("ok", `Bool false); ("error", `Assoc fields) ]

let invalid_request message =
  json_of_evaluation
    (Error { code = "invalid_request"; message; position = None })

let evaluate_request json =
  match json with
  | `Assoc fields ->
      begin match
        (List.assoc_opt "version" fields, List.assoc_opt "expression" fields)
      with
      | Some (`Int 1), Some (`String expression) ->
          json_of_evaluation (evaluate expression)
      | Some (`Int version), _ when version <> 1 ->
          invalid_request "unsupported protocol version"
      | _, None -> invalid_request "missing expression"
      | _ -> invalid_request "version must be 1 and expression must be a string"
      end
  | _ -> invalid_request "request must be a JSON object"
