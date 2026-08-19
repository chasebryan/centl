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

let checkpoint cancelled = if cancelled () then Error Cancelled else Ok ()

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

let charge limits work amount =
  if amount < 0 || !work > limits.max_work - amount then
    Error (Resource_limit "polynomial division exceeds the work limit")
  else begin
    work := !work + amount;
    Ok ()
  end

let exponent_of_monomial variable monomial =
  let rec loop exponent = function
    | [] -> Ok exponent
    | (candidate, power) :: rest ->
        if String.equal candidate variable then loop power rest
        else Error (Mixed_variable candidate)
  in
  loop 0 monomial

let validate_univariate variable polynomial =
  let ( let* ) result next = Result.bind result next in
  let rec loop = function
    | [] -> Ok polynomial
    | (monomial, _) :: rest ->
        let* _ = exponent_of_monomial variable monomial in
        loop rest
  in
  loop (bindings polynomial)

let leading_term variable polynomial =
  let ( let* ) result next = Result.bind result next in
  let rec loop best = function
    | [] -> Ok best
    | (monomial, coefficient) :: rest ->
        let* exponent = exponent_of_monomial variable monomial in
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

let monomial_shift variable shift monomial =
  if shift = 0 then Ok monomial
  else
    match monomial_multiply monomial [ (variable, shift) ] with
    | Ok monomial -> Ok monomial
    | Error error -> Error (Polynomial_error error)

let shift_scale ?(cancelled = never_cancelled) limits work variable shift scalar
    polynomial =
  let ( let* ) result next = Result.bind result next in
  let rec loop result = function
    | [] -> guard limits "intermediate product" result
    | (monomial, coefficient) :: rest ->
        let* () = checkpoint cancelled in
        let* () = charge limits work 1 in
        let* monomial = monomial_shift variable shift monomial in
        let result = add_term (Q.mul scalar coefficient) monomial result in
        let* result = guard limits "intermediate product" result in
        loop result rest
  in
  loop zero (bindings polynomial)

let divide ?(limits = default_limits) ?(cancelled = never_cancelled) ~variable
    ~dividend ~divisor =
  let ( let* ) result next = Result.bind result next in
  if String.equal variable "" then Error Empty_variable
  else if
    limits.max_terms < 1
    || limits.max_exact_bits < 1
    || limits.max_steps < 0
    || limits.max_work < 1
  then Error (Resource_limit "polynomial division limits are invalid")
  else
    let* () = checkpoint cancelled in
    let* dividend = guard limits "dividend" dividend in
    let* divisor = guard limits "divisor" divisor in
    let* dividend = validate_univariate variable dividend in
    let* divisor = validate_univariate variable divisor in
    if is_zero divisor then Error Division_by_zero
    else
      let* divisor_leading = leading_term variable divisor in
      match divisor_leading with
      | None -> Error Division_by_zero
      | Some (divisor_degree, divisor_leading_coefficient) ->
          let work = ref 0 in
          let rec loop steps quotient remainder =
            let* () = checkpoint cancelled in
            let* () = charge limits work 1 in
            if is_zero remainder then Ok { quotient; remainder }
            else
              let* remainder_leading = leading_term variable remainder in
              match remainder_leading with
              | None -> Ok { quotient; remainder }
              | Some (remainder_degree, _) when remainder_degree < divisor_degree ->
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
                  let* quotient_term =
                    match term coefficient [ (variable, shift) ] with
                    | Ok polynomial -> Ok polynomial
                    | Error error -> Error (Polynomial_error error)
                  in
                  let quotient = add quotient quotient_term in
                  let* quotient = guard limits "quotient" quotient in
                  let* subtractor =
                    shift_scale ~cancelled limits work variable shift coefficient
                      divisor
                  in
                  let remainder = sub remainder subtractor in
                  let* remainder = guard limits "remainder" remainder in
                  loop (steps + 1) quotient remainder
          in
          loop 0 zero dividend

let quotient ?limits ?cancelled ~variable ~dividend ~divisor =
  match divide ?limits ?cancelled ~variable ~dividend ~divisor with
  | Ok division -> Ok division.quotient
  | Error _ as error -> error

let remainder ?limits ?cancelled ~variable ~dividend ~divisor =
  match divide ?limits ?cancelled ~variable ~dividend ~divisor with
  | Ok division -> Ok division.remainder
  | Error _ as error -> error
