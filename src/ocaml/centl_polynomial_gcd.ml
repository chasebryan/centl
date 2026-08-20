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

type error =
  | Empty_variable
  | Mixed_variable of string
  | Resource_limit of string
  | Polynomial_error of Centl_multivariate_polynomial.error
  | Internal_division_error of string
  | Cancelled

let never_cancelled () = false

let error_message = function
  | Empty_variable -> "polynomial gcd variable must not be empty"
  | Mixed_variable variable ->
      "polynomial gcd input contains non-admitted variable " ^ variable
  | Resource_limit message -> message
  | Polynomial_error error -> Centl_multivariate_polynomial.error_message error
  | Internal_division_error message -> message
  | Cancelled -> "polynomial gcd was cancelled"

let of_division_error = function
  | Centl_polynomial_division.Empty_variable -> Empty_variable
  | Centl_polynomial_division.Mixed_variable variable -> Mixed_variable variable
  | Centl_polynomial_division.Resource_limit message -> Resource_limit message
  | Centl_polynomial_division.Polynomial_error error -> Polynomial_error error
  | Centl_polynomial_division.Cancelled -> Cancelled
  | Centl_polynomial_division.Division_by_zero ->
      Internal_division_error
        "polynomial gcd reached an impossible zero-divisor state"

let lift_division = Result.map_error of_division_error

let checkpoint state =
  Centl_polynomial_division.checkpoint state |> lift_division

let charge state amount =
  Centl_polynomial_division.charge state amount |> lift_division

let guard state label polynomial =
  Centl_polynomial_division.guard state.Centl_polynomial_division.limits label
    polynomial
  |> lift_division

let validate_univariate state variable polynomial =
  Centl_polynomial_division.validate_univariate state variable polynomial
  |> lift_division

let leading_term state variable polynomial =
  Centl_polynomial_division.leading_term state variable polynomial
  |> lift_division

let monic state variable polynomial =
  let ( let* ) result next = Result.bind result next in
  if is_zero polynomial then Ok zero
  else
    let* leading = leading_term state variable polynomial in
    match leading with
    | None -> Ok zero
    | Some (_, leading_coefficient) ->
        let scalar = Q.inv leading_coefficient in
        let rec normalize result = function
          | [] -> guard state "gcd" result
          | (monomial, coefficient) :: rest ->
              let* () = checkpoint state in
              let* () = charge state 1 in
              let result = add_term (Q.mul scalar coefficient) monomial result in
              let* result = guard state "gcd" result in
              normalize result rest
        in
        normalize zero (bindings polynomial)

let valid_limits limits =
  limits.max_euclid_steps >= 0
  && Centl_polynomial_division.valid_limits limits.division

let gcd ?(limits = default_limits) ?(cancelled = never_cancelled) ~variable left
    right =
  let ( let* ) result next = Result.bind result next in
  if String.equal variable "" then Error Empty_variable
  else if not (valid_limits limits) then
    Error (Resource_limit "polynomial gcd limits are invalid")
  else
    let state =
      Centl_polynomial_division.make_state ~limits:limits.division ~cancelled ()
    in
    let* () = checkpoint state in
    let* left = guard state "left input" left in
    let* right = guard state "right input" right in
    let* left = validate_univariate state variable left in
    let* right = validate_univariate state variable right in
    let* left = monic state variable left in
    let* right = monic state variable right in
    let rec euclid steps a b =
      let* () = checkpoint state in
      let* () = charge state 1 in
      if is_zero b then Ok a
      else if steps >= limits.max_euclid_steps then
        Error (Resource_limit "polynomial gcd exceeds the Euclidean-step limit")
      else
        let* division =
          Centl_polynomial_division.divide_with_state state ~variable a b
          |> lift_division
        in
        let* remainder = monic state variable division.remainder in
        euclid (steps + 1) b remainder
    in
    euclid 0 left right

let coprime ?limits ?cancelled ~variable left right =
  let ( let* ) result next = Result.bind result next in
  let* gcd = gcd ?limits ?cancelled ~variable left right in
  Ok (equal gcd one)
