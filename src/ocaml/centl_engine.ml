type real_enclosure = {
  lower_mantissa : Z.t;
  upper_mantissa : Z.t;
  binary_exponent : int;
  lower_decimal : string;
  upper_decimal : string;
  requested_digits : int;
  working_bits : int;
}

type exact_value =
  | Integer of Z.t
  | Rational of Z.t * Z.t
  | Symbolic of Centl_Core.expression
  | Real_enclosure of real_enclosure

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

type session = { mutable bindings : (string * binding) list }

type session_result =
  | Session_value of exact_value
  | Defined_value of string * exact_value
  | Defined_function of string * string list * Centl_Core.expression

type session_evaluation = (session_result, error) result

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

let scaled_integer ~upper value places =
  let scaled =
    if places >= 0 then Q.mul value (rational_power_of_ten places)
    else Q.div value (rational_power_of_ten (-places))
  in
  if upper then Z.cdiv (Q.num scaled) (Q.den scaled)
  else Z.fdiv (Q.num scaled) (Q.den scaled)

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

let decimal_interval lower upper digits =
  let magnitude =
    let lower = Q.abs lower in
    let upper = Q.abs upper in
    if Q.compare lower upper >= 0 then lower else upper
  in
  let places = digits - 1 - decimal_order magnitude in
  let lower_scaled = scaled_integer ~upper:false lower places in
  let upper_scaled = scaled_integer ~upper:true upper places in
  let resolution = Q.div (rational_power_of_ten (-places)) (Q.of_int 2) in
  ( decimal_of_scaled lower_scaled places,
    decimal_of_scaled upper_scaled places,
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
          let lower = rational_of_dyadic lower_mantissa binary_exponent in
          let upper = rational_of_dyadic upper_mantissa binary_exponent in
          let lower_decimal, upper_decimal, resolved =
            decimal_interval lower upper requested_digits
          in
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

let approximate expression requested_digits =
  if requested_digits < 1 || requested_digits > 1_000 then
    failure "precision_limit" "approximation digits must be between 1 and 1000"
  else
    let target_bits = 64 + (((requested_digits * 3_322) + 999) / 1_000) in
    let rec attempt working_bits =
      match native_value expression working_bits with
      | Error (Domain_error message) -> failure "domain_error" message
      | Error (Unsupported message) ->
          failure "unsupported_approximation" message
      | Error (Backend_failure message) -> failure "backend_failure" message
      | Error (Uncertain_domain message) ->
          if working_bits >= 16_384 then
            failure "insufficient_precision" message
          else attempt (min 16_384 (working_bits * 2))
      | Ok ball ->
          begin match enclosure_of_ball ball requested_digits working_bits with
          | Error (Backend_failure message) -> failure "backend_failure" message
          | Error (Uncertain_domain message) ->
              if working_bits >= 16_384 then
                failure "insufficient_precision" message
              else attempt (min 16_384 (working_bits * 2))
          | Error (Domain_error message) -> failure "domain_error" message
          | Error (Unsupported message) ->
              failure "unsupported_approximation" message
          | Ok (value, true) -> Ok value
          | Ok (_, false) when working_bits >= 16_384 ->
              failure "insufficient_precision"
                "the enclosure did not reach the requested significant digits"
          | Ok (_, false) -> attempt (min 16_384 (working_bits * 2))
          end
    in
    attempt target_bits

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

let syntax_error (parse_error : Centl_parser.error) =
  Error
    {
      code = "syntax_error";
      message = parse_error.message;
      position = Some parse_error.position;
    }

let evaluate_expression expression =
  let expression = Centl_Core.resolve expression in
  match approximation_request expression with
  | Some (Ok (inner, digits)) -> approximate inner digits
  | Some (Error _ as error) -> error
  | None -> evaluate_exact expression

let evaluate source =
  match Centl_parser.parse source with
  | Error parse_error -> syntax_error parse_error
  | Ok expression -> evaluate_expression expression

let reserved_names =
  [
    "pi";
    "e";
    "tau";
    "diff";
    "substitute";
    "assuming";
    "simplify";
    "expand";
    "factor";
    "approx";
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

let create_session () = { bindings = [] }
let lookup session name = List.assoc_opt name session.bindings
let session_failure code message = Error { code; message; position = None }

let rec expand_expression session bound expression =
  let ( let* ) result next = Result.bind result next in
  match expression with
  | Centl_Core.Literal _ -> Ok expression
  | Centl_Core.Symbol name ->
      if List.mem name bound then Ok expression
      else
        begin match lookup session name with
        | None -> Ok expression
        | Some (Bound_value value) -> Ok value
        | Some (Bound_function _) ->
            session_failure "invalid_arguments"
              (name ^ " is a function; call it with parentheses")
        end
  | Centl_Core.Negate inner ->
      let* inner = expand_expression session bound inner in
      Ok (Centl_Core.Negate inner)
  | Centl_Core.Binary (operator, left, right) ->
      let* left = expand_expression session bound left in
      let* right = expand_expression session bound right in
      Ok (Centl_Core.Binary (operator, left, right))
  | Centl_Core.Power (base, exponent) ->
      let* base = expand_expression session bound base in
      Ok (Centl_Core.Power (base, exponent))
  | Centl_Core.Function (name, arguments) ->
      let* arguments = expand_arguments session bound arguments in
      if List.mem name bound then Ok (Centl_Core.Function (name, arguments))
      else
        begin match lookup session name with
        | None -> Ok (Centl_Core.Function (name, arguments))
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
            else
              Ok (instantiate definition.parameters arguments definition.body)
        end
  | Centl_Core.Differentiate (inner, variable) ->
      let* inner = expand_expression session (variable :: bound) inner in
      Ok (Centl_Core.Differentiate (inner, variable))
  | Centl_Core.Substitute (inner, variable, replacement) ->
      let* inner = expand_expression session (variable :: bound) inner in
      let* replacement = expand_expression session bound replacement in
      Ok (Centl_Core.Substitute (inner, variable, replacement))
  | Centl_Core.Derivative (inner, variable) ->
      let* inner = expand_expression session (variable :: bound) inner in
      Ok (Centl_Core.Derivative (inner, variable))
  | Centl_Core.Simplify inner ->
      let* inner = expand_expression session bound inner in
      Ok (Centl_Core.Simplify inner)
  | Centl_Core.Expand inner ->
      let* inner = expand_expression session bound inner in
      Ok (Centl_Core.Expand inner)
  | Centl_Core.Factor inner ->
      let* inner = expand_expression session bound inner in
      Ok (Centl_Core.Factor inner)
  | Centl_Core.Assuming (inner, left, relation, right) ->
      let* inner = expand_expression session bound inner in
      let* left = expand_expression session bound left in
      let* right = expand_expression session bound right in
      Ok (Centl_Core.Assuming (inner, left, relation, right))

and expand_arguments session bound arguments =
  let ( let* ) result next = Result.bind result next in
  match arguments with
  | [] -> Ok []
  | argument :: rest ->
      let* argument = expand_expression session bound argument in
      let* rest = expand_arguments session bound rest in
      Ok (argument :: rest)

and instantiate parameters arguments body =
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
  | Real_enclosure _ -> assert false

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

let prepare_definition session bound name expression =
  let ( let* ) result next = Result.bind result next in
  let* expression = expand_expression session bound expression in
  if references_name name expression then
    session_failure "recursive_definition"
      (name ^ " cannot be defined in terms of itself")
  else if contains_approximation expression then
    session_failure "exact_definition_required"
      "definitions must be exact; use approx(...) when evaluating them"
  else
    let* value = evaluate_expression expression in
    match value with
    | Real_enclosure _ ->
        session_failure "exact_definition_required"
          "definitions must be exact; use approx(...) when evaluating them"
    | value -> Ok (value, expression_of_exact_value value)

let evaluate_in_session session source =
  let ( let* ) result next = Result.bind result next in
  match Centl_parser.parse_statement source with
  | Error parse_error -> syntax_error parse_error
  | Ok (Centl_parser.Evaluate expression) ->
      let* expression = expand_expression session [] expression in
      Result.map
        (fun value -> Session_value value)
        (evaluate_expression expression)
  | Ok (Centl_parser.Define_value (name, expression)) ->
      let* () = validate_definition_name session name in
      let* value, expression = prepare_definition session [] name expression in
      session.bindings <- (name, Bound_value expression) :: session.bindings;
      Ok (Defined_value (name, value))
  | Ok (Centl_parser.Define_function (name, parameters, body)) ->
      let* () = validate_definition_name session name in
      let* () = validate_parameters name parameters in
      let* _, body = prepare_definition session parameters name body in
      session.bindings <-
        (name, Bound_function { parameters; body }) :: session.bindings;
      Ok (Defined_function (name, parameters, body))

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
