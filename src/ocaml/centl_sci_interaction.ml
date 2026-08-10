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

let replace_all_ci ~needle ~replacement text =
  let lower_text = String.lowercase_ascii text in
  let lower_needle = String.lowercase_ascii needle in
  if lower_needle = "" then text
  else
    let output = Buffer.create (String.length text) in
    let rec loop offset =
      if offset >= String.length text then ()
      else
        let remaining_lower =
          String.sub lower_text offset (String.length lower_text - offset)
        in
        match find_substring ~needle:lower_needle remaining_lower with
        | None -> Buffer.add_substring output text offset (String.length text - offset)
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
    ("whats", "what is");
    ("what's", "what is");
  ]

let normalize_lexical text =
  List.fold_left
    (fun current (needle, replacement) ->
      replace_all_ci ~needle ~replacement current)
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

let strip_polite_prefix text =
  let prefixes =
    [
      "could you please ";
      "would you please ";
      "can you please ";
      "please ";
      "could you ";
      "would you ";
      "can you ";
    ]
  in
  let rec strip current =
    let rec choose = function
      | [] -> current
      | prefix :: rest ->
          begin match drop_prefix_ci prefix current with
          | Some body when body <> "" -> strip body
          | _ -> choose rest
          end
    in
    choose prefixes
  in
  strip text

let strip_polite_suffix text =
  let text = String.trim text in
  let lower = String.lowercase_ascii text in
  let suffixes = [ ", please"; " please" ] in
  let rec choose = function
    | [] -> text
    | suffix :: rest ->
        if String.ends_with ~suffix lower then
          String.sub text 0 (String.length text - String.length suffix)
          |> String.trim
        else choose rest
  in
  choose suffixes

let strip_sentence_terminal text =
  let text = String.trim text in
  let rec finish length =
    if length = 0 then 0
    else
      match text.[length - 1] with
      | '?' | '.' -> finish (length - 1)
      | _ -> length
  in
  let length = finish (String.length text) in
  String.sub text 0 length |> String.trim

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

let canonicalize_how_many_conversion text =
  match drop_prefix_ci "how many " text with
  | None -> text
  | Some body ->
      let lower = String.lowercase_ascii body in
      let split marker =
        match find_substring ~needle:marker lower with
        | None -> None
        | Some index ->
            let target = String.sub body 0 index |> String.trim in
            let source =
              String.sub body (index + String.length marker)
                (String.length body - index - String.length marker)
              |> String.trim |> strip_sentence_terminal
            in
            let source =
              match drop_prefix_ci "exactly " source with
              | Some value when value <> "" -> value
              | _ -> source
            in
            if target = "" || source = "" then None
            else Some ("convert " ^ source ^ " to " ^ target)
      in
      begin match split " are in " with
      | Some value -> value
      | None ->
          begin match split " are " with
          | Some value -> value
          | None -> text
          end
      end

let canonicalize_conversion text =
  match drop_prefix_ci "change " text with
  | Some body ->
      let lower = String.lowercase_ascii body in
      if
        find_substring ~needle:" into " lower <> None
        || find_substring ~needle:" to " lower <> None
      then
        "convert " ^ replace_all_ci ~needle:" into " ~replacement:" to " body
      else text
  | None -> canonicalize_how_many_conversion text

let canonicalize_common_intent text =
  text |> canonicalize_root_request |> canonicalize_conversion

let normalize mode text =
  let normalized =
    text |> normalize_unicode |> normalize_lexical |> collapse_spaces
    |> strip_polite_prefix |> strip_polite_suffix
  in
  match mode with
  | Build -> normalized
  | Math | Phys | Hybrid -> canonicalize_common_intent normalized

let session_commands =
  [
    ":help";
    ":history";
    ":clear-history";
    ":last";
    ":result";
    ":results";
    ":recall";
    ":mode";
    ":mode math";
    ":mode physics";
    ":mode hybrid";
    ":mode build";
    ":details on";
    ":details off";
    ":explain on";
    ":explain off";
    ":changes";
    ":extensions";
    ":inspect";
    ":disable";
    ":enable";
    ":remove";
    ":undo";
    ":quit";
    ":exit";
  ]

let math_completions =
  [
    "approx";
    "approximate";
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
    "substitute";
    "verify";
  ]

let physics_completions =
  [
    "N_A";
    "calculate";
    "compute";
    "constant";
    "convert";
    "dt";
    "force";
    "g0";
    "gravity";
    "k_B";
    "mass";
    "position";
    "simulate";
    "steps";
    "velocity";
  ]

let build_completions =
  [
    "adapter";
    "add";
    "assurance";
    "audit";
    "capabilities";
    "create";
    "disable";
    "enable";
    "export";
    "extend";
    "extensions";
    "function";
    "import";
    "initialize";
    "inspect";
    "modify";
    "package";
    "packages";
    "prepare";
    "remove";
    "revision";
    "revisions";
    "scaffold";
    "show";
    "undo";
    "upstream";
    "validate";
    "value";
    "workspace";
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

let mechanics_missing lower =
  if
    not
      (starts_with_any
         [ "simulate particle"; "simulate a particle"; "simulate the particle" ]
         lower)
  then []
  else
    [ "mass"; "position"; "velocity"; "gravity"; "dt"; "steps" ]
    |> List.filter (fun field ->
           find_substring ~needle:(field ^ " ") lower = None)

let clarification mode normalized =
  let lower = String.lowercase_ascii normalized in
  if lower = "" then None
  else
    let missing_mechanics = mechanics_missing lower in
    match mode with
    | Build ->
        Some
          "BUILD can inspect capabilities and assurance; audit the workspace; read revision history; create, modify, validate, package, enable, disable, remove, and undo downstream extensions; scaffold external/native integrations; export or import a workspace; prepare upstream contribution artifacts; or plan deeper CENTL changes. State the capability or change you want."
    | (Phys | Hybrid) when missing_mechanics <> [] ->
        Some
          ("I understand this as a uniform-gravity particle simulation, but required fields are missing: "
          ^ String.concat ", " missing_mechanics
          ^ ". Supply mass, position, velocity, gravity, dt, and steps. Example: "
          ^ "simulate a particle with mass 2 kg, position (0,0,10) m, velocity (1,0,0) m/s, gravity (0,0,-10) m/s^2, dt 1/10 s, steps 10")
    | (Phys | Hybrid)
      when
        starts_with_any
          [ "simulate particle"; "simulate a particle"; "simulate the particle" ]
          lower ->
        Some
          "I recognize a particle-simulation request, but its typed fields could not be parsed safely. Use explicit vector forms such as position (0,0,10) m and velocity (1,0,0) m/s; CENTL-SCi will not invent missing physical values."
    | Math | Hybrid
      when
        starts_with_any
          [ "solve "; "find x "; "find the roots "; "roots of " ]
          lower
        && not (String.contains lower '=')
        && find_substring ~needle:" equals " lower = None ->
        Some
          "I understand this as an equation-solving request, but the equation relation or right-hand side is missing. Try, for example: solve x squared plus 4 equals 0."
    | Math | Hybrid
      when
        starts_with_any
          [ "differentiate "; "derivative of "; "take the derivative of " ]
          lower
        && find_substring ~needle:" with respect to " lower = None
        && find_substring ~needle:" wrt " lower = None ->
        Some
          "I understand this as differentiation, but the differentiation variable is missing. For example: differentiate x^3 with respect to x."
    | Math | Hybrid
      when starts_with_any [ "integrate "; "integral of " ] lower
           && find_substring ~needle:" with respect to " lower = None ->
        Some
          "I understand this as integration, but the integration variable is missing. For example: integrate x^2 with respect to x."
    | Math | Hybrid when String.starts_with ~prefix:"find " lower ->
        Some
          "I understand the expression, but the requested operation is ambiguous. Specify whether you want to solve, simplify, differentiate, integrate, approximate, evaluate, or verify it."
    | Phys | Hybrid
      when String.starts_with ~prefix:"convert " lower
           && find_substring ~needle:" to " lower = None ->
        Some
          "I understand this as a unit-conversion request, but the target unit is missing. For example: convert 25 kilometers to meters."
    | _ -> None
