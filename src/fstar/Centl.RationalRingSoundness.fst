module Centl.RationalRingSoundness

module C = Centl.Core
module P = Centl.PolynomialSoundness

(** Proof-only rational ring laws used by the Horner semantic bridge.  CENTL
    rationals are normalized records, so the laws are stated using the exact
    [equivalent] relation rather than record equality. *)

let add_commutative
    (left right:C.rational{C.invariant left /\ C.invariant right})
  : Lemma
      (ensures
        C.equivalent (C.add left right) (C.add right left))
=
  let left_result = C.add left right in
  let right_result = C.add right left in
  let raw_left : C.rational = {
    numerator =
      left.numerator * right.denominator +
      right.numerator * left.denominator;
    denominator = left.denominator * right.denominator
  } in
  let raw_right : C.rational = {
    numerator =
      right.numerator * left.denominator +
      left.numerator * right.denominator;
    denominator = right.denominator * left.denominator
  } in
  assert (C.invariant raw_left);
  assert (C.invariant raw_right);
  assert (C.equivalent left_result raw_left);
  assert (C.equivalent right_result raw_right);
  assert (raw_left.numerator = raw_right.numerator);
  FStar.Math.Lemmas.swap_mul left.denominator right.denominator;
  assert (raw_left.denominator = raw_right.denominator);
  assert (raw_left = raw_right);
  P.equivalent_reflexive raw_left;
  P.equivalent_transitive left_result raw_left raw_right;
  P.equivalent_symmetric right_result raw_right;
  P.equivalent_transitive left_result raw_right right_result

let multiply_commutative
    (left right:C.rational{C.invariant left /\ C.invariant right})
  : Lemma
      (ensures
        C.equivalent (C.multiply left right) (C.multiply right left))
=
  let left_result = C.multiply left right in
  let right_result = C.multiply right left in
  let raw_left : C.rational = {
    numerator = left.numerator * right.numerator;
    denominator = left.denominator * right.denominator
  } in
  let raw_right : C.rational = {
    numerator = right.numerator * left.numerator;
    denominator = right.denominator * left.denominator
  } in
  assert (C.invariant raw_left);
  assert (C.invariant raw_right);
  assert (C.equivalent left_result raw_left);
  assert (C.equivalent right_result raw_right);
  FStar.Math.Lemmas.swap_mul left.numerator right.numerator;
  FStar.Math.Lemmas.swap_mul left.denominator right.denominator;
  assert (raw_left.numerator = raw_right.numerator);
  assert (raw_left.denominator = raw_right.denominator);
  assert (raw_left = raw_right);
  P.equivalent_reflexive raw_left;
  P.equivalent_transitive left_result raw_left raw_right;
  P.equivalent_symmetric right_result raw_right;
  P.equivalent_transitive left_result raw_right right_result

let multiply_associative
    (first second third:C.rational{
      C.invariant first /\ C.invariant second /\ C.invariant third})
  : Lemma
      (ensures
        C.equivalent
          (C.multiply (C.multiply first second) third)
          (C.multiply first (C.multiply second third)))
=
  let first_second = C.multiply first second in
  let raw_first_second : C.rational = {
    numerator = first.numerator * second.numerator;
    denominator = first.denominator * second.denominator
  } in
  assert (C.invariant raw_first_second);
  assert (C.equivalent first_second raw_first_second);
  P.equivalent_reflexive third;
  P.multiply_respects_equivalent
    first_second third raw_first_second third;
  let left_result = C.multiply first_second third in
  let left_mid = C.multiply raw_first_second third in
  assert (C.equivalent left_result left_mid);
  let left_numerator =
    (first.numerator * second.numerator) * third.numerator in
  let left_denominator : value:pos{
      value =
        (first.denominator * second.denominator) * third.denominator} =
    (first.denominator * second.denominator) * third.denominator in
  let raw_left : value:C.rational{
      value.numerator = left_numerator /\
      value.denominator = left_denominator} = {
    numerator = left_numerator;
    denominator = left_denominator
  } in
  assert (C.invariant raw_left);
  assert (C.equivalent left_mid raw_left);
  P.equivalent_transitive left_result left_mid raw_left;

  let second_third = C.multiply second third in
  let raw_second_third : C.rational = {
    numerator = second.numerator * third.numerator;
    denominator = second.denominator * third.denominator
  } in
  assert (C.invariant raw_second_third);
  assert (C.equivalent second_third raw_second_third);
  P.equivalent_reflexive first;
  P.multiply_respects_equivalent
    first second_third first raw_second_third;
  let right_result = C.multiply first second_third in
  let right_mid = C.multiply first raw_second_third in
  assert (C.equivalent right_result right_mid);
  let right_numerator =
    first.numerator * (second.numerator * third.numerator) in
  let right_denominator : value:pos{
      value =
        first.denominator *
        (second.denominator * third.denominator)} =
    first.denominator *
    (second.denominator * third.denominator) in
  let raw_right : value:C.rational{
      value.numerator = right_numerator /\
      value.denominator = right_denominator} = {
    numerator = right_numerator;
    denominator = right_denominator
  } in
  assert (C.invariant raw_right);
  assert (C.equivalent right_mid raw_right);
  P.equivalent_transitive right_result right_mid raw_right;

  FStar.Math.Lemmas.paren_mul_left
    first.numerator second.numerator third.numerator;
  FStar.Math.Lemmas.paren_mul_right
    first.numerator second.numerator third.numerator;
  assert (
    (first.numerator * second.numerator) * third.numerator =
    first.numerator * (second.numerator * third.numerator));
  assert (left_numerator = right_numerator);
  FStar.Math.Lemmas.paren_mul_left
    first.denominator second.denominator third.denominator;
  FStar.Math.Lemmas.paren_mul_right
    first.denominator second.denominator third.denominator;
  assert (
    (first.denominator * second.denominator) * third.denominator =
    first.denominator * (second.denominator * third.denominator));
  assert (left_denominator = right_denominator);
  assert (raw_left.numerator = raw_right.numerator);
  assert (raw_left.denominator = raw_right.denominator);
  assert (C.equivalent raw_left raw_right);
  P.equivalent_symmetric right_result raw_right;
  P.equivalent_transitive left_result raw_left raw_right;
  P.equivalent_transitive left_result raw_right right_result

let add_associative
    (first second third:C.rational{
      C.invariant first /\ C.invariant second /\ C.invariant third})
  : Lemma
      (ensures
        C.equivalent
          (C.add (C.add first second) third)
          (C.add first (C.add second third)))
=
  let first_second = C.add first second in
  let first_term = first.numerator * second.denominator in
  let second_term = second.numerator * first.denominator in
  let raw_first_second : C.rational = {
    numerator = first_term + second_term;
    denominator = first.denominator * second.denominator
  } in
  assert (C.invariant raw_first_second);
  assert (C.equivalent first_second raw_first_second);
  P.equivalent_reflexive third;
  P.add_respects_equivalent
    first_second third raw_first_second third;
  let left_result = C.add first_second third in
  let left_mid = C.add raw_first_second third in
  assert (C.equivalent left_result left_mid);
  let raw_left : C.rational = {
    numerator =
      (first_term + second_term) * third.denominator +
      third.numerator * (first.denominator * second.denominator);
    denominator =
      (first.denominator * second.denominator) * third.denominator
  } in
  assert (C.invariant raw_left);
  assert (C.equivalent left_mid raw_left);
  P.equivalent_transitive left_result left_mid raw_left;

  let second_third = C.add second third in
  let second_right_term = second.numerator * third.denominator in
  let third_term = third.numerator * second.denominator in
  let raw_second_third : C.rational = {
    numerator = second_right_term + third_term;
    denominator = second.denominator * third.denominator
  } in
  assert (C.invariant raw_second_third);
  assert (C.equivalent second_third raw_second_third);
  P.equivalent_reflexive first;
  P.add_respects_equivalent
    first second_third first raw_second_third;
  let right_result = C.add first second_third in
  let right_mid = C.add first raw_second_third in
  assert (C.equivalent right_result right_mid);
  let raw_right : C.rational = {
    numerator =
      first.numerator * (second.denominator * third.denominator) +
      (second_right_term + third_term) * first.denominator;
    denominator =
      first.denominator * (second.denominator * third.denominator)
  } in
  assert (C.invariant raw_right);
  assert (C.equivalent right_mid raw_right);
  P.equivalent_transitive right_result right_mid raw_right;

  let term_first =
    (first.numerator * second.denominator) * third.denominator in
  let term_second =
    (second.numerator * first.denominator) * third.denominator in
  let term_third =
    third.numerator * (first.denominator * second.denominator) in

  FStar.Math.Lemmas.distributivity_add_left
    first_term second_term third.denominator;
  assert (raw_left.numerator = term_first + term_second + term_third);

  FStar.Math.Lemmas.distributivity_add_left
    second_right_term third_term first.denominator;
  FStar.Math.Lemmas.paren_mul_left
    second.numerator first.denominator third.denominator;
  FStar.Math.Lemmas.paren_mul_right
    second.numerator first.denominator third.denominator;
  FStar.Math.Lemmas.swap_mul first.denominator third.denominator;
  FStar.Math.Lemmas.paren_mul_left
    second.numerator third.denominator first.denominator;
  FStar.Math.Lemmas.paren_mul_right
    second.numerator third.denominator first.denominator;
  assert (
    term_second =
    (second.numerator * third.denominator) * first.denominator);
  FStar.Math.Lemmas.swap_mul first.denominator second.denominator;
  FStar.Math.Lemmas.paren_mul_right
    third.numerator first.denominator second.denominator;
  FStar.Math.Lemmas.paren_mul_left
    third.numerator second.denominator first.denominator;
  FStar.Math.Lemmas.paren_mul_right
    third.numerator second.denominator first.denominator;
  assert (
    term_third =
    (third.numerator * second.denominator) * first.denominator);
  assert (raw_right.numerator = term_first + term_second + term_third);
  FStar.Math.Lemmas.paren_mul_left
    first.denominator second.denominator third.denominator;
  FStar.Math.Lemmas.paren_mul_right
    first.denominator second.denominator third.denominator;
  assert (
    (first.denominator * second.denominator) * third.denominator =
    first.denominator * (second.denominator * third.denominator));
  assert (raw_left.denominator = raw_right.denominator);
  assert (raw_left.numerator = raw_right.numerator);
  assert (raw_left = raw_right);
  P.equivalent_reflexive raw_left;
  P.equivalent_symmetric right_result raw_right;
  P.equivalent_transitive left_result raw_left raw_right;
  P.equivalent_transitive left_result raw_right right_result
