type t = Any | Exact_expression | Polynomial_equation | Unit_conversion

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

let classify problem =
  let problem = String.trim problem |> String.lowercase_ascii in
  let solve = String.starts_with ~prefix:"solve " problem in
  let has_variable_target = contains ~needle:" for " problem in
  let has_relation = contains ~needle:" equals " problem || contains ~needle:"=" problem in
  if solve && has_variable_target && has_relation then Polynomial_equation else Any

let text = function
  | Any -> "any"
  | Exact_expression -> "exact_expression"
  | Polynomial_equation -> "polynomial_equation"
  | Unit_conversion -> "unit_conversion"
