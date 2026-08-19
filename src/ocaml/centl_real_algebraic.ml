type error =
  | Zero_polynomial
  | Constant_polynomial
  | Invalid_interval
  | Endpoint_is_root
  | Non_square_free
  | Root_count_mismatch of int

type t = {
  polynomial : Z.t array;
  lower : Q.t;
  upper : Q.t;
}

type refinement = Rational_root of Q.t | Isolating_interval of t

type qpoly = Q.t array

let error_message = function
  | Zero_polynomial -> "defining polynomial must be nonzero"
  | Constant_polynomial -> "defining polynomial must be nonconstant"
  | Invalid_interval -> "isolating interval must satisfy lower < upper"
  | Endpoint_is_root -> "isolating interval endpoints must not be roots"
  | Non_square_free -> "defining polynomial must be square-free"
  | Root_count_mismatch count ->
      Printf.sprintf "isolating interval contains %d distinct real roots, expected 1" count

let trim_z coefficients =
  let rec last_nonzero index =
    if index < 0 then -1
    else if Z.equal coefficients.(index) Z.zero then last_nonzero (index - 1)
    else index
  in
  let last = last_nonzero (Array.length coefficients - 1) in
  if last < 0 then [||] else Array.sub coefficients 0 (last + 1)

let trim_q coefficients =
  let rec last_nonzero index =
    if index < 0 then -1
    else if Q.equal coefficients.(index) Q.zero then last_nonzero (index - 1)
    else index
  in
  let last = last_nonzero (Array.length coefficients - 1) in
  if last < 0 then [||] else Array.sub coefficients 0 (last + 1)

let degree_z polynomial = Array.length polynomial - 1
let degree_q polynomial = Array.length polynomial - 1
let is_zero_q polynomial = Array.length polynomial = 0

let normalize_integer_polynomial coefficients =
  let coefficients = trim_z (Array.copy coefficients) in
  if Array.length coefficients = 0 then Error Zero_polynomial
  else if Array.length coefficients = 1 then Error Constant_polynomial
  else
    let content =
      Array.fold_left
        (fun gcd coefficient -> Z.gcd gcd (Z.abs coefficient))
        Z.zero coefficients
    in
    let content = if Z.equal content Z.zero then Z.one else content in
    let primitive = Array.map (fun coefficient -> Z.divexact coefficient content) coefficients in
    let leading = primitive.(Array.length primitive - 1) in
    let primitive =
      if Z.sign leading < 0 then Array.map Z.neg primitive else primitive
    in
    Ok primitive

let qpoly_of_z polynomial = Array.map Q.of_bigint polynomial

let derivative polynomial =
  if Array.length polynomial <= 1 then [||]
  else
    Array.init (Array.length polynomial - 1) (fun index ->
        Q.mul (Q.of_int (index + 1)) polynomial.(index + 1))
    |> trim_q

let monic polynomial =
  let polynomial = trim_q polynomial in
  if is_zero_q polynomial then polynomial
  else
    let leading = polynomial.(Array.length polynomial - 1) in
    Array.map (fun coefficient -> Q.div coefficient leading) polynomial

let remainder numerator divisor =
  let divisor = trim_q divisor in
  if is_zero_q divisor then invalid_arg "polynomial remainder by zero"
  else
    let remainder = ref (trim_q (Array.copy numerator)) in
    let divisor_degree = degree_q divisor in
    let divisor_leading = divisor.(divisor_degree) in
    while not (is_zero_q !remainder) && degree_q !remainder >= divisor_degree do
      let remainder_degree = degree_q !remainder in
      let shift = remainder_degree - divisor_degree in
      let factor = Q.div (!remainder).(remainder_degree) divisor_leading in
      let updated = Array.copy !remainder in
      for i = 0 to divisor_degree do
        let index = i + shift in
        updated.(index) <- Q.sub updated.(index) (Q.mul factor divisor.(i))
      done;
      remainder := trim_q updated
    done;
    !remainder

let gcd_q left right =
  let rec loop left right =
    let left = trim_q left in
    let right = trim_q right in
    if is_zero_q right then monic left
    else loop right (remainder left right)
  in
  loop left right

let is_square_free polynomial =
  let qpoly = qpoly_of_z polynomial in
  let derivative = derivative qpoly in
  let gcd = gcd_q qpoly derivative in
  degree_q gcd = 0

let negate_qpoly polynomial = Array.map Q.neg polynomial

let sturm_sequence polynomial =
  let p0 = qpoly_of_z polynomial |> trim_q in
  let p1 = derivative p0 in
  let rec build reversed previous current =
    if is_zero_q current then List.rev reversed
    else
      let next = remainder previous current |> negate_qpoly |> trim_q in
      build (current :: reversed) current next
  in
  build [ p0 ] p0 p1

let evaluate_q polynomial x =
  let value = ref Q.zero in
  for i = Array.length polynomial - 1 downto 0 do
    value := Q.add (Q.mul !value x) polynomial.(i)
  done;
  !value

let evaluate_z polynomial x = evaluate_q (qpoly_of_z polynomial) x

let sign_of_q value =
  let sign = Q.sign value in
  if sign < 0 then -1 else if sign > 0 then 1 else 0

let variations_at sequence x =
  let rec loop previous_sign variations = function
    | [] -> variations
    | polynomial :: rest ->
        let sign = evaluate_q polynomial x |> sign_of_q in
        if sign = 0 then loop previous_sign variations rest
        else
          let variations =
            match previous_sign with
            | None -> variations
            | Some previous when previous <> sign -> variations + 1
            | Some _ -> variations
          in
          loop (Some sign) variations rest
  in
  loop None 0 sequence

let root_count_with_sequence sequence lower upper =
  variations_at sequence lower - variations_at sequence upper

let root_count polynomial lower upper =
  if Q.compare lower upper >= 0 then Error Invalid_interval
  else
    match normalize_integer_polynomial polynomial with
    | Error _ as error -> error
    | Ok polynomial ->
        if Q.equal (evaluate_z polynomial lower) Q.zero
           || Q.equal (evaluate_z polynomial upper) Q.zero
        then Error Endpoint_is_root
        else
          let sequence = sturm_sequence polynomial in
          Ok (root_count_with_sequence sequence lower upper)

let make ~polynomial ~lower ~upper =
  if Q.compare lower upper >= 0 then Error Invalid_interval
  else
    match normalize_integer_polynomial polynomial with
    | Error _ as error -> error
    | Ok polynomial ->
        if Q.equal (evaluate_z polynomial lower) Q.zero
           || Q.equal (evaluate_z polynomial upper) Q.zero
        then Error Endpoint_is_root
        else if not (is_square_free polynomial) then Error Non_square_free
        else
          let sequence = sturm_sequence polynomial in
          let count = root_count_with_sequence sequence lower upper in
          if count <> 1 then Error (Root_count_mismatch count)
          else Ok { polynomial; lower; upper }

let width certificate = Q.sub certificate.upper certificate.lower

let polynomial_equal left right =
  Array.length left = Array.length right
  &&
  let equal = ref true in
  let index = ref 0 in
  while !equal && !index < Array.length left do
    if not (Z.equal left.(!index) right.(!index)) then equal := false;
    incr index
  done;
  !equal

let equal_certificate left right =
  polynomial_equal left.polynomial right.polynomial
  && Q.equal left.lower right.lower
  && Q.equal left.upper right.upper

let refine_once certificate =
  let midpoint = Q.div (Q.add certificate.lower certificate.upper) (Q.of_int 2) in
  if Q.equal (evaluate_z certificate.polynomial midpoint) Q.zero then
    Rational_root midpoint
  else
    let sequence = sturm_sequence certificate.polynomial in
    let left_count =
      root_count_with_sequence sequence certificate.lower midpoint
    in
    if left_count = 1 then
      Isolating_interval { certificate with upper = midpoint }
    else
      Isolating_interval { certificate with lower = midpoint }

let rec refine certificate steps =
  if steps < 0 then invalid_arg "refinement steps must be nonnegative"
  else if steps = 0 then Isolating_interval certificate
  else
    match refine_once certificate with
    | Rational_root _ as exact -> exact
    | Isolating_interval certificate -> refine certificate (steps - 1)

let coefficient_text coefficient = Z.to_string coefficient

let polynomial_text polynomial =
  polynomial
  |> Array.to_list
  |> List.mapi (fun exponent coefficient -> (exponent, coefficient))
  |> List.filter (fun (_, coefficient) -> not (Z.equal coefficient Z.zero))
  |> List.rev
  |> List.map (fun (exponent, coefficient) ->
         if exponent = 0 then coefficient_text coefficient
         else if exponent = 1 then coefficient_text coefficient ^ "*x"
         else Printf.sprintf "%s*x^%d" (coefficient_text coefficient) exponent)
  |> String.concat " + "

let rational_text value =
  let numerator = Q.num value in
  let denominator = Q.den value in
  if Z.equal denominator Z.one then Z.to_string numerator
  else Z.to_string numerator ^ "/" ^ Z.to_string denominator

let text certificate =
  Printf.sprintf "root(%s, %s < x < %s)" (polynomial_text certificate.polynomial)
    (rational_text certificate.lower) (rational_text certificate.upper)

let exact_bits certificate =
  let polynomial_bits =
    Array.fold_left
      (fun total coefficient -> total + Z.numbits (Z.abs coefficient))
      0 certificate.polynomial
  in
  let qbits value = Z.numbits (Z.abs (Q.num value)) + Z.numbits (Q.den value) in
  polynomial_bits + qbits certificate.lower + qbits certificate.upper
