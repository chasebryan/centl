open Centl_multivariate_polynomial

type limits = {
  division : Centl_polynomial_division.limits;
  max_degree : int;
  max_point_abs : int;
  max_divisor_trials : int;
  max_divisors_per_value : int;
  max_candidates : int;
  max_factors : int;
}

let default_limits =
  {
    division = Centl_polynomial_division.default_limits;
    max_degree = 12;
    max_point_abs = 64;
    max_divisor_trials = 250_000;
    max_divisors_per_value = 4_096;
    max_candidates = 250_000;
    max_factors = 64;
  }

type factor = {
  polynomial : Centl_multivariate_polynomial.t;
  multiplicity : int;
}

type factorization = {
  unit : Q.t;
  factors : factor list;
}

type error =
  | Empty_variable
  | Mixed_variable of string
  | Zero_polynomial
  | Resource_limit of string
  | Polynomial_error of Centl_multivariate_polynomial.error
  | Internal_division_error of string
  | Internal_factorization_error of string
  | Cancelled

let never_cancelled () = false

let error_message = function
  | Empty_variable -> "polynomial factorization variable must not be empty"
  | Mixed_variable variable ->
      "polynomial factorization input contains non-admitted variable " ^ variable
  | Zero_polynomial -> "the zero polynomial has no finite irreducible factorization"
  | Resource_limit message -> message
  | Polynomial_error error -> Centl_multivariate_polynomial.error_message error
  | Internal_division_error message -> message
  | Internal_factorization_error message -> message
  | Cancelled -> "polynomial factorization was cancelled"

let of_division_error = function
  | Centl_polynomial_division.Empty_variable -> Empty_variable
  | Centl_polynomial_division.Mixed_variable variable -> Mixed_variable variable
  | Centl_polynomial_division.Resource_limit message -> Resource_limit message
  | Centl_polynomial_division.Polynomial_error error -> Polynomial_error error
  | Centl_polynomial_division.Cancelled -> Cancelled
  | Centl_polynomial_division.Division_by_zero ->
      Internal_division_error
        "polynomial factorization reached an impossible zero-divisor state"

let lift_division result = Result.map_error of_division_error result

type state = {
  core : Centl_polynomial_division.state;
  limits : limits;
  mutable divisor_trials : int;
  mutable candidates : int;
  mutable terminal_factors : int;
}

let make_state limits cancelled =
  {
    core = Centl_polynomial_division.make_state ~limits:limits.division ~cancelled ();
    limits;
    divisor_trials = 0;
    candidates = 0;
    terminal_factors = 0;
  }

let checkpoint state =
  Centl_polynomial_division.checkpoint state.core |> lift_division

let charge state amount =
  Centl_polynomial_division.charge state.core amount |> lift_division

let guard_polynomial state label polynomial =
  Centl_polynomial_division.guard state.limits.division label polynomial
  |> lift_division

let validate_univariate state variable polynomial =
  Centl_polynomial_division.validate_univariate state.core variable polynomial
  |> lift_division

let exponent_of_monomial state variable monomial =
  Centl_polynomial_division.exponent_of_monomial state.core variable monomial
  |> lift_division

let leading_term state variable polynomial =
  Centl_polynomial_division.leading_term state.core variable polynomial
  |> lift_division

let z_bits value = Z.numbits (Z.abs value)

let q_bits value = z_bits (Q.num value) + z_bits (Q.den value)

let guard_integer state label value =
  if z_bits value > state.limits.division.max_exact_bits then
    Error
      (Resource_limit
         ("polynomial factorization " ^ label ^ " exceeds the exact-bit limit"))
  else Ok value

let guard_rational state label value =
  if q_bits value > state.limits.division.max_exact_bits then
    Error
      (Resource_limit
         ("polynomial factorization " ^ label ^ " exceeds the exact-bit limit"))
  else Ok value

let valid_limits limits =
  Centl_polynomial_division.valid_limits limits.division
  && limits.max_degree >= 0
  && limits.max_point_abs >= 0
  && limits.max_divisor_trials >= 1
  && limits.max_divisors_per_value >= 1
  && limits.max_candidates >= 1
  && limits.max_factors >= 1

let positive_lcm left right =
  if Z.equal left Z.zero || Z.equal right Z.zero then Z.zero
  else
    let divisor = Z.gcd left right in
    Z.abs (Z.mul (Z.divexact left divisor) right)

let trim_z coefficients =
  let rec last_nonzero index =
    if index < 0 then -1
    else if Z.equal coefficients.(index) Z.zero then last_nonzero (index - 1)
    else index
  in
  let last = last_nonzero (Array.length coefficients - 1) in
  if last < 0 then [||]
  else if last = Array.length coefficients - 1 then Array.copy coefficients
  else Array.sub coefficients 0 (last + 1)

let degree_z coefficients = Array.length (trim_z coefficients) - 1

let polynomial_of_z state variable coefficients =
  let ( let* ) result next = Result.bind result next in
  let rec loop index result =
    if index >= Array.length coefficients then guard_polynomial state "candidate" result
    else
      let* () = checkpoint state in
      let* () = charge state 1 in
      let coefficient = coefficients.(index) in
      let result =
        if Z.equal coefficient Z.zero then result
        else
          let monomial = if index = 0 then [] else [ (variable, index) ] in
          add_term (Q.of_bigint coefficient) monomial result
      in
      loop (index + 1) result
  in
  loop 0 zero

let dense_q_of_polynomial state variable degree polynomial =
  let ( let* ) result next = Result.bind result next in
  let coefficients = Array.make (degree + 1) Q.zero in
  let rec loop = function
    | [] -> Ok coefficients
    | (monomial, coefficient) :: rest ->
        let* () = checkpoint state in
        let* () = charge state 1 in
        let* exponent = exponent_of_monomial state variable monomial in
        if exponent < 0 || exponent > degree then
          Error
            (Internal_factorization_error
               "polynomial factorization observed an inconsistent degree")
        else begin
          coefficients.(exponent) <- coefficient;
          loop rest
        end
  in
  loop (bindings polynomial)

let primitive_integer_coefficients state rational_coefficients =
  let ( let* ) result next = Result.bind result next in
  let rec denominator_lcm index accumulator =
    if index >= Array.length rational_coefficients then Ok accumulator
    else
      let* () = checkpoint state in
      let* () = charge state 1 in
      let candidate =
        positive_lcm accumulator (Q.den rational_coefficients.(index))
      in
      let* candidate = guard_integer state "denominator LCM" candidate in
      denominator_lcm (index + 1) candidate
  in
  let* common_denominator = denominator_lcm 0 Z.one in
  let integerized = Array.make (Array.length rational_coefficients) Z.zero in
  let rec integerize index common_gcd =
    if index >= Array.length rational_coefficients then Ok common_gcd
    else
      let* () = checkpoint state in
      let* () = charge state 1 in
      let coefficient = rational_coefficients.(index) in
      let multiplier = Z.divexact common_denominator (Q.den coefficient) in
      let value = Z.mul (Q.num coefficient) multiplier in
      let* value = guard_integer state "integerized coefficient" value in
      integerized.(index) <- value;
      integerize (index + 1) (Z.gcd common_gcd (Z.abs value))
  in
  let* common_gcd = integerize 0 Z.zero in
  if Z.equal common_gcd Z.zero then Error Zero_polynomial
  else
    let primitive = Array.make (Array.length integerized) Z.zero in
    let rec divide_gcd index =
      if index >= Array.length integerized then Ok ()
      else
        let* () = checkpoint state in
        let* () = charge state 1 in
        primitive.(index) <- Z.divexact integerized.(index) common_gcd;
        divide_gcd (index + 1)
    in
    let* () = divide_gcd 0 in
    let primitive = trim_z primitive in
    if Array.length primitive = 0 then Error Zero_polynomial
    else
      let leading = primitive.(Array.length primitive - 1) in
      if Z.sign leading >= 0 then Ok primitive
      else
        let rec negate index =
          if index >= Array.length primitive then Ok primitive
          else
            let* () = checkpoint state in
            let* () = charge state 1 in
            primitive.(index) <- Z.neg primitive.(index);
            negate (index + 1)
        in
        negate 0

let gcd_coefficients state coefficients =
  let ( let* ) result next = Result.bind result next in
  let rec loop index accumulator =
    if index >= Array.length coefficients then Ok accumulator
    else
      let* () = checkpoint state in
      let* () = charge state 1 in
      loop (index + 1) (Z.gcd accumulator (Z.abs coefficients.(index)))
  in
  loop 0 Z.zero

let positive_primitive state coefficients =
  let ( let* ) result next = Result.bind result next in
  let coefficients = trim_z coefficients in
  if Array.length coefficients = 0 then Ok false
  else
    let* gcd = gcd_coefficients state coefficients in
    let leading = coefficients.(Array.length coefficients - 1) in
    Ok (Z.equal gcd Z.one && Z.sign leading > 0)

let integral_dense_of_polynomial state variable polynomial =
  let ( let* ) result next = Result.bind result next in
  let* leading = leading_term state variable polynomial in
  match leading with
  | None -> Ok [||]
  | Some (degree, _) ->
      let* rational = dense_q_of_polynomial state variable degree polynomial in
      let result = Array.make (degree + 1) Z.zero in
      let rec loop index =
        if index >= Array.length rational then Ok (trim_z result)
        else
          let* () = checkpoint state in
          let* () = charge state 1 in
          let coefficient = rational.(index) in
          if not (Z.equal (Q.den coefficient) Z.one) then Ok [||]
          else begin
            result.(index) <- Q.num coefficient;
            loop (index + 1)
          end
      in
      loop 0

let evaluate_z state coefficients point =
  let ( let* ) result next = Result.bind result next in
  let rec loop index accumulator =
    if index < 0 then Ok accumulator
    else
      let* () = checkpoint state in
      let* () = charge state 1 in
      let candidate = Z.add coefficients.(index) (Z.mul point accumulator) in
      let* candidate = guard_integer state "evaluation" candidate in
      loop (index - 1) candidate
  in
  loop (Array.length coefficients - 1) Z.zero

let point_of_index index =
  if index = 0 then Z.zero
  else
    let magnitude = (index + 1) / 2 in
    if index mod 2 = 1 then Z.of_int magnitude else Z.of_int (-magnitude)

let choose_points state coefficients count =
  let ( let* ) result next = Result.bind result next in
  let rec loop index reversed =
    if List.length reversed >= count then Ok (Array.of_list (List.rev reversed))
    else
      let magnitude = if index = 0 then 0 else (index + 1) / 2 in
      if magnitude > state.limits.max_point_abs then
        Error
          (Resource_limit
             "polynomial factorization cannot complete the evaluation-point search within its limit")
      else
        let point = point_of_index index in
        let* value = evaluate_z state coefficients point in
        if Z.equal value Z.zero then loop (index + 1) reversed
        else loop (index + 1) ((point, value) :: reversed)
  in
  loop 0 []

let signed_divisors state value =
  let ( let* ) result next = Result.bind result next in
  if Z.equal value Z.zero then
    Error
      (Internal_factorization_error
         "Kronecker divisor enumeration received a zero evaluation")
  else
    let magnitude = Z.abs value in
    let rec trials divisor positives =
      if Z.gt (Z.mul divisor divisor) magnitude then Ok positives
      else if state.divisor_trials >= state.limits.max_divisor_trials then
        Error
          (Resource_limit
             "polynomial factorization exceeds the exact divisor-trial limit")
      else
        let* () = checkpoint state in
        let* () = charge state 1 in
        state.divisor_trials <- state.divisor_trials + 1;
        if Z.equal (Z.rem magnitude divisor) Z.zero then
          let quotient = Z.divexact magnitude divisor in
          let positives =
            if Z.equal quotient divisor then divisor :: positives
            else quotient :: divisor :: positives
          in
          if List.length positives * 2 > state.limits.max_divisors_per_value then
            Error
              (Resource_limit
                 "polynomial factorization exceeds the retained-divisor limit")
          else trials (Z.succ divisor) positives
        else trials (Z.succ divisor) positives
    in
    let* positives = trials Z.one [] in
    let positives = List.sort_uniq Z.compare positives in
    let signed =
      List.sort_uniq Z.compare
        (List.rev_append (List.map Z.neg positives) positives)
    in
    if List.length signed > state.limits.max_divisors_per_value then
      Error
        (Resource_limit
           "polynomial factorization exceeds the retained-divisor limit")
    else Ok signed

let multiply_dense_by_linear state coefficients root =
  let ( let* ) result next = Result.bind result next in
  let result = Array.make (Array.length coefficients + 1) Q.zero in
  let root_q = Q.of_bigint root in
  let rec loop index =
    if index >= Array.length coefficients then Ok result
    else
      let* () = checkpoint state in
      let* () = charge state 2 in
      let coefficient = coefficients.(index) in
      let constant_part = Q.neg (Q.mul root_q coefficient) in
      let lower = Q.add result.(index) constant_part in
      let upper = Q.add result.(index + 1) coefficient in
      let* lower = guard_rational state "interpolation coefficient" lower in
      let* upper = guard_rational state "interpolation coefficient" upper in
      result.(index) <- lower;
      result.(index + 1) <- upper;
      loop (index + 1)
  in
  loop 0

let interpolate state points values =
  let ( let* ) result next = Result.bind result next in
  let count = Array.length points in
  if Array.length values <> count then
    Error (Internal_factorization_error "Kronecker interpolation arity mismatch")
  else
    let result = Array.make count Q.zero in
    let rec basis_for i j basis denominator =
      if j >= count then Ok (basis, denominator)
      else if i = j then basis_for i (j + 1) basis denominator
      else
        let xi, _ = points.(i) in
        let xj, _ = points.(j) in
        let difference = Z.sub xi xj in
        let* denominator =
          guard_integer state "interpolation denominator"
            (Z.mul denominator difference)
        in
        let* basis = multiply_dense_by_linear state basis xj in
        basis_for i (j + 1) basis denominator
    in
    let rec add_basis i =
      if i >= count then Ok result
      else
        let* () = checkpoint state in
        let* () = charge state 1 in
        let* basis, denominator = basis_for i 0 [| Q.one |] Z.one in
        if Z.equal denominator Z.zero then
          Error
            (Internal_factorization_error
               "Kronecker interpolation observed duplicate points")
        else
          let scalar = Q.make values.(i) denominator in
          let* scalar = guard_rational state "interpolation scalar" scalar in
          let rec add index =
            if index >= Array.length basis then Ok ()
            else
              let* () = checkpoint state in
              let* () = charge state 1 in
              let candidate =
                Q.add result.(index) (Q.mul scalar basis.(index))
              in
              let* candidate =
                guard_rational state "interpolation result" candidate
              in
              result.(index) <- candidate;
              add (index + 1)
          in
          let* () = add 0 in
          add_basis (i + 1)
    in
    add_basis 0

let primitive_integer_candidate state expected_degree rational =
  let ( let* ) result next = Result.bind result next in
  let integers = Array.make (Array.length rational) Z.zero in
  let rec convert index =
    if index >= Array.length rational then Ok ()
    else
      let* () = checkpoint state in
      let* () = charge state 1 in
      let coefficient = rational.(index) in
      if not (Z.equal (Q.den coefficient) Z.one) then Ok ()
      else begin
        integers.(index) <- Q.num coefficient;
        convert (index + 1)
      end
  in
  let* () = convert 0 in
  if
    Array.exists
      (fun coefficient -> not (Z.equal (Q.den coefficient) Z.one))
      rational
  then Ok None
  else
    let integers = trim_z integers in
    if degree_z integers <> expected_degree then Ok None
    else
      let* gcd = gcd_coefficients state integers in
      if not (Z.equal gcd Z.one) then Ok None
      else
        let leading = integers.(Array.length integers - 1) in
        if Z.sign leading > 0 then Ok (Some integers)
        else begin
          Array.iteri (fun index value -> integers.(index) <- Z.neg value) integers;
          Ok (Some integers)
        end

let exact_divide_z state variable dividend divisor =
  let ( let* ) result next = Result.bind result next in
  let* dividend_polynomial = polynomial_of_z state variable dividend in
  let* divisor_polynomial = polynomial_of_z state variable divisor in
  let* division =
    Centl_polynomial_division.divide_with_state state.core ~variable
      dividend_polynomial divisor_polynomial
    |> lift_division
  in
  if not (is_zero division.remainder) then Ok None
  else
    let* quotient = integral_dense_of_polynomial state variable division.quotient in
    if Array.length quotient = 0 then Ok None
    else
      let* primitive = positive_primitive state quotient in
      if primitive then Ok (Some quotient) else Ok None

let candidate_tick state =
  let ( let* ) result next = Result.bind result next in
  if state.candidates >= state.limits.max_candidates then
    Error
      (Resource_limit
         "polynomial factorization exceeds the interpolation-candidate limit")
  else
    let* () = checkpoint state in
    let* () = charge state 1 in
    state.candidates <- state.candidates + 1;
    Ok ()

let find_factor_of_degree state variable coefficients target_degree =
  let ( let* ) result next = Result.bind result next in
  let* points = choose_points state coefficients (target_degree + 1) in
  let divisor_lists = Array.make (Array.length points) [] in
  let rec build_divisors index =
    if index >= Array.length points then Ok ()
    else
      let _, value = points.(index) in
      let* divisors = signed_divisors state value in
      divisor_lists.(index) <- divisors;
      build_divisors (index + 1)
  in
  let* () = build_divisors 0 in
  let chosen = Array.make (Array.length points) Z.zero in
  let rec enumerate index =
    if index >= Array.length points then
      let* () = candidate_tick state in
      let* rational = interpolate state points chosen in
      let* candidate =
        primitive_integer_candidate state target_degree rational
      in
      begin match candidate with
      | None -> Ok None
      | Some divisor ->
          let* quotient = exact_divide_z state variable coefficients divisor in
          begin match quotient with
          | None -> Ok None
          | Some quotient -> Ok (Some (divisor, quotient))
          end
      end
    else
      let rec try_values = function
        | [] -> Ok None
        | value :: rest ->
            let* () = checkpoint state in
            let* () = charge state 1 in
            chosen.(index) <- value;
            let* found = enumerate (index + 1) in
            begin match found with
            | Some _ -> Ok found
            | None -> try_values rest
            end
      in
      try_values divisor_lists.(index)
  in
  enumerate 0

let find_nontrivial_factor state variable coefficients =
  let ( let* ) result next = Result.bind result next in
  let degree = degree_z coefficients in
  let rec search target_degree =
    if target_degree > degree / 2 then Ok None
    else
      let* found = find_factor_of_degree state variable coefficients target_degree in
      match found with
      | Some _ -> Ok found
      | None -> search (target_degree + 1)
  in
  search 1

let compare_z_array left right =
  let left = trim_z left in
  let right = trim_z right in
  let degree_compare = Int.compare (Array.length left) (Array.length right) in
  if degree_compare <> 0 then degree_compare
  else
    let rec loop index =
      if index < 0 then 0
      else
        let comparison = Z.compare left.(index) right.(index) in
        if comparison <> 0 then comparison else loop (index - 1)
    in
    loop (Array.length left - 1)

let equal_z_array left right = compare_z_array left right = 0

let factor_primitive state variable primitive =
  let ( let* ) result next = Result.bind result next in
  let rec factor coefficients =
    let degree = degree_z coefficients in
    if degree <= 0 then Ok []
    else if degree = 1 then
      if state.terminal_factors >= state.limits.max_factors then
        Error (Resource_limit "polynomial factorization exceeds the factor-count limit")
      else begin
        state.terminal_factors <- state.terminal_factors + 1;
        Ok [ coefficients ]
      end
    else
      let* found = find_nontrivial_factor state variable coefficients in
      match found with
      | None ->
          if state.terminal_factors >= state.limits.max_factors then
            Error
              (Resource_limit
                 "polynomial factorization exceeds the factor-count limit")
          else begin
            state.terminal_factors <- state.terminal_factors + 1;
            Ok [ coefficients ]
          end
      | Some (left, right) ->
          let* left_factors = factor left in
          let* right_factors = factor right in
          Ok (List.rev_append (List.rev left_factors) right_factors)
  in
  factor primitive

let monic_polynomial_of_z state variable coefficients =
  let ( let* ) result next = Result.bind result next in
  let coefficients = trim_z coefficients in
  if Array.length coefficients = 0 then
    Error (Internal_factorization_error "cannot normalize a zero terminal factor")
  else
    let leading = coefficients.(Array.length coefficients - 1) in
    if Z.equal leading Z.zero then
      Error (Internal_factorization_error "terminal factor has zero leading coefficient")
    else
      let rec loop index result =
        if index >= Array.length coefficients then guard_polynomial state "factor" result
        else
          let* () = checkpoint state in
          let* () = charge state 1 in
          let coefficient = Q.make coefficients.(index) leading in
          let* coefficient = guard_rational state "monic factor coefficient" coefficient in
          let result =
            if Q.equal coefficient Q.zero then result
            else
              let monomial = if index = 0 then [] else [ (variable, index) ] in
              add_term coefficient monomial result
          in
          loop (index + 1) result
      in
      loop 0 zero

let group_terminal_factors state variable terminals =
  let ( let* ) result next = Result.bind result next in
  let sorted = List.sort compare_z_array terminals in
  let rec groups current multiplicity accumulated = function
    | [] ->
        begin match current with
        | None -> Ok (List.rev accumulated)
        | Some coefficients ->
            let* polynomial = monic_polynomial_of_z state variable coefficients in
            Ok (List.rev ({ polynomial; multiplicity } :: accumulated))
        end
    | coefficients :: rest ->
        begin match current with
        | None -> groups (Some coefficients) 1 accumulated rest
        | Some current_coefficients
          when equal_z_array current_coefficients coefficients ->
            groups current (multiplicity + 1) accumulated rest
        | Some current_coefficients ->
            let* polynomial =
              monic_polynomial_of_z state variable current_coefficients
            in
            groups (Some coefficients) 1
              ({ polynomial; multiplicity } :: accumulated) rest
        end
  in
  groups None 0 [] sorted

let multiply_bounded state label left right =
  let ( let* ) result next = Result.bind result next in
  let right_terms = bindings right in
  let rec outer result = function
    | [] -> guard_polynomial state label result
    | (left_monomial, left_coefficient) :: left_rest ->
        let rec inner result = function
          | [] -> outer result left_rest
          | (right_monomial, right_coefficient) :: right_rest ->
              let* () = checkpoint state in
              let* () = charge state 1 in
              begin match monomial_multiply left_monomial right_monomial with
              | Error error -> Error (Polynomial_error error)
              | Ok monomial ->
                  let coefficient = Q.mul left_coefficient right_coefficient in
                  let result = add_term coefficient monomial result in
                  let* result = guard_polynomial state label result in
                  inner result right_rest
              end
        in
        inner result right_terms
  in
  outer zero (bindings left)

let power_bounded state polynomial exponent =
  let ( let* ) result next = Result.bind result next in
  let rec loop remaining accumulator =
    if remaining = 0 then Ok accumulator
    else
      let* accumulator =
        multiply_bounded state "reconstruction" accumulator polynomial
      in
      loop (remaining - 1) accumulator
  in
  loop exponent one

let verify_reconstruction state original unit factors =
  let ( let* ) result next = Result.bind result next in
  let rec loop accumulator = function
    | [] -> Ok (equal accumulator original)
    | factor :: rest ->
        let* powered = power_bounded state factor.polynomial factor.multiplicity in
        let* accumulator =
          multiply_bounded state "reconstruction" accumulator powered
        in
        loop accumulator rest
  in
  let* reconstructed = loop (constant unit) factors in
  if reconstructed then Ok ()
  else
    Error
      (Internal_factorization_error
         "polynomial factorization failed its exact reconstruction check")

let factorize ?(limits = default_limits) ?(cancelled = never_cancelled)
    ~variable polynomial =
  let ( let* ) result next = Result.bind result next in
  if String.equal variable "" then Error Empty_variable
  else if not (valid_limits limits) then
    Error (Resource_limit "polynomial factorization limits are invalid")
  else
    let state = make_state limits cancelled in
    let* () = checkpoint state in
    let* polynomial = guard_polynomial state "input" polynomial in
    let* polynomial = validate_univariate state variable polynomial in
    if is_zero polynomial then Error Zero_polynomial
    else
      let* leading = leading_term state variable polynomial in
      match leading with
      | None -> Error Zero_polynomial
      | Some (degree, unit) ->
          if degree > limits.max_degree then
            Error
              (Resource_limit
                 "polynomial factorization exceeds the admitted degree limit")
          else if degree = 0 then Ok { unit; factors = [] }
          else
            let* rational_coefficients =
              dense_q_of_polynomial state variable degree polynomial
            in
            let* primitive =
              primitive_integer_coefficients state rational_coefficients
            in
            let* terminal_factors = factor_primitive state variable primitive in
            let* factors =
              group_terminal_factors state variable terminal_factors
            in
            let* () = verify_reconstruction state polynomial unit factors in
            Ok { unit; factors }
