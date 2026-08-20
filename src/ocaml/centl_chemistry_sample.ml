type error =
  | Empty_sample
  | Too_many_observations
  | Invalid_observation of string
  | Unknown_unit of string

type observation_class = Measured | Declared_exact

type root_value = Exact_rational of Q.t | Exact_sqrt_rational of Q.t

type derived_root = Available of root_value | Undefined of string

type summary = {
  unit_symbol : string;
  observation_class : observation_class;
  observations : Q.t list;
  n : int;
  sum : Q.t;
  sum_squares : Q.t;
  mean : Q.t;
  median : Q.t;
  minimum : Q.t;
  maximum : Q.t;
  range : Q.t;
  median_absolute_deviation : Q.t;
  population_variance : Q.t;
  population_standard_deviation : root_value;
  sample_variance : Q.t option;
  sample_standard_deviation : derived_root;
  standard_error_of_mean : derived_root;
  relative_standard_deviation : derived_root;
}

let max_observations = 10000

let observation_class_to_string = function
  | Measured -> "measured"
  | Declared_exact -> "declared_exact"

let error_message = function
  | Empty_sample -> "sample must contain at least one observation"
  | Too_many_observations -> "sample exceeds the bounded observation limit"
  | Invalid_observation text -> Printf.sprintf "invalid reported observation %S" text
  | Unknown_unit symbol -> Printf.sprintf "unknown sample unit %s" symbol

let parse_q text =
  try
    let value = Q.of_string text in
    if Z.equal (Q.den value) Z.zero then raise (Invalid_argument text);
    value
  with Invalid_argument _ | Failure _ | Division_by_zero ->
    raise (Invalid_argument text)

let q_of_int value = Q.of_bigint (Z.of_int value)
let q_abs value = if Q.compare value Q.zero < 0 then Q.neg value else value
let q_square value = Q.mul value value

let exact_sqrt value =
  if Q.compare value Q.zero < 0 then invalid_arg "exact_sqrt"
  else
    let numerator = Q.num value in
    let denominator = Q.den value in
    let numerator_root = Z.sqrt numerator in
    let denominator_root = Z.sqrt denominator in
    if
      Z.equal (Z.mul numerator_root numerator_root) numerator
      && Z.equal (Z.mul denominator_root denominator_root) denominator
    then Exact_rational (Q.make numerator_root denominator_root)
    else Exact_sqrt_rational value

let median_sorted sorted =
  let count = Array.length sorted in
  if count = 0 then invalid_arg "median_sorted"
  else if count mod 2 = 1 then sorted.(count / 2)
  else
    Q.div
      (Q.add sorted.((count / 2) - 1) sorted.(count / 2))
      (q_of_int 2)

let variance_about ~center ~denominator values =
  let total =
    List.fold_left
      (fun acc value -> Q.add acc (q_square (Q.sub value center)))
      Q.zero values
  in
  Q.div total (q_of_int denominator)

let summarize_values ?(observation_class = Measured) ~unit_symbol values =
  let n = List.length values in
  if n = 0 then Error Empty_sample
  else if n > max_observations then Error Too_many_observations
  else
    match Centl_physics.unit_of_symbol unit_symbol with
    | None -> Error (Unknown_unit unit_symbol)
    | Some _ ->
        let sorted = Array.of_list values in
        Array.sort Q.compare sorted;
        let sum = List.fold_left Q.add Q.zero values in
        let sum_squares =
          List.fold_left (fun acc value -> Q.add acc (q_square value)) Q.zero values
        in
        let mean = Q.div sum (q_of_int n) in
        let median = median_sorted sorted in
        let minimum = sorted.(0) in
        let maximum = sorted.(n - 1) in
        let range = Q.sub maximum minimum in
        let deviations =
          List.map (fun value -> q_abs (Q.sub value median)) values |> Array.of_list
        in
        Array.sort Q.compare deviations;
        let median_absolute_deviation = median_sorted deviations in
        let population_variance = variance_about ~center:mean ~denominator:n values in
        let population_standard_deviation = exact_sqrt population_variance in
        let sample_variance =
          if n < 2 then None
          else Some (variance_about ~center:mean ~denominator:(n - 1) values)
        in
        let sample_standard_deviation =
          match sample_variance with
          | None -> Undefined "requires_at_least_two_observations"
          | Some variance -> Available (exact_sqrt variance)
        in
        let standard_error_of_mean =
          match sample_variance with
          | None -> Undefined "requires_at_least_two_observations"
          | Some variance -> Available (exact_sqrt (Q.div variance (q_of_int n)))
        in
        let relative_standard_deviation =
          if Q.equal mean Q.zero then Undefined "mean_is_zero"
          else
            match sample_variance with
            | None -> Undefined "requires_at_least_two_observations"
            | Some variance ->
                Available (exact_sqrt (Q.div variance (q_square (q_abs mean))))
        in
        Ok
          {
            unit_symbol;
            observation_class;
            observations = values;
            n;
            sum;
            sum_squares;
            mean;
            median;
            minimum;
            maximum;
            range;
            median_absolute_deviation;
            population_variance;
            population_standard_deviation;
            sample_variance;
            sample_standard_deviation;
            standard_error_of_mean;
            relative_standard_deviation;
          }

let summarize_strings ?(observation_class = Measured) ~unit_symbol texts =
  if texts = [] then Error Empty_sample
  else if List.length texts > max_observations then Error Too_many_observations
  else
    let rec parse reversed = function
      | [] ->
          summarize_values ~observation_class ~unit_symbol (List.rev reversed)
      | text :: rest ->
          let value =
            try Ok (parse_q text) with Invalid_argument _ -> Error (Invalid_observation text)
          in
          begin
            match value with
            | Error _ as error -> error
            | Ok parsed -> parse (parsed :: reversed) rest
          end
    in
    parse [] texts

let root_to_string = function
  | Exact_rational value -> Q.to_string value
  | Exact_sqrt_rational radicand -> "sqrt(" ^ Q.to_string radicand ^ ")"

let derived_root_to_string = function
  | Available value -> root_to_string value
  | Undefined reason -> "undefined(" ^ reason ^ ")"
