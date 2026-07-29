type t

external of_fraction : string -> string -> int -> t = "centl_arb_of_fraction"
external pi : int -> t = "centl_arb_pi"
external neg : t -> t = "centl_arb_neg"
external abs : t -> t = "centl_arb_abs"
external add : t -> t -> int -> t = "centl_arb_add"
external sub : t -> t -> int -> t = "centl_arb_sub"
external mul : t -> t -> int -> t = "centl_arb_mul"
external div : t -> t -> int -> t = "centl_arb_div"
external pow : t -> int -> int -> t = "centl_arb_pow"
external sqrt : t -> int -> t = "centl_arb_sqrt"
external exp : t -> int -> t = "centl_arb_exp"
external log : t -> int -> t = "centl_arb_log"
external sin : t -> int -> t = "centl_arb_sin"
external cos : t -> int -> t = "centl_arb_cos"
external tan : t -> int -> t = "centl_arb_tan"
external asin : t -> int -> t = "centl_arb_asin"
external acos : t -> int -> t = "centl_arb_acos"
external atan : t -> int -> t = "centl_arb_atan"
external atan2 : t -> t -> int -> t = "centl_arb_atan2"
external sinh : t -> int -> t = "centl_arb_sinh"
external cosh : t -> int -> t = "centl_arb_cosh"
external tanh : t -> int -> t = "centl_arb_tanh"
external endpoints : t -> string * string * string = "centl_arb_endpoints"
external classification : t -> int = "centl_arb_classification"

let has flag value = classification value land flag <> 0
let is_finite = has 1
let is_zero = has 2
let is_nonzero = has 4
let is_positive = has 8
let is_nonnegative = has 16
let is_negative = has 32
let is_nonpositive = has 64
