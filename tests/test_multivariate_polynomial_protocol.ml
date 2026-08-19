let assoc name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.fail ("missing JSON field " ^ name)
      end
  | _ -> Alcotest.fail "expected JSON object"

let string name json =
  match assoc name json with
  | `String value -> value
  | _ -> Alcotest.fail ("expected string field " ^ name)

let bool name json =
  match assoc name json with
  | `Bool value -> value
  | _ -> Alcotest.fail ("expected boolean field " ^ name)

let int name json =
  match assoc name json with
  | `Int value -> value
  | _ -> Alcotest.fail ("expected integer field " ^ name)

let power variable exponent =
  `Assoc [ ("variable", `String variable); ("exponent", `Int exponent) ]

let term coefficient powers =
  `Assoc
    [
      ("coefficient", `String coefficient);
      ("powers", `List powers);
    ]

let polynomial terms = `Assoc [ ("terms", `List terms) ]

let request fields =
  Centl_multivariate_polynomial_protocol.handle_json
    (`Assoc (("version", `Int 1) :: fields))

let test_capabilities () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string)
    "kind" "multivariate_polynomial_capabilities" (string "kind" result);
  Alcotest.(check bool) "cooperative cancellation" true
    (bool "cooperative_cancellation" result);
  let limits = assoc "limits" result in
  Alcotest.(check int) "term limit" 4096 (int "max_terms" limits);
  Alcotest.(check int) "dense coefficient limit" 65536
    (int "max_dense_coefficients" limits)

let test_exact_multiply () =
  let left =
    polynomial
      [
        term "1" [ power "x" 1 ];
        term "1" [ power "y" 1 ];
      ]
  in
  let response =
    request
      [
        ("id", `String "square");
        ("action", `String "multiply");
        ("left", left);
        ("right", left);
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "square" (string "id" response);
  let result = assoc "result" response in
  Alcotest.(check string)
    "kind" "multivariate_rational_polynomial" (string "kind" result);
  Alcotest.(check int) "terms" 3 (int "term_count" result);
  Alcotest.(check bool) "exact" true (bool "exact" result)

let test_derivative_and_substitution () =
  let p =
    polynomial
      [
        term "1" [ power "x" 2; power "y" 1 ];
        term "3" [ power "y" 1 ];
        term "2" [ power "x" 1; power "z" 1 ];
      ]
  in
  let derivative =
    request
      [
        ("action", `String "differentiate");
        ("polynomial", p);
        ("variable", `String "x");
      ]
  in
  Alcotest.(check bool) "derivative success" true (bool "ok" derivative);
  Alcotest.(check int) "derivative terms" 2
    (int "term_count" (assoc "result" derivative));
  let substituted =
    request
      [
        ("action", `String "substitute_rationals");
        ("polynomial", p);
        ( "substitutions",
          `List
            [
              `Assoc
                [ ("variable", `String "x"); ("value", `String "2") ];
              `Assoc
                [ ("variable", `String "z"); ("value", `String "-1/2") ];
            ] );
      ]
  in
  Alcotest.(check bool) "substitution success" true (bool "ok" substituted);
  let result = assoc "result" substituted in
  Alcotest.(check int) "substitution terms" 2 (int "term_count" result)

let test_queries () =
  let p =
    polynomial
      [
        term "5/7" [ power "z" 2; power "x" 1 ];
        term "-3" [ power "y" 4 ];
        term "2" [];
      ]
  in
  let coefficient =
    request
      [
        ("action", `String "coefficient");
        ("polynomial", p);
        ("powers", `List [ power "x" 1; power "z" 2 ]);
      ]
  in
  Alcotest.(check string) "coefficient numerator" "5"
    (string "numerator" (assoc "result" coefficient));
  let variables =
    request [ ("action", `String "variables"); ("polynomial", p) ]
  in
  begin match assoc "variables" (assoc "result" variables) with
  | `List [ `String "x"; `String "y"; `String "z" ] -> ()
  | _ -> Alcotest.fail "unexpected variable ordering"
  end;
  let degree =
    request [ ("action", `String "total_degree"); ("polynomial", p) ]
  in
  Alcotest.(check int) "degree" 4 (int "degree" (assoc "result" degree))

let test_coefficient_array () =
  let p =
    polynomial
      [
        term "3" [];
        term "11" [ power "y" 1 ];
        term "-2" [ power "x" 1 ];
        term "5/7" [ power "x" 2; power "y" 1 ];
      ]
  in
  let response =
    request
      [
        ("id", `String "coeff-array");
        ("action", `String "coefficient_array");
        ("polynomial", p);
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "coeff-array" (string "id" response);
  Alcotest.(check string) "provenance method" "coefficient_array"
    (string "method" (assoc "provenance" response));
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_coefficient_array"
    (string "kind" result);
  Alcotest.(check string) "order" "row_major_last_variable_fastest"
    (string "order" result);
  begin match assoc "variables" result with
  | `List [ `String "x"; `String "y" ] -> ()
  | _ -> Alcotest.fail "unexpected coefficient-array variables"
  end;
  begin match assoc "shape" result with
  | `List [ `Int 3; `Int 2 ] -> ()
  | _ -> Alcotest.fail "unexpected coefficient-array shape"
  end;
  begin match assoc "coefficients" result with
  | `List coefficients ->
      let numerators =
        List.map (fun coefficient -> string "numerator" coefficient) coefficients
      in
      Alcotest.(check (list string)) "flattened coefficients"
        [ "3"; "11"; "-2"; "0"; "0"; "5" ] numerators
  | _ -> Alcotest.fail "coefficients must be an array"
  end

let test_strict_and_limits () =
  let strict =
    request
      [
        ("action", `String "differentiate");
        ("polynomial", polynomial [ term "1" [ power "x" 1 ] ]);
        ("variable", `String "x");
        ("approximate", `Bool true);
      ]
  in
  Alcotest.(check bool) "strict failure" false (bool "ok" strict);
  Alcotest.(check string) "strict code" "invalid_request"
    (string "code" (assoc "error" strict));
  let limits =
    Centl_multivariate_polynomial_protocol.{ default_limits with max_work = 1 }
  in
  let p =
    polynomial
      [ term "1" [ power "x" 1 ]; term "1" [ power "y" 1 ] ]
  in
  let limited =
    Centl_multivariate_polynomial_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "multiply");
           ("left", p);
           ("right", p);
         ])
  in
  Alcotest.(check bool) "work failure" false (bool "ok" limited);
  Alcotest.(check string) "work code" "resource_limit"
    (string "code" (assoc "error" limited));
  let dense_limits =
    Centl_multivariate_polynomial_protocol.
      { default_limits with max_dense_coefficients = 3 }
  in
  let dense_limited =
    Centl_multivariate_polynomial_protocol.handle_json ~limits:dense_limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "coefficient_array");
           ( "polynomial",
             polynomial
               [
                 term "1" [ power "x" 1 ];
                 term "1" [ power "y" 1 ];
               ] );
         ])
  in
  Alcotest.(check bool) "dense failure" false (bool "ok" dense_limited);
  Alcotest.(check string) "dense code" "resource_limit"
    (string "code" (assoc "error" dense_limited))

let test_cancellation () =
  let p =
    polynomial
      [ term "1" [ power "x" 1 ]; term "1" [ power "y" 1 ] ]
  in
  let response =
    Centl_multivariate_polynomial_protocol.handle_json
      ~cancelled:(fun () -> true)
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "multiply");
           ("left", p);
           ("right", p);
         ])
  in
  Alcotest.(check bool) "cancelled" false (bool "ok" response);
  Alcotest.(check string) "cancel code" "cancelled"
    (string "code" (assoc "error" response));
  let coefficient_cancel =
    Centl_multivariate_polynomial_protocol.handle_json
      ~cancelled:(fun () -> true)
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "coefficient_array");
           ("polynomial", p);
         ])
  in
  Alcotest.(check string) "coefficient cancel code" "cancelled"
    (string "code" (assoc "error" coefficient_cancel))

let () =
  Alcotest.run "centl multivariate polynomial protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "capabilities" `Quick test_capabilities;
          Alcotest.test_case "exact multiply" `Quick test_exact_multiply;
          Alcotest.test_case "derivative and substitution" `Quick
            test_derivative_and_substitution;
          Alcotest.test_case "queries" `Quick test_queries;
          Alcotest.test_case "coefficient array" `Quick test_coefficient_array;
          Alcotest.test_case "strict and limits" `Quick test_strict_and_limits;
          Alcotest.test_case "cancellation" `Quick test_cancellation;
        ] );
    ]
