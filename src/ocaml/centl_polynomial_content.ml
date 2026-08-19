open Centl_multivariate_polynomial

type limits = {
  max_terms : int;
  max_exact_bits : int;
  max_work : int;
}

let default_limits =
  {
    max_terms = 4_096;
    max_exact_bits = 1_000_000;
    max_work = 8_000_000;
  }

type decomposition = {
  content : Q.t;
  primitive_part : Centl_multivariate_polynomial.t;
}

type error =
  | Resource_limit of string
  | Cancelled

let never_cancelled () = false

let error_message = function
  | Resource_limit message -> message
  | Cancelled -> "polynomial content decomposition was cancelled"

let saturating_add left right =
  if left >= max_int || right >= max_int || right > max_int - left then max_int
  else left + right

let z_bits value = Z.numbits (Z.abs value)

let q_bits value =
  saturating_add (z_bits (Q.num value)) (z_bits (Q.den value))

let checkpoint cancelled = if cancelled () then Error Cancelled else Ok ()

let charge limits work amount =
  if amount < 0 || !work > limits.max_work - amount then
    Error (Resource_limit "polynomial content decomposition exceeds the work limit")
  else begin
    work := !work + amount;
    Ok ()
  end

let guard_integer limits label value =
  if z_bits value > limits.max_exact_bits then
    Error
      (Resource_limit
         ("polynomial content " ^ label ^ " exceeds the exact-bit limit"))
  else Ok value

let guard_rational limits label value =
  if q_bits value > limits.max_exact_bits then
    Error
      (Resource_limit
         ("polynomial content " ^ label ^ " exceeds the exact-bit limit"))
  else Ok value

let guard_polynomial limits label polynomial =
  if term_count polynomial > limits.max_terms then
    Error
      (Resource_limit
         ("polynomial content " ^ label ^ " exceeds the term limit"))
  else if exact_bits polynomial > limits.max_exact_bits then
    Error
      (Resource_limit
         ("polynomial content " ^ label ^ " exceeds the exact-bit limit"))
  else Ok polynomial

let positive_lcm left right =
  if Z.equal left Z.zero || Z.equal right Z.zero then Z.zero
  else
    let gcd = Z.gcd left right in
    Z.abs (Z.mul (Z.divexact left gcd) right)

let decompose ?(limits = default_limits) ?(cancelled = never_cancelled)
    polynomial =
  let ( let* ) result next = Result.bind result next in
  if limits.max_terms < 1 || limits.max_exact_bits < 1 || limits.max_work < 1 then
    Error (Resource_limit "polynomial content limits are invalid")
  else
    let* polynomial = guard_polynomial limits "input" polynomial in
    let terms = bindings polynomial in
    if terms = [] then Ok { content = Q.zero; primitive_part = zero }
    else
      let work = ref 0 in
      let rec denominator_lcm accumulator = function
        | [] -> Ok accumulator
        | (_, coefficient) :: rest ->
            let* () = checkpoint cancelled in
            let* () = charge limits work 1 in
            let denominator = Q.den coefficient in
            let candidate = positive_lcm accumulator denominator in
            let* candidate = guard_integer limits "denominator LCM" candidate in
            denominator_lcm candidate rest
      in
      let* common_denominator = denominator_lcm Z.one terms in
      let rec integer_gcd accumulator = function
        | [] -> Ok accumulator
        | (_, coefficient) :: rest ->
            let* () = checkpoint cancelled in
            let* () = charge limits work 1 in
            let multiplier = Z.divexact common_denominator (Q.den coefficient) in
            let integerized = Z.mul (Q.num coefficient) multiplier in
            let* integerized =
              guard_integer limits "integerized coefficient" integerized
            in
            let candidate = Z.gcd accumulator (Z.abs integerized) in
            let* candidate = guard_integer limits "coefficient GCD" candidate in
            integer_gcd candidate rest
      in
      let* common_numerator = integer_gcd Z.zero terms in
      let content = Q.make common_numerator common_denominator in
      let* content = guard_rational limits "result" content in
      let reciprocal_content = Q.div Q.one content in
      let primitive_part = scale reciprocal_content polynomial in
      let* primitive_part = guard_polynomial limits "primitive part" primitive_part in
      let* () = checkpoint cancelled in
      Ok { content; primitive_part }

let content ?limits ?cancelled polynomial =
  match decompose ?limits ?cancelled polynomial with
  | Ok decomposition -> Ok decomposition.content
  | Error _ as error -> error

let primitive_part ?limits ?cancelled polynomial =
  match decompose ?limits ?cancelled polynomial with
  | Ok decomposition -> Ok decomposition.primitive_part
  | Error _ as error -> error
