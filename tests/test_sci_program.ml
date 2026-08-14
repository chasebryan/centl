let require_plan label = function
  | Ok plan -> plan
  | Error message -> Alcotest.fail (label ^ ": " ^ message)

let test_named_english_function () =
  let plan =
    Centl_sci_program.prepare
      "make a function called kinetic_energy that takes mass and velocity and \
       computes 1/2 * mass * velocity^2"
    |> require_plan "named english function"
  in
  Alcotest.(check (option string))
    "name" (Some "kinetic_energy") plan.Centl_sci_program.name;
  Alcotest.(check (option string))
    "source" (Some "kinetic_energy(mass, velocity) = 1/2 * mass * velocity^2")
    plan.source

let test_topic_function () =
  let plan =
    Centl_sci_program.prepare
      "make a kinetic energy function that takes mass and velocity and \
       computes 1/2 * mass * velocity^2"
    |> require_plan "topic function"
  in
  Alcotest.(check (option string)) "slug name" (Some "kinetic_energy") plan.name

let test_let_definition () =
  let plan =
    Centl_sci_program.prepare "let square(x) = x^2" |> require_plan "let"
  in
  Alcotest.(check (option string)) "name" (Some "square") plan.name;
  Alcotest.(check (option string)) "try" (Some "square(1)") plan.try_next

let test_define_value () =
  let plan =
    Centl_sci_program.prepare "define tau as 2*pi" |> require_plan "define"
  in
  Alcotest.(check (option string)) "name" (Some "tau") plan.name;
  Alcotest.(check (option string)) "source" (Some "tau = 2*pi") plan.source

let test_recipe_without_body () =
  let plan =
    Centl_sci_program.prepare "make a kinetic energy function"
    |> require_plan "recipe"
  in
  Alcotest.(check (option string))
    "recipe name" (Some "kinetic_energy") plan.name;
  Alcotest.(check bool)
    "has conventional note" true
    (Option.is_some plan.recipe_note)

let test_bare_function_definition () =
  let plan = Centl_sci_program.prepare "cube(x) = x^3" |> require_plan "bare" in
  Alcotest.(check (option string)) "name" (Some "cube") plan.name

let test_polite_english () =
  let plan =
    Centl_sci_program.prepare
      "please make a function called square that takes x and computes x^2"
    |> require_plan "polite"
  in
  Alcotest.(check (option string)) "name" (Some "square") plan.name

let test_teach_with_implementation () =
  let plan =
    Centl_sci_program.prepare
      "teach yourself to compute the harmonic mean of a and b as 2 / ((1/a) + \
       (1/b))"
    |> require_plan "teach with body"
  in
  Alcotest.(check bool)
    "becomes a live program" true
    (plan.kind = Centl_sci_program.Function);
  Alcotest.(check (option string)) "name" (Some "harmonic_mean") plan.name

let test_teach_recipe () =
  let plan =
    Centl_sci_program.prepare "teach yourself harmonic mean"
    |> require_plan "teach recipe"
  in
  Alcotest.(check bool)
    "recipe becomes a program" true
    (plan.kind = Centl_sci_program.Function);
  Alcotest.(check (option string)) "name" (Some "harmonic_mean") plan.name

let test_self_extend () =
  let plan =
    Centl_sci_program.prepare "teach yourself to add a local lab helper"
    |> require_plan "self extend"
  in
  Alcotest.(check bool)
    "self extend kind" true
    (plan.kind = Centl_sci_program.Self_extend)

let test_host_growth_is_flagged () =
  let plan =
    Centl_sci_program.prepare
      "patch your source to add harmonic mean to the built-in interpreter"
    |> require_plan "host"
  in
  Alcotest.(check bool)
    "host request recorded" true
    (Option.is_some plan.host_request);
  Alcotest.(check bool)
    "usable locally now" true
    (plan.kind = Centl_sci_program.Function);
  Alcotest.(check (option string))
    "recipe name" (Some "harmonic_mean") plan.name

let test_math_is_not_a_program () =
  Alcotest.(check bool)
    "ordinary math" false
    (Centl_sci_program.wants_program "What is 0.1 plus 0.2?")

let test_restart_copy_is_honest () =
  let plan =
    Centl_sci_program.prepare "let double(x) = 2*x" |> require_plan "double"
  in
  let rendered = Centl_sci_program.render_success plan "installed" in
  Alcotest.(check bool)
    "no restart for native" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"No restart needed"
          rendered));
  Alcotest.(check bool)
    "not verified core" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"not verified CENTL core"
          rendered))

let test_builtin_is_not_shadowed () =
  let plan =
    Centl_sci_program.prepare "make a circle area function"
    |> require_plan "builtin circle area"
  in
  Alcotest.(check bool)
    "already present" true
    (plan.kind = Centl_sci_program.Already_present);
  Alcotest.(check string) "no write" "" plan.command

let test_host_restart_copy () =
  let _, text = Centl_sci_program.restart_for Centl_sci_program.Host_patch in
  Alcotest.(check bool)
    "restart required" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"Restart required" text))

let () =
  Alcotest.run "CENTL-SCi program workshop"
    [
      ( "english",
        [
          Alcotest.test_case "named function" `Quick test_named_english_function;
          Alcotest.test_case "topic function" `Quick test_topic_function;
          Alcotest.test_case "let definition" `Quick test_let_definition;
          Alcotest.test_case "define value" `Quick test_define_value;
          Alcotest.test_case "recipe without body" `Quick
            test_recipe_without_body;
          Alcotest.test_case "bare function" `Quick
            test_bare_function_definition;
          Alcotest.test_case "polite wrapper" `Quick test_polite_english;
          Alcotest.test_case "teach with implementation" `Quick
            test_teach_with_implementation;
          Alcotest.test_case "teach recipe" `Quick test_teach_recipe;
          Alcotest.test_case "self extend" `Quick test_self_extend;
          Alcotest.test_case "host growth flagged" `Quick
            test_host_growth_is_flagged;
          Alcotest.test_case "math is not a program" `Quick
            test_math_is_not_a_program;
          Alcotest.test_case "restart honesty" `Quick
            test_restart_copy_is_honest;
          Alcotest.test_case "host restart copy" `Quick test_host_restart_copy;
          Alcotest.test_case "builtin not shadowed" `Quick
            test_builtin_is_not_shadowed;
        ] );
    ]
