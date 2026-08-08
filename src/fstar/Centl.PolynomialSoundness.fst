module Centl.PolynomialSoundness

open Centl.Core

#push-options "--z3rlimit 2 --split_queries always"

let equivalent_symmetric (left right:rational)
  : Lemma
      (requires equivalent left right)
      (ensures equivalent right left)
= ()

let equivalent_transitive
    (first:rational{invariant first})
    (second:rational{invariant second})
    (third:rational{invariant third})
  : Lemma
      (requires equivalent first second /\ equivalent second third)
      (ensures equivalent first third)
= assert (first.numerator * third.denominator =
    third.numerator * first.denominator)
    by (FStar.Tactics.Canon.canon ())

let equivalent_of_cross_products (left right:rational)
  : Lemma
      (requires
        left.numerator * right.denominator =
        right.numerator * left.denominator)
      (ensures equivalent left right)
= ()

let equivalent_via_raw
    (left:rational{invariant left})
    (left_raw:rational{invariant left_raw})
    (right_raw:rational{invariant right_raw})
    (right:rational{invariant right})
  : Lemma
      (requires
        equivalent left left_raw /\
        equivalent left_raw right_raw /\
        equivalent right right_raw)
      (ensures equivalent left right)
=
  equivalent_transitive left left_raw right_raw;
  equivalent_symmetric right right_raw;
  equivalent_transitive left right_raw right

let multiply_integer_equality (left right factor:int)
  : Lemma
      (requires left = right)
      (ensures left * factor = right * factor)
= ()

let add_integer_equalities (left left' right right':int)
  : Lemma
      (requires left = left' /\ right = right')
      (ensures left + right = left' + right')
= ()

let multiply_integer_equalities (left left' right right':int)
  : Lemma
      (requires left = left' /\ right = right')
      (ensures left * right = left' * right')
= ()

let subtract_integer_equalities (left left' right right':int)
  : Lemma
      (requires left = left' /\ right = right')
      (ensures left - right = left' - right')
= ()

let add_left_cross_equality
    (left left' right right':rational)
  : Lemma
      (requires equivalent left left')
      (ensures
        left.numerator * right.denominator *
          (left'.denominator * right'.denominator) =
        left'.numerator * right'.denominator *
          (left.denominator * right.denominator))
=
  calc (==) {
    left.numerator * right.denominator *
      (left'.denominator * right'.denominator);
    == { assert (
      left.numerator * right.denominator *
        (left'.denominator * right'.denominator) =
      (left.numerator * left'.denominator) *
        (right.denominator * right'.denominator))
      by (FStar.Tactics.Canon.canon ()) }
    (left.numerator * left'.denominator) *
      (right.denominator * right'.denominator);
    == { multiply_integer_equality
      (left.numerator * left'.denominator)
      (left'.numerator * left.denominator)
      (right.denominator * right'.denominator) }
    (left'.numerator * left.denominator) *
      (right.denominator * right'.denominator);
    == { assert (
      (left'.numerator * left.denominator) *
        (right.denominator * right'.denominator) =
      left'.numerator * right'.denominator *
        (left.denominator * right.denominator))
      by (FStar.Tactics.Canon.canon ()) }
    left'.numerator * right'.denominator *
      (left.denominator * right.denominator);
  }

let add_right_cross_equality
    (left left' right right':rational)
  : Lemma
      (requires equivalent right right')
      (ensures
        right.numerator * left.denominator *
          (left'.denominator * right'.denominator) =
        right'.numerator * left'.denominator *
          (left.denominator * right.denominator))
=
  calc (==) {
    right.numerator * left.denominator *
      (left'.denominator * right'.denominator);
    == { assert (
      right.numerator * left.denominator *
        (left'.denominator * right'.denominator) =
      (right.numerator * right'.denominator) *
        (left.denominator * left'.denominator))
      by (FStar.Tactics.Canon.canon ()) }
    (right.numerator * right'.denominator) *
      (left.denominator * left'.denominator);
    == { multiply_integer_equality
      (right.numerator * right'.denominator)
      (right'.numerator * right.denominator)
      (left.denominator * left'.denominator) }
    (right'.numerator * right.denominator) *
      (left.denominator * left'.denominator);
    == { assert (
      (right'.numerator * right.denominator) *
        (left.denominator * left'.denominator) =
      right'.numerator * left'.denominator *
        (left.denominator * right.denominator))
      by (FStar.Tactics.Canon.canon ()) }
    right'.numerator * left'.denominator *
      (left.denominator * right.denominator);
  }

let add_raw_cross_equality
    (left left' right right':rational)
  : Lemma
      (requires equivalent left left' /\ equivalent right right')
      (ensures
        (left.numerator * right.denominator +
          right.numerator * left.denominator) *
          (left'.denominator * right'.denominator) =
        (left'.numerator * right'.denominator +
          right'.numerator * left'.denominator) *
          (left.denominator * right.denominator))
=
  calc (==) {
    (left.numerator * right.denominator +
      right.numerator * left.denominator) *
      (left'.denominator * right'.denominator);
    == { assert (
      (left.numerator * right.denominator +
        right.numerator * left.denominator) *
        (left'.denominator * right'.denominator) =
      left.numerator * right.denominator *
          (left'.denominator * right'.denominator) +
        right.numerator * left.denominator *
          (left'.denominator * right'.denominator))
      by (FStar.Tactics.Canon.canon ()) }
    left.numerator * right.denominator *
        (left'.denominator * right'.denominator) +
      right.numerator * left.denominator *
        (left'.denominator * right'.denominator);
    == { add_left_cross_equality left left' right right';
      add_right_cross_equality left left' right right';
      add_integer_equalities
      (left.numerator * right.denominator *
        (left'.denominator * right'.denominator))
      (left'.numerator * right'.denominator *
        (left.denominator * right.denominator))
      (right.numerator * left.denominator *
        (left'.denominator * right'.denominator))
        (right'.numerator * left'.denominator *
        (left.denominator * right.denominator)) }
    left'.numerator * right'.denominator *
        (left.denominator * right.denominator) +
      right'.numerator * left'.denominator *
        (left.denominator * right.denominator);
    == { assert (
      left'.numerator * right'.denominator *
          (left.denominator * right.denominator) +
        right'.numerator * left'.denominator *
          (left.denominator * right.denominator) =
      (left'.numerator * right'.denominator +
        right'.numerator * left'.denominator) *
        (left.denominator * right.denominator))
      by (FStar.Tactics.Canon.canon ()) }
    (left'.numerator * right'.denominator +
      right'.numerator * left'.denominator) *
      (left.denominator * right.denominator);
  }

let subtract_raw_cross_equality
    (left left' right right':rational)
  : Lemma
      (requires equivalent left left' /\ equivalent right right')
      (ensures
        (left.numerator * right.denominator -
          right.numerator * left.denominator) *
          (left'.denominator * right'.denominator) =
        (left'.numerator * right'.denominator -
          right'.numerator * left'.denominator) *
          (left.denominator * right.denominator))
=
  calc (==) {
    (left.numerator * right.denominator -
      right.numerator * left.denominator) *
      (left'.denominator * right'.denominator);
    == { assert (
      (left.numerator * right.denominator -
        right.numerator * left.denominator) *
        (left'.denominator * right'.denominator) =
      left.numerator * right.denominator *
          (left'.denominator * right'.denominator) -
        right.numerator * left.denominator *
          (left'.denominator * right'.denominator))
      by (FStar.Tactics.Canon.canon ()) }
    left.numerator * right.denominator *
        (left'.denominator * right'.denominator) -
      right.numerator * left.denominator *
        (left'.denominator * right'.denominator);
    == { add_left_cross_equality left left' right right';
      add_right_cross_equality left left' right right';
      subtract_integer_equalities
        (left.numerator * right.denominator *
          (left'.denominator * right'.denominator))
        (left'.numerator * right'.denominator *
          (left.denominator * right.denominator))
        (right.numerator * left.denominator *
          (left'.denominator * right'.denominator))
        (right'.numerator * left'.denominator *
          (left.denominator * right.denominator)) }
    left'.numerator * right'.denominator *
        (left.denominator * right.denominator) -
      right'.numerator * left'.denominator *
        (left.denominator * right.denominator);
    == { assert (
      left'.numerator * right'.denominator *
          (left.denominator * right.denominator) -
        right'.numerator * left'.denominator *
          (left.denominator * right.denominator) =
      (left'.numerator * right'.denominator -
        right'.numerator * left'.denominator) *
        (left.denominator * right.denominator))
      by (FStar.Tactics.Canon.canon ()) }
    (left'.numerator * right'.denominator -
      right'.numerator * left'.denominator) *
      (left.denominator * right.denominator);
  }

let equivalent_add_congruence
    (left:rational{invariant left})
    (left':rational{invariant left'})
    (right:rational{invariant right})
    (right':rational{invariant right'})
  : Lemma
      (requires equivalent left left' /\ equivalent right right')
      (ensures equivalent (add left right) (add left' right'))
=
  let sum = add left right in
  let sum' = add left' right' in
  let raw : value:rational{invariant value} = {
    numerator = left.numerator * right.denominator +
      right.numerator * left.denominator;
    denominator = left.denominator * right.denominator
  } in
  let raw' : value:rational{invariant value} = {
    numerator = left'.numerator * right'.denominator +
      right'.numerator * left'.denominator;
    denominator = left'.denominator * right'.denominator
  } in
  assert (equivalent sum raw);
  assert (equivalent sum' raw');
  assert (left.numerator * left'.denominator =
    left'.numerator * left.denominator);
  assert (right.numerator * right'.denominator =
    right'.numerator * right.denominator);
  add_left_cross_equality left left' right right';
  add_right_cross_equality left left' right right';
  add_raw_cross_equality left left' right right';
  assert (equivalent raw raw');
  equivalent_transitive sum raw raw';
  equivalent_symmetric sum' raw';
  equivalent_transitive sum raw' sum'

let equivalent_multiply_congruence
    (left:rational{invariant left})
    (left':rational{invariant left'})
    (right:rational{invariant right})
    (right':rational{invariant right'})
  : Lemma
      (requires equivalent left left' /\ equivalent right right')
      (ensures equivalent (multiply left right) (multiply left' right'))
=
  let product = multiply left right in
  let product' = multiply left' right' in
  let raw : value:rational{invariant value} = {
    numerator = left.numerator * right.numerator;
    denominator = left.denominator * right.denominator
  } in
  let raw' : value:rational{invariant value} = {
    numerator = left'.numerator * right'.numerator;
    denominator = left'.denominator * right'.denominator
  } in
  assert (equivalent product raw);
  assert (equivalent product' raw');
  multiply_integer_equalities
    (left.numerator * left'.denominator)
    (left'.numerator * left.denominator)
    (right.numerator * right'.denominator)
    (right'.numerator * right.denominator);
  calc (==) {
    left.numerator * right.numerator *
      (left'.denominator * right'.denominator);
    == { assert (
      left.numerator * right.numerator *
        (left'.denominator * right'.denominator) =
      (left.numerator * left'.denominator) *
        (right.numerator * right'.denominator))
      by (FStar.Tactics.Canon.canon ()) }
    (left.numerator * left'.denominator) *
      (right.numerator * right'.denominator);
    == { multiply_integer_equalities
      (left.numerator * left'.denominator)
      (left'.numerator * left.denominator)
      (right.numerator * right'.denominator)
      (right'.numerator * right.denominator) }
    (left'.numerator * left.denominator) *
      (right'.numerator * right.denominator);
    == { assert (
      (left'.numerator * left.denominator) *
        (right'.numerator * right.denominator) =
      left'.numerator * right'.numerator *
        (left.denominator * right.denominator))
      by (FStar.Tactics.Canon.canon ()) }
    left'.numerator * right'.numerator *
      (left.denominator * right.denominator);
  };
  assert (equivalent raw raw');
  equivalent_transitive product raw raw';
  equivalent_symmetric product' raw';
  equivalent_transitive product raw' product'

let equivalent_negate_congruence
    (value:rational{invariant value})
    (value':rational{invariant value'})
  : Lemma
      (requires equivalent value value')
      (ensures equivalent (negate value) (negate value'))
=
  let negative = negate value in
  let negative' = negate value' in
  let raw : result:rational{invariant result} = {
    numerator = -value.numerator;
    denominator = value.denominator
  } in
  let raw' : result:rational{invariant result} = {
    numerator = -value'.numerator;
    denominator = value'.denominator
  } in
  assert (equivalent negative raw);
  assert (equivalent negative' raw');
  multiply_integer_equality
    (value.numerator * value'.denominator)
    (value'.numerator * value.denominator) (-1);
  calc (==) {
    (-value.numerator) * value'.denominator;
    == { assert ((-value.numerator) * value'.denominator =
      (value.numerator * value'.denominator) * (-1))
      by (FStar.Tactics.Canon.canon ()) }
    (value.numerator * value'.denominator) * (-1);
    == { multiply_integer_equality
      (value.numerator * value'.denominator)
      (value'.numerator * value.denominator) (-1) }
    (value'.numerator * value.denominator) * (-1);
    == { assert ((value'.numerator * value.denominator) * (-1) =
      (-value'.numerator) * value.denominator)
      by (FStar.Tactics.Canon.canon ()) }
    (-value'.numerator) * value.denominator;
  };
  assert (equivalent raw raw');
  equivalent_transitive negative raw raw';
  equivalent_symmetric negative' raw';
  equivalent_transitive negative raw' negative'

let equivalent_subtract_congruence
    (left:rational{invariant left})
    (left':rational{invariant left'})
    (right:rational{invariant right})
    (right':rational{invariant right'})
  : Lemma
      (requires equivalent left left' /\ equivalent right right')
      (ensures equivalent (subtract left right) (subtract left' right'))
=
  let difference = subtract left right in
  let difference' = subtract left' right' in
  let raw : value:rational{invariant value} = {
    numerator = left.numerator * right.denominator -
      right.numerator * left.denominator;
    denominator = left.denominator * right.denominator
  } in
  let raw' : value:rational{invariant value} = {
    numerator = left'.numerator * right'.denominator -
      right'.numerator * left'.denominator;
    denominator = left'.denominator * right'.denominator
  } in
  assert (equivalent difference raw);
  assert (equivalent difference' raw');
  subtract_raw_cross_equality left left' right right';
  assert (equivalent raw raw');
  equivalent_transitive difference raw raw';
  equivalent_symmetric difference' raw';
  equivalent_transitive difference raw' difference'

let raw_add
    (left:rational{invariant left})
    (right:rational{invariant right})
  : Tot (result:rational{invariant result})
= {
  numerator = left.numerator * right.denominator +
    right.numerator * left.denominator;
  denominator = left.denominator * right.denominator
}

let raw_multiply
    (left:rational{invariant left})
    (right:rational{invariant right})
  : Tot (result:rational{invariant result})
= {
  numerator = left.numerator * right.numerator;
  denominator = left.denominator * right.denominator
}

let add_equivalent_raw
    (left:rational{invariant left})
    (right:rational{invariant right})
  : Lemma (ensures equivalent (add left right) (raw_add left right))
= ()

let multiply_equivalent_raw
    (left:rational{invariant left})
    (right:rational{invariant right})
  : Lemma (ensures equivalent (multiply left right) (raw_multiply left right))
= ()

let equivalent_add_associative
    (first:rational{invariant first})
    (second:rational{invariant second})
    (third:rational{invariant third})
  : Lemma
      (ensures equivalent
        (add (add first second) third)
        (add first (add second third)))
=
  let first_second = add first second in
  let second_third = add second third in
  let raw_first_second : value:rational{invariant value} = {
    numerator = first.numerator * second.denominator +
      second.numerator * first.denominator;
    denominator = first.denominator * second.denominator
  } in
  let raw_second_third : value:rational{invariant value} = {
    numerator = second.numerator * third.denominator +
      third.numerator * second.denominator;
    denominator = second.denominator * third.denominator
  } in
  assert (invariant raw_first_second);
  assert (invariant raw_second_third);
  let left = add first_second third in
  let right = add first second_third in
  let left_raw_operation = add raw_first_second third in
  let right_raw_operation = add first raw_second_third in
  let left_raw : value:rational{invariant value} = {
    numerator =
      (first.numerator * second.denominator +
        second.numerator * first.denominator) * third.denominator +
      third.numerator * (first.denominator * second.denominator);
    denominator =
      (first.denominator * second.denominator) * third.denominator
  } in
  let right_raw : value:rational{invariant value} = {
    numerator =
      first.numerator * (second.denominator * third.denominator) +
      (second.numerator * third.denominator +
        third.numerator * second.denominator) * first.denominator;
    denominator =
      first.denominator * (second.denominator * third.denominator)
  } in
  add_equivalent_raw first second;
  add_equivalent_raw second third;
  equivalent_add_congruence first_second raw_first_second third third;
  equivalent_add_congruence first first second_third raw_second_third;
  add_equivalent_raw raw_first_second third;
  add_equivalent_raw first raw_second_third;
  assert (
    ((first.numerator * second.denominator +
        second.numerator * first.denominator) * third.denominator +
      third.numerator * (first.denominator * second.denominator)) *
      (first.denominator *
        (second.denominator * third.denominator)) =
    (first.numerator * (second.denominator * third.denominator) +
      (second.numerator * third.denominator +
        third.numerator * second.denominator) * first.denominator) *
      ((first.denominator * second.denominator) * third.denominator))
    by (FStar.Tactics.Canon.canon ());
  equivalent_of_cross_products left_raw right_raw;
  equivalent_transitive left left_raw_operation left_raw;
  equivalent_transitive left left_raw right_raw;
  equivalent_symmetric right right_raw_operation;
  equivalent_symmetric right_raw_operation right_raw;
  equivalent_transitive right_raw right_raw_operation right;
  equivalent_transitive left right_raw right

let equivalent_add_commutative
    (left:rational{invariant left})
    (right:rational{invariant right})
  : Lemma (ensures equivalent (add left right) (add right left))
=
  let sum = add left right in
  let reverse = add right left in
  let raw : value:rational{invariant value} = {
    numerator = left.numerator * right.denominator +
      right.numerator * left.denominator;
    denominator = left.denominator * right.denominator
  } in
  let raw_reverse : value:rational{invariant value} = {
    numerator = right.numerator * left.denominator +
      left.numerator * right.denominator;
    denominator = right.denominator * left.denominator
  } in
  add_equivalent_raw left right;
  add_equivalent_raw right left;
  assert (
    (left.numerator * right.denominator +
      right.numerator * left.denominator) *
      (right.denominator * left.denominator) =
    (right.numerator * left.denominator +
      left.numerator * right.denominator) *
      (left.denominator * right.denominator))
    by (FStar.Tactics.Canon.canon ());
  equivalent_of_cross_products raw raw_reverse;
  equivalent_transitive sum raw raw_reverse;
  equivalent_symmetric reverse raw_reverse;
  equivalent_transitive sum raw_reverse reverse

let equivalent_multiply_associative
    (first:rational{invariant first})
    (second:rational{invariant second})
    (third:rational{invariant third})
  : Lemma
      (ensures equivalent
        (multiply (multiply first second) third)
        (multiply first (multiply second third)))
=
  let first_second = multiply first second in
  let second_third = multiply second third in
  let raw_first_second : value:rational{invariant value} = {
    numerator = first.numerator * second.numerator;
    denominator = first.denominator * second.denominator
  } in
  let raw_second_third : value:rational{invariant value} = {
    numerator = second.numerator * third.numerator;
    denominator = second.denominator * third.denominator
  } in
  assert (invariant raw_first_second);
  assert (invariant raw_second_third);
  let left = multiply first_second third in
  let right = multiply first second_third in
  let left_raw_operation = multiply raw_first_second third in
  let right_raw_operation = multiply first raw_second_third in
  let left_raw : value:rational{invariant value} = {
    numerator =
      (first.numerator * second.numerator) * third.numerator;
    denominator =
      (first.denominator * second.denominator) * third.denominator
  } in
  let right_raw : value:rational{invariant value} = {
    numerator =
      first.numerator * (second.numerator * third.numerator);
    denominator =
      first.denominator * (second.denominator * third.denominator)
  } in
  multiply_equivalent_raw first second;
  multiply_equivalent_raw second third;
  equivalent_multiply_congruence first_second raw_first_second third third;
  equivalent_multiply_congruence first first second_third raw_second_third;
  multiply_equivalent_raw raw_first_second third;
  multiply_equivalent_raw first raw_second_third;
  assert (
    ((first.numerator * second.numerator) * third.numerator) *
      (first.denominator *
        (second.denominator * third.denominator)) =
    (first.numerator * (second.numerator * third.numerator)) *
      ((first.denominator * second.denominator) * third.denominator))
    by (FStar.Tactics.Canon.canon ());
  equivalent_of_cross_products left_raw right_raw;
  equivalent_transitive left left_raw_operation left_raw;
  equivalent_transitive left left_raw right_raw;
  equivalent_symmetric right right_raw_operation;
  equivalent_symmetric right_raw_operation right_raw;
  equivalent_transitive right_raw right_raw_operation right;
  equivalent_transitive left right_raw right

let equivalent_multiply_commutative
    (left:rational{invariant left})
    (right:rational{invariant right})
  : Lemma (ensures equivalent (multiply left right) (multiply right left))
=
  let product = multiply left right in
  let reverse = multiply right left in
  let raw : value:rational{invariant value} = {
    numerator = left.numerator * right.numerator;
    denominator = left.denominator * right.denominator
  } in
  let raw_reverse : value:rational{invariant value} = {
    numerator = right.numerator * left.numerator;
    denominator = right.denominator * left.denominator
  } in
  multiply_equivalent_raw left right;
  multiply_equivalent_raw right left;
  assert (
    (left.numerator * right.numerator) *
      (right.denominator * left.denominator) =
    (right.numerator * left.numerator) *
      (left.denominator * right.denominator))
    by (FStar.Tactics.Canon.canon ());
  equivalent_of_cross_products raw raw_reverse;
  equivalent_transitive product raw raw_reverse;
  equivalent_symmetric reverse raw_reverse;
  equivalent_transitive product raw_reverse reverse

let equivalent_add_zero_left (value:rational{invariant value})
  : Lemma (ensures equivalent (add (make 0 1) value) value)
=
  let zero = make 0 1 in
  let sum = add zero value in
  let raw : result:rational{invariant result} = {
    numerator = zero.numerator * value.denominator +
      value.numerator * zero.denominator;
    denominator = zero.denominator * value.denominator
  } in
  make_zero_numerator ();
  add_equivalent_raw zero value;
  assert (
    (zero.numerator * value.denominator +
      value.numerator * zero.denominator) * value.denominator =
    value.numerator * (zero.denominator * value.denominator))
    by (FStar.Tactics.Canon.canon ());
  equivalent_of_cross_products raw value;
  equivalent_transitive sum raw value

let equivalent_add_zero_right (value:rational{invariant value})
  : Lemma (ensures equivalent (add value (make 0 1)) value)
=
  equivalent_add_commutative value (make 0 1);
  equivalent_add_zero_left value;
  equivalent_transitive
    (add value (make 0 1)) (add (make 0 1) value) value

let equivalent_multiply_zero_left (value:rational{invariant value})
  : Lemma (ensures equivalent (multiply (make 0 1) value) (make 0 1))
= multiply_zero_right value (make 0 1);
   equivalent_multiply_commutative (make 0 1) value;
   equivalent_transitive
     (multiply (make 0 1) value) (multiply value (make 0 1)) (make 0 1)

let make_one_equivalent_raw ()
  : Lemma (ensures equivalent (make 1 1) { numerator = 1; denominator = 1 })
= ()

let equivalent_multiply_one_left (value:rational{invariant value})
  : Lemma (ensures equivalent (multiply (make 1 1) value) value)
=
  let one = make 1 1 in
  let raw_one : result:rational{invariant result} = {
    numerator = 1;
    denominator = 1
  } in
  let product = multiply one value in
  let raw_product = raw_multiply raw_one value in
  make_one_equivalent_raw ();
  equivalent_multiply_congruence one raw_one value value;
  multiply_equivalent_raw raw_one value;
  assert (equivalent raw_product value)
    by (FStar.Tactics.Canon.canon ());
  equivalent_transitive product raw_product value

let equivalent_multiply_one_right (value:rational{invariant value})
  : Lemma (ensures equivalent (multiply value (make 1 1)) value)
=
  equivalent_multiply_commutative value (make 1 1);
  equivalent_multiply_one_left value;
  equivalent_transitive
    (multiply value (make 1 1)) (multiply (make 1 1) value) value

let equivalent_multiply_distributes_over_add
    (factor:rational{invariant factor})
    (left:rational{invariant left})
    (right:rational{invariant right})
  : Lemma
      (ensures equivalent
        (multiply factor (add left right))
        (add (multiply factor left) (multiply factor right)))
=
  let sum = add left right in
  let raw_sum : value:rational{invariant value} = {
    numerator = left.numerator * right.denominator +
      right.numerator * left.denominator;
    denominator = left.denominator * right.denominator
  } in
  let factor_left = multiply factor left in
  let factor_right = multiply factor right in
  let raw_factor_left : value:rational{invariant value} = {
    numerator = factor.numerator * left.numerator;
    denominator = factor.denominator * left.denominator
  } in
  let raw_factor_right : value:rational{invariant value} = {
    numerator = factor.numerator * right.numerator;
    denominator = factor.denominator * right.denominator
  } in
  let distributed = multiply factor sum in
  let collected = add factor_left factor_right in
  let distributed_raw_operation = multiply factor raw_sum in
  let collected_raw_operation = add raw_factor_left raw_factor_right in
  let distributed_raw : value:rational{invariant value} = {
    numerator = factor.numerator *
      (left.numerator * right.denominator +
        right.numerator * left.denominator);
    denominator = factor.denominator *
      (left.denominator * right.denominator)
  } in
  let collected_raw : value:rational{invariant value} = {
    numerator =
      (factor.numerator * left.numerator) *
          (factor.denominator * right.denominator) +
        (factor.numerator * right.numerator) *
          (factor.denominator * left.denominator);
    denominator =
      (factor.denominator * left.denominator) *
        (factor.denominator * right.denominator)
  } in
  add_equivalent_raw left right;
  multiply_equivalent_raw factor left;
  multiply_equivalent_raw factor right;
  equivalent_multiply_congruence factor factor sum raw_sum;
  equivalent_add_congruence factor_left raw_factor_left
    factor_right raw_factor_right;
  multiply_equivalent_raw factor raw_sum;
  add_equivalent_raw raw_factor_left raw_factor_right;
  assert (
    (factor.numerator *
      (left.numerator * right.denominator +
        right.numerator * left.denominator)) *
      ((factor.denominator * left.denominator) *
        (factor.denominator * right.denominator)) =
    ((factor.numerator * left.numerator) *
        (factor.denominator * right.denominator) +
      (factor.numerator * right.numerator) *
        (factor.denominator * left.denominator)) *
      (factor.denominator *
        (left.denominator * right.denominator)))
    by (FStar.Tactics.Canon.canon ());
  equivalent_of_cross_products distributed_raw collected_raw;
  equivalent_transitive distributed distributed_raw_operation distributed_raw;
  equivalent_transitive distributed distributed_raw collected_raw;
  equivalent_symmetric collected collected_raw_operation;
  equivalent_symmetric collected_raw_operation collected_raw;
  equivalent_transitive collected_raw collected_raw_operation collected;
  equivalent_transitive distributed collected_raw collected

let equivalent_add_four_exchange
    (first:rational{invariant first})
    (second:rational{invariant second})
    (third:rational{invariant third})
    (fourth:rational{invariant fourth})
  : Lemma
      (ensures equivalent
        (add (add first second) (add third fourth))
        (add (add first third) (add second fourth)))
=
  let third_fourth = add third fourth in
  let second_third = add second third in
  let third_second = add third second in
  let second_third_fourth = add second_third fourth in
  let third_second_fourth = add third_second fourth in
  let second_nested = add second third_fourth in
  let third_nested = add third (add second fourth) in
  let first_second_nested = add first second_nested in
  let first_second_third_fourth = add first second_third_fourth in
  let first_third_second_fourth = add first third_second_fourth in
  let first_third_nested = add first third_nested in
  let source = add (add first second) third_fourth in
  let target = add (add first third) (add second fourth) in
  equivalent_add_associative first second third_fourth;
  equivalent_add_associative second third fourth;
  equivalent_symmetric second_nested second_third_fourth;
  equivalent_add_commutative second third;
  equivalent_add_congruence second_third third_second fourth fourth;
  equivalent_add_associative third second fourth;
  equivalent_add_congruence first first second_nested second_third_fourth;
  equivalent_add_congruence first first second_third_fourth
    third_second_fourth;
  equivalent_add_congruence first first third_second_fourth third_nested;
  equivalent_add_associative first third (add second fourth);
  equivalent_symmetric target first_third_nested;
  equivalent_transitive source first_second_nested first_second_third_fourth;
  equivalent_transitive source first_second_third_fourth
    first_third_second_fourth;
  equivalent_transitive source first_third_second_fourth first_third_nested;
  equivalent_transitive source first_third_nested target

let equivalent_multiply_exchange
    (first:rational{invariant first})
    (second:rational{invariant second})
    (third:rational{invariant third})
  : Lemma
      (ensures equivalent
        (multiply first (multiply second third))
        (multiply second (multiply first third)))
=
  let first_second = multiply first second in
  let second_first = multiply second first in
  let source = multiply first (multiply second third) in
  let first_shape = multiply first_second third in
  let second_shape = multiply second_first third in
  let target = multiply second (multiply first third) in
  equivalent_multiply_associative first second third;
  equivalent_symmetric source first_shape;
  equivalent_multiply_commutative first second;
  equivalent_multiply_congruence first_second second_first third third;
  equivalent_multiply_associative second first third;
  equivalent_transitive source first_shape second_shape;
  equivalent_transitive source second_shape target

let equivalent_negate_as_minus_one (value:rational{invariant value})
  : Lemma
      (ensures equivalent
        (negate value) (multiply (make (-1) 1) value))
=
  let negative_one = make (-1) 1 in
  let raw_negative_one : result:rational{invariant result} = {
    numerator = -1;
    denominator = 1
  } in
  let negative = negate value in
  let product = multiply negative_one value in
  let raw_negative : result:rational{invariant result} = {
    numerator = -value.numerator;
    denominator = value.denominator
  } in
  let raw_product : result:rational{invariant result} = {
    numerator = (-1) * value.numerator;
    denominator = 1 * value.denominator
  } in
  assert (equivalent negative_one raw_negative_one);
  equivalent_multiply_congruence negative_one raw_negative_one value value;
  multiply_equivalent_raw raw_negative_one value;
  assert (equivalent negative raw_negative);
  assert (equivalent raw_negative raw_product)
    by (FStar.Tactics.Canon.canon ());
  equivalent_transitive negative raw_negative raw_product;
  equivalent_symmetric product raw_product;
  equivalent_transitive negative raw_product product

let equivalent_negate_add
    (left:rational{invariant left})
    (right:rational{invariant right})
  : Lemma
      (ensures equivalent
        (negate (add left right))
        (add (negate left) (negate right)))
=
  let negative_one = make (-1) 1 in
  let sum = add left right in
  let negative_sum = negate sum in
  let scaled_sum = multiply negative_one sum in
  let scaled_left = multiply negative_one left in
  let scaled_right = multiply negative_one right in
  let distributed = add scaled_left scaled_right in
  let target = add (negate left) (negate right) in
  equivalent_negate_as_minus_one sum;
  equivalent_multiply_distributes_over_add negative_one left right;
  equivalent_negate_as_minus_one left;
  equivalent_negate_as_minus_one right;
  equivalent_add_congruence (negate left) scaled_left
    (negate right) scaled_right;
  equivalent_symmetric target distributed;
  equivalent_transitive negative_sum scaled_sum distributed;
  equivalent_transitive negative_sum distributed target

let equivalent_multiply_negate_right
    (factor:rational{invariant factor})
    (value:rational{invariant value})
  : Lemma
      (ensures equivalent
        (multiply factor (negate value))
        (negate (multiply factor value)))
=
  let negative_one = make (-1) 1 in
  let negative_value = negate value in
  let scaled_value = multiply negative_one value in
  let source = multiply factor negative_value in
  let source_scaled = multiply factor scaled_value in
  let exchanged = multiply negative_one (multiply factor value) in
  let target = negate (multiply factor value) in
  equivalent_negate_as_minus_one value;
  equivalent_multiply_congruence factor factor negative_value scaled_value;
  equivalent_multiply_exchange factor negative_one value;
  equivalent_negate_as_minus_one (multiply factor value);
  equivalent_symmetric target exchanged;
  equivalent_transitive source source_scaled exchanged;
  equivalent_transitive source exchanged target

let equivalent_negate_zero ()
  : Lemma (ensures equivalent (negate (make 0 1)) (make 0 1))
=
  let zero = make 0 1 in
  let negative_one = make (-1) 1 in
  equivalent_negate_as_minus_one zero;
  multiply_zero_right negative_one zero;
  equivalent_transitive (negate zero) (multiply negative_one zero) zero

let rec polynomial_add_horner_sound
    (left right:polynomial)
    (point:coefficient)
  : Lemma
      (ensures equivalent
        (polynomial_evaluate_horner (polynomial_add left right) point)
        (add
          (polynomial_evaluate_horner left point)
          (polynomial_evaluate_horner right point)))
      (decreases left)
=
  match left, right with
  | [], _ ->
      equivalent_add_zero_left (polynomial_evaluate_horner right point);
      equivalent_symmetric
        (add (make 0 1) (polynomial_evaluate_horner right point))
        (polynomial_evaluate_horner right point)
  | _, [] ->
      equivalent_add_zero_right (polynomial_evaluate_horner left point);
      equivalent_symmetric
        (add (polynomial_evaluate_horner left point) (make 0 1))
        (polynomial_evaluate_horner left point)
  | left_head :: left_tail, right_head :: right_tail ->
      polynomial_add_horner_sound left_tail right_tail point;
      let left_tail_value = polynomial_evaluate_horner left_tail point in
      let right_tail_value = polynomial_evaluate_horner right_tail point in
      let combined_tail = polynomial_evaluate_horner
        (polynomial_add left_tail right_tail) point in
      let tail_sum = add left_tail_value right_tail_value in
      let source = add (add left_head right_head)
        (multiply point combined_tail) in
      let source_tail_sum = add (add left_head right_head)
        (multiply point tail_sum) in
      let distributed = add (add left_head right_head)
        (add
          (multiply point left_tail_value)
          (multiply point right_tail_value)) in
      let target = add
        (add left_head (multiply point left_tail_value))
        (add right_head (multiply point right_tail_value)) in
      equivalent_multiply_congruence point point combined_tail tail_sum;
      equivalent_add_congruence (add left_head right_head)
        (add left_head right_head)
        (multiply point combined_tail) (multiply point tail_sum);
      equivalent_multiply_distributes_over_add point
        left_tail_value right_tail_value;
      equivalent_add_congruence (add left_head right_head)
        (add left_head right_head)
        (multiply point tail_sum)
        (add (multiply point left_tail_value)
          (multiply point right_tail_value));
      equivalent_add_four_exchange left_head right_head
        (multiply point left_tail_value)
        (multiply point right_tail_value);
      equivalent_transitive source source_tail_sum distributed;
      equivalent_transitive source distributed target

let rec polynomial_scale_horner_sound
    (factor:coefficient)
    (value:polynomial)
    (point:coefficient)
  : Lemma
      (ensures equivalent
        (polynomial_evaluate_horner (polynomial_scale factor value) point)
        (multiply factor (polynomial_evaluate_horner value point)))
      (decreases value)
=
  match value with
  | [] ->
      multiply_zero_right factor (make 0 1);
      equivalent_symmetric
        (multiply factor (make 0 1)) (make 0 1)
  | head :: tail ->
      polynomial_scale_horner_sound factor tail point;
      let tail_value = polynomial_evaluate_horner tail point in
      let scaled_tail = polynomial_evaluate_horner
        (polynomial_scale factor tail) point in
      let source = add (multiply factor head)
        (multiply point scaled_tail) in
      let recursive = add (multiply factor head)
        (multiply point (multiply factor tail_value)) in
      let exchanged = add (multiply factor head)
        (multiply factor (multiply point tail_value)) in
      let target = multiply factor
        (add head (multiply point tail_value)) in
      equivalent_multiply_congruence point point scaled_tail
        (multiply factor tail_value);
      equivalent_add_congruence (multiply factor head)
        (multiply factor head)
        (multiply point scaled_tail)
        (multiply point (multiply factor tail_value));
      equivalent_multiply_exchange point factor tail_value;
      equivalent_add_congruence (multiply factor head)
        (multiply factor head)
        (multiply point (multiply factor tail_value))
        (multiply factor (multiply point tail_value));
      equivalent_multiply_distributes_over_add factor head
        (multiply point tail_value);
      equivalent_symmetric target exchanged;
      equivalent_transitive source recursive exchanged;
      equivalent_transitive source exchanged target

let rec polynomial_negate_horner_sound
    (value:polynomial)
    (point:coefficient)
  : Lemma
      (ensures equivalent
        (polynomial_evaluate_horner (polynomial_negate value) point)
        (negate (polynomial_evaluate_horner value point)))
      (decreases value)
=
  match value with
  | [] ->
      equivalent_negate_zero ();
      equivalent_symmetric (negate (make 0 1)) (make 0 1)
  | head :: tail ->
      polynomial_negate_horner_sound tail point;
      let tail_value = polynomial_evaluate_horner tail point in
      let negated_tail = polynomial_evaluate_horner
        (polynomial_negate tail) point in
      let source = add (negate head) (multiply point negated_tail) in
      let recursive = add (negate head)
        (multiply point (negate tail_value)) in
      let pushed = add (negate head)
        (negate (multiply point tail_value)) in
      let target = negate (add head (multiply point tail_value)) in
      equivalent_multiply_congruence point point negated_tail
        (negate tail_value);
      equivalent_add_congruence (negate head) (negate head)
        (multiply point negated_tail)
        (multiply point (negate tail_value));
      equivalent_multiply_negate_right point tail_value;
      equivalent_add_congruence (negate head) (negate head)
        (multiply point (negate tail_value))
        (negate (multiply point tail_value));
      equivalent_negate_add head (multiply point tail_value);
      equivalent_symmetric target pushed;
      equivalent_transitive source recursive pushed;
      equivalent_transitive source pushed target

let equivalent_add_distributes_over_multiply_right
    (left:rational{invariant left})
    (right:rational{invariant right})
    (factor:rational{invariant factor})
  : Lemma
      (ensures equivalent
        (multiply (add left right) factor)
        (add (multiply left factor) (multiply right factor)))
=
  let sum = add left right in
  let source = multiply sum factor in
  let commuted = multiply factor sum in
  let distributed = add (multiply factor left) (multiply factor right) in
  let target = add (multiply left factor) (multiply right factor) in
  equivalent_multiply_commutative sum factor;
  equivalent_multiply_distributes_over_add factor left right;
  equivalent_multiply_commutative factor left;
  equivalent_multiply_commutative factor right;
  equivalent_add_congruence (multiply factor left) (multiply left factor)
    (multiply factor right) (multiply right factor);
  equivalent_transitive source commuted distributed;
  equivalent_transitive source distributed target

let polynomial_shift_horner_sound
    (value:polynomial)
    (point:coefficient)
  : Lemma
      (ensures equivalent
        (polynomial_evaluate_horner ((make 0 1) :: value) point)
        (multiply point (polynomial_evaluate_horner value point)))
= equivalent_add_zero_left
     (multiply point (polynomial_evaluate_horner value point))

let rec polynomial_multiply_horner_sound
    (left right:polynomial)
    (point:coefficient)
  : Lemma
      (ensures equivalent
        (polynomial_evaluate_horner (polynomial_multiply left right) point)
        (multiply
          (polynomial_evaluate_horner left point)
          (polynomial_evaluate_horner right point)))
      (decreases left)
=
  match left with
  | [] ->
      equivalent_multiply_zero_left
        (polynomial_evaluate_horner right point);
      equivalent_symmetric
        (multiply (make 0 1) (polynomial_evaluate_horner right point))
        (make 0 1)
  | head :: tail ->
      polynomial_multiply_horner_sound tail right point;
      polynomial_scale_horner_sound head right point;
      polynomial_shift_horner_sound
        (polynomial_multiply tail right) point;
      polynomial_add_horner_sound
        (polynomial_scale head right)
        ((make 0 1) :: polynomial_multiply tail right) point;
      let right_value = polynomial_evaluate_horner right point in
      let tail_value = polynomial_evaluate_horner tail point in
      let scaled = polynomial_evaluate_horner
        (polynomial_scale head right) point in
      let tail_product = polynomial_evaluate_horner
        (polynomial_multiply tail right) point in
      let shifted = polynomial_evaluate_horner
        ((make 0 1) :: polynomial_multiply tail right) point in
      let source = polynomial_evaluate_horner
        (polynomial_multiply (head :: tail) right) point in
      let separated = add scaled shifted in
      let coefficients = add (multiply head right_value)
        (multiply point tail_product) in
      let recursive = add (multiply head right_value)
        (multiply point (multiply tail_value right_value)) in
      let associated = add (multiply head right_value)
        (multiply (multiply point tail_value) right_value) in
      let target = multiply
        (add head (multiply point tail_value)) right_value in
      equivalent_add_congruence scaled (multiply head right_value)
        shifted (multiply point tail_product);
      equivalent_multiply_congruence point point tail_product
        (multiply tail_value right_value);
      equivalent_add_congruence (multiply head right_value)
        (multiply head right_value)
        (multiply point tail_product)
        (multiply point (multiply tail_value right_value));
      equivalent_multiply_associative point tail_value right_value;
      equivalent_symmetric
        (multiply (multiply point tail_value) right_value)
        (multiply point (multiply tail_value right_value));
      equivalent_add_congruence (multiply head right_value)
        (multiply head right_value)
        (multiply point (multiply tail_value right_value))
        (multiply (multiply point tail_value) right_value);
      equivalent_add_distributes_over_multiply_right head
        (multiply point tail_value) right_value;
      equivalent_symmetric target associated;
      equivalent_transitive source separated coefficients;
      equivalent_transitive source coefficients recursive;
      equivalent_transitive source recursive associated;
      equivalent_transitive source associated target

let rec polynomial_power_horner_sound
    (base:polynomial)
    (exponent:nat)
    (point:coefficient)
  : Lemma
      (ensures equivalent
        (polynomial_evaluate_horner (polynomial_power base exponent) point)
        (rational_power_product
          (polynomial_evaluate_horner base point) exponent))
      (decreases exponent)
=
  if exponent = 0 then
    let one = make 1 1 in
    let source = add one (multiply point (make 0 1)) in
    multiply_zero_right point (make 0 1);
    equivalent_add_congruence one one
      (multiply point (make 0 1)) (make 0 1);
    equivalent_add_zero_right one;
    equivalent_transitive source (add one (make 0 1)) one
  else
    begin
    assert (exponent > 0);
    let previous_integer = exponent - 1 in
    assert (previous_integer >= 0);
    let previous : nat = previous_integer in
    assert (exponent = previous + 1);
    assert (polynomial_power base exponent =
      polynomial_multiply base (polynomial_power base previous));
    assert (rational_power_product
      (polynomial_evaluate_horner base point) exponent =
      multiply (polynomial_evaluate_horner base point)
        (rational_power_product
          (polynomial_evaluate_horner base point) previous));
    polynomial_power_horner_sound base previous point;
    polynomial_multiply_horner_sound base
      (polynomial_power base previous) point;
    let source = polynomial_evaluate_horner
      (polynomial_power base exponent) point in
    let multiplied = multiply
      (polynomial_evaluate_horner base point)
      (polynomial_evaluate_horner
        (polynomial_power base previous) point) in
    let target = rational_power_product
      (polynomial_evaluate_horner base point) exponent in
    equivalent_multiply_congruence
      (polynomial_evaluate_horner base point)
      (polynomial_evaluate_horner base point)
      (polynomial_evaluate_horner
        (polynomial_power base previous) point)
      (rational_power_product
        (polynomial_evaluate_horner base point) previous);
    equivalent_transitive source multiplied target
    end

let equivalent_subtract_as_add_negate
    (left:rational{invariant left})
    (right:rational{invariant right})
  : Lemma
      (ensures equivalent
        (subtract left right) (add left (negate right)))
=
  let negative = negate right in
  let raw_negative : value:rational{invariant value} = {
    numerator = -right.numerator;
    denominator = right.denominator
  } in
  let difference = subtract left right in
  let sum = add left negative in
  let raw_difference : value:rational{invariant value} = {
    numerator = left.numerator * right.denominator -
      right.numerator * left.denominator;
    denominator = left.denominator * right.denominator
  } in
  let raw_sum : value:rational{invariant value} = {
    numerator = left.numerator * right.denominator +
      (-right.numerator) * left.denominator;
    denominator = left.denominator * right.denominator
  } in
  assert (equivalent negative raw_negative);
  assert (equivalent difference raw_difference);
  equivalent_add_congruence left left negative raw_negative;
  add_equivalent_raw left raw_negative;
  assert (equivalent raw_difference raw_sum)
    by (FStar.Tactics.Canon.canon ());
  equivalent_transitive difference raw_difference raw_sum;
  equivalent_symmetric sum (add left raw_negative);
  equivalent_symmetric (add left raw_negative) raw_sum;
  equivalent_transitive raw_sum (add left raw_negative) sum;
  equivalent_transitive difference raw_sum sum

let variable_polynomial_horner_sound (point:coefficient)
  : Lemma
      (ensures equivalent
        (polynomial_evaluate_horner [make 0 1; make 1 1] point)
        point)
=
  let zero = make 0 1 in
  let one = make 1 1 in
  let inner = add one (multiply point zero) in
  let multiplied = multiply point inner in
  let source = add zero multiplied in
  multiply_zero_right point zero;
  equivalent_add_congruence one one (multiply point zero) zero;
  equivalent_add_zero_right one;
  equivalent_transitive inner (add one zero) one;
  equivalent_multiply_congruence point point inner one;
  equivalent_multiply_one_right point;
  equivalent_transitive multiplied (multiply point one) point;
  equivalent_add_congruence zero zero multiplied point;
  equivalent_add_zero_left point;
  equivalent_transitive source (add zero point) point

let rec rational_power_product_congruence
    (base:rational{invariant base})
    (base':rational{invariant base'})
    (exponent:nat)
  : Lemma
      (requires equivalent base base')
      (ensures equivalent
        (rational_power_product base exponent)
        (rational_power_product base' exponent))
      (decreases exponent)
=
  if exponent > 0 then
    begin
    let previous_integer = exponent - 1 in
    assert (previous_integer >= 0);
    let previous : nat = previous_integer in
    assert (exponent = previous + 1);
    rational_power_product_congruence base base' previous;
    equivalent_multiply_congruence base base'
      (rational_power_product base previous)
      (rational_power_product base' previous)
    end
  else assert (exponent = 0)

let rec rational_polynomial_model_collection_sound
    (term:rational_polynomial_model)
    (point:coefficient)
  : Lemma
      (ensures equivalent
        (polynomial_evaluate_horner
          (collect_rational_polynomial_model term) point)
        (rational_polynomial_model_value term point))
      (decreases term)
=
  match term with
  | RZConstant value ->
      let source = add value (multiply point (make 0 1)) in
      multiply_zero_right point (make 0 1);
      equivalent_add_congruence value value
        (multiply point (make 0 1)) (make 0 1);
      equivalent_add_zero_right value;
      equivalent_transitive source (add value (make 0 1)) value
  | RZVariable -> variable_polynomial_horner_sound point
  | RZNegate inner ->
      rational_polynomial_model_collection_sound inner point;
      polynomial_negate_horner_sound
        (collect_rational_polynomial_model inner) point;
      equivalent_negate_congruence
        (polynomial_evaluate_horner
          (collect_rational_polynomial_model inner) point)
        (rational_polynomial_model_value inner point);
      equivalent_transitive
        (polynomial_evaluate_horner
          (polynomial_negate
            (collect_rational_polynomial_model inner)) point)
        (negate
          (polynomial_evaluate_horner
            (collect_rational_polynomial_model inner) point))
        (negate (rational_polynomial_model_value inner point))
  | RZAdd left right ->
      rational_polynomial_model_collection_sound left point;
      rational_polynomial_model_collection_sound right point;
      polynomial_add_horner_sound
        (collect_rational_polynomial_model left)
        (collect_rational_polynomial_model right) point;
      equivalent_add_congruence
        (polynomial_evaluate_horner
          (collect_rational_polynomial_model left) point)
        (rational_polynomial_model_value left point)
        (polynomial_evaluate_horner
          (collect_rational_polynomial_model right) point)
        (rational_polynomial_model_value right point);
      equivalent_transitive
        (polynomial_evaluate_horner
          (polynomial_add
            (collect_rational_polynomial_model left)
            (collect_rational_polynomial_model right)) point)
        (add
          (polynomial_evaluate_horner
            (collect_rational_polynomial_model left) point)
          (polynomial_evaluate_horner
            (collect_rational_polynomial_model right) point))
        (add
          (rational_polynomial_model_value left point)
          (rational_polynomial_model_value right point))
  | RZSubtract left right ->
      rational_polynomial_model_collection_sound left point;
      rational_polynomial_model_collection_sound right point;
      polynomial_negate_horner_sound
        (collect_rational_polynomial_model right) point;
      polynomial_add_horner_sound
        (collect_rational_polynomial_model left)
        (polynomial_negate
          (collect_rational_polynomial_model right)) point;
      let left_collected = polynomial_evaluate_horner
        (collect_rational_polynomial_model left) point in
      let right_collected = polynomial_evaluate_horner
        (collect_rational_polynomial_model right) point in
      let negated_collected = polynomial_evaluate_horner
        (polynomial_negate
          (collect_rational_polynomial_model right)) point in
      let separated = add left_collected negated_collected in
      let model_add = add
        (rational_polynomial_model_value left point)
        (negate (rational_polynomial_model_value right point)) in
      let target = subtract
        (rational_polynomial_model_value left point)
        (rational_polynomial_model_value right point) in
      equivalent_negate_congruence right_collected
        (rational_polynomial_model_value right point);
      equivalent_transitive negated_collected
        (negate right_collected)
        (negate (rational_polynomial_model_value right point));
      equivalent_add_congruence left_collected
        (rational_polynomial_model_value left point)
        negated_collected
        (negate (rational_polynomial_model_value right point));
      equivalent_subtract_as_add_negate
        (rational_polynomial_model_value left point)
        (rational_polynomial_model_value right point);
      equivalent_symmetric target model_add;
      equivalent_transitive
        (polynomial_evaluate_horner
          (polynomial_subtract
            (collect_rational_polynomial_model left)
            (collect_rational_polynomial_model right)) point)
        separated model_add;
      equivalent_transitive
        (polynomial_evaluate_horner
          (polynomial_subtract
            (collect_rational_polynomial_model left)
            (collect_rational_polynomial_model right)) point)
        model_add target
  | RZMultiply left right ->
      rational_polynomial_model_collection_sound left point;
      rational_polynomial_model_collection_sound right point;
      polynomial_multiply_horner_sound
        (collect_rational_polynomial_model left)
        (collect_rational_polynomial_model right) point;
      equivalent_multiply_congruence
        (polynomial_evaluate_horner
          (collect_rational_polynomial_model left) point)
        (rational_polynomial_model_value left point)
        (polynomial_evaluate_horner
          (collect_rational_polynomial_model right) point)
        (rational_polynomial_model_value right point);
      equivalent_transitive
        (polynomial_evaluate_horner
          (polynomial_multiply
            (collect_rational_polynomial_model left)
            (collect_rational_polynomial_model right)) point)
        (multiply
          (polynomial_evaluate_horner
            (collect_rational_polynomial_model left) point)
          (polynomial_evaluate_horner
            (collect_rational_polynomial_model right) point))
        (multiply
          (rational_polynomial_model_value left point)
          (rational_polynomial_model_value right point))
  | RZScale factor inner ->
      rational_polynomial_model_collection_sound inner point;
      polynomial_scale_horner_sound factor
        (collect_rational_polynomial_model inner) point;
      equivalent_multiply_congruence factor factor
        (polynomial_evaluate_horner
          (collect_rational_polynomial_model inner) point)
        (rational_polynomial_model_value inner point);
      equivalent_transitive
        (polynomial_evaluate_horner
          (polynomial_scale factor
            (collect_rational_polynomial_model inner)) point)
        (multiply factor
          (polynomial_evaluate_horner
            (collect_rational_polynomial_model inner) point))
        (multiply factor (rational_polynomial_model_value inner point))
  | RZPower base exponent ->
      rational_polynomial_model_collection_sound base point;
      polynomial_power_horner_sound
        (collect_rational_polynomial_model base) exponent point;
      let collected = polynomial_evaluate_horner
        (collect_rational_polynomial_model base) point in
      let modeled = rational_polynomial_model_value base point in
      rational_power_product_congruence collected modeled exponent;
      equivalent_transitive
        (polynomial_evaluate_horner
          (polynomial_power
            (collect_rational_polynomial_model base) exponent) point)
        (rational_power_product collected exponent)
        (rational_power_product modeled exponent)

(** F* admission parser for the surface fragment covered by the collection
    theorem.  Constant arithmetic has already been reduced by the evaluator,
    so rational coefficients arrive as [Literal] nodes. *)
let rec rational_polynomial_model_of_expression
    (term:expression)
    (variable:string)
  : Tot (option rational_polynomial_model) (decreases term)
=
  match term with
  | Literal numerator denominator ->
      if denominator = 0 then None
      else Some (RZConstant (make numerator denominator))
  | Symbol name -> if name = variable then Some RZVariable else None
  | Negate inner ->
      begin match rational_polynomial_model_of_expression inner variable with
      | Some model -> Some (RZNegate model)
      | None -> None
      end
  | Binary operator left right ->
      begin match
        rational_polynomial_model_of_expression left variable,
        rational_polynomial_model_of_expression right variable
      with
      | Some left_model, Some right_model ->
          begin match operator with
          | Add -> Some (RZAdd left_model right_model)
          | Subtract -> Some (RZSubtract left_model right_model)
          | Multiply -> Some (RZMultiply left_model right_model)
          | Divide -> None
          end
      | _, _ -> None
      end
  | Power base exponent ->
      if exponent > 0 && exponent <= maximum_expansion_exponent then
        begin match rational_polynomial_model_of_expression base variable with
        | Some model -> Some (RZPower model exponent)
        | None -> None
        end
      else None
  | Simplify inner
  | Expand inner
  | Factor inner -> rational_polynomial_model_of_expression inner variable
  | Function _ _
  | Differentiate _ _
  | Substitute _ _ _
  | Derivative _ _
  | Assuming _ _ _ _ -> None

let rec rational_polynomial_model_of_expression_sound
    (term:expression)
    (variable:string)
    (point:coefficient)
    (model:rational_polynomial_model)
    (value:rational{invariant value})
  : Lemma
      (requires
        rational_polynomial_model_of_expression term variable = Some model /\
        evaluate_rational_polynomial term variable point = Some value)
      (ensures equivalent value
        (rational_polynomial_model_value model point))
      (decreases term)
=
  match term with
  | Literal numerator denominator -> ()
  | Symbol name -> ()
  | Negate inner ->
      begin match
        rational_polynomial_model_of_expression inner variable,
        evaluate_rational_polynomial inner variable point
      with
      | Some inner_model, Some inner_value ->
          rational_polynomial_model_of_expression_sound inner variable point
            inner_model inner_value;
          equivalent_negate_congruence inner_value
            (rational_polynomial_model_value inner_model point)
      | _, _ -> ()
      end
  | Binary operator left right ->
      begin match
        rational_polynomial_model_of_expression left variable,
        rational_polynomial_model_of_expression right variable,
        evaluate_rational_polynomial left variable point,
        evaluate_rational_polynomial right variable point
      with
      | Some left_model, Some right_model,
        Some left_value, Some right_value ->
          rational_polynomial_model_of_expression_sound left variable point
            left_model left_value;
          rational_polynomial_model_of_expression_sound right variable point
            right_model right_value;
          begin match operator with
          | Add ->
              equivalent_add_congruence left_value
                (rational_polynomial_model_value left_model point)
                right_value
                (rational_polynomial_model_value right_model point)
          | Subtract ->
              equivalent_subtract_congruence left_value
                (rational_polynomial_model_value left_model point)
                right_value
                (rational_polynomial_model_value right_model point)
          | Multiply ->
              equivalent_multiply_congruence left_value
                (rational_polynomial_model_value left_model point)
                right_value
                (rational_polynomial_model_value right_model point)
          | Divide -> ()
          end
      | _, _, _, _ -> ()
      end
  | Power base exponent ->
      begin match
        rational_polynomial_model_of_expression base variable,
        evaluate_rational_polynomial base variable point
      with
      | Some base_model, Some base_value ->
          rational_polynomial_model_of_expression_sound base variable point
            base_model base_value;
          rational_power_product_congruence base_value
            (rational_polynomial_model_value base_model point) exponent
      | _, _ -> ()
      end
  | Simplify inner
  | Expand inner
  | Factor inner ->
      rational_polynomial_model_of_expression_sound inner variable point
        model value
  | Function _ _
  | Differentiate _ _
  | Substitute _ _ _
  | Derivative _ _
  | Assuming _ _ _ _ -> ()

let subtract_equivalent_zero_implies_equal
    (left:rational{invariant left})
    (right:rational{invariant right})
  : Lemma
      (requires equivalent (subtract left right) (make 0 1))
      (ensures equivalent left right)
=
  let difference = subtract left right in
  let raw : value:rational{invariant value} = {
    numerator = left.numerator * right.denominator -
      right.numerator * left.denominator;
    denominator = left.denominator * right.denominator
  } in
  assert (equivalent difference raw);
  equivalent_zero_implies_numerator_zero difference;
  assert (difference.numerator = 0);
  assert (difference.numerator * raw.denominator =
    raw.numerator * difference.denominator);
  assert (raw.numerator * difference.denominator = 0);
  assert (difference.denominator > 0);
  assert (raw.numerator = 0);
  assert (left.numerator * right.denominator =
    right.numerator * left.denominator)

let rational_polynomial_identity_sound
    (left right:rational_polynomial_model)
    (point:coefficient)
  : Lemma
      (requires polynomial_is_zero
        (collect_rational_polynomial_model (RZSubtract left right)))
      (ensures equivalent
        (rational_polynomial_model_value left point)
        (rational_polynomial_model_value right point))
=
  let difference = RZSubtract left right in
  let coefficients = collect_rational_polynomial_model difference in
  let evaluated = polynomial_evaluate_horner coefficients point in
  let modeled = rational_polynomial_model_value difference point in
  rational_polynomial_model_collection_sound difference point;
  rational_polynomial_zero_difference_sound coefficients point;
  equivalent_symmetric evaluated modeled;
  equivalent_transitive modeled evaluated (make 0 1);
  subtract_equivalent_zero_implies_equal
    (rational_polynomial_model_value left point)
    (rational_polynomial_model_value right point)

let surface_rational_polynomial_identity_sound
    (left right:expression)
    (variable:string)
    (point:coefficient)
    (left_model right_model:rational_polynomial_model)
    (left_value:rational{invariant left_value})
    (right_value:rational{invariant right_value})
  : Lemma
      (requires
        rational_polynomial_model_of_expression left variable =
          Some left_model /\
        rational_polynomial_model_of_expression right variable =
          Some right_model /\
        evaluate_rational_polynomial left variable point = Some left_value /\
        evaluate_rational_polynomial right variable point = Some right_value /\
        polynomial_is_zero
          (collect_rational_polynomial_model
            (RZSubtract left_model right_model)))
      (ensures equivalent left_value right_value)
=
  rational_polynomial_model_of_expression_sound left variable point
    left_model left_value;
  rational_polynomial_model_of_expression_sound right variable point
    right_model right_value;
  rational_polynomial_identity_sound left_model right_model point;
  equivalent_transitive left_value
    (rational_polynomial_model_value left_model point)
    (rational_polynomial_model_value right_model point);
  equivalent_symmetric right_value
    (rational_polynomial_model_value right_model point);
  equivalent_transitive left_value
    (rational_polynomial_model_value right_model point) right_value

type polynomial_identity_classification =
  | VerifiedPolynomialIdentity
  | NonzeroPolynomialIdentity
  | UnsupportedPolynomialIdentity

(** Executable classifier used by the host.  [VerifiedPolynomialIdentity]
    is returned only under the hypotheses of
    [surface_rational_polynomial_identity_sound]. *)
let classify_polynomial_identity
    (left right:expression)
    (variable:string)
  : Tot polynomial_identity_classification
=
  match rational_polynomial_model_of_expression left variable,
        rational_polynomial_model_of_expression right variable with
  | Some left_model, Some right_model ->
      if polynomial_is_zero
          (collect_rational_polynomial_model
            (RZSubtract left_model right_model))
      then VerifiedPolynomialIdentity
      else NonzeroPolynomialIdentity
  | _, _ -> UnsupportedPolynomialIdentity

let polynomial_identity_example ()
  : Lemma
      (ensures
        classify_polynomial_identity
          (Power (Binary Add (Symbol "x") (Literal 1 1)) 2)
          (Binary Add
            (Binary Add
              (Power (Symbol "x") 2)
              (Binary Multiply (Literal 2 1) (Symbol "x")))
            (Literal 1 1))
          "x" = VerifiedPolynomialIdentity)
= assert_norm (
  classify_polynomial_identity
    (Power (Binary Add (Symbol "x") (Literal 1 1)) 2)
    (Binary Add
      (Binary Add
        (Power (Symbol "x") 2)
        (Binary Multiply (Literal 2 1) (Symbol "x")))
      (Literal 1 1))
    "x" = VerifiedPolynomialIdentity)

#pop-options
