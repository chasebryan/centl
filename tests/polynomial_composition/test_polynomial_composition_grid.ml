open Centl_multivariate_polynomial
open Centl_polynomial_composition

let q = Q.of_int

let unwrap_poly = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_multivariate_polynomial.error_message error)

let unwrap_comp = function
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_polynomial_composition.error_message error)

let termi coefficient powers = unwrap_poly (term (q coefficient) powers)
let variable_i name = unwrap_poly (variable name)
let u = variable_i "u"
let v = variable_i "v"

let rec qpow value exponent accumulator =
  if exponent = 0 then accumulator
  else qpow value (exponent - 1) (Q.mul accumulator value)

let lookup assignment variable =
  match List.assoc_opt variable assignment with
  | Some value -> value
  | None -> Alcotest.fail ("missing oracle assignment for " ^ variable)

let eval assignment polynomial =
  bindings polynomial
  |> List.fold_left
       (fun total (monomial, coefficient) ->
         let term_value =
           List.fold_left
             (fun value (variable, exponent) ->
               Q.mul value (qpow (lookup assignment variable) exponent Q.one))
             coefficient monomial
         in
         Q.add total term_value)
       Q.zero

let check_q message expected actual =
  Alcotest.(check string) message (Q.to_string expected) (Q.to_string actual)

let linear a b variable =
  add (scale (q a) variable) (constant (q b))

let source a b c ex ey =
  add (termi a [ ("x", ex); ("y", ey) ])
    (add (termi b [ ("x", 1) ]) (constant (q c)))

let test_adversarial_grid () =
  let coefficients = [ -3; -1; 1; 2; 5 ] in
  let exponents = [ 1; 2; 3 ] in
  let assignments =
    [
      [ ("u", q (-2)); ("v", q 3) ];
      [
        ("u", Q.make (Z.of_int 1) (Z.of_int 2));
        ("v", q (-1));
      ];
      [
        ("u", Q.make (Z.of_int (-5)) (Z.of_int 3));
        ("v", Q.make (Z.of_int 7) (Z.of_int 4));
      ];
    ]
  in
  let case = ref 0 in
  List.iter
    (fun a ->
      List.iter
        (fun b ->
          List.iter
            (fun exponent ->
              incr case;
              let original =
                source a b 7 exponent ((exponent mod 2) + 1)
              in
              let replacement_x = linear 2 (-1) u in
              let replacement_y =
                add (linear (-1) 3 u) (scale (q 2) v)
              in
              let composed =
                unwrap_comp
                  (compose
                     [ ("x", replacement_x); ("y", replacement_y) ]
                     original)
              in
              List.iteri
                (fun sample target ->
                  let source_assignment =
                    [
                      ("x", eval target replacement_x);
                      ("y", eval target replacement_y);
                    ]
                  in
                  check_q
                    (Printf.sprintf "grid case %d sample %d" !case sample)
                    (eval source_assignment original)
                    (eval target composed))
                assignments)
            exponents)
        coefficients)
    coefficients;
  Alcotest.(check int) "grid cases" 75 !case

let test_large_exact_coefficients () =
  let huge = Z.shift_left Z.one 4_096 in
  let coefficient = Q.make (Z.add huge Z.one) (Z.sub huge Z.one) in
  let source = unwrap_poly (term coefficient [ ("x", 2) ]) in
  let replacement = add u (constant (Q.make Z.one (Z.of_int 3))) in
  let result = unwrap_comp (compose [ ("x", replacement) ] source) in
  let target = [ ("u", Q.make (Z.of_int 5) (Z.of_int 7)) ] in
  check_q "4096-bit exact coefficient"
    (eval [ ("x", eval target replacement) ] source)
    (eval target result)

let () =
  Alcotest.run "centl polynomial composition oracle"
    [
      ( "oracle",
        [
          Alcotest.test_case "75 exact composition cases" `Quick
            test_adversarial_grid;
          Alcotest.test_case "4096-bit coefficient" `Quick
            test_large_exact_coefficients;
        ] );
    ]
