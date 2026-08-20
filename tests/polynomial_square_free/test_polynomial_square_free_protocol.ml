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
      term "16" [];
      term "-8" [ power "x" 1 ];
      term "-20" [ power "x" 2 ];
      term "2" [ power "x" 3 ];
      term "8" [ power "x" 4 ];
      term "2" [ power "x" 5 ];
    ]

let request fields =
  Centl_polynomial_square_free_protocol.handle_json
    (`Assoc (("version", `Int 1) :: fields))

let test_capabilities () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_square_free_capabilities"
    (string "kind" result);
  Alcotest.(check bool) "characteristic zero" true
    (bool "characteristic_zero" result);
  Alcotest.(check bool) "monic factors" true (bool "monic_factors" result);
  Alcotest.(check bool) "multiplicity groups" true
    (bool "multiplicity_groups" result);
  Alcotest.(check bool) "not irreducible factorization" false
    (bool "irreducible_factorization" result);
  Alcotest.(check bool) "zero refused" true
    (bool "zero_polynomial_refused" result);
  Alcotest.(check bool) "cancellable" true
    (bool "cooperative_cancellation" result)

let test_factorize () =
  let response =
    request
      [
        ("id", `String "square-free-1");
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", source ());
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "square-free-1" (string "id" response);
  Alcotest.(check string) "classification" "exact"
    (string "classification" (assoc "provenance" response));
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_square_free_factorization"
    (string "kind" result);
  Alcotest.(check string) "factor semantics" "square_free_multiplicity_groups"
    (string "factor_semantics" result);
  Alcotest.(check bool) "not irreducible" false
    (bool "irreducible_factorization" result);
  Alcotest.(check int) "factor count" 2 (int "factor_count" result);
  Alcotest.(check string) "unit numerator" "2"
    (string "numerator" (assoc "unit" result));
  begin match assoc "factors" result with
  | `List [ first; second ] ->
      Alcotest.(check int) "multiplicity two" 2 (int "multiplicity" first);
      Alcotest.(check int) "first terms" 2
        (int "term_count" (assoc "polynomial" first));
      Alcotest.(check int) "multiplicity three" 3 (int "multiplicity" second);
      Alcotest.(check int) "second terms" 2
        (int "term_count" (assoc "polynomial" second))
  | _ -> Alcotest.fail "expected two multiplicity groups"
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
        ("irreducible", `Bool true);
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

let test_result_limit () =
  let limits =
    Centl_polynomial_square_free_protocol.
      { default_limits with max_result_bytes = 96 }
  in
  let response =
    Centl_polynomial_square_free_protocol.handle_json ~limits
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
    Centl_polynomial_square_free_protocol.handle_json
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
  Alcotest.run "centl polynomial square-free protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "capabilities" `Quick test_capabilities;
          Alcotest.test_case "factorize" `Quick test_factorize;
          Alcotest.test_case "constant" `Quick test_constant;
          Alcotest.test_case "zero refusal" `Quick test_zero_refusal;
          Alcotest.test_case "strict request" `Quick test_strict_request;
          Alcotest.test_case "mixed variable" `Quick test_mixed_variable;
          Alcotest.test_case "result limit" `Quick test_result_limit;
          Alcotest.test_case "cancellation" `Quick test_cancellation;
        ] );
    ]
