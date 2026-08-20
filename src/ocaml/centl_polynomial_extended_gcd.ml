open Centl_multivariate_polynomial

type limits = {
  division : Centl_polynomial_division.limits;
  max_euclid_steps : int;
}

let default_limits =
  {
    division = Centl_polynomial_division.default_limits;
    max_euclid_steps = 4_096;
  }

type certificate = {
  gcd : Centl_multivariate_polynomial.t;
  left_coefficient : Centl_multivariate_polynomial.t;
  right_coefficient : Centl_multivariate_polynomial.t;
}

type error =
  | Empty_variable
  | Mixed_variable of string
  | Resource_limit of string
  | Polynomial_error of Centl_multivariate_polynomial.error
  | Internal_division_error of string
  | Cancelled

let never_cancelled () = false

let error_message = function
  | Empty_variable -> "polynomial extended gcd variable must not be empty"
  | Mixed_variable variable ->
      "polynomial extended gcd input contains non-admitted variable " ^ variable
  | Resource_limit message -> message
  | Polynomial_error error -> Centl_multivariate_polynomial.error_message error
  | Internal_division_error message -> message
  | Cancelled -> "polynomial extended gcd was cancelled"

let of_division_error = function
  | Centl_polynomial_division.Empty_variable -> Empty_variable
  | Centl_polynomial_division.Mixed_variable variable -> Mixed_variable variable
  | Centl_polynomial_division.Resource_limit message -> Resource_limit message
  | Centl_polynomial_division.Polynomial_error error -> Polynomial_error error
  | Centl_polynomial_division.Cancelled -> Cancelled
  | Centl_polynomial_division.Division_by_zero ->
      Internal_division_error
        "polynomial extended gcd reached an impossible zero-divisor state"

let lift_division result = Result.map_error of_division_error result

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
         ("polynomial extended gcd " ^ label ^ " exceeds the term limit"))
  else if exact_bits polynomial > limits.max_exact_bits then
    Error
      (Resource_limit
         ("polynomial extended gcd " ^ label ^ " exceeds the exact-bit limit"))
  else Ok polynomial

let validate_univariate state variable polynomial =
  Centl_polynomial_division.validate_univariate state variable polynomial
  |> lift_division

let leading_term state variable polynomial =
  Centl_polynomial_division.leading_term state variable polynomial
  |> lift_division

let divide state variable dividend divisor =
  Centl_polynomial_division.divide_with_state state ~variable dividend divisor
  |> lift_division

let scale_bounded state scalar polynomial =
  let ( let* ) result next = Result.bind result next in
  if Q.equal scalar Q.zero || is_zero polynomial then Ok zero
  else
    let rec loop result = function
      | [] -> guard state "scaled witness" result
      | (monomial, coefficient) :: rest ->
          let* () = checkpoint state in
          let* () = charge state 1 in
          let result = add_term (Q.mul scalar coefficient) monomial result in
          let* result = guard state "scaled witness" result in
          loop result rest
    in
    loop zero (bindings polynomial)

let subtract_bounded state left right =
  let ( let* ) result next = Result.bind result next in
  let* left = guard state "witness input" left in
  let rec loop result = function
    | [] -> guard state "witness difference" result
    | (monomial, coefficient) :: rest ->
        let* () = checkpoint state in
        let* () = charge state 1 in
        let result = add_term (Q.neg coefficient) monomial result in
        let* result = guard state "witness difference" result in
        loop result rest
  in
  loop left (bindings right)

let multiply_bounded state left right =
  let ( let* ) result next = Result.bind result next in
  let left_terms = bindings left in
  let right_terms = bindings right in
  let rec outer result = function
    | [] -> guard state "witness product" result
    | (left_monomial, left_coefficient) :: rest ->
        let* () = checkpoint state in
        let rec inner result = function
          | [] -> Ok result
          | (right_monomial, right_coefficient) :: right_rest ->
              let* () = checkpoint state in
              let* () = charge state 1 in
              let* monomial =
                match monomial_multiply left_monomial right_monomial with
                | Ok monomial -> Ok monomial
                | Error error -> Error (Polynomial_error error)
              in
              let coefficient = Q.mul left_coefficient right_coefficient in
              let result = add_term coefficient monomial result in
              let* result = guard state "witness product" result in
              inner result right_rest
        in
        let* result = inner result right_terms in
        outer result rest
  in
  outer zero left_terms

let valid_limits limits =
  limits.max_euclid_steps >= 0
  && Centl_polynomial_division.valid_limits limits.division

let extended_gcd ?(limits = default_limits) ?(cancelled = never_cancelled)
    ~variable left right =
  let ( let* ) result next = Result.bind result next in
  if String.equal variable "" then Error Empty_variable
  else if not (valid_limits limits) then
    Error (Resource_limit "polynomial extended gcd limits are invalid")
  else
    let state =
      Centl_polynomial_division.make_state ~limits:limits.division ~cancelled ()
    in
    let* () = checkpoint state in
    let* left = guard state "left input" left in
    let* right = guard state "right input" right in
    let* left = validate_univariate state variable left in
    let* right = validate_univariate state variable right in
    let rec euclid steps old_r r old_s s old_t t =
      let* () = checkpoint state in
      let* () = charge state 1 in
      if is_zero r then
        if is_zero old_r then
          Ok { gcd = zero; left_coefficient = zero; right_coefficient = zero }
        else
          let* leading = leading_term state variable old_r in
          begin match leading with
          | None ->
              Ok { gcd = zero; left_coefficient = zero; right_coefficient = zero }
          | Some (_, leading_coefficient) ->
              let scalar = Q.inv leading_coefficient in
              let* gcd = scale_bounded state scalar old_r in
              let* left_coefficient = scale_bounded state scalar old_s in
              let* right_coefficient = scale_bounded state scalar old_t in
              Ok { gcd; left_coefficient; right_coefficient }
          end
      else if steps >= limits.max_euclid_steps then
        Error
          (Resource_limit
             "polynomial extended gcd exceeds the Euclidean-step limit")
      else
        let* division = divide state variable old_r r in
        let* quotient_times_s = multiply_bounded state division.quotient s in
        let* next_s = subtract_bounded state old_s quotient_times_s in
        let* quotient_times_t = multiply_bounded state division.quotient t in
        let* next_t = subtract_bounded state old_t quotient_times_t in
        euclid (steps + 1) r division.remainder s next_s t next_t
    in
    euclid 0 left right one zero zero one
