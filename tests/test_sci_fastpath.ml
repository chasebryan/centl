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
          | Some (`String value) -> Alcotest.(check string) "solutions" "x in {2, 3}" value
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
          Alcotest.test_case "unit conversion language" `Quick
            test_unit_conversion_language;
          Alcotest.test_case "symbolic equation" `Quick test_symbolic_equation;
          Alcotest.test_case "spoken equation" `Quick test_spoken_equation;
          Alcotest.test_case "ambiguous spoken equation defers" `Quick
            test_ambiguous_spoken_equation_defers_to_model;
          Alcotest.test_case "general knowledge defers" `Quick
            test_general_knowledge_defers_to_model;
        ] );
      ( "execution",
        [
          Alcotest.test_case "exact result" `Quick
            test_fast_path_executes_exactly;
          Alcotest.test_case "spoken equation exact result" `Quick
            test_spoken_equation_executes_exactly;
        ] );
    ]
