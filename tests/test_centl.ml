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

let symbolic_examples () =
  Alcotest.(check string)
    "symbolic polynomial" "x^2 + 2 * x + 1" (value "x^2 + 2*x + 1");
  Alcotest.(check string)
    "polynomial derivative" "3 * x^2 + 2"
    (value "diff(x^3 + 2*x + 1, x)");
  Alcotest.(check string)
    "substitution" "10"
    (value "substitute(x^2 + 1, x = 3)");
  Alcotest.(check string)
    "trigonometric derivative" "cos(x)" (value "diff(sin(x), x)");
  Alcotest.(check string)
    "logarithmic derivative" "1 / x" (value "diff(log(x), x)");
  Alcotest.(check string)
    "formal derivative" "diff(f(x), x)" (value "diff(f(x), x)");
  Alcotest.(check string)
    "second derivative" "12 * x^2"
    (value "diff(diff(x^4, x), x)");
  Alcotest.(check string)
    "domain-preserving zero product" "0 * 1 / x" (value "0 * (1 / x)");
  Alcotest.(check string) "integer power" "1024" (value "2^10");
  Alcotest.(check string) "negative integer power" "1/8" (value "2^-3")

let failures () =
  Alcotest.(check string)
    "division by zero" "division_by_zero" (error_code "1 / (2 - 2)");
  Alcotest.(check string) "missing operand" "syntax_error" (error_code "1 +");
  Alcotest.(check string)
    "missing parenthesis" "syntax_error" (error_code "(1 + 2");
  Alcotest.(check string)
    "noninteger exponent" "syntax_error" (error_code "x^0.5");
  Alcotest.(check string)
    "zero to negative power" "division_by_zero" (error_code "0^-1");
  Alcotest.(check string)
    "zero to zero power" "undefined_power" (error_code "0^0")

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

let symbolic_json_protocol () =
  match
    Centl_engine.evaluate_request
      (`Assoc [ ("version", `Int 1); ("expression", `String "diff(x^3, x)") ])
  with
  | `Assoc fields ->
      begin match List.assoc_opt "value" fields with
      | Some (`Assoc value_fields) ->
          Alcotest.(check (option string))
            "symbolic kind" (Some "symbolic")
            (match List.assoc_opt "kind" value_fields with
            | Some (`String value) -> Some value
            | _ -> None);
          Alcotest.(check (option string))
            "canonical expression" (Some "3 * x^2")
            (match List.assoc_opt "expression" value_fields with
            | Some (`String value) -> Some value
            | _ -> None)
      | _ -> Alcotest.fail "response contained no symbolic value"
      end
  | _ -> Alcotest.fail "response was not a JSON object"

let coloration () =
  match Centl_engine.evaluate "diff(x^3, x)" with
  | Error error -> Alcotest.fail (Centl_engine.error_text error)
  | Ok result ->
      Alcotest.(check string)
        "plain mathematical text" "3 * x^2"
        (Centl_engine.text_of_value result);
      Alcotest.(check string)
        "semantic ANSI colors"
        "\027[96m3\027[0m\027[93m * \
         \027[0m\027[95mx\027[0m\027[93m^\027[0m\027[96m2\027[0m"
        (Centl_engine.colored_text_of_value result)

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

let property_quadratic_derivative () =
  let input =
    QCheck.quad QCheck.int_small QCheck.int_small QCheck.int_small
      QCheck.int_small
  in
  let test =
    QCheck.Test.make ~count:1_000 input (fun (a, b, c, x) ->
        let source =
          Printf.sprintf
            "substitute(diff((%d)*x^2 + (%d)*x + (%d), x), x = (%d))" a b c x
        in
        value source = string_of_int ((2 * a * x) + b))
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
      ( "symbolic calculus",
        [
          Alcotest.test_case "examples" `Quick symbolic_examples;
          Alcotest.test_case "quadratic derivative property" `Quick
            property_quadratic_derivative;
        ] );
      ("errors", [ Alcotest.test_case "structured failures" `Quick failures ]);
      ( "machine interface",
        [
          Alcotest.test_case "versioned request" `Quick json_protocol;
          Alcotest.test_case "symbolic result" `Quick symbolic_json_protocol;
        ] );
      ("presentation", [ Alcotest.test_case "coloration" `Quick coloration ]);
    ]
