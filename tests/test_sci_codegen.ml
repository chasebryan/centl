let test_function_generation () =
  let input =
    "create a function named kinetic_energy that takes mass and velocity and \
     computes 1/2 * mass * velocity^2"
  in
  match Centl_sci_codegen.generate input with
  | Centl_sci_codegen.Generated
      (Centl_sci_codegen.Function { replace = false; source }) ->
      Alcotest.(check string)
        "native source"
        "kinetic_energy(mass, velocity) = 1/2 * mass * velocity^2" source
  | _ -> Alcotest.fail "expected generated function"

let test_value_generation () =
  match Centl_sci_codegen.generate "create a value named tau equal to 2*pi" with
  | Centl_sci_codegen.Generated
      (Centl_sci_codegen.Value { replace = false; source }) ->
      Alcotest.(check string) "native source" "tau = 2*pi" source
  | _ -> Alcotest.fail "expected generated value"

let test_modify_generation () =
  let input = "modify a function named square that takes x and returns x^2" in
  match Centl_sci_codegen.generate input with
  | Centl_sci_codegen.Generated
      (Centl_sci_codegen.Function { replace = true; source }) ->
      Alcotest.(check string) "native source" "square(x) = x^2" source
  | _ -> Alcotest.fail "expected generated function modification"

let test_change_ir_json () =
  let request =
    Centl_sci_change_ir.native_definition ~action:Centl_sci_change_ir.Create
      ~target_kind:Centl_sci_change_ir.Function ~name:"f" ~parameters:[ "x" ]
      ~implementation:"x + 1"
  in
  match Centl_sci_change_ir.to_centl_source request with
  | Error message -> Alcotest.fail message
  | Ok source -> Alcotest.(check string) "source" "f(x) = x + 1" source

let test_missing_body_clarifies () =
  match Centl_sci_codegen.generate "create a function named f that takes x" with
  | Centl_sci_codegen.Needs_clarification _ -> ()
  | _ -> Alcotest.fail "incomplete generated function should clarify"

let () =
  Alcotest.run "CENTL-SCi Caramels code generation"
    [
      ( "change IR",
        [
          Alcotest.test_case "function" `Quick test_function_generation;
          Alcotest.test_case "value" `Quick test_value_generation;
          Alcotest.test_case "modify" `Quick test_modify_generation;
          Alcotest.test_case "IR source" `Quick test_change_ir_json;
          Alcotest.test_case "clarification" `Quick test_missing_body_clarifies;
        ] );
    ]
