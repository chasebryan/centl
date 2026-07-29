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

let session_text session source =
  match Centl_engine.evaluate_in_session session source with
  | Ok result -> Centl_engine.text_of_session_result result
  | Error error -> Alcotest.fail (Centl_engine.error_text error)

let session_error_code session source =
  match Centl_engine.evaluate_in_session session source with
  | Ok result ->
      Alcotest.failf "expected an error, received %s"
        (Centl_engine.text_of_session_result result)
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
  Alcotest.(check string)
    "large integer power" "1267650600228229401496703205376" (value "2^100");
  Alcotest.(check string) "negative integer power" "1/8" (value "2^-3")

let algebra_examples () =
  Alcotest.(check string)
    "collect coefficients" "5 * x"
    (value "simplify(2*x + 3*x)");
  Alcotest.(check string)
    "exact rational coefficients" "5/6 * x"
    (value "simplify(1/2*x + 1/3*x)");
  Alcotest.(check string)
    "expand binomial" "x^3 + 3 * x^2 + 3 * x + 1"
    (value "expand((x + 1)^3)");
  Alcotest.(check string)
    "difference of squares" "(x - 1) * (x + 1)" (value "factor(x^2 - 1)");
  Alcotest.(check string)
    "higher difference of squares" "(x^2 - 1) * (x^2 + 1)"
    (value "factor(x^4 - 1)");
  Alcotest.(check string)
    "multivariate difference of squares" "(x - y) * (x + y)"
    (value "factor(x^2 - y^2)");
  Alcotest.(check string)
    "common monomial" "x^2 * (x + 1)"
    (value "factor(x^3 + x^2)");
  Alcotest.(check string)
    "bounded expansion" "(x + 1)^65"
    (value "expand((x + 1)^65)")

let equation_examples () =
  Alcotest.(check string)
    "linear equation" "x = 4"
    (value "solve(2*x + 3 = 11, x)");
  Alcotest.(check string)
    "terms on both sides" "x = 4"
    (value "solve(3*x + 2 = x + 10, x)");
  Alcotest.(check string)
    "rational coefficients" "x = 1"
    (value "solve(x/3 + 1/2 = 5/6, x)");
  Alcotest.(check string)
    "two rational roots" "x in {1/2, 2}"
    (value "solve(2*x^2 - 5*x + 2 = 0, x)");
  Alcotest.(check string)
    "repeated root" "x = 3"
    (value "solve((x - 3)^2 = 0, x)");
  Alcotest.(check string)
    "no real solutions" "no solutions"
    (value "solve(x^2 + 1 = 0, x)");
  Alcotest.(check string)
    "identity" "all values of x"
    (value "solve(x + 1 = x + 1, x)");
  Alcotest.(check string)
    "false constant equation" "no solutions" (value "solve(1 = 2, x)");
  Alcotest.(check string)
    "irrational roots remain explicit" "unresolved: solve(x^2 = 2, x)"
    (value "solve(x^2 = 2, x)");
  Alcotest.(check string)
    "higher degree remains explicit" "unresolved: solve(x^3 = 1, x)"
    (value "solve(x^3 = 1, x)")

let assumption_examples () =
  Alcotest.(check string)
    "safe cancellation" "1 where x != 0"
    (value "assuming(x / x, x != 0)");
  Alcotest.(check string)
    "strict positivity" "1 / x where x > 0"
    (value "assuming(diff(log(x), x), x > 0)");
  Alcotest.(check string)
    "insufficient assumption" "x / x where x >= 0"
    (value "assuming(x / x, x >= 0)")

let geometry_examples () =
  Alcotest.(check string)
    "Pythagorean distance" "5"
    (value "distance(0, 0, 3, 4)");
  Alcotest.(check string) "rational square root" "2/3" (value "sqrt(4/9)");
  Alcotest.(check string)
    "rectangle area" "42"
    (value "rectangle_area(12, 7/2)");
  Alcotest.(check string) "triangle area" "15" (value "triangle_area(10, 3)");
  Alcotest.(check string)
    "trapezoid area" "16"
    (value "trapezoid_area(3, 5, 4)");
  Alcotest.(check string) "circle area" "9 * pi" (value "circle_area(3)");
  Alcotest.(check string) "sphere volume" "36 * pi" (value "sphere_volume(3)");
  Alcotest.(check string) "slope" "1/2" (value "slope(0, 0, 4, 2)");
  Alcotest.(check string) "degrees to radians" "pi" (value "radians(180)");
  Alcotest.(check string) "radians to degrees" "180" (value "degrees(pi)")

let concrete_math_examples () =
  Alcotest.(check string) "greatest common divisor" "6" (value "gcd(-48, 18)");
  Alcotest.(check string) "least common multiple" "42" (value "lcm(-21, 6)");
  Alcotest.(check string)
    "factorial" "2432902008176640000" (value "factorial(20)");
  Alcotest.(check string)
    "binomial coefficient" "2598960" (value "choose(52, 5)");
  Alcotest.(check string) "permutations" "720" (value "permutations(10, 3)");
  Alcotest.(check string)
    "Fibonacci" "354224848179261915075" (value "fibonacci(100)")

let enclosure source =
  match Centl_engine.evaluate source with
  | Ok (Centl_engine.Real_enclosure result) -> result
  | Ok result ->
      Alcotest.failf "expected a real enclosure, received %s"
        (Centl_engine.text_of_value result)
  | Error error -> Alcotest.fail (Centl_engine.error_text error)

let rational_of_enclosure_endpoint mantissa exponent =
  if exponent >= 0 then Q.mul_2exp (Q.of_bigint mantissa) exponent
  else Q.div_2exp (Q.of_bigint mantissa) (-exponent)

let rigorous_approximation () =
  let square_root = enclosure "approx(sqrt(2), 20)" in
  let lower =
    rational_of_enclosure_endpoint square_root.lower_mantissa
      square_root.binary_exponent
  in
  let upper =
    rational_of_enclosure_endpoint square_root.upper_mantissa
      square_root.binary_exponent
  in
  let two = Q.of_int 2 in
  Alcotest.(check bool)
    "sqrt lower bound" true
    (Q.compare (Q.mul lower lower) two <= 0);
  Alcotest.(check bool)
    "sqrt upper bound" true
    (Q.compare (Q.mul upper upper) two >= 0);
  Alcotest.(check int)
    "requested significant digits" 20 square_root.requested_digits;
  let sine = enclosure "approx(sin(pi / 6), 20)" in
  let sine_lower =
    rational_of_enclosure_endpoint sine.lower_mantissa sine.binary_exponent
  in
  let sine_upper =
    rational_of_enclosure_endpoint sine.upper_mantissa sine.binary_exponent
  in
  let half = Q.make Z.one (Z.of_int 2) in
  Alcotest.(check bool)
    "sin(pi/6) lower containment" true
    (Q.compare sine_lower half <= 0);
  Alcotest.(check bool)
    "sin(pi/6) upper containment" true
    (Q.compare sine_upper half >= 0)

let enclosure_contains (enclosure : Centl_engine.real_enclosure) expected =
  let lower =
    rational_of_enclosure_endpoint enclosure.lower_mantissa
      enclosure.binary_exponent
  in
  let upper =
    rational_of_enclosure_endpoint enclosure.upper_mantissa
      enclosure.binary_exponent
  in
  Q.compare lower expected <= 0 && Q.compare expected upper <= 0

let elementary_function_smoke () =
  [
    "approx(exp(1), 20)";
    "approx(log(2), 20)";
    "approx(tan(1/4), 20)";
    "approx(asin(1/2), 20)";
    "approx(acos(1/2), 20)";
    "approx(atan(1), 20)";
    "approx(atan2(1, -1), 20)";
    "approx(sinh(1), 20)";
    "approx(cosh(1), 20)";
    "approx(tanh(1), 20)";
    "approx(abs(-3/2), 20)";
  ]
  |> List.iter (fun source -> ignore (enclosure source));
  Alcotest.(check bool)
    "trigonometric identity contains one" true
    (enclosure_contains (enclosure "approx(sin(1)^2 + cos(1)^2, 25)") Q.one);
  Alcotest.(check bool)
    "log-exp identity contains one" true
    (enclosure_contains (enclosure "approx(log(exp(1)), 25)") Q.one)

let approximation_failures () =
  Alcotest.(check string)
    "negative square root" "domain_error"
    (error_code "approx(sqrt(-1), 20)");
  Alcotest.(check string)
    "precision budget" "precision_limit"
    (error_code "approx(pi, 1001)");
  Alcotest.(check string)
    "unresolved variable" "unsupported_approximation"
    (error_code "approx(x, 20)")

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
    "zero to zero power" "undefined_power" (error_code "0^0");
  Alcotest.(check string)
    "division by zero in equation" "division_by_zero"
    (error_code "solve(x / 0 = 1, x)");
  Alcotest.(check string)
    "missing equation equality" "syntax_error"
    (error_code "solve(x + 1, x)");
  Alcotest.(check string)
    "missing solution variable" "syntax_error"
    (error_code "solve(x = 1, 2)");
  Alcotest.(check string)
    "constant as solution variable" "invalid_solution_variable"
    (error_code "solve(pi = 3, pi)");
  Alcotest.(check string)
    "solution set used as a number" "solution_set_not_expression"
    (error_code "solve(x = 1, x) + 2")

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

let enclosure_json_protocol () =
  match
    Centl_engine.evaluate_request
      (`Assoc [ ("version", `Int 1); ("expression", `String "approx(pi, 25)") ])
  with
  | `Assoc fields ->
      begin match List.assoc_opt "value" fields with
      | Some (`Assoc value_fields) ->
          Alcotest.(check (option string))
            "enclosure kind" (Some "real_enclosure")
            (match List.assoc_opt "kind" value_fields with
            | Some (`String value) -> Some value
            | _ -> None);
          Alcotest.(check (option bool))
            "approximate classification" (Some false)
            (match List.assoc_opt "exact" value_fields with
            | Some (`Bool value) -> Some value
            | _ -> None);
          begin match List.assoc_opt "precision" value_fields with
          | Some (`Assoc precision) ->
              Alcotest.(check (option bool))
                "rigorous backend" (Some true)
                (match List.assoc_opt "rigorous" precision with
                | Some (`Bool value) -> Some value
                | _ -> None)
          | _ -> Alcotest.fail "response contained no precision metadata"
          end;
          begin match List.assoc_opt "decimal" value_fields with
          | Some (`Assoc decimal) ->
              Alcotest.(check (option int))
                "certified digits" (Some 25)
                (match
                   List.assoc_opt "certified_significant_digits" decimal
                 with
                | Some (`Int value) -> Some value
                | _ -> None)
          | _ -> Alcotest.fail "response contained no decimal metadata"
          end
      | _ -> Alcotest.fail "response contained no enclosure"
      end
  | _ -> Alcotest.fail "response was not a JSON object"

let conditional_json_protocol () =
  match
    Centl_engine.evaluate_request
      (`Assoc
         [
           ("version", `Int 1); ("expression", `String "assuming(x/x, x != 0)");
         ])
  with
  | `Assoc fields ->
      begin match List.assoc_opt "value" fields with
      | Some (`Assoc value_fields) ->
          begin match List.assoc_opt "conditions" value_fields with
          | Some (`List [ `Assoc condition ]) ->
              Alcotest.(check (option string))
                "condition relation" (Some "not_equal")
                (match List.assoc_opt "relation" condition with
                | Some (`String value) -> Some value
                | _ -> None)
          | _ -> Alcotest.fail "response contained no structured condition"
          end
      | _ -> Alcotest.fail "response contained no conditional value"
      end
  | _ -> Alcotest.fail "response was not a JSON object"

let equation_json_protocol () =
  match
    Centl_engine.evaluate_request
      (`Assoc
         [
           ("version", `Int 1); ("expression", `String "solve(x^2 - 1 = 0, x)");
         ])
  with
  | `Assoc fields ->
      begin match List.assoc_opt "value" fields with
      | Some (`Assoc value_fields) ->
          Alcotest.(check (option string))
            "solution-set kind" (Some "solution_set")
            (match List.assoc_opt "kind" value_fields with
            | Some (`String value) -> Some value
            | _ -> None);
          Alcotest.(check (option string))
            "finite status" (Some "finite")
            (match List.assoc_opt "status" value_fields with
            | Some (`String value) -> Some value
            | _ -> None);
          Alcotest.(check (option bool))
            "resolved result" (Some true)
            (match List.assoc_opt "resolved" value_fields with
            | Some (`Bool value) -> Some value
            | _ -> None);
          Alcotest.(check (option int))
            "two solutions" (Some 2)
            (match List.assoc_opt "solutions" value_fields with
            | Some (`List values) -> Some (List.length values)
            | _ -> None)
      | _ -> Alcotest.fail "response contained no solution set"
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

let definition_examples () =
  let session = Centl_engine.create_session () in
  Alcotest.(check string)
    "define a value" "r = 3"
    (session_text session "r = 3");
  Alcotest.(check string)
    "use a value" "9 * pi"
    (session_text session "circle_area(r)");
  Alcotest.(check string)
    "define a function" "f(x) = x^2 + 1"
    (session_text session "f(x) = x^2 + 1");
  Alcotest.(check string) "call a function" "10" (session_text session "f(3)");
  Alcotest.(check string)
    "differentiate a function" "2 * x"
    (session_text session "diff(f(x), x)");
  let multivariate = Centl_engine.create_session () in
  ignore (session_text multivariate "difference(x, y) = x - y");
  Alcotest.(check string)
    "simultaneous substitution" "y - x"
    (session_text multivariate "difference(y, x)");
  let nested = Centl_engine.create_session () in
  ignore (session_text nested "shift(x) = x + 1");
  Alcotest.(check string)
    "compose definitions" "square_shift(x) = (x + 1)^2"
    (session_text nested "square_shift(x) = shift(x)^2");
  Alcotest.(check string)
    "call composed definition" "16"
    (session_text nested "square_shift(3)");
  let bound = Centl_engine.create_session () in
  ignore (session_text bound "x = 3");
  Alcotest.(check string)
    "calculus variable shadows a value" "2 * x"
    (session_text bound "diff(x^2, x)");
  Alcotest.(check string)
    "substitution variable shadows a value" "9"
    (session_text bound "substitute(x^2, x = 3)");
  ignore (session_text bound "square(x) = x^2");
  Alcotest.(check string)
    "function parameter shadows a value" "16"
    (session_text bound "square(4)");
  Alcotest.(check string)
    "solution variable shadows a value" "x in {-2, 2}"
    (session_text bound "solve(x^2 = 4, x)");
  let captured = Centl_engine.create_session () in
  ignore (session_text captured "a = 2");
  Alcotest.(check string)
    "definitions use prior values" "b = 5"
    (session_text captured "b = a + 3");
  Alcotest.(check string) "resolved definition" "5" (session_text captured "b");
  let exact = Centl_engine.create_session () in
  ignore (session_text exact "angle = pi / 6");
  Alcotest.(check bool)
    "definitions can be approximated when used" true
    (match Centl_engine.evaluate_in_session exact "approx(sin(angle), 20)" with
    | Ok (Centl_engine.Session_value (Centl_engine.Real_enclosure _)) -> true
    | _ -> false)

let definition_failures () =
  let immutable = Centl_engine.create_session () in
  ignore (session_text immutable "r = 3");
  Alcotest.(check string)
    "immutable names" "immutable_definition"
    (session_error_code immutable "r = 4");
  Alcotest.(check string)
    "failed redefinition changes nothing" "3"
    (session_text immutable "r");
  let error source =
    session_error_code (Centl_engine.create_session ()) source
  in
  Alcotest.(check string) "reserved name" "reserved_name" (error "pi = 3");
  Alcotest.(check string)
    "empty parameters" "invalid_definition" (error "f() = 3");
  Alcotest.(check string)
    "duplicate parameters" "invalid_definition" (error "f(x, x) = x");
  Alcotest.(check string)
    "self-referencing value" "recursive_definition" (error "a = a + 1");
  Alcotest.(check string)
    "self-referencing function" "recursive_definition" (error "f(x) = f(x) + 1");
  Alcotest.(check string)
    "approximate definition" "exact_definition_required"
    (error "a = approx(pi, 20)");
  Alcotest.(check string)
    "solution-set definition" "expression_definition_required"
    (error "roots = solve(x^2 = 1, x)");
  let arity = Centl_engine.create_session () in
  ignore (session_text arity "f(x) = x^2");
  Alcotest.(check string)
    "wrong arity" "invalid_arguments"
    (session_error_code arity "f(1, 2)");
  let isolated = Centl_engine.create_session () in
  Alcotest.(check string)
    "sessions are isolated" "r"
    (session_text isolated "r")

let contains text fragment =
  let text_length = String.length text in
  let fragment_length = String.length fragment in
  let rec search offset =
    if offset + fragment_length > text_length then false
    else if String.sub text offset fragment_length = fragment then true
    else search (offset + 1)
  in
  fragment_length = 0 || search 0

let syntax_catalog () =
  let entries =
    Array.to_list Centl_syntax.sections
    |> List.concat_map (fun (section : Centl_syntax.section) ->
        Array.to_list section.entries)
  in
  Alcotest.(check bool) "substantial catalog" true (List.length entries >= 60);
  let forms =
    List.map (fun (entry : Centl_syntax.entry) -> entry.form) entries
  in
  let unique_forms = List.sort_uniq String.compare forms in
  Alcotest.(check int)
    "each form appears once" (List.length forms) (List.length unique_forms);
  let sheet = Centl_syntax.plain_text () in
  Alcotest.(check bool) "compact heading" true (contains sheet "CENTL syntax");
  Alcotest.(check bool) "examples block" true (contains sheet "examples:");
  Alcotest.(check bool) "no fixed-width table" false (contains sheet "| group");
  Alcotest.(check bool)
    "small output" true
    (List.length (String.split_on_char '\n' sheet) <= 16);
  let identifiers =
    List.map Centl_syntax.identifier_of_form forms
    |> List.sort_uniq String.compare
  in
  List.iter
    (fun identifier ->
      Alcotest.(check bool)
        ("terminal sheet includes " ^ identifier)
        true
        (contains sheet identifier))
    identifiers;
  let channel = open_in "../docs/SYNTAX.md" in
  let documentation =
    Fun.protect
      ~finally:(fun () -> close_in channel)
      (fun () -> really_input_string channel (in_channel_length channel))
  in
  List.iter
    (fun form ->
      Alcotest.(check bool)
        ("documentation includes " ^ form)
        true
        (contains documentation ("`" ^ form ^ "`")))
    forms;
  Array.iter
    (fun (example : Centl_syntax.example) ->
      let session = Centl_engine.create_session () in
      Alcotest.(check string)
        ("example result for " ^ example.calculation)
        example.result
        (session_text session example.calculation))
    Centl_syntax.examples

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

let property_cubic_derivative () =
  let small = QCheck.make QCheck.Gen.(-25 -- 25) in
  let input = QCheck.pair (QCheck.quad small small small small) small in
  let test =
    QCheck.Test.make ~count:1_000 input (fun ((a, b, c, d), x) ->
        let source =
          Printf.sprintf
            "substitute(simplify(diff((%d)*x^3 + (%d)*x^2 + (%d)*x + (%d), \
             x)), x = (%d))"
            a b c d x
        in
        let expected = (3 * a * x * x) + (2 * b * x) + c in
        value source = (Z.of_int expected |> Z.to_string))
  in
  QCheck.Test.check_exn test

let property_binomial_expansion () =
  let small = QCheck.make QCheck.Gen.(-10 -- 10) in
  let exponent = QCheck.make QCheck.Gen.(1 -- 6) in
  let input = QCheck.quad small small small exponent in
  let test =
    QCheck.Test.make ~count:1_000 input (fun (a, b, x, exponent) ->
        let source =
          Printf.sprintf "substitute(expand(((%d)*x + (%d))^%d), x = (%d))" a b
            exponent x
        in
        let expected = Z.pow (Z.of_int ((a * x) + b)) exponent |> Z.to_string in
        value source = expected)
  in
  QCheck.Test.check_exn test

let property_coefficient_collection () =
  let small = QCheck.make QCheck.Gen.(-100 -- 100) in
  let input = QCheck.triple small small small in
  let test =
    QCheck.Test.make ~count:1_000 input (fun (a, b, x) ->
        let source =
          Printf.sprintf "substitute(simplify((%d)*x + (%d)*x), x = (%d))" a b x
        in
        value source = (Z.of_int ((a + b) * x) |> Z.to_string))
  in
  QCheck.Test.check_exn test

let property_linear_solving () =
  let coefficient = QCheck.make QCheck.Gen.(oneof [ 1 -- 100; -100 -- -1 ]) in
  let small = QCheck.make QCheck.Gen.(-100 -- 100) in
  let input = QCheck.triple coefficient small small in
  let test =
    QCheck.Test.make ~count:1_000 input (fun (a, b, root) ->
        let right = (a * root) + b in
        let source =
          Printf.sprintf "solve((%d)*x + (%d) = (%d), x)" a b right
        in
        value source = Printf.sprintf "x = %d" root)
  in
  QCheck.Test.check_exn test

let property_quadratic_solving () =
  let coefficient = QCheck.make QCheck.Gen.(oneof [ 1 -- 20; -20 -- -1 ]) in
  let root = QCheck.make QCheck.Gen.(-30 -- 30) in
  let input = QCheck.triple coefficient root root in
  let test =
    QCheck.Test.make ~count:1_000 input (fun (a, first, second) ->
        let source =
          Printf.sprintf "solve((%d) * (x - (%d)) * (x - (%d)) = 0, x)" a first
            second
        in
        let expected =
          if first = second then Printf.sprintf "x = %d" first
          else
            Printf.sprintf "x in {%d, %d}" (min first second) (max first second)
        in
        value source = expected)
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
          Alcotest.test_case "cubic derivative property" `Quick
            property_cubic_derivative;
        ] );
      ( "symbolic algebra",
        [
          Alcotest.test_case "examples" `Quick algebra_examples;
          Alcotest.test_case "binomial expansion property" `Quick
            property_binomial_expansion;
          Alcotest.test_case "coefficient collection property" `Quick
            property_coefficient_collection;
        ] );
      ( "equation solving",
        [
          Alcotest.test_case "exact classifications" `Quick equation_examples;
          Alcotest.test_case "linear root property" `Quick
            property_linear_solving;
          Alcotest.test_case "quadratic root property" `Quick
            property_quadratic_solving;
        ] );
      ( "definitions",
        [
          Alcotest.test_case "values and functions" `Quick definition_examples;
          Alcotest.test_case "immutable failures" `Quick definition_failures;
        ] );
      ( "assumptions",
        [
          Alcotest.test_case "domain-aware examples" `Quick assumption_examples;
        ] );
      ( "geometry",
        [ Alcotest.test_case "exact formulas" `Quick geometry_examples ] );
      ( "concrete mathematics",
        [ Alcotest.test_case "exact primitives" `Quick concrete_math_examples ]
      );
      ( "rigorous approximation",
        [
          Alcotest.test_case "Arb containment" `Quick rigorous_approximation;
          Alcotest.test_case "elementary function smoke" `Quick
            elementary_function_smoke;
          Alcotest.test_case "structured failures" `Quick approximation_failures;
        ] );
      ("errors", [ Alcotest.test_case "structured failures" `Quick failures ]);
      ( "machine interface",
        [
          Alcotest.test_case "versioned request" `Quick json_protocol;
          Alcotest.test_case "symbolic result" `Quick symbolic_json_protocol;
          Alcotest.test_case "rigorous enclosure" `Quick enclosure_json_protocol;
          Alcotest.test_case "structured condition" `Quick
            conditional_json_protocol;
          Alcotest.test_case "structured solution set" `Quick
            equation_json_protocol;
        ] );
      ( "presentation",
        [
          Alcotest.test_case "coloration" `Quick coloration;
          Alcotest.test_case "syntax catalog" `Quick syntax_catalog;
        ] );
    ]
