module Centl.PolynomialSoundness

module Core = Centl.Core

type coefficient = value:Core.rational{Core.invariant value}
type polynomial = list coefficient

(** A coefficient list is zero when every coefficient has zero numerator.
    Since every coefficient is a normalized CENTL rational with positive
    denominator, this is the exact zero predicate used by polynomial identity
    certification. *)
let rec polynomial_is_zero (coefficients:polynomial) : Tot bool =
  match coefficients with
  | [] -> true
  | head :: tail -> head.numerator = 0 && polynomial_is_zero tail

#push-options "--z3rlimit 20"

let make_zero_numerator ()
  : Lemma (ensures (Core.make 0 1).numerator = 0)
=
  let zero = Core.make 0 1 in
  assert (Core.equivalent zero { numerator = 0; denominator = 1 });
  assert (zero.numerator * 1 = 0 * zero.denominator);
  assert (zero.numerator = 0)

let zero_numerator_is_equivalent_zero
    (value:Core.rational{Core.invariant value})
  : Lemma
      (requires value.numerator = 0)
      (ensures Core.equivalent value (Core.make 0 1))
=
  make_zero_numerator ();
  let zero = Core.make 0 1 in
  assert (value.numerator * zero.denominator =
    zero.numerator * value.denominator)

let equivalent_zero_implies_numerator_zero
    (value:Core.rational{Core.invariant value})
  : Lemma
      (requires Core.equivalent value (Core.make 0 1))
      (ensures value.numerator = 0)
=
  make_zero_numerator ();
  let zero = Core.make 0 1 in
  assert (value.numerator * zero.denominator =
    zero.numerator * value.denominator);
  assert (value.numerator * zero.denominator = 0);
  assert (zero.denominator > 0);
  assert (value.numerator = 0)

let equivalent_unreduced_zero_is_zero
    (value:Core.rational{Core.invariant value})
    (unreduced_denominator:pos)
  : Lemma
      (requires
        Core.equivalent value {
          numerator = 0;
          denominator = unreduced_denominator
        })
      (ensures Core.equivalent value (Core.make 0 1))
=
  assert (value.numerator * unreduced_denominator =
    0 * value.denominator);
  assert (value.numerator * unreduced_denominator = 0);
  assert (value.numerator = 0);
  zero_numerator_is_equivalent_zero value

let multiply_zero_right
    (left right:Core.rational{
      Core.invariant left /\ Core.invariant right})
  : Lemma
      (requires Core.equivalent right (Core.make 0 1))
      (ensures Core.equivalent
        (Core.multiply left right) (Core.make 0 1))
=
  equivalent_zero_implies_numerator_zero right;
  let product = Core.multiply left right in
  assert (Core.equivalent product {
    numerator = left.numerator * right.numerator;
    denominator = left.denominator * right.denominator
  });
  assert (right.numerator = 0);
  assert (left.numerator * right.numerator = 0);
  equivalent_unreduced_zero_is_zero product
    (left.denominator * right.denominator)

let add_zero_zero
    (left right:Core.rational{
      Core.invariant left /\ Core.invariant right})
  : Lemma
      (requires
        Core.equivalent left (Core.make 0 1) /\
        Core.equivalent right (Core.make 0 1))
      (ensures Core.equivalent
        (Core.add left right) (Core.make 0 1))
=
  equivalent_zero_implies_numerator_zero left;
  equivalent_zero_implies_numerator_zero right;
  let sum = Core.add left right in
  assert (Core.equivalent sum {
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

(** First soundness layer: a zero coefficient list denotes zero at every
    rational point under the production Horner evaluator. *)
let rec zero_polynomial_evaluates_to_zero
    (coefficients:polynomial)
    (point:coefficient)
  : Lemma
      (requires polynomial_is_zero coefficients)
      (ensures
        Core.equivalent
          (Core.polynomial_evaluate_horner coefficients point)
          (Core.make 0 1))
      (decreases coefficients)
=
  match coefficients with
  | [] -> ()
  | head :: tail ->
      assert (head.numerator = 0 && polynomial_is_zero tail);
      zero_polynomial_evaluates_to_zero tail point;
      zero_numerator_is_equivalent_zero head;
      multiply_zero_right point
        (Core.polynomial_evaluate_horner tail point);
      add_zero_zero head
        (Core.multiply point
          (Core.polynomial_evaluate_horner tail point))

#pop-options

(** A deliberately narrower collector than [Core.polynomial_of].  Division is
    excluded from the proof-backed certification path for now; rational
    constants remain fully supported through [Literal numerator denominator].
    Unsupported syntax returns [None] and therefore cannot be certified. *)
let rec sound_polynomial_of
    (term:Core.expression)
    (variable:string)
  : Tot (option polynomial)
=
  match term with
  | Core.Literal numerator denominator ->
      if denominator = 0 then None
      else Some [Core.make numerator denominator]
  | Core.Symbol name ->
      if name = variable
      then Some [Core.make 0 1; Core.make 1 1]
      else None
  | Core.Negate inner ->
      begin match sound_polynomial_of inner variable with
      | None -> None
      | Some value -> Some (Core.polynomial_negate value)
      end
  | Core.Binary operator left right ->
      begin match operator with
      | Core.Divide -> None
      | Core.Add
      | Core.Subtract
      | Core.Multiply ->
          begin match sound_polynomial_of left variable,
                      sound_polynomial_of right variable with
          | Some left_value, Some right_value ->
              begin match operator with
              | Core.Add -> Some (Core.polynomial_add left_value right_value)
              | Core.Subtract ->
                  Some (Core.polynomial_subtract left_value right_value)
              | Core.Multiply ->
                  Some (Core.polynomial_multiply left_value right_value)
              | Core.Divide -> None
              end
          | _, _ -> None
          end
      end
  | Core.Power base exponent ->
      if exponent > 0 && exponent <= Core.maximum_expansion_exponent then
        begin match sound_polynomial_of base variable with
        | None -> None
        | Some value -> Some (Core.polynomial_power value exponent)
        end
      else None
  | Core.Simplify inner -> sound_polynomial_of inner variable
  | Core.Expand inner -> sound_polynomial_of inner variable
  | Core.Factor inner -> sound_polynomial_of inner variable
  | Core.Function _ _ -> None
  | Core.Differentiate _ _ -> None
  | Core.Substitute _ _ _ -> None
  | Core.Derivative _ _ -> None
  | Core.Assuming _ _ _ _ -> None

let rec rational_power_product
    (base:coefficient)
    (exponent:nat)
  : Tot coefficient (decreases exponent)
=
  if exponent = 0 then Core.make 1 1
  else Core.multiply base (rational_power_product base (exponent - 1))

(** Independent denotational evaluator for the exact syntax accepted by
    [sound_polynomial_of].  It is intentionally not implemented by Horner
    evaluation or coefficient collection. *)
let rec evaluate_rational_polynomial
    (term:Core.expression)
    (variable:string)
    (point:coefficient)
  : Tot (option coefficient)
=
  match term with
  | Core.Literal numerator denominator ->
      if denominator = 0 then None
      else Some (Core.make numerator denominator)
  | Core.Symbol name -> if name = variable then Some point else None
  | Core.Negate inner ->
      begin match evaluate_rational_polynomial inner variable point with
      | Some value -> Some (Core.negate value)
      | None -> None
      end
  | Core.Binary operator left right ->
      begin match operator with
      | Core.Divide -> None
      | Core.Add
      | Core.Subtract
      | Core.Multiply ->
          begin match evaluate_rational_polynomial left variable point,
                      evaluate_rational_polynomial right variable point with
          | Some left_value, Some right_value ->
              begin match operator with
              | Core.Add -> Some (Core.add left_value right_value)
              | Core.Subtract -> Some (Core.subtract left_value right_value)
              | Core.Multiply -> Some (Core.multiply left_value right_value)
              | Core.Divide -> None
              end
          | _, _ -> None
          end
      end
  | Core.Power base exponent ->
      if exponent > 0 && exponent <= Core.maximum_expansion_exponent then
        begin match evaluate_rational_polynomial base variable point with
        | Some value -> Some (rational_power_product value exponent)
        | None -> None
        end
      else None
  | Core.Simplify inner -> evaluate_rational_polynomial inner variable point
  | Core.Expand inner -> evaluate_rational_polynomial inner variable point
  | Core.Factor inner -> evaluate_rational_polynomial inner variable point
  | Core.Function _ _ -> None
  | Core.Differentiate _ _ -> None
  | Core.Substitute _ _ _ -> None
  | Core.Derivative _ _ -> None
  | Core.Assuming _ _ _ _ -> None

type zero_certificate =
  | CertifiedZero
  | NotCertifiedZero

let certify_zero_difference
    (term:Core.expression)
    (variable:string)
  : Tot zero_certificate
=
  match sound_polynomial_of term variable with
  | Some coefficients ->
      if polynomial_is_zero coefficients
      then CertifiedZero
      else NotCertifiedZero
  | None -> NotCertifiedZero

(** The remaining proof obligation on this branch is the structural bridge:
    [sound_polynomial_of] must be shown equivalent to
    [evaluate_rational_polynomial] at every rational point.  Only after that
    theorem is discharged may [CertifiedZero] become production
    [verified_core] assurance. *)
