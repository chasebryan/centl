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

let substitution variable replacement =
  `Assoc
    [
      ("variable", `String variable);
      ("polynomial", replacement);
    ]

let request fields =
  Centl_polynomial_composition_protocol.handle_json
    (`Assoc (("version", `Int 1) :: fields))

let source () =
  polynomial
    [
      term "3" [ power "x" 2; power "y" 1 ];
      term "-2" [ power "y" 1 ];
      term "5" [];
    ]

let substitutions () =
  `List
    [
      substitution "x"
        (polynomial
           [
             term "1" [ power "u" 1 ];
             term "1" [];
           ]);
      substitution "y" (polynomial [ term "1" [ power "v" 1 ] ]);
    ]

let test_exact_protocol_result () =
  let response =
    request
      [
        ("id", `String "compose-1");
        ("action", `String "compose");
        ("polynomial", source ());
        ("substitutions", substitutions ());
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "compose-1" (string "id" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "multivariate_rational_polynomial"
    (string "kind" result);
  Alcotest.(check bool) "exact" true (bool "exact" result);
  Alcotest.(check int) "four canonical terms" 4 (int "term_count" result);
  Alcotest.(check string) "classification" "exact"
    (string "classification" (assoc "provenance" response))

let test_simultaneous_protocol_semantics () =
  let response =
    request
      [
        ("action", `String "compose");
        ( "polynomial",
          polynomial
            [
              term "1" [ power "x" 1 ];
              term "-1" [ power "y" 1 ];
            ] );
        ( "substitutions",
          `List
            [
              substitution "x" (polynomial [ term "1" [ power "y" 1 ] ]);
              substitution "y" (polynomial [ term "1" [ power "x" 1 ] ]);
            ] );
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check int) "two swapped terms" 2
    (int "term_count" (assoc "result" response))

let test_capabilities () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_composition_capabilities"
    (string "kind" result);
  Alcotest.(check bool) "simultaneous" true (bool "simultaneous" result);
  Alcotest.(check bool) "cancellable" true
    (bool "cooperative_cancellation" result);
  Alcotest.(check int) "default power limit" 1000
    (int "max_power_exponent" (assoc "limits" result))

let test_strict_request () =
  let response =
    request
      [
        ("action", `String "compose");
        ("polynomial", source ());
        ("substitutions", substitutions ());
        ("approximate", `Bool true);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "strict code" "invalid_request"
    (string "code" (assoc "error" response))

let test_power_limit () =
  let composition =
    Centl_polynomial_composition.
      { default_limits with max_power_exponent = 1 }
  in
  let limits =
    Centl_polynomial_composition_protocol.
      { default_limits with composition }
  in
  let response =
    Centl_polynomial_composition_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "compose");
           ("polynomial", polynomial [ term "1" [ power "x" 2 ] ]);
           ( "substitutions",
             `List
               [
                 substitution "x"
                   (polynomial
                      [
                        term "1" [ power "u" 1 ];
                        term "1" [];
                      ]);
               ] );
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "resource code" "resource_limit"
    (string "code" (assoc "error" response))

let test_cancellation () =
  let response =
    Centl_polynomial_composition_protocol.handle_json
      ~cancelled:(fun () -> true)
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "cancelled");
           ("action", `String "compose");
           ("polynomial", source ());
           ("substitutions", substitutions ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "id" "cancelled" (string "id" response);
  Alcotest.(check string) "cancel code" "cancelled"
    (string "code" (assoc "error" response))

let () =
  Alcotest.run "centl polynomial composition protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "exact result" `Quick test_exact_protocol_result;
          Alcotest.test_case "simultaneous semantics" `Quick
            test_simultaneous_protocol_semantics;
          Alcotest.test_case "capabilities" `Quick test_capabilities;
          Alcotest.test_case "strict request" `Quick test_strict_request;
          Alcotest.test_case "power limit" `Quick test_power_limit;
          Alcotest.test_case "cancellation" `Quick test_cancellation;
        ] );
    ]
