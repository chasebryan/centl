(* Minimal extraction runtime for the primitives used by Centl.Core. *)
type int = Z.t
type nat = int
type pos = int
type nonrec bool = bool
type string = Stdlib.String.t

let int_zero = Z.zero
let int_one = Z.one
let of_int = Z.of_int
let ( + ) = Z.add
let ( - ) = Z.sub
let ( * ) = Z.mul
let ( / ) = Z.ediv
let ( mod ) = Z.erem
let ( ~- ) = Z.neg
let ( > ) = Z.gt
let ( >= ) = Z.geq
