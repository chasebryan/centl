module String_map = Map.Make (String)
module String_set = Set.Make (String)

type monomial = (string * int) list

module Monomial_order = struct
  type t = monomial

  let compare = Stdlib.compare
end

module Monomial_map = Map.Make (Monomial_order)

type t = Q.t Monomial_map.t

type error =
  | Empty_variable
  | Negative_exponent of string * int
  | Exponent_overflow of string
  | Total_degree_overflow
  | Undefined_zero_power
  | Negative_power of int
  | Duplicate_substitution of string

let error_message = function
  | Empty_variable -> "polynomial variable names must not be empty"
  | Negative_exponent (variable, exponent) ->
      Printf.sprintf "polynomial exponent for %s must be nonnegative, got %d"
        variable exponent
  | Exponent_overflow variable ->
      "polynomial exponent overflow for variable " ^ variable
  | Total_degree_overflow ->
      "polynomial total degree exceeds the exact integer representation limit"
  | Undefined_zero_power -> "zero polynomial to the zero power is undefined"
  | Negative_power exponent ->
      Printf.sprintf
        "negative polynomial power %d leaves the polynomial ring" exponent
  | Duplicate_substitution variable ->
      "duplicate rational substitution for variable " ^ variable

let zero = Monomial_map.empty
let is_zero polynomial = Monomial_map.is_empty polynomial

let safe_exponent_add variable left right =
  if right > max_int - left then Error (Exponent_overflow variable)
  else Ok (left + right)

let validate_total_degree powers =
  let ( let* ) result next = Result.bind result next in
  let rec total degree = function
    | [] -> Ok degree
    | (_, exponent) :: rest ->
        if exponent > max_int - degree then Error Total_degree_overflow
        else total (degree + exponent) rest
  in
  let* _ = total 0 powers in
  Ok powers

let normalize_monomial powers =
  let ( let* ) result next = Result.bind result next in
  let rec collect map = function
    | [] -> Ok map
    | (variable, exponent) :: rest ->
        if String.equal variable "" then Error Empty_variable
        else if exponent < 0 then Error (Negative_exponent (variable, exponent))
        else if exponent = 0 then collect map rest
        else
          let current =
            match String_map.find_opt variable map with
            | None -> 0
            | Some exponent -> exponent
          in
          let* exponent = safe_exponent_add variable current exponent in
          collect (String_map.add variable exponent map) rest
  in
  let* powers = collect String_map.empty powers in
  String_map.bindings powers |> validate_total_degree

let monomial_multiply left right =
  let ( let* ) result next = Result.bind result next in
  let rec merge reversed left right =
    match (left, right) with
    | [], rest | rest, [] -> Ok (List.rev_append reversed rest)
    | ((left_variable, left_exponent) as left_power) :: left_rest,
      ((right_variable, right_exponent) as right_power) :: right_rest ->
        let comparison = String.compare left_variable right_variable in
        if comparison < 0 then merge (left_power :: reversed) left_rest right
        else if comparison > 0 then
          merge (right_power :: reversed) left right_rest
        else
          let* exponent =
            safe_exponent_add left_variable left_exponent right_exponent
          in
          merge ((left_variable, exponent) :: reversed) left_rest right_rest
  in
  let* monomial = merge [] left right in
  validate_total_degree monomial

let add_term coefficient monomial polynomial =
  if Q.equal coefficient Q.zero then polynomial
  else
    let coefficient =
      match Monomial_map.find_opt monomial polynomial with
      | None -> coefficient
      | Some existing -> Q.add existing coefficient
    in
    if Q.equal coefficient Q.zero then Monomial_map.remove monomial polynomial
    else Monomial_map.add monomial coefficient polynomial

let term coefficient powers =
  match normalize_monomial powers with
  | Error _ as error -> error
  | Ok monomial -> Ok (add_term coefficient monomial zero)

let constant coefficient = add_term coefficient [] zero
let one = constant Q.one

let variable name =
  match term Q.one [ (name, 1) ] with
  | Ok polynomial -> Ok polynomial
  | Error _ as error -> error

let equal = Monomial_map.equal Q.equal
let neg polynomial = Monomial_map.map Q.neg polynomial

let scale scalar polynomial =
  if Q.equal scalar Q.zero then zero else Monomial_map.map (Q.mul scalar) polynomial

let add left right =
  Monomial_map.fold
    (fun monomial coefficient result -> add_term coefficient monomial result)
    right left

let sub left right = add left (neg right)

let multiply left right =
  let ( let* ) result next = Result.bind result next in
  let left_terms = Monomial_map.bindings left in
  let right_terms = Monomial_map.bindings right in
  let rec outer result = function
    | [] -> Ok result
    | (left_monomial, left_coefficient) :: rest ->
        let rec inner result = function
          | [] -> Ok result
          | (right_monomial, right_coefficient) :: right_rest ->
              let* monomial = monomial_multiply left_monomial right_monomial in
              let coefficient = Q.mul left_coefficient right_coefficient in
              inner (add_term coefficient monomial result) right_rest
        in
        let* result = inner result right_terms in
        outer result rest
  in
  outer zero left_terms

let rec power_loop base exponent accumulator =
  if exponent = 0 then Ok accumulator
  else
    let ( let* ) result next = Result.bind result next in
    let* accumulator =
      if exponent land 1 = 1 then multiply accumulator base else Ok accumulator
    in
    let exponent = exponent lsr 1 in
    if exponent = 0 then Ok accumulator
    else
      let* base = multiply base base in
      power_loop base exponent accumulator

let power polynomial exponent =
  if exponent < 0 then Error (Negative_power exponent)
  else if exponent = 0 then
    if is_zero polynomial then Error Undefined_zero_power else Ok one
  else power_loop polynomial exponent one

let coefficient polynomial powers =
  match normalize_monomial powers with
  | Error _ as error -> error
  | Ok monomial ->
      Ok
        (match Monomial_map.find_opt monomial polynomial with
        | None -> Q.zero
        | Some coefficient -> coefficient)

let term_count polynomial = Monomial_map.cardinal polynomial
let bindings polynomial = Monomial_map.bindings polynomial

let variables polynomial =
  let variables =
    Monomial_map.fold
      (fun monomial _ variables ->
        List.fold_left
          (fun variables (variable, _) -> String_set.add variable variables)
          variables monomial)
      polynomial String_set.empty
  in
  String_set.elements variables

let monomial_total_degree monomial =
  List.fold_left (fun degree (_, exponent) -> degree + exponent) 0 monomial

let total_degree polynomial =
  if is_zero polynomial then None
  else
    Some
      (Monomial_map.fold
         (fun monomial _ degree -> max degree (monomial_total_degree monomial))
         polynomial 0)

let decrement_power variable monomial =
  let rec loop reversed = function
    | [] -> List.rev reversed
    | (candidate, exponent) :: rest when String.equal candidate variable ->
        if exponent = 1 then List.rev_append reversed rest
        else List.rev_append reversed ((candidate, exponent - 1) :: rest)
    | power :: rest -> loop (power :: reversed) rest
  in
  loop [] monomial

let derivative variable polynomial =
  if String.equal variable "" then Error Empty_variable
  else
    Ok
      (Monomial_map.fold
         (fun monomial coefficient result ->
           match List.assoc_opt variable monomial with
           | None -> result
           | Some exponent ->
               let coefficient = Q.mul coefficient (Q.of_int exponent) in
               add_term coefficient (decrement_power variable monomial) result)
         polynomial zero)

let q_power value exponent =
  let rec loop base exponent accumulator =
    if exponent = 0 then accumulator
    else
      let accumulator =
        if exponent land 1 = 1 then Q.mul accumulator base else accumulator
      in
      let exponent = exponent lsr 1 in
      if exponent = 0 then accumulator
      else loop (Q.mul base base) exponent accumulator
  in
  loop value exponent Q.one

let substitution_map substitutions =
  let rec build map = function
    | [] -> Ok map
    | (variable, value) :: rest ->
        if String.equal variable "" then Error Empty_variable
        else if String_map.mem variable map then
          Error (Duplicate_substitution variable)
        else build (String_map.add variable value map) rest
  in
  build String_map.empty substitutions

let substitute_rationals substitutions polynomial =
  let ( let* ) result next = Result.bind result next in
  let* substitutions = substitution_map substitutions in
  let substitute_term monomial coefficient =
    let rec loop coefficient reversed = function
      | [] -> (coefficient, List.rev reversed)
      | ((variable, exponent) as power) :: rest ->
          begin match String_map.find_opt variable substitutions with
          | None -> loop coefficient (power :: reversed) rest
          | Some value ->
              loop (Q.mul coefficient (q_power value exponent)) reversed rest
          end
    in
    loop coefficient [] monomial
  in
  Ok
    (Monomial_map.fold
       (fun monomial coefficient result ->
         let coefficient, monomial = substitute_term monomial coefficient in
         add_term coefficient monomial result)
       polynomial zero)

let saturating_add left right =
  if left >= max_int || right >= max_int || right > max_int - left then max_int
  else left + right

let exact_bits polynomial =
  Monomial_map.fold
    (fun monomial coefficient total ->
      let coefficient_bits =
        saturating_add
          (Z.numbits (Z.abs (Q.num coefficient)))
          (Z.numbits (Q.den coefficient))
      in
      let exponent_bits =
        List.fold_left
          (fun bits (_, exponent) ->
            saturating_add bits (Z.numbits (Z.of_int exponent)))
          0 monomial
      in
      saturating_add total (saturating_add coefficient_bits exponent_bits))
    polynomial 0
