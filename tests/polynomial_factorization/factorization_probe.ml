open Centl_multivariate_polynomial
open Centl_polynomial_factorization

let fail message =
  prerr_endline message;
  exit 2

let q text =
  try Q.of_string text
  with Invalid_argument _ | Failure _ -> fail ("invalid rational coefficient: " ^ text)

let split_coefficients text =
  if String.equal text "" then [] else String.split_on_char ',' text

let polynomial_of_dense text =
  split_coefficients text
  |> List.mapi (fun exponent encoded ->
         let coefficient = q encoded in
         if Q.equal coefficient Q.zero then zero
         else if exponent = 0 then constant coefficient
         else
           match term coefficient [ ("x", exponent) ] with
           | Ok polynomial -> polynomial
           | Error error -> fail (Centl_multivariate_polynomial.error_message error))
  |> List.fold_left add zero

let qtext value =
  Printf.sprintf "%s/%s" (Z.to_string (Q.num value)) (Z.to_string (Q.den value))

let exponent_of_monomial monomial =
  match List.assoc_opt "x" monomial with None -> 0 | Some exponent -> exponent

let dense_coefficients polynomial =
  let terms = bindings polynomial in
  let degree =
    List.fold_left
      (fun maximum (monomial, _) -> max maximum (exponent_of_monomial monomial))
      0 terms
  in
  let coefficients = Array.make (degree + 1) Q.zero in
  List.iter
    (fun (monomial, coefficient) ->
      coefficients.(exponent_of_monomial monomial) <- coefficient)
    terms;
  Array.to_list coefficients |> List.map (fun value -> `String (qtext value))

let factor_json (factor : Centl_polynomial_factorization.factor) =
  `Assoc
    [
      ("multiplicity", `Int factor.multiplicity);
      ("coefficients", `List (dense_coefficients factor.polynomial));
    ]

let result_json result =
  `Assoc
    [
      ("unit", `String (qtext result.unit));
      ("factors", `List (List.map factor_json result.factors));
    ]

let () =
  match Array.to_list Sys.argv with
  | [ _; coefficients ] ->
      begin match factorize ~variable:"x" (polynomial_of_dense coefficients) with
      | Ok result -> Yojson.Safe.to_channel stdout (result_json result); print_newline ()
      | Error error -> fail (Centl_polynomial_factorization.error_message error)
      end
  | _ -> fail "usage: factorization_probe COEFF0,COEFF1,..."
