open Centl_multivariate_polynomial
open Centl_polynomial_factorization

let q text = Q.of_string text

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_factorization = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_factorization.error_message error)

let x = unwrap_poly (variable "x")

let multiply_exn left right =
  match multiply left right with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let power_exn polynomial exponent =
  match power polynomial exponent with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let polynomial_of_ints coefficients =
  coefficients
  |> List.mapi (fun exponent coefficient ->
         if coefficient = 0 then zero
         else if exponent = 0 then constant (Q.of_int coefficient)
         else unwrap_poly (term (Q.of_int coefficient) [ ("x", exponent) ]))
  |> List.fold_left add zero

(* Independent irreducibility facts used by this oracle:
   q2a/q2b have discriminant -7, so they have no rational root and are
   irreducible quadratics over Q. c3a is Eisenstein at 2; c3b is Eisenstein at 3. *)
let q2a = polynomial_of_ints [ 2; 1; 1 ]
let q2b = polynomial_of_ints [ 2; -1; 1 ]
let c3a = polynomial_of_ints [ 2; 2; 0; 1 ]
let c3b = polynomial_of_ints [ 3; 3; 0; 1 ]
let l1 = add x (constant (q "-2"))

type expected_factor = {
  polynomial : Centl_multivariate_polynomial.t;
  multiplicity : int;
}

let build unit factors =
  factors
  |> List.fold_left
       (fun result factor ->
         multiply_exn result (power_exn factor.polynomial factor.multiplicity))
       (constant unit)

let reconstruct result =
  result.factors
  |> List.fold_left
       (fun product factor ->
         multiply_exn product (power_exn factor.polynomial factor.multiplicity))
       (constant result.unit)

let find_actual expected factors =
  List.find_opt (fun factor -> equal expected.polynomial factor.polynomial) factors

let check_case index unit expected =
  let source = build unit expected in
  let result = unwrap_factorization (factorize ~variable:"x" source) in
  Alcotest.(check string)
    (Printf.sprintf "unit case %d" index)
    (Q.to_string unit) (Q.to_string result.unit);
  Alcotest.(check int)
    (Printf.sprintf "factor count case %d" index)
    (List.length expected) (List.length result.factors);
  List.iter
    (fun wanted ->
      match find_actual wanted result.factors with
      | None -> Alcotest.failf "missing expected irreducible factor in case %d" index
      | Some actual ->
          Alcotest.(check int)
            (Printf.sprintf "multiplicity case %d" index)
            wanted.multiplicity actual.multiplicity)
    expected;
  Alcotest.(check bool)
    (Printf.sprintf "reconstruction case %d" index)
    true (equal source (reconstruct result))

let ef polynomial multiplicity = { polynomial; multiplicity }

let test_constructed_products () =
  let cases =
    [
      (q "1", [ ef q2a 1 ]);
      (q "-3/5", [ ef q2b 1 ]);
      (q "2", [ ef c3a 1 ]);
      (q "7/3", [ ef c3b 1 ]);
      (q "1", [ ef q2a 1; ef q2b 1 ]);
      (q "-2", [ ef q2a 2 ]);
      (q "5/7", [ ef q2a 1; ef c3a 1 ]);
      (q "3/2", [ ef q2b 1; ef c3b 1 ]);
      (q "1", [ ef c3a 1; ef c3b 1 ]);
      (q "-1/4", [ ef l1 1; ef q2a 1; ef c3a 1 ]);
      (q "9/5", [ ef q2a 2; ef q2b 1 ]);
      (q "-7/11", [ ef l1 2; ef q2b 2 ]);
      (q "4/9", [ ef q2a 1; ef q2b 1; ef c3a 1 ]);
      (q "-5/6", [ ef l1 1; ef c3a 1; ef c3b 1 ]);
      (q "11/13", [ ef q2a 1; ef c3a 2 ]);
      (q "-13/17", [ ef q2b 2; ef c3b 1 ]);
    ]
  in
  List.iteri (fun index (unit, factors) -> check_case (index + 1) unit factors) cases;
  Alcotest.(check int) "constructed oracle cases" 16 (List.length cases)

let () =
  Alcotest.run "centl rational polynomial factorization oracle"
    [
      ( "oracle",
        [
          Alcotest.test_case "16 independently constructed products" `Quick
            test_constructed_products;
        ] );
    ]
