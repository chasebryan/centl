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

let list name json =
  match assoc name json with
  | `List values -> values
  | _ -> Alcotest.fail ("expected list field " ^ name)

let power variable exponent =
  `Assoc [ ("variable", `String variable); ("exponent", `Int exponent) ]

let term coefficient powers =
  `Assoc [ ("coefficient", `String coefficient); ("powers", `List powers) ]

let polynomial terms = `Assoc [ ("terms", `List terms) ]

let repeated () =
  polynomial
    [
      term "2" [];
      term "-4" [ power "x" 1 ];
      term "2" [ power "x" 2 ];
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
  Alcotest.(check bool) "not irreducible factorization" false
    (bool "irreducible_factorization" result);
  Alcotest.(check bool) "zero refused" true
    (bool "zero_polynomial_refused" result)

let test_factorize () =
  let response =
    request
      [
        ("id", `String "sqf-1");
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", repeated ());
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "sqf-1" (string "id" response);
  Alcotest.(check string) "classification" "exact"
    (string "classification" (assoc "provenance" response));
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_square_free_factorization"
    (string "kind" result);
  Alcotest.(check string) "semantics" "square_free_multiplicity_groups"
    (string "factor_semantics" result);
  Alcotest.(check bool) "not irreducible" false
    (bool "irreducible_factorization" result);
  Alcotest.(check string) "unit" "2" (string "text" (assoc "unit" result));
  begin match list "factors" result with
  | [ factor ] ->
      Alcotest.(check int) "multiplicity" 2 (int "multiplicity" factor);
      Alcotest.(check int) "x-1 terms" 2
        (int "term_count" (assoc "polynomial" factor))
  | _ -> Alcotest.fail "expected one multiplicity group"
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
  Alcotest.(check string) "unit" "-7/3" (string "text" (assoc "unit" result));
  Alcotest.(check int) "no groups" 0 (int "factor_count" result)

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
  Alcotest.(check string) "zero code" "invalid_polynomial"
    (string "code" (assoc "error" response))

let test_strict_request () =
  let response =
    request
      [
        ("action", `String "factorize");
        ("variable", `String "x");
        ("polynomial", repeated ());
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
          polynomial [ term "1" []; term "1" [ power "y" 1 ] ] );
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "mixed code" "invalid_request"
    (string "code" (assoc "error" response))

let test_result_limit () =
  let limits =
    Centl_polynomial_square_free_protocol.
      { default_limits with max_result_bytes = 128 }
  in
  let response =
    Centl_polynomial_square_free_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "factorize");
           ("variable", `String "x");
           ("polynomial", repeated ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "result limit" "resource_limit"
    (string "code" (assoc "error" response))

let test_cancellation () =
  let response =
    Centl_polynomial_square_free_protocol.handle_json ~cancelled:(fun () -> true)
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "cancelled");
           ("action", `String "factorize");
           ("variable", `String "x");
           ("polynomial", repeated ());
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
