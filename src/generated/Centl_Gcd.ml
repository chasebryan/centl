open Prims
let rec gcd (left : Prims.nat) (right : Prims.nat) : Prims.nat=
  if right = Prims.int_zero then left else gcd right ((mod) left right)
