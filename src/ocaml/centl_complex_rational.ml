type t = { real : Q.t; imaginary : Q.t }

type error =
  | Zero_denominator_literal
  | Division_by_zero
  | Undefined_zero_power
  | Non_rational_component of string
  | Unsupported_expression of string

let make real imaginary = { real; imaginary }
let zero = make Q.zero Q.zero
let one = make Q.one Q.zero
let of_rational value = make value Q.zero
let is_zero z = Q.equal z.real Q.zero && Q.equal z.imaginary Q.zero
let equal a b = Q.equal a.real b.real && Q.equal a.imaginary b.imaginary
let neg z = make (Q.neg z.real) (Q.neg z.imaginary)

let add a b =
  make (Q.add a.real b.real) (Q.add a.imaginary b.imaginary)

let sub a b =
  make (Q.sub a.real b.real) (Q.sub a.imaginary b.imaginary)

let mul a b =
  make
    (Q.sub (Q.mul a.real b.real) (Q.mul a.imaginary b.imaginary))
    (Q.add (Q.mul a.real b.imaginary) (Q.mul a.imaginary b.real))

let conjugate z = make z.real (Q.neg z.imaginary)

let norm2 z =
  Q.add (Q.mul z.real z.real) (Q.mul z.imaginary z.imaginary)

let reciprocal z =
  if is_zero z then Error Division_by_zero
  else
    let denominator = norm2 z in
    Ok
      (make (Q.div z.real denominator)
         (Q.div (Q.neg z.imaginary) denominator))

let div a b =
  match reciprocal b with
  | Error _ as error -> error
  | Ok inverse -> Ok (mul a inverse)

let rec pow_nonnegative base exponent accumulator =
  if Z.equal exponent Z.zero then accumulator
  else
    let accumulator =
      if Z.testbit exponent 0 then mul accumulator base else accumulator
    in
    let exponent = Z.shift_right exponent 1 in
    if Z.equal exponent Z.zero then accumulator
    else pow_nonnegative (mul base base) exponent accumulator

let pow base exponent =
  if Z.equal exponent Z.zero then
    if is_zero base then Error Undefined_zero_power else Ok one
  else if Z.sign exponent > 0 then Ok (pow_nonnegative base exponent one)
  else
    match reciprocal base with
    | Error _ as error -> error
    | Ok inverse -> Ok (pow_nonnegative inverse (Z.neg exponent) one)

let q_of_literal numerator denominator =
  if Z.equal denominator Z.zero then Error Zero_denominator_literal
  else Ok (Q.make numerator denominator)

let q_pair value = (Q.num value, Q.den value)

let rational_text value =
  let numerator, denominator = q_pair value in
  if Z.equal denominator Z.one then Z.to_string numerator
  else Z.to_string numerator ^ "/" ^ Z.to_string denominator

let text z =
  let real_zero = Q.equal z.real Q.zero in
  let imaginary_zero = Q.equal z.imaginary Q.zero in
  if imaginary_zero then rational_text z.real
  else
    let imaginary_negative = Q.sign z.imaginary < 0 in
    let imaginary_abs = Q.abs z.imaginary in
    let coefficient =
      if Q.equal imaginary_abs Q.one then "i"
      else rational_text imaginary_abs ^ "*i"
    in
    if real_zero then if imaginary_negative then "-" ^ coefficient else coefficient
    else
      rational_text z.real
      ^ (if imaginary_negative then " - " else " + ")
      ^ coefficient

let error_message = function
  | Zero_denominator_literal -> "a literal denominator cannot be zero"
  | Division_by_zero -> "division by zero complex rational"
  | Undefined_zero_power -> "0^0 is undefined"
  | Non_rational_component component ->
      component ^ " must evaluate to an exact rational"
  | Unsupported_expression description ->
      "unsupported exact complex-rational expression: " ^ description

let trigger_name = function
  | "complex" | "re" | "im" | "conj" | "norm2" -> true
  | _ -> false

let rec contains_complex = function
  | Centl_Core.Function (name, arguments) ->
      trigger_name name || List.exists contains_complex arguments
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> false
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      contains_complex inner
  | Centl_Core.Binary (_, left, right) ->
      contains_complex left || contains_complex right
  | Centl_Core.Substitute (inner, _, replacement) ->
      contains_complex inner || contains_complex replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      contains_complex inner || contains_complex left || contains_complex right

let require_real component z =
  if Q.equal z.imaginary Q.zero then Ok z.real
  else Error (Non_rational_component component)

let rec evaluate_node expression =
  let ( let* ) result next = Result.bind result next in
  match expression with
  | Centl_Core.Literal (numerator, denominator) ->
      let* value = q_of_literal numerator denominator in
      Ok (of_rational value)
  | Centl_Core.Symbol name -> Error (Unsupported_expression ("symbol " ^ name))
  | Centl_Core.Negate inner ->
      let* value = evaluate_node inner in
      Ok (neg value)
  | Centl_Core.Binary (operator, left, right) ->
      let* left = evaluate_node left in
      let* right = evaluate_node right in
      begin match operator with
      | Centl_Core.Add -> Ok (add left right)
      | Centl_Core.Subtract -> Ok (sub left right)
      | Centl_Core.Multiply -> Ok (mul left right)
      | Centl_Core.Divide -> div left right
      end
  | Centl_Core.Power (base, exponent) ->
      let* base = evaluate_node base in
      pow base exponent
  | Centl_Core.Function ("complex", [ real; imaginary ]) ->
      let* real_value = evaluate_node real in
      let* imaginary_value = evaluate_node imaginary in
      let* real = require_real "complex real component" real_value in
      let* imaginary = require_real "complex imaginary component" imaginary_value in
      Ok (make real imaginary)
  | Centl_Core.Function ("re", [ argument ]) ->
      let* value = evaluate_node argument in
      Ok (of_rational value.real)
  | Centl_Core.Function ("im", [ argument ]) ->
      let* value = evaluate_node argument in
      Ok (of_rational value.imaginary)
  | Centl_Core.Function ("conj", [ argument ]) ->
      let* value = evaluate_node argument in
      Ok (conjugate value)
  | Centl_Core.Function ("norm2", [ argument ]) ->
      let* value = evaluate_node argument in
      Ok (of_rational (norm2 value))
  | Centl_Core.Function (name, _) ->
      Error (Unsupported_expression ("function " ^ name))
  | Centl_Core.Differentiate _ -> Error (Unsupported_expression "differentiate")
  | Centl_Core.Derivative _ -> Error (Unsupported_expression "derivative")
  | Centl_Core.Substitute _ -> Error (Unsupported_expression "substitute")
  | Centl_Core.Simplify _ -> Error (Unsupported_expression "simplify")
  | Centl_Core.Expand _ -> Error (Unsupported_expression "expand")
  | Centl_Core.Factor _ -> Error (Unsupported_expression "factor")
  | Centl_Core.Assuming _ -> Error (Unsupported_expression "assuming")

let evaluate_expression expression =
  if contains_complex expression then Some (evaluate_node expression) else None

let q_bits value =
  Z.numbits (Z.abs (Q.num value)) + Z.numbits (Q.den value)

let exact_bits z = q_bits z.real + q_bits z.imaginary
