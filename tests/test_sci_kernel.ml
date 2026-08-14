let test_uses_extracts_callees () =
  let uses =
    Centl_sci_kernel.uses_of_source
      "total_energy(mass, velocity, height, g) = kinetic_energy(mass, \
       velocity) + mass * g * height"
  in
  Alcotest.(check (list string)) "uses" [ "kinetic_energy" ] uses

let test_chain_split () =
  match
    Centl_sci_kernel.split_chain "let square(x) = x^2 and then square(6)"
  with
  | None -> Alcotest.fail "expected chain"
  | Some (left, right) ->
      Alcotest.(check string) "left" "let square(x) = x^2" left;
      Alcotest.(check string) "right" "square(6)" right

let test_math_is_not_a_chain () =
  Alcotest.(check bool)
    "ordinary and then in math" true
    (Option.is_none (Centl_sci_kernel.split_chain "what is 1 and then 2"))

let test_unknown_call () =
  Alcotest.(check (option string))
    "foo call" (Some "foo")
    (Centl_sci_kernel.unknown_call "foo(6)");
  Alcotest.(check bool)
    "reserved sin is not unknown program" true
    (Option.is_none (Centl_sci_kernel.unknown_call "sin(1)"))

let () =
  Alcotest.run "CENTL-SCi growth kernel"
    [
      ( "kernel",
        [
          Alcotest.test_case "uses" `Quick test_uses_extracts_callees;
          Alcotest.test_case "chain" `Quick test_chain_split;
          Alcotest.test_case "math is not a chain" `Quick
            test_math_is_not_a_chain;
          Alcotest.test_case "unknown call" `Quick test_unknown_call;
        ] );
    ]
