let parse text =
  match Centl_sci_ir.of_string text with
  | Ok value -> value
  | Error error -> Alcotest.fail (Centl_sci_ir.string_of_error error)

let execute text = parse text |> Centl_sci_runtime.execute

let test_exact_human () =
  let outcome =
    execute
      {|{"schema_version":1,"domain":"mathematics","problem_class":"exact_expression","operation":"compute","assumptions":[],"expression":"0.1 + 0.2"}|}
  in
  Alcotest.(check string) "answer" "3/10" (Centl_sci_present.human outcome)

let test_solution_set_human () =
  let outcome =
    execute
      {|{"schema_version":1,"domain":"mathematics","problem_class":"polynomial_equation","operation":"solve","assumptions":[],"left":"x^2 - 5*x + 6","relation":"equal","right":"0","variable":"x"}|}
  in
  Alcotest.(check string)
    "natural solutions" "x = 2 or x = 3"
    (Centl_sci_present.human outcome)

let test_unit_human () =
  let outcome =
    execute
      {|{"schema_version":1,"domain":"physics","problem_class":"unit_conversion","operation":"convert","assumptions":[],"value":"2.5","from_unit":"km","to_unit":"m"}|}
  in
  Alcotest.(check string) "natural unit" "2500 m" (Centl_sci_present.human outcome)

let test_details () =
  let outcome =
    execute
      {|{"schema_version":1,"domain":"mathematics","problem_class":"polynomial_equation","operation":"solve","assumptions":[],"left":"x^2 - 5*x + 6","relation":"equal","right":"0","variable":"x"}|}
  in
  Alcotest.(check string)
    "details"
    "x = 2 or x = 3\n\nDetails:\n  Exact result\n  Variable: x\n  Method: polynomial equation solving\n  Verified by CENTL"
    (Centl_sci_present.details outcome)

let test_missing_information () =
  let outcome =
    execute
      {|{"schema_version":1,"domain":"unsupported","problem_class":"unsupported","operation":"unsupported","assumptions":[],"reason":"missing initial position and velocity"}|}
  in
  Alcotest.(check string)
    "missing data" "More information is required to solve this problem."
    (Centl_sci_present.human outcome)

let test_unsupported () =
  let outcome =
    execute
      {|{"schema_version":1,"domain":"unsupported","problem_class":"unsupported","operation":"unsupported","assumptions":[],"reason":"mechanics class not yet admitted"}|}
  in
  Alcotest.(check string)
    "unsupported" "CENTL-SCi cannot solve this problem yet."
    (Centl_sci_present.human outcome)

let test_failed () =
  let outcome =
    execute
      {|{"schema_version":1,"domain":"physics","problem_class":"unit_conversion","operation":"convert","assumptions":[],"value":"5","from_unit":"m","to_unit":"s"}|}
  in
  Alcotest.(check string)
    "failed" "CENTL could not establish a result."
    (Centl_sci_present.human outcome)

let test_approximation_is_qualified () =
  let ir =
    parse
      {|{"schema_version":1,"domain":"mathematics","problem_class":"exact_expression","operation":"compute","assumptions":[],"expression":"sqrt(2)"}|}
  in
  let outcome : Centl_sci_runtime.outcome =
    {
      ir;
      plan = None;
      response =
        Some
          (`Assoc
             [
               ("ok", `Bool true);
               ( "value",
                 `Assoc
                   [
                     ("kind", `String "interval");
                     ("exact", `Bool false);
                     ("text", `String "≈ [1.4142, 1.4143]");
                   ] );
             ]);
      status = Centl_sci_runtime.Established;
    }
  in
  Alcotest.(check string)
    "qualified approximation" "Approximately between 1.4142 and 1.4143"
    (Centl_sci_present.human outcome)

let () =
  Alcotest.run "centl-sci-presentation"
    [
      ( "human",
        [
          Alcotest.test_case "exact arithmetic" `Quick test_exact_human;
          Alcotest.test_case "solution set" `Quick test_solution_set_human;
          Alcotest.test_case "unit conversion" `Quick test_unit_human;
          Alcotest.test_case "missing information" `Quick test_missing_information;
          Alcotest.test_case "unsupported" `Quick test_unsupported;
          Alcotest.test_case "failed" `Quick test_failed;
          Alcotest.test_case "approximation qualification" `Quick
            test_approximation_is_qualified;
        ] );
      ( "details",
        [ Alcotest.test_case "scientific metadata" `Quick test_details ] );
    ]
