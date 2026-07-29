type exact_value =
  | Integer of Z.t
  | Rational of Z.t * Z.t
  | Symbolic of Centl_Core.expression

type token_style =
  | Number
  | Symbol_name
  | Function_name
  | Operator
  | Punctuation

type fragment = token_style * string
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
      begin match Centl_Core.evaluate (Centl_Core.resolve expression) with
      | Centl_Core.Evaluated (Centl_Core.ExactRational value) ->
          value_from_core value.numerator value.denominator
      | Centl_Core.Evaluated (Centl_Core.ExactSymbolic expression) ->
          Ok (Symbolic expression)
      | Centl_Core.EvaluationFailure Centl_Core.ZeroDenominator ->
          Error
            {
              code = "zero_denominator";
              message = "a literal denominator cannot be zero";
              position = None;
            }
      | Centl_Core.EvaluationFailure Centl_Core.DivisionByZero ->
          Error
            {
              code = "division_by_zero";
              message = "division by zero";
              position = None;
            }
      | Centl_Core.EvaluationFailure Centl_Core.UndefinedPower ->
          Error
            {
              code = "undefined_power";
              message = "0^0 is undefined";
              position = None;
            }
      end

let fragment style text = [ (style, text) ]
let append right left = List.append left right

let surround fragments =
  fragment Punctuation "(" |> append fragments
  |> append (fragment Punctuation ")")

let literal_fragments numerator denominator =
  if Z.equal denominator Z.one then fragment Number (Z.to_string numerator)
  else
    fragment Number (Z.to_string numerator)
    |> append (fragment Operator "/")
    |> append (fragment Number (Z.to_string denominator))

let binary_precedence = function
  | Centl_Core.Add | Centl_Core.Subtract -> 0
  | Centl_Core.Multiply | Centl_Core.Divide -> 1

let operator_text = function
  | Centl_Core.Add -> "+"
  | Centl_Core.Subtract -> "-"
  | Centl_Core.Multiply -> "*"
  | Centl_Core.Divide -> "/"

let rec expression_fragments ?(parent_precedence = -1) expression =
  let precedence, fragments =
    match expression with
    | Centl_Core.Literal (numerator, denominator) ->
        (4, literal_fragments numerator denominator)
    | Centl_Core.Symbol name -> (4, fragment Symbol_name name)
    | Centl_Core.Negate inner ->
        ( 2,
          fragment Operator "-"
          |> append (expression_fragments ~parent_precedence:2 inner) )
    | Centl_Core.Binary (operator, left, right) ->
        let precedence = binary_precedence operator in
        let right_precedence =
          match operator with
          | Centl_Core.Subtract | Centl_Core.Divide -> precedence + 1
          | Centl_Core.Add | Centl_Core.Multiply -> precedence
        in
        ( precedence,
          expression_fragments ~parent_precedence:precedence left
          |> append (fragment Operator (" " ^ operator_text operator ^ " "))
          |> append
               (expression_fragments ~parent_precedence:right_precedence right)
        )
    | Centl_Core.Power (base, exponent) ->
        ( 3,
          expression_fragments ~parent_precedence:3 base
          |> append (fragment Operator "^")
          |> append (fragment Number (Z.to_string exponent)) )
    | Centl_Core.Function (name, argument) ->
        (4, call_fragments name [ argument ])
    | Centl_Core.Differentiate (inner, variable)
    | Centl_Core.Derivative (inner, variable) ->
        (4, call_fragments "diff" [ inner; Centl_Core.Symbol variable ])
    | Centl_Core.Substitute (inner, variable, replacement) ->
        let assignment =
          fragment Symbol_name variable
          |> append (fragment Operator " = ")
          |> append (expression_fragments replacement)
        in
        ( 4,
          fragment Function_name "substitute"
          |> append (fragment Punctuation "(")
          |> append (expression_fragments inner)
          |> append (fragment Punctuation ", ")
          |> append assignment
          |> append (fragment Punctuation ")") )
  in
  if precedence < parent_precedence then surround fragments else fragments

and call_fragments name arguments =
  let rec arguments_fragments = function
    | [] -> []
    | [ argument ] -> expression_fragments argument
    | argument :: rest ->
        expression_fragments argument
        |> append (fragment Punctuation ", ")
        |> append (arguments_fragments rest)
  in
  fragment Function_name name
  |> append (fragment Punctuation "(")
  |> append (arguments_fragments arguments)
  |> append (fragment Punctuation ")")

let fragments_of_value = function
  | Integer value -> fragment Number (Z.to_string value)
  | Rational (numerator, denominator) -> literal_fragments numerator denominator
  | Symbolic expression -> expression_fragments expression

let text_of_fragments fragments = fragments |> List.map snd |> String.concat ""
let text_of_value value = value |> fragments_of_value |> text_of_fragments

let ansi_code = function
  | Number -> "96"
  | Symbol_name -> "95"
  | Function_name -> "94"
  | Operator -> "93"
  | Punctuation -> "2;37"

let colored_text_of_value value =
  fragments_of_value value
  |> List.map (fun (style, text) ->
      Printf.sprintf "\027[%sm%s\027[0m" (ansi_code style) text)
  |> String.concat ""

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
  | Symbolic expression ->
      let text = expression_fragments expression |> text_of_fragments in
      `Assoc
        [
          ("kind", `String "symbolic");
          ("exact", `Bool true);
          ("expression", `String text);
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
