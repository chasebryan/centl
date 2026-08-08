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
  let raw_left : C.rational = {
    numerator =
      left_a.numerator * left_b.denominator +
      left_b.numerator * left_a.denominator;
    denominator = left_a.denominator * left_b.denominator
  } in
  let raw_right : C.rational = {
    numerator =
      right_a.numerator * right_b.denominator +
      right_b.numerator * right_a.denominator;
    denominator = right_a.denominator * right_b.denominator
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
  assert (
    raw_left.numerator * raw_right.denominator =
    left_a_cross * (left_b.denominator * right_b.denominator) +
    left_b_cross * (left_a.denominator * right_a.denominator))
    by (FStar.Tactics.Canon.canon ());
  assert (
    raw_right.numerator * raw_left.denominator =
    right_a_cross * (right_b.denominator * left_b.denominator) +
    right_b_cross * (right_a.denominator * left_a.denominator))
    by (FStar.Tactics.Canon.canon ());
  assert (
    left_a_cross * (left_b.denominator * right_b.denominator) =
    right_a_cross * (right_b.denominator * left_b.denominator))
    by (FStar.Tactics.Canon.canon ());
  assert (
    left_b_cross * (left_a.denominator * right_a.denominator) =
    right_b_cross * (right_a.denominator * left_a.denominator))
    by (FStar.Tactics.Canon.canon ());
  assert (
    raw_left.numerator * raw_right.denominator =
    raw_right.numerator * raw_left.denominator);
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
  let raw_left : C.rational = {
    numerator = left_a.numerator * left_b.numerator;
    denominator = left_a.denominator * left_b.denominator
  } in
  let raw_right : C.rational = {
    numerator = right_a.numerator * right_b.numerator;
    denominator = right_a.denominator * right_b.denominator
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
  assert (
    raw_left.numerator * raw_right.denominator =
    left_a_cross * left_b_cross)
    by (FStar.Tactics.Canon.canon ());
  assert (
    raw_right.numerator * raw_left.denominator =
    right_a_cross * right_b_cross)
    by (FStar.Tactics.Canon.canon ());
  assert (left_a_cross * left_b_cross = right_a_cross * right_b_cross);
  assert (
    raw_left.numerator * raw_right.denominator =
    raw_right.numerator * raw_left.denominator);
  assert (C.equivalent raw_left raw_right);
  equivalent_transitive left_result raw_left raw_right;
  equivalent_symmetric right_result raw_right;
  equivalent_transitive left_result raw_right right_result

#pop-options