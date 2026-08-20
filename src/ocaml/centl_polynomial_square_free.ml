open Centl_multivariate_polynomial

type limits = {
  division : Centl_polynomial_division.limits;
  max_gcd_steps : int;
  max_factor_steps : int;
}

let default_limits =
  {
    division = Centl_polynomial_division.default_limits;
    max_gcd_steps = 4_096;
    max_factor_steps = 4_096;
  }

type factor = {
  multiplicity : int;
  polynomial : Centl_multivariate_polynomial.t;
}

type factorization = {
  unit : Q.t;
  factors : factor list;
}

type error =
  | Empty_variable
  | Zero_polynomial
  | Mixed_variable of string
  | Resource_limit of string
  | Polynomial_error of Centl_multivariate_polynomial.error
  | Internal_division_error of string
  | Internal_gcd_error of string
  | Internal_factorization_error of string
  | Cancelled

let never_cancelled () = false

let error_message = function
  | Empty_variable -> "polynomial square-free factorization variable must not be empty"
  | Zero_polynomial ->
      "square-free factorization of the zero polynomial is undefined"
  | Mixed_variable variable ->
      "polynomial square-free factorization input contains non-admitted variable "
      ^ variable
  | Resource_limit message -> message
  | Polynomial_error error -> Centl_multivariate_polynomial.error_message error
  | Internal_division_error message -> message
  | Internal_gcd_error message -> message
  | Internal_factorization_error message -> message
  | Cancelled -> "polynomial square-free factorization was cancelled"

let of_division_error = function
  | Centl_polynomial_division.Empty_variable -> Empty_variable
  | Centl_polynomial_division.Mixed_variable variable -> Mixed_variable variable
  | Centl_polynomial_division.Resource_limit message -> Resource_limit message
  | Centl_polynomial_division.Polynomial_error error -> Polynomial_error error
  | Centl_polynomial_division.Cancelled -> Cancelled
  | Centl_polynomial_division.Division_by_zero ->
      Internal_division_error
        "square-free factorization reached an impossible zero-divisor state"

let of_gcd_error = function
  | Centl_polynomial_gcd.Empty_variable -> Empty_variable
  | Centl_polynomial_gcd.Mixed_variable variable -> Mixed_variable variable
  | Centl_polynomial_gcd.Resource_limit message -> Resource_limit message
  | Centl_polynomial_gcd.Polynomial_error error -> Polynomial_error error
  | Centl_polynomial_gcd.Cancelled -> Cancelled
  | Centl_polynomial_gcd.Internal_division_error message ->
      Internal_gcd_error message

let lift_division result = Result.map_error of_division_error result
let lift_gcd result = Result.map_error of_gcd_error result

let checkpoint state =
  Centl_polynomial_division.checkpoint state |> lift_division

let charge state amount =
  Centl_polynomial_division.charge state amount |> lift_division

let state_limits state = state.Centl_polynomial_division.limits

let guard state label polynomial =
  let limits = state_limits state in
  if term_count polynomial > limits.max_terms then
    Error
      (Resource_limit
         ("polynomial square-free " ^ label ^ " exceeds the term limit"))
  else if exact_bits polynomial > limits.max_exact_bits then
    Error
      (Resource_limit
         ("polynomial square-free " ^ label ^ " exceeds the exact-bit limit"))
  else Ok polynomial

let validate_univariate state variable polynomial =
  Centl_polynomial_division.validate_univariate state variable polynomial
  |> lift_division

let leading_term state variable polynomial =
  Centl_polynomial_division.leading_term state variable polynomial
  |> lift_division

let scale_bounded state label scalar polynomial =
  let ( let* ) result next = Result.bind result next in
  if Q.equal scalar Q.zero || is_zero polynomial then Ok zero
  else
    let rec loop result = function
      | [] -> guard state label result
      | (monomial, coefficient) :: rest ->
          let* () = checkpoint state in
          let* () = charge state 1 in
          let result = add_term (Q.mul scalar coefficient) monomial result in
          let* result = guard state label result in
          loop result rest
    in
    loop zero (bindings polynomial)

let normalize_input state variable polynomial =
  let ( let* ) result next = Result.bind result next in
  let* leading = leading_term state variable polynomial in
  match leading with
  | None -> Error Zero_polynomial
  | Some (degree, leading_coefficient) ->
      let* monic =
        scale_bounded state "normalized input" (Q.inv leading_coefficient)
          polynomial
      in
      Ok (leading_coefficient, degree, monic)

let derivative_bounded state variable polynomial =
  let ( let* ) result next = Result.bind result next in
  let rec loop result = function
    | [] -> guard state "derivative" result
    | (monomial, coefficient) :: rest ->
        let* () = checkpoint state in
        let* () = charge state 1 in
        let result =
          match List.assoc_opt variable monomial with
          | None -> result
          | Some exponent ->
              let coefficient = Q.mul coefficient (Q.of_int exponent) in
              let monomial =
                let rec decrement reversed = function
                  | [] -> List.rev reversed
                  | (candidate, power) :: tail
                    when String.equal candidate variable ->
                      if power = 1 then List.rev_append reversed tail
                      else
                        List.rev_append reversed
                          ((candidate, power - 1) :: tail)
                  | power :: tail -> decrement (power :: reversed) tail
                in
                decrement [] monomial
              in
              add_term coefficient monomial result
        in
        let* result = guard state "derivative" result in
        loop result rest
  in
  loop zero (bindings polynomial)

let exact_quotient state variable dividend divisor =
  let ( let* ) result next = Result.bind result next in
  let* division =
    Centl_polynomial_division.divide_with_state state ~variable dividend divisor
    |> lift_division
  in
  if is_zero division.remainder then Ok division.quotient
  else
    Error
      (Internal_division_error
         "square-free factorization expected an exact polynomial quotient")

let gcd state limits variable left right =
  Centl_polynomial_gcd.gcd_with_state state
    ~max_euclid_steps:limits.max_gcd_steps ~variable left right
  |> lift_gcd

let valid_limits limits =
  limits.max_gcd_steps >= 0
  && limits.max_factor_steps >= 0
  && Centl_polynomial_division.valid_limits limits.division

let factorize ?(limits = default_limits) ?(cancelled = never_cancelled) ~variable
    polynomial =
  let ( let* ) result next = Result.bind result next in
  if String.equal variable "" then Error Empty_variable
  else if not (valid_limits limits) then
    Error (Resource_limit "polynomial square-free limits are invalid")
  else
    let state =
      Centl_polynomial_division.make_state ~limits:limits.division ~cancelled ()
    in
    let* () = checkpoint state in
    let* polynomial = guard state "input" polynomial in
    let* polynomial = validate_univariate state variable polynomial in
    let* unit, degree, monic = normalize_input state variable polynomial in
    if degree = 0 then Ok { unit; factors = [] }
    else
      let* derivative = derivative_bounded state variable monic in
      let* repeated = gcd state limits variable monic derivative in
      let* square_free = exact_quotient state variable monic repeated in
      let rec loop steps multiplicity repeated square_free reversed =
        let* () = checkpoint state in
        let* () = charge state 1 in
        if equal square_free one then
          if equal repeated one then
            Ok { unit; factors = List.rev reversed }
          else
            Error
              (Internal_factorization_error
                 "square-free factorization ended with residual repeated content")
        else if steps >= limits.max_factor_steps then
          Error
            (Resource_limit
               "polynomial square-free factorization exceeds the factor-step limit")
        else
          let* common = gcd state limits variable square_free repeated in
          let* factor = exact_quotient state variable square_free common in
          let reversed =
            if equal factor one then reversed
            else { multiplicity; polynomial = factor } :: reversed
          in
          let* repeated = exact_quotient state variable repeated common in
          loop (steps + 1) (multiplicity + 1) repeated common reversed
      in
      loop 0 1 repeated square_free []
