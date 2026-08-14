let require_some label = function
  | Some value -> value
  | None ->
      Alcotest.fail (label ^ " was not admitted by the deterministic fast path")

let test_exact_decimal_language () =
  match
    Centl_sci_fastpath.interpret "What is 0.1 plus 0.2?"
    |> require_some "exact decimal addition"
  with
  | Centl_sci_ir.Exact_expression data ->
      Alcotest.(check string) "expression" "0.1 + 0.2" data.expression
  | _ -> Alcotest.fail "expected exact_expression fast-path IR"

let test_approximation_language () =
  match
    Centl_sci_fastpath.interpret "Approximate pi."
    |> require_some "default approximation"
  with
  | Centl_sci_ir.Exact_expression data ->
      Alcotest.(check string) "expression" "approx(pi)" data.expression
  | _ -> Alcotest.fail "expected exact_expression approximation IR"

let test_approximation_precision_language () =
  match
    Centl_sci_fastpath.interpret "Approximate sqrt(2) to 30 significant digits."
    |> require_some "explicit approximation precision"
  with
  | Centl_sci_ir.Exact_expression data ->
      Alcotest.(check string) "expression" "approx(sqrt(2), 30)" data.expression
  | _ -> Alcotest.fail "expected exact_expression approximation IR"

let test_verification_language () =
  match
    Centl_sci_fastpath.interpret "Verify 0.1 + 0.2 equals 3/10."
    |> require_some "closed verification claim"
  with
  | Centl_sci_ir.Verification_claim data ->
      Alcotest.(check string) "left" "0.1 + 0.2" data.left;
      Alcotest.(check string) "relation" "equal" data.relation;
      Alcotest.(check string) "right" "3/10" data.right;
      Alcotest.(check (list string))
        "no inferred assumptions" [] data.verification_assumptions
  | _ -> Alcotest.fail "expected verification_claim fast-path IR"

let test_verification_inequality_language () =
  match
    Centl_sci_fastpath.interpret "Check whether 1/3 < 1/2."
    |> require_some "closed inequality verification claim"
  with
  | Centl_sci_ir.Verification_claim data ->
      Alcotest.(check string) "left" "1/3" data.left;
      Alcotest.(check string) "relation" "less_than" data.relation;
      Alcotest.(check string) "right" "1/2" data.right
  | _ -> Alcotest.fail "expected verification_claim inequality IR"

let test_unit_conversion_language () =
  match
    Centl_sci_fastpath.interpret "Convert 100 centimeters to meters."
    |> require_some "unit conversion"
  with
  | Centl_sci_ir.Unit_conversion data ->
      Alcotest.(check string) "value" "100" data.value;
      Alcotest.(check string) "from" "cm" data.from_unit;
      Alcotest.(check string) "to" "m" data.to_unit
  | _ -> Alcotest.fail "expected unit_conversion fast-path IR"

let test_exact_constant_language () =
  match
    Centl_sci_fastpath.interpret "What is the speed of light in vacuum?"
    |> require_some "speed of light"
  with
  | Centl_sci_ir.Physical_constant data ->
      Alcotest.(check string) "constant symbol" "c" data.symbol
  | _ -> Alcotest.fail "expected physical_constant fast-path IR"

let test_exact_constant_symbol_language () =
  match
    Centl_sci_fastpath.interpret "constant k_B"
    |> require_some "Boltzmann constant symbol"
  with
  | Centl_sci_ir.Physical_constant data ->
      Alcotest.(check string) "constant symbol" "k_B" data.symbol
  | _ -> Alcotest.fail "expected physical_constant fast-path IR"

let test_measured_constant_is_explicitly_outside_catalog () =
  match
    Centl_sci_fastpath.interpret
      "What is the Newtonian gravitational constant G?"
    |> require_some "measured Newtonian gravitational constant boundary"
  with
  | Centl_sci_ir.Unsupported data ->
      Alcotest.(check bool)
        "measured boundary is explicit" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"measured Newtonian"
              data.unsupported_reason))
  | _ -> Alcotest.fail "expected explicit unsupported IR for measured constant"

let test_symbolic_equation () =
  match
    Centl_sci_fastpath.interpret "Solve x^2 - 5*x + 6 = 0 for x."
    |> require_some "symbolic equation"
  with
  | Centl_sci_ir.Polynomial_equation data ->
      Alcotest.(check string) "left" "x^2 - 5*x + 6" data.left;
      Alcotest.(check string) "right" "0" data.right;
      Alcotest.(check string) "variable" "x" data.variable
  | _ -> Alcotest.fail "expected polynomial_equation fast-path IR"

let test_spoken_equation () =
  match
    Centl_sci_fastpath.interpret
      "Solve x squared minus 5 x plus 6 equals zero for x."
    |> require_some "spoken polynomial equation"
  with
  | Centl_sci_ir.Polynomial_equation data ->
      Alcotest.(check string) "left" "x^2 - 5*x + 6" data.left;
      Alcotest.(check string) "right" "0" data.right;
      Alcotest.(check string) "variable" "x" data.variable
  | _ -> Alcotest.fail "expected spoken polynomial_equation fast-path IR"

let test_spoken_equation_infers_leading_variable () =
  match
    Centl_sci_fastpath.interpret "Solve x squared minus 5x plus 6 equals zero."
    |> require_some
         "spoken polynomial equation without explicit variable suffix"
  with
  | Centl_sci_ir.Polynomial_equation data ->
      Alcotest.(check string) "left" "x^2 - 5*x + 6" data.left;
      Alcotest.(check string) "right" "0" data.right;
      Alcotest.(check string) "variable" "x" data.variable
  | _ -> Alcotest.fail "expected polynomial_equation fast-path IR"

let test_ambiguous_spoken_equation_defers_to_model () =
  Alcotest.(check bool)
    "ambiguous language is not overclaimed" true
    (Option.is_none
       (Centl_sci_fastpath.interpret
          "Solve the equation from the previous example for x."))

let test_general_knowledge_defers_to_model () =
  Alcotest.(check bool)
    "general knowledge is not admitted" true
    (Option.is_none
       (Centl_sci_fastpath.interpret
          "Who was the 16th president of the United States?"))

let test_gcd_language () =
  match
    Centl_sci_fastpath.interpret "What is the gcd of 48 and 18?"
    |> require_some "gcd combinator"
  with
  | Centl_sci_ir.Exact_expression data ->
      Alcotest.(check string) "expression" "gcd(48, 18)" data.expression
  | _ -> Alcotest.fail "expected exact_expression gcd IR"

let test_sum_language () =
  match
    Centl_sci_fastpath.interpret "sum of k^2 from 1 to 10"
    |> require_some "sum series"
  with
  | Centl_sci_ir.Exact_expression data ->
      Alcotest.(check string) "expression" "sum(k^2, k = 1, 10)" data.expression
  | _ -> Alcotest.fail "expected exact_expression sum IR"

let test_product_language () =
  match
    Centl_sci_fastpath.interpret "product of k from 1 to 5"
    |> require_some "product series"
  with
  | Centl_sci_ir.Exact_expression data ->
      Alcotest.(check string)
        "expression" "product(k, k = 1, 5)" data.expression
  | _ -> Alcotest.fail "expected exact_expression product IR"

let test_ordinal_fibonacci_language () =
  match
    Centl_sci_fastpath.interpret "the 10th fibonacci number"
    |> require_some "ordinal fibonacci"
  with
  | Centl_sci_ir.Exact_expression data ->
      Alcotest.(check string) "expression" "fibonacci(10)" data.expression
  | _ -> Alcotest.fail "expected exact_expression ordinal fibonacci IR"

let test_factorial_language () =
  match
    Centl_sci_fastpath.interpret "factorial of 6"
    |> require_some "factorial combinator"
  with
  | Centl_sci_ir.Exact_expression data ->
      Alcotest.(check string) "expression" "factorial(6)" data.expression
  | _ -> Alcotest.fail "expected exact_expression factorial IR"

let test_fibonacci_language () =
  match
    Centl_sci_fastpath.interpret "fibonacci of 10"
    |> require_some "fibonacci combinator"
  with
  | Centl_sci_ir.Exact_expression data ->
      Alcotest.(check string) "expression" "fibonacci(10)" data.expression
  | _ -> Alcotest.fail "expected exact_expression fibonacci IR"

let test_named_call_language () =
  match
    Centl_sci_fastpath.interpret "square(6)" |> require_some "named local call"
  with
  | Centl_sci_ir.Exact_expression data ->
      Alcotest.(check string) "expression" "square(6)" data.expression
  | _ -> Alcotest.fail "expected exact_expression named call IR"

let test_fast_path_executes_exactly () =
  let ir =
    Centl_sci_fastpath.interpret "What is 0.1 plus 0.2?"
    |> require_some "exact decimal addition"
  in
  let outcome = Centl_sci_runtime.execute ir in
  Alcotest.(check string)
    "status" "established"
    (Centl_sci_runtime.status_text outcome.status);
  match outcome.response with
  | None -> Alcotest.fail "expected CENTL response"
  | Some (`Assoc fields) ->
      begin match List.assoc_opt "value" fields with
      | Some (`Assoc value_fields) ->
          begin match List.assoc_opt "text" value_fields with
          | Some (`String value) ->
              Alcotest.(check string) "exact decimal result" "3/10" value
          | _ -> Alcotest.fail "missing exact result text"
          end
      | _ -> Alcotest.fail "missing CENTL value"
      end
  | Some _ -> Alcotest.fail "expected structured CENTL response"

let verification_outcome problem =
  let ir = Centl_sci_fastpath.interpret problem |> require_some problem in
  Centl_sci_runtime.execute ir

let test_verification_executes_verified () =
  let outcome = verification_outcome "Verify 0.1 + 0.2 equals 3/10." in
  Alcotest.(check string)
    "status" "established"
    (Centl_sci_runtime.status_text outcome.status);
  Alcotest.(check string)
    "human verdict" "Verified."
    (Centl_sci_present.human outcome)

let test_verification_executes_refuted () =
  let outcome = verification_outcome "Verify 2 + 2 equals 5." in
  Alcotest.(check string)
    "status" "established"
    (Centl_sci_runtime.status_text outcome.status);
  Alcotest.(check string)
    "human verdict" "Refuted."
    (Centl_sci_present.human outcome)

let test_verification_unknown_remains_visible () =
  let outcome = verification_outcome "Verify x + 1 equals 2." in
  Alcotest.(check string)
    "status" "unresolved"
    (Centl_sci_runtime.status_text outcome.status);
  let rendered = Centl_sci_present.human outcome in
  Alcotest.(check bool)
    "unknown verifier verdict is visible" true
    (String.starts_with ~prefix:"Unknown" rendered)

let test_exact_constant_executes () =
  let ir =
    Centl_sci_fastpath.interpret "What is the speed of light?"
    |> require_some "speed of light"
  in
  let outcome = Centl_sci_runtime.execute ir in
  Alcotest.(check string)
    "status" "established"
    (Centl_sci_runtime.status_text outcome.status);
  match outcome.response with
  | Some response ->
      begin match Centl_sci_runtime.result_text response with
      | Some text ->
          Alcotest.(check bool)
            "exact c value appears" true
            (Option.is_some
               (Centl_sci_interaction.find_substring ~needle:"299792458" text))
      | None -> Alcotest.fail "missing constant result text"
      end
  | None -> Alcotest.fail "expected physics constant response"

let test_spoken_equation_executes_exactly () =
  let ir =
    Centl_sci_fastpath.interpret
      "Solve x squared minus 5 x plus 6 equals zero for x."
    |> require_some "spoken polynomial equation"
  in
  let outcome = Centl_sci_runtime.execute ir in
  Alcotest.(check string)
    "status" "established"
    (Centl_sci_runtime.status_text outcome.status);
  match outcome.response with
  | Some (`Assoc fields) ->
      begin match List.assoc_opt "value" fields with
      | Some (`Assoc value_fields) ->
          begin match List.assoc_opt "text" value_fields with
          | Some (`String value) ->
              Alcotest.(check string) "solutions" "x in {2, 3}" value
          | _ -> Alcotest.fail "missing solution text"
          end
      | _ -> Alcotest.fail "missing CENTL value"
      end
  | _ -> Alcotest.fail "expected structured CENTL response"

let () =
  Alcotest.run "centl-sci-fastpath"
    [
      ( "admission",
        [
          Alcotest.test_case "exact decimal language" `Quick
            test_exact_decimal_language;
          Alcotest.test_case "default approximation" `Quick
            test_approximation_language;
          Alcotest.test_case "explicit approximation precision" `Quick
            test_approximation_precision_language;
          Alcotest.test_case "closed verification claim" `Quick
            test_verification_language;
          Alcotest.test_case "closed verification inequality" `Quick
            test_verification_inequality_language;
          Alcotest.test_case "unit conversion language" `Quick
            test_unit_conversion_language;
          Alcotest.test_case "exact physical constant" `Quick
            test_exact_constant_language;
          Alcotest.test_case "constant symbol" `Quick
            test_exact_constant_symbol_language;
          Alcotest.test_case "measured constant boundary" `Quick
            test_measured_constant_is_explicitly_outside_catalog;
          Alcotest.test_case "symbolic equation" `Quick test_symbolic_equation;
          Alcotest.test_case "spoken equation" `Quick test_spoken_equation;
          Alcotest.test_case "spoken equation infers leading variable" `Quick
            test_spoken_equation_infers_leading_variable;
          Alcotest.test_case "ambiguous spoken equation defers" `Quick
            test_ambiguous_spoken_equation_defers_to_model;
          Alcotest.test_case "general knowledge defers" `Quick
            test_general_knowledge_defers_to_model;
          Alcotest.test_case "gcd language" `Quick test_gcd_language;
          Alcotest.test_case "fibonacci language" `Quick test_fibonacci_language;
          Alcotest.test_case "sum language" `Quick test_sum_language;
          Alcotest.test_case "factorial language" `Quick test_factorial_language;
          Alcotest.test_case "product language" `Quick test_product_language;
          Alcotest.test_case "ordinal fibonacci" `Quick
            test_ordinal_fibonacci_language;
          Alcotest.test_case "named local call" `Quick test_named_call_language;
        ] );
      ( "execution",
        [
          Alcotest.test_case "exact result" `Quick
            test_fast_path_executes_exactly;
          Alcotest.test_case "verification verified" `Quick
            test_verification_executes_verified;
          Alcotest.test_case "verification refuted" `Quick
            test_verification_executes_refuted;
          Alcotest.test_case "verification unknown" `Quick
            test_verification_unknown_remains_visible;
          Alcotest.test_case "exact physical constant result" `Quick
            test_exact_constant_executes;
          Alcotest.test_case "spoken equation exact result" `Quick
            test_spoken_equation_executes_exactly;
        ] );
    ]
