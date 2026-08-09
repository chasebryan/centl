type t =
  | Any
  | Exact_expression
  | Polynomial_equation
  | Unit_conversion
  | Unsupported of string

let contains ~needle text =
  let needle_length = String.length needle in
  let text_length = String.length text in
  let rec loop index =
    if needle_length = 0 then true
    else if index + needle_length > text_length then false
    else if String.sub text index needle_length = needle then true
    else loop (index + 1)
  in
  loop 0

let starts prefix text = String.starts_with ~prefix text

let classify problem =
  let problem = String.trim problem |> String.lowercase_ascii in
  let has_relation =
    contains ~needle:" equals " problem || contains ~needle:"=" problem
  in
  let has_variable_target = contains ~needle:" for " problem in
  let equation_request =
    has_relation
    && ((contains ~needle:"solve " problem && has_variable_target)
       || contains ~needle:" satisfying " problem
       || contains ~needle:"value of " problem
       || contains ~needle:"determine the value" problem)
  in
  let contradictory =
    contains ~needle:"but also assume" problem
    || contains ~needle:"contradict" problem
  in
  let mechanics =
    contains ~needle:"dropped from" problem
    || contains ~needle:"air resistance" problem
    || contains ~needle:"before impact" problem
    || contains ~needle:"spring" problem
  in
  let general_knowledge =
    starts "who " problem || starts "who was " problem || starts "who is " problem
  in
  if contradictory then Unsupported "contradictory request"
  else if mechanics then
    if contains ~needle:"spring" problem then
      Unsupported "missing physics parameters or unsupported mechanics"
    else Unsupported "mechanics outside CENTL-SCi v0.0.1"
  else if general_knowledge then Unsupported "general knowledge outside CENTL-SCi"
  else if
    starts "convert " problem
    || (starts "how many " problem && Centl_sci_units.mentions_known_unit problem)
  then Unit_conversion
  else if equation_request then Polynomial_equation
  else if
    starts "what is " problem || starts "calculate " problem
    || starts "compute " problem || starts "evaluate " problem
  then Exact_expression
  else Any

let text = function
  | Any -> "any"
  | Exact_expression -> "exact_expression"
  | Polynomial_equation -> "polynomial_equation"
  | Unit_conversion -> "unit_conversion"
  | Unsupported _ -> "unsupported"

let reason_hint = function Unsupported reason -> Some reason | _ -> None
