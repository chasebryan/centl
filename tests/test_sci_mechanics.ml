let fail message = Alcotest.fail message

let test_example_interprets () =
  match Centl_sci_mechanics.interpret Centl_sci_mechanics.example with
  | Some (Centl_sci_ir.Uniform_gravity_particle data) ->
      Alcotest.(check string) "mass" "2" data.mass_value;
      Alcotest.(check string) "position z" "10" data.position_z;
      Alcotest.(check string) "gravity z" "-10" data.gravity_z;
      Alcotest.(check string) "dt" "1/10" data.dt_value;
      Alcotest.(check int) "steps" 10 data.steps
  | Some _ -> fail "expected uniform-gravity particle IR"
  | None -> fail "example did not interpret"

let test_example_executes_deterministically () =
  match Centl_sci_mechanics.interpret Centl_sci_mechanics.example with
  | None -> fail "example did not interpret"
  | Some ir ->
      let outcome = Centl_sci_runtime.execute ir in
      Alcotest.(check string)
        "status" "established"
        (Centl_sci_runtime.status_text outcome.status);
      begin match outcome.response with
      | None -> fail "missing physics response"
      | Some response ->
          begin match Centl_sci_runtime.result_text response with
          | None -> fail "missing human simulation result"
          | Some text ->
              Alcotest.(check bool)
                "final z appears" true
                (Option.is_some
                   (Centl_sci_interaction.find_substring ~needle:"9/2" text))
          end;
          begin match Centl_sci_runtime.assoc_field "physics" response with
          | Some physics ->
              Alcotest.(check (option string))
                "structured integrator" (Some "symplectic_euler")
                (Centl_sci_runtime.string_field "integrator" physics)
          | None -> fail "missing structured physics result"
          end;
          let details = Centl_sci_present.details outcome in
          Alcotest.(check bool)
            "details explain integrator" true
            (Option.is_some
               (Centl_sci_interaction.find_substring ~needle:"symplectic Euler"
                  details))
      end

let test_missing_fields_clarifies () =
  match
    Centl_sci_interaction.clarification Centl_sci_interaction.Phys
      "simulate a particle with mass 2 kg"
  with
  | None -> fail "expected mechanics clarification"
  | Some message ->
      Alcotest.(check bool)
        "asks for position" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"position" message));
      Alcotest.(check bool)
        "does not invent data" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"Supply mass" message))

let () =
  Alcotest.run "CENTL-SCi Caramels mechanics"
    [
      ( "uniform gravity",
        [
          Alcotest.test_case "typed example" `Quick test_example_interprets;
          Alcotest.test_case "deterministic execution" `Quick
            test_example_executes_deterministically;
          Alcotest.test_case "missing fields clarify" `Quick
            test_missing_fields_clarifies;
        ] );
    ]
