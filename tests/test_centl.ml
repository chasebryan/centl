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
    (value "expand((x + 1)^65")
