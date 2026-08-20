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

let source () =
  polynomial
    [
      term "6/35" [ power "x" 2 ];
      term "-9/14" [ power "x" 1; power "y" 1 ];
      term "3/10" [];
    ]

let request fields =
  Centl_polynomial_content_protocol.handle_json
    (`Assoc (("version", `Int 1) :: fields))

let test_capabilities () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_content_capabilities"
    (string "kind" result);
  Alcotest.(check bool) "positive normalization" true
    (bool "positive_content_normalization" result);
  Alcotest.(check bool) "zero convention" true
    (bool "zero_content_is_zero" result);
  Alcotest.(check bool) "cancellation" true
    (bool "cooperative_cancellation" result)

let test_decompose () =
  let response =
    request
      [
        ("id", `String "content-decompose");
        ("action", `String "decompose");
        ("polynomial", source ());
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "content-decompose" (string "id" response);
  Alcotest.(check string) "classification" "exact"
    (string "classification" (assoc "provenance" response));
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_content_decomposition"
    (string "kind" result);
  let content = assoc "content" result in
  Alcotest.(check string) "content numerator" "3" (string "numerator" content);
  Alcotest.(check string) "content denominator" "70"
    (string "denominator" content);
  let primitive = assoc "primitive_part" result in
  Alcotest.(check string) "primitive kind" "multivariate_rational_polynomial"
    (string "kind" primitive);
  Alcotest.(check int) "primitive terms" 3 (int "term_count" primitive)

let test_content_action () =
  let response =
    request
      [
        ("action", `String "content");
        ("polynomial", source ());
      ]
  in
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_content" (string "kind" result);
  let value = assoc "value" result in
  Alcotest.(check string) "numerator" "3" (string "numerator" value);
  Alcotest.(check string) "denominator" "70" (string "denominator" value)

let test_primitive_part_action () =
  let response =
    request
      [
        ("action", `String "primitive_part");
        ("polynomial", source ());
      ]
  in
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "multivariate_rational_polynomial"
    (string "kind" result);
  begin match assoc "terms" result with
  | `List terms ->
      let coefficients =
        List.map
          (fun term -> string "text" (assoc "coefficient" term))
          terms
      in
      Alcotest.(check (list string)) "primitive coefficients"
        [ "7"; "-15"; "4" ] coefficients
  | _ -> Alcotest.fail "primitive terms must be an array"
  end

let test_zero_decomposition () =
  let response =
    request
      [
        ("action", `String "decompose");
        ("polynomial", polynomial []);
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string) "zero content" "0"
    (string "text" (assoc "content" result));
  Alcotest.(check int) "zero primitive terms" 0
    (int "term_count" (assoc "primitive_part" result))

let test_strict_request () =
  let response =
    request
      [
        ("action", `String "decompose");
        ("polynomial", source ());
        ("approximate", `Bool true);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "code" "invalid_request"
    (string "code" (assoc "error" response))

let test_work_limit () =
  let content = Centl_polynomial_content.{ default_limits with max_work = 1 } in
  let limits =
    Centl_polynomial_content_protocol.{ default_limits with content }
  in
  let response =
    Centl_polynomial_content_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "decompose");
           ("polynomial", source ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "code" "resource_limit"
    (string "code" (assoc "error" response))

let test_primitive_output_limit () =
  let content =
    Centl_polynomial_content.{ default_limits with max_exact_bits = 40 }
  in
  let limits =
    Centl_polynomial_content_protocol.{ default_limits with content }
  in
  let growing =
    polynomial
      [
        term "1/101" [ power "x" 1 ];
        term "1/103" [ power "y" 1 ];
        term "1/107" [ power "z" 1 ];
      ]
  in
  let response =
    Centl_polynomial_content_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "decompose");
           ("polynomial", growing);
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "code" "resource_limit"
    (string "code" (assoc "error" response));
  Alcotest.(check string) "message"
    "polynomial content primitive part exceeds the exact-bit limit"
    (string "message" (assoc "error" response))

let test_cancellation () =
  let response =
    Centl_polynomial_content_protocol.handle_json
      ~cancelled:(fun () -> true)
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "cancelled");
           ("action", `String "decompose");
           ("polynomial", source ());
         ])
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string) "id" "cancelled" (string "id" response);
  Alcotest.(check string) "code" "cancelled"
    (string "code" (assoc "error" response))

let () =
  Alcotest.run "centl polynomial content protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "capabilities" `Quick test_capabilities;
          Alcotest.test_case "decompose" `Quick test_decompose;
          Alcotest.test_case "content" `Quick test_content_action;
          Alcotest.test_case "primitive part" `Quick test_primitive_part_action;
          Alcotest.test_case "zero" `Quick test_zero_decomposition;
          Alcotest.test_case "strict request" `Quick test_strict_request;
          Alcotest.test_case "work limit" `Quick test_work_limit;
          Alcotest.test_case "primitive output limit" `Quick
            test_primitive_output_limit;
          Alcotest.test_case "cancellation" `Quick test_cancellation;
        ] );
    ]
