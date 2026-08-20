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

let dividend () =
  polynomial [ term "-1" []; term "1" [ power "x" 3 ] ]

let divisor () =
  polynomial [ term "-1" []; term "1" [ power "x" 1 ] ]

let request fields =
  Centl_polynomial_division_protocol.handle_json
    (`Assoc (("version", `Int 1) :: fields))

let test_capabilities () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_division_capabilities"
    (string "kind" result);
  Alcotest.(check bool) "univariate" true (bool "univariate" result);
  Alcotest.(check bool) "explicit variable" true
    (bool "explicit_variable" result);
  Alcotest.(check bool) "cancellable" true
    (bool "cooperative_cancellation" result)

let test_divide () =
  let response =
    request
      [
        ("id", `String "division-1");
        ("action", `String "divide");
        ("variable", `String "x");
        ("dividend", dividend ());
        ("divisor", divisor ());
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "division-1" (string "id" response);
  Alcotest.(check string) "classification" "exact"
    (string "classification" (assoc "provenance" response));
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_division" (string "kind" result);
  Alcotest.(check int) "quotient terms" 3
    (int "term_count" (assoc "quotient" result));
  Alcotest.(check int) "remainder terms" 0
    (int "term_count" (assoc "remainder" result))

let test_quotient_action () =
  let response =
    request
      [
        ("action", `String "quotient");
        ("variable", `String "x");
        ("dividend", dividend ());
        ("divisor", divisor ());
      ]
  in
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "multivariate_rational_polynomial"
    (string "kind" result);
  Alcotest.(check int) "quotient terms" 3 (int "term_count" result)

let test_remainder_action () =
  let response =
    request
      [
        ("action", `String "remainder");
        ("variable", `String "x");
        ( "dividend",
          polynomial
            [
              term "1" [];
              term "2" [ power "x" 1 ];
              term "1" [ power "x" 3 ];
            ] );
        ( "divisor",
          polynomial [ term "1" []; term "1" [ power "x" 2 ] ] );
      ]
  in
  let result = assoc "result" response in
  Alcotest.(check int) "remainder terms" 2 (int "term_count" result)

let test_strict_request () =
  let response =
    request
      [
        ("action", `String "divide");
        ("variable", `String "x");
        ("dividend", dividend ());
        ("divisor", divisor ());
        ("approximate", `Bool true);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "strict code" "invalid_request"
    (string "code" (assoc "error" response))

let test_mixed_variable () =
  let response =
    request
      [
        ("action", `String "divide");
        ("variable", `String "x");
        ("dividend", dividend ());
        ( "divisor",
          polynomial [ term "1" []; term "1" [ power "y" 1 ] ] );
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "mixed-variable code" "invalid_request"
    (string "code" (assoc "error" response))

let test_zero_divisor () =
  let response =
    request
      [
        ("action", `String "divide");
        ("variable", `String "x");
        ("dividend", dividend ());
        ("divisor", polynomial []);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "zero-divisor code" "division_by_zero"
    (string "code" (assoc "error" response))

let test_result_limit () =
  let limits =
    Centl_polynomial_division_protocol.{ default_limits with max_result_bytes = 96 }
  in
  let response =
    Centl_polynomial_division_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "divide");
           ("variable", `String "x");
           ("dividend", dividend ());
           ("divisor", divisor ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "result-limit code" "resource_limit"
    (string "code" (assoc "error" response))

let test_cancellation () =
  let response =
    Centl_polynomial_division_protocol.handle_json
      ~cancelled:(fun () -> true)
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "cancelled");
           ("action", `String "divide");
           ("variable", `String "x");
           ("dividend", dividend ());
           ("divisor", divisor ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "id" "cancelled" (string "id" response);
  Alcotest.(check string) "cancel code" "cancelled"
    (string "code" (assoc "error" response))

let () =
  Alcotest.run "centl polynomial division protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "capabilities" `Quick test_capabilities;
          Alcotest.test_case "divide" `Quick test_divide;
          Alcotest.test_case "quotient" `Quick test_quotient_action;
          Alcotest.test_case "remainder" `Quick test_remainder_action;
          Alcotest.test_case "strict request" `Quick test_strict_request;
          Alcotest.test_case "mixed variable" `Quick test_mixed_variable;
          Alcotest.test_case "zero divisor" `Quick test_zero_divisor;
          Alcotest.test_case "result limit" `Quick test_result_limit;
          Alcotest.test_case "cancellation" `Quick test_cancellation;
        ] );
    ]
