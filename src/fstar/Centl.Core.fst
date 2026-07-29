module Centl.Core

module Gcd = Centl.Gcd
module Euclid = FStar.Math.Euclid
module Math = FStar.Math.Lemmas

type binary_operator =
  | Add
  | Subtract
  | Multiply
  | Divide

type relation =
  | Equal
  | NotEqual
  | LessThan
  | LessOrEqual
  | GreaterThan
  | GreaterOrEqual

type expression =
  | Literal: numerator:int -> denominator:int -> expression
  | Symbol: name:string -> expression
  | Negate: expression -> expression
  | Binary: binary_operator -> expression -> expression -> expression
  | Power: expression -> exponent:int -> expression
  | Function: name:string -> argument:expression -> expression
  | Differentiate: expression -> variable:string -> expression
  | Substitute: expression -> variable:string -> replacement:expression -> expression
  | Derivative: expression -> variable:string -> expression
  | Simplify: expression -> expression
  | Expand: expression -> expression
  | Factor: expression -> expression
  | Assuming:
      expression -> left:expression -> relation -> right:expression -> expression

type rational = {
  numerator: int;
  denominator: int
}

let invariant (value:rational) : prop = value.denominator > 0

let equivalent (left right:rational) : prop =
  left.numerator * right.denominator =
  right.numerator * left.denominator

let reduction_preserves_value
    (numerator denominator reduced_numerator reduced_denominator divisor:int)
  : Lemma
      (requires
        numerator = divisor * reduced_numerator /\
        denominator = divisor * reduced_denominator)
      (ensures
        reduced_numerator * denominator =
        numerator * reduced_denominator)
= assert (reduced_numerator * denominator =
    numerator * reduced_denominator)
    by (FStar.Tactics.Canon.canon ())

let positive_quotient (value factor quotient:int)
  : Lemma
      (requires value > 0 /\ factor > 0 /\ value = factor * quotient)
      (ensures quotient > 0)
= ()

let normalize_natural (numerator:nat) (denominator:pos)
  : Pure rational
      (requires True)
      (ensures fun value ->
        invariant value /\
        equivalent value { numerator = numerator; denominator = denominator })
=
  let divisor = Gcd.gcd numerator denominator in
  Gcd.gcd_is_gcd numerator denominator;
  assert (Euclid.is_gcd numerator denominator divisor);
  if divisor > 0 then
    begin
    assert (Euclid.divides divisor numerator);
    assert (Euclid.divides divisor denominator);
    Euclid.divides_mod numerator divisor;
    Euclid.divides_mod denominator divisor;
    Math.lemma_div_mod numerator divisor;
    Math.lemma_div_mod denominator divisor;
    let reduced_numerator = numerator / divisor in
    let reduced_denominator = denominator / divisor in
    assert (numerator = divisor * reduced_numerator);
    assert (denominator = divisor * reduced_denominator);
    positive_quotient denominator divisor reduced_denominator;
    reduction_preserves_value numerator denominator
      reduced_numerator reduced_denominator divisor;
    { numerator = reduced_numerator; denominator = reduced_denominator }
    end
  else
    { numerator = numerator; denominator = denominator }

let normalize_positive (numerator:int) (denominator:pos)
  : Pure rational
      (requires True)
      (ensures fun value ->
        invariant value /\
        equivalent value { numerator = numerator; denominator = denominator })
=
  if numerator >= 0 then
    normalize_natural numerator denominator
  else
    begin
    let magnitude : pos = -numerator in
    let magnitude_value = normalize_natural magnitude denominator in
    let result = {
      numerator = -magnitude_value.numerator;
      denominator = magnitude_value.denominator
    } in
    assert (invariant result);
    assert (equivalent magnitude_value {
      numerator = magnitude;
      denominator = denominator
    });
    assert (equivalent result {
      numerator = numerator;
      denominator = denominator
    }) by (FStar.Tactics.Canon.canon ());
    result
    end

let make (numerator denominator:int)
  : Pure rational
      (requires denominator <> 0)
      (ensures fun value -> invariant value /\
        equivalent value { numerator = numerator; denominator = denominator })
=
  if denominator > 0 then
    normalize_positive numerator denominator
  else
    begin
    let result = normalize_positive (-numerator) (-denominator) in
    assert (equivalent result {
      numerator = -numerator;
      denominator = -denominator
    });
    assert (equivalent result {
      numerator = numerator;
      denominator = denominator
    }) by (FStar.Tactics.Canon.canon ());
    result
    end

let negate (value:rational{invariant value})
  : Pure rational
      (requires True)
      (ensures fun result -> invariant result /\
        equivalent result {
          numerator = -value.numerator;
          denominator = value.denominator
        })
=
  make (-value.numerator) value.denominator

let add (left right:rational{invariant left /\ invariant right})
  : Pure rational
      (requires True)
      (ensures fun result -> invariant result /\
        equivalent result {
          numerator = left.numerator * right.denominator +
            right.numerator * left.denominator;
          denominator = left.denominator * right.denominator
        })
=
  make
    (left.numerator * right.denominator +
      right.numerator * left.denominator)
    (left.denominator * right.denominator)

let subtract (left right:rational{invariant left /\ invariant right})
  : Pure rational
      (requires True)
      (ensures fun result -> invariant result /\
        equivalent result {
          numerator = left.numerator * right.denominator -
            right.numerator * left.denominator;
          denominator = left.denominator * right.denominator
        })
=
  make
    (left.numerator * right.denominator -
      right.numerator * left.denominator)
    (left.denominator * right.denominator)

let multiply (left right:rational{invariant left /\ invariant right})
  : Pure rational
      (requires True)
      (ensures fun result -> invariant result /\
        equivalent result {
          numerator = left.numerator * right.numerator;
          denominator = left.denominator * right.denominator
        })
=
  make
    (left.numerator * right.numerator)
    (left.denominator * right.denominator)

let rec power_natural
    (value:rational{invariant value})
    (exponent:nat)
  : Pure rational
      (requires True)
      (ensures fun result -> invariant result)
      (decreases exponent)
=
  if exponent = 0 then make 1 1
  else if exponent % 2 = 0 then
    let half = power_natural value (exponent / 2) in
    multiply half half
  else multiply value (power_natural value (exponent - 1))

type error =
  | ZeroDenominator
  | DivisionByZero
  | UndefinedPower

type outcome =
  | Success: rational -> outcome
  | Failure: error -> outcome

let outcome_invariant (result:outcome) : prop =
  match result with
  | Success value -> invariant value
  | Failure _ -> True

let division_postcondition (left right:rational) (result:outcome) : prop =
  outcome_invariant result /\
  (match result with
   | Success value ->
       right.numerator <> 0 /\
       equivalent value {
         numerator = left.numerator * right.denominator;
         denominator = left.denominator * right.numerator
       }
   | Failure DivisionByZero -> right.numerator = 0
   | Failure ZeroDenominator -> False
   | Failure UndefinedPower -> False)

let divide (left right:rational{invariant left /\ invariant right})
  : Tot (result:outcome{division_postcondition left right result})
=
  if right.numerator = 0 then
    Failure DivisionByZero
  else
    Success (make
      (left.numerator * right.denominator)
      (left.denominator * right.numerator))

let power (value:rational{invariant value}) (exponent:int)
  : Tot (result:outcome{outcome_invariant result})
=
  if exponent = 0 && value.numerator = 0 then Failure UndefinedPower
  else if exponent >= 0 then Success (power_natural value exponent)
  else if value.numerator = 0 then Failure DivisionByZero
  else
    let reciprocal = make value.denominator value.numerator in
    Success (power_natural reciprocal (-exponent))

let apply (operator:binary_operator)
          (left right:rational{invariant left /\ invariant right})
  : Tot (result:outcome{outcome_invariant result})
=
  match operator with
  | Add -> Success (add left right)
  | Subtract -> Success (subtract left right)
  | Multiply -> Success (multiply left right)
  | Divide -> divide left right

type value =
  | ExactRational: rational -> value
  | ExactSymbolic: expression -> value

let value_invariant (result:value) : prop =
  match result with
  | ExactRational rational -> invariant rational
  | ExactSymbolic _ -> True

type evaluation =
  | Evaluated: value -> evaluation
  | EvaluationFailure: error -> evaluation

let evaluation_invariant (result:evaluation) : prop =
  match result with
  | Evaluated value -> value_invariant value
  | EvaluationFailure _ -> True

let expression_of_value (result:value) : expression =
  match result with
  | ExactRational rational ->
      Literal rational.numerator rational.denominator
  | ExactSymbolic expression -> expression

let is_zero_value (result:value) : bool =
  match result with
  | ExactRational rational -> rational.numerator = 0
  | ExactSymbolic _ -> false

let is_one_value (result:value) : bool =
  match result with
  | ExactRational rational ->
      rational.numerator = 1 && rational.denominator = 1
  | ExactSymbolic _ -> false

let rec expression_is_total (term:expression) : Tot bool =
  match term with
  | Literal _ denominator -> denominator <> 0
  | Symbol _ -> true
  | Negate inner -> expression_is_total inner
  | Binary Divide _ _ -> false
  | Binary _ left right ->
      expression_is_total left && expression_is_total right
  | Power base exponent -> exponent > 0 && expression_is_total base
  | Function name argument ->
      (name = "sin" || name = "cos" || name = "exp") &&
      expression_is_total argument
  | Differentiate _ _ -> false
  | Substitute _ _ _ -> false
  | Derivative _ _ -> false
  | Simplify inner -> expression_is_total inner
  | Expand inner -> expression_is_total inner
  | Factor inner -> expression_is_total inner
  | Assuming _ _ _ _ -> false

let value_is_total (result:value) : bool =
  match result with
  | ExactRational _ -> true
  | ExactSymbolic expression -> expression_is_total expression

let scale_symbolic
    (coefficient:rational{invariant coefficient})
    (expression:expression)
  : Tot (result:evaluation{evaluation_invariant result})
=
  match expression with
  | Binary Multiply (Literal numerator denominator) remainder ->
      if denominator = 0 then EvaluationFailure ZeroDenominator
      else
        let combined = multiply coefficient (make numerator denominator) in
        if combined.numerator = 0 && expression_is_total remainder then
          Evaluated (ExactRational combined)
        else if combined.numerator = 1 && combined.denominator = 1 then
          Evaluated (ExactSymbolic remainder)
        else Evaluated (ExactSymbolic (Binary Multiply
          (Literal combined.numerator combined.denominator) remainder))
  | _ ->
      if coefficient.numerator = 0 && expression_is_total expression then
        Evaluated (ExactRational coefficient)
      else if coefficient.numerator = 1 && coefficient.denominator = 1 then
        Evaluated (ExactSymbolic expression)
      else Evaluated (ExactSymbolic (Binary Multiply
        (Literal coefficient.numerator coefficient.denominator) expression))

let evaluate_rational_outcome (result:outcome{outcome_invariant result})
  : Tot (evaluation:evaluation{evaluation_invariant evaluation})
=
  match result with
  | Success rational -> Evaluated (ExactRational rational)
  | Failure error -> EvaluationFailure error

let negate_value (result:value{value_invariant result})
  : Tot (value:value{value_invariant value})
=
  match result with
  | ExactRational rational -> ExactRational (negate rational)
  | ExactSymbolic (Negate inner) -> ExactSymbolic inner
  | ExactSymbolic expression -> ExactSymbolic (Negate expression)

let apply_values
    (operator:binary_operator)
    (left right:value{value_invariant left /\ value_invariant right})
  : Tot (result:evaluation{evaluation_invariant result})
=
  match left, right with
  | ExactRational left_rational, ExactRational right_rational ->
      evaluate_rational_outcome (apply operator left_rational right_rational)
  | _, _ ->
      begin match operator with
      | Add ->
          if is_zero_value left then Evaluated right
          else if is_zero_value right then Evaluated left
          else Evaluated (ExactSymbolic (Binary Add
            (expression_of_value left) (expression_of_value right)))
      | Subtract ->
          if is_zero_value right then Evaluated left
          else Evaluated (ExactSymbolic (Binary Subtract
            (expression_of_value left) (expression_of_value right)))
      | Multiply ->
          begin match left, right with
          | ExactRational coefficient, ExactSymbolic expression ->
              scale_symbolic coefficient expression
          | ExactSymbolic expression, ExactRational coefficient ->
              scale_symbolic coefficient expression
          | _, _ ->
              if (is_zero_value left && value_is_total right) ||
                 (is_zero_value right && value_is_total left) then
                Evaluated (ExactRational (make 0 1))
              else if is_one_value left then Evaluated right
              else if is_one_value right then Evaluated left
              else Evaluated (ExactSymbolic (Binary Multiply
                (expression_of_value left) (expression_of_value right)))
          end
      | Divide ->
          if is_zero_value right then EvaluationFailure DivisionByZero
          else if is_one_value right then Evaluated left
          else Evaluated (ExactSymbolic (Binary Divide
            (expression_of_value left) (expression_of_value right)))
      end

let power_value
    (base:value{value_invariant base})
    (exponent:int)
  : Tot (result:evaluation{evaluation_invariant result})
=
  match base with
  | ExactRational rational -> evaluate_rational_outcome (power rational exponent)
  | ExactSymbolic expression ->
      if exponent = 1 then Evaluated base
      else Evaluated (ExactSymbolic (Power expression exponent))

let rec substitute
    (term:expression)
    (variable:string)
    (replacement:expression)
  : Tot expression
=
  match term with
  | Literal _ _ -> term
  | Symbol name -> if name = variable then replacement else term
  | Negate inner -> Negate (substitute inner variable replacement)
  | Binary operator left right -> Binary operator
      (substitute left variable replacement)
      (substitute right variable replacement)
  | Power base exponent -> Power
      (substitute base variable replacement) exponent
  | Function name argument -> Function name
      (substitute argument variable replacement)
  | Differentiate inner bound_variable ->
      if bound_variable = variable then term
      else Differentiate
        (substitute inner variable replacement) bound_variable
  | Substitute inner bound_variable inner_replacement -> Substitute
      (substitute inner variable replacement)
      bound_variable
      (substitute inner_replacement variable replacement)
  | Derivative inner bound_variable ->
      if bound_variable = variable then term
      else Derivative (substitute inner variable replacement) bound_variable
  | Simplify inner -> Simplify (substitute inner variable replacement)
  | Expand inner -> Expand (substitute inner variable replacement)
  | Factor inner -> Factor (substitute inner variable replacement)
  | Assuming inner left relation right -> Assuming
      (substitute inner variable replacement)
      (substitute left variable replacement)
      relation
      (substitute right variable replacement)

let rec differentiate (term:expression) (variable:string) : Tot expression =
  match term with
  | Literal _ _ -> Literal 0 1
  | Symbol name -> if name = variable then Literal 1 1 else Literal 0 1
  | Negate inner -> Negate (differentiate inner variable)
  | Binary Add left right -> Binary Add
      (differentiate left variable) (differentiate right variable)
  | Binary Subtract left right -> Binary Subtract
      (differentiate left variable) (differentiate right variable)
  | Binary Multiply left right -> Binary Add
      (Binary Multiply (differentiate left variable) right)
      (Binary Multiply left (differentiate right variable))
  | Binary Divide left right -> Binary Divide
      (Binary Subtract
        (Binary Multiply (differentiate left variable) right)
        (Binary Multiply left (differentiate right variable)))
      (Power right 2)
  | Power base exponent ->
      if exponent = 0 then Literal 0 1
      else if exponent = 1 then differentiate base variable
      else Binary Multiply
        (Binary Multiply
          (Literal exponent 1)
          (Power base (exponent - 1)))
        (differentiate base variable)
  | Function name argument ->
      let argument_derivative = differentiate argument variable in
      if name = "sin" then
        Binary Multiply (Function "cos" argument) argument_derivative
      else if name = "cos" then
        Binary Multiply
          (Negate (Function "sin" argument)) argument_derivative
      else if name = "exp" then
        Binary Multiply (Function "exp" argument) argument_derivative
      else if name = "log" then
        Binary Divide argument_derivative argument
      else if name = "sqrt" then
        Binary Divide argument_derivative
          (Binary Multiply (Literal 2 1) (Function "sqrt" argument))
      else if name = "tan" then
        Binary Divide argument_derivative (Power (Function "cos" argument) 2)
      else Derivative term variable
  | Derivative _ _ -> Derivative term variable
  | Differentiate _ _ -> Derivative term variable
  | Substitute _ _ _ -> Derivative term variable
  | Simplify inner -> differentiate inner variable
  | Expand inner -> differentiate inner variable
  | Factor inner -> differentiate inner variable
  | Assuming inner left relation right -> Assuming
      (differentiate inner variable) left relation right

type coefficient = value:rational{invariant value}
type polynomial = list coefficient

type variable_scan =
  | NoVariable
  | OneVariable: string -> variable_scan
  | NotUnivariate

let maximum_expansion_exponent : nat = 64

let merge_variable_scan (left right:variable_scan) : variable_scan =
  match left, right with
  | NotUnivariate, _ -> NotUnivariate
  | _, NotUnivariate -> NotUnivariate
  | NoVariable, result -> result
  | result, NoVariable -> result
  | OneVariable left_name, OneVariable right_name ->
      if left_name = right_name then left else NotUnivariate

let rec scan_polynomial_variable (term:expression) : Tot variable_scan =
  match term with
  | Literal _ _ -> NoVariable
  | Symbol name -> OneVariable name
  | Negate inner -> scan_polynomial_variable inner
  | Binary Add left right
  | Binary Subtract left right
  | Binary Multiply left right -> merge_variable_scan
      (scan_polynomial_variable left) (scan_polynomial_variable right)
  | Binary Divide left right ->
      begin match scan_polynomial_variable right with
      | NoVariable -> scan_polynomial_variable left
      | _ -> NotUnivariate
      end
  | Power base exponent ->
      if exponent > 0 && exponent <= maximum_expansion_exponent then
        scan_polynomial_variable base
      else NotUnivariate
  | Function _ _ -> NotUnivariate
  | Differentiate _ _ -> NotUnivariate
  | Substitute _ _ _ -> NotUnivariate
  | Derivative _ _ -> NotUnivariate
  | Simplify inner -> scan_polynomial_variable inner
  | Expand inner -> scan_polynomial_variable inner
  | Factor inner -> scan_polynomial_variable inner
  | Assuming _ _ _ _ -> NotUnivariate

let rec polynomial_add (left right:polynomial) : Tot polynomial =
  match left, right with
  | [], result -> result
  | result, [] -> result
  | left_head :: left_tail, right_head :: right_tail ->
      add left_head right_head :: polynomial_add left_tail right_tail

let rec polynomial_negate (value:polynomial) : Tot polynomial =
  match value with
  | [] -> []
  | head :: tail -> negate head :: polynomial_negate tail

let polynomial_subtract (left right:polynomial) : Tot polynomial =
  polynomial_add left (polynomial_negate right)

let rec polynomial_scale (factor:coefficient) (value:polynomial)
  : Tot polynomial
=
  match value with
  | [] -> []
  | head :: tail -> multiply factor head :: polynomial_scale factor tail

let rec polynomial_multiply (left right:polynomial) : Tot polynomial =
  match left with
  | [] -> []
  | head :: tail -> polynomial_add
      (polynomial_scale head right)
      (make 0 1 :: polynomial_multiply tail right)

let rec polynomial_power (base:polynomial) (exponent:nat) : Tot polynomial =
  if exponent = 0 then [make 1 1]
  else polynomial_multiply base (polynomial_power base (exponent - 1))

let rec polynomial_tail_is_zero (value:polynomial) : Tot bool =
  match value with
  | [] -> true
  | head :: tail -> head.numerator = 0 && polynomial_tail_is_zero tail

let polynomial_constant (value:polynomial) : option coefficient =
  match value with
  | [] -> Some (make 0 1)
  | head :: tail ->
      if polynomial_tail_is_zero tail then Some head else None

let polynomial_divide_constant (numerator denominator:polynomial)
  : option polynomial
=
  match polynomial_constant denominator with
  | Some value ->
      if value.numerator = 0 then None
      else Some (polynomial_scale (make value.denominator value.numerator) numerator)
  | None -> None

let rec polynomial_of (term:expression) (variable:string)
  : Tot (option polynomial)
=
  match term with
  | Literal numerator denominator ->
      if denominator = 0 then None else Some [make numerator denominator]
  | Symbol name ->
      if name = variable then Some [make 0 1; make 1 1] else None
  | Negate inner ->
      begin match polynomial_of inner variable with
      | None -> None
      | Some value -> Some (polynomial_negate value)
      end
  | Binary operator left right ->
      begin match polynomial_of left variable, polynomial_of right variable with
      | Some left_value, Some right_value ->
          begin match operator with
          | Add -> Some (polynomial_add left_value right_value)
          | Subtract -> Some (polynomial_subtract left_value right_value)
          | Multiply -> Some (polynomial_multiply left_value right_value)
          | Divide -> polynomial_divide_constant left_value right_value
          end
      | _, _ -> None
      end
  | Power base exponent ->
      if exponent > 0 && exponent <= maximum_expansion_exponent then
        begin match polynomial_of base variable with
        | None -> None
        | Some value -> Some (polynomial_power value exponent)
        end
      else None
  | Function _ _ -> None
  | Differentiate _ _ -> None
  | Substitute _ _ _ -> None
  | Derivative _ _ -> None
  | Simplify inner -> polynomial_of inner variable
  | Expand inner -> polynomial_of inner variable
  | Factor inner -> polynomial_of inner variable
  | Assuming _ _ _ _ -> None

type signed_term =
  | PositiveTerm: expression -> signed_term
  | NegativeTerm: expression -> signed_term

let coefficient_is_one (value:coefficient) : bool =
  value.numerator = 1 && value.denominator = 1

let coefficient_is_integer (value:coefficient) (integer:int) : bool =
  value.numerator = integer && value.denominator = 1

let polynomial_term
    (value:coefficient)
    (variable:string)
    (degree:nat)
  : Tot (option signed_term)
=
  if value.numerator = 0 then None
  else
    let negative = value.numerator < 0 in
    let magnitude = if negative then negate value else value in
    let term =
      if degree = 0 then Literal magnitude.numerator magnitude.denominator
      else
        let variable_term =
          if degree = 1 then Symbol variable else Power (Symbol variable) degree
        in
        if coefficient_is_one magnitude then variable_term
        else Binary Multiply
          (Literal magnitude.numerator magnitude.denominator) variable_term
    in
    if negative then Some (NegativeTerm term) else Some (PositiveTerm term)

let add_polynomial_term
    (higher:option expression)
    (current:option signed_term)
  : option expression
=
  match higher, current with
  | None, None -> None
  | Some expression, None -> Some expression
  | None, Some (PositiveTerm expression) -> Some expression
  | None, Some (NegativeTerm expression) -> Some (Negate expression)
  | Some expression, Some (PositiveTerm current) ->
      Some (Binary Add expression current)
  | Some expression, Some (NegativeTerm current) ->
      Some (Binary Subtract expression current)

let rec polynomial_expression_from
    (coefficients:polynomial)
    (variable:string)
    (degree:nat)
  : Tot (option expression)
=
  match coefficients with
  | [] -> None
  | head :: tail ->
      let higher = polynomial_expression_from tail variable (degree + 1) in
      add_polynomial_term higher (polynomial_term head variable degree)

let polynomial_expression (coefficients:polynomial) (variable:string)
  : expression
=
  match polynomial_expression_from coefficients variable 0 with
  | None -> Literal 0 1
  | Some expression -> expression

let canonicalize_polynomial (term:expression) : expression =
  match scan_polynomial_variable term with
  | NoVariable -> term
  | NotUnivariate -> term
  | OneVariable variable ->
      begin match polynomial_of term variable with
      | None -> term
      | Some coefficients -> polynomial_expression coefficients variable
      end

let square_base (term:expression) : option expression =
  match term with
  | Power base exponent ->
      if exponent > 0 && exponent % 2 = 0 then
        if exponent = 2 then Some base else Some (Power base (exponent / 2))
      else None
  | Literal numerator denominator ->
      if numerator = 1 && denominator = 1 then Some term else None
  | _ -> None

let difference_of_squares (term:expression) : option expression =
  match term with
  | Binary Subtract left right ->
      begin match square_base left, square_base right with
      | Some left_base, Some right_base -> Some (Binary Multiply
          (Binary Subtract left_base right_base)
          (Binary Add left_base right_base))
      | _, _ -> None
      end
  | _ -> None

let rec drop_zero_coefficients (coefficients:polynomial)
  : Tot (nat & polynomial)
=
  match coefficients with
  | [] -> (0, [])
  | head :: tail ->
      if head.numerator = 0 then
        let degree, remainder = drop_zero_coefficients tail in
        (degree + 1, remainder)
      else (0, coefficients)

let factor_polynomial
    (canonical:expression)
    (variable:string)
    (coefficients:polynomial)
  : expression
=
  match coefficients with
  | constant :: linear :: quadratic :: [] ->
      if coefficient_is_integer constant (-1) &&
         coefficient_is_integer linear 0 &&
         coefficient_is_integer quadratic 1 then
        Binary Multiply
          (Binary Subtract (Symbol variable) (Literal 1 1))
          (Binary Add (Symbol variable) (Literal 1 1))
      else if coefficient_is_integer constant 1 &&
              coefficient_is_integer linear 2 &&
              coefficient_is_integer quadratic 1 then
        Power (Binary Add (Symbol variable) (Literal 1 1)) 2
      else if coefficient_is_integer constant 1 &&
              coefficient_is_integer linear (-2) &&
              coefficient_is_integer quadratic 1 then
        Power (Binary Subtract (Symbol variable) (Literal 1 1)) 2
      else
        let degree, remainder = drop_zero_coefficients coefficients in
        if degree = 0 || (degree > 0 && remainder = []) then canonical
        else Binary Multiply
          (if degree = 1 then Symbol variable else Power (Symbol variable) degree)
          (polynomial_expression remainder variable)
  | _ ->
      let degree, remainder = drop_zero_coefficients coefficients in
      if degree = 0 || (degree > 0 && remainder = []) then canonical
      else Binary Multiply
        (if degree = 1 then Symbol variable else Power (Symbol variable) degree)
        (polynomial_expression remainder variable)

let factor_expression (term:expression) : expression =
  let canonical = canonicalize_polynomial term in
  match difference_of_squares canonical with
  | Some factored -> factored
  | None ->
      begin match scan_polynomial_variable canonical with
      | OneVariable variable ->
          begin match polynomial_of canonical variable with
          | Some coefficients -> factor_polynomial canonical variable coefficients
          | None -> canonical
          end
      | _ -> canonical
      end

let is_zero_literal (term:expression) : bool =
  match term with
  | Literal numerator denominator -> numerator = 0 && denominator <> 0
  | _ -> false

let condition_proves_nonzero
    (term left:expression)
    (relation:relation)
    (right:expression)
  : bool
=
  let strict =
    relation = NotEqual || relation = LessThan || relation = GreaterThan
  in
  strict &&
    ((term = left && is_zero_literal right) ||
     (term = right && is_zero_literal left))

let rec simplify_assuming
    (term left:expression)
    (relation:relation)
    (right:expression)
  : Tot expression
=
  match term with
  | Literal _ _ -> term
  | Symbol _ -> term
  | Negate inner -> Negate (simplify_assuming inner left relation right)
  | Binary operator inner_left inner_right ->
      let simplified_left = simplify_assuming inner_left left relation right in
      let simplified_right = simplify_assuming inner_right left relation right in
      begin match operator with
      | Divide ->
          if simplified_left = simplified_right &&
             condition_proves_nonzero simplified_right left relation right then
            Literal 1 1
          else Binary Divide simplified_left simplified_right
      | _ -> Binary operator simplified_left simplified_right
      end
  | Power base exponent ->
      let simplified = simplify_assuming base left relation right in
      if exponent = 0 && condition_proves_nonzero simplified left relation right
      then Literal 1 1
      else Power simplified exponent
  | Function name argument -> Function name
      (simplify_assuming argument left relation right)
  | Differentiate inner variable -> Differentiate
      (simplify_assuming inner left relation right) variable
  | Substitute inner variable replacement -> Substitute
      (simplify_assuming inner left relation right)
      variable
      (simplify_assuming replacement left relation right)
  | Derivative inner variable -> Derivative
      (simplify_assuming inner left relation right) variable
  | Simplify inner -> Simplify (simplify_assuming inner left relation right)
  | Expand inner -> Expand (simplify_assuming inner left relation right)
  | Factor inner -> Factor (simplify_assuming inner left relation right)
  | Assuming inner nested_left nested_relation nested_right -> Assuming
      (simplify_assuming inner left relation right)
      nested_left nested_relation nested_right

let rec resolve (term:expression) : Tot expression =
  match term with
  | Literal _ _ -> term
  | Symbol _ -> term
  | Negate inner -> Negate (resolve inner)
  | Binary operator left right -> Binary operator (resolve left) (resolve right)
  | Power base exponent -> Power (resolve base) exponent
  | Function name argument -> Function name (resolve argument)
  | Derivative inner variable -> Derivative (resolve inner) variable
  | Differentiate inner variable -> differentiate (resolve inner) variable
  | Substitute inner variable replacement -> substitute
      (resolve inner) variable (resolve replacement)
  | Simplify inner -> canonicalize_polynomial (resolve inner)
  | Expand inner -> canonicalize_polynomial (resolve inner)
  | Factor inner -> factor_expression (resolve inner)
  | Assuming inner left relation right ->
      let resolved_left = resolve left in
      let resolved_right = resolve right in
      Assuming
        (simplify_assuming (resolve inner)
          resolved_left relation resolved_right)
        resolved_left relation resolved_right

let rec evaluate (term:expression)
  : Tot (result:evaluation{evaluation_invariant result})
=
  match term with
  | Literal numerator denominator ->
      if denominator = 0 then EvaluationFailure ZeroDenominator
      else Evaluated (ExactRational (make numerator denominator))
  | Symbol name -> Evaluated (ExactSymbolic (Symbol name))
  | Negate inner ->
      begin match evaluate inner with
      | EvaluationFailure error -> EvaluationFailure error
      | Evaluated value -> Evaluated (negate_value value)
      end
  | Binary operator left right ->
      begin match evaluate left with
      | EvaluationFailure error -> EvaluationFailure error
      | Evaluated left_value ->
          begin match evaluate right with
          | EvaluationFailure error -> EvaluationFailure error
          | Evaluated right_value -> apply_values operator left_value right_value
          end
      end
  | Power base exponent ->
      begin match evaluate base with
      | EvaluationFailure error -> EvaluationFailure error
      | Evaluated value -> power_value value exponent
      end
  | Function name argument ->
      begin match evaluate argument with
      | EvaluationFailure error -> EvaluationFailure error
      | Evaluated value -> Evaluated (ExactSymbolic
          (Function name (expression_of_value value)))
      end
  | Derivative inner variable ->
      begin match evaluate inner with
      | EvaluationFailure error -> EvaluationFailure error
      | Evaluated value -> Evaluated (ExactSymbolic
          (Derivative (expression_of_value value) variable))
      end
  | Differentiate inner variable ->
      begin match evaluate inner with
      | EvaluationFailure error -> EvaluationFailure error
      | Evaluated value -> Evaluated (ExactSymbolic
          (Differentiate (expression_of_value value) variable))
      end
  | Substitute inner variable replacement ->
      begin match evaluate inner with
      | EvaluationFailure error -> EvaluationFailure error
      | Evaluated inner_value ->
          begin match evaluate replacement with
          | EvaluationFailure error -> EvaluationFailure error
          | Evaluated replacement_value -> Evaluated (ExactSymbolic
              (Substitute
                (expression_of_value inner_value)
                variable
                (expression_of_value replacement_value)))
          end
      end
  | Simplify inner -> evaluate inner
  | Expand inner -> evaluate inner
  | Factor inner -> evaluate inner
  | Assuming inner left relation right ->
      begin match evaluate inner with
      | EvaluationFailure error -> EvaluationFailure error
      | Evaluated inner_value ->
          begin match evaluate left with
          | EvaluationFailure error -> EvaluationFailure error
          | Evaluated left_value ->
              begin match evaluate right with
              | EvaluationFailure error -> EvaluationFailure error
              | Evaluated right_value -> Evaluated (ExactSymbolic
                  (Assuming
                    (expression_of_value inner_value)
                    (expression_of_value left_value)
                    relation
                    (expression_of_value right_value)))
              end
          end
      end
