type kind = Sum | Product

type failure =
  | Invalid_bound of string
  | Resource_limit of string
  | Cancelled
  | Term_error of string * string
  | Core_error of Centl_Core.error

type limits = {
  max_iterations : int;
  max_work : int;
  max_exact_bits : int;
  max_expression_nodes : int;
  max_result_bytes : int;
}

let bits_of_integer value =
  if Z.equal value Z.zero then 1 else Z.numbits (Z.abs value)

let rec expression_nodes = function
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> 1
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      1 + expression_nodes inner
  | Centl_Core.Binary (_, left, right) ->
      1 + expression_nodes left + expression_nodes right
  | Centl_Core.Function (_, arguments) ->
      1
      + List.fold_left
          (fun total argument -> total + expression_nodes argument)
          0 arguments
  | Centl_Core.Substitute (inner, _, replacement) ->
      1 + expression_nodes inner + expression_nodes replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      1 + expression_nodes inner + expression_nodes left
      + expression_nodes right

let bounded_add limit left right =
  if left > limit || right > limit - left then limit + 1 else left + right

let rec expression_exact_bits limit = function
  | Centl_Core.Literal (numerator, denominator) ->
      bounded_add limit
        (bits_of_integer numerator)
        (bits_of_integer denominator)
  | Centl_Core.Symbol _ -> 0
  | Centl_Core.Negate inner
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      expression_exact_bits limit inner
  | Centl_Core.Power (inner, exponent) ->
      bounded_add limit
        (expression_exact_bits limit inner)
        (bits_of_integer exponent)
  | Centl_Core.Binary (_, left, right) ->
      bounded_add limit
        (expression_exact_bits limit left)
        (expression_exact_bits limit right)
  | Centl_Core.Function (_, arguments) ->
      List.fold_left
        (fun total argument ->
          bounded_add limit total (expression_exact_bits limit argument))
        0 arguments
  | Centl_Core.Substitute (inner, _, replacement) ->
      bounded_add limit
        (expression_exact_bits limit inner)
        (expression_exact_bits limit replacement)
  | Centl_Core.Assuming (inner, left, _, right) ->
      bounded_add limit
        (expression_exact_bits limit inner)
        (bounded_add limit
           (expression_exact_bits limit left)
           (expression_exact_bits limit right))

let integer_render_bytes value = String.length (Z.to_string value)

let rec expression_render_bytes limit = function
  | Centl_Core.Literal (numerator, denominator) ->
      bounded_add limit 16
        (bounded_add limit
           (integer_render_bytes numerator)
           (integer_render_bytes denominator))
  | Centl_Core.Symbol name -> bounded_add limit 16 (String.length name)
  | Centl_Core.Negate inner
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      bounded_add limit 16 (expression_render_bytes limit inner)
  | Centl_Core.Power (inner, exponent) ->
      bounded_add limit 16
        (bounded_add limit
           (expression_render_bytes limit inner)
           (integer_render_bytes exponent))
  | Centl_Core.Binary (_, left, right) ->
      bounded_add limit 16
        (bounded_add limit
           (expression_render_bytes limit left)
           (expression_render_bytes limit right))
  | Centl_Core.Function (name, arguments) ->
      List.fold_left
        (fun total argument ->
          bounded_add limit total (expression_render_bytes limit argument))
        (bounded_add limit 16 (String.length name))
        arguments
  | Centl_Core.Substitute (inner, variable, replacement) ->
      bounded_add limit 16
        (bounded_add limit (String.length variable)
           (bounded_add limit
              (expression_render_bytes limit inner)
              (expression_render_bytes limit replacement)))
  | Centl_Core.Assuming (inner, left, _, right) ->
      bounded_add limit 16
        (bounded_add limit
           (expression_render_bytes limit inner)
           (bounded_add limit
              (expression_render_bytes limit left)
              (expression_render_bytes limit right)))

let value_render_bytes limit = function
  | Centl_Core.ExactRational value ->
      bounded_add limit 1
        (bounded_add limit
           (integer_render_bytes value.Centl_Core.numerator)
           (integer_render_bytes value.denominator))
  | Centl_Core.ExactSymbolic expression ->
      expression_render_bytes limit expression

let check_value limits = function
  | Centl_Core.ExactRational value ->
      let bits =
        bits_of_integer value.Centl_Core.numerator
        + bits_of_integer value.denominator
      in
      if bits > limits.max_exact_bits then
        Error
          (Resource_limit
             "the finite iteration exceeds the exact-result bit limit")
      else if
        value_render_bytes limits.max_result_bytes
          (Centl_Core.ExactRational value)
        > limits.max_result_bytes
      then
        Error
          (Resource_limit "the finite iteration exceeds the result-byte limit")
      else Ok ()
  | Centl_Core.ExactSymbolic expression ->
      if expression_nodes expression > limits.max_expression_nodes then
        Error
          (Resource_limit
             "the finite iteration exceeds the symbolic expression-node limit")
      else if
        expression_exact_bits limits.max_exact_bits expression
        > limits.max_exact_bits
      then
        Error
          (Resource_limit
             "the finite iteration exceeds the symbolic exact-value bit limit")
      else if
        expression_render_bytes limits.max_result_bytes expression
        > limits.max_result_bytes
      then
        Error
          (Resource_limit "the finite iteration exceeds the result-byte limit")
      else Ok ()

let evaluate_core expression =
  match Centl_Core.evaluate expression with
  | Centl_Core.Evaluated value -> Ok value
  | Centl_Core.EvaluationFailure error -> Error (Core_error error)

let integer_bound label expression =
  match evaluate_core expression with
  | Ok (Centl_Core.ExactRational value)
    when Z.equal value.Centl_Core.denominator Z.one ->
      Ok value.numerator
  | Ok _ ->
      Error
        (Invalid_bound
           (Printf.sprintf
              "the %s finite-iteration bound must be an exact integer" label))
  | Error error -> Error error

let identity = function
  | Sum -> Centl_Core.ExactRational (Centl_Core.make Z.zero Z.one)
  | Product -> Centl_Core.ExactRational (Centl_Core.make Z.one Z.one)

let operator = function Sum -> Centl_Core.Add | Product -> Centl_Core.Multiply

let combine kind left right =
  match Centl_Core.apply_values (operator kind) left right with
  | Centl_Core.Evaluated value -> Ok value
  | Centl_Core.EvaluationFailure error -> Error (Core_error error)

type partial = { value : Centl_Core.value; nodes : int; bytes : int }

let partial_of_value limits value =
  let ( let* ) result next = Result.bind result next in
  let* () = check_value limits value in
  let nodes =
    match value with
    | Centl_Core.ExactRational _ -> 1
    | Centl_Core.ExactSymbolic expression -> expression_nodes expression
  in
  let bytes = value_render_bytes limits.max_result_bytes value in
  Ok { value; nodes; bytes }

let retained_nodes limit bins =
  List.fold_left
    (fun total -> function
      | None -> total | Some partial -> bounded_add limit total partial.nodes)
    0 bins

let check_retained_nodes limits bins =
  if
    retained_nodes limits.max_expression_nodes bins
    > limits.max_expression_nodes
  then
    Error
      (Resource_limit
         "the finite iteration exceeds the aggregate retained-node limit")
  else Ok ()

let check_retained_bytes limits bins =
  let bytes =
    List.fold_left
      (fun total -> function
        | None -> total
        | Some partial ->
            bounded_add limits.max_result_bytes total partial.bytes)
      0 bins
  in
  if bytes > limits.max_result_bytes then
    Error
      (Resource_limit
         "the finite iteration exceeds the aggregate retained-byte limit")
  else Ok ()

let evaluate ?(cancelled = fun () -> false) ?(evaluate_term = evaluate_core)
    ?(consume = fun _ -> true) ?consume_work limits kind body variable lower
    upper =
  let ( let* ) result next = Result.bind result next in
  let remaining_work = ref limits.max_work in
  let local_consume_work amount =
    if amount < 0 || amount > !remaining_work then false
    else begin
      remaining_work := !remaining_work - amount;
      true
    end
  in
  let consume_work = Option.value consume_work ~default:local_consume_work in
  let work_failure () =
    Error
      (Resource_limit
         "finite-iteration evaluation exceeds the request-wide work limit")
  in
  let combine_partials left right =
    if cancelled () then Error Cancelled
    else
      let* value = combine kind left.value right.value in
      let* partial = partial_of_value limits value in
      if consume_work partial.nodes then Ok partial else work_failure ()
  in
  let rec insert partial = function
    | [] -> Ok [ Some partial ]
    | None :: rest -> Ok (Some partial :: rest)
    | Some left :: rest ->
        let* combined = combine_partials left partial in
        let* rest = insert combined rest in
        Ok (None :: rest)
  in
  let insert_checked partial bins =
    let* bins = insert partial bins in
    let* () = check_retained_nodes limits bins in
    let* () = check_retained_bytes limits bins in
    Ok bins
  in
  let finish bins =
    let rec reduce accumulator = function
      | [] ->
          Ok
            (match accumulator with
            | None -> identity kind
            | Some partial -> partial.value)
      | None :: rest -> reduce accumulator rest
      | Some partial :: rest ->
          begin match accumulator with
          | None -> reduce (Some partial) rest
          | Some left ->
              let* combined = combine_partials left partial in
              reduce (Some combined) rest
          end
    in
    reduce None (List.rev bins)
  in
  if cancelled () then Error Cancelled
  else
    let* lower = integer_bound "lower" lower in
    let* upper = integer_bound "upper" upper in
    let count =
      if Z.gt lower upper then Z.zero else Z.add Z.one (Z.sub upper lower)
    in
    if Z.gt count (Z.of_int limits.max_iterations) then
      Error
        (Resource_limit
           "the finite iteration exceeds the integer-iteration limit")
    else if not (Z.fits_int count) then
      Error
        (Resource_limit
           "the finite iteration range is outside the host iteration limit")
    else if not (consume (Z.to_int count)) then
      Error
        (Resource_limit
           "nested finite iterations exceed the request-wide integer-iteration \
            limit")
    else
      let rec collect current remaining bins =
        if cancelled () then Error Cancelled
        else if remaining = 0 then finish bins
        else
          let term =
            Centl_Core.substitute body variable
              (Centl_Core.Literal (current, Z.one))
          in
          let term_nodes = expression_nodes term in
          let* () =
            if term_nodes > limits.max_expression_nodes then
              Error
                (Resource_limit
                   "a finite-iteration term exceeds the expression-node limit")
            else if consume_work term_nodes then Ok ()
            else work_failure ()
          in
          let* term = evaluate_term term in
          let* partial = partial_of_value limits term in
          let* bins = insert_checked partial bins in
          collect (Z.succ current) (remaining - 1) bins
      in
      collect lower (Z.to_int count) []
