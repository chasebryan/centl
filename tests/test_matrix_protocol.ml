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

let rational text = `String text

let matrix rows =
  `List
    (List.map
       (fun row -> `List (List.map rational row))
       rows)

let vector values = `List (List.map rational values)

let request fields =
  Centl_matrix_protocol.handle_json (`Assoc (("version", `Int 1) :: fields))

let test_capabilities () =
  let response = request [ ("action", `String "capabilities") ] in
  Alcotest.(check bool) "success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "matrix_capabilities" (string "kind" result);
  let limits = assoc "limits" result in
  Alcotest.(check int) "entry limit" 4096 (int "max_entries" limits)

let test_multiply_and_determinant () =
  let a = matrix [ [ "1"; "2" ]; [ "3"; "4" ] ] in
  let b = matrix [ [ "5"; "6" ]; [ "7"; "8" ] ] in
  let response =
    request
      [
        ("id", `String "mul");
        ("action", `String "multiply");
        ("left", a);
        ("right", b);
      ]
  in
  Alcotest.(check bool) "multiply success" true (bool "ok" response);
  Alcotest.(check string) "id" "mul" (string "id" response);
  let result = assoc "result" response in
  Alcotest.(check string) "kind" "rational_matrix" (string "kind" result);
  begin match assoc "entries" result with
  | `List [ `List [ e00; e01 ]; `List [ e10; e11 ] ] ->
      Alcotest.(check string) "00" "19" (string "numerator" e00);
      Alcotest.(check string) "01" "22" (string "numerator" e01);
      Alcotest.(check string) "10" "43" (string "numerator" e10);
      Alcotest.(check string) "11" "50" (string "numerator" e11)
  | _ -> Alcotest.fail "unexpected matrix entries"
  end;
  let determinant =
    request [ ("action", `String "determinant"); ("matrix", a) ]
  in
  Alcotest.(check bool) "det success" true (bool "ok" determinant);
  Alcotest.(check string) "det numerator" "-2"
    (string "numerator" (assoc "result" determinant))

let test_rref_and_inverse () =
  let singular = matrix [ [ "1"; "2"; "3" ]; [ "2"; "4"; "6" ] ] in
  let response =
    request [ ("action", `String "rref"); ("matrix", singular) ]
  in
  Alcotest.(check bool) "rref success" true (bool "ok" response);
  let result = assoc "result" response in
  Alcotest.(check int) "rank" 1 (int "rank" result);
  begin match assoc "pivot_columns" result with
  | `List [ `Int 0 ] -> ()
  | _ -> Alcotest.fail "unexpected pivot columns"
  end;
  let inverse =
    request
      [
        ("action", `String "inverse");
        ("matrix", matrix [ [ "1"; "2" ]; [ "2"; "4" ] ]);
      ]
  in
  Alcotest.(check bool) "singular failure" false (bool "ok" inverse);
  Alcotest.(check string) "singular code" "singular_matrix"
    (string "code" (assoc "error" inverse))

let test_solve_decisions () =
  let a = matrix [ [ "1"; "2" ]; [ "3"; "4" ] ] in
  let unique =
    request
      [
        ("action", `String "solve");
        ("matrix", a);
        ("rhs", vector [ "5"; "11" ]);
      ]
  in
  Alcotest.(check bool) "unique success" true (bool "ok" unique);
  let unique_result = assoc "result" unique in
  Alcotest.(check string) "unique decision" "unique"
    (string "decision" unique_result);
  begin match assoc "entries" (assoc "solution" unique_result) with
  | `List [ x; y ] ->
      Alcotest.(check string) "x" "1" (string "numerator" x);
      Alcotest.(check string) "y" "2" (string "numerator" y)
  | _ -> Alcotest.fail "unexpected unique solution"
  end;
  let singular = matrix [ [ "1"; "1" ]; [ "2"; "2" ] ] in
  let none =
    request
      [
        ("action", `String "solve");
        ("matrix", singular);
        ("rhs", vector [ "1"; "3" ]);
      ]
  in
  Alcotest.(check string) "no-solution decision" "no_solution"
    (string "decision" (assoc "result" none));
  let infinite =
    request
      [
        ("action", `String "solve");
        ("matrix", singular);
        ("rhs", vector [ "1"; "2" ]);
      ]
  in
  let infinite_result = assoc "result" infinite in
  Alcotest.(check string) "infinite decision" "infinite"
    (string "decision" infinite_result);
  Alcotest.(check int) "parameter count" 1 (int "parameter_count" infinite_result)

let test_strict_and_limits () =
  let strict =
    request
      [
        ("action", `String "determinant");
        ("matrix", matrix [ [ "1" ] ]);
        ("approximate", `Bool true);
      ]
  in
  Alcotest.(check bool) "strict failure" false (bool "ok" strict);
  Alcotest.(check string) "strict code" "invalid_request"
    (string "code" (assoc "error" strict));
  let limits =
    Centl_matrix_protocol.{ default_limits with max_rows = 1; max_entries = 2 }
  in
  let limited =
    Centl_matrix_protocol.handle_json ~limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "rank");
           ("matrix", matrix [ [ "1" ]; [ "2" ] ]);
         ])
  in
  Alcotest.(check bool) "limit failure" false (bool "ok" limited);
  Alcotest.(check string) "limit code" "invalid_request"
    (string "code" (assoc "error" limited));
  let work_limits =
    Centl_matrix_protocol.{ default_limits with max_work = 1 }
  in
  let work =
    Centl_matrix_protocol.handle_json ~limits:work_limits
      (`Assoc
         [
           ("version", `Int 1);
           ("action", `String "determinant");
           ("matrix", matrix [ [ "1"; "2" ]; [ "3"; "4" ] ]);
         ])
  in
  Alcotest.(check bool) "work failure" false (bool "ok" work);
  Alcotest.(check string) "work code" "resource_limit"
    (string "code" (assoc "error" work))

let () =
  Alcotest.run "centl exact rational matrix protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "capabilities" `Quick test_capabilities;
          Alcotest.test_case "multiply and determinant" `Quick
            test_multiply_and_determinant;
          Alcotest.test_case "rref and inverse" `Quick test_rref_and_inverse;
          Alcotest.test_case "solve decisions" `Quick test_solve_decisions;
          Alcotest.test_case "strict and limits" `Quick test_strict_and_limits;
        ] );
    ]
