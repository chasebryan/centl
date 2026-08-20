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
  `Assoc [ ("coefficient", `String coefficient); ("powers", `List powers) ]

let polynomial terms = `Assoc [ ("terms", `List terms) ]

let source () =
  polynomial
    [
      term "5/7" [];
      term "25/7" [ power "x" 1 ];
      term "55/7" [ power "x" 2 ];
      term "80/7" [ power "x" 3 ];
      term "60/7" [ power "x" 4 ];
    ]

let irreducible_quadratic () =
  polynomial [ term "1" []; term "1" [ power "x" 2 ] ]

let request fields =
  Centl_polynomial_factorization_protocol.handle_json
    (`Assoc (("version", `Int 1) :: fields))

let test_capabilities () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_rational_factorization_capabilities"
    (string "kind" result);
  Alcotest.(check string) "coefficient domain" "Q"
    (string "coefficient_domain" result);
  Alcotest.(check bool) "irreducible factorization" true
    (bool "irreducible_factorization" result);
  Alcotest.(check bool) "deterministic ordering" true
    (bool "deterministic_ordering" result);
  Alcotest.(check bool) "reconstruction verified" true
    (bool "exact_reconstruction_verified" result);
  Alcotest.(check bool) "zero refused" true
    (bool "zero_polynomial_refused" result)

let test_golden_factorization () =
  let response =
    request
      [
        ("id", `String "factor-golden-1");
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", source ());
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "factor-golden-1" (string "id" response);
  Alcotest.(check string) "classification" "exact"
    (string "classification" (assoc "provenance" response));
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_rational_factorization"
    (string "kind" result);
  Alcotest.(check string) "semantics" "irreducible_factors_over_Q"
    (string "factor_semantics" result);
  Alcotest.(check bool) "irreducible" true
    (bool "irreducible_factorization" result);
  Alcotest.(check bool) "complete" true (bool "complete" result);
  Alcotest.(check string) "unit" "60/7" (string "text" (assoc "unit" result));
  Alcotest.(check int) "factor count" 2 (int "factor_count" result);
  begin match assoc "factors" result with
  | `List [ first; second ] ->
      Alcotest.(check int) "linear multiplicity" 2 (int "multiplicity" first);
      Alcotest.(check string) "linear golden" "1/2 + x"
        (string "text" (assoc "polynomial" first));
      Alcotest.(check int) "quadratic multiplicity" 1
        (int "multiplicity" second);
      Alcotest.(check string) "quadratic golden" "1/3 + 1/3*x + x^2"
        (string "text" (assoc "polynomial" second))
  | _ -> Alcotest.fail "expected canonical two-factor result"
  end

let test_constant () =
  let response =
    request
      [
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", polynomial [ term "-7/3" [] ]);
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check int) "no factors" 0 (int "factor_count" result);
  Alcotest.(check string) "unit" "-7/3" (string "text" (assoc "unit" result))

let test_zero_refusal () =
  let response =
    request
      [
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", polynomial []);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "zero code" "zero_polynomial"
    (string "code" (assoc "error" response))

let test_strict_request () =
  let response =
    request
      [
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", source ());
        ("partial", `Bool true);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "strict code" "invalid_request"
    (string "code" (assoc "error" response))

let test_mixed_variable () =
  let response =
    request
      [
        ("action", `String "factorize");
        ("variable", `String "x");
        ( "polynomial",
          polynomial
            [
              term "1" [ power "x" 1 ];
              term "1" [ power "y" 1 ];
            ] );
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "mixed code" "invalid_request"
    (string "code" (assoc "error" response))

let test_incomplete_search_refuses () =
  let core =
    Centl_polynomial_factorization.
      { default_limits with max_candidates = 1 }
  in
  let limits =
    Centl_polynomial_factorization_protocol.
      { default_limits with factorization = core }
  in
  let response =
    Centl_polynomial_factorization_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "factorize");
           ("variable", `String "x");
           ("polynomial", irreducible_quadratic ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "resource code" "resource_limit"
    (string "code" (assoc "error" response))

let test_result_limit () =
  let limits =
    Centl_polynomial_factorization_protocol.
      { default_limits with max_result_bytes = 96 }
  in
  let response =
    Centl_polynomial_factorization_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "factorize");
           ("variable", `String "x");
           ("polynomial", source ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "result limit" "resource_limit"
    (string "code" (assoc "error" response))

let test_cancellation () =
  let response =
    Centl_polynomial_factorization_protocol.handle_json
      ~cancelled:(fun () -> true)
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "cancelled");
           ("action", `String "factorize");
           ("variable", `String "x");
           ("polynomial", source ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "id" "cancelled" (string "id" response);
  Alcotest.(check string) "cancel code" "cancelled"
    (string "code" (assoc "error" response))

let () =
  Alcotest.run "centl rational polynomial factorization protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "capabilities" `Quick test_capabilities;
          Alcotest.test_case "golden factorization" `Quick
            test_golden_factorization;
          Alcotest.test_case "constant" `Quick test_constant;
          Alcotest.test_case "zero refusal" `Quick test_zero_refusal;
          Alcotest.test_case "strict request" `Quick test_strict_request;
          Alcotest.test_case "mixed variable" `Quick test_mixed_variable;
          Alcotest.test_case "incomplete search refuses" `Quick
            test_incomplete_search_refuses;
          Alcotest.test_case "result limit" `Quick test_result_limit;
          Alcotest.test_case "cancellation" `Quick test_cancellation;
        ] );
    ]
