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

let evaluation_error source =
  match Centl_engine.evaluate source with
  | Ok result ->
      Alcotest.failf "expected an error, received %s"
        (Centl_engine.text_of_value result)
  | Error error -> error

let session_evaluation_error session source =
  match Centl_engine.evaluate_in_session session source with
  | Ok result ->
      Alcotest.failf "expected an error, received %s"
        (Centl_engine.text_of_session_result result)
  | Error error -> error

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

let integration_examples () =
  Alcotest.(check string)
    "canonical cubic antiderivative" "x^3 + x^2 + x"
    (value "integrate(3*x^2 + 2*x + 1, x)");
  Alcotest.(check string)
    "rational coefficients" "1/8 * x^4 - 3/8 * x^2 + 5 * x"
    (value "integrate(1/2*x^3 - 3/4*x + 5, x)");
  Alcotest.(check string)
    "constant antiderivative" "6 * x" (value "integrate(6, x)");
  Alcotest.(check string)
    "integer definite bounds" "9"
    (value "integrate(x^2, x = 0, 3)");
  Alcotest.(check string)
    "rational definite bounds" "1/24"
    (value "integrate(x^2, x = 0, 1/2)");
  Alcotest.(check string)
    "reversed definite bounds" "-9"
    (value "integrate(x^2, x = 3, 0)");
  Alcotest.(check string)
    "derivative round trip" "3 * x^2 + 2 * x + 1"
    (value "diff(integrate(3*x^2 + 2*x + 1, x), x)")

let integration_residuals_and_failures () =
  Alcotest.(check string)
    "transcendental integral remains visible" "integrate(sin(x), x)"
    (value "integrate(sin(x), x)");
  Alcotest.(check string)
    "non-polynomial integral remains visible" "integrate(1 / x, x)"
    (value "integrate(1/x, x)");
  Alcotest.(check string)
    "explicit zero power preserves its undefined point" "integrate(x^0, x)"
    (value "integrate(x^0, x)");
  Alcotest.(check string)
    "symbolic bound remains visible" "integrate(x^2, x = 0, a)"
    (value "integrate(x^2, x = 0, a)");
  [
    "integrate(x^2)";
    "integrate(x^2, 3)";
    "integrate(x^2, x, 0, 1)";
    "integrate(x^2, x = 0)";
    "integrate(x^2, x = 0,)";
  ]
  |> List.iter (fun source ->
      Alcotest.(check string)
        ("malformed form: " ^ source)
        "syntax_error" (error_code source))

let integration_binder_scope () =
  let scoped = Centl_engine.create_session () in
  ignore (session_text scoped "x = 4");
  Alcotest.(check string)
    "integrand binder shadows a session value" "1/3 * x^3"
    (session_text scoped "integrate(x^2, x)");
  Alcotest.(check string)
    "definite upper bound uses surrounding scope" "8"
    (session_text scoped "integrate(x, x = 0, x)");
  let functions = Centl_engine.create_session () in
  ignore
    (session_text functions
       "integrated_scale(scale) = integrate(scale*x, x = 0, 1)");
  Alcotest.(check string)
    "function arguments enter a deferred integral" "3"
    (session_text functions "integrated_scale(6)");
  ignore (session_text functions "held(value) = integrate(value, x)");
  begin match Centl_engine.evaluate_in_session functions "held(x)" with
  | Ok
      (Centl_engine.Session_value
         (Centl_engine.Symbolic
            (Centl_Core.Function
               ( "integrate",
                 [ Centl_Core.Symbol free_name; Centl_Core.Symbol bound_name ]
               )))) ->
      Alcotest.(check string) "replacement remains free" "x" free_name;
      Alcotest.(check bool)
        "integration binder is alpha-renamed" true (bound_name <> "x")
  | Ok result ->
      Alcotest.failf
        "expected a residual capture-avoiding integral, received %s"
        (Centl_engine.text_of_session_result result)
  | Error error -> Alcotest.fail (Centl_engine.error_text error)
  end

let integration_limits_and_cancellation () =
  let limited =
    { Centl_engine.default_evaluation_limits with max_expression_nodes = 20 }
  in
  begin match
    Centl_engine.evaluate_with_limits limited "integrate((x + 1)^8, x)"
  with
  | Error { code = "resource_limit"; _ } -> ()
  | Error error ->
      Alcotest.failf "integration limit returned %s instead: %s" error.code
        error.message
  | Ok result ->
      Alcotest.failf "integration bypassed its node budget: %s"
        (Centl_engine.text_of_value result)
  end;
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 3
  in
  begin match
    Centl_engine.evaluate_with_limits ~cancelled
      Centl_engine.default_evaluation_limits "integrate((x + 1)^16, x)"
  with
  | Error { code = "cancelled"; _ } -> ()
  | Error error ->
      Alcotest.failf "cancelled integration returned %s instead: %s" error.code
        error.message
  | Ok result ->
      Alcotest.failf "cancelled integration completed: %s"
        (Centl_engine.text_of_value result)
  end;
  Alcotest.(check bool)
    "integration has repeated cancellation checks" true (!checks >= 3)

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
    "exact irrational roots" "x in {-sqrt(2), sqrt(2)}"
    (value "solve(x^2 = 2, x)");
  Alcotest.(check string)
    "scaled equation has the same canonical roots" "x in {-sqrt(2), sqrt(2)}"
    (value "solve(2*x^2 = 4, x)");
  Alcotest.(check string)
    "negative scaling has the same canonical roots" "x in {-sqrt(2), sqrt(2)}"
    (value "solve(-3*x^2 = -6, x)");
  Alcotest.(check string)
    "translated irrational roots" "x in {-1/2 - sqrt(3/4), -1/2 + sqrt(3/4)}"
    (value "solve(4*x^2 + 4*x - 2 = 0, x)");
  Alcotest.(check string)
    "rational radicand" "x in {-sqrt(2/3), sqrt(2/3)}"
    (value "solve(x^2 = 2/3, x)");
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
    (error_code "solve(x = 1, x) + 2");
  Alcotest.(check string)
    "oversized exact power" "resource_limit" (error_code "2^1000000");
  Alcotest.(check string)
    "oversized sequence" "resource_limit"
    (error_code "fibonacci(100001)");
  Alcotest.(check string)
    "computed oversized sequence index" "resource_limit"
    (error_code "fibonacci(50000 + 50001)")

let runtime_source_positions () =
  let nested = evaluation_error "10 + 20 / (3 - 3)" in
  Alcotest.(check string) "nested error code" "division_by_zero" nested.code;
  Alcotest.(check (option int))
    "smallest failing arithmetic subtree" (Some 5) nested.position;
  let multiline = evaluation_error "approx(\n  sqrt(-1), 20)" in
  Alcotest.(check string) "domain error code" "domain_error" multiline.code;
  Alcotest.(check (option int))
    "multiline byte offset" (Some 10) multiline.position;
  let response =
    Centl_engine.json_of_evaluation (Centl_engine.evaluate "4 + 1 / (2 - 2)")
  in
  let machine_position =
    match response with
    | `Assoc fields ->
        begin match List.assoc_opt "error" fields with
        | Some (`Assoc error) ->
            begin match List.assoc_opt "position" error with
            | Some (`Int position) -> position
            | _ -> Alcotest.fail "machine error contained no integer position"
            end
        | _ -> Alcotest.fail "machine response contained no error object"
        end
    | _ -> Alcotest.fail "machine response was not an object"
  in
  Alcotest.(check int)
    "machine position is the zero-based byte offset" 4 machine_position

let session_runtime_source_positions () =
  let session = Centl_engine.create_session () in
  ignore (session_text session "f(x) = 1 / x");
  let call_error = session_evaluation_error session "100 + f(0)" in
  Alcotest.(check string)
    "stored body failure" "division_by_zero" call_error.code;
  Alcotest.(check (option int))
    "stored body is blamed on this source's call site" (Some 6)
    call_error.position;
  ignore (session_text session "identity(x) = x");
  let argument_error = session_evaluation_error session "identity(1 / 0)" in
  Alcotest.(check (option int))
    "failing caller argument remains more specific than call site" (Some 9)
    argument_error.position;
  let definition_error =
    session_evaluation_error (Centl_engine.create_session ()) "bad(x) = 1 / 0"
  in
  Alcotest.(check (option int))
    "definition-time failure uses the original RHS offset" (Some 9)
    definition_error.position;
  ignore (session_text session "root(x) = sqrt(x)");
  let approximate_call =
    session_evaluation_error session "approx(root(-1), 20)"
  in
  Alcotest.(check (option int))
    "stored approximation body is blamed on its call" (Some 7)
    approximate_call.position;
  let statement_error source =
    session_evaluation_error (Centl_engine.create_session ()) source
  in
  let check_statement_error label source expected_code expected_position =
    let error = statement_error source in
    Alcotest.(check string) (label ^ " code") expected_code error.code;
    Alcotest.(check (option int))
      (label ^ " position") (Some expected_position) error.position
  in
  check_statement_error "reserved definition name" "  pi = 3" "reserved_name" 2;
  check_statement_error "reserved function name" "sum = 3" "reserved_name" 0;
  check_statement_error "empty parameter list" "f() = 3" "invalid_definition" 2;
  check_statement_error "self-named parameter" "f(x, f) = x"
    "invalid_definition" 5;
  check_statement_error "reserved parameter" "f(x, pi) = x" "reserved_name" 5;
  check_statement_error "duplicate parameter" "f(x, y, x) = x"
    "invalid_definition" 8;
  let immutable = Centl_engine.create_session () in
  ignore (session_text immutable "rate = 1");
  let immutable_error = session_evaluation_error immutable "  rate = 2" in
  Alcotest.(check (option int))
    "immutable definition name" (Some 2) immutable_error.position;
  let one_binding =
    { Centl_engine.default_evaluation_limits with max_bindings = 1 }
  in
  let bounded = Centl_engine.create_session () in
  ignore
    (Centl_engine.evaluate_in_session_with_limits one_binding bounded "a = 1");
  begin match
    Centl_engine.evaluate_in_session_with_limits one_binding bounded "  b = 2"
  with
  | Error { code = "resource_limit"; position; _ } ->
      Alcotest.(check (option int))
        "binding-limit definition name" (Some 2) position
  | Error error ->
      Alcotest.failf "binding limit returned %s instead: %s" error.code
        error.message
  | Ok _ -> Alcotest.fail "binding limit accepted another definition"
  end

let session_diagnostic_origin_scaling () =
  let session = Centl_engine.create_session () in
  ignore (session_text session "identity(x) = x");
  let depth = 1_000 in
  let source =
    String.concat "" (List.init depth (Fun.const "identity("))
    ^ "0" ^ String.make depth ')'
  in
  Alcotest.(check string)
    "near-limit nested calls retain linear provenance bookkeeping" "0"
    (session_text session source)

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

let json_member name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.failf "JSON object contained no %s field" name
      end
  | _ -> Alcotest.fail "expected a JSON object"

let json_string name json =
  match json_member name json with
  | `String value -> value
  | _ -> Alcotest.failf "JSON field %s was not a string" name

let json_int name json =
  match json_member name json with
  | `Int value -> value
  | _ -> Alcotest.failf "JSON field %s was not an integer" name

let json_bool name json =
  match json_member name json with
  | `Bool value -> value
  | _ -> Alcotest.failf "JSON field %s was not a Boolean" name

let schema_accepts schema value =
  let definitions =
    match schema with
    | `Assoc fields ->
        begin match List.assoc_opt "$defs" fields with
        | Some (`Assoc definitions) -> definitions
        | _ -> []
        end
    | _ -> []
  in
  let integer_string ~positive = function
    | `String value ->
        let length = String.length value in
        let start =
          if (not positive) && length > 0 && value.[0] = '-' then 1 else 0
        in
        length > start
        && ((not positive) || (value.[0] >= '1' && value.[0] <= '9'))
        &&
        let rec digits index =
          index = length
          || (value.[index] >= '0' && value.[index] <= '9')
             && digits (index + 1)
        in
        digits start
    | _ -> false
  in
  let rec accepts candidate value =
    match candidate with
    | `Assoc fields ->
        let reference_ok =
          match List.assoc_opt "$ref" fields with
          | None -> true
          | Some (`String reference) ->
              let prefix = "#/$defs/" in
              if
                String.length reference <= String.length prefix
                || String.sub reference 0 (String.length prefix) <> prefix
              then false
              else
                let name =
                  String.sub reference (String.length prefix)
                    (String.length reference - String.length prefix)
                in
                begin match List.assoc_opt name definitions with
                | Some definition -> accepts definition value
                | None -> false
                end
          | Some _ -> false
        in
        let type_ok =
          match List.assoc_opt "type" fields with
          | None -> true
          | Some (`String "object") ->
              begin match value with `Assoc _ -> true | _ -> false
              end
          | Some (`String "array") ->
              begin match value with `List _ -> true | _ -> false
              end
          | Some (`String "string") ->
              begin match value with `String _ -> true | _ -> false
              end
          | Some (`String "integer") ->
              begin match value with `Int _ | `Intlit _ -> true | _ -> false
              end
          | Some (`String "boolean") ->
              begin match value with `Bool _ -> true | _ -> false
              end
          | Some _ -> false
        in
        let const_ok =
          match List.assoc_opt "const" fields with
          | None -> true
          | Some expected -> expected = value
        in
        let enum_ok =
          match List.assoc_opt "enum" fields with
          | None -> true
          | Some (`List choices) -> List.exists (( = ) value) choices
          | Some _ -> false
        in
        let minimum_ok =
          match (List.assoc_opt "minimum" fields, value) with
          | None, _ -> true
          | Some (`Int minimum), `Int actual -> actual >= minimum
          | Some (`Int minimum), `Intlit actual ->
              Z.compare (Z.of_string actual) (Z.of_int minimum) >= 0
          | Some _, _ -> false
        in
        let pattern_ok =
          match List.assoc_opt "pattern" fields with
          | None -> true
          | Some (`String "^-?[0-9]+$") -> integer_string ~positive:false value
          | Some (`String "^[1-9][0-9]*$") ->
              integer_string ~positive:true value
          | Some _ -> false
        in
        let required_ok =
          match (List.assoc_opt "required" fields, value) with
          | None, _ -> true
          | Some (`List required), `Assoc actual ->
              List.for_all
                (function
                  | `String name -> Option.is_some (List.assoc_opt name actual)
                  | _ -> false)
                required
          | Some _, _ -> false
        in
        let properties_ok =
          match (List.assoc_opt "properties" fields, value) with
          | None, _ -> true
          | Some (`Assoc properties), `Assoc actual ->
              List.for_all
                (fun (name, actual_value) ->
                  match List.assoc_opt name properties with
                  | Some property -> accepts property actual_value
                  | None ->
                      List.assoc_opt "additionalProperties" fields
                      <> Some (`Bool false))
                actual
          | Some (`Assoc _), _ -> true
          | Some _, _ -> false
        in
        let items_ok =
          match (List.assoc_opt "items" fields, value) with
          | None, _ -> true
          | Some item_schema, `List items ->
              List.for_all (accepts item_schema) items
          | Some _, _ -> true
        in
        let one_of_ok =
          match List.assoc_opt "oneOf" fields with
          | None -> true
          | Some (`List choices) ->
              List.fold_left
                (fun matches choice ->
                  if accepts choice value then matches + 1 else matches)
                0 choices
              = 1
          | Some _ -> false
        in
        let not_ok =
          match List.assoc_opt "not" fields with
          | None -> true
          | Some rejected -> not (accepts rejected value)
        in
        reference_ok && type_ok && const_ok && enum_ok && minimum_ok
        && pattern_ok && required_ok && properties_ok && items_ok && one_of_ok
        && not_ok
    | _ -> false
  in
  accepts schema value

let protocol_error_code json = json |> json_member "error" |> json_string "code"
let protocol_value_text json = json |> json_member "value" |> json_string "text"

let integration_json_protocol () =
  let response =
    Centl_engine.evaluate_request
      (`Assoc
         [
           ("version", `Int 1);
           ("expression", `String "integrate(x^2, x = 0, 1)");
         ])
  in
  Alcotest.(check bool)
    "integration request succeeds" true (json_bool "ok" response);
  let result = json_member "value" response in
  Alcotest.(check string)
    "existing rational kind" "rational"
    (json_string "kind" result);
  Alcotest.(check bool)
    "definite integral is exact" true (json_bool "exact" result);
  Alcotest.(check string)
    "rational numerator" "1"
    (json_string "numerator" result);
  Alcotest.(check string)
    "rational denominator" "3"
    (json_string "denominator" result);
  Alcotest.(check string) "rational text" "1/3" (json_string "text" result);
  Alcotest.(check string)
    "ordinary exact provenance" "exact"
    (response |> json_member "provenance" |> json_string "classification")

let real_quadratic_json_protocol () =
  let evaluate expression =
    Centl_engine.evaluate_request
      (`Assoc [ ("version", `Int 1); ("expression", `String expression) ])
  in
  let solutions response =
    match response |> json_member "value" |> json_member "solutions" with
    | `List solutions -> solutions
    | _ -> Alcotest.fail "quadratic solutions were not a JSON array"
  in
  let response = evaluate "solve(x^2 = 2, x)" in
  let lower, upper =
    match solutions response with
    | [ lower; upper ] -> (lower, upper)
    | _ -> Alcotest.fail "quadratic equation did not return two solutions"
  in
  let check_solution label branch text solution =
    Alcotest.(check string)
      (label ^ " kind") "real_quadratic"
      (json_string "kind" solution);
    Alcotest.(check bool) (label ^ " exact") true (json_bool "exact" solution);
    Alcotest.(check string)
      (label ^ " branch") branch
      (json_string "branch" solution);
    Alcotest.(check string) (label ^ " text") text (json_string "text" solution);
    let center = json_member "center" solution in
    let radicand = json_member "radicand" solution in
    Alcotest.(check string)
      (label ^ " center numerator")
      "0"
      (json_string "numerator" center);
    Alcotest.(check string)
      (label ^ " center denominator")
      "1"
      (json_string "denominator" center);
    Alcotest.(check string)
      (label ^ " radicand numerator")
      "2"
      (json_string "numerator" radicand);
    Alcotest.(check string)
      (label ^ " radicand denominator")
      "1"
      (json_string "denominator" radicand)
  in
  check_solution "lower" "lower" "-sqrt(2)" lower;
  check_solution "upper" "upper" "sqrt(2)" upper;
  Alcotest.(check (list string))
    "scaling-invariant algebraic solutions"
    (solutions response |> List.map Yojson.Safe.to_string)
    (solutions (evaluate "solve(2*x^2 = 4, x)")
    |> List.map Yojson.Safe.to_string);
  let provenance = json_member "provenance" response in
  Alcotest.(check string)
    "quadratic provenance method" "verified_quadratic_solving"
    (json_string "method" provenance);
  Alcotest.(check string)
    "quadratic provenance backend" "centl-core"
    (json_string "backend" provenance);
  begin match solutions (evaluate "solve(x^2 - 1 = 0, x)") with
  | `Assoc first :: _ ->
      Alcotest.(check bool)
        "rational solution schema remains untagged" true
        (List.assoc_opt "kind" first = None)
  | _ -> Alcotest.fail "rational equation returned no object solution"
  end

let persistent_json_protocol () =
  let state = Centl_protocol.create () in
  let request json = Centl_protocol.handle_line state json in
  let defined =
    request {|{"version":1,"id":"define-r","expression":"r = 3"}|}
  in
  Alcotest.(check string) "request id" "define-r" (json_string "id" defined);
  Alcotest.(check string)
    "definition result" "definition"
    (defined |> json_member "value" |> json_string "kind");
  Alcotest.(check int)
    "one definition" 1
    (defined |> json_member "session" |> json_int "definitions");
  let area = request {|{"version":1,"id":2,"expression":"circle_area(r)"}|} in
  Alcotest.(check string)
    "stateful calculation" "9 * pi" (protocol_value_text area);
  Alcotest.(check int) "integer id" 2 (json_int "id" area);
  let reset = request {|{"version":1,"id":3,"op":"reset"}|} in
  Alcotest.(check bool) "reset succeeds" true (json_bool "reset" reset);
  Alcotest.(check int)
    "definitions cleared" 0
    (reset |> json_member "session" |> json_int "definitions");
  let isolated = request {|{"version":1,"id":4,"expression":"r"}|} in
  Alcotest.(check string)
    "reset forgets values" "r"
    (protocol_value_text isolated)

let machine_resource_limits () =
  let state = Centl_protocol.create () in
  let request fields = Centl_protocol.handle_json state (`Assoc fields) in
  let evaluate expression limits =
    request
      [
        ("version", `Int 1);
        ("expression", `String expression);
        ("limits", `Assoc limits);
      ]
  in
  Alcotest.(check string)
    "precision digits" "precision_limit"
    (evaluate "approx(pi, 20)" [ ("max_precision_digits", `Int 10) ]
    |> protocol_error_code);
  Alcotest.(check string)
    "source bytes" "resource_limit"
    (evaluate "100" [ ("max_source_bytes", `Int 2) ] |> protocol_error_code);
  Alcotest.(check string)
    "expression nodes" "resource_limit"
    (evaluate "1 + 1" [ ("max_expression_nodes", `Int 1) ]
    |> protocol_error_code);
  ignore
    (request [ ("version", `Int 1); ("expression", `String "f(x) = x + x") ]);
  Alcotest.(check string)
    "session expansion nodes" "resource_limit"
    (evaluate "f(f(f(1)))" [ ("max_expression_nodes", `Int 10) ]
    |> protocol_error_code);
  Alcotest.(check string)
    "symbolic expansion work" "resource_limit"
    (evaluate "expand(((x + 1)^64)^64)" [] |> protocol_error_code);
  Alcotest.(check string)
    "exact result bits" "resource_limit"
    (evaluate "2^100" [ ("max_exact_bits", `Int 100) ] |> protocol_error_code);
  Alcotest.(check string)
    "quadratic square-witness bits" "resource_limit"
    (evaluate "solve(x^2 = 257, x)" [ ("max_exact_bits", `Int 8) ]
    |> protocol_error_code);
  Alcotest.(check string)
    "integer iterations" "resource_limit"
    (evaluate "fibonacci(101)" [ ("max_integer_iterations", `Int 100) ]
    |> protocol_error_code);
  let long_symbol = String.make 500 'x' in
  Alcotest.(check string)
    "serialized value bytes" "resource_limit"
    (evaluate
       (Printf.sprintf "sum(%s, k = 1, 100)" long_symbol)
       [ ("max_result_bytes", `Int 1_000) ]
    |> protocol_error_code);
  ignore (evaluate "a = 1" [ ("max_bindings", `Int 1) ]);
  Alcotest.(check string)
    "session definitions" "resource_limit"
    (evaluate "b = 2" [ ("max_bindings", `Int 1) ] |> protocol_error_code);
  Alcotest.(check string)
    "limits cannot raise ceilings" "invalid_request"
    (evaluate "1" [ ("max_precision_digits", `Int 1_001) ]
    |> protocol_error_code);
  let retained = Centl_protocol.create () in
  let retained_definition name symbol =
    Centl_protocol.handle_json retained
      (`Assoc
         [
           ("version", `Int 1);
           ("expression", `String (name ^ " = " ^ symbol));
           ("limits", `Assoc [ ("max_result_bytes", `Int 300) ]);
         ])
  in
  ignore (retained_definition "first" (String.make 100 'u'));
  Alcotest.(check string)
    "aggregate session retention" "resource_limit"
    (retained_definition "second" (String.make 100 'v') |> protocol_error_code);
  let dependency_retention = Centl_protocol.create () in
  let dependency_limits = `Assoc [ ("max_result_bytes", `Int 500) ] in
  let define_dependency expression =
    Centl_protocol.handle_json dependency_retention
      (`Assoc
         [
           ("version", `Int 1);
           ("expression", `String expression);
           ("limits", dependency_limits);
         ])
  in
  let dependency_names =
    [
      "dependency_alpha_000000000000";
      "dependency_beta_0000000000000";
      "dependency_gamma_000000000000";
      "dependency_delta_000000000000";
    ]
  in
  List.iter
    (fun name -> ignore (define_dependency (name ^ " = 1")))
    dependency_names;
  Alcotest.(check string)
    "dependency metadata retention" "resource_limit"
    (define_dependency ("combined = " ^ String.concat " + " dependency_names)
    |> protocol_error_code);
  let small_server =
    {
      Centl_protocol.default_server_limits with
      max_requests = 1;
      max_request_bytes = 8;
    }
  in
  let bounded = Centl_protocol.create ~limits:small_server () in
  ignore (Centl_protocol.handle_line bounded {|{"bad":1}|});
  let exhausted =
    Centl_protocol.handle_line bounded {|{"version":1,"id":2,"op":"ping"}|}
  in
  Alcotest.(check string)
    "process request ceiling" "resource_limit"
    (protocol_error_code exhausted);
  Alcotest.(check int) "limit echoes request id" 2 (json_int "id" exhausted)

let machine_describe () =
  let state = Centl_protocol.create () in
  let response =
    Centl_protocol.handle_json state
      (`Assoc [ ("version", `Int 1); ("op", `String "describe") ])
  in
  let capabilities = json_member "capabilities" response in
  Alcotest.(check string)
    "transport" "jsonl"
    (json_string "transport" capabilities);
  Alcotest.(check bool) "stateful" true (json_bool "stateful" capabilities);
  let cancellation = json_member "cancellation" capabilities in
  Alcotest.(check bool)
    "request-scoped cancellation" true
    (json_bool "request_scoped" cancellation);
  Alcotest.(check bool)
    "cooperative cancellation" true
    (json_bool "cooperative" cancellation);
  let limits = json_member "limits" capabilities in
  Alcotest.(check int)
    "request bytes" 65_536
    (json_int "max_request_bytes" limits);
  Alcotest.(check int)
    "precision digits" 1_000
    (json_int "max_precision_digits" limits);
  Alcotest.(check int)
    "exact result bits" 1_000_000
    (json_int "max_exact_bits" limits);
  Alcotest.(check int)
    "integer iterations" 100_000
    (json_int "max_integer_iterations" limits);
  Alcotest.(check int)
    "result bytes" 1_048_576
    (json_int "max_result_bytes" limits)

let provenance_classification json =
  json |> json_member "provenance" |> json_string "classification"

let machine_provenance () =
  let evaluate source =
    Centl_engine.evaluate source |> Centl_engine.json_of_evaluation
  in
  let check source expected =
    Alcotest.(check string)
      source expected
      (evaluate source |> provenance_classification)
  in
  check "42" "exact";
  check "1/2" "exact";
  check "x + 1" "exact_symbolic";
  check "approx(pi, 8)" "rigorous_enclosure";
  check "solve(x^2 - 1 = 0, x)" "exact_solution_set";
  check "solve(x^2 = 2, x)" "exact_solution_set";
  check "1 / 0" "failure";
  let producer =
    evaluate "42" |> json_member "provenance" |> json_member "producer"
  in
  Alcotest.(check string) "producer" "centl" (json_string "name" producer);
  Alcotest.(check string)
    "producer version" Centl_version.value
    (json_string "version" producer);
  let state = Centl_protocol.create () in
  let definition =
    Centl_protocol.handle_json state
      (`Assoc [ ("version", `Int 1); ("expression", `String "a = 1") ])
  in
  Alcotest.(check string)
    "definition provenance" "exact_definition"
    (provenance_classification definition);
  let ping =
    Centl_protocol.handle_json state
      (`Assoc [ ("version", `Int 1); ("op", `String "ping") ])
  in
  Alcotest.(check string)
    "control provenance" "control"
    (provenance_classification ping)

let transformation_resolution_metadata () =
  let evaluate source =
    Centl_engine.evaluate_detailed source
    |> Centl_engine.json_of_detailed_evaluation
  in
  let resolution source = evaluate source |> json_member "resolution" in
  let check ?operation ?reason source expected_status =
    let metadata = resolution source in
    Alcotest.(check string)
      (source ^ " resolution status")
      expected_status
      (json_string "status" metadata);
    Option.iter
      (fun expected ->
        Alcotest.(check string)
          (source ^ " operation") expected
          (json_string "operation" metadata))
      operation;
    Option.iter
      (fun expected ->
        Alcotest.(check string)
          (source ^ " reason") expected
          (json_string "reason" metadata))
      reason;
    if expected_status <> "computed" then
      Alcotest.(check bool)
        (source ^ " supported domain is documented")
        true
        (match json_member "supported_domain" metadata with
        | `String domain -> String.length domain > 0
        | _ -> false)
  in
  check "1 + 1" "computed";
  [
    ("diff(x^3, x)", "diff");
    ("integrate(x^2, x)", "integrate");
    ("simplify(1 + 1)", "simplify");
    ("simplify(x + 0)", "simplify");
    ("expand(1 + 1)", "expand");
    ("expand((x + 1)^2)", "expand");
    ("factor(x^2 - 1)", "factor");
    ("substitute(x + y, x = 2)", "substitute");
    ("solve(x^2 - 1 = 0, x)", "solve");
  ]
  |> List.iter (fun (source, operation) ->
      check ~operation source "transformed");
  [ ("simplify(x)", "simplify"); ("expand(x^2 + 2*x + 1)", "expand") ]
  |> List.iter (fun (source, operation) ->
      check ~operation ~reason:"polynomial_normal_form" source
        "unchanged_proved");
  check ~operation:"factor" ~reason:"supported_factorization_form"
    "factor((x + 1)^2)" "unchanged_proved";
  [
    ("diff(foo(x), x)", "diff", "unsupported_derivative_rule");
    ("integrate(sin(x), x)", "integrate", "non_polynomial_integrand");
    ("integrate(x^2, x = 0, a)", "integrate", "non_rational_bounds");
    ("simplify(sin(x))", "simplify", "non_polynomial_expression");
    ("expand(sin(x))", "expand", "non_polynomial_expression");
    ("factor(x^2 + 1)", "factor", "no_supported_factorization");
    ("factor(x^2 - 3*x + 2)", "factor", "no_supported_factorization");
    ("factor(sin(x))", "factor", "non_polynomial_expression");
    ("solve(x^3 = 1, x)", "solve", "unsupported_equation_degree_or_domain");
  ]
  |> List.iter (fun (source, operation, reason) ->
      check ~operation ~reason source "unsupported");
  let state = Centl_protocol.create () in
  let persistent =
    Centl_protocol.handle_json state
      (`Assoc
         [ ("version", `Int 1); ("expression", `String "integrate(sin(x), x)") ])
  in
  Alcotest.(check string)
    "persistent protocol carries resolution" "unsupported"
    (persistent |> json_member "resolution" |> json_string "status");
  let human =
    Centl_engine.evaluate_in_session_detailed
      (Centl_engine.create_session ())
      "factor(x^2 + 1)"
  in
  begin match human with
  | Ok outcome ->
      let annotation =
        outcome |> Centl_engine.text_of_session_outcome
        |> String.split_on_char '\n' |> List.rev |> List.hd
      in
      let prefix = "resolution: unsupported" in
      Alcotest.(check bool)
        "human output labels an unsupported transformation" true
        (String.length annotation >= String.length prefix
        && String.sub annotation 0 (String.length prefix) = prefix)
  | Error error -> Alcotest.fail (Centl_engine.error_text error)
  end

let machine_compute_and_define () =
  let state = Centl_protocol.create () in
  let request op expression =
    Centl_protocol.handle_json state
      (`Assoc
         [
           ("version", `Int 1);
           ("op", `String op);
           ("expression", `String expression);
         ])
  in
  let rejected_definition = request "compute" "r = 3" in
  Alcotest.(check string)
    "compute rejects definitions" "definition_not_allowed"
    (protocol_error_code rejected_definition);
  Alcotest.(check int)
    "rejected compute does not mutate" 0
    (Centl_engine.session_binding_count (Centl_protocol.session state));
  let rejected_expression = request "define" "1 + 1" in
  Alcotest.(check string)
    "define rejects expressions" "definition_required"
    (protocol_error_code rejected_expression);
  ignore (request "define" "r = 3");
  Alcotest.(check int)
    "define mutates explicitly" 1
    (Centl_engine.session_binding_count (Centl_protocol.session state));
  Alcotest.(check string)
    "compute reads session state" "9"
    (request "compute" "r^2" |> protocol_value_text);
  ignore (request "evaluate" "legacy = 4");
  Alcotest.(check int)
    "legacy evaluate retains compatibility" 2
    (Centl_engine.session_binding_count (Centl_protocol.session state));
  ignore (request "define" "square = r^2");
  let inspection =
    Centl_protocol.handle_json state
      (`Assoc [ ("version", `Int 1); ("op", `String "session") ])
  in
  let square =
    match json_member "definitions" inspection with
    | `List definitions ->
        begin match
          List.find_opt
            (fun definition -> json_string "name" definition = "square")
            definitions
        with
        | Some definition -> definition
        | None -> Alcotest.fail "session inspection omitted square"
        end
    | _ -> Alcotest.fail "session definitions was not a list"
  in
  Alcotest.(check (list string))
    "session inspection exposes dependencies" [ "r" ]
    (match json_member "dependencies" square with
    | `List dependencies ->
        List.map
          (function
            | `String dependency -> dependency
            | _ -> Alcotest.fail "dependency was not a string")
          dependencies
    | _ -> Alcotest.fail "dependencies was not a list");
  let focused_help =
    Centl_protocol.handle_json state
      (`Assoc
         [
           ("version", `Int 1);
           ("op", `String "help");
           ("query", `String "factor");
         ])
  in
  Alcotest.(check bool)
    "focused help comes from syntax catalog" true
    (match focused_help |> json_member "help" |> json_member "entries" with
    | `List (_ :: _) -> true
    | _ -> false);
  let description =
    Centl_protocol.handle_json state
      (`Assoc [ ("version", `Int 1); ("op", `String "describe") ])
  in
  let operations =
    match
      description |> json_member "capabilities" |> json_member "operations"
    with
    | `List values ->
        List.map
          (function
            | `String value -> value
            | _ -> Alcotest.fail "operation was not a string")
          values
    | _ -> Alcotest.fail "operations was not a list"
  in
  Alcotest.(check bool)
    "capabilities advertise compute" true
    (List.mem "compute" operations);
  Alcotest.(check bool)
    "capabilities advertise define" true
    (List.mem "define" operations);
  Alcotest.(check bool)
    "capabilities publish mathematical domains" true
    (match
       description |> json_member "capabilities"
       |> json_member "mathematical_domains"
     with
    | `List domains ->
        List.exists
          (fun domain -> json_string "operation" domain = "factor")
          domains
    | _ -> false)

let machine_error_metadata () =
  let syntax =
    Centl_engine.evaluate_detailed "1 +"
    |> Centl_engine.json_of_detailed_evaluation |> json_member "error"
  in
  Alcotest.(check bool)
    "syntax errors are not retryable unchanged" false
    (json_bool "retryable" syntax);
  Alcotest.(check bool)
    "syntax errors include a suggestion" true
    (String.length (json_string "suggestion" syntax) > 0);
  let range = json_member "range" syntax in
  Alcotest.(check int) "source range start" 3 (json_int "start" range);
  Alcotest.(check int) "source range end" 3 (json_int "end" range);
  let limits =
    { Centl_engine.default_evaluation_limits with max_exact_bits = 1 }
  in
  let limited =
    Centl_engine.evaluate_outcome_with_limits limits "4"
    |> Centl_engine.json_of_detailed_evaluation |> json_member "error"
  in
  Alcotest.(check bool)
    "limit failures can be retried with changed limits" true
    (json_bool "retryable" limited);
  Alcotest.(check string)
    "limit detail names the exhausted budget" "max_exact_bits"
    (limited |> json_member "details" |> json_string "limit")

let agent_tool_corpus () =
  let member_opt name = function
    | `Assoc fields -> List.assoc_opt name fields
    | _ -> None
  in
  let channel = open_in "corpus/agent_tools.jsonl" in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () ->
      let rec cases line_number =
        match input_line channel with
        | line ->
            let case = Yojson.Safe.from_string line in
            let name = json_string "name" case in
            let op = json_string "op" case in
            let cancelled =
              match member_opt "cancelled" case with
              | Some (`Bool value) -> value
              | _ -> false
            in
            let fields = [ ("version", `Int 1); ("op", `String op) ] in
            let reserved =
              [
                "name";
                "op";
                "cancelled";
                "expected_error";
                "expected_resolution";
                "expected_operation";
                "expected_reason";
                "expected_value_status";
                "expected_verdict";
              ]
            in
            let fields =
              match case with
              | `Assoc case_fields ->
                  fields
                  @ List.filter
                      (fun (name, _) -> not (List.mem name reserved))
                      case_fields
              | _ -> fields
            in
            let response =
              Centl_protocol.handle_json
                ~cancelled:(fun () -> cancelled)
                (Centl_protocol.create ()) (`Assoc fields)
            in
            begin match member_opt "expected_error" case with
            | Some (`String expected) ->
                Alcotest.(check string)
                  (name ^ " error") expected
                  (protocol_error_code response)
            | _ ->
                begin match member_opt "expected_verdict" case with
                | Some (`String expected) ->
                    Alcotest.(check string)
                      (name ^ " verdict") expected
                      (response |> json_member "verification"
                     |> json_string "verdict")
                | _ ->
                    let resolution = json_member "resolution" response in
                    Alcotest.(check string)
                      (name ^ " resolution")
                      (json_string "expected_resolution" case)
                      (json_string "status" resolution);
                    Option.iter
                      (fun expected ->
                        Alcotest.(check string)
                          (name ^ " operation") expected
                          (json_string "operation" resolution))
                      (match member_opt "expected_operation" case with
                      | Some (`String value) -> Some value
                      | _ -> None);
                    Option.iter
                      (fun expected ->
                        Alcotest.(check string)
                          (name ^ " reason") expected
                          (json_string "reason" resolution))
                      (match member_opt "expected_reason" case with
                      | Some (`String value) -> Some value
                      | _ -> None);
                    Option.iter
                      (fun expected ->
                        Alcotest.(check string)
                          (name ^ " value status") expected
                          (response |> json_member "value"
                         |> json_string "status"))
                      (match member_opt "expected_value_status" case with
                      | Some (`String value) -> Some value
                      | _ -> None)
                end
            end;
            cases (line_number + 1)
        | exception End_of_file -> ()
        | exception Yojson.Json_error message ->
            Alcotest.failf "agent corpus line %d: %s" line_number message
      in
      cases 1)

let closed_claim_verification () =
  let verify ?limits fields =
    let body = ("version", `Int 1) :: ("op", `String "verify") :: fields in
    let body =
      match limits with
      | None -> body
      | Some limits -> body @ [ ("limits", limits) ]
    in
    Centl_protocol.handle_json (Centl_protocol.create ()) (`Assoc body)
  in
  let verdict response =
    response |> json_member "verification" |> json_string "verdict"
  in
  let scope response =
    response |> json_member "verification" |> json_string "scope"
  in
  let is_error response = json_member "ok" response = `Bool false in
  let error_code response =
    response |> json_member "error" |> json_string "code"
  in
  (* six exact rational relations *)
  [
    ("equal", "2", "2", "verified");
    ("not_equal", "2", "3", "verified");
    ("less_than", "2", "3", "verified");
    ("less_or_equal", "2", "2", "verified");
    ("greater_than", "3", "2", "verified");
    ("greater_or_equal", "3", "3", "verified");
  ]
  |> List.iter (fun (relation, left, right, expected) ->
      let response =
        verify
          [
            ("left", `String left);
            ("relation", `String relation);
            ("right", `String right);
          ]
      in
      Alcotest.(check string)
        (relation ^ " exact relation")
        expected (verdict response));
  let equal_claim =
    verify
      [
        ("left", `String "0.1 + 0.2");
        ("relation", `String "equal");
        ("right", `String "3/10");
      ]
  in
  Alcotest.(check string)
    "0.1+0.2=3/10 verified" "verified" (verdict equal_claim);
  Alcotest.(check string)
    "assurance is exact algorithm" "exact_algorithm"
    (equal_claim |> json_member "verification" |> json_member "assurance"
   |> json_string "class");
  let refuted =
    verify
      [
        ("left", `String "1 + 1");
        ("relation", `String "equal");
        ("right", `String "3");
      ]
  in
  Alcotest.(check string) "1+1=3 refuted" "refuted" (verdict refuted);
  let ordered =
    verify
      [
        ("left", `String "7/8");
        ("relation", `String "less_than");
        ("right", `String "0.9");
      ]
  in
  Alcotest.(check string) "7/8<0.9 verified" "verified" (verdict ordered);
  let enclosure_order =
    verify
      [
        ("left", `String "sqrt(2)");
        ("relation", `String "less_than");
        ("right", `String "2");
      ]
  in
  Alcotest.(check string)
    "sqrt(2)<2 verified by enclosure" "verified" (verdict enclosure_order);
  Alcotest.(check string)
    "enclosure assurance" "certified_enclosure"
    (enclosure_order |> json_member "verification" |> json_member "assurance"
   |> json_string "class");
  let left_side =
    enclosure_order |> json_member "verification" |> json_member "evidence"
    |> json_member "left"
  in
  Alcotest.(check bool)
    "enclosure side exposes dyadic bounds" true
    (match json_member "dyadic" left_side with
    | `Assoc fields ->
        List.mem_assoc "lower_mantissa" fields
        && List.mem_assoc "upper_mantissa" fields
        && List.mem_assoc "binary_exponent" fields
    | _ -> false);
  let real_equal =
    verify
      [
        ("left", `String "pi");
        ("relation", `String "equal");
        ("right", `String "3");
      ]
  in
  Alcotest.(check string)
    "real equality remains unknown" "unknown" (verdict real_equal);
  let named_constant_order =
    verify
      [
        ("left", `String "pi");
        ("relation", `String "greater_than");
        ("right", `String "3");
      ]
  in
  Alcotest.(check string)
    "named constants are closed enclosure expressions" "verified"
    (verdict named_constant_order);
  let not_strict =
    verify
      [
        ("left", `String "2");
        ("relation", `String "less_than");
        ("right", `String "2");
      ]
  in
  Alcotest.(check string)
    "exact equal values do not verify strict less_than" "refuted"
    (verdict not_strict);
  let quantified =
    verify
      [
        ("left", `String "x + 0");
        ("relation", `String "equal");
        ("right", `String "x");
        ( "variables",
          `List
            [ `Assoc [ ("name", `String "x"); ("domain", `String "rational") ] ]
        );
      ]
  in
  Alcotest.(check string)
    "quantified rational polynomial identity is verified" "verified"
    (verdict quantified);
  Alcotest.(check string)
    "polynomial scope" "univariate_rational_polynomial" (scope quantified);
  Alcotest.(check string)
    "polynomial theorem has verified-core assurance" "verified_core"
    (quantified |> json_member "verification" |> json_member "assurance"
   |> json_string "class");
  Alcotest.(check string)
    "polynomial theorem is named"
    "Centl.PolynomialSoundness.surface_rational_polynomial_identity_sound"
    (quantified |> json_member "verification" |> json_member "assurance"
   |> json_string "theorem");
  let poly_identity =
    verify
      [
        ("left", `String "(x+1)^2");
        ("relation", `String "equal");
        ("right", `String "x^2+2*x+1");
        ( "variables",
          `List
            [ `Assoc [ ("name", `String "x"); ("domain", `String "rational") ] ]
        );
      ]
  in
  Alcotest.(check string)
    "expanded square identity is verified" "verified" (verdict poly_identity);
  Alcotest.(check bool)
    "normalized difference is present" true
    (match
       poly_identity |> json_member "verification" |> json_member "evidence"
       |> json_member "normalized_difference"
     with
    | `String text -> text = "0"
    | _ -> false);
  let poly_disequality =
    verify
      [
        ("left", `String "x");
        ("relation", `String "not_equal");
        ("right", `String "x");
        ( "variables",
          `List
            [ `Assoc [ ("name", `String "x"); ("domain", `String "rational") ] ]
        );
      ]
  in
  Alcotest.(check string)
    "identical polynomial disequality is exactly refuted" "refuted"
    (verdict poly_disequality);
  let disequality_witness =
    poly_disequality |> json_member "verification" |> json_member "evidence"
    |> json_member "counterexample"
  in
  Alcotest.(check string)
    "disequality witness has equal exact sides"
    (disequality_witness |> json_member "left" |> json_string "text")
    (disequality_witness |> json_member "right" |> json_string "text");
  let poly_refuted =
    verify
      [
        ("left", `String "(x+1)^2");
        ("relation", `String "equal");
        ("right", `String "x^2+2*x");
        ( "variables",
          `List
            [ `Assoc [ ("name", `String "x"); ("domain", `String "rational") ] ]
        );
      ]
  in
  Alcotest.(check string)
    "false polynomial identity is refuted" "refuted" (verdict poly_refuted);
  Alcotest.(check string)
    "refutation uses witness assurance" "witness_checked"
    (poly_refuted |> json_member "verification" |> json_member "assurance"
   |> json_string "class");
  let bounded_normalization =
    verify
      ~limits:(`Assoc [ ("max_expression_nodes", `Int 20) ])
      [
        ("left", `String "(x+1)^8");
        ("relation", `String "equal");
        ("right", `String "x^8");
        ( "variables",
          `List
            [ `Assoc [ ("name", `String "x"); ("domain", `String "rational") ] ]
        );
      ]
  in
  Alcotest.(check bool)
    "polynomial normalization respects work limit" true
    (is_error bounded_normalization);
  Alcotest.(check string)
    "polynomial work limit is operational" "resource_limit"
    (error_code bounded_normalization);
  Alcotest.(check bool)
    "refutation includes counterexample binding" true
    (match
       poly_refuted |> json_member "verification" |> json_member "evidence"
       |> json_member "counterexample"
     with
    | `Assoc fields ->
        begin match List.assoc_opt "bindings" fields with
        | Some (`Assoc bindings) -> List.mem_assoc "x" bindings
        | _ -> false
        end
    | _ -> false);
  let assumed =
    verify
      [
        ("left", `String "1");
        ("relation", `String "equal");
        ("right", `String "1");
        ("assumptions", `List [ `String "x > 0" ]);
      ]
  in
  Alcotest.(check string)
    "free-form assumptions remain unknown" "unknown" (verdict assumed);
  let open_claim =
    verify
      [
        ("left", `String "(x+1)^2");
        ("relation", `String "equal");
        ("right", `String "x^2+2*x+1");
      ]
  in
  Alcotest.(check string)
    "free variables require quantification" "unknown" (verdict open_claim);
  let unknown_field =
    verify
      [
        ("left", `String "1");
        ("relation", `String "equal");
        ("right", `String "1");
        ("extra", `String "nope");
      ]
  in
  Alcotest.(check bool) "unknown field is error" true (is_error unknown_field);
  Alcotest.(check string)
    "unknown field code" "invalid_request" (error_code unknown_field);
  let duplicate_field =
    verify
      [
        ("left", `String "1");
        ("left", `String "2");
        ("relation", `String "equal");
        ("right", `String "1");
      ]
  in
  Alcotest.(check bool)
    "duplicate claim field is error" true (is_error duplicate_field);
  Alcotest.(check string)
    "duplicate claim field code" "invalid_claim"
    (error_code duplicate_field);
  let bad_variable =
    verify
      [
        ("left", `String "1");
        ("relation", `String "equal");
        ("right", `String "1");
        ( "variables",
          `List
            [ `Assoc [ ("name", `String "x"); ("domain", `String "complex") ] ]
        );
      ]
  in
  Alcotest.(check bool) "bad domain is error" true (is_error bad_variable);
  Alcotest.(check string)
    "bad domain code" "invalid_claim" (error_code bad_variable);
  let bad_variable_name =
    verify
      [
        ("left", `String "1");
        ("relation", `String "equal");
        ("right", `String "1");
        ( "variables",
          `List
            [
              `Assoc
                [
                  ("name", `String "not a name"); ("domain", `String "rational");
                ];
            ] );
      ]
  in
  Alcotest.(check bool)
    "invalid variable name is error" true
    (is_error bad_variable_name);
  let duplicate_variable_field =
    verify
      [
        ("left", `String "x");
        ("relation", `String "equal");
        ("right", `String "x");
        ( "variables",
          `List
            [
              `Assoc
                [
                  ("name", `String "x");
                  ("name", `String "y");
                  ("domain", `String "rational");
                ];
            ] );
      ]
  in
  Alcotest.(check bool)
    "duplicate variable field is error" true
    (is_error duplicate_variable_field);
  let duplicate_variables =
    verify
      [
        ("left", `String "x");
        ("relation", `String "equal");
        ("right", `String "x");
        ( "variables",
          `List
            [
              `Assoc [ ("name", `String "x"); ("domain", `String "rational") ];
              `Assoc [ ("name", `String "x"); ("domain", `String "rational") ];
            ] );
      ]
  in
  Alcotest.(check bool)
    "duplicate variables are error" true
    (is_error duplicate_variables);
  let bad_assumption =
    verify
      [
        ("left", `String "1");
        ("relation", `String "equal");
        ("right", `String "1");
        ("assumptions", `List [ `Int 1 ]);
      ]
  in
  Alcotest.(check bool)
    "non-string assumption is error" true (is_error bad_assumption);
  let tiny =
    verify
      ~limits:(`Assoc [ ("max_result_bytes", `Int 50) ])
      [
        ("left", `String "0.1 + 0.2");
        ("relation", `String "equal");
        ("right", `String "3/10");
      ]
  in
  Alcotest.(check bool)
    "oversized verification response is operational error" true (is_error tiny);
  Alcotest.(check string)
    "oversized response code" "resource_limit" (error_code tiny);
  let cancelled =
    Centl_protocol.handle_json
      ~cancelled:(fun () -> true)
      (Centl_protocol.create ())
      (`Assoc
         [
           ("version", `Int 1);
           ("op", `String "verify");
           ("left", `String "1");
           ("relation", `String "equal");
           ("right", `String "1");
         ])
  in
  Alcotest.(check bool)
    "cancellation is operational error" true (is_error cancelled);
  Alcotest.(check string) "cancellation code" "cancelled" (error_code cancelled);
  let state = Centl_protocol.create () in
  ignore
    (Centl_protocol.handle_json state
       (`Assoc
          [
            ("version", `Int 1);
            ("op", `String "define");
            ("expression", `String "a = 3/10");
          ]));
  let with_definition =
    Centl_protocol.handle_json state
      (`Assoc
         [
           ("version", `Int 1);
           ("op", `String "verify");
           ("left", `String "0.1 + 0.2");
           ("relation", `String "equal");
           ("right", `String "a");
         ])
  in
  Alcotest.(check string)
    "verify may read session definitions" "verified" (verdict with_definition);
  Alcotest.(check (list string))
    "session dependency recorded on claim" [ "a" ]
    (match
       with_definition |> json_member "verification" |> json_member "evidence"
       |> json_member "dependencies"
     with
    | `List items ->
        List.map
          (function
            | `String name -> name
            | _ -> Alcotest.fail "dependency was not a string")
          items
    | _ -> Alcotest.fail "dependencies missing");
  Alcotest.(check int)
    "verify does not mutate session" 1
    (Centl_engine.session_binding_count (Centl_protocol.session state));
  let shadowed = Centl_protocol.create () in
  ignore
    (Centl_protocol.handle_json shadowed
       (`Assoc
          [
            ("version", `Int 1);
            ("op", `String "define");
            ("expression", `String "x = 1");
          ]));
  let shadowed_claim =
    Centl_protocol.handle_json shadowed
      (`Assoc
         [
           ("version", `Int 1);
           ("op", `String "verify");
           ("left", `String "x");
           ("relation", `String "equal");
           ("right", `String "0");
           ( "variables",
             `List
               [
                 `Assoc
                   [ ("name", `String "x"); ("domain", `String "rational") ];
               ] );
         ])
  in
  Alcotest.(check string)
    "quantified variable does not capture a session binding" "unknown"
    (verdict shadowed_claim);
  Alcotest.(check string)
    "session-shadow reason is explicit"
    "quantified_variable_shadows_session_binding"
    (shadowed_claim |> json_member "verification" |> json_member "evidence"
   |> json_string "reason");
  let again =
    Centl_protocol.handle_json state
      (`Assoc
         [
           ("version", `Int 1);
           ("op", `String "verify");
           ("left", `String "0.1 + 0.2");
           ("relation", `String "equal");
           ("right", `String "a");
         ])
  in
  Alcotest.(check string)
    "repeated verification is deterministic" "verified" (verdict again);
  Alcotest.(check string)
    "repeated verification keeps exact scope" "closed_exact_rational"
    (scope again);
  ignore
    (Centl_protocol.handle_json state
       (`Assoc
          [
            ("version", `Int 1);
            ("op", `String "define");
            ("expression", `String "b = a");
          ]));
  let transitive =
    Centl_protocol.handle_json state
      (`Assoc
         [
           ("version", `Int 1);
           ("op", `String "verify");
           ("left", `String "0.1 + 0.2");
           ("relation", `String "equal");
           ("right", `String "b");
         ])
  in
  Alcotest.(check (list string))
    "claim evidence includes transitive session dependencies" [ "a"; "b" ]
    (match
       transitive |> json_member "verification" |> json_member "evidence"
       |> json_member "dependencies"
     with
    | `List items ->
        List.map
          (function
            | `String name -> name
            | _ -> Alcotest.fail "dependency was not a string")
          items
    | _ -> Alcotest.fail "dependencies missing")

let assert_grammar () =
  let parse source =
    match Centl_parser.parse_statement_located source with
    | Ok located -> located.statement
    | Error error -> Alcotest.failf "parse failed: %s" error.message
  in
  begin match parse "assert(0.1 + 0.2 = 3/10)" with
  | Centl_parser.Assert
      { left_source; relation = "equal"; right_source; variable = None } ->
      Alcotest.(check string)
        "assert left" "0.1 + 0.2" (String.trim left_source);
      Alcotest.(check string) "assert right" "3/10" (String.trim right_source)
  | _ -> Alcotest.fail "expected closed assert statement"
  end;
  begin match
    parse "assert((x+1)^2 = x^2+2*x+1, for_all = x, domain = rational)"
  with
  | Centl_parser.Assert { relation = "equal"; variable = Some "x"; _ } -> ()
  | _ -> Alcotest.fail "expected quantified assert statement"
  end;
  begin match parse "assert(1 < 2)" with
  | Centl_parser.Assert { relation = "less_than"; variable = None; _ } -> ()
  | _ -> Alcotest.fail "expected less_than assert"
  end;
  begin match
    Centl_engine.evaluate_in_session_detailed
      (Centl_engine.create_session ())
      "assert(1 = 1)"
  with
  | Error error ->
      Alcotest.(check string)
        "engine assert is host-only" "assert_host_only" error.code
  | Ok _ -> Alcotest.fail "engine must not evaluate assert"
  end;
  begin match
    Centl_engine.evaluate_in_session_detailed
      (Centl_engine.create_session ())
      "assert = 1"
  with
  | Error error ->
      Alcotest.(check string)
        "assert cannot be redefined" "reserved_name" error.code
  | Ok _ -> Alcotest.fail "assert must remain reserved host syntax"
  end

let machine_cancellation () =
  let evaluation =
    Yojson.Safe.from_string
      {|{"version":1,"id":"job-1","expression":"expand((x + 1)^20)"}|}
  in
  begin match Centl_protocol.cancellable_request_id evaluation with
  | Some (`String id) ->
      Alcotest.(check string) "cancellable request id" "job-1" id
  | _ -> Alcotest.fail "evaluation request was not classified as cancellable"
  end;
  let cancellation =
    Yojson.Safe.from_string
      {|{"version":1,"id":"stop-1","op":"cancel","target":"job-1"}|}
  in
  begin match Centl_protocol.cancellation_target_of_json cancellation with
  | Some (`String id) -> Alcotest.(check string) "cancel target" "job-1" id
  | _ -> Alcotest.fail "cancel request target was not recognized"
  end;
  let invalid_cancellation_id =
    Yojson.Safe.from_string
      {|{"version":1,"id":{},"op":"cancel","target":"job-1"}|}
  in
  Alcotest.(check bool)
    "invalid cancellation request is not actionable" true
    (Centl_protocol.cancellation_target_of_json invalid_cancellation_id = None);
  let state = Centl_protocol.create () in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 3
  in
  let response = Centl_protocol.handle_json ~cancelled state evaluation in
  Alcotest.(check string)
    "cooperative error" "cancelled"
    (protocol_error_code response);
  Alcotest.(check string)
    "cancellation provenance" "cancelled"
    (provenance_classification response);
  Alcotest.(check bool) "multiple checkpoints" true (!checks >= 3);
  let definition =
    Centl_protocol.handle_json
      ~cancelled:(fun () -> true)
      state
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "define-cancelled");
           ("expression", `String "never_committed = 1");
         ])
  in
  Alcotest.(check string)
    "cancelled definition" "cancelled"
    (protocol_error_code definition);
  Alcotest.(check int)
    "cancelled definition is not committed" 0
    (Centl_engine.session_binding_count (Centl_protocol.session state));
  let acknowledgement = Centl_protocol.handle_json state cancellation in
  Alcotest.(check string)
    "cancellation acknowledged" "requested"
    (acknowledgement |> json_member "cancellation" |> json_string "status");
  let one_request =
    { Centl_protocol.default_server_limits with max_requests = 1 }
  in
  let bounded = Centl_protocol.create ~limits:one_request () in
  ignore
    (Centl_protocol.handle_line bounded
       {|{"version":1,"id":"first","op":"ping"}|});
  let late_cancellation =
    Centl_protocol.handle_line bounded
      {|{"version":1,"id":"stop-late","op":"cancel","target":"first"}|}
  in
  Alcotest.(check bool)
    "valid cancellation bypasses request admission" true
    (Centl_protocol.ok late_cancellation)

let mcp_request state json =
  match Centl_mcp.handle_json state (Yojson.Safe.from_string json) with
  | Some response -> response
  | None -> Alcotest.fail "MCP request produced no response"

let mcp_error_code json = json |> json_member "error" |> json_int "code"

let mcp_structured_content json =
  json |> json_member "result" |> json_member "structuredContent"

let mcp_schema_laziness () =
  Alcotest.(check bool)
    "calculate schema starts lazy" false
    (Lazy.is_val Centl_mcp.tool_output_schema);
  Alcotest.(check bool)
    "reset schema starts lazy" false
    (Lazy.is_val Centl_mcp.reset_output_schema);
  let state = Centl_mcp.create () in
  ignore
    (mcp_request state
       {|{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"lazy-test","version":"1"}}}|});
  ignore
    (Centl_mcp.handle_json state
       (Yojson.Safe.from_string
          {|{"jsonrpc":"2.0","method":"notifications/initialized"}|}));
  ignore
    (mcp_request state
       {|{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":"1 + 1"}}}|});
  Alcotest.(check bool)
    "ordinary calculation does not force calculate schema" false
    (Lazy.is_val Centl_mcp.tool_output_schema);
  Alcotest.(check bool)
    "ordinary calculation does not force reset schema" false
    (Lazy.is_val Centl_mcp.reset_output_schema);
  ignore (mcp_request state {|{"jsonrpc":"2.0","id":3,"method":"tools/list"}|});
  Alcotest.(check bool)
    "tool discovery forces calculate schema" true
    (Lazy.is_val Centl_mcp.tool_output_schema);
  Alcotest.(check bool)
    "tool discovery forces reset schema" true
    (Lazy.is_val Centl_mcp.reset_output_schema)

let mcp_text_matches_human_resolution () =
  let expression = "factor(x^2 + 1)" in
  let human =
    match
      Centl_engine.evaluate_in_session_detailed
        (Centl_engine.create_session ())
        expression
    with
    | Ok outcome -> Centl_engine.text_of_session_outcome outcome
    | Error error -> Alcotest.fail (Centl_engine.error_text error)
  in
  let state = Centl_mcp.create () in
  ignore
    (mcp_request state
       {|{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"residual-text","version":"1"}}}|});
  ignore
    (Centl_mcp.handle_json state
       (Yojson.Safe.from_string
          {|{"jsonrpc":"2.0","method":"notifications/initialized"}|}));
  let response =
    mcp_request state
      {|{"jsonrpc":"2.0","id":"residual","method":"tools/call","params":{"name":"centl_compute","arguments":{"expression":"factor(x^2 + 1)"}}}|}
  in
  let text =
    match response |> json_member "result" |> json_member "content" with
    | `List (`Assoc content :: _) -> json_string "text" (`Assoc content)
    | _ -> Alcotest.fail "MCP content missing"
  in
  Alcotest.(check string)
    "MCP text content matches human residual annotation" human text

let mcp_output_schemas () =
  let calculate_schema = Lazy.force Centl_mcp.tool_output_schema in
  let compute_schema = Lazy.force Centl_mcp.compute_output_schema in
  let define_schema = Lazy.force Centl_mcp.define_output_schema in
  let capabilities_schema = Lazy.force Centl_mcp.capabilities_output_schema in
  let session_schema = Lazy.force Centl_mcp.session_output_schema in
  let help_schema = Lazy.force Centl_mcp.help_output_schema in
  let reset_schema = Lazy.force Centl_mcp.reset_output_schema in
  Alcotest.(check bool)
    "calculate descriptor uses calculate schema" true
    (json_member "outputSchema" (Centl_mcp.calculate_tool ()) = calculate_schema);
  Alcotest.(check bool)
    "compute descriptor uses read-only schema" true
    (json_member "outputSchema" (Centl_mcp.compute_tool ()) = compute_schema);
  Alcotest.(check bool)
    "define descriptor uses definition schema" true
    (json_member "outputSchema" (Centl_mcp.define_tool ()) = define_schema);
  Alcotest.(check bool)
    "capabilities descriptor uses exact schema" true
    (json_member "outputSchema" (Centl_mcp.capabilities_tool ())
    = capabilities_schema);
  Alcotest.(check bool)
    "session descriptor uses exact schema" true
    (json_member "outputSchema" (Centl_mcp.session_tool ()) = session_schema);
  Alcotest.(check bool)
    "help descriptor uses exact schema" true
    (json_member "outputSchema" (Centl_mcp.help_tool ()) = help_schema);
  let verify_schema = Lazy.force Centl_mcp.verify_output_schema in
  Alcotest.(check bool)
    "verify descriptor uses exact schema" true
    (json_member "outputSchema" (Centl_mcp.verify_tool ()) = verify_schema);
  Alcotest.(check bool)
    "reset descriptor uses self-contained reset schema" true
    (json_member "outputSchema" (Centl_mcp.reset_tool ()) = reset_schema);
  let initialized_state () =
    let state = Centl_mcp.create () in
    ignore
      (mcp_request state
         {|{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"schema-test","version":"1"}}}|});
    ignore
      (Centl_mcp.handle_json state
         (Yojson.Safe.from_string
            {|{"jsonrpc":"2.0","method":"notifications/initialized"}|}));
    state
  in
  let calculate expression =
    let state = initialized_state () in
    let request =
      `Assoc
        [
          ("jsonrpc", `String "2.0");
          ("id", `String "schema");
          ("method", `String "tools/call");
          ( "params",
            `Assoc
              [
                ("name", `String "centl_calculate");
                ("arguments", `Assoc [ ("expression", `String expression) ]);
              ] );
        ]
    in
    match Centl_mcp.handle_json state request with
    | Some response -> mcp_structured_content response
    | None -> Alcotest.fail "schema test calculation returned no response"
  in
  [
    ("integer", "1");
    ("rational", "1/2");
    ("symbolic", "x + 1");
    ("conditional symbolic", "assuming(x / x, x != 0)");
    ("sequence", "sequence(k, k = 1, 3)");
    ("real enclosure", "approx(pi, 8)");
    ("rational solution set", "solve(x^2 - 1 = 0, x)");
    ("real-quadratic solution set", "solve(x^2 = 2, x)");
    ("value definition", "a = 1");
    ("function definition", "f(x) = x + 1");
    ("structured error", "1 / 0");
  ]
  |> List.iter (fun (label, expression) ->
      Alcotest.(check bool)
        (label ^ " conforms to calculate outputSchema")
        true
        (schema_accepts calculate_schema (calculate expression)));
  Alcotest.(check bool)
    "compute schema accepts mathematical values" true
    (schema_accepts compute_schema (calculate "1 + 1"));
  Alcotest.(check bool)
    "compute schema rejects definition values" false
    (schema_accepts compute_schema (calculate "schema_value = 1"));
  Alcotest.(check bool)
    "define schema accepts definitions" true
    (schema_accepts define_schema (calculate "schema_function(x) = x + 1"));
  Alcotest.(check bool)
    "define schema rejects mathematical values" false
    (schema_accepts define_schema (calculate "1 + 1"));
  let control name arguments =
    let state = initialized_state () in
    let request =
      `Assoc
        [
          ("jsonrpc", `String "2.0");
          ("id", `String "control-schema");
          ("method", `String "tools/call");
          ( "params",
            `Assoc [ ("name", `String name); ("arguments", `Assoc arguments) ]
          );
        ]
    in
    match Centl_mcp.handle_json state request with
    | Some response -> mcp_structured_content response
    | None -> Alcotest.fail "schema control tool returned no response"
  in
  Alcotest.(check bool)
    "capabilities response conforms to schema" true
    (schema_accepts capabilities_schema (control "centl_capabilities" []));
  Alcotest.(check bool)
    "verify response conforms to schema" true
    (schema_accepts verify_schema
       (control "centl_verify"
          [
            ("left", `String "0.1 + 0.2");
            ("relation", `String "equal");
            ("right", `String "3/10");
          ]));
  Alcotest.(check bool)
    "unknown verification conforms to schema" true
    (schema_accepts verify_schema
       (control "centl_verify"
          [
            ("left", `String "x + 1");
            ("relation", `String "equal");
            ("right", `String "x + 1");
          ]));
  Alcotest.(check bool)
    "enclosure verification conforms to schema" true
    (schema_accepts verify_schema
       (control "centl_verify"
          [
            ("left", `String "sqrt(2)");
            ("relation", `String "less_than");
            ("right", `String "2");
          ]));
  Alcotest.(check bool)
    "verification failure conforms to schema" true
    (schema_accepts verify_schema
       (control "centl_verify"
          [
            ("left", `String "1");
            ("relation", `String "unsupported");
            ("right", `String "1");
          ]));
  Alcotest.(check bool)
    "session response conforms to schema" true
    (schema_accepts session_schema (control "centl_session" []));
  Alcotest.(check bool)
    "help response conforms to schema" true
    (schema_accepts help_schema
       (control "centl_help" [ ("query", `String "solve") ]));
  let reset_state = initialized_state () in
  let reset_response =
    mcp_request reset_state
      {|{"jsonrpc":"2.0","id":"reset-schema","method":"tools/call","params":{"name":"centl_reset","arguments":{}}}|}
    |> mcp_structured_content
  in
  Alcotest.(check bool)
    "reset response conforms to reset outputSchema" true
    (schema_accepts reset_schema reset_response)

let mcp_protocol () =
  let state = Centl_mcp.create () in
  let before =
    mcp_request state {|{"jsonrpc":"2.0","id":0,"method":"tools/list"}|}
  in
  Alcotest.(check int) "lifecycle enforced" (-32002) (mcp_error_code before);
  let initialized =
    mcp_request state
      {|{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}|}
  in
  Alcotest.(check string)
    "protocol version" "2025-11-25"
    (initialized |> json_member "result" |> json_string "protocolVersion");
  Alcotest.(check bool)
    "initialized notification has no response" true
    (Centl_mcp.handle_json state
       (Yojson.Safe.from_string
          {|{"jsonrpc":"2.0","method":"notifications/initialized"}|})
    = None);
  let listed =
    mcp_request state {|{"jsonrpc":"2.0","id":2,"method":"tools/list"}|}
  in
  let names =
    match listed |> json_member "result" |> json_member "tools" with
    | `List tools -> List.map (json_string "name") tools
    | _ -> Alcotest.fail "MCP tools was not a list"
  in
  Alcotest.(check (list string))
    "deterministic tools"
    [
      "centl_compute";
      "centl_define";
      "centl_verify";
      "centl_capabilities";
      "centl_session";
      "centl_help";
      "centl_calculate";
      "centl_reset";
    ]
    names;
  let tools =
    match listed |> json_member "result" |> json_member "tools" with
    | `List tools -> tools
    | _ -> Alcotest.fail "MCP tools was not a list"
  in
  let tool name =
    match
      List.find_opt (fun candidate -> json_string "name" candidate = name) tools
    with
    | Some descriptor -> descriptor
    | None -> Alcotest.failf "MCP tool %s was not listed" name
  in
  let compute_annotations = tool "centl_compute" |> json_member "annotations" in
  Alcotest.(check bool)
    "compute is read-only" true
    (json_bool "readOnlyHint" compute_annotations);
  Alcotest.(check bool)
    "compute is idempotent" true
    (json_bool "idempotentHint" compute_annotations);
  let rejected =
    mcp_request state
      {|{"jsonrpc":"2.0","id":"read-only","method":"tools/call","params":{"name":"centl_compute","arguments":{"expression":"blocked = 1"}}}|}
  in
  Alcotest.(check string)
    "MCP compute rejects definitions" "definition_not_allowed"
    (rejected |> mcp_structured_content |> protocol_error_code);
  let define =
    mcp_request state
      {|{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"centl_define","arguments":{"definition":"r = 3"}}}|}
  in
  Alcotest.(check string)
    "MCP definition" "r = 3"
    (define |> mcp_structured_content |> protocol_value_text);
  let area =
    mcp_request state
      {|{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"centl_compute","arguments":{"expression":"circle_area(r)"}}}|}
  in
  Alcotest.(check string)
    "MCP session state" "9 * pi"
    (area |> mcp_structured_content |> protocol_value_text);
  let failure =
    mcp_request state
      {|{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":"1 / 0"}}}|}
  in
  Alcotest.(check bool)
    "math failure is a tool error" true
    (failure |> json_member "result" |> json_bool "isError");
  Alcotest.(check string)
    "structured math error" "division_by_zero"
    (failure |> mcp_structured_content |> protocol_error_code);
  let reset =
    mcp_request state
      {|{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"centl_reset","arguments":{}}}|}
  in
  Alcotest.(check bool)
    "MCP reset" false
    (reset |> json_member "result" |> json_bool "isError")

let mcp_failures () =
  let state = Centl_mcp.create () in
  let parse =
    match Centl_mcp.handle_line state "{" with
    | Some response -> response
    | None -> Alcotest.fail "invalid JSON produced no response"
  in
  Alcotest.(check int) "parse error" (-32700) (mcp_error_code parse);
  let initialize =
    {|{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}|}
  in
  ignore (mcp_request state initialize);
  ignore
    (Centl_mcp.handle_json state
       (Yojson.Safe.from_string
          {|{"jsonrpc":"2.0","method":"notifications/initialized"}|}));
  let unknown =
    mcp_request state
      {|{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"unknown","arguments":{}}}|}
  in
  Alcotest.(check int) "unknown tool" (-32602) (mcp_error_code unknown);
  let malformed_limits =
    mcp_request state
      {|{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":"1 + 1","limits":"unbounded"}}}|}
  in
  Alcotest.(check int)
    "malformed limits" (-32602)
    (mcp_error_code malformed_limits);
  let excessive_limit =
    mcp_request state
      {|{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":"1 + 1","limits":{"max_expression_nodes":100001}}}}|}
  in
  Alcotest.(check int)
    "excessive limit" (-32602)
    (mcp_error_code excessive_limit);
  let one_request =
    { Centl_protocol.default_server_limits with max_requests = 1 }
  in
  let bounded = Centl_mcp.create ~limits:one_request () in
  ignore (Centl_mcp.handle_line bounded initialize);
  Alcotest.(check bool)
    "limited notifications have no response" true
    (Centl_mcp.handle_line bounded
       {|{"jsonrpc":"2.0","method":"notifications/initialized"}|}
    = None)

let mcp_cancellation () =
  let state = Centl_mcp.create () in
  ignore
    (mcp_request state
       {|{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}|});
  ignore
    (Centl_mcp.handle_json state
       (Yojson.Safe.from_string
          {|{"jsonrpc":"2.0","method":"notifications/initialized"}|}));
  let call =
    Yojson.Safe.from_string
      {|{"jsonrpc":"2.0","id":"tool-7","method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":"expand((x + 1)^20)"}}}|}
  in
  begin match Centl_mcp.cancellable_request_id call with
  | Some (`String id) -> Alcotest.(check string) "MCP request id" "tool-7" id
  | _ -> Alcotest.fail "MCP tool call was not classified as cancellable"
  end;
  let notification =
    Yojson.Safe.from_string
      {|{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":"tool-7","reason":"test"}}|}
  in
  begin match Centl_mcp.cancellation_target_of_json notification with
  | Some (`String id) -> Alcotest.(check string) "MCP cancel target" "tool-7" id
  | _ -> Alcotest.fail "MCP cancellation target was not recognized"
  end;
  let response =
    match Centl_mcp.handle_json ~cancelled:(fun () -> true) state call with
    | Some response -> response
    | None -> Alcotest.fail "cancelled MCP call produced no internal result"
  in
  let structured = mcp_structured_content response in
  Alcotest.(check string)
    "MCP cooperative error" "cancelled"
    (protocol_error_code structured);
  Alcotest.(check bool)
    "MCP cancellation is a tool error" true
    (response |> json_member "result" |> json_bool "isError");
  Alcotest.(check bool)
    "MCP notification has no response" true
    (Centl_mcp.handle_json state notification = None);
  let malformed =
    Yojson.Safe.from_string
      {|{"jsonrpc":"2.0","id":99,"method":"notifications/cancelled","params":{"requestId":"tool-7","reason":7}}|}
  in
  Alcotest.(check bool)
    "malformed MCP cancellation is not actionable" true
    (Centl_mcp.cancellation_target_of_json malformed = None);
  begin match Centl_mcp.handle_json state malformed with
  | Some response ->
      Alcotest.(check int)
        "notification method with an id is a request" (-32601)
        (mcp_error_code response)
  | None -> Alcotest.fail "an MCP request with an id must receive a response"
  end

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

let binder_scope_examples () =
  let deferred = Centl_engine.create_session () in
  ignore
    (session_text deferred
       "substituted(x) = sum(substitute(x^2, x = 3), k = 1, 2)");
  Alcotest.(check string)
    "substitution binder shadows a function parameter" "18"
    (session_text deferred "substituted(4)");
  ignore
    (session_text deferred "differentiated(y) = sum(diff(x*y, x), k = 1, 2)");
  Alcotest.(check string)
    "differentiation avoids argument capture" "x + x"
    (session_text deferred "differentiated(x)");
  Alcotest.(check string)
    "solution binder shadows an outer substitution" "x in {-2, 2}"
    (value "substitute(solve(x^2 = 4, x), x = 3)");
  let capture_avoiding_solution =
    Centl_Core.substitute
      (Centl_Core.Function
         ( "solve",
           [
             Centl_Core.Binary
               (Centl_Core.Add, Centl_Core.Symbol "y", Centl_Core.Symbol "x");
             Centl_Core.Literal (Z.one, Z.one);
             Centl_Core.Symbol "x";
           ] ))
      "y" (Centl_Core.Symbol "x")
  in
  begin match capture_avoiding_solution with
  | Centl_Core.Function
      ( "solve",
        [
          Centl_Core.Binary
            ( Centl_Core.Add,
              Centl_Core.Symbol free_variable,
              Centl_Core.Symbol renamed_occurrence );
          Centl_Core.Literal (one, denominator);
          Centl_Core.Symbol renamed_binder;
        ] ) ->
      Alcotest.(check string) "replacement remains free" "x" free_variable;
      Alcotest.(check bool)
        "solution variable is alpha-renamed" true (renamed_binder <> "x");
      Alcotest.(check string)
        "bound occurrences use the renamed solution variable" renamed_binder
        renamed_occurrence;
      Alcotest.(check bool)
        "equation right side is preserved" true
        (Z.equal one Z.one && Z.equal denominator Z.one)
  | _ -> Alcotest.fail "expected a capture-avoiding solve expression"
  end;
  Alcotest.(check string)
    "solution binder is not a recursive definition reference"
    "expression_definition_required"
    (session_error_code
       (Centl_engine.create_session ())
       "x = solve(x^2 = 4, x)")

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
  let channel = open_in_bin "../docs/SYNTAX.md" in
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

let property_real_quadratic_scaling () =
  let scale = QCheck.make QCheck.Gen.(oneof [ 1 -- 50; -50 -- -1 ]) in
  let nonsquare =
    QCheck.make QCheck.Gen.(oneof_list [ 2; 3; 5; 6; 7; 8; 10 ])
  in
  let test =
    QCheck.Test.make ~count:500 (QCheck.pair scale nonsquare)
      (fun (scale, radicand) ->
        let source =
          Printf.sprintf "solve((%d)*x^2 = (%d), x)" scale (scale * radicand)
        in
        value source
        = Printf.sprintf "x in {-sqrt(%d), sqrt(%d)}" radicand radicand)
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
      ( "exact polynomial integration",
        [
          Alcotest.test_case "canonical and definite examples" `Quick
            integration_examples;
          Alcotest.test_case "residual and malformed forms" `Quick
            integration_residuals_and_failures;
          Alcotest.test_case "lexical binder scope" `Quick
            integration_binder_scope;
          Alcotest.test_case "limits and cancellation" `Quick
            integration_limits_and_cancellation;
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
          Alcotest.test_case "real-quadratic scaling property" `Quick
            property_real_quadratic_scaling;
        ] );
      ( "definitions",
        [
          Alcotest.test_case "values and functions" `Quick definition_examples;
          Alcotest.test_case "lexical binder scope" `Quick binder_scope_examples;
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
      ( "errors",
        [
          Alcotest.test_case "structured failures" `Quick failures;
          Alcotest.test_case "runtime source positions" `Quick
            runtime_source_positions;
          Alcotest.test_case "session source positions" `Quick
            session_runtime_source_positions;
          Alcotest.test_case "session diagnostic scaling" `Quick
            session_diagnostic_origin_scaling;
        ] );
      ( "machine interface",
        [
          Alcotest.test_case "versioned request" `Quick json_protocol;
          Alcotest.test_case "symbolic result" `Quick symbolic_json_protocol;
          Alcotest.test_case "integration keeps rational schema" `Quick
            integration_json_protocol;
          Alcotest.test_case "rigorous enclosure" `Quick enclosure_json_protocol;
          Alcotest.test_case "structured condition" `Quick
            conditional_json_protocol;
          Alcotest.test_case "structured solution set" `Quick
            equation_json_protocol;
          Alcotest.test_case "exact real-quadratic solution set" `Quick
            real_quadratic_json_protocol;
          Alcotest.test_case "persistent sessions and request ids" `Quick
            persistent_json_protocol;
          Alcotest.test_case "resource limits" `Quick machine_resource_limits;
          Alcotest.test_case "capability description" `Quick machine_describe;
          Alcotest.test_case "structured provenance" `Quick machine_provenance;
          Alcotest.test_case "transformation resolution metadata" `Quick
            transformation_resolution_metadata;
          Alcotest.test_case "read-only compute and explicit define" `Quick
            machine_compute_and_define;
          Alcotest.test_case "structured error metadata" `Quick
            machine_error_metadata;
          Alcotest.test_case "closed rational claim verification" `Quick
            closed_claim_verification;
          Alcotest.test_case "assert grammar" `Quick assert_grammar;
          Alcotest.test_case "agent tool evaluation corpus" `Quick
            agent_tool_corpus;
          Alcotest.test_case "MCP residual text matches human" `Quick
            mcp_text_matches_human_resolution;
          Alcotest.test_case "cooperative cancellation" `Quick
            machine_cancellation;
          Alcotest.test_case "MCP schema laziness" `Quick mcp_schema_laziness;
          Alcotest.test_case "MCP lifecycle and tools" `Quick mcp_protocol;
          Alcotest.test_case "MCP output schemas" `Quick mcp_output_schemas;
          Alcotest.test_case "MCP failures" `Quick mcp_failures;
          Alcotest.test_case "MCP cancellation" `Quick mcp_cancellation;
        ] );
      ( "presentation",
        [
          Alcotest.test_case "coloration" `Quick coloration;
          Alcotest.test_case "syntax catalog" `Quick syntax_catalog;
        ] );
    ]
