type real_enclosure = {
  lower_mantissa : Z.t;
  upper_mantissa : Z.t;
  binary_exponent : int;
  lower_decimal : string;
  upper_decimal : string;
  requested_digits : int;
  working_bits : int;
}

type equation_status =
  | Finite_solutions of (Z.t * Z.t) list
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

let rec native_value expression precision =
  let ( let* ) result next = Result.bind result next in
  match expression with
  | Centl_Core.Literal (numerator, denominator) ->
      if Z.equal denominator Z.zero then
        Error (Domain_error "a literal denominator cannot be zero")
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
        (Unsupported
           (Printf.sprintf "cannot approximate the unresolved symbol %s" name))
  | Centl_Core.Negate inner ->
      let* value = native_value inner precision in
      Ok (Centl_arb.neg value)
  | Centl_Core.Binary (operator, left, right) ->
      let* left_value = native_value left precision in
      let* right_value = native_value right precision in
      begin match operator with
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
              (Uncertain_domain "could not prove that the divisor excludes zero")
          else ensure_finite (Centl_arb.div left_value right_value precision)
      end
  | Centl_Core.Power (base, exponent) ->
      if (not (Z.fits_int exponent)) || Z.gt (Z.abs exponent) (Z.of_int 100_000)
      then
        Error
          (Unsupported "the integer exponent exceeds the approximation limit")
      else
        let* base_value = native_value base precision in
        let exponent = Z.to_int exponent in
        if exponent < 0 && Centl_arb.is_zero base_value then
          Error (Domain_error "zero cannot be raised to a negative power")
        else if exponent < 0 && not (Centl_arb.is_nonzero base_value) then
          Error
            (Uncertain_domain
               "could not prove that the base of a negative power excludes zero")
        else ensure_finite (Centl_arb.pow base_value exponent precision)
  | Centl_Core.Function ("abs", [ argument ]) ->
      let* value = native_value argument precision in
      Ok (Centl_arb.abs value)
  | Centl_Core.Function (name, [ argument ]) ->
      let* value = native_value argument precision in
      begin match name with
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
      | _ -> Error (Unsupported ("cannot rigorously approximate " ^ name))
      end
  | Centl_Core.Function ("atan2", [ y; x ]) ->
      let* y_value = native_value y precision in
      let* x_value = native_value x precision in
      if Centl_arb.is_zero y_value && Centl_arb.is_zero x_value then
        Error (Domain_error "atan2(0, 0) is undefined")
      else ensure_finite (Centl_arb.atan2 y_value x_value precision)
  | Centl_Core.Function (name, _) ->
      Error
        (Unsupported
           (Printf.sprintf "%s has unsupported arguments for approximation" name))
  | Centl_Core.Assuming (inner, _, _, _) -> native_value inner precision
  | Centl_Core.Differentiate _ | Centl_Core.Substitute _
  | Centl_Core.Derivative _ | Centl_Core.Simplify _ | Centl_Core.Expand _
  | Centl_Core.Factor _ ->
      Error
        (Unsupported "this unresolved symbolic operation cannot be approximated")

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

let approximate_with_limits ?(cancelled = never_cancelled) limits expression
    requested_digits =
  let ( let* ) result next = Result.bind result next in
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
        let retry message =
          if working_bits >= working_limit then
            failure "insufficient_precision" message
          else attempt (min working_limit (working_bits * 2))
        in
        let native_result = native_value expression working_bits in
        let* () = check_cancelled cancelled in
        match native_result with
        | Error (Domain_error message) -> failure "domain_error" message
        | Error (Unsupported message) ->
            failure "unsupported_approximation" message
        | Error (Resource_limit_failure message) ->
            failure "resource_limit" message
        | Error (Backend_failure message) -> failure "backend_failure" message
        | Error (Uncertain_domain message) -> retry message
        | Ok ball ->
            begin match
              enclosure_of_ball ball requested_digits working_bits
            with
            | Error (Backend_failure message) ->
                failure "backend_failure" message
            | Error (Uncertain_domain message) -> retry message
            | Error (Domain_error message) -> failure "domain_error" message
            | Error (Unsupported message) ->
                failure "unsupported_approximation" message
            | Error (Resource_limit_failure message) ->
                failure "resource_limit" message
            | Ok (value, true) -> Ok value
            | Ok (_, false) ->
                retry
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

let complete_quadratic variable left right leading linear discriminant =
  match
    exact_square_root discriminant.Centl_Core.numerator discriminant.denominator
  with
  | None -> equation_result variable left right Unresolved
  | Some root ->
      begin match
        Centl_Core.complete_rational_quadratic leading linear discriminant root
      with
      | Centl_Core.TwoEquationSolutions (first, second) ->
          let ( let* ) result next = Result.bind result next in
          let* first = rational_pair_from_core first in
          let* second = rational_pair_from_core second in
          let solutions =
            List.sort_uniq compare_rational_pairs [ first; second ]
          in
          equation_result variable left right (Finite_solutions solutions)
      | _ ->
          failure "core_contract_violation"
            "the verified core rejected a validated quadratic root"
      end

let solve_equation left right variable =
  let ( let* ) result next = Result.bind result next in
  if List.mem variable [ "pi"; "e"; "tau" ] then
    failure "invalid_solution_variable"
      (variable ^ " is a constant, not a solution variable")
  else
    let* _ = evaluate_exact left in
    let* _ = evaluate_exact right in
    match Centl_Core.solve_equation left right variable with
    | Centl_Core.NoEquationSolutions ->
        equation_result variable left right No_solutions
    | Centl_Core.AllEquationValues ->
        equation_result variable left right All_values
    | Centl_Core.OneEquationSolution solution ->
        let* solution = rational_pair_from_core solution in
        equation_result variable left right (Finite_solutions [ solution ])
    | Centl_Core.TwoEquationSolutions (first, second) ->
        let* first = rational_pair_from_core first in
        let* second = rational_pair_from_core second in
        equation_result variable left right
          (Finite_solutions
             (List.sort_uniq compare_rational_pairs [ first; second ]))
    | Centl_Core.RationalQuadratic (leading, linear, discriminant) ->
        complete_quadratic variable left right leading linear discriminant
    | Centl_Core.UnresolvedEquation ->
        equation_result variable left right Unresolved

let solution_request = function
  | Centl_Core.Function ("solve", [ left; right; Centl_Core.Symbol variable ])
    ->
      Some (solve_equation left right variable)
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

let rec expression_node_count = function
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> 1
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      1 + expression_node_count inner
  | Centl_Core.Binary (_, left, right) ->
      1 + expression_node_count left + expression_node_count right
  | Centl_Core.Function (_, arguments) ->
      1
      + List.fold_left
          (fun total argument -> total + expression_node_count argument)
          0 arguments
  | Centl_Core.Substitute (inner, _, replacement) ->
      1 + expression_node_count inner + expression_node_count replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      1
      + expression_node_count inner
      + expression_node_count left
      + expression_node_count right

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
      (("sum" | "product"), [ body; Centl_Core.Symbol variable; lower; upper ])
    ->
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
  | Centl_Core.Function (_, arguments) -> children 1 arguments
  | Centl_Core.Substitute (inner, _, replacement) ->
      children 1 [ inner; replacement ]
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
    | Some bits when Z.gt bits (Z.of_int limits.max_exact_bits) ->
        failure "resource_limit" "the exact result exceeds the bit limit"
    | bits -> Ok bits
  in
  let add_optional left right =
    match (left, right) with
    | Some left, Some right -> Some (Z.add left right)
    | _ -> None
  in
  let rec estimate expression =
    let* () = check_cancelled cancelled in
    let* bits =
      match expression with
      | Centl_Core.Literal (numerator, denominator) ->
          Ok
            (Some
               (Z.of_int
                  (bits_of_integer numerator + bits_of_integer denominator)))
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
               (fun bits -> Z.mul bits (Z.max Z.one (Z.abs exponent)))
               base)
      | Centl_Core.Binary (_, left, right) ->
          let* left = estimate left in
          let* right = estimate right in
          Ok (Option.map (Z.add Z.one) (add_optional left right))
      | Centl_Core.Function ("factorial", [ argument ]) ->
          let* _ = estimate argument in
          Ok
            (Option.map
               (fun value -> Z.mul value (Z.of_int (bits_of_integer value)))
               (natural_value argument))
      | Centl_Core.Function ("fibonacci", [ argument ]) ->
          let* _ = estimate argument in
          Ok
            (Option.map
               (fun value -> Z.add value Z.one)
               (natural_value argument))
      | Centl_Core.Function ("choose", [ n_argument; k_argument ]) ->
          let* _ = estimate n_argument in
          let* _ = estimate k_argument in
          Ok
            (match (natural_value n_argument, natural_value k_argument) with
            | Some n, Some _ -> Some (Z.add n Z.one)
            | _ -> None)
      | Centl_Core.Function ("permutations", [ n_argument; k_argument ]) ->
          let* _ = estimate n_argument in
          let* _ = estimate k_argument in
          Ok
            (match (natural_value n_argument, natural_value k_argument) with
            | Some n, Some k -> Some (Z.mul k (Z.of_int (bits_of_integer n)))
            | _ -> None)
      | Centl_Core.Function (_, arguments) ->
          estimate_arguments (Some Z.one) arguments
      | Centl_Core.Substitute (inner, _, replacement) ->
          let* inner = estimate inner in
          let* replacement = estimate replacement in
          Ok (add_optional inner replacement)
      | Centl_Core.Assuming (inner, left, _, right) ->
          let* inner = estimate inner in
          let* _ = estimate left in
          let* _ = estimate right in
          Ok inner
    in
    checked bits
  and estimate_arguments total = function
    | [] -> Ok total
    | argument :: rest ->
        let* bits = estimate argument in
        estimate_arguments (add_optional total bits) rest
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
          (("sum" | "product"), [ _; Centl_Core.Symbol _; lower; upper ]) ->
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

let result_render_bytes limit value =
  let add left right = bounded_sum limit left right in
  let integer value = String.length (Z.to_string value) in
  let expression = Centl_iteration.expression_render_bytes limit in
  let rational numerator denominator =
    add (integer numerator) (integer denominator)
  in
  match value with
  | Integer value -> add 64 (integer value)
  | Rational (numerator, denominator) -> add 64 (rational numerator denominator)
  | Symbolic value -> add 64 (expression value)
  | Real_enclosure enclosure ->
      add 256
        (add
           (add
              (integer enclosure.lower_mantissa)
              (integer enclosure.upper_mantissa))
           (add
              (String.length enclosure.lower_decimal)
              (String.length enclosure.upper_decimal)))
  | Equation_result equation ->
      let solutions =
        match equation.status with
        | Finite_solutions values ->
            List.fold_left
              (fun total (numerator, denominator) ->
                add total (rational numerator denominator))
              0 values
        | No_solutions | All_values | Unresolved -> 0
      in
      add 256
        (add
           (String.length equation.variable)
           (add (expression equation.left)
              (add (expression equation.right) solutions)))

let check_result_limit limits value =
  if result_render_bytes limits.max_result_bytes value > limits.max_result_bytes
  then failure "resource_limit" "the result exceeds the byte limit"
  else Ok ()

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
    "sum";
    "product";
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
                Z.add Z.one (Z.max left.coefficient_bits right.coefficient_bits);
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

let contains_iteration =
  contains_named_function (fun name -> name = "sum" || name = "product")

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

let iteration_value_of_exact = function
  | Integer value -> Ok (Centl_Core.ExactRational (Centl_Core.make value Z.one))
  | Rational (numerator, denominator) ->
      Ok (Centl_Core.ExactRational (Centl_Core.make numerator denominator))
  | Symbolic expression -> Ok (Centl_Core.ExactSymbolic expression)
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

let resolve_with_limits ?(cancelled = never_cancelled) limits expression =
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
  let rec resolve expression =
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
          let evaluate_term term =
            match resolve term with
            | Error error ->
                Error (Centl_iteration.Term_error (error.code, error.message))
            | Ok (term, _) ->
                if
                  contains_named_function
                    (fun function_name ->
                      function_name = "approx" || function_name = "solve")
                    term
                then
                  Error
                    (Centl_iteration.Term_error
                       ( "exact_iteration_required",
                         "finite iteration terms must be exact expressions" ))
                else
                  begin match evaluate_exact term with
                  | Error error ->
                      Error
                        (Centl_iteration.Term_error (error.code, error.message))
                  | Ok value -> iteration_value_of_exact value
                  end
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
        if contains_iteration inner then
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
        let* () = check_polynomial_transformation limits inner in
        let transformed = Centl_Core.canonicalize_polynomial inner in
        checked transformed (expression_node_count transformed)
    | Centl_Core.Factor inner ->
        let* inner, _ = resolve inner in
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
  and resolve_iteration_bound label expression =
    let* expression, _ = resolve expression in
    match evaluate_exact expression with
    | Ok (Integer value) -> Ok (Centl_Core.Literal (value, Z.one))
    | Ok _ ->
        failure "invalid_arguments"
          (Printf.sprintf
             "the %s finite-iteration bound must be an exact integer" label)
    | Error _ as error -> error
  in
  let* expression, _ = resolve expression in
  Ok expression

let evaluate_expression_with_limits ?(cancelled = never_cancelled) limits
    expression =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  let* () = check_expression_limit limits expression in
  let* () = check_computation_limit ~cancelled limits expression in
  let* expression = resolve_with_limits ~cancelled limits expression in
  let* () = check_expression_limit limits expression in
  let* () = check_computation_limit ~cancelled limits expression in
  let result =
    match solution_request expression with
    | Some result -> result
    | None when contains_solution expression ->
        failure "solution_set_not_expression"
          "solve(...) returns a solution set and must be evaluated on its own"
    | None ->
        begin match approximation_request expression with
        | Some (Ok (inner, digits)) ->
            approximate_with_limits ~cancelled limits inner digits
        | Some (Error _ as error) -> error
        | None -> evaluate_exact expression
        end
  in
  let* value = result in
  let* () = check_result_limit limits value in
  let* () = check_cancelled cancelled in
  Ok value

let evaluate_expression expression =
  evaluate_expression_with_limits default_evaluation_limits expression

let evaluate_with_limits ?(cancelled = never_cancelled) limits source =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  let* () = check_source_limit limits source in
  match Centl_parser.parse source with
  | Error parse_error -> syntax_error parse_error
  | Ok expression ->
      let* () = check_cancelled cancelled in
      evaluate_expression_with_limits ~cancelled limits expression

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
let session_failure code message = Error { code; message; position = None }

type retention_cost = { nodes : int; bits : int; bytes : int }

let check_session_retention limits session ~metadata_bytes expression =
  let nodes = expression_node_count expression in
  let bits =
    Centl_iteration.expression_exact_bits limits.max_exact_bits expression
  in
  let bytes =
    bounded_sum limits.max_result_bytes (64 + metadata_bytes)
      (Centl_iteration.expression_render_bytes limits.max_result_bytes
         expression)
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

let rec expand_expression ?(cancelled = never_cancelled) limit session bound
    expression =
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
              else Ok (value, nodes)
          | Some (Bound_function _) ->
              session_failure "invalid_arguments"
                (name ^ " is a function; call it with parentheses")
          end
    | Centl_Core.Negate inner ->
        let* inner, nodes =
          expand_expression ~cancelled (limit - 1) session bound inner
        in
        Ok (Centl_Core.Negate inner, nodes + 1)
    | Centl_Core.Binary (operator, left, right) ->
        let* left, left_nodes =
          expand_expression ~cancelled (limit - 1) session bound left
        in
        let* right, right_nodes =
          expand_expression ~cancelled
            (limit - 1 - left_nodes)
            session bound right
        in
        Ok
          ( Centl_Core.Binary (operator, left, right),
            left_nodes + right_nodes + 1 )
    | Centl_Core.Power (base, exponent) ->
        let* base, nodes =
          expand_expression ~cancelled (limit - 1) session bound base
        in
        Ok (Centl_Core.Power (base, exponent), nodes + 1)
    | Centl_Core.Function
        ( (("sum" | "product") as name),
          [ body; Centl_Core.Symbol variable; lower; upper ] ) ->
        let* body, body_nodes =
          expand_expression ~cancelled (limit - 2) session (variable :: bound)
            body
        in
        let* lower, lower_nodes =
          expand_expression ~cancelled
            (limit - 2 - body_nodes)
            session bound lower
        in
        let* upper, upper_nodes =
          expand_expression ~cancelled
            (limit - 2 - body_nodes - lower_nodes)
            session bound upper
        in
        Ok
          ( Centl_Core.Function
              (name, [ body; Centl_Core.Symbol variable; lower; upper ]),
            body_nodes + lower_nodes + upper_nodes + 2 )
    | Centl_Core.Function ("solve", [ left; right; Centl_Core.Symbol variable ])
      ->
        let* left, left_nodes =
          expand_expression ~cancelled (limit - 2) session (variable :: bound)
            left
        in
        let* right, right_nodes =
          expand_expression ~cancelled
            (limit - 2 - left_nodes)
            session (variable :: bound) right
        in
        Ok
          ( Centl_Core.Function
              ("solve", [ left; right; Centl_Core.Symbol variable ]),
            left_nodes + right_nodes + 2 )
    | Centl_Core.Function (name, arguments) ->
        let* arguments, argument_nodes =
          expand_arguments ~cancelled (limit - 1) session bound arguments
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
                  Ok
                    ( instantiate definition.parameters arguments definition.body,
                      nodes )
              end
          end
    | Centl_Core.Differentiate (inner, variable) ->
        let* inner, nodes =
          expand_expression ~cancelled (limit - 1) session (variable :: bound)
            inner
        in
        Ok (Centl_Core.Differentiate (inner, variable), nodes + 1)
    | Centl_Core.Substitute (inner, variable, replacement) ->
        let* inner, inner_nodes =
          expand_expression ~cancelled (limit - 1) session (variable :: bound)
            inner
        in
        let* replacement, replacement_nodes =
          expand_expression ~cancelled
            (limit - 1 - inner_nodes)
            session bound replacement
        in
        Ok
          ( Centl_Core.Substitute (inner, variable, replacement),
            inner_nodes + replacement_nodes + 1 )
    | Centl_Core.Derivative (inner, variable) ->
        let* inner, nodes =
          expand_expression ~cancelled (limit - 1) session (variable :: bound)
            inner
        in
        Ok (Centl_Core.Derivative (inner, variable), nodes + 1)
    | Centl_Core.Simplify inner ->
        let* inner, nodes =
          expand_expression ~cancelled (limit - 1) session bound inner
        in
        Ok (Centl_Core.Simplify inner, nodes + 1)
    | Centl_Core.Expand inner ->
        let* inner, nodes =
          expand_expression ~cancelled (limit - 1) session bound inner
        in
        Ok (Centl_Core.Expand inner, nodes + 1)
    | Centl_Core.Factor inner ->
        let* inner, nodes =
          expand_expression ~cancelled (limit - 1) session bound inner
        in
        Ok (Centl_Core.Factor inner, nodes + 1)
    | Centl_Core.Assuming (inner, left, relation, right) ->
        let* inner, inner_nodes =
          expand_expression ~cancelled (limit - 1) session bound inner
        in
        let* left, left_nodes =
          expand_expression ~cancelled
            (limit - 1 - inner_nodes)
            session bound left
        in
        let* right, right_nodes =
          expand_expression ~cancelled
            (limit - 1 - inner_nodes - left_nodes)
            session bound right
        in
        Ok
          ( Centl_Core.Assuming (inner, left, relation, right),
            inner_nodes + left_nodes + right_nodes + 1 )

and expand_arguments ?(cancelled = never_cancelled) limit session bound
    arguments =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  match arguments with
  | [] -> Ok ([], 0)
  | argument :: rest ->
      let* argument, argument_nodes =
        expand_expression ~cancelled limit session bound argument
      in
      let* rest, rest_nodes =
        expand_arguments ~cancelled (limit - argument_nodes) session bound rest
      in
      Ok (argument :: rest, argument_nodes + rest_nodes)

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
    when function_name = "sum" || function_name = "product" ->
      function_name = name
      || (variable <> name && references_name name body)
      || references_name name lower || references_name name upper
  | Centl_Core.Function (function_name, arguments) ->
      function_name = name || List.exists (references_name name) arguments
  | Centl_Core.Literal _ -> false
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      references_name name inner
  | Centl_Core.Binary (_, left, right) ->
      references_name name left || references_name name right
  | Centl_Core.Substitute (inner, _, replacement) ->
      references_name name inner || references_name name replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      references_name name inner || references_name name left
      || references_name name right

let expression_of_exact_value = function
  | Integer value -> Centl_Core.Literal (value, Z.one)
  | Rational (numerator, denominator) ->
      Centl_Core.Literal (numerator, denominator)
  | Symbolic expression -> expression
  | Real_enclosure _ | Equation_result _ -> assert false

let validate_definition_name session name =
  if List.mem name reserved_names then
    session_failure "reserved_name"
      (name ^ " is built in and cannot be redefined")
  else if Option.is_some (lookup session name) then
    session_failure "immutable_definition"
      (name ^ " is already defined; definitions are immutable")
  else Ok ()

let validate_parameters name parameters =
  if parameters = [] then
    session_failure "invalid_definition"
      "a function definition needs at least one parameter"
  else if List.mem name parameters then
    session_failure "invalid_definition"
      "a function cannot use its own name as a parameter"
  else if
    List.exists (fun parameter -> List.mem parameter reserved_names) parameters
  then
    session_failure "reserved_name"
      "function parameters cannot use built-in names"
  else
    let unique = List.sort_uniq String.compare parameters in
    if List.length unique <> List.length parameters then
      session_failure "invalid_definition" "function parameters must be unique"
    else Ok ()

let prepare_definition ?(cancelled = never_cancelled) limits session bound name
    expression =
  let ( let* ) result next = Result.bind result next in
  let* () = check_cancelled cancelled in
  let* expression, _ =
    expand_expression ~cancelled limits.max_expression_nodes session bound
      expression
  in
  if references_name name expression then
    session_failure "recursive_definition"
      (name ^ " cannot be defined in terms of itself")
  else if contains_approximation expression then
    session_failure "exact_definition_required"
      "definitions must be exact; use approx(...) when evaluating them"
  else if bound <> [] && contains_iteration expression then
    if
      contains_named_function
        (fun function_name -> function_name = "solve")
        expression
    then
      session_failure "expression_definition_required"
        "solution sets cannot be stored in definitions yet"
    else
      let* () = check_result_limit limits (Symbolic expression) in
      Ok (Symbolic expression, expression)
  else
    let* value = evaluate_expression_with_limits ~cancelled limits expression in
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
  let parsed = Centl_parser.parse_statement source in
  let* () = check_cancelled cancelled in
  match parsed with
  | Error parse_error -> syntax_error parse_error
  | Ok (Centl_parser.Evaluate expression) ->
      let* expression, _ =
        expand_expression ~cancelled limits.max_expression_nodes session []
          expression
      in
      Result.map
        (fun value -> Session_value value)
        (evaluate_expression_with_limits ~cancelled limits expression)
  | Ok (Centl_parser.Define_value (name, expression)) ->
      let* () = validate_definition_name session name in
      let* () =
        if session_binding_count session >= limits.max_bindings then
          session_failure "resource_limit"
            "the session has reached its definition limit"
        else Ok ()
      in
      let* value, expression =
        prepare_definition ~cancelled limits session [] name expression
      in
      let* retention =
        check_session_retention limits session
          ~metadata_bytes:(String.length name) expression
      in
      let* () = check_cancelled cancelled in
      retain_binding session name (Bound_value expression) retention;
      Ok (Defined_value (name, value))
  | Ok (Centl_parser.Define_function (name, parameters, body)) ->
      let* () = validate_definition_name session name in
      let* () = validate_parameters name parameters in
      let* () =
        if session_binding_count session >= limits.max_bindings then
          session_failure "resource_limit"
            "the session has reached its definition limit"
        else Ok ()
      in
      let* _, body =
        prepare_definition ~cancelled limits session parameters name body
      in
      let metadata_bytes =
        List.fold_left
          (fun total parameter -> total + String.length parameter)
          (String.length name) parameters
      in
      let* retention =
        check_session_retention limits session ~metadata_bytes body
      in
      let* () = check_cancelled cancelled in
      retain_binding session name
        (Bound_function { parameters; body })
        retention;
      Ok (Defined_function (name, parameters, body))

let evaluate_in_session session source =
  evaluate_in_session_with_limits default_evaluation_limits session source

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

let relation_text = function
  | Centl_Core.Equal -> "="
  | Centl_Core.NotEqual -> "!="
  | Centl_Core.LessThan -> "<"
  | Centl_Core.LessOrEqual -> "<="
  | Centl_Core.GreaterThan -> ">"
  | Centl_Core.GreaterOrEqual -> ">="

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
    | Centl_Core.Function
        ( (("sum" | "product") as name),
          [ body; Centl_Core.Symbol variable; lower; upper ] ) ->
        let assignment =
          fragment Symbol_name variable
          |> append (fragment Operator " = ")
          |> append (expression_fragments lower)
        in
        ( 4,
          fragment Function_name name
          |> append (fragment Punctuation "(")
          |> append (expression_fragments body)
          |> append (fragment Punctuation ", ")
          |> append assignment
          |> append (fragment Punctuation ", ")
          |> append (expression_fragments upper)
          |> append (fragment Punctuation ")") )
    | Centl_Core.Function (name, arguments) -> (4, call_fragments name arguments)
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
    | Centl_Core.Simplify inner -> (4, call_fragments "simplify" [ inner ])
    | Centl_Core.Expand inner -> (4, call_fragments "expand" [ inner ])
    | Centl_Core.Factor inner -> (4, call_fragments "factor" [ inner ])
    | Centl_Core.Assuming (inner, left, relation, right) ->
        ( -1,
          expression_fragments ~parent_precedence:0 inner
          |> append (fragment Punctuation " where ")
          |> append (expression_fragments left)
          |> append (fragment Operator (" " ^ relation_text relation ^ " "))
          |> append (expression_fragments right) )
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

let solution_fragments (numerator, denominator) =
  literal_fragments numerator denominator

let rec solution_list_fragments = function
  | [] -> []
  | [ solution ] -> solution_fragments solution
  | solution :: rest ->
      solution_fragments solution
      |> append (fragment Punctuation ", ")
      |> append (solution_list_fragments rest)

let equation_call_fragments result =
  fragment Function_name "solve"
  |> append (fragment Punctuation "(")
  |> append (expression_fragments result.left)
  |> append (fragment Operator " = ")
  |> append (expression_fragments result.right)
  |> append (fragment Punctuation ", ")
  |> append (fragment Symbol_name result.variable)
  |> append (fragment Punctuation ")")

let equation_result_fragments result =
  match result.status with
  | Finite_solutions [ solution ] ->
      fragment Symbol_name result.variable
      |> append (fragment Operator " = ")
      |> append (solution_fragments solution)
  | Finite_solutions solutions ->
      fragment Symbol_name result.variable
      |> append (fragment Operator " in ")
      |> append (fragment Punctuation "{")
      |> append (solution_list_fragments solutions)
      |> append (fragment Punctuation "}")
  | No_solutions -> fragment Punctuation "no solutions"
  | All_values ->
      fragment Punctuation "all values of "
      |> append (fragment Symbol_name result.variable)
  | Unresolved ->
      fragment Punctuation "unresolved: "
      |> append (equation_call_fragments result)

let fragments_of_value = function
  | Integer value -> fragment Number (Z.to_string value)
  | Rational (numerator, denominator) -> literal_fragments numerator denominator
  | Symbolic expression -> expression_fragments expression
  | Real_enclosure enclosure ->
      let prefix = fragment Operator "≈ " in
      if enclosure.lower_decimal = enclosure.upper_decimal then
        prefix |> append (fragment Number enclosure.lower_decimal)
      else
        prefix
        |> append (fragment Punctuation "[")
        |> append (fragment Number enclosure.lower_decimal)
        |> append (fragment Punctuation ", ")
        |> append (fragment Number enclosure.upper_decimal)
        |> append (fragment Punctuation "]")
  | Equation_result result -> equation_result_fragments result

let text_of_fragments fragments = fragments |> List.map snd |> String.concat ""
let text_of_value value = value |> fragments_of_value |> text_of_fragments

let ansi_code = function
  | Number -> "96"
  | Symbol_name -> "95"
  | Function_name -> "94"
  | Operator -> "93"
  | Punctuation -> "2;37"

let colored_text_of_fragments fragments =
  fragments
  |> List.map (fun (style, text) ->
      Printf.sprintf "\027[%sm%s\027[0m" (ansi_code style) text)
  |> String.concat ""

let colored_text_of_value value =
  fragments_of_value value |> colored_text_of_fragments

let fragments_of_session_result = function
  | Session_value value -> fragments_of_value value
  | Defined_value (name, value) ->
      fragment Symbol_name name
      |> append (fragment Operator " = ")
      |> append (fragments_of_value value)
  | Defined_function (name, parameters, body) ->
      let arguments =
        List.map (fun name -> Centl_Core.Symbol name) parameters
      in
      call_fragments name arguments
      |> append (fragment Operator " = ")
      |> append (expression_fragments body)

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
  | Real_enclosure _ ->
      json_of_provenance ~classification:"rigorous_enclosure"
        ~method_:"interval_evaluation" ~backend:"flint-arb"
  | Equation_result { status = Unresolved; _ } ->
      json_of_provenance ~classification:"unresolved"
        ~method_:"equation_solving" ~backend:"centl-exact"
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
      let status, solutions, resolved =
        match result.status with
        | Finite_solutions solutions ->
            ("finite", List.map rational_json solutions, true)
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
