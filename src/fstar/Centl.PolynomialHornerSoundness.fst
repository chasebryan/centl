module Centl.PolynomialHornerSoundness

module C = Centl.Core
module P = Centl.PolynomialSoundness

(** Second proof-only layer for the 0.12 polynomial assurance boundary.
    This module begins the semantic bridge from production coefficient
    collection/Horner evaluation to the independent polynomial model. *)

let make_one_numerator_equals_denominator ()
  : Lemma
      (ensures
        (C.make 1 1).numerator = (C.make 1 1).denominator)
=
  let one = C.make 1 1 in
  assert (C.equivalent one { numerator = 1; denominator = 1 });
  assert (one.numerator * 1 = 1 * one.denominator);
  assert (one.numerator = one.denominator)

let add_zero_right
    (value:C.rational{C.invariant value})
  : Lemma
      (ensures
        C.equivalent (C.add value (C.make 0 1)) value)
=
  let zero = C.make 0 1 in
  P.make_zero_numerator ();
  let result = C.add value zero in
  let raw : C.rational = {
    numerator =
      value.numerator * zero.denominator +
      zero.numerator * value.denominator;
    denominator = value.denominator * zero.denominator
  } in
  assert (C.invariant raw);
  assert (C.equivalent result raw);
  assert (zero.numerator = 0);
  assert (raw.numerator = value.numerator * zero.denominator);
  assert (raw.denominator = value.denominator * zero.denominator);
  assert (
    raw.numerator * value.denominator =
    value.numerator * raw.denominator)
    by (FStar.Tactics.Canon.canon ());
  assert (C.equivalent raw value);
  P.equivalent_transitive result raw value

let add_zero_left
    (value:C.rational{C.invariant value})
  : Lemma
      (ensures
        C.equivalent (C.add (C.make 0 1) value) value)
=
  let zero = C.make 0 1 in
  P.make_zero_numerator ();
  let result = C.add zero value in
  let raw : C.rational = {
    numerator =
      zero.numerator * value.denominator +
      value.numerator * zero.denominator;
    denominator = zero.denominator * value.denominator
  } in
  assert (C.invariant raw);
  assert (C.equivalent result raw);
  assert (zero.numerator = 0);
  assert (raw.numerator = value.numerator * zero.denominator);
  assert (raw.denominator = zero.denominator * value.denominator);
  assert (
    raw.numerator * value.denominator =
    value.numerator * raw.denominator)
    by (FStar.Tactics.Canon.canon ());
  assert (C.equivalent raw value);
  P.equivalent_transitive result raw value

let multiply_one_right
    (value:C.rational{C.invariant value})
  : Lemma
      (ensures
        C.equivalent (C.multiply value (C.make 1 1)) value)
=
  let one = C.make 1 1 in
  make_one_numerator_equals_denominator ();
  let result = C.multiply value one in
  let raw : C.rational = {
    numerator = value.numerator * one.numerator;
    denominator = value.denominator * one.denominator
  } in
  let factor = value.numerator * value.denominator in
  assert (C.invariant raw);
  assert (C.equivalent result raw);
  assert (one.numerator = one.denominator);
  P.multiply_int_right_respects_equality
    one.numerator one.denominator factor;
  assert (
    raw.numerator * value.denominator =
    one.numerator * factor)
    by (FStar.Tactics.Canon.canon ());
  assert (
    value.numerator * raw.denominator =
    one.denominator * factor)
    by (FStar.Tactics.Canon.canon ());
  assert (
    raw.numerator * value.denominator =
    value.numerator * raw.denominator);
  assert (C.equivalent raw value);
  P.equivalent_transitive result raw value

let multiply_one_left
    (value:C.rational{C.invariant value})
  : Lemma
      (ensures
        C.equivalent (C.multiply (C.make 1 1) value) value)
=
  let one = C.make 1 1 in
  make_one_numerator_equals_denominator ();
  let result = C.multiply one value in
  let raw : C.rational = {
    numerator = one.numerator * value.numerator;
    denominator = one.denominator * value.denominator
  } in
  let factor = value.numerator * value.denominator in
  assert (C.invariant raw);
  assert (C.equivalent result raw);
  assert (one.numerator = one.denominator);
  P.multiply_int_right_respects_equality
    one.numerator one.denominator factor;
  assert (
    raw.numerator * value.denominator =
    one.numerator * factor)
    by (FStar.Tactics.Canon.canon ());
  assert (
    value.numerator * raw.denominator =
    one.denominator * factor)
    by (FStar.Tactics.Canon.canon ());
  assert (
    raw.numerator * value.denominator =
    value.numerator * raw.denominator);
  assert (C.equivalent raw value);
  P.equivalent_transitive result raw value

let horner_constant_sound
    (value:C.rational{C.invariant value})
    (point:C.rational{C.invariant point})
  : Lemma
      (ensures
        C.equivalent
          (C.polynomial_evaluate_horner [value] point)
          value)
=
  let zero = C.make 0 1 in
  let tail = C.polynomial_evaluate_horner [] point in
  assert (tail = zero);
  P.equivalent_reflexive zero;
  P.multiply_zero_right point tail;
  let scaled = C.multiply point tail in
  assert (C.equivalent scaled zero);
  P.equivalent_reflexive value;
  P.add_respects_equivalent value scaled value zero;
  let result = C.polynomial_evaluate_horner [value] point in
  assert (result = C.add value scaled);
  add_zero_right value;
  P.equivalent_transitive result (C.add value zero) value

let horner_variable_sound
    (point:C.rational{C.invariant point})
  : Lemma
      (ensures
        C.equivalent
          (C.polynomial_evaluate_horner
            [C.make 0 1; C.make 1 1] point)
          point)
=
  let zero = C.make 0 1 in
  let one = C.make 1 1 in
  let higher = C.polynomial_evaluate_horner [one] point in
  horner_constant_sound one point;
  assert (C.equivalent higher one);
  P.equivalent_reflexive point;
  P.multiply_respects_equivalent point higher point one;
  let scaled = C.multiply point higher in
  let scaled_one = C.multiply point one in
  assert (C.equivalent scaled scaled_one);
  multiply_one_right point;
  P.equivalent_transitive scaled scaled_one point;
  P.equivalent_reflexive zero;
  P.add_respects_equivalent zero scaled zero point;
  let result = C.polynomial_evaluate_horner [zero; one] point in
  assert (result = C.add zero scaled);
  add_zero_left point;
  P.equivalent_transitive result (C.add zero point) point
