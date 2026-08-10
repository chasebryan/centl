type mode = Math | Phys | Hybrid | Build

let mode_text = function
  | Math -> "math"
  | Phys -> "physics"
  | Hybrid -> "hybrid"
  | Build -> "build"

let prompt = function
  | Math -> "MATH> "
  | Phys -> "PHYS> "
  | Hybrid -> "HYBRID> "
  | Build -> "BUILD> "

let parse_mode value =
  match String.lowercase_ascii (String.trim value) with
  | "math" | "mathematics" -> Ok Math
  | "phys" | "physics" -> Ok Phys
  | "hybrid" | "sci" | "science" -> Ok Hybrid
  | "build" -> Ok Build
  | other -> Error ("unknown CENTL-SCi mode: " ^ other)

let find_substring ~needle text =
  let needle_length = String.length needle in
  let text_length = String.length text in
  let rec loop index =
    if needle_length = 0 then Some index
    else if index + needle_length > text_length then None
    else if String.sub text index needle_length = needle then Some index
    else loop (index + 1)
  in
  loop 0

let replace_all ~needle ~replacement text =
  if needle = "" then text
  else
    let output = Buffer.create (String.length text) in
    let rec loop offset =
      if offset >= String.length text then ()
      else
        let remaining = String.sub text offset (String.length text - offset) in
        match find_substring ~needle remaining with
        | None -> Buffer.add_string output remaining
        | Some relative ->
            let index = offset + relative in
            Buffer.add_substring output text offset (index - offset);
            Buffer.add_string output replacement;
            loop (index + String.length needle)
    in
    loop 0;
    Buffer.contents output

let collapse_spaces text =
  let output = Buffer.create (String.length text) in
  let pending_space = ref false in
  String.iter
    (fun character ->
      match character with
      | ' ' | '\t' | '\r' | '\n' -> pending_space := Buffer.length output > 0
      | _ ->
          if !pending_space then Buffer.add_char output ' ';
          pending_space := false;
          Buffer.add_char output character)
    text;
  Buffer.contents output |> String.trim

let normalize_unicode text =
  text
  |> replace_all ~needle:"×" ~replacement:"*"
  |> replace_all ~needle:"÷" ~replacement:"/"
  |> replace_all ~needle:"−" ~replacement:"-"
  |> replace_all ~needle:"²" ~replacement:"^2"
  |> replace_all ~needle:"³" ~replacement:"^3"
  |> replace_all ~needle:"½" ~replacement:"1/2"
  |> replace_all ~needle:"π" ~replacement:"pi"

let safe_lexical_corrections =
  [
    ("intergrate", "integrate");
    ("intergration", "integration");
    ("differenciate", "differentiate");
    ("derivitive", "derivative");
    ("squred", "squared");
    ("equls", "equals");
    ("kilomters", "kilometers");
    ("metres", "meters");
  ]

let normalize_lexical text =
  List.fold_left
    (fun current (needle, replacement) ->
      replace_all ~needle ~replacement current)
    text safe_lexical_corrections

let drop_prefix_ci prefix text =
  let lower = String.lowercase_ascii text in
  let prefix_lower = String.lowercase_ascii prefix in
  if String.starts_with ~prefix:prefix_lower lower then
    Some
      (String.sub text (String.length prefix)
         (String.length text - String.length prefix)
      |> String.trim)
  else None

let canonicalize_root_request text =
  let prefixes =
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
        begin match drop_prefix_ci prefix text with
        | Some body when body <> "" -> Some body
        | _ -> choose rest
        end
  in
  match choose prefixes with
  | None -> text
  | Some body ->
      let lower_body = String.lowercase_ascii body in
      if
        String.contains body '='
        || find_substring ~needle:" equals " lower_body <> None
      then "solve " ^ body
      else "solve " ^ body ^ " equals zero"

let canonicalize_conversion text =
  match drop_prefix_ci "change " text with
  | None -> text
  | Some body ->
      let lower = String.lowercase_ascii body in
      if
        find_substring ~needle:" into " lower <> None
        || find_substring ~needle:" to " lower <> None
      then
        "convert "
        ^ replace_all ~needle:" into " ~replacement:" to " body
      else text

let canonicalize_common_intent text =
  text |> canonicalize_root_request |> canonicalize_conversion

let normalize mode text =
  let normalized =
    text |> normalize_unicode |> normalize_lexical |> collapse_spaces
  in
  match mode with Build -> normalized | Math | Phys | Hybrid -> canonicalize_common_intent normalized

let session_commands =
  [
    ":help";
    ":history";
    ":clear-history";
    ":mode";
    ":mode math";
    ":mode physics";
    ":mode hybrid";
    ":mode build";
    ":details on";
    ":details off";
    ":explain on";
    ":explain off";
    ":quit";
    ":exit";
  ]

let math_completions =
  [
    "calculate";
    "compute";
    "differentiate";
    "derivative";
    "evaluate";
    "expand";
    "factor";
    "integrate";
    "simplify";
    "solve";
    "verify";
  ]

let physics_completions =
  [
    "calculate";
    "compute";
    "convert";
    "force";
    "mass";
    "position";
    "simulate";
    "velocity";
  ]

let build_completions =
  [
    "function";
    "value";
    "workspace";
    "create";
    "initialize";
    "inspect";
    "modify";
    "show";
    "add";
    "disable";
    "enable";
    "extend";
    "remove";
    "undo";
  ]

let completion_candidates mode =
  let domain =
    match mode with
    | Math -> math_completions
    | Phys -> physics_completions
    | Hybrid -> math_completions @ physics_completions
    | Build -> build_completions
  in
  session_commands @ domain |> List.sort_uniq String.compare

let starts_with_any prefixes text =
  List.exists (fun prefix -> String.starts_with ~prefix text) prefixes

let clarification mode normalized =
  let lower = String.lowercase_ascii normalized in
  if lower = "" then None
  else
    match mode with
    | Build ->
        begin match Centl_sci_build.handle normalized with
        | Centl_sci_build.Handled handled -> Some handled.message
        | Centl_sci_build.Not_handled ->
            Some
              "I understand this as a BUILD request, but this construction class is not implemented yet. Current Linux-first BUILD support can initialize or inspect the local workspace and create/modify parser-valid CENTL values and functions."
        end
    | Math | Hybrid
      when starts_with_any [ "solve "; "find x "; "find the roots "; "roots of " ] lower
           && not (String.contains lower '=')
           && find_substring ~needle:" equals " lower = None ->
        Some
          "I understand this as an equation-solving request, but the equation relation or right-hand side is missing. Try, for example: solve x squared plus 4 equals 0."
    | Math | Hybrid
      when String.starts_with ~prefix:"find " lower ->
        Some
          "I understand the expression, but the requested operation is ambiguous. Specify whether you want to solve, simplify, differentiate, integrate, evaluate, or verify it."
    | Phys | Hybrid
      when String.starts_with ~prefix:"convert " lower
           && find_substring ~needle:" to " lower = None ->
        Some
          "I understand this as a unit-conversion request, but the target unit is missing. For example: convert 25 kilometers to meters."
    | _ -> None
