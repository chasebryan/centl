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

let parse text =
  match Centl_sci_ir.of_string text with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_sci_ir.string_of_error error)

let expect_ir_error text =
  match Centl_sci_ir.of_string text with
  | Ok _ -> Alcotest.fail "expected CENTL-SCi IR rejection"
  | Error _ -> ()

let response outcome =
  match outcome.Centl_sci_runtime.response with
  | Some value -> value
  | None -> Alcotest.fail "expected CENTL response"

let test_schema_is_json () =
  match Yojson.Safe.from_string Centl_sci_ir.json_schema with
  | `Assoc _ -> ()
  | _ -> Alcotest.fail "SCi schema must be a JSON object"

let test_exact_expression_ir () =
  let ir =
    parse
      {|{"schema_version":1,"domain":"mathematics","problem_class":"exact_expression","operation":"compute","assumptions":[],"expression":"0.1 + 0.2"}|}
  in
  Alcotest.(check string)
    "class" "exact_expression" (Centl_sci_ir.problem_class ir);
  Alcotest.(check string) "operation" "compute" (Centl_sci_ir.operation ir)

let test_equation_ir () =
  let ir =
    parse
      {|{"schema_version":1,"domain":"mathematics","problem_class":"polynomial_equation","operation":"solve","assumptions":[],"left":"x^2 - 5*x + 6","relation":"equal","right":"0","variable":"x"}|}
  in
  match ir with
  | Centl_sci_ir.Polynomial_equation value ->
      Alcotest.(check string) "variable" "x" value.variable
  | _ -> Alcotest.fail "expected polynomial equation IR"

let test_unit_conversion_ir () =
  let ir =
    parse
      {|{"schema_version":1,"domain":"physics","problem_class":"unit_conversion","operation":"convert","assumptions":[],"value":"100","from_unit":"cm","to_unit":"m"}|}
  in
  match ir with
  | Centl_sci_ir.Unit_conversion value ->
      Alcotest.(check string) "value" "100" value.value;
      Alcotest.(check string) "from" "cm" value.from_unit;
      Alcotest.(check string) "to" "m" value.to_unit
  | _ -> Alcotest.fail "expected unit conversion IR"

let test_ir_rejects_hallucinated_operation () =
  expect_ir_error
    {|{"schema_version":1,"domain":"mathematics","problem_class":"exact_expression","operation":"run_shell","assumptions":[],"expression":"1 + 1"}|}

let test_ir_rejects_unknown_field () =
  expect_ir_error
    {|{"schema_version":1,"domain":"mathematics","problem_class":"exact_expression","operation":"compute","assumptions":[],"expression":"1 + 1","unexpected":"not permitted"}|}

let test_ir_rejects_equation_separator_injection () =
  expect_ir_error
    {|{"schema_version":1,"domain":"mathematics","problem_class":"polynomial_equation","operation":"solve","assumptions":[],"left":"x, unsupported(1)","relation":"equal","right":"0","variable":"x"}|}

let test_ir_rejects_prose () =
  expect_ir_error "The answer is probably 42."

let test_compute_runtime () =
  let ir =
    parse
      {|{"schema_version":1,"domain":"mathematics","problem_class":"exact_expression","operation":"compute","assumptions":[],"expression":"0.1 + 0.2"}|}
  in
  let outcome = Centl_sci_runtime.execute ir in
  Alcotest.(check string)
    "status" "established" (Centl_sci_runtime.status_text outcome.status);
  let result = response outcome in
  Alcotest.(check bool) "success" true (bool "ok" result);
  let value = assoc "value" result in
  Alcotest.(check string) "exact decimal result" "3/10" (string "text" value);
  let provenance = assoc "provenance" result in
  Alcotest.(check string) "classification" "exact" (string "classification" provenance)

let test_solve_runtime () =
  let ir =
    parse
      {|{"schema_version":1,"domain":"mathematics","problem_class":"polynomial_equation","operation":"solve","assumptions":[],"left":"x^2 - 5*x + 6","relation":"equal","right":"0","variable":"x"}|}
  in
  let outcome = Centl_sci_runtime.execute ir in
  Alcotest.(check string)
    "status" "established" (Centl_sci_runtime.status_text outcome.status);
  let result = response outcome in
  let value = assoc "value" result in
  Alcotest.(check string) "solutions" "x in {2, 3}" (string "text" value);
  let resolution = assoc "resolution" result in
  Alcotest.(check string) "resolution" "transformed" (string "status" resolution)

let test_conversion_runtime () =
  let ir =
    parse
      {|{"schema_version":1,"domain":"physics","problem_class":"unit_conversion","operation":"convert","assumptions":[],"value":"100","from_unit":"cm","to_unit":"m"}|}
  in
  let outcome = Centl_sci_runtime.execute ir in
  Alcotest.(check string)
    "status" "established" (Centl_sci_runtime.status_text outcome.status);
  let result = response outcome in
  Alcotest.(check bool) "success" true (bool "ok" result);
  let physics = assoc "physics" result in
  Alcotest.(check string) "exact conversion" "1" (string "result" physics);
  Alcotest.(check bool) "exact" true (bool "exact" physics)

let test_unsupported_has_no_execution () =
  let ir =
    parse
      {|{"schema_version":1,"domain":"unsupported","problem_class":"unsupported","operation":"unsupported","assumptions":[],"reason":"outside v0.0.1 support"}|}
  in
  let outcome = Centl_sci_runtime.execute ir in
  Alcotest.(check string)
    "status" "unsupported" (Centl_sci_runtime.status_text outcome.status);
  Alcotest.(check bool) "no execution" true (Option.is_none outcome.plan);
  Alcotest.(check bool) "no response" true (Option.is_none outcome.response)

let test_model_argv_is_offline_and_schema_constrained () =
  let config =
    Centl_sci_llama.default ~executable:"/usr/bin/llama-cli"
      ~model:"/models/sci.gguf" ()
  in
  let arguments = Centl_sci_llama.argv config "Solve x = 2." |> Array.to_list in
  Alcotest.(check bool) "offline" true (List.mem "--offline" arguments);
  Alcotest.(check bool) "schema" true (List.mem "--json-schema" arguments);
  Alcotest.(check bool) "single turn" true (List.mem "--single-turn" arguments);
  Alcotest.(check bool) "no shell command" false (List.mem "sh" arguments)

let () =
  Alcotest.run "centl-sci"
    [
      ( "ir",
        [
          Alcotest.test_case "schema is JSON" `Quick test_schema_is_json;
          Alcotest.test_case "exact expression" `Quick test_exact_expression_ir;
          Alcotest.test_case "equation" `Quick test_equation_ir;
          Alcotest.test_case "unit conversion" `Quick test_unit_conversion_ir;
          Alcotest.test_case "hallucinated operation" `Quick
            test_ir_rejects_hallucinated_operation;
          Alcotest.test_case "unknown field" `Quick test_ir_rejects_unknown_field;
          Alcotest.test_case "equation injection" `Quick
            test_ir_rejects_equation_separator_injection;
          Alcotest.test_case "prose output" `Quick test_ir_rejects_prose;
        ] );
      ( "runtime",
        [
          Alcotest.test_case "exact computation" `Quick test_compute_runtime;
          Alcotest.test_case "equation solve" `Quick test_solve_runtime;
          Alcotest.test_case "unit conversion" `Quick test_conversion_runtime;
          Alcotest.test_case "unsupported" `Quick test_unsupported_has_no_execution;
        ] );
      ( "inference",
        [
          Alcotest.test_case "offline constrained argv" `Quick
            test_model_argv_is_offline_and_schema_constrained;
        ] );
    ]
