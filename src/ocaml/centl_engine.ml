type real_enclosure = {
  lower_mantissa : Z.t;
  upper_mantissa : Z.t;
  binary_exponent : int;
  lower_decimal : string;
  upper_decimal : string;
  requested_digits : int;
  working_bits : int;
}

type quadratic_branch = Lower | Upper
type rational_pair = Z.t * Z.t

type real_quadratic = {
  center : rational_pair;
  radicand : rational_pair;
  branch : quadratic_branch;
}

type equation_solution =
  | Rational_solution of rational_pair
  | Real_quadratic of real_quadratic

type equation_status =
  | Finite_solutions of equation_solution list
  | No_solutions
  | All_values
  | Unresolved

type equation_result = {
  variable : string;
  left : Centl_Core.expression;
  right : Centl_Core.expression;
  status : equation_status;
}

type exact_value =
  | Integer of Z.t
  | Rational of Z.t * Z.t
  | Symbolic of Centl_Core.expression
  | Exact_sequence of Centl_Core.value list
  | Real_enclosure of real_enclosure
  | Equation_result of equation_result

type token_style =
  | Number
  | Symbol_name
  | Function_name
  | Operator
  | Punctuation

type fragment = token_style * string
type error = { code : string; message : string; position : int option }
type evaluation = (exact_value, error) result

(* Diagnostic origins are intentionally separate from [Centl_Core.expression].
   The verified AST and all verified operations stay untouched; the host keeps
   only the byte at which each parsed or generated subtree should be blamed. *)
module Expression_origins = Hashtbl.Make (struct
  type t = Centl_Core.expression

  let equal = ( == )
  let hash expression = Hashtbl.hash_param 16 32 expression
end)

type diagnostic_origins = int Expression_origins.t

let diagnostic_origins_of_spans spans =
  let origins = Expression_origins.create (List.length spans) in
  List.iter
    (fun (expression, (span : Centl_parser.source_span)) ->
      Expression_origins.replace origins expression span.start)
    spans;
  origins

let origin_of origins expression =
  Expression_origins.find_opt origins expression

let remember_origin origins expression position =
  if not (Expression_origins.mem origins expression) then
    Expression_origins.add origins expression position

let remember_generated_tree origins position root =
  let rec remember = function
    | [] -> ()
    | expression :: rest when Expression_origins.mem origins expression ->
        remember rest
    | expression :: rest ->
        Expression_origins.add origins expression position;
        let children =
          match expression with
          | Centl_Core.Literal _ | Centl_Core.Symbol _ -> rest
          | Centl_Core.Negate inner
          | Centl_Core.Power (inner, _)
          | Centl_Core.Differentiate (inner, _)
          | Centl_Core.Derivative (inner, _)
          | Centl_Core.Simplify inner
          | Centl_Core.Expand inner
          | Centl_Core.Factor inner ->
              inner :: rest
          | Centl_Core.Binary (_, left, right) -> left :: right :: rest
          | Centl_Core.Function (_, arguments) -> List.rev_append arguments rest
          | Centl_Core.Substitute (inner, _, replacement) ->
              inner :: replacement :: rest
          | Centl_Core.Assuming (inner, left, _, right) ->
              inner :: left :: right :: rest
        in
        remember children
  in
  remember [ root ]

type function_binding = {
  parameters : string list;
  body : Centl_Core.expression;
}

type binding =
  | Bound_value of Centl_Core.expression
  | Bound_function of function_binding

type session = {
  mutable bindings : (string * binding) list;
  mutable retained_nodes : int;
  mutable retained_bits : int;
  mutable retained_bytes : int;
}

type session_result =
  | Session_value of exact_value
  | Defined_value of string * exact_value
  | Defined_function of string * string list * Centl_Core.expression

type session_evaluation = (session_result, error) result

type evaluation_limits = {
  max_source_bytes : int;
  max_expression_nodes : int;
  max_exact_bits : int;
  max_integer_iterations : int;
  max_result_bytes : int;
  max_bindings : int;
  max_precision_digits : int;
  max_working_bits : int;
}

let default_evaluation_limits =
  {
    max_source_bytes = 32_768;
    max_expression_nodes = 100_000;
    max_exact_bits = 1_000_000;
    max_integer_iterations = 100_000;
    max_result_bytes = 1_048_576;
    max_bindings = 1_024;
    max_precision_digits = 1_000;
    max_working_bits = 16_384;
  }

let bounded_requested_limit fields name ~minimum ~maximum ~default =
  match List.assoc_opt name fields with
  | None -> Ok default
  | Some (`Int value) when value >= minimum && value <= maximum -> Ok value
  | Some _ ->
      Error
        (Printf.sprintf "limits.%s must be an integer between %d and %d" name
           minimum maximum)

let requested_evaluation_limits ~ceiling fields =
  let ( let* ) result next = Result.bind result next in
  match List.assoc_opt "limits" fields with
  | None -> Ok ceiling
  | Some (`Assoc requested) ->
      let allowed =
        [
          "max_source_bytes";
          "max_expression_nodes";
          "max_exact_bits";
          "max_integer_iterations";
          "max_result_bytes";
          "max_bindings";
          "max_precision_digits";
          "max_working_bits";
        ]
      in
      begin match
        List.find_opt (fun (name, _) -> not (List.mem name allowed)) requested
      with
      | Some (name, _) -> Error ("unknown limit " ^ name)
      | None ->
          let* max_source_bytes =
            bounded_requested_limit requested "max_source_bytes" ~minimum:1
              ~maximum:ceiling.max_source_bytes
              ~default:ceiling.max_source_bytes
          in
          let* max_expression_nodes =
            bounded_requested_limit requested "max_expression_nodes" ~minimum:1
              ~maximum:ceiling.max_expression_nodes
              ~default:ceiling.max_expression_nodes
          in
          let* max_exact_bits =
            bounded_requested_limit requested "max_exact_bits" ~minimum:1
              ~maximum:ceiling.max_exact_bits ~default:ceiling.max_exact_bits
          in
          let* max_integer_iterations =
            bounded_requested_limit requested "max_integer_iterations"
              ~minimum:1 ~maximum:ceiling.max_integer_iterations
              ~default:ceiling.max_integer_iterations
          in
          let* max_result_bytes =
            bounded_requested_limit requested "max_result_bytes" ~minimum:1
              ~maximum:ceiling.max_result_bytes
              ~default:ceiling.max_result_bytes
          in
          let* max_bindings =
            bounded_requested_limit requested "max_bindings" ~minimum:0
              ~maximum:ceiling.max_bindings ~default:ceiling.max_bindings
          in
          let* max_precision_digits =
            bounded_requested_limit requested "max_precision_digits" ~minimum:1
              ~maximum:ceiling.max_precision_digits
              ~default:ceiling.max_precision_digits
          in
          let* max_working_bits =
            bounded_requested_limit requested "max_working_bits" ~minimum:64
              ~maximum:ceiling.max_working_bits
              ~default:ceiling.max_working_bits
          in
          Ok
            {
              max_source_bytes;
              max_expression_nodes;
              max_exact_bits;
              max_integer_iterations;
              max_result_bytes;
              max_bindings;
              max_precision_digits;
              max_working_bits;
            }
      end
  | Some _ -> Error "limits must be an object"

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

let failure code message = Error { code; message; position = None }
let never_cancelled () = false

let check_cancelled cancelled =
  if cancelled () then failure "cancelled" "the request was cancelled"
  else Ok ()

let exact_square_root numerator denominator =
  if Z.sign numerator < 0 || Z.sign denominator <= 0 then None
  else
    let root_numerator = Z.sqrt numerator in
    let root_denominator = Z.sqrt denominator in
    match
      Centl_Core.validate_square_root numerator denominator root_numerator
        root_denominator
    with
    | Centl_Core.InvalidSquareRoot -> None
    | Centl_Core.ValidSquareRoot root -> Some root

let evaluate_exact expression =
  match Centl_Core.evaluate expression with
  | Centl_Core.Evaluated (Centl_Core.ExactRational value) ->
      value_from_core value.numerator value.denominator
  | Centl_Core.Evaluated
      (Centl_Core.ExactSymbolic
         (Centl_Core.Function
            ("sqrt", [ Centl_Core.Literal (numerator, denominator) ]) as
          expression)) ->
      begin match exact_square_root numerator denominator with
      | Some root -> value_from_core root.numerator root.denominator
      | None -> Ok (Symbolic expression)
      end
  | Centl_Core.Evaluated (Centl_Core.ExactSymbolic expression) ->
      Ok (Symbolic expression)
  | Centl_Core.EvaluationFailure Centl_Core.ZeroDenominator ->
      failure "zero_denominator" "a literal denominator cannot be zero"
  | Centl_Core.EvaluationFailure Centl_Core.DivisionByZero ->
      failure "division_by_zero" "division by zero"
  | Centl_Core.EvaluationFailure Centl_Core.UndefinedPower ->
      failure "undefined_power" "0^0 is undefined"

type native_failure =
  | Domain_error of string
  | Uncertain_domain of string
  | Unsupported of string
  | Resource_limit_failure of string
  | Backend_failure of string
  | Cancelled_failure

let ensure_finite value =
  if Centl_arb.is_finite value then Ok value
  else Error (Uncertain_domain "the enclosure is not finite at this precision")

let unary_domain name operation argument precision =
  match name with
  | "sqrt" ->
      if Centl_arb.is_negative argument then
        Error (Domain_error "sqrt is undefined for negative real values")
      else if not (Centl_arb.is_nonnegative argument) then
        Error
          (Uncertain_domain
             "could not prove that sqrt's argument is nonnegative")
      else ensure_finite (operation argument precision)
  | "log" ->
      if Centl_arb.is_nonpositive argument then
        Error (Domain_error "log is defined only for positive real values")
      else if not (Centl_arb.is_positive argument) then
        Error
          (Uncertain_domain "could not prove that log's argument is positive")
      else ensure_finite (operation argument precision)
  | "asin" | "acos" ->
      let one = Centl_arb.of_fraction "1" "1" precision in
      let above_lower = Centl_arb.add argument one precision in
      let below_upper = Centl_arb.sub one argument precision in
      if Centl_arb.is_negative above_lower || Centl_arb.is_negative below_upper
      then
        Error (Domain_error (name ^ " requires an argument between -1 and 1"))
      else if
        not
          (Centl_arb.is_nonnegative above_lower
          && Centl_arb.is_nonnegative below_upper)
      then
        Error
          (Uncertain_domain
             ("could not prove that " ^ name ^ "'s argument is between -1 and 1"))
      else ensure_finite (operation argument precision)
  | _ -> ensure_finite (operation argument precision)

let rec native_value ?(cancelled = never_cancelled) expression precision =
  let ( let* ) result next = Result.bind result next in
  let local = Result.map_error (fun failure -> (failure, expression)) in
  if cancelled () then Error (Cancelled_failure, expression)
  else
    match expression with
    | Centl_Core.Literal (numerator, denominator) ->
        if Z.equal denominator Z.zero then
          Error (Domain_error "a literal denominator cannot be zero", expression)
        else
          Ok
            (Centl_arb.of_fraction (Z.to_string numerator)
               (Z.to_string denominator) precision)
    | Centl_Core.Symbol "pi" -> Ok (Centl_arb.pi precision)
    | Centl_Core.Symbol "e" ->
        Ok (Centl_arb.exp (Centl_arb.of_fraction "1" "1" precision) precision)
    | Centl_Core.Symbol "tau" ->
        let two = Centl_arb.of_fraction "2" "1" precision in
        Ok (Centl_arb.mul two (Centl_arb.pi precision) precision)
    | Centl_Core.Symbol name ->
        Error
          ( Unsupported
              (Printf.sprintf "cannot approximate the unresolved symbol %s" name),
            expression )
    | Centl_Core.Negate inner ->
        let* value = native_value ~cancelled inner precision in
        Ok (Centl_arb.neg value)
    | Centl_Core.Binary (operator, left, right) ->
        let* left_value = native_value ~cancelled left precision in
        let* right_value = native_value ~cancelled right precision in
        local
          (match operator with
          | Centl_Core.Add ->
              ensure_finite (Centl_arb.add left_value right_value precision)
          | Centl_Core.Subtract ->
              ensure_finite (Centl_arb.sub left_value right_value precision)
          | Centl_Core.Multiply ->
              ensure_finite (Centl_arb.mul left_value right_value precision)
          | Centl_Core.Divide ->
              if Centl_arb.is_zero right_value then
                Error (Domain_error "division by zero")
              else if not (Centl_arb.is_nonzero right_value) then
                Error
                  (Uncertain_domain
                     "could not prove that the divisor excludes zero")
              else
                ensure_finite (Centl_arb.div left_value right_value precision))
    | Centl_Core.Power (base, exponent) ->
        if
          (not (Z.fits_int exponent))
          || Z.gt (Z.abs exponent) (Z.of_int 100_000)
        then
          Error
            ( Unsupported "the integer exponent exceeds the approximation limit",
              expression )
        else
          let* base_value = native_value ~cancelled base precision in
          let exponent = Z.to_int exponent in
          if exponent < 0 && Centl_arb.is_zero base_value then
            Error
              ( Domain_error "zero cannot be raised to a negative power",
                expression )
          else if exponent < 0 && not (Centl_arb.is_nonzero base_value) then
            Error
              ( Uncertain_domain
                  "could not prove that the base of a negative power excludes \
                   zero",
                expression )
          else
            local (ensure_finite (Centl_arb.pow base_value exponent precision))
    | Centl_Core.Function ("abs", [ argument ]) ->
        let* value = native_value ~cancelled argument precision in
        Ok (Centl_arb.abs value)
    | Centl_Core.Function (name, [ argument ]) ->
        let* value = native_value ~cancelled argument precision in
        local
          (match name with
          | "sqrt" -> unary_domain name Centl_arb.sqrt value precision
          | "exp" -> unary_domain name Centl_arb.exp value precision
          | "log" -> unary_domain name Centl_arb.log value precision
          | "sin" -> unary_domain name Centl_arb.sin value precision
          | "cos" -> unary_domain name Centl_arb.cos value precision
          | "tan" -> unary_domain name Centl_arb.tan value precision
          | "asin" -> unary_domain name Centl_arb.asin value precision
          | "acos" -> unary_domain name Centl_arb.acos value precision
          | "atan" -> unary_domain name Centl_arb.atan value precision
          | "sinh" -> unary_domain name Centl_arb.sinh value precision
          | "cosh" -> unary_domain name Centl_arb.cosh value precision
          | "tanh" -> unary_domain name Centl_arb.tanh value precision
          | _ -> Error (Unsupported ("cannot rigorously approximate " ^ name)))
    | Centl_Core.Function ("atan2", [ y; x ]) ->
        let* y_value = native_value ~cancelled y precision in
        let* x_value = native_value ~cancelled x precision in
        if Centl_arb.is_zero y_value && Centl_arb.is_zero x_value then
          Error (Domain_error "atan2(0, 0) is undefined", expression)
        else local (ensure_finite (Centl_arb.atan2 y_value x_value precision))
    | Centl_Core.Function (name, _) ->
        Error
          ( Unsupported
              (Printf.sprintf "%s has unsupported arguments for approximation"
                 name),
            expression )
    | Centl_Core.Assuming (inner, _, _, _) ->
        native_value ~cancelled inner precision
    | Centl_Core.Differentiate _ | Centl_Core.Substitute _
    | Centl_Core.Derivative _ | Centl_Core.Simplify _ | Centl_Core.Expand _
    | Centl_Core.Factor _ ->
        Error
          ( Unsupported
              "this unresolved symbolic operation cannot be approximated",
            expression )

let power_of_ten exponent = Z.pow (Z.of_int 10) exponent

let rational_power_of_ten exponent =
  if exponent >= 0 then Q.of_bigint (power_of_ten exponent)
  else Q.make Z.one (power_of_ten (-exponent))

let rational_of_dyadic mantissa exponent =
  if exponent >= 0 then Q.mul_2exp (Q.of_bigint mantissa) exponent
  else Q.div_2exp (Q.of_bigint mantissa) (-exponent)

let decimal_digits value = String.length (Z.to_string (Z.abs value))

let decimal_order value =
  if Q.sign value = 0 then 0
  else
    let value = Q.abs value in
    let estimate =
      decimal_digits (Q.num value) - decimal_digits (Q.den value)
    in
    let rec adjust order =
      if Q.compare value (rational_power_of_ten order) < 0 then
        adjust (order - 1)
      else if Q.compare value (rational_power_of_ten (order + 1)) >= 0 then
        adjust (order + 1)
      else order
    in
    adjust estimate

let decimal_of_scaled value places =
  if places < 0 then Z.to_string value ^ String.make (-places) '0'
  else if places = 0 then Z.to_string value
  else
    let negative = Z.sign value < 0 in
    let digits = Z.to_string (Z.abs value) in
    let padded =
      if String.length digits <= places then
        String.make (places + 1 - String.length digits) '0' ^ digits
      else digits
    in
    let split = String.length padded - places in
    (if negative then "-" else "")
    ^ String.sub padded 0 split ^ "."
    ^ String.sub padded split places

let decimal_interval_of_dyadic lower_mantissa upper_mantissa binary_exponent
    digits =
  let magnitude =
    let lower = Q.abs (rational_of_dyadic lower_mantissa binary_exponent) in
    let upper = Q.abs (rational_of_dyadic upper_mantissa binary_exponent) in
    if Q.compare lower upper >= 0 then lower else upper
  in
  let places = digits - 1 - decimal_order magnitude in
  match
    Centl_Core.round_enclosure_outward lower_mantissa upper_mantissa
      (Z.of_int binary_exponent) (Z.of_int 1_000_000) (Z.of_int places)
      (Z.of_int 4_096)
  with
  | Centl_Core.InvalidDecimalRounding ->
      Error
        (Resource_limit_failure
           "the decimal enclosure exceeds the verified rendering scale limit")
  | Centl_Core.RoundedDecimalEnclosure rounded ->
      let lower = rational_of_dyadic lower_mantissa binary_exponent in
      let upper = rational_of_dyadic upper_mantissa binary_exponent in
      let resolution = Q.div (rational_power_of_ten (-places)) (Q.of_int 2) in
      Ok
        ( decimal_of_scaled rounded.lower_scaled places,
          decimal_of_scaled rounded.upper_scaled places,
          Q.compare (Q.sub upper lower) resolution <= 0 )

let enclosure_of_ball ball requested_digits working_bits =
  if not (Centl_arb.is_finite ball) then
    Error (Uncertain_domain "the backend returned a non-finite enclosure")
  else
    let lower_text, upper_text, exponent_text = Centl_arb.endpoints ball in
    let lower_mantissa = Z.of_string lower_text in
    let upper_mantissa = Z.of_string upper_text in
    let exponent = Z.of_string exponent_text in
    begin match
      Centl_Core.validate_enclosure lower_mantissa upper_mantissa exponent
        (Z.of_int 1_000_000)
    with
    | Centl_Core.InvalidEnclosure ->
        Error
          (Backend_failure "the backend returned an invalid dyadic enclosure")
    | Centl_Core.ValidEnclosure enclosure ->
        if not (Z.fits_int enclosure.binary_exponent) then
          Error
            (Backend_failure "the backend exponent is outside the host range")
        else
          let binary_exponent = Z.to_int enclosure.binary_exponent in
          begin match
            decimal_interval_of_dyadic lower_mantissa upper_mantissa
              binary_exponent requested_digits
          with
          | Error _ as error -> error
          | Ok (lower_decimal, upper_decimal, resolved) ->
              Ok
                ( Real_enclosure
                    {
                      lower_mantissa;
                      upper_mantissa;
                      binary_exponent;
                      lower_decimal;
                      upper_decimal;
                      requested_digits;
                      working_bits;
                    },
                  resolved )
          end
    end

let approximate_with_limits ?(cancelled = never_cancelled)
    ?(position_of = fun _ -> None) limits expression requested_digits =
  let ( let* ) result next = Result.bind result next in
  let failure_at expression code message =
    match position_of expression with
    | Some position -> Error { code; message; position = Some position }
    | None -> failure code message
  in
  let digit_limit = min 1_000 limits.max_precision_digits in
  let working_limit = min 16_384 limits.max_working_bits in
  if requested_digits < 1 || requested_digits > digit_limit then
    failure "precision_limit"
      (Printf.sprintf "approximation digits must be between 1 and %d"
         digit_limit)
  else
    let target_bits = 64 + (((requested_digits * 3_322) + 999) / 1_000) in
    if target_bits > working_limit then
      failure "precision_limit"
        "the requested digits exceed the working-precision limit"
    else
      let rec attempt working_bits =
        let* () = check_cancelled cancelled in
        let retry blamed message =
          if working_bits >= working_limit then
            failure_at blamed "insufficient_precision" message
          else attempt (min working_limit (working_bits * 2))
        in
        let native_result = native_value ~cancelled expression working_bits in
        let* () = check_cancelled cancelled in
        match native_result with
        | Error (Cancelled_failure, _) ->
            failure "cancelled" "the request was cancelled"
        | Error (Domain_error message, blamed) ->
            failure_at blamed "domain_error" message
        | Error (Unsupported message, blamed) ->
            failure_at blamed "unsupported_approximation" message
        | Error (Resource_limit_failure message, blamed) ->
            failure_at blamed "resource_limit" message
        | Error (Backend_failure message, blamed) ->
            failure_at blamed "backend_failure" message
        | Error (Uncertain_domain message, blamed) -> retry blamed message
        | Ok ball ->
            begin match
              enclosure_of_ball ball requested_digits working_bits
            with
            | Error (Backend_failure message) ->
                failure_at expression "backend_failure" message
            | Error (Uncertain_domain message) -> retry expression message
            | Error (Domain_error message) ->
                failure_at expression "domain_error" message
            | Error (Unsupported message) ->
                failure_at expression "unsupported_approximation" message
            | Error (Resource_limit_failure message) ->
                failure_at expression "resource_limit" message
            | Error Cancelled_failure ->
                failure "cancelled" "the request was cancelled"
            | Ok (value, true) -> Ok value
            | Ok (_, false) ->
                retry expression
                  "the enclosure did not reach the requested significant digits"
            end
      in
      attempt target_bits

let approximate expression requested_digits =
  approximate_with_limits default_evaluation_limits expression requested_digits

let approximation_request = function
  | Centl_Core.Function ("approx", [ expression ]) -> Some (Ok (expression, 20))
  | Centl_Core.Function
      ("approx", [ expression; Centl_Core.Literal (digits, denominator) ])
    when Z.equal denominator Z.one ->
      if Z.fits_int digits then Some (Ok (expression, Z.to_int digits))
      else Some (failure "precision_limit" "approximation digits are too large")
  | Centl_Core.Function ("approx", _) ->
      Some
        (failure "invalid_arguments"
           "use approx(expression) or approx(expression, digits)")
  | _ -> None

let rational_pair_from_core value =
  match value_from_core value.Centl_Core.numerator value.denominator with
  | Ok (Integer numerator) -> Ok (numerator, Z.one)
  | Ok (Rational (numerator, denominator)) -> Ok (numerator, denominator)
  | Ok _ -> assert false
  | Error _ as error -> error

let compare_rational_pairs (left_numerator, left_denominator)
    (right_numerator, right_denominator) =
  Z.compare
    (Z.mul left_numerator right_denominator)
    (Z.mul right_numerator left_denominator)

let equation_result variable left right status =
  Ok (Equation_result { variable; left; right; status })

let equation_solution_from_core = function
  | Centl_Core.RationalSolution value ->
      Result.map
        (fun value -> Rational_solution value)
        (rational_pair_from_core value)
  | Centl_Core.RealQuadraticSolution value ->
      let ( let* ) result next = Result.bind result next in
      let* center = rational_pair_from_core value.Centl_Core.center in
      let* radicand = rational_pair_from_core value.Centl_Core.radicand in
      let branch =
        match value.Centl_Core.branch with
        | Centl_Core.Lower -> Lower
        | Centl_Core.Upper -> Upper
      in
      if Z.sign (fst radicand) <= 0 then
        failure "core_contract_violation"
          "the verified core returned a nonpositive quadratic radicand"
      else Ok (Real_quadratic { center; radicand; branch })

let normalize_two_equation_solutions first second =
  let ( let* ) result next = Result.bind result next in
  let* first = equation_solution_from_core first in
  let* second = equation_solution_from_core second in
  match (first, second) with
  | Rational_solution first, Rational_solution second ->
      Ok
        (List.map
           (fun value -> Rational_solution value)
           (List.sort_uniq compare_rational_pairs [ first; second ]))
  | ( Real_quadratic
        ({ center = first_center; radicand = first_radicand; branch = Lower } as
         first),
      Real_quadratic
        ({ center = second_center; radicand = second_radicand; branch = Upper }
         as second) )
    when first_center = second_center && first_radicand = second_radicand ->
      Ok [ Real_quadratic first; Real_quadratic second ]
  | _ ->
      failure "core_contract_violation"
        "the verified core returned an invalid pair of equation solutions"

let complete_quadratic ~cancelled limits variable left right leading linear
    discriminant =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  let* _leading = rational_pair_from_core leading in
  let* _linear = rational_pair_from_core linear in
  let* numerator, denominator = rational_pair_from_core discriminant in
  if Z.sign numerator <= 0 then
    failure "core_contract_violation"
      "the verified core requested completion for a nonpositive discriminant"
  else
    let integer_bits value =
      if Z.equal value Z.zero then 1 else Z.numbits (Z.abs value)
    in
    let numerator_bits = integer_bits numerator in
    let denominator_bits = integer_bits denominator in
    if
      numerator_bits > limits.max_exact_bits
      || denominator_bits > limits.max_exact_bits - numerator_bits
    then failure "resource_limit" "the exact result exceeds the bit limit"
    else
      let numerator_floor = Z.sqrt numerator in
      let* () = check_cancelled cancelled in
      let denominator_floor = Z.sqrt denominator in
      let* () = check_cancelled cancelled in
      begin match
        Centl_Core.complete_real_quadratic leading linear discriminant
          numerator_floor denominator_floor
      with
      | Centl_Core.TwoEquationSolutions (first, second) ->
          let* solutions = normalize_two_equation_solutions first second in
          let* () = check_cancelled cancelled in
          equation_result variable left right (Finite_solutions solutions)
      | _ ->
          failure "core_contract_violation"
            "the verified core rejected validated quadratic square witnesses"
      end

let solve_equation ~cancelled limits left right variable =
  let ( let* ) result next = Result.bind result next in
  if List.mem variable [ "pi"; "e"; "tau" ] then
    failure "invalid_solution_variable"
      (variable ^ " is a constant, not a solution variable")
  else
    let* () = check_cancelled cancelled in
    let* _ = evaluate_exact left in
    let* () = check_cancelled cancelled in
    let* _ = evaluate_exact right in
    let* () = check_cancelled cancelled in
    match Centl_Core.solve_equation left right variable with
    | Centl_Core.NoEquationSolutions ->
        equation_result variable left right No_solutions
    | Centl_Core.AllEquationValues ->
        equation_result variable left right All_values
    | Centl_Core.OneEquationSolution solution ->
        let* solution = equation_solution_from_core solution in
        equation_result variable left right (Finite_solutions [ solution ])
    | Centl_Core.TwoEquationSolutions (first, second) ->
        let* solutions = normalize_two_equation_solutions first second in
        equation_result variable left right (Finite_solutions solutions)
    | Centl_Core.RationalQuadratic (leading, linear, discriminant) ->
        complete_quadratic ~cancelled limits variable left right leading linear
          discriminant
    | Centl_Core.UnresolvedEquation ->
        equation_result variable left right Unresolved

let solution_request ~cancelled limits = function
  | Centl_Core.Function ("solve", [ left; right; Centl_Core.Symbol variable ])
    ->
      Some (solve_equation ~cancelled limits left right variable)
  | Centl_Core.Function ("solve", _) ->
      Some (failure "invalid_arguments" "use solve(left = right, variable)")
  | _ -> None

let rec contains_solution = function
  | Centl_Core.Function ("solve", _) -> true
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> false
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      contains_solution inner
  | Centl_Core.Binary (_, left, right) ->
      contains_solution left || contains_solution right
  | Centl_Core.Function (_, arguments) ->
      List.exists contains_solution arguments
  | Centl_Core.Substitute (inner, _, replacement) ->
      contains_solution inner || contains_solution replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      contains_solution inner || contains_solution left
      || contains_solution right

let syntax_error (parse_error : Centl_parser.error) =
  Error
    {
      code = "syntax_error";
      message = parse_error.message;
      position = Some parse_error.position;
    }

let expression_node_count expression =
  let rec count total = function
    | [] -> total
    | expression :: rest ->
        let rest =
          match expression with
          | Centl_Core.Literal _ | Centl_Core.Symbol _ -> rest
          | Centl_Core.Negate inner
          | Centl_Core.Power (inner, _)
          | Centl_Core.Differentiate (inner, _)
          | Centl_Core.Derivative (inner, _)
          | Centl_Core.Simplify inner
          | Centl_Core.Expand inner
          | Centl_Core.Factor inner ->
              inner :: rest
          | Centl_Core.Binary (_, left, right) -> left :: right :: rest
          | Centl_Core.Function (_, arguments) -> List.rev_append arguments rest
          | Centl_Core.Substitute (inner, _, replacement) ->
              inner :: replacement :: rest
          | Centl_Core.Assuming (inner, left, _, right) ->
              inner :: left :: right :: rest
        in
        count (total + 1) rest
  in
  count 0 [ expression ]

let bounded_sum limit left right =
  if left > limit || right > limit - left then limit + 1 else left + right

let rec substituted_node_count limit replacements expression =
  let add left right = bounded_sum limit left right in
  let children base expressions =
    List.fold_left
      (fun total expression ->
        add total (substituted_node_count limit replacements expression))
      base expressions
  in
  match expression with
  | Centl_Core.Literal _ -> 1
  | Centl_Core.Symbol name ->
      Option.value (List.assoc_opt name replacements) ~default:1
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      add 1 (substituted_node_count limit replacements inner)
  | Centl_Core.Differentiate (inner, variable)
  | Centl_Core.Derivative (inner, variable) ->
      add 1
        (substituted_node_count limit
           (List.remove_assoc variable replacements)
           inner)
  | Centl_Core.Binary (_, left, right) -> children 1 [ left; right ]
  | Centl_Core.Function
      ( ("sum" | "product" | "integrate" | "sequence"),
        [ body; Centl_Core.Symbol variable; lower; upper ] ) ->
      let body_nodes =
        substituted_node_count limit
          (List.remove_assoc variable replacements)
          body
      in
      add 2
        (add body_nodes
           (add
              (substituted_node_count limit replacements lower)
              (substituted_node_count limit replacements upper)))
  | Centl_Core.Function
      ( "recurrence",
        [
          initial;
          step;
          Centl_Core.Symbol previous;
          Centl_Core.Symbol variable;
          lower;
          upper;
        ] ) ->
      let scoped =
        replacements |> List.remove_assoc previous |> List.remove_assoc variable
      in
      add 3
        (add
           (substituted_node_count limit replacements initial)
           (add
              (substituted_node_count limit scoped step)
              (add
                 (substituted_node_count limit replacements lower)
                 (substituted_node_count limit replacements upper))))
  | Centl_Core.Function ("integrate", [ body; Centl_Core.Symbol variable ]) ->
      add 2
        (substituted_node_count limit
           (List.remove_assoc variable replacements)
           body)
  | Centl_Core.Function ("solve", [ left; right; Centl_Core.Symbol variable ])
    ->
      let scoped = List.remove_assoc variable replacements in
      add 2
        (add
           (substituted_node_count limit scoped left)
           (substituted_node_count limit scoped right))
  | Centl_Core.Function (_, arguments) -> children 1 arguments
  | Centl_Core.Substitute (inner, variable, replacement) ->
      add 1
        (add
           (substituted_node_count limit
              (List.remove_assoc variable replacements)
              inner)
           (substituted_node_count limit replacements replacement))
  | Centl_Core.Assuming (inner, left, _, right) ->
      children 1 [ inner; left; right ]

let bits_of_integer value =
  if Z.equal value Z.zero then 1 else Z.numbits (Z.abs value)

let natural_value expression =
  match Centl_Core.evaluate expression with
  | Centl_Core.Evaluated (Centl_Core.ExactRational value)
    when Z.equal value.denominator Z.one && Z.sign value.numerator >= 0 ->
      Some value.numerator
  | _ -> None

let estimated_exact_bits_with_limits ~cancelled limits expression =
  let ( let* ) result next = Result.bind result next in
  let checked = function
    | Some (numerator_bits, denominator_bits)
      when Z.gt
             (Z.add numerator_bits denominator_bits)
             (Z.of_int limits.max_exact_bits) ->
        failure "resource_limit" "the exact result exceeds the bit limit"
    | profile -> Ok profile
  in
  let map_profiles combine left right =
    match (left, right) with
    | Some left, Some right -> Some (combine left right)
    | _ -> None
  in
  let rec estimate expression =
    let* () = check_cancelled cancelled in
    let* bits =
      match expression with
      | Centl_Core.Literal (numerator, denominator) ->
          Ok
            (Some
               ( Z.of_int (bits_of_integer numerator),
                 Z.of_int (bits_of_integer denominator) ))
      | Centl_Core.Symbol _ -> Ok None
      | Centl_Core.Negate inner
      | Centl_Core.Differentiate (inner, _)
      | Centl_Core.Derivative (inner, _)
      | Centl_Core.Simplify inner
      | Centl_Core.Expand inner
      | Centl_Core.Factor inner ->
          estimate inner
      | Centl_Core.Power (base, exponent) ->
          let* base = estimate base in
          Ok
            (Option.map
               (fun (numerator_bits, denominator_bits) ->
                 if Z.equal exponent Z.zero then (Z.one, Z.one)
                 else
                   let magnitude = Z.abs exponent in
                   let numerator_bits = Z.mul numerator_bits magnitude in
                   let denominator_bits = Z.mul denominator_bits magnitude in
                   if Z.sign exponent > 0 then (numerator_bits, denominator_bits)
                   else (denominator_bits, numerator_bits))
               base)
      | Centl_Core.Binary ((Centl_Core.Add | Centl_Core.Subtract), left, right)
        ->
          let* left = estimate left in
          let* right = estimate right in
          Ok
            (map_profiles
               (fun (left_numerator, left_denominator)
                    (right_numerator, right_denominator) ->
                 ( Z.add Z.one
                     (Z.max
                        (Z.add left_numerator right_denominator)
                        (Z.add right_numerator left_denominator)),
                   Z.add left_denominator right_denominator ))
               left right)
      | Centl_Core.Binary (Centl_Core.Multiply, left, right) ->
          let* left = estimate left in
          let* right = estimate right in
          Ok
            (map_profiles
               (fun (left_numerator, left_denominator)
                    (right_numerator, right_denominator) ->
                 ( Z.add left_numerator right_numerator,
                   Z.add left_denominator right_denominator ))
               left right)
      | Centl_Core.Binary (Centl_Core.Divide, left, right) ->
          let* left = estimate left in
          let* right = estimate right in
          Ok
            (map_profiles
               (fun (left_numerator, left_denominator)
                    (right_numerator, right_denominator) ->
                 ( Z.add left_numerator right_denominator,
                   Z.add left_denominator right_numerator ))
               left right)
      | Centl_Core.Function ("factorial", [ argument ]) ->
          let* _ = estimate argument in
          Ok
            (Option.map
               (fun value ->
                 (Z.mul value (Z.of_int (bits_of_integer value)), Z.one))
               (natural_value argument))
      | Centl_Core.Function ("fibonacci", [ argument ]) ->
          let* _ = estimate argument in
          Ok
            (Option.map
               (fun value -> (Z.add value Z.one, Z.one))
               (natural_value argument))
      | Centl_Core.Function ("choose", [ n_argument; k_argument ]) ->
          let* _ = estimate n_argument in
          let* _ = estimate k_argument in
          Ok
            (match (natural_value n_argument, natural_value k_argument) with
            | Some n, Some _ -> Some (Z.add n Z.one, Z.one)
            | _ -> None)
      | Centl_Core.Function ("permutations", [ n_argument; k_argument ]) ->
          let* _ = estimate n_argument in
          let* _ = estimate k_argument in
          Ok
            (match (natural_value n_argument, natural_value k_argument) with
            | Some n, Some k ->
                Some (Z.mul k (Z.of_int (bits_of_integer n)), Z.one)
            | _ -> None)
      | Centl_Core.Function
          ( ("sum" | "product" | "sequence"),
            [ _; Centl_Core.Symbol _; lower; upper ] ) ->
          let* () = estimate_arguments [ lower; upper ] in
          Ok None
      | Centl_Core.Function
          ( "recurrence",
            [ _; _; Centl_Core.Symbol _; Centl_Core.Symbol _; lower; upper ] )
        ->
          let* () = estimate_arguments [ lower; upper ] in
          Ok None
      | Centl_Core.Function (_, arguments) ->
          let* () = estimate_arguments arguments in
          Ok None
      | Centl_Core.Substitute (inner, _, replacement) ->
          let* _ = estimate inner in
          let* _ = estimate replacement in
          Ok None
      | Centl_Core.Assuming (inner, left, _, right) ->
          let* inner = estimate inner in
          let* _ = estimate left in
          let* _ = estimate right in
          Ok inner
    in
    checked bits
  and estimate_arguments = function
    | [] -> Ok ()
    | argument :: rest ->
        let* _ = estimate argument in
        estimate_arguments rest
  in
  estimate expression

let concrete_iterations = function
  | Centl_Core.Function (("factorial" | "fibonacci"), [ argument ]) ->
      natural_value argument
  | Centl_Core.Function ("choose", [ n_argument; k_argument ]) ->
      begin match (natural_value n_argument, natural_value k_argument) with
      | Some n, Some k when Z.leq k n -> Some (Z.min k (Z.sub n k))
      | _ -> None
      end
  | Centl_Core.Function ("permutations", [ n_argument; k_argument ]) ->
      begin match (natural_value n_argument, natural_value k_argument) with
      | Some n, Some k when Z.leq k n -> Some k
      | _ -> None
      end
  | _ -> None

let check_computation_limit ?(cancelled = never_cancelled) limits expression =
  let ( let* ) result next = Result.bind result next in
  let rec check_iterations expression =
    let* () = check_cancelled cancelled in
    let rec check_list = function
      | [] -> Ok ()
      | expression :: rest ->
          let* () = check_iterations expression in
          check_list rest
    in
    let children =
      match expression with
      | Centl_Core.Literal _ | Centl_Core.Symbol _ -> []
      | Centl_Core.Negate inner
      | Centl_Core.Power (inner, _)
      | Centl_Core.Differentiate (inner, _)
      | Centl_Core.Derivative (inner, _)
      | Centl_Core.Simplify inner
      | Centl_Core.Expand inner
      | Centl_Core.Factor inner ->
          [ inner ]
      | Centl_Core.Binary (_, left, right) -> [ left; right ]
      | Centl_Core.Function
          ( ("sum" | "product" | "sequence"),
            [ _; Centl_Core.Symbol _; lower; upper ] ) ->
          [ lower; upper ]
      | Centl_Core.Function
          ( "recurrence",
            [ _; _; Centl_Core.Symbol _; Centl_Core.Symbol _; lower; upper ] )
        ->
          [ lower; upper ]
      | Centl_Core.Function (_, arguments) -> arguments
      | Centl_Core.Substitute (inner, _, replacement) -> [ inner; replacement ]
      | Centl_Core.Assuming (inner, left, _, right) -> [ inner; left; right ]
    in
    let* () = check_list children in
    match concrete_iterations expression with
    | Some iterations
      when Z.gt iterations (Z.of_int limits.max_integer_iterations) ->
        failure "resource_limit"
          "the exact operation exceeds the integer-iteration limit"
    | _ -> Ok ()
  in
  let* _ = estimated_exact_bits_with_limits ~cancelled limits expression in
  check_iterations expression

let check_expression_limit limits expression =
  if expression_node_count expression > limits.max_expression_nodes then
    failure "resource_limit" "the expression exceeds the node limit"
  else Ok ()

let check_source_limit limits source =
  if String.length source > limits.max_source_bytes then
    failure "resource_limit" "the expression exceeds the source-byte limit"
  else Ok ()

let expression_render_bytes_with_cancellation ~cancelled limit expression =
  let ( let* ) result next = Result.bind result next in
  let add left right = bounded_sum limit left right in
  let integer value = String.length (Z.to_string value) in
  let rec render_bytes total = function
    | [] -> Ok total
    | `Expressions [] :: rest -> render_bytes total rest
    | `Expressions (expression :: expressions) :: rest ->
        render_bytes total
          (`Expression expression :: `Expressions expressions :: rest)
    | `Expression expression :: rest ->
        let* () = check_cancelled cancelled in
        begin match expression with
        | Centl_Core.Literal (numerator, denominator) ->
            render_bytes
              (add total
                 (add 16 (add (integer numerator) (integer denominator))))
              rest
        | Centl_Core.Symbol name ->
            render_bytes (add total (add 16 (String.length name))) rest
        | Centl_Core.Negate inner
        | Centl_Core.Simplify inner
        | Centl_Core.Expand inner
        | Centl_Core.Factor inner ->
            render_bytes (add total 16) (`Expression inner :: rest)
        | Centl_Core.Differentiate (inner, variable)
        | Centl_Core.Derivative (inner, variable) ->
            render_bytes
              (add total (add 16 (String.length variable)))
              (`Expression inner :: rest)
        | Centl_Core.Power (inner, exponent) ->
            render_bytes
              (add total (add 16 (integer exponent)))
              (`Expression inner :: rest)
        | Centl_Core.Binary (_, left, right) ->
            render_bytes (add total 16)
              (`Expression left :: `Expression right :: rest)
        | Centl_Core.Function (name, arguments) ->
            render_bytes
              (add total (add 16 (String.length name)))
              (`Expressions arguments :: rest)
        | Centl_Core.Substitute (inner, variable, replacement) ->
            render_bytes
              (add total (add 16 (String.length variable)))
              (`Expression inner :: `Expression replacement :: rest)
        | Centl_Core.Assuming (inner, left, _, right) ->
            render_bytes (add total 16)
              (`Expression inner :: `Expression left :: `Expression right
             :: rest)
        end
  in
  render_bytes 0 [ `Expression expression ]

let value_text_bytes_with_cancellation ~cancelled limit value =
  let ( let* ) result next = Result.bind result next in
  let add left right = bounded_sum limit left right in
  let integer value = String.length (Z.to_string value) in
  let rational numerator denominator =
    if Z.equal denominator Z.one then integer numerator
    else add 1 (add (integer numerator) (integer denominator))
  in
  match value with
  | Integer value -> Ok (integer value)
  | Rational (numerator, denominator) -> Ok (rational numerator denominator)
  | Symbolic expression ->
      expression_render_bytes_with_cancellation ~cancelled limit expression
  | Exact_sequence values ->
      let rec elements total first = function
        | [] -> Ok total
        | Centl_Core.ExactRational value :: rest ->
            let* () = check_cancelled cancelled in
            let separator = if first then 0 else 2 in
            elements
              (add total
                 (add separator (rational value.numerator value.denominator)))
              false rest
        | Centl_Core.ExactSymbolic expression :: rest ->
            let* () = check_cancelled cancelled in
            let* bytes =
              expression_render_bytes_with_cancellation ~cancelled limit
                expression
            in
            let separator = if first then 0 else 2 in
            elements (add total (add separator bytes)) false rest
      in
      elements 2 true values
  | Real_enclosure enclosure ->
      Ok
        (add 16
           (add
              (String.length enclosure.lower_decimal)
              (String.length enclosure.upper_decimal)))
  | Equation_result equation ->
      let solution_bytes = function
        | Rational_solution (numerator, denominator) ->
            rational numerator denominator
        | Real_quadratic { center; radicand; branch } ->
            let center_bytes = rational (fst center) (snd center) in
            let radicand_bytes = rational (fst radicand) (snd radicand) in
            let square_root_bytes = add 6 radicand_bytes in
            if Z.equal (fst center) Z.zero then
              begin match branch with
              | Lower -> add 1 square_root_bytes
              | Upper -> square_root_bytes
              end
            else add center_bytes (add 3 square_root_bytes)
      in
      let rec solutions total = function
        | [] -> Ok total
        | solution :: rest ->
            let* () = check_cancelled cancelled in
            solutions (add total (add 2 (solution_bytes solution))) rest
      in
      let* solutions =
        match equation.status with
        | Finite_solutions values -> solutions 0 values
        | No_solutions | All_values | Unresolved -> Ok 0
      in
      let* left =
        expression_render_bytes_with_cancellation ~cancelled limit equation.left
      in
      let* right =
        expression_render_bytes_with_cancellation ~cancelled limit
          equation.right
      in
      Ok
        (add 64
           (add
              (String.length equation.variable)
              (add left (add right solutions))))

let result_render_bytes_with_cancellation ~cancelled limit value =
  let ( let* ) result next = Result.bind result next in
  let add left right = bounded_sum limit left right in
  let scale factor bytes =
    let rec multiply total remaining =
      if remaining = 0 then total else multiply (add total bytes) (remaining - 1)
    in
    multiply 0 factor
  in
  let integer value = String.length (Z.to_string value) in
  let rational numerator denominator =
    add (integer numerator) (integer denominator)
  in
  let rec condition_bytes total = function
    | [] -> Ok total
    | Centl_Core.Assuming (inner, left, _, right) :: rest ->
        let* () = check_cancelled cancelled in
        let* left =
          expression_render_bytes_with_cancellation ~cancelled limit left
        in
        let* right =
          expression_render_bytes_with_cancellation ~cancelled limit right
        in
        condition_bytes
          (add total (add 14 (scale 2 (add left right))))
          (inner :: rest)
    | _ :: rest -> condition_bytes total rest
  in
  match value with
  | Integer value -> Ok (add 56 (scale 2 (integer value)))
  | Rational (numerator, denominator) ->
      Ok (add 80 (scale 2 (rational numerator denominator)))
  | Symbolic value ->
      let* bytes =
        expression_render_bytes_with_cancellation ~cancelled limit value
      in
      let* conditions = condition_bytes 0 [ value ] in
      Ok (add 32 (add (scale 2 bytes) conditions))
  | Exact_sequence values ->
      let rec sequence_bytes total = function
        | [] -> Ok total
        | Centl_Core.ExactRational value :: rest ->
            let* () = check_cancelled cancelled in
            let bytes =
              if Z.equal value.denominator Z.one then
                add 56 (scale 3 (integer value.numerator))
              else add 80 (scale 3 (rational value.numerator value.denominator))
            in
            sequence_bytes (add total bytes) rest
        | Centl_Core.ExactSymbolic expression :: rest ->
            let* () = check_cancelled cancelled in
            let* bytes =
              expression_render_bytes_with_cancellation ~cancelled limit
                expression
            in
            let* conditions = condition_bytes 0 [ expression ] in
            sequence_bytes
              (add total (add 16 (add (scale 3 bytes) conditions)))
              rest
      in
      sequence_bytes 66 values
  | Real_enclosure enclosure ->
      let metadata =
        String.length (string_of_int enclosure.binary_exponent)
        + (2 * String.length (string_of_int enclosure.requested_digits))
        + String.length (string_of_int enclosure.working_bits)
      in
      Ok
        (add 304
           (add metadata
              (add
                 (add
                    (integer enclosure.lower_mantissa)
                    (integer enclosure.upper_mantissa))
                 (scale 2
                    (add
                       (String.length enclosure.lower_decimal)
                       (String.length enclosure.upper_decimal))))))
  | Equation_result equation ->
      let rec solution_bytes total = function
        | [] -> Ok total
        | Rational_solution (numerator, denominator) :: rest ->
            let* () = check_cancelled cancelled in
            solution_bytes
              (add total (add 64 (scale 3 (rational numerator denominator))))
              rest
        | Real_quadratic { center; radicand; _ } :: rest ->
            let* () = check_cancelled cancelled in
            let center_bytes = rational (fst center) (snd center) in
            let radicand_bytes = rational (fst radicand) (snd radicand) in
            solution_bytes
              (add total (add 256 (scale 3 (add center_bytes radicand_bytes))))
              rest
      in
      let* solutions =
        match equation.status with
        | Finite_solutions values -> solution_bytes 0 values
        | No_solutions | All_values | Unresolved -> Ok 0
      in
      let* left =
        expression_render_bytes_with_cancellation ~cancelled limit equation.left
      in
      let* right =
        expression_render_bytes_with_cancellation ~cancelled limit
          equation.right
      in
      Ok
        (add 128
           (add
              (scale 2 (add (String.length equation.variable) (add left right)))
              solutions))

let result_render_bytes limit value =
  match
    result_render_bytes_with_cancellation ~cancelled:never_cancelled limit value
  with
  | Ok bytes -> bytes
  | Error _ -> limit + 1

let session_result_render_bytes_with_cancellation ~cancelled limit = function
  | Session_value value ->
      result_render_bytes_with_cancellation ~cancelled limit value
  | Defined_value (name, value) ->
      let ( let* ) result next = Result.bind result next in
      let add left right = bounded_sum limit left right in
      let* value_bytes =
        result_render_bytes_with_cancellation ~cancelled limit value
      in
      let* text_bytes =
        value_text_bytes_with_cancellation ~cancelled limit value
      in
      Ok
        (add 128
           (add
              (add (String.length name) (String.length name))
              (add value_bytes text_bytes)))
  | Defined_function (name, parameters, body) ->
      let ( let* ) result next = Result.bind result next in
      let add left right = bounded_sum limit left right in
      let rec parameter_bytes total = function
        | [] -> Ok total
        | parameter :: rest ->
            let* () = check_cancelled cancelled in
            parameter_bytes (add total (String.length parameter)) rest
      in
      let* parameters = parameter_bytes 0 parameters in
      let* body =
        expression_render_bytes_with_cancellation ~cancelled limit body
      in
      let duplicated = add (String.length name) (add parameters body) in
      Ok (add 128 (add duplicated duplicated))

let check_session_result_limit ?(cancelled = never_cancelled) limits result =
  let ( let* ) result next = Result.bind result next in
  let* bytes =
    session_result_render_bytes_with_cancellation ~cancelled
      limits.max_result_bytes result
  in
  if bytes > limits.max_result_bytes then
    failure "resource_limit" "the session result exceeds the byte limit"
  else Ok ()

let check_result_limit ?(cancelled = never_cancelled) limits value =
  let ( let* ) result next = Result.bind result next in
  let* bytes =
    result_render_bytes_with_cancellation ~cancelled limits.max_result_bytes
      value
  in
  if bytes > limits.max_result_bytes then
    failure "resource_limit" "the result exceeds the byte limit"
  else Ok ()

let check_exact_result_bits ?(cancelled = never_cancelled) limits value =
  let ( let* ) result next = Result.bind result next in
  let add_bits total bits =
    if total > limits.max_exact_bits || bits > limits.max_exact_bits - total
    then failure "resource_limit" "the exact result exceeds the bit limit"
    else Ok (total + bits)
  in
  let add_rational total numerator denominator =
    let* () = check_cancelled cancelled in
    let* total = add_bits total (bits_of_integer numerator) in
    add_bits total (bits_of_integer denominator)
  in
  let rec add_expression total = function
    | [] -> Ok total
    | expression :: rest ->
        let* () = check_cancelled cancelled in
        begin match expression with
        | Centl_Core.Literal (numerator, denominator) ->
            let* total = add_rational total numerator denominator in
            add_expression total rest
        | Centl_Core.Symbol _ -> add_expression total rest
        | Centl_Core.Negate inner
        | Centl_Core.Differentiate (inner, _)
        | Centl_Core.Derivative (inner, _)
        | Centl_Core.Simplify inner
        | Centl_Core.Expand inner
        | Centl_Core.Factor inner ->
            add_expression total (inner :: rest)
        | Centl_Core.Power (inner, exponent) ->
            let* total = add_bits total (bits_of_integer exponent) in
            add_expression total (inner :: rest)
        | Centl_Core.Binary (_, left, right) ->
            add_expression total (left :: right :: rest)
        | Centl_Core.Function (_, arguments) ->
            add_expression total (List.rev_append arguments rest)
        | Centl_Core.Substitute (inner, _, replacement) ->
            add_expression total (inner :: replacement :: rest)
        | Centl_Core.Assuming (inner, left, _, right) ->
            add_expression total (inner :: left :: right :: rest)
        end
  in
  let add_core_value total = function
    | Centl_Core.ExactRational rational ->
        add_rational total rational.numerator rational.denominator
    | Centl_Core.ExactSymbolic expression -> add_expression total [ expression ]
  in
  let rec add_core_values total = function
    | [] -> Ok total
    | value :: rest ->
        let* total = add_core_value total value in
        add_core_values total rest
  in
  let rec add_solutions total = function
    | [] -> Ok total
    | Rational_solution (numerator, denominator) :: rest ->
        let* total = add_rational total numerator denominator in
        add_solutions total rest
    | Real_quadratic { center; radicand; _ } :: rest ->
        let* total = add_rational total (fst center) (snd center) in
        let* total = add_rational total (fst radicand) (snd radicand) in
        add_solutions total rest
  in
  let* _ =
    match value with
    | Integer integer -> add_rational 0 integer Z.one
    | Rational (numerator, denominator) -> add_rational 0 numerator denominator
    | Symbolic expression -> add_expression 0 [ expression ]
    | Exact_sequence values -> add_core_values 0 values
    | Real_enclosure _ -> Ok 0
    | Equation_result equation ->
        let* total = add_expression 0 [ equation.left; equation.right ] in
        begin match equation.status with
        | Finite_solutions solutions -> add_solutions total solutions
        | No_solutions | All_values | Unresolved -> Ok total
        end
  in
  Ok ()

let reserved_names =
  [
    "pi";
    "e";
    "tau";
    "solve";
    "diff";
    "substitute";
    "assuming";
    "simplify";
    "expand";
    "factor";
    "approx";
    "integrate";
    "sum";
    "product";
    "sequence";
    "recurrence";
    "sqrt";
    "abs";
    "exp";
    "log";
    "sin";
    "cos";
    "tan";
    "asin";
    "acos";
    "atan";
    "atan2";
    "sinh";
    "cosh";
    "tanh";
    "radians";
    "degrees";
    "square_area";
    "rectangle_area";
    "rectangle_perimeter";
    "triangle_area";
    "trapezoid_area";
    "circle_area";
    "circumference";
    "sphere_area";
    "sphere_volume";
    "cylinder_volume";
    "hypot";
    "distance";
    "slope";
    "gcd";
    "lcm";
    "factorial";
    "choose";
    "permutations";
    "fibonacci";
  ]

let rec validate_deferred_binders = function
  | Centl_Core.Function
      (("sum" | "product"), [ body; Centl_Core.Symbol variable; lower; upper ])
    ->
      if List.mem variable reserved_names then
        failure "reserved_name"
          (variable ^ " is built in and cannot be an iteration variable")
      else validate_deferred_arguments [ body; lower; upper ]
  | Centl_Core.Function
      ("sequence", [ body; Centl_Core.Symbol variable; lower; upper ]) ->
      if List.mem variable reserved_names then
        failure "reserved_name"
          (variable ^ " is built in and cannot be a sequence index")
      else validate_deferred_arguments [ body; lower; upper ]
  | Centl_Core.Function
      ( "recurrence",
        [
          initial;
          step;
          Centl_Core.Symbol previous;
          Centl_Core.Symbol variable;
          lower;
          upper;
        ] ) ->
      if previous = variable then
        failure "invalid_arguments"
          "the recurrence value name and index must be different"
      else if
        List.mem previous reserved_names || List.mem variable reserved_names
      then
        failure "reserved_name"
          "recurrence value and index names cannot be built-in names"
      else validate_deferred_arguments [ initial; step; lower; upper ]
  | Centl_Core.Function ("integrate", [ body; Centl_Core.Symbol variable ]) ->
      if List.mem variable reserved_names then
        failure "reserved_name"
          (variable ^ " is built in and cannot be an integration variable")
      else validate_deferred_binders body
  | Centl_Core.Function
      ("integrate", [ body; Centl_Core.Symbol variable; lower; upper ]) ->
      if List.mem variable reserved_names then
        failure "reserved_name"
          (variable ^ " is built in and cannot be an integration variable")
      else validate_deferred_arguments [ body; lower; upper ]
  | Centl_Core.Function (_, arguments) -> validate_deferred_arguments arguments
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> Ok ()
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      validate_deferred_binders inner
  | Centl_Core.Binary (_, left, right) ->
      let ( let* ) result next = Result.bind result next in
      let* () = validate_deferred_binders left in
      validate_deferred_binders right
  | Centl_Core.Substitute (inner, _, replacement) ->
      let ( let* ) result next = Result.bind result next in
      let* () = validate_deferred_binders inner in
      validate_deferred_binders replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      validate_deferred_arguments [ inner; left; right ]

and validate_deferred_arguments = function
  | [] -> Ok ()
  | expression :: rest ->
      let ( let* ) result next = Result.bind result next in
      let* () = validate_deferred_binders expression in
      validate_deferred_arguments rest

type polynomial_profile = {
  polynomial_variable : string option;
  degree : Z.t;
  work : Z.t;
  coefficient_bits : Z.t;
}

let merge_polynomial_variable left right =
  match (left, right) with
  | None, variable | variable, None -> Some variable
  | Some left, Some right when left = right -> Some (Some left)
  | Some _, Some _ -> None

let rec polynomial_profile expression =
  let combine operator left right =
    match (polynomial_profile left, polynomial_profile right) with
    | Some left, Some right ->
        begin match
          merge_polynomial_variable left.polynomial_variable
            right.polynomial_variable
        with
        | None -> None
        | Some variable -> operator variable left right
        end
    | _ -> None
  in
  match expression with
  | Centl_Core.Literal (numerator, denominator) ->
      if Z.equal denominator Z.zero then None
      else
        Some
          {
            polynomial_variable = None;
            degree = Z.zero;
            work = Z.one;
            coefficient_bits =
              Z.of_int (bits_of_integer numerator + bits_of_integer denominator);
          }
  | Centl_Core.Symbol variable ->
      Some
        {
          polynomial_variable = Some variable;
          degree = Z.one;
          work = Z.one;
          coefficient_bits = Z.one;
        }
  | Centl_Core.Negate inner ->
      Option.map
        (fun profile ->
          {
            profile with
            work = Z.add profile.work (Z.add profile.degree Z.one);
          })
        (polynomial_profile inner)
  | Centl_Core.Binary ((Centl_Core.Add | Centl_Core.Subtract), left, right) ->
      combine
        (fun variable left right ->
          let degree = Z.max left.degree right.degree in
          Some
            {
              polynomial_variable = variable;
              degree;
              work = Z.add (Z.add left.work right.work) (Z.add degree Z.one);
              coefficient_bits =
                Z.add Z.one (Z.add left.coefficient_bits right.coefficient_bits);
            })
        left right
  | Centl_Core.Binary (Centl_Core.Multiply, left, right) ->
      combine
        (fun variable left right ->
          let degree = Z.add left.degree right.degree in
          let operations =
            Z.mul (Z.add left.degree Z.one) (Z.add right.degree Z.one)
          in
          let convolution_bits =
            Z.of_int
              (bits_of_integer (Z.add (Z.min left.degree right.degree) Z.one))
          in
          Some
            {
              polynomial_variable = variable;
              degree;
              work = Z.add operations (Z.add left.work right.work);
              coefficient_bits =
                Z.add convolution_bits
                  (Z.add left.coefficient_bits right.coefficient_bits);
            })
        left right
  | Centl_Core.Binary (Centl_Core.Divide, left, right) ->
      begin match (polynomial_profile left, polynomial_profile right) with
      | Some left, Some right when Option.is_none right.polynomial_variable ->
          Some
            {
              polynomial_variable = left.polynomial_variable;
              degree = left.degree;
              work =
                Z.add (Z.add left.work right.work) (Z.add left.degree Z.one);
              coefficient_bits =
                Z.add left.coefficient_bits right.coefficient_bits;
            }
      | _ -> None
      end
  | Centl_Core.Power (base, exponent)
    when Z.gt exponent Z.zero && Z.leq exponent (Z.of_int 64) ->
      begin match polynomial_profile base with
      | None -> None
      | Some base ->
          let degree = Z.mul base.degree exponent in
          let triangular =
            Z.divexact (Z.mul exponent (Z.sub exponent Z.one)) (Z.of_int 2)
          in
          let operations =
            Z.mul (Z.add base.degree Z.one)
              (Z.add exponent (Z.mul base.degree triangular))
          in
          let degree_bits =
            Z.of_int (bits_of_integer (Z.add base.degree Z.one))
          in
          Some
            {
              polynomial_variable = base.polynomial_variable;
              degree;
              work = Z.add base.work operations;
              coefficient_bits =
                Z.mul exponent
                  (Z.add Z.one (Z.add base.coefficient_bits degree_bits));
            }
      end
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      polynomial_profile inner
  | Centl_Core.Power _ | Centl_Core.Function _ | Centl_Core.Differentiate _
  | Centl_Core.Substitute _ | Centl_Core.Derivative _ | Centl_Core.Assuming _ ->
      None

let check_polynomial_transformation limits expression =
  match polynomial_profile expression with
  | Some { polynomial_variable = Some _; degree; work; coefficient_bits } ->
      let output_nodes =
        if Z.equal degree Z.zero then Z.one else Z.mul (Z.of_int 5) degree
      in
      if Z.gt output_nodes (Z.of_int limits.max_expression_nodes) then
        failure "resource_limit"
          "the symbolic transformation exceeds the expression-node limit"
      else if Z.gt work (Z.of_int limits.max_expression_nodes) then
        failure "resource_limit"
          "the symbolic transformation exceeds the work limit"
      else if Z.gt coefficient_bits (Z.of_int limits.max_exact_bits) then
        failure "resource_limit"
          "the symbolic transformation exceeds the exact-coefficient bit limit"
      else Ok ()
  | _ -> Ok ()

let check_polynomial_integration limits variable expression endpoints =
  match polynomial_profile expression with
  | Some { polynomial_variable; degree; work; coefficient_bits }
    when Option.fold ~none:true ~some:(( = ) variable) polynomial_variable ->
      let terms = Z.add degree (Z.of_int 2) in
      let degree_bits =
        Z.of_int (bits_of_integer (Z.max Z.one (Z.add degree Z.one)))
      in
      let endpoint_bits =
        List.fold_left
          (fun maximum (endpoint : Centl_Core.rational) ->
            Z.max maximum
              (Z.of_int
                 (bits_of_integer endpoint.numerator
                 + bits_of_integer endpoint.denominator)))
          Z.zero endpoints
      in
      let output_nodes = Z.mul (Z.of_int 6) terms in
      let integration_work = Z.add work (Z.mul terms terms) in
      let result_bits =
        Z.mul terms
          (Z.add (Z.of_int 4)
             (Z.add coefficient_bits (Z.add degree_bits endpoint_bits)))
      in
      if Z.gt output_nodes (Z.of_int limits.max_expression_nodes) then
        failure "resource_limit"
          "the polynomial integral exceeds the expression-node limit"
      else if Z.gt integration_work (Z.of_int limits.max_expression_nodes) then
        failure "resource_limit"
          "the polynomial integral exceeds the symbolic work limit"
      else if Z.gt result_bits (Z.of_int limits.max_exact_bits) then
        failure "resource_limit"
          "the polynomial integral exceeds the exact-coefficient bit limit"
      else Ok true
  | _ -> Ok false

let rec differentiated_node_count limit expression variable =
  let sum values = List.fold_left (bounded_sum limit) 0 values in
  let nodes expression = expression_node_count expression in
  match expression with
  | Centl_Core.Literal _ -> 1
  | Centl_Core.Symbol _ -> 1
  | Centl_Core.Negate inner ->
      sum [ 1; differentiated_node_count limit inner variable ]
  | Centl_Core.Binary ((Centl_Core.Add | Centl_Core.Subtract), left, right) ->
      sum
        [
          1;
          differentiated_node_count limit left variable;
          differentiated_node_count limit right variable;
        ]
  | Centl_Core.Binary (Centl_Core.Multiply, left, right) ->
      sum
        [
          3;
          differentiated_node_count limit left variable;
          differentiated_node_count limit right variable;
          nodes left;
          nodes right;
        ]
  | Centl_Core.Binary (Centl_Core.Divide, left, right) ->
      sum
        [
          5;
          differentiated_node_count limit left variable;
          differentiated_node_count limit right variable;
          nodes left;
          2 * nodes right;
        ]
  | Centl_Core.Power (base, exponent) ->
      if Z.equal exponent Z.zero then 1
      else if Z.equal exponent Z.one then
        differentiated_node_count limit base variable
      else sum [ 4; nodes base; differentiated_node_count limit base variable ]
  | Centl_Core.Function (name, [ argument ])
    when List.mem name
           [
             "sin";
             "cos";
             "exp";
             "log";
             "sqrt";
             "tan";
             "sinh";
             "cosh";
             "tanh";
             "asin";
             "acos";
             "atan";
           ] ->
      sum
        [
          6;
          2 * nodes argument;
          differentiated_node_count limit argument variable;
        ]
  | Centl_Core.Function _ | Centl_Core.Derivative _ | Centl_Core.Differentiate _
  | Centl_Core.Substitute _ ->
      sum [ 1; nodes expression ]
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      differentiated_node_count limit inner variable
  | Centl_Core.Assuming (inner, left, _, right) ->
      sum
        [
          1;
          differentiated_node_count limit inner variable;
          nodes left;
          nodes right;
        ]

let rec contains_named_function predicate = function
  | Centl_Core.Function (name, arguments) ->
      predicate name
      || List.exists (contains_named_function predicate) arguments
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> false
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      contains_named_function predicate inner
  | Centl_Core.Binary (_, left, right) ->
      contains_named_function predicate left
      || contains_named_function predicate right
  | Centl_Core.Substitute (inner, _, replacement) ->
      contains_named_function predicate inner
      || contains_named_function predicate replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      contains_named_function predicate inner
      || contains_named_function predicate left
      || contains_named_function predicate right

let contains_deferred_evaluation =
  contains_named_function (fun name ->
      name = "sum" || name = "product" || name = "integrate"
      || name = "sequence" || name = "recurrence")

let internal_sequence_name = "$centl_sequence"

let engine_failure_of_core = function
  | Centl_Core.ZeroDenominator ->
      failure "zero_denominator" "a literal denominator cannot be zero"
  | Centl_Core.DivisionByZero -> failure "division_by_zero" "division by zero"
  | Centl_Core.UndefinedPower -> failure "undefined_power" "0^0 is undefined"

let engine_failure_of_iteration = function
  | Centl_iteration.Invalid_bound message -> failure "invalid_arguments" message
  | Centl_iteration.Resource_limit message -> failure "resource_limit" message
  | Centl_iteration.Cancelled -> failure "cancelled" "the request was cancelled"
  | Centl_iteration.Term_error (code, message) -> failure code message
  | Centl_iteration.Core_error error -> engine_failure_of_core error

let core_error_of_code = function
  | "zero_denominator" -> Some Centl_Core.ZeroDenominator
  | "division_by_zero" -> Some Centl_Core.DivisionByZero
  | "undefined_power" -> Some Centl_Core.UndefinedPower
  | _ -> None

type core_diagnostic =
  | Core_diagnostic_value of Centl_Core.value
  | Core_diagnostic_failure of Centl_Core.error * Centl_Core.expression
  | Core_diagnostic_cancelled

(* Mirror only the verified evaluator's control flow, combining already traced
   child values with extracted verified operations.  The authoritative result
   has already come from [Centl_Core.evaluate]; this single pass determines
   blame without repeatedly evaluating overlapping subtrees. *)
let rec trace_core_evaluation ~cancelled expression =
  let finish operation =
    if cancelled () then Core_diagnostic_cancelled
    else
      match operation () with
      | Centl_Core.Evaluated value -> Core_diagnostic_value value
      | Centl_Core.EvaluationFailure error ->
          Core_diagnostic_failure (error, expression)
  in
  if cancelled () then Core_diagnostic_cancelled
  else
    match expression with
    | Centl_Core.Literal (numerator, denominator) ->
        if Z.equal denominator Z.zero then
          Core_diagnostic_failure (Centl_Core.ZeroDenominator, expression)
        else
          Core_diagnostic_value
            (Centl_Core.ExactRational (Centl_Core.make numerator denominator))
    | Centl_Core.Symbol name ->
        Core_diagnostic_value
          (Centl_Core.ExactSymbolic (Centl_Core.Symbol name))
    | Centl_Core.Negate inner ->
        begin match trace_core_evaluation ~cancelled inner with
        | Core_diagnostic_value value ->
            Core_diagnostic_value (Centl_Core.negate_value value)
        | (Core_diagnostic_failure _ | Core_diagnostic_cancelled) as result ->
            result
        end
    | Centl_Core.Binary (operator, left, right) ->
        begin match trace_core_evaluation ~cancelled left with
        | (Core_diagnostic_failure _ | Core_diagnostic_cancelled) as result ->
            result
        | Core_diagnostic_value left_value ->
            begin match trace_core_evaluation ~cancelled right with
            | (Core_diagnostic_failure _ | Core_diagnostic_cancelled) as result
              ->
                result
            | Core_diagnostic_value right_value ->
                finish (fun () ->
                    Centl_Core.apply_values operator left_value right_value)
            end
        end
    | Centl_Core.Power (base, exponent) ->
        begin match trace_core_evaluation ~cancelled base with
        | (Core_diagnostic_failure _ | Core_diagnostic_cancelled) as result ->
            result
        | Core_diagnostic_value value ->
            finish (fun () -> Centl_Core.power_value value exponent)
        end
    | Centl_Core.Function (name, arguments) ->
        begin match trace_core_arguments ~cancelled [] arguments with
        | `Cancelled -> Core_diagnostic_cancelled
        | `Failure (error, blamed) -> Core_diagnostic_failure (error, blamed)
        | `Values arguments ->
            Core_diagnostic_value
              (Centl_Core.ExactSymbolic (Centl_Core.Function (name, arguments)))
        end
    | Centl_Core.Differentiate (inner, variable) ->
        trace_core_unary_symbolic ~cancelled expression inner (fun inner ->
            Centl_Core.Differentiate (inner, variable))
    | Centl_Core.Substitute (inner, variable, replacement) ->
        begin match trace_core_evaluation ~cancelled inner with
        | (Core_diagnostic_failure _ | Core_diagnostic_cancelled) as result ->
            result
        | Core_diagnostic_value inner_value ->
            begin match trace_core_evaluation ~cancelled replacement with
            | (Core_diagnostic_failure _ | Core_diagnostic_cancelled) as result
              ->
                result
            | Core_diagnostic_value replacement_value ->
                Core_diagnostic_value
                  (Centl_Core.ExactSymbolic
                     (Centl_Core.Substitute
                        ( Centl_Core.expression_of_value inner_value,
                          variable,
                          Centl_Core.expression_of_value replacement_value )))
            end
        end
    | Centl_Core.Derivative (inner, variable) ->
        trace_core_unary_symbolic ~cancelled expression inner (fun inner ->
            Centl_Core.Derivative (inner, variable))
    | Centl_Core.Simplify inner
    | Centl_Core.Expand inner
    | Centl_Core.Factor inner ->
        trace_core_evaluation ~cancelled inner
    | Centl_Core.Assuming (inner, left, relation, right) ->
        begin match trace_core_evaluation ~cancelled inner with
        | (Core_diagnostic_failure _ | Core_diagnostic_cancelled) as result ->
            result
        | Core_diagnostic_value inner_value ->
            begin match trace_core_evaluation ~cancelled left with
            | (Core_diagnostic_failure _ | Core_diagnostic_cancelled) as result
              ->
                result
            | Core_diagnostic_value left_value ->
                begin match trace_core_evaluation ~cancelled right with
                | (Core_diagnostic_failure _ | Core_diagnostic_cancelled) as
                  result ->
                    result
                | Core_diagnostic_value right_value ->
                    Core_diagnostic_value
                      (Centl_Core.ExactSymbolic
                         (Centl_Core.Assuming
                            ( Centl_Core.expression_of_value inner_value,
                              Centl_Core.expression_of_value left_value,
                              relation,
                              Centl_Core.expression_of_value right_value )))
                end
            end
        end

and trace_core_arguments ~cancelled reversed = function
  | [] -> `Values (List.rev reversed)
  | argument :: rest ->
      begin match trace_core_evaluation ~cancelled argument with
      | Core_diagnostic_cancelled -> `Cancelled
      | Core_diagnostic_failure (error, blamed) -> `Failure (error, blamed)
      | Core_diagnostic_value value ->
          trace_core_arguments ~cancelled
            (Centl_Core.expression_of_value value :: reversed)
            rest
      end

and trace_core_unary_symbolic ~cancelled _expression inner make_expression =
  match trace_core_evaluation ~cancelled inner with
  | (Core_diagnostic_failure _ | Core_diagnostic_cancelled) as result -> result
  | Core_diagnostic_value value ->
      Core_diagnostic_value
        (Centl_Core.ExactSymbolic
           (make_expression (Centl_Core.expression_of_value value)))

type diagnostic_blame =
  | Blame_expression of Centl_Core.expression
  | Blame_cancelled

let diagnostic_blame ~cancelled expression error =
  match core_error_of_code error.code with
  | Some expected ->
      begin match trace_core_evaluation ~cancelled expression with
      | Core_diagnostic_cancelled -> Blame_cancelled
      | Core_diagnostic_failure (actual, blamed) when actual = expected ->
          Blame_expression blamed
      | Core_diagnostic_failure _ | Core_diagnostic_value _ ->
          Blame_expression expression
      end
  | None -> Blame_expression expression

let attach_diagnostic_origin ~cancelled origins expression = function
  | Error ({ code = "cancelled"; _ } as error) -> Error error
  | Error ({ position = None; _ } as error) ->
      begin match diagnostic_blame ~cancelled expression error with
      | Blame_cancelled -> failure "cancelled" "the request was cancelled"
      | Blame_expression blamed ->
          begin match origin_of origins blamed with
          | Some position -> Error { error with position = Some position }
          | None ->
              begin match origin_of origins expression with
              | Some position -> Error { error with position = Some position }
              | None -> Error error
              end
          end
      end
  | result -> result

let iteration_value_of_exact = function
  | Integer value -> Ok (Centl_Core.ExactRational (Centl_Core.make value Z.one))
  | Rational (numerator, denominator) ->
      Ok (Centl_Core.ExactRational (Centl_Core.make numerator denominator))
  | Symbolic expression -> Ok (Centl_Core.ExactSymbolic expression)
  | Exact_sequence _ ->
      Error
        (Centl_iteration.Term_error
           ( "exact_sequence_required",
             "finite iteration terms cannot themselves be sequences" ))
  | Real_enclosure _ ->
      Error
        (Centl_iteration.Term_error
           ( "exact_iteration_required",
             "finite iteration terms must remain exact" ))
  | Equation_result _ ->
      Error
        (Centl_iteration.Term_error
           ( "expression_required",
             "finite iteration terms cannot return solution sets" ))

let resolve_with_limits ?(cancelled = never_cancelled)
    ?(prepare_iteration_term = fun term -> Ok term)
    ?(position_of = fun _ -> None) ?(remember_position = fun _ _ -> ()) limits
    expression =
  let ( let* ) result next = Result.bind result next in
  let remaining_iterations = ref limits.max_integer_iterations in
  let maximum_iteration_work =
    if limits.max_integer_iterations > max_int / 64 then max_int
    else limits.max_integer_iterations * 64
  in
  let remaining_iteration_work = ref maximum_iteration_work in
  let consume_integer_work amount =
    if amount < 0 || amount > !remaining_iterations then false
    else begin
      remaining_iterations := !remaining_iterations - amount;
      true
    end
  in
  let consume_integer_work_z amount =
    Z.sign amount >= 0
    && Z.fits_int amount
    && consume_integer_work (Z.to_int amount)
  in
  let consume_iteration_work amount =
    if amount < 0 || amount > !remaining_iteration_work then false
    else begin
      remaining_iteration_work := !remaining_iteration_work - amount;
      true
    end
  in
  let checked expression nodes =
    let* () = check_cancelled cancelled in
    if nodes > limits.max_expression_nodes then
      failure "resource_limit" "the expression exceeds the node limit"
    else Ok (expression, nodes)
  in
  let add_nodes left right =
    bounded_sum limits.max_expression_nodes left right
  in
  let expanding_function = function
    | "square_area" | "rectangle_area" | "rectangle_perimeter" | "triangle_area"
    | "trapezoid_area" | "hypot" | "distance" | "circle_area" | "circumference"
    | "sphere_area" | "sphere_volume" | "cylinder_volume" | "slope" | "radians"
    | "degrees" ->
        true
    | _ -> false
  in
  let check_scalar_transformation expression =
    if
      contains_named_function
        (fun name -> name = internal_sequence_name)
        expression
    then
      failure "sequence_not_expression"
        "sequence(...) returns a sequence and cannot be transformed as a \
         scalar expression"
    else if contains_solution expression then
      failure "solution_set_not_expression"
        "solve(...) returns a solution set and cannot be transformed as a \
         scalar expression"
    else if contains_named_function (fun name -> name = "approx") expression
    then
      failure "approximation_not_expression"
        "approx(...) returns an inexact enclosure and cannot be transformed as \
         an exact scalar expression"
    else Ok ()
  in
  let rec resolve expression =
    match resolve_unlocated expression with
    | Ok (resolved, nodes) ->
        Option.iter (remember_position resolved) (position_of expression);
        Ok (resolved, nodes)
    | Error ({ position = None; _ } as error) ->
        begin match position_of expression with
        | Some position -> Error { error with position = Some position }
        | None -> Error error
        end
    | result -> result
  and resolve_unlocated expression =
    let* () = check_cancelled cancelled in
    match expression with
    | Centl_Core.Literal _ | Centl_Core.Symbol _ -> Ok (expression, 1)
    | Centl_Core.Negate inner ->
        let* inner, nodes = resolve inner in
        checked (Centl_Core.Negate inner) (add_nodes 1 nodes)
    | Centl_Core.Binary (operator, left, right) ->
        let* left, left_nodes = resolve left in
        let* right, right_nodes = resolve right in
        checked
          (Centl_Core.Binary (operator, left, right))
          (add_nodes 1 (add_nodes left_nodes right_nodes))
    | Centl_Core.Power (base, exponent) ->
        let* base, nodes = resolve base in
        checked (Centl_Core.Power (base, exponent)) (add_nodes 1 nodes)
    | Centl_Core.Function
        ("sequence", [ body; Centl_Core.Symbol variable; lower; upper ]) ->
        if List.mem variable reserved_names then
          failure "reserved_name"
            (variable ^ " is built in and cannot be a sequence index")
        else
          let* lower = resolve_iteration_bound "lower" lower in
          let* upper = resolve_iteration_bound "upper" upper in
          let iteration_limits =
            Centl_iteration.
              {
                max_iterations = limits.max_integer_iterations;
                max_work = maximum_iteration_work;
                max_exact_bits = limits.max_exact_bits;
                max_expression_nodes = limits.max_expression_nodes;
                max_result_bytes = limits.max_result_bytes;
              }
          in
          let evaluate_term =
            evaluate_iteration_term
              (fun function_name ->
                function_name = "approx" || function_name = "solve"
                || function_name = internal_sequence_name)
              "exact_sequence_required"
              "finite sequence elements must be scalar exact values"
          in
          begin match
            Centl_iteration.collect ~cancelled ~evaluate_term
              ~consume:consume_integer_work ~consume_work:consume_iteration_work
              iteration_limits body variable lower upper
          with
          | Ok values ->
              let elements = List.map Centl_Core.expression_of_value values in
              let expression =
                Centl_Core.Function (internal_sequence_name, elements)
              in
              checked expression (expression_node_count expression)
          | Error error -> engine_failure_of_iteration error
          end
    | Centl_Core.Function ("sequence", _) ->
        failure "invalid_arguments"
          "use sequence(expression, variable = lower, upper)"
    | Centl_Core.Function
        ( "recurrence",
          [
            initial;
            step;
            Centl_Core.Symbol previous;
            Centl_Core.Symbol variable;
            lower;
            upper;
          ] ) ->
        if previous = variable then
          failure "invalid_arguments"
            "the recurrence value name and index must be different"
        else if
          List.mem previous reserved_names || List.mem variable reserved_names
        then
          failure "reserved_name"
            "recurrence value and index names cannot be built-in names"
        else
          let* lower = resolve_iteration_bound "lower" lower in
          let* upper = resolve_iteration_bound "upper" upper in
          let iteration_limits =
            Centl_iteration.
              {
                max_iterations = limits.max_integer_iterations;
                max_work = maximum_iteration_work;
                max_exact_bits = limits.max_exact_bits;
                max_expression_nodes = limits.max_expression_nodes;
                max_result_bytes = limits.max_result_bytes;
              }
          in
          let evaluate_term =
            evaluate_iteration_term
              (fun function_name ->
                function_name = "approx" || function_name = "solve"
                || function_name = internal_sequence_name)
              "exact_sequence_required"
              "recurrence terms must be scalar exact values"
          in
          begin match
            Centl_iteration.recurrence ~cancelled ~evaluate_term
              ~consume:consume_integer_work ~consume_work:consume_iteration_work
              iteration_limits initial step previous variable lower upper
          with
          | Ok values ->
              let elements = List.map Centl_Core.expression_of_value values in
              let expression =
                Centl_Core.Function (internal_sequence_name, elements)
              in
              checked expression (expression_node_count expression)
          | Error error -> engine_failure_of_iteration error
          end
    | Centl_Core.Function ("recurrence", _) ->
        failure "invalid_arguments"
          "use recurrence(initial, previous = step, index = lower, upper)"
    | Centl_Core.Function ("integrate", [ body; Centl_Core.Symbol variable ]) ->
        if List.mem variable reserved_names then
          failure "reserved_name"
            (variable ^ " is built in and cannot be an integration variable")
        else
          let* body, body_nodes = resolve body in
          let* integrable =
            check_polynomial_integration limits variable body []
          in
          if not integrable then
            checked
              (Centl_Core.Function
                 ("integrate", [ body; Centl_Core.Symbol variable ]))
              (add_nodes 2 body_nodes)
          else
            let* () = check_cancelled cancelled in
            let integrated = Centl_Core.integrate_polynomial body variable in
            let* () = check_cancelled cancelled in
            begin match integrated with
            | Some expression ->
                checked expression (expression_node_count expression)
            | None ->
                checked
                  (Centl_Core.Function
                     ("integrate", [ body; Centl_Core.Symbol variable ]))
                  (add_nodes 2 body_nodes)
            end
    | Centl_Core.Function
        ("integrate", [ body; Centl_Core.Symbol variable; lower; upper ]) ->
        if List.mem variable reserved_names then
          failure "reserved_name"
            (variable ^ " is built in and cannot be an integration variable")
        else
          let* lower, lower_value = resolve_integral_bound lower in
          let* upper, upper_value = resolve_integral_bound upper in
          let* body, body_nodes = resolve body in
          begin match (lower_value, upper_value) with
          | Some lower_value, Some upper_value ->
              let* integrable =
                check_polynomial_integration limits variable body
                  [ lower_value; upper_value ]
              in
              if not integrable then
                checked
                  (Centl_Core.Function
                     ( "integrate",
                       [ body; Centl_Core.Symbol variable; lower; upper ] ))
                  (add_nodes 2
                     (add_nodes body_nodes
                        (add_nodes
                           (expression_node_count lower)
                           (expression_node_count upper))))
              else
                let* () = check_cancelled cancelled in
                let integrated =
                  Centl_Core.definite_integral_polynomial body variable
                    lower_value upper_value
                in
                let* () = check_cancelled cancelled in
                begin match integrated with
                | Some value ->
                    checked
                      (Centl_Core.Literal (value.numerator, value.denominator))
                      1
                | None ->
                    checked
                      (Centl_Core.Function
                         ( "integrate",
                           [ body; Centl_Core.Symbol variable; lower; upper ] ))
                      (add_nodes 2
                         (add_nodes body_nodes
                            (add_nodes
                               (expression_node_count lower)
                               (expression_node_count upper))))
                end
          | _ ->
              checked
                (Centl_Core.Function
                   ( "integrate",
                     [ body; Centl_Core.Symbol variable; lower; upper ] ))
                (add_nodes 2
                   (add_nodes body_nodes
                      (add_nodes
                         (expression_node_count lower)
                         (expression_node_count upper))))
          end
    | Centl_Core.Function ("integrate", _) ->
        failure "invalid_arguments"
          "use integrate(expression, variable) or integrate(expression, \
           variable = lower, upper)"
    | Centl_Core.Function
        ( (("sum" | "product") as name),
          [ body; Centl_Core.Symbol variable; lower; upper ] ) ->
        if List.mem variable reserved_names then
          failure "reserved_name"
            (variable ^ " is built in and cannot be an iteration variable")
        else
          let* lower = resolve_iteration_bound "lower" lower in
          let* upper = resolve_iteration_bound "upper" upper in
          let kind =
            if name = "sum" then Centl_iteration.Sum
            else Centl_iteration.Product
          in
          let iteration_limits =
            Centl_iteration.
              {
                max_iterations = limits.max_integer_iterations;
                max_work = maximum_iteration_work;
                max_exact_bits = limits.max_exact_bits;
                max_expression_nodes = limits.max_expression_nodes;
                max_result_bytes = limits.max_result_bytes;
              }
          in
          let evaluate_term =
            evaluate_iteration_term
              (fun function_name ->
                function_name = "approx" || function_name = "solve"
                || function_name = internal_sequence_name)
              "exact_iteration_required"
              "finite iteration terms must be exact expressions"
          in
          begin match
            Centl_iteration.evaluate ~cancelled ~evaluate_term
              ~consume:consume_integer_work ~consume_work:consume_iteration_work
              iteration_limits kind body variable lower upper
          with
          | Ok value ->
              let expression = Centl_Core.expression_of_value value in
              checked expression (expression_node_count expression)
          | Error error -> engine_failure_of_iteration error
          end
    | Centl_Core.Function (("sum" | "product"), _) ->
        failure "invalid_arguments"
          "use sum(expression, variable = lower, upper) or product(expression, \
           variable = lower, upper)"
    | Centl_Core.Function (name, arguments) ->
        let* arguments, argument_nodes = resolve_arguments arguments in
        let call = Centl_Core.Function (name, arguments) in
        let* () =
          match concrete_iterations call with
          | Some amount when not (consume_integer_work_z amount) ->
              failure "resource_limit"
                "exact operations exceed the request-wide integer-iteration \
                 limit"
          | _ -> Ok ()
        in
        let rewritten = Centl_Core.rewrite_function name arguments in
        let nodes =
          if expanding_function name then expression_node_count rewritten
          else add_nodes 1 argument_nodes
        in
        checked rewritten nodes
    | Centl_Core.Derivative (inner, variable) ->
        let* inner, nodes = resolve inner in
        checked (Centl_Core.Derivative (inner, variable)) (add_nodes 1 nodes)
    | Centl_Core.Differentiate (inner, variable) ->
        let* inner, _ = resolve inner in
        let nodes =
          differentiated_node_count limits.max_expression_nodes inner variable
        in
        if nodes > limits.max_expression_nodes then
          failure "resource_limit"
            "the derivative exceeds the expression-node limit"
        else checked (Centl_Core.differentiate inner variable) nodes
    | Centl_Core.Substitute (inner, variable, replacement) ->
        let* replacement, replacement_nodes = resolve replacement in
        if contains_deferred_evaluation inner then
          let nodes =
            substituted_node_count limits.max_expression_nodes
              [ (variable, replacement_nodes) ]
              inner
          in
          if nodes > limits.max_expression_nodes then
            failure "resource_limit"
              "the substitution exceeds the expression-node limit"
          else resolve (Centl_Core.substitute inner variable replacement)
        else
          let* inner, _ = resolve inner in
          let nodes =
            substituted_node_count limits.max_expression_nodes
              [ (variable, replacement_nodes) ]
              inner
          in
          if nodes > limits.max_expression_nodes then
            failure "resource_limit"
              "the substitution exceeds the expression-node limit"
          else checked (Centl_Core.substitute inner variable replacement) nodes
    | Centl_Core.Simplify inner | Centl_Core.Expand inner ->
        let* inner, _ = resolve inner in
        let* () = check_scalar_transformation inner in
        let* () = check_polynomial_transformation limits inner in
        let transformed = Centl_Core.canonicalize_polynomial inner in
        checked transformed (expression_node_count transformed)
    | Centl_Core.Factor inner ->
        let* inner, _ = resolve inner in
        let* () = check_scalar_transformation inner in
        let* () = check_polynomial_transformation limits inner in
        let transformed = Centl_Core.factor_expression inner in
        checked transformed (expression_node_count transformed)
    | Centl_Core.Assuming (inner, left, relation, right) ->
        let* left, left_nodes = resolve left in
        let* right, right_nodes = resolve right in
        let* inner, inner_nodes = resolve inner in
        checked
          (Centl_Core.Assuming
             ( Centl_Core.simplify_assuming inner left relation right,
               left,
               relation,
               right ))
          (add_nodes 1
             (add_nodes inner_nodes (add_nodes left_nodes right_nodes)))
  and resolve_arguments = function
    | [] -> Ok ([], 0)
    | argument :: rest ->
        let* argument, argument_nodes = resolve argument in
        let* rest, rest_nodes = resolve_arguments rest in
        Ok (argument :: rest, add_nodes argument_nodes rest_nodes)
  and evaluate_iteration_term reject rejection_code rejection_message term =
    let iteration_error error =
      Error (Centl_iteration.Term_error (error.code, error.message))
    in
    match prepare_iteration_term term with
    | Error error -> iteration_error error
    | Ok term ->
        begin match check_computation_limit ~cancelled limits term with
        | Error error -> iteration_error error
        | Ok () ->
            begin match resolve term with
            | Error error -> iteration_error error
            | Ok (term, _) ->
                begin match check_computation_limit ~cancelled limits term with
                | Error error -> iteration_error error
                | Ok () ->
                    if contains_named_function reject term then
                      Error
                        (Centl_iteration.Term_error
                           (rejection_code, rejection_message))
                    else
                      begin match evaluate_exact term with
                      | Error error -> iteration_error error
                      | Ok value -> iteration_value_of_exact value
                      end
                end
            end
        end
  and resolve_iteration_bound label expression =
    let* expression, _ = resolve expression in
    match evaluate_exact expression with
    | Ok (Integer value) -> Ok (Centl_Core.Literal (value, Z.one))
    | Ok _ ->
        failure "invalid_arguments"
          (Printf.sprintf
             "the %s finite-iteration bound must be an exact integer" label)
    | Error _ as error -> error
  and resolve_integral_bound expression =
    let* expression, _ = resolve expression in
    match evaluate_exact expression with
    | Ok (Integer value) -> Ok (expression, Some (Centl_Core.make value Z.one))
    | Ok (Rational (numerator, denominator)) ->
        Ok (expression, Some (Centl_Core.make numerator denominator))
    | Ok (Symbolic _) -> Ok (expression, None)
    | Ok (Exact_sequence _ | Real_enclosure _ | Equation_result _) ->
        Ok (expression, None)
    | Error _ as error -> error
  in
  let* expression, _ = resolve expression in
  Ok expression

let evaluate_expression_with_limits ?(cancelled = never_cancelled)
    ?prepare_iteration_term ?(position_of = fun _ -> None)
    ?(remember_position = fun _ _ -> ()) limits expression =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  let* () = check_expression_limit limits expression in
  let* () = validate_deferred_binders expression in
  let* () = check_computation_limit ~cancelled limits expression in
  let* expression =
    resolve_with_limits ~cancelled ?prepare_iteration_term ~position_of
      ~remember_position limits expression
  in
  let* () = check_expression_limit limits expression in
  let* () = check_computation_limit ~cancelled limits expression in
  let exact_sequence_request = function
    | Centl_Core.Function (name, elements) when name = internal_sequence_name ->
        let rec evaluate_elements reversed = function
          | [] -> Ok (Exact_sequence (List.rev reversed))
          | element :: rest ->
              let* () = check_cancelled cancelled in
              begin match Centl_Core.evaluate element with
              | Centl_Core.Evaluated value ->
                  evaluate_elements (value :: reversed) rest
              | Centl_Core.EvaluationFailure error ->
                  engine_failure_of_core error
              end
        in
        Some (evaluate_elements [] elements)
    | _ -> None
  in
  let result =
    match exact_sequence_request expression with
    | Some result -> result
    | None
      when contains_named_function
             (fun name -> name = internal_sequence_name)
             expression ->
        failure "sequence_not_expression"
          "sequence(...) returns a sequence and must be evaluated on its own"
    | None ->
        begin match approximation_request expression with
        | Some (Ok (inner, digits)) ->
            approximate_with_limits ~cancelled ~position_of limits inner digits
        | Some (Error _ as error) -> error
        | None
          when contains_named_function (fun name -> name = "approx") expression
          ->
            failure "approximation_not_expression"
              "approx(...) returns an inexact enclosure and must be evaluated \
               on its own"
        | None ->
            begin match solution_request ~cancelled limits expression with
            | Some result -> result
            | None when contains_solution expression ->
                failure "solution_set_not_expression"
                  "solve(...) returns a solution set and must be evaluated on \
                   its own"
            | None -> evaluate_exact expression
            end
        end
  in
  let* value = result in
  let* () = check_exact_result_bits ~cancelled limits value in
  let* () = check_result_limit ~cancelled limits value in
  let* () = check_cancelled cancelled in
  Ok value

let evaluate_expression expression =
  evaluate_expression_with_limits default_evaluation_limits expression

let evaluate_with_limits ?(cancelled = never_cancelled) limits source =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  let* () = check_source_limit limits source in
  match Centl_parser.parse_located source with
  | Error parse_error -> syntax_error parse_error
  | Ok located ->
      let expression = located.expression in
      let origins = diagnostic_origins_of_spans located.spans in
      let position_of = origin_of origins in
      let* () = check_cancelled cancelled in
      evaluate_expression_with_limits ~cancelled ~position_of
        ~remember_position:(remember_origin origins) limits expression
      |> attach_diagnostic_origin ~cancelled origins expression

let evaluate source = evaluate_with_limits default_evaluation_limits source

let create_session () =
  { bindings = []; retained_nodes = 0; retained_bits = 0; retained_bytes = 0 }

let reset_session session =
  session.bindings <- [];
  session.retained_nodes <- 0;
  session.retained_bits <- 0;
  session.retained_bytes <- 0

let session_binding_count session = List.length session.bindings
let lookup session name = List.assoc_opt name session.bindings
let session_failure ?position code message = Error { code; message; position }

type retention_cost = { nodes : int; bits : int; bytes : int }

let check_session_retention ?(cancelled = never_cancelled) ?value limits session
    ~metadata_bytes expression =
  let ( let* ) result next = Result.bind result next in
  let nodes = expression_node_count expression in
  let bits =
    Centl_iteration.expression_exact_bits limits.max_exact_bits expression
  in
  let* payload_bytes =
    match value with
    | Some value ->
        result_render_bytes_with_cancellation ~cancelled limits.max_result_bytes
          value
    | None ->
        expression_render_bytes_with_cancellation ~cancelled
          limits.max_result_bytes expression
  in
  let bytes =
    bounded_sum limits.max_result_bytes (64 + metadata_bytes) payload_bytes
  in
  let exceeds current added maximum =
    current > maximum || added > maximum - current
  in
  if exceeds session.retained_nodes nodes limits.max_expression_nodes then
    session_failure "resource_limit"
      "the session exceeds the aggregate retained-node limit"
  else if exceeds session.retained_bits bits limits.max_exact_bits then
    session_failure "resource_limit"
      "the session exceeds the aggregate retained exact-bit limit"
  else if exceeds session.retained_bytes bytes limits.max_result_bytes then
    session_failure "resource_limit"
      "the session exceeds the aggregate retained-byte limit"
  else Ok { nodes; bits; bytes }

let retain_binding session name binding cost =
  session.bindings <- (name, binding) :: session.bindings;
  session.retained_nodes <- session.retained_nodes + cost.nodes;
  session.retained_bits <- session.retained_bits + cost.bits;
  session.retained_bytes <- session.retained_bytes + cost.bytes

let instantiate parameters arguments body =
  let markers =
    List.mapi
      (fun index _ -> Printf.sprintf "$centl_argument_%d" index)
      parameters
  in
  let marked =
    List.fold_left2
      (fun expression parameter marker ->
        Centl_Core.substitute expression parameter (Centl_Core.Symbol marker))
      body parameters markers
  in
  List.fold_left2
    (fun expression marker argument ->
      Centl_Core.substitute expression marker argument)
    marked markers arguments

let expansion_limit_failure () =
  session_failure "resource_limit"
    "the expression exceeds the node limit during session expansion"

let rec expand_expression ?(cancelled = never_cancelled)
    ?(defer_iterations = false) ?(origins = Expression_origins.create 0) limit
    session bound expression =
  match
    expand_expression_unlocated ~cancelled ~defer_iterations ~origins limit
      session bound expression
  with
  | Ok (expanded, _) as result ->
      Option.iter
        (fun position -> remember_origin origins expanded position)
        (origin_of origins expression);
      result
  | Error ({ position = None; _ } as error) ->
      begin match origin_of origins expression with
      | Some position -> Error { error with position = Some position }
      | None -> Error error
      end
  | Error _ as error -> error

and expand_expression_unlocated ~cancelled ~defer_iterations ~origins limit
    session bound expression =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  if limit < 1 then expansion_limit_failure ()
  else
    match expression with
    | Centl_Core.Literal _ -> Ok (expression, 1)
    | Centl_Core.Symbol name ->
        if List.mem name bound then Ok (expression, 1)
        else
          begin match lookup session name with
          | None -> Ok (expression, 1)
          | Some (Bound_value value) ->
              let nodes = expression_node_count value in
              if nodes > limit then expansion_limit_failure ()
              else begin
                Option.iter
                  (fun position ->
                    remember_generated_tree origins position value)
                  (origin_of origins expression);
                Ok (value, nodes)
              end
          | Some (Bound_function _) ->
              session_failure "invalid_arguments"
                (name ^ " is a function; call it with parentheses")
          end
    | Centl_Core.Negate inner ->
        let* inner, nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 1)
            session bound inner
        in
        Ok (Centl_Core.Negate inner, nodes + 1)
    | Centl_Core.Binary (operator, left, right) ->
        let* left, left_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 1)
            session bound left
        in
        let* right, right_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins
            (limit - 1 - left_nodes)
            session bound right
        in
        Ok
          ( Centl_Core.Binary (operator, left, right),
            left_nodes + right_nodes + 1 )
    | Centl_Core.Power (base, exponent) ->
        let* base, nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 1)
            session bound base
        in
        Ok (Centl_Core.Power (base, exponent), nodes + 1)
    | Centl_Core.Function
        ( (("sum" | "product" | "integrate" | "sequence") as name),
          [ body; Centl_Core.Symbol variable; lower; upper ] ) ->
        let* body, body_nodes =
          if defer_iterations && name <> "integrate" then
            let nodes = expression_node_count body in
            if nodes > limit - 2 then expansion_limit_failure ()
            else Ok (body, nodes)
          else
            expand_expression ~cancelled ~defer_iterations ~origins (limit - 2)
              session (variable :: bound) body
        in
        let* lower, lower_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins
            (limit - 2 - body_nodes)
            session bound lower
        in
        let* upper, upper_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins
            (limit - 2 - body_nodes - lower_nodes)
            session bound upper
        in
        Ok
          ( Centl_Core.Function
              (name, [ body; Centl_Core.Symbol variable; lower; upper ]),
            body_nodes + lower_nodes + upper_nodes + 2 )
    | Centl_Core.Function
        ( "recurrence",
          [
            initial;
            step;
            Centl_Core.Symbol previous;
            Centl_Core.Symbol variable;
            lower;
            upper;
          ] ) ->
        let* initial, initial_nodes =
          if defer_iterations then
            let nodes = expression_node_count initial in
            if nodes > limit - 3 then expansion_limit_failure ()
            else Ok (initial, nodes)
          else
            expand_expression ~cancelled ~defer_iterations ~origins (limit - 3)
              session bound initial
        in
        let* step, step_nodes =
          if defer_iterations then
            let nodes = expression_node_count step in
            if nodes > limit - 3 - initial_nodes then expansion_limit_failure ()
            else Ok (step, nodes)
          else
            expand_expression ~cancelled ~defer_iterations ~origins
              (limit - 3 - initial_nodes)
              session
              (previous :: variable :: bound)
              step
        in
        let* lower, lower_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins
            (limit - 3 - initial_nodes - step_nodes)
            session bound lower
        in
        let* upper, upper_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins
            (limit - 3 - initial_nodes - step_nodes - lower_nodes)
            session bound upper
        in
        Ok
          ( Centl_Core.Function
              ( "recurrence",
                [
                  initial;
                  step;
                  Centl_Core.Symbol previous;
                  Centl_Core.Symbol variable;
                  lower;
                  upper;
                ] ),
            initial_nodes + step_nodes + lower_nodes + upper_nodes + 3 )
    | Centl_Core.Function ("integrate", [ body; Centl_Core.Symbol variable ]) ->
        let* body, body_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 2)
            session (variable :: bound) body
        in
        Ok
          ( Centl_Core.Function
              ("integrate", [ body; Centl_Core.Symbol variable ]),
            body_nodes + 2 )
    | Centl_Core.Function ("solve", [ left; right; Centl_Core.Symbol variable ])
      ->
        let* left, left_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 2)
            session (variable :: bound) left
        in
        let* right, right_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins
            (limit - 2 - left_nodes)
            session (variable :: bound) right
        in
        Ok
          ( Centl_Core.Function
              ("solve", [ left; right; Centl_Core.Symbol variable ]),
            left_nodes + right_nodes + 2 )
    | Centl_Core.Function (name, arguments) ->
        let* arguments, argument_nodes =
          expand_arguments ~cancelled ~defer_iterations ~origins (limit - 1)
            session bound arguments
        in
        if List.mem name bound then
          Ok (Centl_Core.Function (name, arguments), argument_nodes + 1)
        else
          begin match lookup session name with
          | None ->
              Ok (Centl_Core.Function (name, arguments), argument_nodes + 1)
          | Some (Bound_value _) ->
              session_failure "invalid_arguments"
                (name ^ " is a value, not a function")
          | Some (Bound_function definition) ->
              let expected = List.length definition.parameters in
              let received = List.length arguments in
              if expected <> received then
                session_failure "invalid_arguments"
                  (Printf.sprintf "%s expects %d %s, received %d" name expected
                     (if expected = 1 then "argument" else "arguments")
                     received)
              else begin
                let replacements =
                  List.combine definition.parameters
                    (List.map expression_node_count arguments)
                in
                let nodes =
                  substituted_node_count limit replacements definition.body
                in
                if nodes > limit then expansion_limit_failure ()
                else
                  let instantiated =
                    instantiate definition.parameters arguments definition.body
                  in
                  Option.iter
                    (fun position ->
                      remember_generated_tree origins position instantiated)
                    (origin_of origins expression);
                  Ok (instantiated, nodes)
              end
          end
    | Centl_Core.Differentiate (inner, variable) ->
        let* inner, nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 1)
            session (variable :: bound) inner
        in
        Ok (Centl_Core.Differentiate (inner, variable), nodes + 1)
    | Centl_Core.Substitute (inner, variable, replacement) ->
        let* inner, inner_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 1)
            session (variable :: bound) inner
        in
        let* replacement, replacement_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins
            (limit - 1 - inner_nodes)
            session bound replacement
        in
        Ok
          ( Centl_Core.Substitute (inner, variable, replacement),
            inner_nodes + replacement_nodes + 1 )
    | Centl_Core.Derivative (inner, variable) ->
        let* inner, nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 1)
            session (variable :: bound) inner
        in
        Ok (Centl_Core.Derivative (inner, variable), nodes + 1)
    | Centl_Core.Simplify inner ->
        let* inner, nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 1)
            session bound inner
        in
        Ok (Centl_Core.Simplify inner, nodes + 1)
    | Centl_Core.Expand inner ->
        let* inner, nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 1)
            session bound inner
        in
        Ok (Centl_Core.Expand inner, nodes + 1)
    | Centl_Core.Factor inner ->
        let* inner, nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 1)
            session bound inner
        in
        Ok (Centl_Core.Factor inner, nodes + 1)
    | Centl_Core.Assuming (inner, left, relation, right) ->
        let* inner, inner_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins (limit - 1)
            session bound inner
        in
        let* left, left_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins
            (limit - 1 - inner_nodes)
            session bound left
        in
        let* right, right_nodes =
          expand_expression ~cancelled ~defer_iterations ~origins
            (limit - 1 - inner_nodes - left_nodes)
            session bound right
        in
        Ok
          ( Centl_Core.Assuming (inner, left, relation, right),
            inner_nodes + left_nodes + right_nodes + 1 )

and expand_arguments ?(cancelled = never_cancelled) ?(defer_iterations = false)
    ?(origins = Expression_origins.create 0) limit session bound arguments =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  match arguments with
  | [] -> Ok ([], 0)
  | argument :: rest ->
      let* argument, argument_nodes =
        expand_expression ~cancelled ~defer_iterations ~origins limit session
          bound argument
      in
      let* rest, rest_nodes =
        expand_arguments ~cancelled ~defer_iterations ~origins
          (limit - argument_nodes) session bound rest
      in
      Ok (argument :: rest, argument_nodes + rest_nodes)

let prepare_session_iteration_term ~cancelled ~origins limits session expression
    =
  Result.map fst
    (expand_expression ~cancelled ~defer_iterations:true ~origins
       limits.max_expression_nodes session [] expression)

let rec contains_approximation = function
  | Centl_Core.Function ("approx", _) -> true
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> false
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      contains_approximation inner
  | Centl_Core.Binary (_, left, right) ->
      contains_approximation left || contains_approximation right
  | Centl_Core.Function (_, arguments) ->
      List.exists contains_approximation arguments
  | Centl_Core.Substitute (inner, _, replacement) ->
      contains_approximation inner || contains_approximation replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      contains_approximation inner
      || contains_approximation left
      || contains_approximation right

let rec references_name name = function
  | Centl_Core.Symbol symbol -> symbol = name
  | Centl_Core.Function
      (function_name, [ body; Centl_Core.Symbol variable; lower; upper ])
    when function_name = "sum" || function_name = "product"
         || function_name = "integrate"
         || function_name = "sequence" ->
      function_name = name
      || (variable <> name && references_name name body)
      || references_name name lower || references_name name upper
  | Centl_Core.Function
      ( "recurrence",
        [
          initial;
          step;
          Centl_Core.Symbol previous;
          Centl_Core.Symbol variable;
          lower;
          upper;
        ] ) ->
      name = "recurrence"
      || references_name name initial
      || (name <> previous && name <> variable && references_name name step)
      || references_name name lower || references_name name upper
  | Centl_Core.Function ("integrate", [ body; Centl_Core.Symbol variable ]) ->
      name = "integrate" || (variable <> name && references_name name body)
  | Centl_Core.Function ("solve", [ left; right; Centl_Core.Symbol variable ])
    ->
      name = "solve"
      || variable <> name
         && (references_name name left || references_name name right)
  | Centl_Core.Function (function_name, arguments) ->
      function_name = name || List.exists (references_name name) arguments
  | Centl_Core.Literal _ -> false
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      references_name name inner
  | Centl_Core.Differentiate (inner, variable)
  | Centl_Core.Derivative (inner, variable) ->
      variable <> name && references_name name inner
  | Centl_Core.Binary (_, left, right) ->
      references_name name left || references_name name right
  | Centl_Core.Substitute (inner, variable, replacement) ->
      (variable <> name && references_name name inner)
      || references_name name replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      references_name name inner || references_name name left
      || references_name name right

let expression_of_exact_value = function
  | Integer value -> Centl_Core.Literal (value, Z.one)
  | Rational (numerator, denominator) ->
      Centl_Core.Literal (numerator, denominator)
  | Symbolic expression -> expression
  | Exact_sequence values ->
      Centl_Core.Function
        (internal_sequence_name, List.map Centl_Core.expression_of_value values)
  | Real_enclosure _ | Equation_result _ -> assert false

let validate_definition_name ?position session name =
  if List.mem name reserved_names then
    session_failure ?position "reserved_name"
      (name ^ " is built in and cannot be redefined")
  else if Option.is_some (lookup session name) then
    session_failure ?position "immutable_definition"
      (name ^ " is already defined; definitions are immutable")
  else Ok ()

let parameter_position predicate parameter_spans =
  List.find_map
    (fun (parameter, (span : Centl_parser.source_span)) ->
      if predicate parameter then Some span.start else None)
    parameter_spans

let duplicate_parameter_position parameter_spans =
  let rec find seen = function
    | [] -> None
    | (parameter, (span : Centl_parser.source_span)) :: rest ->
        if List.mem parameter seen then Some span.start
        else find (parameter :: seen) rest
  in
  find [] parameter_spans

let validate_parameters ?empty_position ~parameter_spans name parameters =
  if parameters = [] then
    session_failure ?position:empty_position "invalid_definition"
      "a function definition needs at least one parameter"
  else if List.mem name parameters then
    session_failure
      ?position:(parameter_position (String.equal name) parameter_spans)
      "invalid_definition" "a function cannot use its own name as a parameter"
  else if
    List.exists (fun parameter -> List.mem parameter reserved_names) parameters
  then
    session_failure
      ?position:
        (parameter_position
           (fun parameter -> List.mem parameter reserved_names)
           parameter_spans)
      "reserved_name" "function parameters cannot use built-in names"
  else
    let unique = List.sort_uniq String.compare parameters in
    if List.length unique <> List.length parameters then
      session_failure
        ?position:(duplicate_parameter_position parameter_spans)
        "invalid_definition" "function parameters must be unique"
    else Ok ()

let prepare_definition ?(cancelled = never_cancelled) ~origins limits session
    bound name expression =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  let defer_iterations = bound = [] in
  let* expression, _ =
    expand_expression ~cancelled ~defer_iterations ~origins
      limits.max_expression_nodes session bound expression
  in
  let* () = validate_deferred_binders expression in
  if references_name name expression then
    session_failure "recursive_definition"
      (name ^ " cannot be defined in terms of itself")
  else if contains_approximation expression then
    session_failure "exact_definition_required"
      "definitions must be exact; use approx(...) when evaluating them"
  else if bound <> [] && contains_deferred_evaluation expression then
    if
      contains_named_function
        (fun function_name -> function_name = "solve")
        expression
    then
      session_failure "expression_definition_required"
        "solution sets cannot be stored in definitions yet"
    else
      let* () = check_result_limit ~cancelled limits (Symbolic expression) in
      Ok (Symbolic expression, expression)
  else
    let* value =
      evaluate_expression_with_limits ~cancelled
        ~position_of:(origin_of origins)
        ~remember_position:(remember_origin origins)
        ~prepare_iteration_term:
          (prepare_session_iteration_term ~cancelled ~origins limits session)
        limits expression
    in
    match value with
    | Real_enclosure _ ->
        session_failure "exact_definition_required"
          "definitions must be exact; use approx(...) when evaluating them"
    | Equation_result _ ->
        session_failure "expression_definition_required"
          "solution sets cannot be stored in definitions yet"
    | value -> Ok (value, expression_of_exact_value value)

let evaluate_in_session_with_limits ?(cancelled = never_cancelled) limits
    session source =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  let* () = check_source_limit limits source in
  let parsed = Centl_parser.parse_statement_located source in
  let* () = check_cancelled cancelled in
  match parsed with
  | Error parse_error -> syntax_error parse_error
  | Ok located ->
      let origins = diagnostic_origins_of_spans located.statement_spans in
      let position_of = origin_of origins in
      let definition_name_position =
        Option.map
          (fun (span : Centl_parser.source_span) -> span.start)
          located.definition_name_span
      in
      let empty_parameter_position =
        Option.map
          (fun (span : Centl_parser.source_span) -> span.finish - 1)
          located.parameter_list_span
      in
      let result =
        match located.statement with
        | Centl_parser.Evaluate expression ->
            let* expression, _ =
              expand_expression ~cancelled ~defer_iterations:true ~origins
                limits.max_expression_nodes session [] expression
            in
            evaluate_expression_with_limits ~cancelled ~position_of
              ~remember_position:(remember_origin origins)
              ~prepare_iteration_term:
                (prepare_session_iteration_term ~cancelled ~origins limits
                   session)
              limits expression
            |> attach_diagnostic_origin ~cancelled origins expression
            |> Result.map (fun value -> Session_value value)
        | Centl_parser.Define_value (name, expression) ->
            let* () =
              validate_definition_name ?position:definition_name_position
                session name
            in
            let* () =
              if session_binding_count session >= limits.max_bindings then
                session_failure ?position:definition_name_position
                  "resource_limit"
                  "the session has reached its definition limit"
              else Ok ()
            in
            let* value, expression =
              prepare_definition ~cancelled ~origins limits session [] name
                expression
              |> attach_diagnostic_origin ~cancelled origins expression
            in
            let result = Defined_value (name, value) in
            let* () = check_session_result_limit ~cancelled limits result in
            let* retention =
              check_session_retention ~cancelled ~value limits session
                ~metadata_bytes:(String.length name) expression
            in
            let* () = check_cancelled cancelled in
            retain_binding session name (Bound_value expression) retention;
            Ok result
        | Centl_parser.Define_function (name, parameters, body) ->
            let* () =
              validate_definition_name ?position:definition_name_position
                session name
            in
            let* () =
              validate_parameters ?empty_position:empty_parameter_position
                ~parameter_spans:located.parameter_spans name parameters
            in
            let* () =
              if session_binding_count session >= limits.max_bindings then
                session_failure ?position:definition_name_position
                  "resource_limit"
                  "the session has reached its definition limit"
              else Ok ()
            in
            let* _, body =
              prepare_definition ~cancelled ~origins limits session parameters
                name body
              |> attach_diagnostic_origin ~cancelled origins body
            in
            let result = Defined_function (name, parameters, body) in
            let* () = check_session_result_limit ~cancelled limits result in
            let metadata_bytes =
              List.fold_left
                (fun total parameter -> total + String.length parameter)
                (String.length name) parameters
            in
            let* retention =
              check_session_retention ~cancelled limits session ~metadata_bytes
                body
            in
            let* () = check_cancelled cancelled in
            retain_binding session name
              (Bound_function { parameters; body })
              retention;
            Ok result
      in
      result

let evaluate_in_session session source =
  evaluate_in_session_with_limits default_evaluation_limits session source

let fragment style text = [ (style, text) ]
let append right left = List.rev_append (List.rev left) right

let surround fragments =
  (Punctuation, "(")
  :: List.rev_append (List.rev fragments) [ (Punctuation, ")") ]

let literal_fragments numerator denominator =
  if Z.equal denominator Z.one then fragment Number (Z.to_string numerator)
  else
    [
      (Number, Z.to_string numerator);
      (Operator, "/");
      (Number, Z.to_string denominator);
    ]

let binary_precedence = function
  | Centl_Core.Add | Centl_Core.Subtract -> 0
  | Centl_Core.Multiply | Centl_Core.Divide -> 1

let operator_text = function
  | Centl_Core.Add -> "+"
  | Centl_Core.Subtract -> "-"
  | Centl_Core.Multiply -> "*"
  | Centl_Core.Divide -> "/"

let relation_text = function
  | Centl_Core.Equal -> "="
  | Centl_Core.NotEqual -> "!="
  | Centl_Core.LessThan -> "<"
  | Centl_Core.LessOrEqual -> "<="
  | Centl_Core.GreaterThan -> ">"
  | Centl_Core.GreaterOrEqual -> ">="

type fragment_render_command =
  | Emit_fragment of fragment
  | Render_expression of int * Centl_Core.expression
  | Render_arguments of Centl_Core.expression list
  | Render_parameter_arguments of string list
  | Render_call of string * Centl_Core.expression list
  | Render_literal of rational_pair
  | Render_core_values of Centl_Core.value list
  | Render_solution of equation_solution
  | Render_solutions of equation_solution list
  | Render_equation_call of equation_result
  | Render_equation_result of equation_result
  | Render_value of exact_value

let expression_precedence = function
  | Centl_Core.Literal (_, denominator) when not (Z.equal denominator Z.one) ->
      1
  | Centl_Core.Literal (numerator, _) when Z.sign numerator < 0 -> 2
  | Centl_Core.Literal _ | Centl_Core.Symbol _ | Centl_Core.Function _
  | Centl_Core.Differentiate _ | Centl_Core.Derivative _
  | Centl_Core.Substitute _ | Centl_Core.Simplify _ | Centl_Core.Expand _
  | Centl_Core.Factor _ ->
      4
  | Centl_Core.Power _ -> 3
  | Centl_Core.Negate _ -> 2
  | Centl_Core.Binary (operator, _, _) -> binary_precedence operator
  | Centl_Core.Assuming _ -> -1

let render_fragment_commands commands =
  let emit style text rest = Emit_fragment (style, text) :: rest in
  let rec render reversed = function
    | [] -> List.rev reversed
    | Emit_fragment fragment :: rest -> render (fragment :: reversed) rest
    | Render_literal (numerator, denominator) :: rest ->
        let commands =
          if Z.equal denominator Z.one then
            emit Number (Z.to_string numerator) rest
          else
            emit Number (Z.to_string numerator)
              (emit Operator "/" (emit Number (Z.to_string denominator) rest))
        in
        render reversed commands
    | Render_core_values [] :: rest -> render reversed rest
    | Render_core_values (value :: values) :: rest ->
        let rest =
          match values with
          | [] -> rest
          | _ -> emit Punctuation ", " (Render_core_values values :: rest)
        in
        let commands =
          match value with
          | Centl_Core.ExactRational rational ->
              Render_literal (rational.numerator, rational.denominator) :: rest
          | Centl_Core.ExactSymbolic expression ->
              Render_expression (-1, expression) :: rest
        in
        render reversed commands
    | Render_arguments [] :: rest -> render reversed rest
    | Render_arguments (argument :: arguments) :: rest ->
        let rest =
          match arguments with
          | [] -> rest
          | _ -> emit Punctuation ", " (Render_arguments arguments :: rest)
        in
        render reversed (Render_expression (-1, argument) :: rest)
    | Render_parameter_arguments [] :: rest -> render reversed rest
    | Render_parameter_arguments (parameter :: parameters) :: rest ->
        let rest =
          match parameters with
          | [] -> rest
          | _ ->
              emit Punctuation ", "
                (Render_parameter_arguments parameters :: rest)
        in
        render reversed (emit Symbol_name parameter rest)
    | Render_call (name, arguments) :: rest ->
        render reversed
          (emit Function_name name
             (emit Punctuation "("
                (Render_arguments arguments :: emit Punctuation ")" rest)))
    | Render_expression (parent_precedence, expression) :: rest ->
        let precedence = expression_precedence expression in
        let parenthesized = precedence < parent_precedence in
        let trailing =
          if parenthesized then emit Punctuation ")" rest else rest
        in
        let body =
          match expression with
          | Centl_Core.Literal (numerator, denominator) ->
              Render_literal (numerator, denominator) :: trailing
          | Centl_Core.Symbol name -> emit Symbol_name name trailing
          | Centl_Core.Negate inner ->
              emit Operator "-" (Render_expression (2, inner) :: trailing)
          | Centl_Core.Binary (operator, left, right) ->
              let right_precedence =
                match operator with
                | Centl_Core.Subtract | Centl_Core.Divide -> precedence + 1
                | Centl_Core.Add | Centl_Core.Multiply -> precedence
              in
              Render_expression (precedence, left)
              :: emit Operator
                   (" " ^ operator_text operator ^ " ")
                   (Render_expression (right_precedence, right) :: trailing)
          | Centl_Core.Power (base, exponent) ->
              Render_expression (4, base)
              :: emit Operator "^" (emit Number (Z.to_string exponent) trailing)
          | Centl_Core.Function
              ( (("sum" | "product" | "integrate" | "sequence") as name),
                [ body; Centl_Core.Symbol variable; lower; upper ] ) ->
              emit Function_name name
                (emit Punctuation "("
                   (Render_expression (-1, body)
                   :: emit Punctuation ", "
                        (emit Symbol_name variable
                           (emit Operator " = "
                              (Render_expression (-1, lower)
                              :: emit Punctuation ", "
                                   (Render_expression (-1, upper)
                                   :: emit Punctuation ")" trailing))))))
          | Centl_Core.Function
              ( "recurrence",
                [
                  initial;
                  step;
                  Centl_Core.Symbol previous;
                  Centl_Core.Symbol variable;
                  lower;
                  upper;
                ] ) ->
              let commands = emit Punctuation ")" trailing in
              let commands = Render_expression (-1, upper) :: commands in
              let commands = emit Punctuation ", " commands in
              let commands = Render_expression (-1, lower) :: commands in
              let commands = emit Operator " = " commands in
              let commands = emit Symbol_name variable commands in
              let commands = emit Punctuation ", " commands in
              let commands = Render_expression (-1, step) :: commands in
              let commands = emit Operator " = " commands in
              let commands = emit Symbol_name previous commands in
              let commands = emit Punctuation ", " commands in
              let commands = Render_expression (-1, initial) :: commands in
              emit Function_name "recurrence" (emit Punctuation "(" commands)
          | Centl_Core.Function (name, arguments) ->
              Render_call (name, arguments) :: trailing
          | Centl_Core.Differentiate (inner, variable)
          | Centl_Core.Derivative (inner, variable) ->
              emit Function_name "diff"
                (emit Punctuation "("
                   (Render_expression (-1, inner)
                   :: emit Punctuation ", "
                        (emit Symbol_name variable
                           (emit Punctuation ")" trailing))))
          | Centl_Core.Substitute (inner, variable, replacement) ->
              emit Function_name "substitute"
                (emit Punctuation "("
                   (Render_expression (-1, inner)
                   :: emit Punctuation ", "
                        (emit Symbol_name variable
                           (emit Operator " = "
                              (Render_expression (-1, replacement)
                              :: emit Punctuation ")" trailing)))))
          | Centl_Core.Simplify inner ->
              Render_call ("simplify", [ inner ]) :: trailing
          | Centl_Core.Expand inner ->
              Render_call ("expand", [ inner ]) :: trailing
          | Centl_Core.Factor inner ->
              Render_call ("factor", [ inner ]) :: trailing
          | Centl_Core.Assuming (inner, left, relation, right) ->
              Render_expression (0, inner)
              :: emit Punctuation " where "
                   (Render_expression (-1, left)
                   :: emit Operator
                        (" " ^ relation_text relation ^ " ")
                        (Render_expression (-1, right) :: trailing))
        in
        let commands =
          if parenthesized then emit Punctuation "(" body else body
        in
        render reversed commands
    | Render_solution (Rational_solution value) :: rest ->
        render reversed (Render_literal value :: rest)
    | Render_solution (Real_quadratic { center; radicand; branch }) :: rest ->
        let square_root rest =
          emit Function_name "sqrt"
            (emit Punctuation "("
               (Render_literal radicand :: emit Punctuation ")" rest))
        in
        let commands =
          if Z.equal (fst center) Z.zero then
            begin match branch with
            | Lower -> emit Operator "-" (square_root rest)
            | Upper -> square_root rest
            end
          else
            Render_literal center
            :: emit Operator
                 (match branch with Lower -> " - " | Upper -> " + ")
                 (square_root rest)
        in
        render reversed commands
    | Render_solutions [] :: rest -> render reversed rest
    | Render_solutions (solution :: solutions) :: rest ->
        let rest =
          match solutions with
          | [] -> rest
          | _ -> emit Punctuation ", " (Render_solutions solutions :: rest)
        in
        render reversed (Render_solution solution :: rest)
    | Render_equation_call result :: rest ->
        render reversed
          (emit Function_name "solve"
             (emit Punctuation "("
                (Render_expression (-1, result.left)
                :: emit Operator " = "
                     (Render_expression (-1, result.right)
                     :: emit Punctuation ", "
                          (emit Symbol_name result.variable
                             (emit Punctuation ")" rest))))))
    | Render_equation_result result :: rest ->
        let commands =
          match result.status with
          | Finite_solutions [ solution ] ->
              emit Symbol_name result.variable
                (emit Operator " = " (Render_solution solution :: rest))
          | Finite_solutions solutions ->
              emit Symbol_name result.variable
                (emit Operator " in "
                   (emit Punctuation "{"
                      (Render_solutions solutions :: emit Punctuation "}" rest)))
          | No_solutions -> emit Punctuation "no solutions" rest
          | All_values ->
              emit Punctuation "all values of "
                (emit Symbol_name result.variable rest)
          | Unresolved ->
              emit Punctuation "unresolved: "
                (Render_equation_call result :: rest)
        in
        render reversed commands
    | Render_value value :: rest ->
        let commands =
          match value with
          | Integer value -> emit Number (Z.to_string value) rest
          | Rational (numerator, denominator) ->
              Render_literal (numerator, denominator) :: rest
          | Symbolic expression -> Render_expression (-1, expression) :: rest
          | Exact_sequence values ->
              emit Punctuation "["
                (Render_core_values values :: emit Punctuation "]" rest)
          | Real_enclosure enclosure ->
              if enclosure.lower_decimal = enclosure.upper_decimal then
                emit Operator "≈ " (emit Number enclosure.lower_decimal rest)
              else
                emit Operator "≈ "
                  (emit Punctuation "["
                     (emit Number enclosure.lower_decimal
                        (emit Punctuation ", "
                           (emit Number enclosure.upper_decimal
                              (emit Punctuation "]" rest)))))
          | Equation_result result -> Render_equation_result result :: rest
        in
        render reversed commands
  in
  render [] commands

let expression_fragments ?(parent_precedence = -1) expression =
  render_fragment_commands [ Render_expression (parent_precedence, expression) ]

let call_fragments name arguments =
  render_fragment_commands [ Render_call (name, arguments) ]

let solution_fragments (numerator, denominator) =
  render_fragment_commands
    [ Render_solution (Rational_solution (numerator, denominator)) ]

let solution_list_fragments solutions =
  render_fragment_commands
    [
      Render_solutions
        (List.map (fun value -> Rational_solution value) solutions);
    ]

let equation_call_fragments result =
  render_fragment_commands [ Render_equation_call result ]

let equation_result_fragments result =
  render_fragment_commands [ Render_equation_result result ]

let fragments_of_value value = render_fragment_commands [ Render_value value ]

let text_of_fragments fragments =
  let buffer = Buffer.create 256 in
  List.iter (fun (_, text) -> Buffer.add_string buffer text) fragments;
  Buffer.contents buffer

let text_of_value value = value |> fragments_of_value |> text_of_fragments

let ansi_code = function
  | Number -> "96"
  | Symbol_name -> "95"
  | Function_name -> "94"
  | Operator -> "93"
  | Punctuation -> "2;37"

let colored_text_of_fragments fragments =
  let buffer = Buffer.create 256 in
  List.iter
    (fun (style, text) ->
      Buffer.add_string buffer "\027[";
      Buffer.add_string buffer (ansi_code style);
      Buffer.add_char buffer 'm';
      Buffer.add_string buffer text;
      Buffer.add_string buffer "\027[0m")
    fragments;
  Buffer.contents buffer

let colored_text_of_value value =
  fragments_of_value value |> colored_text_of_fragments

let fragments_of_session_result = function
  | Session_value value -> render_fragment_commands [ Render_value value ]
  | Defined_value (name, value) ->
      render_fragment_commands
        [
          Emit_fragment (Symbol_name, name);
          Emit_fragment (Operator, " = ");
          Render_value value;
        ]
  | Defined_function (name, parameters, body) ->
      render_fragment_commands
        [
          Emit_fragment (Function_name, name);
          Emit_fragment (Punctuation, "(");
          Render_parameter_arguments parameters;
          Emit_fragment (Punctuation, ")");
          Emit_fragment (Operator, " = ");
          Render_expression (-1, body);
        ]

let text_of_session_result result =
  result |> fragments_of_session_result |> text_of_fragments

let colored_text_of_session_result result =
  result |> fragments_of_session_result |> colored_text_of_fragments

let error_text error =
  match error.position with
  | None -> error.message
  | Some position ->
      Printf.sprintf "%s at column %d" error.message (position + 1)

let relation_code = function
  | Centl_Core.Equal -> "equal"
  | Centl_Core.NotEqual -> "not_equal"
  | Centl_Core.LessThan -> "less_than"
  | Centl_Core.LessOrEqual -> "less_or_equal"
  | Centl_Core.GreaterThan -> "greater_than"
  | Centl_Core.GreaterOrEqual -> "greater_or_equal"

let json_of_condition left relation right =
  let left_text = expression_fragments left |> text_of_fragments in
  let right_text = expression_fragments right |> text_of_fragments in
  `Assoc
    [
      ("left", `String left_text);
      ("relation", `String (relation_code relation));
      ("right", `String right_text);
      ( "text",
        `String (left_text ^ " " ^ relation_text relation ^ " " ^ right_text) );
    ]

let rec conditions_of_expression = function
  | Centl_Core.Assuming (inner, left, relation, right) ->
      json_of_condition left relation right :: conditions_of_expression inner
  | _ -> []

let json_of_provenance ~classification ~method_ ~backend =
  `Assoc
    [
      ("schema", `Int 1);
      ( "producer",
        `Assoc
          [
            ("name", `String "centl"); ("version", `String Centl_version.value);
          ] );
      ("classification", `String classification);
      ("method", `String method_);
      ("backend", `String backend);
    ]

let provenance_of_value = function
  | Integer _ | Rational _ ->
      json_of_provenance ~classification:"exact" ~method_:"rational_evaluation"
        ~backend:"centl-core"
  | Symbolic _ ->
      json_of_provenance ~classification:"exact_symbolic"
        ~method_:"symbolic_evaluation" ~backend:"centl-core"
  | Exact_sequence _ ->
      json_of_provenance ~classification:"exact_sequence"
        ~method_:"finite_iteration" ~backend:"centl-iteration"
  | Real_enclosure _ ->
      json_of_provenance ~classification:"rigorous_enclosure"
        ~method_:"interval_evaluation" ~backend:"flint-arb"
  | Equation_result { status = Unresolved; _ } ->
      json_of_provenance ~classification:"unresolved"
        ~method_:"equation_solving" ~backend:"centl-exact"
  | Equation_result { status = Finite_solutions solutions; _ }
    when List.exists
           (function Real_quadratic _ -> true | Rational_solution _ -> false)
           solutions ->
      json_of_provenance ~classification:"exact_solution_set"
        ~method_:"verified_quadratic_solving" ~backend:"centl-core"
  | Equation_result _ ->
      json_of_provenance ~classification:"exact_solution_set"
        ~method_:"equation_solving" ~backend:"centl-exact"

let provenance_of_session_result = function
  | Session_value value -> provenance_of_value value
  | Defined_value _ | Defined_function _ ->
      json_of_provenance ~classification:"exact_definition"
        ~method_:"session_binding" ~backend:"centl-session"

let provenance_of_error error =
  if error.code = "cancelled" then
    json_of_provenance ~classification:"cancelled"
      ~method_:"cooperative_cancellation" ~backend:"centl-runtime"
  else
    json_of_provenance ~classification:"failure" ~method_:"evaluation"
      ~backend:"centl-runtime"

let rec json_of_value = function
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
      let fields =
        [
          ("kind", `String "symbolic");
          ("exact", `Bool true);
          ("expression", `String text);
          ("text", `String text);
        ]
      in
      let conditions = conditions_of_expression expression in
      let fields =
        match conditions with
        | [] -> fields
        | conditions -> fields @ [ ("conditions", `List conditions) ]
      in
      `Assoc fields
  | Exact_sequence values ->
      let json_of_core_value = function
        | Centl_Core.ExactRational value ->
            if Z.equal value.denominator Z.one then
              json_of_value (Integer value.numerator)
            else json_of_value (Rational (value.numerator, value.denominator))
        | Centl_Core.ExactSymbolic expression ->
            json_of_value (Symbolic expression)
      in
      `Assoc
        [
          ("kind", `String "sequence");
          ("exact", `Bool true);
          ("length", `Int (List.length values));
          ("items", `List (List.map json_of_core_value values));
          ("text", `String (text_of_value (Exact_sequence values)));
        ]
  | Real_enclosure enclosure ->
      let text = text_of_value (Real_enclosure enclosure) in
      `Assoc
        [
          ("kind", `String "real_enclosure");
          ("exact", `Bool false);
          ("text", `String text);
          ( "dyadic",
            `Assoc
              [
                ( "lower_mantissa",
                  `String (Z.to_string enclosure.lower_mantissa) );
                ( "upper_mantissa",
                  `String (Z.to_string enclosure.upper_mantissa) );
                ("binary_exponent", `Int enclosure.binary_exponent);
              ] );
          ( "decimal",
            `Assoc
              [
                ("lower", `String enclosure.lower_decimal);
                ("upper", `String enclosure.upper_decimal);
                ("requested_significant_digits", `Int enclosure.requested_digits);
                ("certified_significant_digits", `Int enclosure.requested_digits);
              ] );
          ( "precision",
            `Assoc
              [
                ("working_bits", `Int enclosure.working_bits);
                ("backend", `String "flint-arb");
                ("rigorous", `Bool true);
              ] );
        ]
  | Equation_result result ->
      let rational_json (numerator, denominator) =
        let text =
          if Z.equal denominator Z.one then Z.to_string numerator
          else Z.to_string numerator ^ "/" ^ Z.to_string denominator
        in
        `Assoc
          [
            ("numerator", `String (Z.to_string numerator));
            ("denominator", `String (Z.to_string denominator));
            ("text", `String text);
          ]
      in
      let equation_solution_json = function
        | Rational_solution value -> rational_json value
        | Real_quadratic { center; radicand; branch } as solution ->
            let rational_components (numerator, denominator) =
              `Assoc
                [
                  ("numerator", `String (Z.to_string numerator));
                  ("denominator", `String (Z.to_string denominator));
                ]
            in
            let text =
              render_fragment_commands [ Render_solution solution ]
              |> text_of_fragments
            in
            `Assoc
              [
                ("kind", `String "real_quadratic");
                ("exact", `Bool true);
                ( "branch",
                  `String
                    (match branch with Lower -> "lower" | Upper -> "upper") );
                ("center", rational_components center);
                ("radicand", rational_components radicand);
                ("text", `String text);
              ]
      in
      let status, solutions, resolved =
        match result.status with
        | Finite_solutions solutions ->
            ("finite", List.map equation_solution_json solutions, true)
        | No_solutions -> ("none", [], true)
        | All_values -> ("all", [], true)
        | Unresolved -> ("unresolved", [], false)
      in
      let left = expression_fragments result.left |> text_of_fragments in
      let right = expression_fragments result.right |> text_of_fragments in
      `Assoc
        [
          ("kind", `String "solution_set");
          ("exact", `Bool true);
          ("resolved", `Bool resolved);
          ("status", `String status);
          ("variable", `String result.variable);
          ("solutions", `List solutions);
          ( "equation",
            `Assoc [ ("left", `String left); ("right", `String right) ] );
          ("text", `String (text_of_value (Equation_result result)));
        ]

let json_of_session_result = function
  | Session_value value -> json_of_value value
  | Defined_value (name, value) ->
      `Assoc
        [
          ("kind", `String "definition");
          ("exact", `Bool true);
          ("definition_kind", `String "value");
          ("name", `String name);
          ("value", json_of_value value);
          ("text", `String (name ^ " = " ^ text_of_value value));
        ]
  | Defined_function (name, parameters, body) ->
      let expression = expression_fragments body |> text_of_fragments in
      `Assoc
        [
          ("kind", `String "definition");
          ("exact", `Bool true);
          ("definition_kind", `String "function");
          ("name", `String name);
          ("parameters", `List (List.map (fun name -> `String name) parameters));
          ("expression", `String expression);
          ( "text",
            `String
              (Printf.sprintf "%s(%s) = %s" name
                 (String.concat ", " parameters)
                 expression) );
        ]

let json_of_evaluation = function
  | Ok value ->
      `Assoc
        [
          ("version", `Int 1);
          ("ok", `Bool true);
          ("value", json_of_value value);
          ("provenance", provenance_of_value value);
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
        [
          ("version", `Int 1);
          ("ok", `Bool false);
          ("error", `Assoc fields);
          ("provenance", provenance_of_error error);
        ]

let json_of_session_evaluation = function
  | Ok result ->
      `Assoc
        [
          ("version", `Int 1);
          ("ok", `Bool true);
          ("value", json_of_session_result result);
          ("provenance", provenance_of_session_result result);
        ]
  | Error error -> json_of_evaluation (Error error)

let invalid_request message =
  json_of_evaluation
    (Error { code = "invalid_request"; message; position = None })

let with_request_id id = function
  | `Assoc fields ->
      begin match id with
      | None -> `Assoc fields
      | Some id ->
          let rec insert = function
            | [] -> [ ("id", id) ]
            | (("version", _) as version) :: rest ->
                version :: ("id", id) :: rest
            | field :: rest -> field :: insert rest
          in
          `Assoc (insert fields)
      end
  | json -> json

let stateless_request_id fields =
  match List.assoc_opt "id" fields with
  | None -> Ok None
  | Some ((`String _ | `Int _ | `Intlit _) as id) -> Ok (Some id)
  | Some _ -> Error "id must be a string or integer"

let evaluate_request json =
  match json with
  | `Assoc fields ->
      begin match stateless_request_id fields with
      | Error message -> invalid_request message
      | Ok id ->
          let respond response = with_request_id id response in
          begin match
            List.find_opt
              (fun (name, _) ->
                not
                  (List.mem name
                     [ "version"; "id"; "op"; "expression"; "limits" ]))
              fields
          with
          | Some (name, _) ->
              respond (invalid_request ("unknown request field " ^ name))
          | None ->
              begin match List.assoc_opt "op" fields with
              | None | Some (`String "evaluate") ->
                  begin match
                    ( List.assoc_opt "version" fields,
                      List.assoc_opt "expression" fields )
                  with
                  | Some (`Int 1), Some (`String expression) ->
                      begin match
                        requested_evaluation_limits
                          ~ceiling:default_evaluation_limits fields
                      with
                      | Ok limits ->
                          respond
                            (json_of_evaluation
                               (evaluate_with_limits limits expression))
                      | Error message -> respond (invalid_request message)
                      end
                  | Some (`Int version), _ when version <> 1 ->
                      respond (invalid_request "unsupported protocol version")
                  | _, None -> respond (invalid_request "missing expression")
                  | _ ->
                      respond
                        (invalid_request
                           "version must be 1 and expression must be a string")
                  end
              | Some (`String operation) ->
                  respond (invalid_request ("unknown operation " ^ operation))
              | Some _ -> respond (invalid_request "op must be a string")
              end
          end
      end
  | _ -> invalid_request "request must be a JSON object"
