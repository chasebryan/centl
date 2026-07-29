(* Minimal extraction runtime for the primitives used by Centl.Core. *)
type int = Z.t
type nat = int
type pos = int
type nonrec bool = bool

let int_zero = Z.zero
let ( + ) = Z.add
let ( - ) = Z.sub
let ( * ) = Z.mul
let ( / ) = Z.ediv
let ( mod ) = Z.erem
let ( ~- ) = Z.neg
let ( > ) = Z.gt
let ( >= ) = Z.geq
