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

let parse text =
  match Centl_sci_ir.of_string text with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_sci_ir.string_of_error error)

let test_coefficient_variable () =
  Alcotest.(check string)
    "coefficient multiplication" "x^2 - 5*x + 6"
    (Centl_sci_runtime.normalize_polynomial_side ~variable:"x" "x^2 - 5x + 6");
  Alcotest.(check string)
    "parenthesized coefficient multiplication" "(1/2)*x + 1"
    (Centl_sci_runtime.normalize_polynomial_side ~variable:"x" "(1/2)x + 1")

let test_identifier_boundary () =
  Alcotest.(check string)
    "do not split another identifier" "5xy + 1"
    (Centl_sci_runtime.normalize_polynomial_side ~variable:"x" "5xy + 1")

let test_model_style_equation_executes () =
  let ir =
    parse
      {|{"schema_version":1,"domain":"mathematics","problem_class":"polynomial_equation","operation":"solve","assumptions":[],"left":"x^2 - 5x + 6","relation":"equal","right":"0","variable":"x"}|}
  in
  let outcome = Centl_sci_runtime.execute ir in
  Alcotest.(check string)
    "status" "established"
    (Centl_sci_runtime.status_text outcome.status);
  begin match outcome.plan with
  | Some plan ->
      let request_expression = string "expression" plan.request in
      Alcotest.(check string)
        "lowered execution request" "solve((x^2 - 5*x + 6) = (0), x)"
        request_expression
  | None -> Alcotest.fail "expected execution plan"
  end;
  match outcome.response with
  | Some response ->
      let value = assoc "value" response in
      Alcotest.(check string) "solutions" "x in {2, 3}" (string "text" value)
  | None -> Alcotest.fail "expected CENTL response"

let test_verification_schema_and_lowering () =
  Alcotest.(check bool)
    "canonical schema includes verification_claim" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"verification_claim"
          Centl_sci_ir.json_schema));
  let ir =
    parse
      {|{"schema_version":1,"domain":"mathematics","problem_class":"verification_claim","operation":"verify","assumptions":[],"left":"0.1 + 0.2","relation":"equal","right":"3/10"}|}
  in
  match Centl_sci_runtime.plan ir with
  | None -> Alcotest.fail "expected verification execution plan"
  | Some plan ->
      Alcotest.(check string) "op" "verify" (string "op" plan.request);
      Alcotest.(check string) "left" "0.1 + 0.2" (string "left" plan.request);
      Alcotest.(check string)
        "relation" "equal"
        (string "relation" plan.request);
      Alcotest.(check string) "right" "3/10" (string "right" plan.request)

let test_verification_rejects_inferred_assumptions () =
  match
    Centl_sci_ir.of_string
      {|{"schema_version":1,"domain":"mathematics","problem_class":"verification_claim","operation":"verify","assumptions":["x is real"],"left":"x","relation":"equal","right":"x"}|}
  with
  | Error error ->
      Alcotest.(check string) "error class" "invalid_ir" error.code;
      Alcotest.(check bool)
        "closed-claim boundary is explicit" true
        (Option.is_some
           (Centl_sci_interaction.find_substring
              ~needle:"closed verification claims" error.message))
  | Ok _ -> Alcotest.fail "verification_claim must reject inferred assumptions"

let test_model_unit_names_execute () =
  let ir =
    parse
      {|{"schema_version":1,"domain":"physics","problem_class":"unit_conversion","operation":"convert","assumptions":[],"value":"100","from_unit":"centimeters","to_unit":"meters"}|}
  in
  let outcome = Centl_sci_runtime.execute ir in
  Alcotest.(check string)
    "status" "established"
    (Centl_sci_runtime.status_text outcome.status);
  begin match outcome.plan with
  | Some plan ->
      Alcotest.(check string)
        "canonical from" "cm"
        (string "from_unit" plan.request);
      Alcotest.(check string) "canonical to" "m" (string "to_unit" plan.request)
  | None -> Alcotest.fail "expected conversion execution plan"
  end;
  match outcome.response with
  | Some response ->
      Alcotest.(check (option string))
        "exact result" (Some "1 m")
        (Centl_sci_runtime.result_text response)
  | None -> Alcotest.fail "expected CENTL Physics response"

let () =
  Alcotest.run "centl-sci-lowering"
    [
      ( "polynomial",
        [
          Alcotest.test_case "coefficient variable" `Quick
            test_coefficient_variable;
          Alcotest.test_case "identifier boundary" `Quick
            test_identifier_boundary;
          Alcotest.test_case "model style equation executes" `Quick
            test_model_style_equation_executes;
        ] );
      ( "verification",
        [
          Alcotest.test_case "schema and protocol lowering" `Quick
            test_verification_schema_and_lowering;
          Alcotest.test_case "closed claims reject assumptions" `Quick
            test_verification_rejects_inferred_assumptions;
        ] );
      ( "units",
        [
          Alcotest.test_case "model unit names execute" `Quick
            test_model_unit_names_execute;
        ] );
    ]
