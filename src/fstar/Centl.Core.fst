module Centl.Core

module Gcd = Centl.Gcd
module Euclid = FStar.Math.Euclid
module Math = FStar.Math.Lemmas

type binary_operator =
  | Add
  | Subtract
  | Multiply
  | Divide

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
