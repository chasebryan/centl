type category = Lexical | Structural

type t = {
  category : category;
  replacement_start : int;
  replacement_end : int;
  replacement_text : string;
  display_text : string;
  confidence : float;
  safe_to_accept : bool;
  explanation : string;
  alternatives : string list;
  missing_slots : string list;
  source : string;
}

let identifier_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | ':' -> true
  | _ -> false

let token_start input cursor =
  let rec loop index =
    if index > 0 && identifier_char input.[index - 1] then loop (index - 1)
    else index
  in
  loop cursor

let lexical ~mode input cursor =
  let start = token_start input cursor in
  let prefix = String.sub input start (cursor - start) in
  if prefix = "" then None
  else
    let matches =
      Centl_sci_interaction.completion_candidates mode
      |> List.filter (String.starts_with ~prefix)
      |> List.sort_uniq String.compare
    in
    match matches with
    | [ candidate ] when String.length candidate > String.length prefix ->
        let suffix =
          String.sub candidate (String.length prefix)
            (String.length candidate - String.length prefix)
        in
        Some
          {
            category = Lexical;
            replacement_start = start;
            replacement_end = cursor;
            replacement_text = candidate;
            display_text = suffix;
            confidence = 1.0;
            safe_to_accept = true;
            explanation = "known deterministic completion";
            alternatives = [];
            missing_slots = [];
            source = "completion-catalog";
          }
    | _ -> None

let contains needle text =
  Option.is_some (Centl_sci_interaction.find_substring ~needle text)

let structural ~mode input cursor =
  if cursor <> String.length input then None
  else
    let normalized = Centl_sci_interaction.normalize mode input in
    let lower = String.lowercase_ascii normalized in
    let classification = Centl_sci_intent.classify ~mode normalized in
    let mechanics_missing = Centl_sci_interaction.mechanics_missing lower in
    let make display slots explanation =
      Some
        {
          category = Structural;
          replacement_start = cursor;
          replacement_end = cursor;
          replacement_text = "";
          display_text = display;
          confidence = 0.75;
          safe_to_accept = false;
          explanation;
          alternatives = [];
          missing_slots = slots;
          source = "deterministic-grammar";
        }
    in
    match classification.intent with
    | Centl_sci_intent.Equation_solving
      when not (String.contains lower '=') && not (contains " equals " lower) ->
        make " equals [right side] for [variable]" [ "right side"; "variable" ]
          "equation-solving grammar is incomplete"
    | Centl_sci_intent.Differentiation
      when not (contains " with respect to " lower) && not (contains " wrt " lower) ->
        make " with respect to [variable]" [ "variable" ]
          "differentiation grammar is missing a differentiation variable"
    | Centl_sci_intent.Integration
      when not (contains " from " lower)
           && not (contains " with respect to " lower) ->
        make " with respect to [variable]" [ "variable" ]
          "integration grammar is missing an integration variable or bounds"
    | Centl_sci_intent.Unit_conversion
      when not (contains " to " lower) && not (contains " into " lower) ->
        make " to [unit]" [ "target unit" ]
          "unit conversion is missing a target unit"
    | Centl_sci_intent.Physics_simulation when mechanics_missing <> [] ->
        make
          (" [missing: " ^ String.concat ", " mechanics_missing ^ "]")
          mechanics_missing
          "particle-simulation grammar is missing required typed fields"
    | Centl_sci_intent.Program_creation
      when mode = Centl_sci_interaction.Build && not (String.contains lower '=') ->
        make " = [expression]" [ "implementation expression" ]
          "BUILD creation request is missing an implementation body"
    | _ -> None

let suggest ~mode input cursor =
  match lexical ~mode input cursor with
  | Some value -> Some value
  | None -> structural ~mode input cursor

let ghost ~mode input cursor =
  match suggest ~mode input cursor with
  | None -> None
  | Some suggestion ->
      Some (suggestion.display_text, suggestion.safe_to_accept)
