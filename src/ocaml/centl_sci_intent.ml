type t =
  | Arithmetic
  | Simplification
  | Equation_solving
  | Differentiation
  | Integration
  | Substitution
  | Approximation
  | Verification
  | Unit_conversion
  | Constant_lookup
  | Geometry
  | Sequence
  | Recurrence
  | Physics_calculation
  | Physics_simulation
  | System_inspection
  | Program_creation
  | System_extension
  | System_modification
  | Unknown

type confidence = High | Medium | Low

type classification = {
  intent : t;
  confidence : confidence;
  evidence : string;
}

let text = function
  | Arithmetic -> "arithmetic"
  | Simplification -> "simplification"
  | Equation_solving -> "equation_solving"
  | Differentiation -> "differentiation"
  | Integration -> "integration"
  | Substitution -> "substitution"
  | Approximation -> "approximation"
  | Verification -> "verification"
  | Unit_conversion -> "unit_conversion"
  | Constant_lookup -> "constant_lookup"
  | Geometry -> "geometry"
  | Sequence -> "sequence"
  | Recurrence -> "recurrence"
  | Physics_calculation -> "physics_calculation"
  | Physics_simulation -> "physics_simulation"
  | System_inspection -> "system_inspection"
  | Program_creation -> "program_creation"
  | System_extension -> "system_extension"
  | System_modification -> "system_modification"
  | Unknown -> "unknown"

let lower text = String.lowercase_ascii (String.trim text)

let contains needle text =
  Option.is_some (Centl_sci_interaction.find_substring ~needle text)

let contains_any needles text = List.exists (fun needle -> contains needle text) needles
let starts prefixes text = List.exists (fun prefix -> String.starts_with ~prefix text) prefixes

let constant_phrase input =
  contains_any
    [
      "speed of light";
      "planck constant";
      "planck's constant";
      "elementary charge";
      "boltzmann constant";
      "avogadro constant";
      "avogadro's constant";
      "standard gravity";
      "standard acceleration of gravity";
    ]
    input
  || starts [ "constant "; "physical constant "; "lookup constant " ] input

let classify ~mode input =
  let input = lower input in
  let result intent confidence evidence = { intent; confidence; evidence } in
  if input = "" then result Unknown Low "empty input"
  else
    match mode with
    | Centl_sci_interaction.Build ->
        if
          starts
            [
              "show ";
              "inspect ";
              "list ";
              "why ";
              "validate ";
              "capabilities";
              "workspace";
              "extensions";
              "packages";
            ]
            input
        then result System_inspection High "BUILD inspection/validation verb"
        else if starts [ "create "; "write "; "make "; "scaffold " ] input then
          result Program_creation High "BUILD creation verb"
        else if starts [ "add "; "extend "; "install "; "integrate "; "prepare " ] input then
          result System_extension High "BUILD extension verb"
        else if
          starts
            [
              "modify ";
              "change ";
              "replace ";
              "remove ";
              "disable ";
              "enable ";
              "undo ";
              "import ";
            ]
            input
        then result System_modification High "BUILD modification verb"
        else result System_extension Medium "BUILD mode default"
    | _ ->
        if
          starts [ "convert "; "change "; "how many " ] input
          && (contains " to " input || contains " into " input || contains " in " input)
        then result Unit_conversion High "conversion phrase with source/target units"
        else if constant_phrase input then
          result Constant_lookup High "known physical-constant lookup phrase"
        else if
          starts
            [
              "solve ";
              "find the roots";
              "roots of ";
              "zeros of ";
              "find zeros";
              "solutions of ";
            ]
            input
        then result Equation_solving High "equation-solving phrase"
        else if
          starts
            [ "differentiate "; "derivative of "; "take the derivative"; "find dy/dx" ]
            input
        then result Differentiation High "differentiation phrase"
        else if starts [ "integrate "; "integral of "; "find the integral" ] input then
          result Integration High "integration phrase"
        else if starts [ "simplify "; "reduce " ] input then
          result Simplification High "simplification phrase"
        else if starts [ "substitute "; "plug "; "replace " ] input && contains " into " input then
          result Substitution High "substitution phrase"
        else if starts [ "approx "; "approximate "; "decimal "; "estimate " ] input then
          result Approximation High "approximation phrase"
        else if starts [ "verify "; "check whether "; "prove whether "; "assert " ] input then
          result Verification High "verification phrase"
        else if starts [ "simulate "; "step "; "evolve " ] input then
          result Physics_simulation Medium "simulation verb"
        else if starts [ "calculate "; "compute "; "evaluate "; "what is " ] input then
          result Arithmetic Medium "calculation phrase"
        else if starts [ "find " ] input then
          result Unknown Medium "ambiguous find request"
        else result Unknown Low "no deterministic intent match"

let strip_prefix prefix text =
  if String.starts_with ~prefix text then
    Some
      (String.sub text (String.length prefix) (String.length text - String.length prefix)
      |> String.trim)
  else None

let canonicalize classification input =
  let trimmed = String.trim input in
  let lowered = lower trimmed in
  match classification.intent with
  | Unit_conversion ->
      let normalized =
        Centl_sci_interaction.replace_all_ci ~needle:" into " ~replacement:" to " trimmed
      in
      begin match strip_prefix "change " (lower normalized) with
      | Some _ -> "convert " ^ String.sub normalized 7 (String.length normalized - 7)
      | None -> normalized
      end
  | Equation_solving ->
      let root_body =
        let candidates =
          [
            "find the roots of ";
            "find roots of ";
            "roots of ";
            "find the zeros of ";
            "find zeros of ";
            "zeros of ";
          ]
        in
        let rec choose = function
          | [] -> None
          | prefix :: rest ->
              begin match strip_prefix prefix lowered with
              | Some _ ->
                  Some
                    (String.sub trimmed (String.length prefix)
                       (String.length trimmed - String.length prefix)
                    |> String.trim)
              | None -> choose rest
              end
        in
        choose candidates
      in
      begin match root_body with
      | Some body
        when not (String.contains body '=')
             && not (contains " equals " (lower body)) ->
          "solve " ^ body ^ " equals zero"
      | Some body -> "solve " ^ body
      | None -> trimmed
      end
  | _ -> trimmed
