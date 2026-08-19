module String_map = Map.Make (String)

open Centl_multivariate_polynomial

type limits = {
  max_substitutions : int;
  max_power_exponent : int;
  max_terms : int;
  max_exact_bits : int;
  max_work : int;
}

let default_limits =
  {
    max_substitutions = 128;
    max_power_exponent = 1_000;
    max_terms = 4_096;
    max_exact_bits = 1_000_000;
    max_work = 8_000_000;
  }

type error =
  | Empty_variable
  | Duplicate_substitution of string
  | Power_exponent_limit of string * int
  | Resource_limit of string
  | Polynomial_error of Centl_multivariate_polynomial.error
  | Cancelled

let never_cancelled () = false

let error_message = function
  | Empty_variable -> "polynomial substitution variable must not be empty"
  | Duplicate_substitution variable ->
      "duplicate polynomial substitution for variable " ^ variable
  | Power_exponent_limit (variable, exponent) ->
      Printf.sprintf
        "substitution exponent %d for %s exceeds the composition power limit"
        exponent variable
  | Resource_limit message -> message
  | Polynomial_error error -> Centl_multivariate_polynomial.error_message error
  | Cancelled -> "polynomial composition was cancelled"

let guard limits polynomial =
  if term_count polynomial > limits.max_terms then
    Error (Resource_limit "polynomial composition exceeds the term limit")
  else if exact_bits polynomial > limits.max_exact_bits then
    Error (Resource_limit "polynomial composition exceeds the exact-bit limit")
  else Ok polynomial

type state = {
  limits : limits;
  cancelled : unit -> bool;
  mutable work : int;
}

let checkpoint state = if state.cancelled () then Error Cancelled else Ok ()

let charge_product state left_terms right_terms =
  if left_terms < 0 || right_terms < 0 then
    Error (Resource_limit "polynomial composition exceeds the work limit")
  else if left_terms = 0 || right_terms = 0 then Ok ()
  else
    let remaining = state.limits.max_work - state.work in
    if remaining < 0 || left_terms > remaining / right_terms then
      Error (Resource_limit "polynomial composition exceeds the work limit")
    else begin
      state.work <- state.work + (left_terms * right_terms);
      Ok ()
    end

let charge_linear state amount =
  if amount < 0 || amount > state.limits.max_work - state.work then
    Error (Resource_limit "polynomial composition exceeds the work limit")
  else begin
    state.work <- state.work + amount;
    Ok ()
  end

let multiply_bounded state left right =
  let ( let* ) result next = Result.bind result next in
  let left_terms = bindings left in
  let right_terms = bindings right in
  let* () = checkpoint state in
  let* () = charge_product state (List.length left_terms) (List.length right_terms) in
  let rec outer result = function
    | [] -> Ok result
    | (left_monomial, left_coefficient) :: rest ->
        let* () = checkpoint state in
        let rec inner result = function
          | [] -> Ok result
          | (right_monomial, right_coefficient) :: right_rest ->
              let* () = checkpoint state in
              let* monomial =
                match monomial_multiply left_monomial right_monomial with
                | Ok monomial -> Ok monomial
                | Error error -> Error (Polynomial_error error)
              in
              let coefficient = Q.mul left_coefficient right_coefficient in
              let result = add_term coefficient monomial result in
              let* result = guard state.limits result in
              inner result right_rest
        in
        let* result = inner result right_terms in
        outer result rest
  in
  outer zero left_terms

let add_scaled_bounded state scalar destination source =
  let ( let* ) result next = Result.bind result next in
  let rec loop result = function
    | [] -> Ok result
    | (monomial, coefficient) :: rest ->
        let* () = checkpoint state in
        let* () = charge_linear state 1 in
        let coefficient = Q.mul scalar coefficient in
        let result = add_term coefficient monomial result in
        let* result = guard state.limits result in
        loop result rest
  in
  loop destination (bindings source)

let power_bounded state variable polynomial exponent =
  let ( let* ) result next = Result.bind result next in
  if exponent < 0 then
    Error
      (Polynomial_error (Centl_multivariate_polynomial.Negative_power exponent))
  else if exponent > state.limits.max_power_exponent then
    Error (Power_exponent_limit (variable, exponent))
  else if exponent = 0 then Ok one
  else
    let rec loop base exponent accumulator =
      let* () = checkpoint state in
      if exponent = 0 then Ok accumulator
      else
        let* accumulator =
          if exponent land 1 = 1 then multiply_bounded state accumulator base
          else Ok accumulator
        in
        let exponent = exponent lsr 1 in
        if exponent = 0 then Ok accumulator
        else
          let* base = multiply_bounded state base base in
          loop base exponent accumulator
    in
    loop polynomial exponent one

let substitution_map limits substitutions =
  if List.length substitutions > limits.max_substitutions then
    Error (Resource_limit "too many polynomial substitutions")
  else
    let rec build map = function
      | [] -> Ok map
      | (variable, polynomial) :: rest ->
          if String.equal variable "" then Error Empty_variable
          else if String_map.mem variable map then
            Error (Duplicate_substitution variable)
          else
            begin match guard limits polynomial with
            | Error _ as error -> error
            | Ok polynomial ->
                build (String_map.add variable polynomial map) rest
            end
    in
    build String_map.empty substitutions

let unchanged_power variable exponent =
  match term Q.one [ (variable, exponent) ] with
  | Ok polynomial -> Ok polynomial
  | Error error -> Error (Polynomial_error error)

let compose ?(limits = default_limits) ?(cancelled = never_cancelled)
    substitutions polynomial =
  let ( let* ) result next = Result.bind result next in
  if
    limits.max_substitutions < 0
    || limits.max_power_exponent < 0
    || limits.max_terms < 1
    || limits.max_exact_bits < 1
    || limits.max_work < 1
  then Error (Resource_limit "polynomial composition limits are invalid")
  else
    let* polynomial = guard limits polynomial in
    let* substitutions = substitution_map limits substitutions in
    let state = { limits; cancelled; work = 0 } in
    let compose_monomial monomial =
      let rec loop accumulator = function
        | [] -> Ok accumulator
        | (variable, exponent) :: rest ->
            let* () = checkpoint state in
            let* factor =
              match String_map.find_opt variable substitutions with
              | None -> unchanged_power variable exponent
              | Some replacement ->
                  power_bounded state variable replacement exponent
            in
            let* accumulator = multiply_bounded state accumulator factor in
            loop accumulator rest
      in
      loop one monomial
    in
    let rec compose_terms accumulator = function
      | [] -> guard limits accumulator
      | (monomial, coefficient) :: rest ->
          let* () = checkpoint state in
          let* expanded = compose_monomial monomial in
          let* candidate = add_scaled_bounded state coefficient accumulator expanded in
          compose_terms candidate rest
    in
    compose_terms zero (bindings polynomial)

let substitute_polynomials = compose
