let value source =
  match Centl_engine.evaluate source with
  | Ok value -> Centl_engine.text_of_value value
  | Error error -> Alcotest.fail (Centl_engine.error_text error)

let error_code source =
  match Centl_engine.evaluate source with
  | Ok result ->
      Alcotest.failf "expected an error, received %s"
        (Centl_engine.text_of_value result)
  | Error error -> error.code

let exact_examples () =
  Alcotest.(check string) "finite decimals" "3/10" (value "0.1 + 0.2");
  Alcotest.(check string) "fractions" "1/2" (value "1/3 + 1/6");
  Alcotest.(check string) "subtraction" "-3" (value "2 - 5");
  Alcotest.(check string) "multiplication" "3/2" (value "2/3 * 9/4");
  Alcotest.(check string) "division" "5/6" (value "(2/3) / (4/5)");
  Alcotest.(check string) "precedence" "7" (value "1 + 2 * 3");
  Alcotest.(check string) "parentheses" "9" (value "(1 + 2) * 3");
  Alcotest.(check string) "unary signs" "-1/2" (value "1 / -2");
  Alcotest.(check string) "leading decimal point" "1/2" (value ".5");
  Alcotest.(check string) "trailing decimal point" "2" (value "2.");
  Alcotest.(check string)
    "arbitrary precision" "100000000000000000000000000000000000001"
    (value "100000000000000000000000000000000000000 + 1")

let failures () =
  Alcotest.(check string)
    "division by zero" "division_by_zero" (error_code "1 / (2 - 2)");
  Alcotest.(check string) "missing operand" "syntax_error" (error_code "1 +");
  Alcotest.(check string)
    "missing parenthesis" "syntax_error" (error_code "(1 + 2")

let json_protocol () =
  let request = `Assoc [ ("version", `Int 1); ("expression", `String "2/4") ] in
  match Centl_engine.evaluate_request request with
  | `Assoc fields ->
      Alcotest.(check (option bool))
        "request succeeds" (Some true)
        (match List.assoc_opt "ok" fields with
        | Some (`Bool value) -> Some value
        | _ -> None)
  | _ -> Alcotest.fail "response was not a JSON object"

let property_integer_addition () =
  let test =
    QCheck.Test.make ~count:1_000
      QCheck.(pair int_small int_small)
      (fun (left, right) ->
        let source = Printf.sprintf "%d + %d" left right in
        value source = string_of_int (left + right))
  in
  QCheck.Test.check_exn test

let property_fraction_addition () =
  let positive = QCheck.make QCheck.Gen.(1 -- 100) in
  let input = QCheck.quad QCheck.int_small positive QCheck.int_small positive in
  let test =
    QCheck.Test.make ~count:1_000 input (fun (a, b, c, d) ->
        let source = Printf.sprintf "%d/%d + %d/%d" a b c d in
        let expected =
          Q.add
            (Q.make (Z.of_int a) (Z.of_int b))
            (Q.make (Z.of_int c) (Z.of_int d))
        in
        value source = Q.to_string expected)
  in
  QCheck.Test.check_exn test

let property_fraction_operators () =
  let positive = QCheck.make QCheck.Gen.(1 -- 100) in
  let nonzero = QCheck.make QCheck.Gen.(oneof [ 1 -- 100; -100 -- -1 ]) in
  let input = QCheck.quad QCheck.int_small positive nonzero positive in
  let test =
    QCheck.Test.make ~count:1_000 input (fun (a, b, c, d) ->
        let left = Q.make (Z.of_int a) (Z.of_int b) in
        let right = Q.make (Z.of_int c) (Z.of_int d) in
        let check operator operation =
          let source = Printf.sprintf "(%d/%d) %s (%d/%d)" a b operator c d in
          value source = Q.to_string (operation left right)
        in
        check "-" Q.sub && check "*" Q.mul && check "/" Q.div)
  in
  QCheck.Test.check_exn test

let () =
  Alcotest.run "centl"
    [
      ( "exact arithmetic",
        [
          Alcotest.test_case "examples" `Quick exact_examples;
          Alcotest.test_case "integer addition property" `Quick
            property_integer_addition;
          Alcotest.test_case "fraction addition property" `Quick
            property_fraction_addition;
          Alcotest.test_case "fraction operator properties" `Quick
            property_fraction_operators;
        ] );
      ("errors", [ Alcotest.test_case "structured failures" `Quick failures ]);
      ( "machine interface",
        [ Alcotest.test_case "versioned request" `Quick json_protocol ] );
    ]
