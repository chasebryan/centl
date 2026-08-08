module Centl.PolynomialSoundness

module C = Centl.Core

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
  assert (middle.denominator <> 0);
  assert (
    left.numerator * middle.denominator * right.denominator =
    right.numerator * middle.denominator * left.denominator)
    by (FStar.Tactics.Canon.canon ());
  assert (C.equivalent left right)

let negate_respects_equivalent
    (left right:C.rational{C.invariant left /\ C.invariant right})
  : Lemma
      (requires C.equivalent left right)
      (ensures C.equivalent (C.negate left) (C.negate right))
=
  let left_result = C.negate left in
  let right_result = C.negate right in
  assert (C.equivalent left_result {
    numerator = -left.numerator;
    denominator = left.denominator
  });
  assert (C.equivalent right_result {
    numerator = -right.numerator;
    denominator = right.denominator
  });
  assert (C.equivalent left_result right_result)
    by (FStar.Tactics.Canon.canon ())

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
  assert (C.equivalent left_result {
    numerator =
      left_a.numerator * left_b.denominator +
      left_b.numerator * left_a.denominator;
    denominator = left_a.denominator * left_b.denominator
  });
  assert (C.equivalent right_result {
    numerator =
      right_a.numerator * right_b.denominator +
      right_b.numerator * right_a.denominator;
    denominator = right_a.denominator * right_b.denominator
  });
  assert (C.equivalent left_result right_result)
    by (FStar.Tactics.Canon.canon ())

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
  assert (C.equivalent left_result {
    numerator = left_a.numerator * left_b.numerator;
    denominator = left_a.denominator * left_b.denominator
  });
  assert (C.equivalent right_result {
    numerator = right_a.numerator * right_b.numerator;
    denominator = right_a.denominator * right_b.denominator
  });
  assert (C.equivalent left_result right_result)
    by (FStar.Tactics.Canon.canon ())

#pop-options
