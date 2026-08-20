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

let left () = polynomial [ term "-1" []; term "1" [ power "x" 3 ] ]
let right () = polynomial [ term "-1" []; term "1" [ power "x" 2 ] ]

let request fields =
  Centl_polynomial_gcd_protocol.handle_json
    (`Assoc (("version", `Int 1) :: fields))

let test_capabilities () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_gcd_capabilities"
    (string "kind" result);
  Alcotest.(check bool) "univariate" true (bool "univariate" result);
  Alcotest.(check bool) "monic" true (bool "monic_nonzero_gcd" result);
  Alcotest.(check bool) "zero convention" true (bool "zero_zero_is_zero" result);
  let limits = assoc "limits" result in
  Alcotest.(check bool) "work advertised" true (int "max_work" limits > 0)

let test_gcd () =
  let response =
    request
      [
        ("id", `String "gcd-1");
        ("action", `String "gcd");
        ("variable", `String "x");
        ("left", left ());
        ("right", right ());
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "gcd-1" (string "id" response);
  Alcotest.(check string) "classification" "exact"
    (string "classification" (assoc "provenance" response));
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "multivariate_rational_polynomial"
    (string "kind" result);
  Alcotest.(check int) "x-1 terms" 2 (int "term_count" result)

let test_coprime () =
  let response =
    request
      [
        ("action", `String "coprime");
        ("variable", `String "x");
        ("left", polynomial [ term "1" []; term "1" [ power "x" 2 ] ]);
        ("right", polynomial [ term "1" []; term "1" [ power "x" 1 ] ]);
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_coprimality" (string "kind" result);
  Alcotest.(check bool) "coprime" true (bool "coprime" result)

let test_zero_convention () =
  let response =
    request
      [
        ("action", `String "gcd");
        ("variable", `String "x");
        ("left", polynomial []);
        ("right", polynomial []);
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check int) "zero terms" 0 (int "term_count" (assoc "result" response))

let test_strict_request () =
  let response =
    request
      [
        ("action", `String "gcd");
        ("variable", `String "x");
        ("left", left ());
        ("right", right ());
        ("monic", `Bool false);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "strict code" "invalid_request"
    (string "code" (assoc "error" response))

let test_mixed_variable () =
  let response =
    request
      [
        ("action", `String "gcd");
        ("variable", `String "x");
        ("left", left ());
        ("right", polynomial [ term "1" []; term "1" [ power "y" 1 ] ]);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "mixed code" "invalid_request"
    (string "code" (assoc "error" response))

let test_result_limit () =
  let limits = Centl_polynomial_gcd_protocol.{ default_limits with max_result_bytes = 96 } in
  let response =
    Centl_polynomial_gcd_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "gcd");
           ("variable", `String "x");
           ("left", left ());
           ("right", right ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "result limit" "resource_limit"
    (string "code" (assoc "error" response))

let test_cancellation () =
  let response =
    Centl_polynomial_gcd_protocol.handle_json ~cancelled:(fun () -> true)
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "cancelled");
           ("action", `String "gcd");
           ("variable", `String "x");
           ("left", left ());
           ("right", right ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "id" "cancelled" (string "id" response);
  Alcotest.(check string) "cancel code" "cancelled"
    (string "code" (assoc "error" response))

let () =
  Alcotest.run "centl polynomial gcd protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "capabilities" `Quick test_capabilities;
          Alcotest.test_case "gcd" `Quick test_gcd;
          Alcotest.test_case "coprime" `Quick test_coprime;
          Alcotest.test_case "zero convention" `Quick test_zero_convention;
          Alcotest.test_case "strict request" `Quick test_strict_request;
          Alcotest.test_case "mixed variable" `Quick test_mixed_variable;
          Alcotest.test_case "result limit" `Quick test_result_limit;
          Alcotest.test_case "cancellation" `Quick test_cancellation;
        ] );
    ]
