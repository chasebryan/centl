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
    { mode = Hybrid; prompt = "what is 1/3 + 2/7" };
    { mode = Hybrid; prompt = "calculate (12 + 4) / 8" };
    { mode = Phys; prompt = "convert 25 kilometers to meters" };
    { mode = Phys; prompt = "change 2500 metres into kilometers" };
    { mode = Phys; prompt = "convert 10 meters per second to km" };
    { mode = Math; prompt = "solve x squared plus 4" };
    { mode = Math; prompt = "find x squared plus 4" };
    { mode = Phys; prompt = "convert 25 kilometers" };
    { mode = Build; prompt = "show workspace" };
    { mode = Build; prompt = "create function kinetic_energy(mass, velocity) = 1/2 * mass * velocity^2" };
  ]

let collapse_spaces text =
  text
  |> String.split_on_char ' '
  |> List.filter (fun item -> item <> "")
  |> String.concat " "

let titlecase text =
  if text = "" then text
  else String.make 1 (Char.uppercase_ascii text.[0])
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
    (fun text -> Centl_sci_interaction.replace_all ~needle:"x^2" ~replacement:"x²" text);
    (fun text -> Centl_sci_interaction.replace_all ~needle:"*" ~replacement:"×" text);
    (fun text -> Centl_sci_interaction.replace_all ~needle:"/" ~replacement:"÷" text);
    (fun text -> "   " ^ String.uppercase_ascii text ^ "   ");
  ]

let corpus =
  List.concat_map
    (fun seed -> List.map (fun style -> (seed.mode, style seed.prompt)) styles)
    seeds

let test_corpus_size () =
  Alcotest.(check bool) "Caramels corpus contains at least 250 human variations"
    true (List.length corpus >= 250)

let test_normalization_never_erases_nonempty_input () =
  List.iter
    (fun (mode, prompt) ->
      let normalized = Centl_sci_interaction.normalize mode prompt in
      Alcotest.(check bool) prompt true (String.trim normalized <> ""))
    corpus

let test_known_typos_recover () =
  let normalized =
    Centl_sci_interaction.normalize Math "intergrate x squred where x equls 2"
  in
  Alcotest.(check string) "known safe lexical corrections"
    "integrate x squared where x equals 2" normalized

let () =
  Alcotest.run "CENTL-SCi Caramels human variation"
    [
      ( "corpus",
        [
          Alcotest.test_case "size" `Quick test_corpus_size;
          Alcotest.test_case "normalization preserves input" `Quick
            test_normalization_never_erases_nonempty_input;
          Alcotest.test_case "known typo recovery" `Quick test_known_typos_recover;
        ] );
    ]
