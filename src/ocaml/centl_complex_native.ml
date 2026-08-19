type outcome =
  | Not_complex
  | Exact of Centl_complex_rational.t
  | Refused of Centl_complex_rational.error

let complex_function = function
  | "complex" | "conj" | "re" | "im" | "norm2" -> true
  | _ -> false

let rec contains_complex_semantics = function
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> false
  | Centl_Core.Negate expression -> contains_complex_semantics expression
  | Centl_Core.Binary (_, left, right) ->
      contains_complex_semantics left || contains_complex_semantics right
  | Centl_Core.Power (base, _) -> contains_complex_semantics base
  | Centl_Core.Function (name, arguments) ->
      complex_function name || List.exists contains_complex_semantics arguments
  | Centl_Core.Differentiate (expression, _)
  | Centl_Core.Derivative (expression, _)
  | Centl_Core.Simplify expression
  | Centl_Core.Expand expression
  | Centl_Core.Factor expression ->
      contains_complex_semantics expression
  | Centl_Core.Substitute (expression, _, replacement) ->
      contains_complex_semantics expression
      || contains_complex_semantics replacement
  | Centl_Core.Assuming (expression, left, _, right) ->
      contains_complex_semantics expression
      || contains_complex_semantics left
      || contains_complex_semantics right

let evaluate expression =
  if not (contains_complex_semantics expression) then Not_complex
  else
    match Centl_complex_rational.evaluate_expression expression with
    | Ok value -> Exact value
    | Error error -> Refused error

let evaluate_source source =
  match Centl_parser.parse source with
  | Error error -> Error (`Parse error)
  | Ok expression -> Ok (evaluate expression)

let classification = function
  | Not_complex -> "not_complex"
  | Exact _ -> "exact"
  | Refused _ -> "refused"

let exact_bits = function
  | Not_complex -> 0
  | Exact value -> Centl_complex_rational.exact_bits value
  | Refused _ -> 0

let text = function
  | Not_complex -> "not a complex-rational expression"
  | Exact value -> Centl_complex_rational.to_string value
  | Refused error -> Centl_complex_rational.error_message error
