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

let matrix rows =
  `List
    (List.map
       (fun row -> `List (List.map (fun value -> `String value) row))
       rows)

let integer_polynomial coefficients =
  `List (List.map (fun value -> `String value) coefficients)

let power variable exponent =
  `Assoc [ ("variable", `String variable); ("exponent", `Int exponent) ]

let term coefficient powers =
  `Assoc
    [
      ("coefficient", `String coefficient);
      ("powers", `List powers);
    ]

let polynomial terms = `Assoc [ ("terms", `List terms) ]

let public_math ?id state domain request =
  let id_fields = match id with None -> [] | Some id -> [ ("id", id) ] in
  Centl_protocol.handle_json state
    (`Assoc
       ([ ("version", `Int 1); ("op", `String "math") ] @ id_fields
       @ [ ("domain", `String domain); ("request", `Assoc request) ]))

let list_contains_string value = function
  | `List values -> List.mem (`String value) values
  | _ -> false

let test_matrix_through_public_protocol () =
  let state = Centl_protocol.create () in
  let response =
    public_math ~id:(`String "det") state "matrix"
      [
        ("action", `String "determinant");
        ("matrix", matrix [ [ "1"; "2" ]; [ "3"; "4" ] ]);
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "det" (string "id" response);
  Alcotest.(check string) "domain" "matrix" (string "domain" response);
  Alcotest.(check string) "determinant" "-2"
    (string "numerator" (assoc "result" response));
  Alcotest.(check int) "request count" 0
    (int "requests" (assoc "session" response));
  Alcotest.(check string) "exact provenance" "exact"
    (string "classification" (assoc "provenance" response))

let test_polynomial_coefficient_array_public_protocol () =
  let state = Centl_protocol.create () in
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
    public_math ~id:(`String "coeff-array") state "multivariate_polynomial"
      [
        ("action", `String "coefficient_array");
        ("polynomial", p);
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "coeff-array" (string "id" response);
  Alcotest.(check string) "domain" "multivariate_polynomial"
    (string "domain" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "polynomial_coefficient_array"
    (string "kind" result);
  begin match assoc "shape" result with
  | `List [ `Int 3; `Int 2 ] -> ()
  | _ -> Alcotest.fail "unexpected public coefficient-array shape"
  end;
  begin match assoc "coefficients" result with
  | `List coefficients ->
      Alcotest.(check (list string)) "public numerators"
        [ "3"; "11"; "-2"; "0"; "0"; "5" ]
        (List.map (fun coefficient -> string "numerator" coefficient) coefficients)
  | _ -> Alcotest.fail "public coefficients must be a list"
  end;
  Alcotest.(check string) "exact provenance" "exact"
    (string "classification" (assoc "provenance" response))

let test_describe_advertises_math () =
  let state = Centl_protocol.create () in
  let response =
    Centl_protocol.handle_json state
      (`Assoc [ ("version", `Int 1); ("op", `String "describe") ])
  in
  Alcotest.(check bool) "describe success" true (bool "ok" response);
  let capabilities = assoc "capabilities" response in
  Alcotest.(check bool) "math operation advertised" true
    (list_contains_string "math" (assoc "operations" capabilities));
  let gateway =
    Centl_protocol.handle_json state
      (`Assoc
         [
           ("version", `Int 1);
           ("op", `String "math");
           ("domain", `String "capabilities");
         ])
  in
  Alcotest.(check bool) "gateway discovery success" true (bool "ok" gateway);
  Alcotest.(check string) "gateway domain" "capabilities"
    (string "domain" gateway);
  let gateway_result = assoc "result" gateway in
  Alcotest.(check string) "gateway kind" "centl_math_capabilities"
    (string "kind" gateway_result);
  Alcotest.(check bool) "exact first" true (bool "exact_first" gateway_result)

let test_server_limit_clamps_gateway () =
  let evaluation =
    Centl_engine.{ default_evaluation_limits with max_exact_bits = 4 }
  in
  let limits = Centl_protocol.{ default_server_limits with evaluation } in
  let state = Centl_protocol.create ~limits () in
  let response =
    public_math state "complex_rational"
      [ ("expression", `String "complex(17, 0)") ]
  in
  Alcotest.(check bool) "refused" false (bool "ok" response);
  Alcotest.(check string) "resource code" "resource_limit"
    (string "code" (assoc "error" response))

let test_public_protocol_cancellation () =
  let state = Centl_protocol.create () in
  let response =
    Centl_protocol.handle_json ~cancelled:(fun () -> true) state
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `Int 9);
           ("op", `String "math");
           ("domain", `String "matrix");
           ( "request",
             `Assoc
               [
                 ("action", `String "inverse");
                 ("matrix", matrix [ [ "1"; "2" ]; [ "3"; "4" ] ]);
               ] );
         ])
  in
  Alcotest.(check bool) "cancelled" false (bool "ok" response);
  Alcotest.(check string) "cancel code" "cancelled"
    (string "code" (assoc "error" response))

let test_deep_algebraic_cancellation () =
  let state = Centl_protocol.create () in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 5
  in
  let response =
    Centl_protocol.handle_json ~cancelled state
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "deep-cancel");
           ("op", `String "math");
           ("domain", `String "real_algebraic");
           ( "request",
             `Assoc
               [
                 ("action", `String "refine");
                 ("polynomial", integer_polynomial [ "-2"; "0"; "1" ]);
                 ("lower", `String "1");
                 ("upper", `String "2");
                 ("steps", `Int 8);
               ] );
         ])
  in
  Alcotest.(check bool) "cancelled" false (bool "ok" response);
  Alcotest.(check string) "id preserved" "deep-cancel" (string "id" response);
  Alcotest.(check string) "domain preserved" "real_algebraic"
    (string "domain" response);
  Alcotest.(check string) "cancel code" "cancelled"
    (string "code" (assoc "error" response));
  Alcotest.(check bool) "callback reached refinement" true (!checks >= 5)

let test_public_protocol_strictness () =
  let state = Centl_protocol.create () in
  let response =
    Centl_protocol.handle_json state
      (`Assoc
         [
           ("version", `Int 1);
           ("op", `String "math");
           ("domain", `String "matrix");
           ( "request",
             `Assoc
               [
                 ("action", `String "rank");
                 ("matrix", matrix [ [ "1" ] ]);
               ] );
           ("approximate", `Bool true);
         ])
  in
  Alcotest.(check bool) "strict refusal" false (bool "ok" response);
  Alcotest.(check string) "strict code" "invalid_request"
    (string "code" (assoc "error" response))

let () =
  Alcotest.run "centl canonical math public protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "matrix public route" `Quick
            test_matrix_through_public_protocol;
          Alcotest.test_case "polynomial coefficient array" `Quick
            test_polynomial_coefficient_array_public_protocol;
          Alcotest.test_case "describe advertises math" `Quick
            test_describe_advertises_math;
          Alcotest.test_case "server limits clamp gateway" `Quick
            test_server_limit_clamps_gateway;
          Alcotest.test_case "cancellation" `Quick
            test_public_protocol_cancellation;
          Alcotest.test_case "deep algebraic cancellation" `Quick
            test_deep_algebraic_cancellation;
          Alcotest.test_case "strictness" `Quick test_public_protocol_strictness;
        ] );
    ]
