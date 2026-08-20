open Centl_multivariate_polynomial

type limits = {
  max_terms : int;
  max_exact_bits : int;
  max_steps : int;
  max_work : int;
}

let default_limits =
  {
    max_terms = 4_096;
    max_exact_bits = 1_000_000;
    max_steps = 100_000;
    max_work = 8_000_000;
  }

type division = {
  quotient : Centl_multivariate_polynomial.t;
  remainder : Centl_multivariate_polynomial.t;
}

type error =
  | Empty_variable
  | Division_by_zero
  | Mixed_variable of string
  | Resource_limit of string
  | Polynomial_error of Centl_multivariate_polynomial.error
  | Cancelled

let never_cancelled () = false

let error_message = function
  | Empty_variable -> "polynomial division variable must not be empty"
  | Division_by_zero -> "polynomial division by the zero polynomial is undefined"
  | Mixed_variable variable ->
      "polynomial division input contains non-admitted variable " ^ variable
  | Resource_limit message -> message
  | Polynomial_error error -> Centl_multivariate_polynomial.error_message error
  | Cancelled -> "polynomial division was cancelled"

type state = {
  limits : limits;
  cancelled : unit -> bool;
  mutable work : int;
}

let make_state ?(limits = default_limits) ?(cancelled = never_cancelled) () =
  { limits; cancelled; work = 0 }

let checkpoint state = if state.cancelled () then Error Cancelled else Ok ()

let charge state amount =
  if amount < 0 || state.work > state.limits.max_work - amount then
    Error (Resource_limit "polynomial division exceeds the work limit")
  else begin
    state.work <- state.work + amount;
    Ok ()
  end

let guard limits label polynomial =
  if term_count polynomial > limits.max_terms then
    Error
      (Resource_limit
         ("polynomial division " ^ label ^ " exceeds the term limit"))
  else if exact_bits polynomial > limits.max_exact_bits then
    Error
      (Resource_limit
         ("polynomial division " ^ label ^ " exceeds the exact-bit limit"))
  else Ok polynomial

let valid_limits limits =
  limits.max_terms >= 1
  && limits.max_exact_bits >= 1
  && limits.max_steps >= 0
  && limits.max_work >= 1

let exponent_of_monomial state variable monomial =
  let ( let* ) result next = Result.bind result next in
  let rec loop exponent = function
    | [] -> Ok exponent
    | (candidate, power) :: rest ->
        let* () = checkpoint state in
        let* () = charge state 1 in
        if String.equal candidate variable then loop power rest
        else Error (Mixed_variable candidate)
  in
  loop 0 monomial

let validate_univariate state variable polynomial =
  let ( let* ) result next = Result.bind result next in
  let rec loop = function
    | [] -> Ok polynomial
    | (monomial, _) :: rest ->
        let* () = checkpoint state in
        let* () = charge state 1 in
        let* _ = exponent_of_monomial state variable monomial in
        loop rest
  in
  loop (bindings polynomial)

let leading_term state variable polynomial =
  let ( let* ) result next = Result.bind result next in
  let rec loop best = function
    | [] -> Ok best
    | (monomial, coefficient) :: rest ->
        let* () = checkpoint state in
        let* () = charge state 1 in
        let* exponent = exponent_of_monomial state variable monomial in
        let best =
          match best with
          | None -> Some (exponent, coefficient)
          | Some (best_exponent, _) when exponent > best_exponent ->
              Some (exponent, coefficient)
          | Some _ -> best
        in
        loop best rest
  in
  loop None (bindings polynomial)

let monomial_shift state variable shift monomial =
  let ( let* ) result next = Result.bind result next in
  let* () = checkpoint state in
  let* () = charge state 1 in
  if shift = 0 then Ok monomial
  else
    match monomial_multiply monomial [ (variable, shift) ] with
    | Ok monomial -> Ok monomial
    | Error error -> Error (Polynomial_error error)

let subtract_shifted state variable shift scalar divisor remainder =
  let ( let* ) result next = Result.bind result next in
  let rec loop result = function
    | [] -> guard state.limits "remainder" result
    | (monomial, coefficient) :: rest ->
        let* () = checkpoint state in
        let* () = charge state 1 in
        let* monomial = monomial_shift state variable shift monomial in
        let coefficient = Q.mul scalar coefficient in
        let result = add_term (Q.neg coefficient) monomial result in
        let* result = guard state.limits "remainder" result in
        loop result rest
  in
  loop remainder (bindings divisor)

let divide_with_state state ~variable dividend divisor =
  let ( let* ) result next = Result.bind result next in
  let limits = state.limits in
  if String.equal variable "" then Error Empty_variable
  else if not (valid_limits limits) then
    Error (Resource_limit "polynomial division limits are invalid")
  else
    let* () = checkpoint state in
    let* dividend = guard limits "dividend" dividend in
    let* divisor = guard limits "divisor" divisor in
    let* dividend = validate_univariate state variable dividend in
    let* divisor = validate_univariate state variable divisor in
    if is_zero divisor then Error Division_by_zero
    else
      let* divisor_leading = leading_term state variable divisor in
      match divisor_leading with
      | None -> Error Division_by_zero
      | Some (divisor_degree, divisor_leading_coefficient) ->
          let rec loop steps quotient remainder =
            let* () = checkpoint state in
            let* () = charge state 1 in
            if is_zero remainder then Ok { quotient; remainder }
            else
              let* remainder_leading = leading_term state variable remainder in
              match remainder_leading with
              | None -> Ok { quotient; remainder }
              | Some (remainder_degree, _)
                when remainder_degree < divisor_degree ->
                  Ok { quotient; remainder }
              | Some _ when steps >= limits.max_steps ->
                  Error
                    (Resource_limit
                       "polynomial division exceeds the step limit")
              | Some (remainder_degree, remainder_leading_coefficient) ->
                  let shift = remainder_degree - divisor_degree in
                  let coefficient =
                    Q.div remainder_leading_coefficient
                      divisor_leading_coefficient
                  in
                  let* () = checkpoint state in
                  let* () = charge state 1 in
                  let quotient_monomial =
                    if shift = 0 then [] else [ (variable, shift) ]
                  in
                  let quotient =
                    add_term coefficient quotient_monomial quotient
                  in
                  let* quotient = guard limits "quotient" quotient in
                  let* remainder =
                    subtract_shifted state variable shift coefficient divisor
                      remainder
                  in
                  loop (steps + 1) quotient remainder
          in
          loop 0 zero dividend

let divide ?(limits = default_limits) ?(cancelled = never_cancelled) ~variable
    dividend divisor =
  let state = make_state ~limits ~cancelled () in
  divide_with_state state ~variable dividend divisor

let quotient ?limits ?cancelled ~variable dividend divisor =
  match divide ?limits ?cancelled ~variable dividend divisor with
  | Ok division -> Ok division.quotient
  | Error _ as error -> error

let remainder ?limits ?cancelled ~variable dividend divisor =
  match divide ?limits ?cancelled ~variable dividend divisor with
  | Ok division -> Ok division.remainder
  | Error _ as error -> error
