type outcome =
  | Not_complex
  | Exact of Centl_complex_rational.t
  | Refused of Centl_complex_rational.error

let evaluate ?(limits = Centl_complex_rational.default_evaluation_limits)
    ?(cancelled = Centl_complex_rational.never_cancelled) expression =
  match Centl_complex_rational.evaluate_expression ~limits ~cancelled expression with
  | None -> Not_complex
  | Some (Ok value) -> Exact value
  | Some (Error error) -> Refused error

let evaluate_source ?(limits = Centl_complex_rational.default_evaluation_limits)
    ?(cancelled = Centl_complex_rational.never_cancelled) source =
  match Centl_parser.parse source with
  | Error error -> Error (`Parse error)
  | Ok expression -> Ok (evaluate ~limits ~cancelled expression)

let rational_expression value =
  Centl_Core.Literal (Q.num value, Q.den value)

let expression_of_exact (value : Centl_complex_rational.t) =
  Centl_Core.Function
    ( "complex",
      [ rational_expression value.real; rational_expression value.imaginary ] )

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
  | Exact value -> Centl_complex_rational.text value
  | Refused error -> Centl_complex_rational.error_message error
