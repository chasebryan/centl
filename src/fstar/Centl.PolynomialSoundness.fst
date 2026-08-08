module Centl.PolynomialSoundness

module C = Centl.Core
module Math = FStar.Math.Lemmas

(** Proof-only support for the 0.12 univariate rational polynomial assurance
    boundary.  This module is verified but not extracted into runtime code. *)

let equivalent_reflexive
    (value:C.rational{C.invariant value})
  : Lemma (ensures C.equivalent value value)
= ()

let equivalent_symmetric
    (left right:C.rational{C.invariant left /\ C.invariant right})
  : Lemma
      (requires C.equivalent left right)
      (ensures C.equivalent right left)
= ()

#push-options "--z3rlimit 20"

let equivalent_transitive
    (left middle right:C.rational{
      C.invariant left /\ C.invariant middle /\ C.invariant right})
  : Lemma
      (requires C.equivalent left middle /\ C.equivalent middle right)
      (ensures C.equivalent left right)
=
  assert (middle.denominator > 0);
  assert (
    left.numerator * middle.denominator * right.denominator =
    right.numerator * middle.denominator * left.denominator)
    by (FStar.Tactics.Canon.canon ());
  assert (
    (left.numerator * right.denominator) * middle.denominator =
    (right.numerator * left.denominator) * middle.denominator)
    by (FStar.Tactics.Canon.canon ());
  Math.lemma_cancel_mul
    (left.numerator * right.denominator)
    (right.numerator * left.denominator)
    middle.denominator;
  assert (C.equivalent left right)

(** Keep ordinary equality substitution separate from the nonlinear rational
    algebra below.  These lemmas need only congruence, not ring reasoning. *)
let multiply_int_right_respects_equality
    (left right multiplier:int)
  : Lemma
      (requires left = right)
      (ensures left * multiplier = right * multiplier)
= ()

let add_int_respects_pairwise_equality
    (left_a right_a left_b right_b:int)
  : Lemma
      (requires left_a = right_a /\ left_b = right_b)
      (ensures left_a + left_b = right_a + right_b)
= ()

let multiply_int_respects_pairwise_equality
    (left_a right_a left_b right_b:int)
  : Lemma
      (requires left_a = right_a /\ left_b = right_b)
      (ensures left_a * left_b = right_a * right_b)
= ()

(** Reassociate and commute four integer factors using F*'s explicit integer
    ring laws.  This avoids expensive nonlinear normalization in the rational
    congruence proofs below. *)
let reorder_four_ac_bd (a b c d:int)
  : Lemma (ensures (a * b) * (c * d) = (a * c) * (b * d))
=
  Math.paren_mul_right a b (c * d);
  Math.paren_mul_left b c d;
  Math.swap_mul b c;
  Math.paren_mul_right c b d;
  Math.paren_mul_left a c (b * d)

let reorder_four_ad_bc (a b c d:int)
  : Lemma (ensures (a * b) * (c * d) = (a * d) * (b * c))
=
  Math.swap_mul c d;
  reorder_four_ac_bd a b d c

let reorder_four_ac_db (a b c d:int)
  : Lemma (ensures (a * b) * (c * d) = (a * c) * (d * b))
=
  reorder_four_ac_bd a b c d;
  Math.swap_mul b d

let negate_respects_equivalent
    (left right:C.rational{C.invariant left /\ C.invariant right})
  : Lemma
      (requires C.equivalent left right)
      (ensures C.equivalent (C.negate left) (C.negate right))
=
  let left_result = C.negate left in
  let right_result = C.negate right in
  let raw_left : C.rational = {
    numerator = -left.numerator;
    denominator = left.denominator
  } in
  let raw_right : C.rational = {
    numerator = -right.numerator;
    denominator = right.denominator
  } in
  assert (C.invariant raw_left);
  assert (C.invariant raw_right);
  assert (C.equivalent left_result raw_left);
  assert (C.equivalent right_result raw_right);
  assert (C.equivalent raw_left raw_right)
    by (FStar.Tactics.Canon.canon ());
  equivalent_transitive left_result raw_left raw_right;
  equivalent_symmetric right_result raw_right;
  equivalent_transitive left_result raw_right right_result

let add_respects_equivalent
    (left_a left_b right_a right_b:C.rational{
      C.invariant left_a /\ C.invariant left_b /\
      C.invariant right_a /\ C.invariant right_b})
  : Lemma
      (requires
        C.equivalent left_a right_a /\
        C.equivalent left_b right_b)
      (ensures
        C.equivalent
          (C.add left_a left_b)
          (C.add right_a right_b))
=
  let left_result = C.add left_a left_b in
  let right_result = C.add right_a right_b in
  let left_first = left_a.numerator * left_b.denominator in
  let left_second = left_b.numerator * left_a.denominator in
  let left_numerator = left_first + left_second in
  let left_denominator = left_a.denominator * left_b.denominator in
  let right_first = right_a.numerator * right_b.denominator in
  let right_second = right_b.numerator * right_a.denominator in
  let right_numerator = right_first + right_second in
  let right_denominator = right_a.denominator * right_b.denominator in
  let raw_left : C.rational = {
    numerator = left_numerator;
    denominator = left_denominator
  } in
  let raw_right : C.rational = {
    numerator = right_numerator;
    denominator = right_denominator
  } in
  assert (C.invariant raw_left);
  assert (C.invariant raw_right);
  assert (C.equivalent left_result raw_left);
  assert (C.equivalent right_result raw_right);
  assert (
    left_a.numerator * right_a.denominator =
    right_a.numerator * left_a.denominator);
  assert (
    left_b.numerator * right_b.denominator =
    right_b.numerator * left_b.denominator);
  let left_a_cross = left_a.numerator * right_a.denominator in
  let right_a_cross = right_a.numerator * left_a.denominator in
  let left_b_cross = left_b.numerator * right_b.denominator in
  let right_b_cross = right_b.numerator * left_b.denominator in
  let a_multiplier = left_b.denominator * right_b.denominator in
  let b_multiplier = left_a.denominator * right_a.denominator in
  let left_expanded_first = left_first * right_denominator in
  let left_expanded_second = left_second * right_denominator in
  let right_expanded_first = right_first * left_denominator in
  let right_expanded_second = right_second * left_denominator in
  assert (left_a_cross = right_a_cross);
  assert (left_b_cross = right_b_cross);
  Math.distributivity_add_left left_first left_second right_denominator;
  assert (left_numerator * right_denominator =
    left_expanded_first + left_expanded_second);
  reorder_four_ac_bd
    left_a.numerator left_b.denominator
    right_a.denominator right_b.denominator;
  reorder_four_ad_bc
    left_b.numerator left_a.denominator
    right_a.denominator right_b.denominator;
  assert (left_expanded_first = left_a_cross * a_multiplier);
  assert (left_expanded_second = left_b_cross * b_multiplier);
  add_int_respects_pairwise_equality
    left_expanded_first (left_a_cross * a_multiplier)
    left_expanded_second (left_b_cross * b_multiplier);
  assert (left_numerator * right_denominator =
    left_a_cross * a_multiplier + left_b_cross * b_multiplier);
  Math.distributivity_add_left right_first right_second left_denominator;
  assert (right_numerator * left_denominator =
    right_expanded_first + right_expanded_second);
  reorder_four_ac_db
    right_a.numerator right_b.denominator
    left_a.denominator left_b.denominator;
  reorder_four_ad_bc
    right_b.numerator right_a.denominator
    left_a.denominator left_b.denominator;
  assert (right_expanded_first = right_a_cross * a_multiplier);
  assert (right_expanded_second = right_b_cross * b_multiplier);
  add_int_respects_pairwise_equality
    right_expanded_first (right_a_cross * a_multiplier)
    right_expanded_second (right_b_cross * b_multiplier);
  assert (right_numerator * left_denominator =
    right_a_cross * a_multiplier + right_b_cross * b_multiplier);
  multiply_int_right_respects_equality
    left_a_cross right_a_cross a_multiplier;
  multiply_int_right_respects_equality
    left_b_cross right_b_cross b_multiplier;
  add_int_respects_pairwise_equality
    (left_a_cross * a_multiplier)
    (right_a_cross * a_multiplier)
    (left_b_cross * b_multiplier)
    (right_b_cross * b_multiplier);
  assert (left_numerator * right_denominator =
    right_numerator * left_denominator);
  assert (raw_left.numerator = left_numerator);
  assert (raw_left.denominator = left_denominator);
  assert (raw_right.numerator = right_numerator);
  assert (raw_right.denominator = right_denominator);
  assert (C.equivalent raw_left raw_right);
  equivalent_transitive left_result raw_left raw_right;
  equivalent_symmetric right_result raw_right;
  equivalent_transitive left_result raw_right right_result

let multiply_respects_equivalent
    (left_a left_b right_a right_b:C.rational{
      C.invariant left_a /\ C.invariant left_b /\
      C.invariant right_a /\ C.invariant right_b})
  : Lemma
      (requires
        C.equivalent left_a right_a /\
        C.equivalent left_b right_b)
      (ensures
        C.equivalent
          (C.multiply left_a left_b)
          (C.multiply right_a right_b))
=
  let left_result = C.multiply left_a left_b in
  let right_result = C.multiply right_a right_b in
  let left_numerator = left_a.numerator * left_b.numerator in
  let left_denominator = left_a.denominator * left_b.denominator in
  let right_numerator = right_a.numerator * right_b.numerator in
  let right_denominator = right_a.denominator * right_b.denominator in
  let raw_left : C.rational = {
    numerator = left_numerator;
    denominator = left_denominator
  } in
  let raw_right : C.rational = {
    numerator = right_numerator;
    denominator = right_denominator
  } in
  assert (C.invariant raw_left);
  assert (C.invariant raw_right);
  assert (C.equivalent left_result raw_left);
  assert (C.equivalent right_result raw_right);
  assert (
    left_a.numerator * right_a.denominator =
    right_a.numerator * left_a.denominator);
  assert (
    left_b.numerator * right_b.denominator =
    right_b.numerator * left_b.denominator);
  let left_a_cross = left_a.numerator * right_a.denominator in
  let right_a_cross = right_a.numerator * left_a.denominator in
  let left_b_cross = left_b.numerator * right_b.denominator in
  let right_b_cross = right_b.numerator * left_b.denominator in
  assert (left_a_cross = right_a_cross);
  assert (left_b_cross = right_b_cross);
  reorder_four_ac_bd
    left_a.numerator left_b.numerator
    right_a.denominator right_b.denominator;
  assert (left_numerator * right_denominator =
    left_a_cross * left_b_cross);
  reorder_four_ac_bd
    right_a.numerator right_b.numerator
    left_a.denominator left_b.denominator;
  assert (right_numerator * left_denominator =
    right_a_cross * right_b_cross);
  multiply_int_respects_pairwise_equality
    left_a_cross right_a_cross left_b_cross right_b_cross;
  assert (left_numerator * right_denominator =
    right_numerator * left_denominator);
  assert (raw_left.numerator = left_numerator);
  assert (raw_left.denominator = left_denominator);
  assert (raw_right.numerator = right_numerator);
  assert (raw_right.denominator = right_denominator);
  assert (C.equivalent raw_left raw_right);
  equivalent_transitive left_result raw_left raw_right;
  equivalent_symmetric right_result raw_right;
  equivalent_transitive left_result raw_right right_result

#pop-options

(** The remaining soundness scaffold stays in this proof-only module until the
    semantic bridge is complete.  This prevents unfinished theorem machinery
    from changing the extracted runtime. *)

type coefficient = C.coefficient
type polynomial = C.polynomial

let rec rational_power_product
    (base:C.rational{C.invariant base})
    (exponent:nat)
  : Tot (result:C.rational{C.invariant result}) (decreases exponent)
=
  if exponent = 0 then C.make 1 1
  else C.multiply base (rational_power_product base (exponent - 1))

let rec evaluate_rational_polynomial
    (term:C.expression)
    (variable:string)
    (point:C.rational{C.invariant point})
  : Tot (option (value:C.rational{C.invariant value})) (decreases term)
=
  match term with
  | C.Literal numerator denominator ->
      if denominator = 0 then None else Some (C.make numerator denominator)
  | C.Symbol name -> if name = variable then Some point else None
  | C.Negate inner ->
      begin match evaluate_rational_polynomial inner variable point with
      | Some value -> Some (C.negate value)
      | None -> None
      end
  | C.Binary operator left right ->
      begin match evaluate_rational_polynomial left variable point,
                  evaluate_rational_polynomial right variable point with
      | Some left_value, Some right_value ->
          begin match operator with
          | C.Add -> Some (C.add left_value right_value)
          | C.Subtract -> Some (C.subtract left_value right_value)
          | C.Multiply -> Some (C.multiply left_value right_value)
          | C.Divide ->
              begin match C.divide left_value right_value with
              | C.Success value -> Some value
              | C.Failure _ -> None
              end
          end
      | _, _ -> None
      end
  | C.Power base exponent ->
      if exponent > 0 && exponent <= C.maximum_expansion_exponent then
        begin match evaluate_rational_polynomial base variable point with
        | Some value -> Some (rational_power_product value exponent)
        | None -> None
        end
      else None
  | C.Function _ _ -> None
  | C.Differentiate _ _ -> None
  | C.Substitute _ _ _ -> None
  | C.Derivative _ _ -> None
  | C.Simplify inner -> evaluate_rational_polynomial inner variable point
  | C.Expand inner -> evaluate_rational_polynomial inner variable point
  | C.Factor inner -> evaluate_rational_polynomial inner variable point
  | C.Assuming _ _ _ _ -> None

let rec polynomial_is_zero (coefficients:polynomial) : Tot bool =
  match coefficients with
  | [] -> true
  | head :: tail -> head.numerator = 0 && polynomial_is_zero tail

#push-options "--z3rlimit 20"

let make_zero_numerator ()
  : Lemma (ensures (C.make 0 1).numerator = 0)
=
  let zero = C.make 0 1 in
  assert (C.equivalent zero { numerator = 0; denominator = 1 });
  assert (zero.numerator * 1 = 0 * zero.denominator);
  assert (zero.numerator = 0)

let zero_numerator_is_equivalent_zero
    (value:C.rational{C.invariant value})
  : Lemma
      (requires value.numerator = 0)
      (ensures C.equivalent value (C.make 0 1))
=
  make_zero_numerator ();
  let zero = C.make 0 1 in
  assert (value.numerator * zero.denominator =
    zero.numerator * value.denominator)

let equivalent_zero_implies_numerator_zero
    (value:C.rational{C.invariant value})
  : Lemma
      (requires C.equivalent value (C.make 0 1))
      (ensures value.numerator = 0)
=
  make_zero_numerator ();
  let zero = C.make 0 1 in
  assert (value.numerator * zero.denominator =
    zero.numerator * value.denominator);
  assert (value.numerator * zero.denominator = 0);
  assert (zero.denominator > 0);
  assert (value.numerator = 0)

let equivalent_unreduced_zero_is_zero
    (value:C.rational{C.invariant value})
    (unreduced_denominator:pos)
  : Lemma
      (requires
        C.equivalent value {
          numerator = 0;
          denominator = unreduced_denominator
        })
      (ensures C.equivalent value (C.make 0 1))
=
  assert (value.numerator * unreduced_denominator =
    0 * value.denominator);
  assert (value.numerator * unreduced_denominator = 0);
  assert (value.numerator = 0);
  zero_numerator_is_equivalent_zero value

let multiply_zero_right
    (left right:C.rational{C.invariant left /\ C.invariant right})
  : Lemma
      (requires C.equivalent right (C.make 0 1))
      (ensures C.equivalent (C.multiply left right) (C.make 0 1))
=
  equivalent_zero_implies_numerator_zero right;
  let product = C.multiply left right in
  assert (C.equivalent product {
    numerator = left.numerator * right.numerator;
    denominator = left.denominator * right.denominator
  });
  assert (right.numerator = 0);
  assert (left.numerator * right.numerator = 0);
  equivalent_unreduced_zero_is_zero product
    (left.denominator * right.denominator)

let add_zero_zero
    (left right:C.rational{C.invariant left /\ C.invariant right})
  : Lemma
      (requires
        C.equivalent left (C.make 0 1) /\
        C.equivalent right (C.make 0 1))
      (ensures C.equivalent (C.add left right) (C.make 0 1))
=
  equivalent_zero_implies_numerator_zero left;
  equivalent_zero_implies_numerator_zero right;
  let sum = C.add left right in
  assert (C.equivalent sum {
    numerator =
      left.numerator * right.denominator +
      right.numerator * left.denominator;
    denominator = left.denominator * right.denominator
  });
  assert (left.numerator = 0);
  assert (right.numerator = 0);
  assert (
    left.numerator * right.denominator +
    right.numerator * left.denominator = 0);
  equivalent_unreduced_zero_is_zero sum
    (left.denominator * right.denominator)

let rec zero_polynomial_evaluates_to_zero
    (coefficients:polynomial)
    (point:coefficient)
  : Lemma
      (requires polynomial_is_zero coefficients)
      (ensures
        C.equivalent
          (C.polynomial_evaluate_horner coefficients point)
          (C.make 0 1))
      (decreases coefficients)
=
  match coefficients with
  | [] -> ()
  | head :: tail ->
      assert (head.numerator = 0 && polynomial_is_zero tail);
      zero_polynomial_evaluates_to_zero tail point;
      zero_numerator_is_equivalent_zero head;
      multiply_zero_right point
        (C.polynomial_evaluate_horner tail point);
      add_zero_zero head
        (C.multiply point (C.polynomial_evaluate_horner tail point))

#pop-options

type rational_polynomial_model =
  | RZConstant:
      value:C.rational{C.invariant value} -> rational_polynomial_model
  | RZVariable
  | RZNegate: rational_polynomial_model -> rational_polynomial_model
  | RZAdd:
      rational_polynomial_model -> rational_polynomial_model ->
      rational_polynomial_model
  | RZSubtract:
      rational_polynomial_model -> rational_polynomial_model ->
      rational_polynomial_model
  | RZMultiply:
      rational_polynomial_model -> rational_polynomial_model ->
      rational_polynomial_model
  | RZScale:
      factor:C.rational{C.invariant factor} ->
      rational_polynomial_model ->
      rational_polynomial_model
  | RZPower: rational_polynomial_model -> nat -> rational_polynomial_model

let rec rational_polynomial_model_value
    (term:rational_polynomial_model)
    (point:C.rational{C.invariant point})
  : Tot (result:C.rational{C.invariant result}) (decreases term)
=
  match term with
  | RZConstant value -> value
  | RZVariable -> point
  | RZNegate inner ->
      C.negate (rational_polynomial_model_value inner point)
  | RZAdd left right ->
      C.add
        (rational_polynomial_model_value left point)
        (rational_polynomial_model_value right point)
  | RZSubtract left right ->
      C.subtract
        (rational_polynomial_model_value left point)
        (rational_polynomial_model_value right point)
  | RZMultiply left right ->
      C.multiply
        (rational_polynomial_model_value left point)
        (rational_polynomial_model_value right point)
  | RZScale factor inner ->
      C.multiply factor (rational_polynomial_model_value inner point)
  | RZPower base exponent ->
      rational_power_product
        (rational_polynomial_model_value base point) exponent

let rec collect_rational_polynomial_model
    (term:rational_polynomial_model)
  : Tot polynomial (decreases term)
=
  match term with
  | RZConstant value -> [value]
  | RZVariable -> [C.make 0 1; C.make 1 1]
  | RZNegate inner ->
      C.polynomial_negate (collect_rational_polynomial_model inner)
  | RZAdd left right ->
      C.polynomial_add
        (collect_rational_polynomial_model left)
        (collect_rational_polynomial_model right)
  | RZSubtract left right ->
      C.polynomial_subtract
        (collect_rational_polynomial_model left)
        (collect_rational_polynomial_model right)
  | RZMultiply left right ->
      C.polynomial_multiply
        (collect_rational_polynomial_model left)
        (collect_rational_polynomial_model right)
  | RZScale factor inner ->
      C.polynomial_scale factor (collect_rational_polynomial_model inner)
  | RZPower base exponent ->
      C.polynomial_power (collect_rational_polynomial_model base) exponent

let rec embed_rational_polynomial_model
    (term:rational_polynomial_model)
    (variable:string)
  : Tot C.expression (decreases term)
=
  match term with
  | RZConstant value -> C.Literal value.numerator value.denominator
  | RZVariable -> C.Symbol variable
  | RZNegate inner ->
      C.Negate (embed_rational_polynomial_model inner variable)
  | RZAdd left right ->
      C.Binary C.Add
        (embed_rational_polynomial_model left variable)
        (embed_rational_polynomial_model right variable)
  | RZSubtract left right ->
      C.Binary C.Subtract
        (embed_rational_polynomial_model left variable)
        (embed_rational_polynomial_model right variable)
  | RZMultiply left right ->
      C.Binary C.Multiply
        (embed_rational_polynomial_model left variable)
        (embed_rational_polynomial_model right variable)
  | RZScale factor inner ->
      C.Binary C.Multiply
        (C.Literal factor.numerator factor.denominator)
        (embed_rational_polynomial_model inner variable)
  | RZPower base exponent ->
      C.Power (embed_rational_polynomial_model base variable) exponent

let rational_polynomial_zero_difference_sound
    (coefficients:polynomial)
    (point:coefficient)
  : Lemma
      (requires polynomial_is_zero coefficients)
      (ensures
        C.equivalent
          (C.polynomial_evaluate_horner coefficients point)
          (C.make 0 1))
= zero_polynomial_evaluates_to_zero coefficients point

let zero_polynomial_horner_example
    (point:C.rational{C.invariant point})
  : Lemma
      (ensures
        C.equivalent
          (C.polynomial_evaluate_horner
            [C.make 0 1; C.make 0 1; C.make 0 1] point)
          (C.make 0 1))
=
  rational_polynomial_zero_difference_sound
    [C.make 0 1; C.make 0 1; C.make 0 1] point