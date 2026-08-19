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

let request fields =
  Centl_complex_rational_protocol.handle_json
    (`Assoc (("version", `Int 1) :: fields))

let test_exact_result () =
  let response =
    request
      [
        ("id", `String "z");
        ( "expression",
          `String "complex(1/2, 2/3) * complex(3/4, -5/6)" );
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "z" (string "id" response);
  let value = assoc "value" response in
  Alcotest.(check string) "kind" "complex_rational" (string "kind" value);
  Alcotest.(check bool) "exact" true (bool "exact" value);
  let real = assoc "real" value in
  let imaginary = assoc "imaginary" value in
  Alcotest.(check string) "real numerator" "67" (string "numerator" real);
  Alcotest.(check string) "real denominator" "72" (string "denominator" real);
  Alcotest.(check string) "imag numerator" "1" (string "numerator" imaginary);
  Alcotest.(check string) "imag denominator" "12"
    (string "denominator" imaginary);
  let provenance = assoc "provenance" response in
  Alcotest.(check string)
    "classification" "exact" (string "classification" provenance)

let test_exact_functions () =
  let response =
    request [ ("expression", `String "norm2(complex(3/5, -4/7))") ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let value = assoc "value" response in
  let real = assoc "real" value in
  let imaginary = assoc "imaginary" value in
  Alcotest.(check string) "norm2 numerator" "841" (string "numerator" real);
  Alcotest.(check string) "norm2 denominator" "1225"
    (string "denominator" real);
  Alcotest.(check string) "norm2 imaginary" "0" (string "numerator" imaginary)

let test_refusal_boundary () =
  let response =
    request [ ("expression", `String "complex(sqrt(2), 0)") ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  let error = assoc "error" response in
  Alcotest.(check string)
    "code" "unsupported_exact_complex_expression" (string "code" error);
  let ordinary = request [ ("expression", `String "1/2 + 1/3") ] in
  Alcotest.(check bool) "ordinary expression refused" false (bool "ok" ordinary);
  Alcotest.(check string)
    "ordinary code" "not_exact_complex_request"
    (string "code" (assoc "error" ordinary))

let test_strict_request () =
  let response =
    request
      [
        ("expression", `String "complex(1, 2)");
        ("approximate", `Bool true);
      ]
  in
  Alcotest.(check bool) "failure" false (bool "ok" response);
  Alcotest.(check string)
    "strict field" "invalid_request" (string "code" (assoc "error" response))

let test_resource_limits () =
  let limits =
    Centl_complex_rational_protocol.
      { default_limits with max_exact_bits = 4; max_result_bytes = 4096 }
  in
  let response =
    Centl_complex_rational_protocol.evaluate_source ~limits "complex(17, 0)"
  in
  Alcotest.(check bool) "bit failure" false (bool "ok" response);
  Alcotest.(check string)
    "bit code" "resource_limit" (string "code" (assoc "error" response));
  let source_limits =
    Centl_complex_rational_protocol.{ default_limits with max_source_bytes = 3 }
  in
  let response =
    Centl_complex_rational_protocol.evaluate_source ~limits:source_limits
      "complex(1, 2)"
  in
  Alcotest.(check bool) "source failure" false (bool "ok" response);
  Alcotest.(check string)
    "source code" "resource_limit" (string "code" (assoc "error" response))

let () =
  Alcotest.run "centl exact complex-rational protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "exact result" `Quick test_exact_result;
          Alcotest.test_case "exact functions" `Quick test_exact_functions;
          Alcotest.test_case "refusal boundary" `Quick test_refusal_boundary;
          Alcotest.test_case "strict request" `Quick test_strict_request;
          Alcotest.test_case "resource limits" `Quick test_resource_limits;
        ] );
    ]
