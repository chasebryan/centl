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

let polynomial coefficients = `List (List.map (fun value -> `String value) coefficients)

let request fields =
  Centl_real_algebraic_protocol.handle_json
    (`Assoc (("version", `Int 1) :: fields))

let sqrt2 = polynomial [ "-2"; "0"; "1" ]

let test_capabilities () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "real_algebraic_capabilities" (string "kind" result);
  Alcotest.(check int) "degree limit" 64 (int "max_degree" (assoc "limits" result))

let test_certify_sqrt2 () =
  let response =
    request
      [
        ("id", `String "sqrt2");
        ("action", `String "certify");
        ("polynomial", sqrt2);
        ("lower", `String "1");
        ("upper", `String "2");
      ]
  in
  Alcotest.(check bool) "success" true (bool "ok" response);
  Alcotest.(check string) "id" "sqrt2" (string "id" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "real_algebraic_root" (string "kind" result);
  Alcotest.(check string) "classification" "algebraic_exact"
    (string "classification" result);
  Alcotest.(check int) "root count" 1 (int "root_count" result);
  Alcotest.(check string) "provenance classification" "algebraic_exact"
    (string "classification" (assoc "provenance" response))

let test_count_and_refine () =
  let count =
    request
      [
        ("action", `String "count_roots");
        ("polynomial", sqrt2);
        ("lower", `String "-2");
        ("upper", `String "2");
      ]
  in
  Alcotest.(check bool) "count success" true (bool "ok" count);
  Alcotest.(check int) "two roots" 2 (int "count" (assoc "result" count));
  let refined =
    request
      [
        ("action", `String "refine");
        ("polynomial", sqrt2);
        ("lower", `String "1");
        ("upper", `String "2");
        ("steps", `Int 8);
      ]
  in
  Alcotest.(check bool) "refine success" true (bool "ok" refined);
  Alcotest.(check string) "refined kind" "real_algebraic_root"
    (string "kind" (assoc "result" refined));
  let rational_root =
    request
      [
        ("action", `String "refine");
        ("polynomial", polynomial [ "-3"; "1" ]);
        ("lower", `String "2");
        ("upper", `String "4");
        ("steps", `Int 1);
      ]
  in
  Alcotest.(check string) "rational midpoint" "rational"
    (string "kind" (assoc "result" rational_root));
  Alcotest.(check string) "rational numerator" "3"
    (string "numerator" (assoc "value" (assoc "result" rational_root)))

let test_refusals () =
  let repeated =
    request
      [
        ("action", `String "certify");
        ("polynomial", polynomial [ "1"; "-2"; "1" ]);
        ("lower", `String "0");
        ("upper", `String "2");
      ]
  in
  Alcotest.(check bool) "repeated failure" false (bool "ok" repeated);
  Alcotest.(check string) "repeated code" "non_square_free"
    (string "code" (assoc "error" repeated));
  let multiple =
    request
      [
        ("action", `String "certify");
        ("polynomial", sqrt2);
        ("lower", `String "-2");
        ("upper", `String "2");
      ]
  in
  Alcotest.(check bool) "multiple failure" false (bool "ok" multiple);
  Alcotest.(check string) "multiple code" "root_count_mismatch"
    (string "code" (assoc "error" multiple));
  let strict =
    request
      [
        ("action", `String "count_roots");
        ("polynomial", sqrt2);
        ("lower", `String "1");
        ("upper", `String "2");
        ("approximate", `Bool true);
      ]
  in
  Alcotest.(check bool) "strict failure" false (bool "ok" strict);
  Alcotest.(check string) "strict code" "invalid_request"
    (string "code" (assoc "error" strict))

let test_limits () =
  let limits =
    Centl_real_algebraic_protocol.{ default_limits with max_degree = 1 }
  in
  let response =
    Centl_real_algebraic_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "count_roots");
           ("polynomial", sqrt2);
           ("lower", `String "1");
           ("upper", `String "2");
         ])
  in
  Alcotest.(check bool) "degree failure" false (bool "ok" response);
  Alcotest.(check string) "degree code" "invalid_request"
    (string "code" (assoc "error" response));
  let step_limits =
    Centl_real_algebraic_protocol.{ default_limits with max_refinement_steps = 2 }
  in
  let response =
    Centl_real_algebraic_protocol.handle_json ~limits:step_limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "refine");
           ("polynomial", sqrt2);
           ("lower", `String "1");
           ("upper", `String "2");
           ("steps", `Int 3);
         ])
  in
  Alcotest.(check bool) "step failure" false (bool "ok" response);
  Alcotest.(check string) "step code" "resource_limit"
    (string "code" (assoc "error" response))

let () =
  Alcotest.run "centl real algebraic protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "capabilities" `Quick test_capabilities;
          Alcotest.test_case "certify sqrt2" `Quick test_certify_sqrt2;
          Alcotest.test_case "count and refine" `Quick test_count_and_refine;
          Alcotest.test_case "refusals" `Quick test_refusals;
          Alcotest.test_case "limits" `Quick test_limits;
        ] );
    ]
