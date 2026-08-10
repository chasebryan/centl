type seed = {
  mode : Centl_sci_interaction.mode;
  prompt : string;
}

let seeds =
  [
    { mode = Math; prompt = "solve x squared minus 5x plus 6 equals zero" };
    { mode = Math; prompt = "find the roots of x^2 - 5*x + 6" };
    { mode = Math; prompt = "differentiate x^3 with respect to x" };
    { mode = Math; prompt = "derivative of x^4 with respect to x" };
    { mode = Math; prompt = "integrate x^2 with respect to x" };
    { mode = Math; prompt = "integrate x^2 from 0 to 5 with respect to x" };
    { mode = Math; prompt = "simplify 2*x + 3*x" };
    { mode = Math; prompt = "expand (x + 1)^3" };
    { mode = Math; prompt = "factor x^2 - 1" };
    { mode = Math; prompt = "substitute x = 3 into x^2 + 1" };
    { mode = Math; prompt = "approximate pi" };
    { mode = Math; prompt = "approximate sqrt(2) to 30 significant digits" };
    { mode = Math; prompt = "verify 0.1 + 0.2 equals 3/10" };
    { mode = Hybrid; prompt = "what is 1/3 + 2/7" };
    { mode = Hybrid; prompt = "calculate (12 + 4) / 8" };
    { mode = Phys; prompt = "convert 25 kilometers to meters" };
    { mode = Phys; prompt = "change 2500 metres into kilometers" };
    { mode = Phys; prompt = "convert 10 meters per second to km" };
    { mode = Phys; prompt = "what is the speed of light in vacuum" };
    { mode = Phys; prompt = "give me the Boltzmann constant" };
    { mode = Phys; prompt = "constant N_A" };
    { mode = Phys; prompt = "what is the Newtonian gravitational constant G" };
    {
      mode = Phys;
      prompt =
        "simulate a particle with mass 2 kg, position (0,0,10) m, velocity (1,0,0) m/s, gravity (0,0,-10) m/s^2, dt 1/10 s, steps 10";
    };
    { mode = Math; prompt = "solve x squared plus 4" };
    { mode = Math; prompt = "find x squared plus 4" };
    { mode = Phys; prompt = "convert 25 kilometers" };
    { mode = Build; prompt = "show workspace" };
    { mode = Build; prompt = "show capabilities" };
    { mode = Build; prompt = "validate kinetic_energy" };
    {
      mode = Build;
      prompt =
        "create function kinetic_energy(mass, velocity) = 1/2 * mass * velocity^2";
    };
  ]

let collapse_spaces text =
  text |> String.split_on_char ' '
  |> List.filter (fun item -> item <> "")
  |> String.concat " "

let titlecase text =
  if text = "" then text
  else
    String.make 1 (Char.uppercase_ascii text.[0])
    ^ String.sub text 1 (String.length text - 1)

let typo text =
  text
  |> Centl_sci_interaction.replace_all ~needle:"integrate" ~replacement:"intergrate"
  |> Centl_sci_interaction.replace_all ~needle:"squared" ~replacement:"squred"
  |> Centl_sci_interaction.replace_all ~needle:"equals" ~replacement:"equls"
  |> Centl_sci_interaction.replace_all ~needle:"kilometers" ~replacement:"kilomters"

let styles =
  [
    (fun text -> text);
    (fun text -> text ^ ".");
    (fun text -> text ^ "?");
    titlecase;
    String.uppercase_ascii;
    (fun text -> "  " ^ text ^ "  ");
    (fun text -> collapse_spaces ("please " ^ text));
    (fun text -> collapse_spaces ("could you " ^ text));
    (fun text -> collapse_spaces ("can you " ^ text));
    (fun text -> typo text);
    (fun text -> typo text ^ ".");
    (fun text ->
      Centl_sci_interaction.replace_all ~needle:"x^2" ~replacement:"x²" text);
    (fun text ->
      Centl_sci_interaction.replace_all ~needle:"*" ~replacement:"×" text);
    (fun text ->
      Centl_sci_interaction.replace_all ~needle:"/" ~replacement:"÷" text);
    (fun text -> "   " ^ String.uppercase_ascii text ^ "   ");
  ]

let corpus =
  List.concat_map
    (fun seed -> List.map (fun style -> (seed.mode, style seed.prompt)) styles)
    seeds

let test_corpus_size () =
  Alcotest.(check bool) "Caramels corpus contains at least 250 human variations"
    true (List.length corpus >= 250 && List.length corpus <= 500)

let test_normalization_never_erases_nonempty_input () =
  List.iter
    (fun (mode, prompt) ->
      let normalized = Centl_sci_interaction.normalize mode prompt in
      Alcotest.(check bool) prompt true (String.trim normalized <> ""))
    corpus

let test_known_typos_recover () =
  let normalized =
    Centl_sci_interaction.normalize Math "INTERGRATE x SQURED where x EQULS 2"
  in
  Alcotest.(check string) "known safe lexical corrections"
    "integrate x squared where x equals 2" (String.lowercase_ascii normalized)

let useful_interpretation mode prompt =
  let normalized = Centl_sci_interaction.normalize mode prompt in
  match mode with
  | Build ->
      let classification = Centl_sci_intent.classify ~mode normalized in
      classification.intent <> Centl_sci_intent.Unknown
      || Centl_sci_codegen.generate normalized <> Centl_sci_codegen.Not_generated
  | Math | Phys | Hybrid ->
      Option.is_some (Centl_sci_fastpath.interpret normalized)
      || Option.is_some (Centl_sci_interaction.clarification mode normalized)

let test_useful_interpretation_rate () =
  let useful =
    List.fold_left
      (fun count (mode, prompt) ->
        if useful_interpretation mode prompt then count + 1 else count)
      0 corpus
  in
  let total = List.length corpus in
  let rate = (float_of_int useful /. float_of_int total) *. 100.0 in
  if rate < 95.0 then
    Alcotest.failf
      "Caramels human-variation gate: %.2f%% useful interpretations/clarifications (%d/%d), target >= 95%%"
      rate useful total

let () =
  Alcotest.run "CENTL-SCi Caramels human variation"
    [
      ( "corpus",
        [
          Alcotest.test_case "size" `Quick test_corpus_size;
          Alcotest.test_case "normalization preserves input" `Quick
            test_normalization_never_erases_nonempty_input;
          Alcotest.test_case "known typo recovery" `Quick test_known_typos_recover;
          Alcotest.test_case "95 percent useful interpretation" `Quick
            test_useful_interpretation_rate;
        ] );
    ]
