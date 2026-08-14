type restart = Hot_loaded | Restart_required | Inspect_only
type kind = Function | Value | Self_extend | Host_patch | Already_present

type plan = {
  kind : kind;
  command : string;
  name : string option;
  source : string option;
  try_next : string option;
  recipe_note : string option;
  spoken_phrases : string list;
  host_request : string option;
}

let lower text = String.lowercase_ascii (String.trim text)

let contains needle text =
  Option.is_some
    (Centl_sci_interaction.find_substring ~needle (String.lowercase_ascii text))

let starts prefixes text =
  let text = lower text in
  List.exists (fun prefix -> String.starts_with ~prefix text) prefixes

let normalize text =
  Centl_sci_interaction.normalize Centl_sci_interaction.Hybrid text

let slugify text =
  let buffer = Buffer.create (String.length text) in
  String.iter
    (function
      | ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9') as character ->
          Buffer.add_char buffer (Char.lowercase_ascii character)
      | ' ' | '-' | '/' ->
          if Buffer.length buffer > 0 then Buffer.add_char buffer '_'
      | _ -> ())
    text;
  let name = Buffer.contents buffer in
  let name =
    if name <> "" && name.[0] >= '0' && name.[0] <= '9' then "f_" ^ name
    else name
  in
  if Centl_sci_change_ir.valid_identifier name then Some name else None

let self_extend_request text =
  let text = lower text in
  if
    starts
      [
        "teach yourself ";
        "program yourself ";
        "extend yourself ";
        "make yourself ";
        "teach centl ";
        "teach centl-sci ";
        "grow yourself ";
      ]
      text
  then
    let stripped =
      List.fold_left
        (fun acc prefix ->
          match acc with
          | Some _ as value -> value
          | None -> Centl_sci_codegen.strip_prefix_ci prefix text)
        None
        [
          "teach yourself to ";
          "teach yourself ";
          "program yourself to ";
          "program yourself ";
          "extend yourself to ";
          "extend yourself ";
          "make yourself able to ";
          "make yourself ";
          "teach centl to ";
          "teach centl-sci to ";
          "teach centl ";
          "teach centl-sci ";
          "grow yourself to ";
          "grow yourself ";
        ]
    in
    match stripped with
    | Some value when String.trim value <> "" -> Some (String.trim value)
    | _ -> None
  else None

let empty_plan kind command =
  {
    kind;
    command;
    name = None;
    source = None;
    try_next = None;
    recipe_note = None;
    spoken_phrases = [];
    host_request = None;
  }

let with_host host plan = { plan with host_request = host }

let satisfy_existing plan =
  match plan.name with
  | Some name
    when List.mem name Centl_engine.reserved_names
         && (plan.kind = Function || plan.kind = Value) ->
      { plan with kind = Already_present; command = "" }
  | _ -> plan

let try_next_of_source source =
  match Centl_parser.parse_statement_located source with
  | Ok located -> (
      match located.statement with
      | Centl_parser.Define_function (name, parameters, _) ->
          Some
            (Printf.sprintf "%s(%s)" name
               (String.concat ", "
                  (List.mapi
                     (fun index _ -> string_of_int (index + 1))
                     parameters)))
      | Centl_parser.Define_value (name, _) -> Some name
      | _ -> None)
  | Error _ -> None

let name_of_source source =
  match Centl_parser.parse_statement_located source with
  | Ok located -> (
      match located.statement with
      | Centl_parser.Define_function (name, _, _)
      | Centl_parser.Define_value (name, _) ->
          Some name
      | _ -> None)
  | Error _ -> None

let function_plan ~replace ~name ~parameters ~implementation ?note
    ?(phrases = []) () =
  let source =
    Printf.sprintf "%s(%s) = %s" name
      (String.concat ", " parameters)
      implementation
  in
  match Centl_parser.parse_statement_located source with
  | Error _ -> None
  | Ok located -> (
      match located.statement with
      | Centl_parser.Define_function _ ->
          Some
            {
              kind = Function;
              command =
                (if replace then "modify function " else "create function ")
                ^ source;
              name = Some name;
              source = Some source;
              try_next = try_next_of_source source;
              recipe_note = note;
              spoken_phrases = phrases;
              host_request = None;
            }
      | _ -> None)

let plan_of_recipe ?replace recipe =
  function_plan
    ~replace:(Option.value replace ~default:false)
    ~name:recipe.Centl_sci_recipe.name ~parameters:recipe.parameters
    ~implementation:recipe.implementation ~note:recipe.note
    ~phrases:recipe.phrases ()

let plan_of_generated = function
  | Centl_sci_codegen.Generated (Centl_sci_codegen.Function { source; replace })
    ->
      let verb = if replace then "modify function " else "create function " in
      Some
        {
          kind = Function;
          command = verb ^ source;
          name = name_of_source source;
          source = Some source;
          try_next = try_next_of_source source;
          recipe_note = None;
          spoken_phrases = [];
          host_request = None;
        }
  | Centl_sci_codegen.Generated (Centl_sci_codegen.Value { source; replace }) ->
      let verb = if replace then "modify value " else "create value " in
      Some
        {
          kind = Value;
          command = verb ^ source;
          name = name_of_source source;
          source = Some source;
          try_next = try_next_of_source source;
          recipe_note = None;
          spoken_phrases = [];
          host_request = None;
        }
  | Centl_sci_codegen.Needs_clarification _ | Centl_sci_codegen.Not_generated ->
      None

let parse_let_definition text =
  match Centl_sci_codegen.strip_prefix_ci "let " (String.trim text) with
  | None -> None
  | Some body -> (
      match Centl_parser.parse_statement_located body with
      | Ok located -> (
          match located.statement with
          | Centl_parser.Define_function (name, parameters, _) ->
              Some
                {
                  kind = Function;
                  command = "create function " ^ body;
                  name = Some name;
                  source = Some body;
                  try_next =
                    Some
                      (Printf.sprintf "%s(%s)" name
                         (String.concat ", "
                            (List.mapi
                               (fun index _ -> string_of_int (index + 1))
                               parameters)));
                  recipe_note = None;
                  spoken_phrases = [];
                  host_request = None;
                }
          | Centl_parser.Define_value (name, _) ->
              Some
                {
                  kind = Value;
                  command = "create value " ^ body;
                  name = Some name;
                  source = Some body;
                  try_next = Some name;
                  recipe_note = None;
                  spoken_phrases = [];
                  host_request = None;
                }
          | _ -> None)
      | Error _ -> None)

let parse_prefixed_definition text =
  let prefixes = [ "make "; "write me "; "write "; "create "; "define " ] in
  let rec loop = function
    | [] -> None
    | prefix :: rest -> (
        match Centl_sci_codegen.strip_prefix_ci prefix text with
        | None -> loop rest
        | Some body -> (
            match Centl_parser.parse_statement_located body with
            | Ok located -> (
                match located.statement with
                | Centl_parser.Define_function (name, parameters, _) ->
                    Some
                      {
                        kind = Function;
                        command = "create function " ^ body;
                        name = Some name;
                        source = Some body;
                        try_next =
                          Some
                            (Printf.sprintf "%s(%s)" name
                               (String.concat ", "
                                  (List.mapi
                                     (fun index _ -> string_of_int (index + 1))
                                     parameters)));
                        recipe_note = None;
                        spoken_phrases = [];
                        host_request = None;
                      }
                | Centl_parser.Define_value (name, _) ->
                    Some
                      {
                        kind = Value;
                        command = "create value " ^ body;
                        name = Some name;
                        source = Some body;
                        try_next = Some name;
                        recipe_note = None;
                        spoken_phrases = [];
                        host_request = None;
                      }
                | _ -> loop rest)
            | Error _ -> loop rest))
  in
  loop prefixes

let parse_named_topic_function text =
  let openers =
    [
      "make a ";
      "create a ";
      "write a ";
      "write me a ";
      "add a ";
      "i need a ";
      "i want a ";
    ]
  in
  let rec loop = function
    | [] -> None
    | opener :: rest -> (
        match Centl_sci_codegen.strip_prefix_ci opener text with
        | None -> loop rest
        | Some tail -> (
            match
              Centl_sci_codegen.split_at_ci " function that takes " tail
            with
            | None -> loop rest
            | Some (topic, after) -> (
                match slugify topic with
                | None -> loop rest
                | Some name ->
                    let reconstructed =
                      "create a function named " ^ name ^ " that takes " ^ after
                    in
                    Some reconstructed)))
  in
  loop openers

let parse_define_value text =
  match Centl_sci_codegen.strip_prefix_ci "define " (String.trim text) with
  | None -> None
  | Some body -> (
      let assignment =
        match Centl_sci_codegen.split_at_ci " as " body with
        | Some value -> Some value
        | None -> (
            match Centl_sci_codegen.split_at_ci " equal to " body with
            | Some value -> Some value
            | None -> Centl_sci_codegen.split_at_ci " = " body)
      in
      match assignment with
      | Some (name, expression)
        when Centl_sci_change_ir.valid_identifier (String.trim name)
             && String.trim expression <> ""
             && not (String.contains name '(') ->
          Some
            {
              kind = Value;
              command =
                "create a value named " ^ String.trim name ^ " equal to "
                ^ String.trim expression;
              name = Some (String.trim name);
              source = Some (String.trim name ^ " = " ^ String.trim expression);
              try_next = Some (String.trim name);
              recipe_note = None;
              spoken_phrases = [];
              host_request = None;
            }
      | _ -> None)

let parse_bare_function text =
  let text = String.trim text in
  if not (contains ") =" text || contains ")=" text) then None
  else
    match Centl_parser.parse_statement_located text with
    | Ok located -> (
        match located.statement with
        | Centl_parser.Define_function (name, parameters, _) ->
            Some
              {
                kind = Function;
                command = "create function " ^ text;
                name = Some name;
                source = Some text;
                try_next =
                  Some
                    (Printf.sprintf "%s(%s)" name
                       (String.concat ", "
                          (List.mapi
                             (fun index _ -> string_of_int (index + 1))
                             parameters)));
                recipe_note = None;
                spoken_phrases = [];
                host_request = None;
              }
        | _ -> None)
    | Error _ -> None

let split_implementation text =
  match Centl_sci_codegen.split_at_ci " as " text with
  | Some value -> Some value
  | None -> (
      match Centl_sci_codegen.split_at_ci " that is " text with
      | Some value -> Some value
      | None -> (
          match Centl_sci_codegen.split_at_ci " that computes " text with
          | Some value -> Some value
          | None -> (
              match Centl_sci_codegen.split_at_ci " that returns " text with
              | Some value -> Some value
              | None -> Centl_sci_codegen.split_at_ci " = " text)))

let parse_named_implementation text =
  let text =
    match Centl_sci_codegen.strip_prefix_ci "compute " text with
    | Some value -> value
    | None -> (
        match Centl_sci_codegen.strip_prefix_ci "calculate " text with
        | Some value -> value
        | None -> text)
  in
  let text =
    match Centl_sci_codegen.strip_prefix_ci "the " text with
    | Some value -> value
    | None -> text
  in
  match split_implementation text with
  | None -> None
  | Some (left, expression) when String.trim expression <> "" -> (
      match Centl_sci_codegen.split_at_ci " of " left with
      | Some (phrase, parameters_text) -> (
          match slugify phrase with
          | None -> None
          | Some name ->
              let parameters =
                Centl_sci_codegen.split_parameters parameters_text
              in
              if
                parameters = []
                || List.exists
                     (fun value ->
                       not (Centl_sci_change_ir.valid_identifier value))
                     parameters
              then None
              else
                function_plan ~replace:false ~name ~parameters
                  ~implementation:(String.trim expression) ~phrases:[ phrase ]
                  ())
      | None -> (
          match Centl_sci_recipe.lookup left with
          | Some recipe ->
              function_plan ~replace:false ~name:recipe.name
                ~parameters:recipe.parameters
                ~implementation:(String.trim expression) ~note:recipe.note
                ~phrases:recipe.phrases ()
          | None -> None))
  | _ -> None

let parse_recipe_request text =
  match Centl_sci_recipe.lookup_request text with
  | None -> None
  | Some recipe ->
      let lower = lower text in
      if
        contains "function" lower || contains "program" lower
        || self_extend_request text <> None
        || starts
             [
               "make ";
               "create ";
               "write ";
               "add ";
               "i need ";
               "i want ";
               "teach ";
             ]
             lower
      then plan_of_recipe recipe
      else None

let first_some choices =
  let rec loop = function
    | [] -> None
    | None :: rest -> loop rest
    | Some value :: _ -> Some value
  in
  loop choices

let parse_program_body text =
  first_some
    [
      plan_of_generated (Centl_sci_codegen.generate text);
      parse_let_definition text;
      parse_prefixed_definition text;
      parse_define_value text;
      (match parse_named_topic_function text with
      | None -> None
      | Some reconstructed ->
          plan_of_generated (Centl_sci_codegen.generate reconstructed));
      parse_bare_function text;
      parse_named_implementation text;
      parse_recipe_request text;
    ]

let parse_teach_program text =
  match self_extend_request text with
  | None -> None
  | Some rest -> (
      match parse_program_body rest with
      | Some _ as value -> value
      | None -> (
          match Centl_sci_recipe.lookup_request rest with
          | Some recipe -> plan_of_recipe recipe
          | None -> parse_program_body text))

let mentioned_recipe text =
  let normalized = Centl_sci_recipe.normalize text in
  List.find_opt
    (fun recipe ->
      let needles =
        recipe.Centl_sci_recipe.name :: recipe.phrases
        |> List.map Centl_sci_recipe.normalize
        |> List.filter (fun needle ->
            String.length needle >= 10
            || String.contains recipe.Centl_sci_recipe.name '_')
      in
      List.exists
        (fun needle ->
          needle <> ""
          && Option.is_some
               (Centl_sci_interaction.find_substring ~needle normalized))
        needles)
    Centl_sci_recipe.all

let clarification_for text =
  match Centl_sci_codegen.generate text with
  | Centl_sci_codegen.Needs_clarification message -> Some message
  | _ -> None

let help_message =
  "I can create a local CENTL program from English.\n\
   Examples:\n\
  \  make a function called square that takes x and computes x^2\n\
  \  let harmonic_mean(a, b) = 2 / ((1/a) + (1/b))\n\
  \  make a kinetic energy function\n\
   Local programs hot-load into this session. No restart.\n\
   If you want the compiled host to change, say `patch your source to ...` — I \
   will write a reviewable proposal and tell you to rebuild and restart."

let wants_program text =
  let text = normalize text in
  self_extend_request text <> None
  || Centl_sci_host.wants text
  || parse_bare_function text <> None
  || parse_recipe_request text <> None
  || starts
       [
         "create a function";
         "make a function";
         "write a function";
         "write me a function";
         "define a function";
         "add a function";
         "i need a function";
         "i want a function";
         "create function ";
         "make function ";
         "define function ";
         "create a value";
         "make a value";
         "define a value";
         "define ";
         "let ";
       ]
       text
  || contains "function" text
     && (contains "that takes" text || contains "computes" text
       || contains "called" text || contains "named" text)
  ||
  let compact = String.lowercase_ascii text in
  Option.is_some (Centl_sci_interaction.find_substring ~needle:") =" compact)
  && starts [ "make "; "write "; "create "; "define "; "let " ] compact

let prepare text =
  let text = normalize text in
  let host = if Centl_sci_host.wants text then Some text else None in
  let finish = function
    | Some plan -> Ok (with_host host (satisfy_existing plan))
    | None -> (
        match (self_extend_request text, host) with
        | Some request, _ ->
            Ok
              (with_host host
                 {
                   (empty_plan Self_extend ("extend " ^ request)) with
                   try_next = Some "centl-mirage status";
                 })
        | None, Some _ -> (
            match mentioned_recipe text with
            | Some recipe -> (
                match plan_of_recipe recipe with
                | Some plan -> Ok (with_host host (satisfy_existing plan))
                | None ->
                    Ok { (empty_plan Host_patch "") with host_request = host })
            | None -> Ok { (empty_plan Host_patch "") with host_request = host }
            )
        | None, None -> (
            match clarification_for text with
            | Some message -> Error message
            | None -> Error help_message))
  in
  match parse_teach_program text with
  | Some _ as value -> finish value
  | None -> finish (parse_program_body text)

let restart_for = function
  | Function | Value ->
      (Hot_loaded, "No restart needed. It is loaded into this live session now.")
  | Self_extend ->
      ( Inspect_only,
        "No restart needed to inspect the MIRAGE cycle. Restart would only be \
         required later if you activate a non-native scaffold." )
  | Host_patch ->
      ( Restart_required,
        "Restart required after rebuild. I cannot hot-load OCaml host or \
         verified-core changes into this running process." )
  | Already_present ->
      ( Hot_loaded,
        "No restart needed. CENTL already computes this in the live session." )

let render_success ?spoken_line ?host_line ?try_result plan detail =
  let _restart, restart_text = restart_for plan.kind in
  let heading =
    match (plan.kind, plan.name) with
    | Function, Some name -> "I created local program `" ^ name ^ "`."
    | Value, Some name -> "I created local value `" ^ name ^ "`."
    | Self_extend, _ -> "I started a local self-development cycle."
    | Host_patch, _ -> "I wrote a host-growth proposal."
    | Already_present, Some name ->
        "CENTL already has `" ^ name
        ^ "`. I did not create a shadowing program."
    | Already_present, None ->
        "CENTL already has this operation. I did not create a shadowing \
         program."
    | Function, None -> "I created a local program."
    | Value, None -> "I created a local value."
  in
  let recipe_lines =
    match plan.recipe_note with
    | None -> []
    | Some note -> [ ""; "Definition used: " ^ note ]
  in
  let source_lines =
    match plan.source with
    | None -> []
    | Some source -> [ ""; "Source:"; "  " ^ source ]
  in
  let try_lines =
    match plan.try_next with
    | None -> []
    | Some value ->
        let shown =
          match try_result with
          | Some result -> value ^ "  →  " ^ result
          | None -> value
        in
        [ ""; "Try it now:"; "  " ^ shown ]
  in
  let spoken_lines =
    match spoken_line with None -> [] | Some value -> [ ""; value ]
  in
  let host_lines =
    match host_line with
    | None -> []
    | Some value ->
        [
          "";
          value;
          "The local program above, if any, already works without a restart.";
        ]
  in
  let restart_lines =
    match (plan.kind, host_line) with
    | Host_patch, Some _ ->
        [ ""; "Restart required after `dune build` for host changes only." ]
    | _, Some _ ->
        [
          "";
          restart_text;
          "Host-growth still requires `dune build` and a restart of \
           `centl-sci`.";
        ]
    | _ -> [ ""; restart_text ]
  in
  let hack =
    match plan.kind with
    | Host_patch ->
        [
          "";
          "The running process was not rewritten.";
          "This proposal is not verified CENTL core.";
        ]
    | Already_present ->
        [
          "";
          "I can still teach this session a spoken English alias.";
          "Built-in operations are not local extensions.";
        ]
    | _ ->
        [
          "";
          "This is yours to edit, disable, or undo.";
          "It is a local extension, not verified CENTL core.";
        ]
  in
  String.concat "\n"
    ([ heading ] @ recipe_lines @ source_lines @ [ ""; detail ] @ try_lines
   @ spoken_lines @ host_lines @ restart_lines @ hack)

let install_accessories workspace plan =
  let spoken =
    match (plan.kind, plan.name, plan.source) with
    | (Function | Already_present), Some name, Some source -> (
        match
          Centl_sci_spoken.install workspace ~name ~source
            ~phrases:plan.spoken_phrases ()
        with
        | Error _ -> None
        | Ok alias -> Some alias)
    | _ -> None
  in
  let host =
    match plan.host_request with
    | None -> None
    | Some request -> (
        match
          Centl_sci_host.propose workspace ~name:plan.name ~request
            ~source:plan.source
        with
        | Error _ -> None
        | Ok proposal -> Some proposal)
  in
  (spoken, host)

let spoken_line alias =
  "Spoken English now:\n  " ^ Centl_sci_spoken.example alias

let list_programs workspace =
  let programs =
    Centl_sci_extensions.list workspace
    |> List.filter (fun item ->
        item.Centl_sci_extensions.enabled && item.kind = "native_centl")
  in
  let spoken = Centl_sci_spoken.render_list workspace in
  match programs with
  | [] ->
      "No local programs are enabled yet. Say `make a function called square \
       that takes x and computes x^2`.\n\n" ^ spoken
  | values ->
      let lines =
        List.map
          (fun item ->
            Printf.sprintf "  %s  (%s)\n    %s\n    edit: modify function %s"
              item.Centl_sci_extensions.name item.assurance item.source
              item.name)
          values
      in
      String.concat "\n"
        (("Local programs in this session:" :: lines)
        @ [
            "";
            "Disable with `disable NAME`. Undo the last change with `undo`.";
            "";
            spoken;
          ])
