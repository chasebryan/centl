module Centl.Gcd

module Euclid = FStar.Math.Euclid
module Math = FStar.Math.Lemmas

let rec gcd (left right:nat)
  : Tot nat (decreases right)
=
  if right = 0 then left
  else gcd right (left % right)

let rec gcd_is_gcd (left right:nat)
  : Lemma (ensures Euclid.is_gcd left right (gcd left right))
      (decreases right)
=
  if right = 0 then
    Euclid.is_gcd_0 left
  else
    let remainder = left % right in
    let divisor = gcd right remainder in
    gcd_is_gcd right remainder;
    Euclid.is_gcd_plus right remainder (left / right) divisor;
    Math.euclidean_division_definition left right;
    Euclid.is_gcd_symmetric left right divisor
