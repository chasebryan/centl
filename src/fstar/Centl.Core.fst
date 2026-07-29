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
  | Negate: expression -> expression
  | Binary: binary_operator -> expression -> expression -> expression

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

type error =
  | ZeroDenominator
  | DivisionByZero

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
   | Failure ZeroDenominator -> False)

let divide (left right:rational{invariant left /\ invariant right})
  : Tot (result:outcome{division_postcondition left right result})
=
  if right.numerator = 0 then
    Failure DivisionByZero
  else
    Success (make
      (left.numerator * right.denominator)
      (left.denominator * right.numerator))

let apply (operator:binary_operator)
          (left right:rational{invariant left /\ invariant right})
  : Tot (result:outcome{outcome_invariant result})
=
  match operator with
  | Add -> Success (add left right)
  | Subtract -> Success (subtract left right)
  | Multiply -> Success (multiply left right)
  | Divide -> divide left right

let rec evaluate (term:expression)
  : Tot (result:outcome{outcome_invariant result})
=
  match term with
  | Literal numerator denominator ->
      if denominator = 0 then Failure ZeroDenominator
      else Success (make numerator denominator)
  | Negate inner ->
      begin match evaluate inner with
      | Failure error -> Failure error
      | Success value -> Success (negate value)
      end
  | Binary operator left right ->
      begin match evaluate left with
      | Failure error -> Failure error
      | Success left_value ->
          begin match evaluate right with
          | Failure error -> Failure error
          | Success right_value -> apply operator left_value right_value
          end
      end
