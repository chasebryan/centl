type alias = {
  name : string;
  target : string;
  phrases : string list;
  parameters : string list;
}

let directory workspace =
  Filename.concat workspace.Centl_sci_workspace.root "spoken"

let path workspace name = Filename.concat (directory workspace) (name ^ ".json")
let phrase_of_name name = Centl_sci_recipe.phrase_of_name name

let trim_terminal text =
  let text = String.trim text in
  let rec finish length =
    if length = 0 then 0
    else
      match text.[length - 1] with
      | '?' | '.' | '!' -> finish (length - 1)
      | _ -> length
  in
  let length = finish (String.length text) in
  String.sub text 0 length |> String.trim

let token_ok text =
  let text = String.trim text in
  text <> ""
  && String.length text <= 64
  && String.for_all
       (function
         | 'a' .. 'z'
         | 'A' .. 'Z'
         | '0' .. '9'
         | '_' | '.' | '/' | '+' | '-' | '*' | '^' | '(' | ')' ->
             true
         | _ -> false)
       text

let split_arguments text =
  text
  |> Centl_sci_interaction.replace_all ~needle:" and " ~replacement:","
  |> String.split_on_char ',' |> List.map String.trim
  |> List.filter (fun value -> value <> "")

let of_json json =
  let string_field name = function
    | `Assoc fields -> (
        match List.assoc_opt name fields with
        | Some (`String value) -> Some value
        | _ -> None)
    | _ -> None
  in
  let string_list name = function
    | `Assoc fields -> (
        match List.assoc_opt name fields with
        | Some (`List values) ->
            let rec loop acc = function
              | [] -> Some (List.rev acc)
              | `String value :: rest -> loop (value :: acc) rest
              | _ -> None
            in
            loop [] values
        | _ -> None)
    | _ -> None
  in
  match
    ( string_field "name" json,
      string_field "target" json,
      string_list "phrases" json,
      string_list "parameters" json )
  with
  | Some name, Some target, Some phrases, Some parameters
    when Centl_sci_change_ir.valid_identifier name
         && Centl_sci_change_ir.valid_identifier target
         && phrases <> []
         && List.for_all Centl_sci_change_ir.valid_identifier parameters ->
      Some { name; target; phrases; parameters }
  | _ -> None

let to_json alias =
  let strings values = `List (List.map (fun value -> `String value) values) in
  `Assoc
    [
      ("schema_version", `Int 1);
      ("kind", `String "spoken_alias");
      ("name", `String alias.name);
      ("target", `String alias.target);
      ("phrases", strings alias.phrases);
      ("parameters", strings alias.parameters);
      ("assurance", `String "locally_tested_extension");
    ]

let read workspace name =
  let path = path workspace name in
  if not (Sys.file_exists path) then None
  else
    try of_json (Yojson.Safe.from_file path)
    with Sys_error _ | Yojson.Json_error _ -> None

let list workspace =
  let directory = directory workspace in
  if not (Sys.file_exists directory) then []
  else
    Sys.readdir directory |> Array.to_list
    |> List.filter (fun name -> Filename.check_suffix name ".json")
    |> List.filter_map (fun filename ->
        let name = Filename.chop_suffix filename ".json" in
        read workspace name)
    |> List.sort (fun left right -> String.compare left.name right.name)

let write workspace alias =
  try
    Centl_sci_workspace.ensure workspace;
    Centl_sci_workspace.ensure_directory (directory workspace);
    Centl_sci_workspace.atomic_write_json
      (path workspace alias.name)
      (to_json alias);
    Ok alias
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let parameters_of_source source =
  match Centl_parser.parse_statement_located source with
  | Ok located -> (
      match located.statement with
      | Centl_parser.Define_function (_, parameters, _) -> parameters
      | _ -> [])
  | Error _ -> []

let install workspace ~name ?source ?(phrases = []) () =
  if String.length name <= 1 then
    Error "spoken aliases skip single-letter names"
  else if not (Centl_sci_change_ir.valid_identifier name) then
    Error ("invalid spoken alias name: " ^ name)
  else
    let parameters =
      match source with None -> [] | Some value -> parameters_of_source value
    in
    if parameters = [] then Error ("no parameters for spoken alias " ^ name)
    else
      let phrases =
        phrase_of_name name :: phrases
        |> List.map String.trim
        |> List.filter (fun value -> value <> "")
        |> List.sort_uniq String.compare
      in
      write workspace { name; target = name; phrases; parameters }

let strip_ask text =
  let prefixes =
    [
      "what is the value of the ";
      "what is the value of ";
      "what's the value of the ";
      "what's the value of ";
      "what is the ";
      "what is ";
      "what's the ";
      "what's ";
      "calculate the ";
      "calculate ";
      "compute the ";
      "compute ";
      "evaluate the ";
      "evaluate ";
      "find the ";
      "find ";
    ]
  in
  let rec loop current = function
    | [] -> current
    | prefix :: rest -> (
        match Centl_sci_codegen.strip_prefix_ci prefix current with
        | Some body when body <> "" -> body
        | _ -> loop current rest)
  in
  let text = loop (trim_terminal text) prefixes in
  match Centl_sci_codegen.strip_prefix_ci "the " text with
  | Some body when body <> "" -> body
  | _ -> text

let match_alias alias text =
  let text = strip_ask text in
  let phrases =
    List.sort
      (fun left right -> String.length right - String.length left)
      alias.phrases
  in
  let rec loop = function
    | [] -> None
    | phrase :: rest -> (
        match Centl_sci_codegen.split_at_ci (phrase ^ " of ") text with
        | Some (prefix, arguments) when String.trim prefix = "" ->
            let arguments = split_arguments arguments in
            if
              List.length arguments = List.length alias.parameters
              && List.for_all token_ok arguments
            then
              Some
                (Printf.sprintf "%s(%s)" alias.target
                   (String.concat ", " arguments))
            else loop rest
        | Some _ | None -> loop rest)
  in
  loop phrases

let interpret ?workspace problem =
  let workspace =
    match workspace with
    | Some value -> Some value
    | None -> Centl_sci_workspace.default ()
  in
  match workspace with
  | None -> None
  | Some workspace ->
      let rec loop = function
        | [] -> None
        | alias :: rest -> (
            match match_alias alias problem with
            | None -> loop rest
            | Some expression -> Centl_sci_fastpath.native_ir expression)
      in
      loop (list workspace)

let example alias =
  let arguments =
    List.mapi (fun index _ -> string_of_int (index + 2)) alias.parameters
  in
  match alias.phrases with
  | [] -> alias.target ^ "(" ^ String.concat ", " arguments ^ ")"
  | phrase :: _ -> phrase ^ " of " ^ String.concat " and " arguments

let render_list workspace =
  match list workspace with
  | [] ->
      "No spoken aliases yet. Create a local function and I will teach this \
       session the English phrase automatically."
  | aliases ->
      let lines =
        List.map
          (fun alias ->
            Printf.sprintf "  %s\n    English: %s\n    file: %s" alias.name
              (example alias)
              (path workspace alias.name))
          aliases
      in
      String.concat "\n"
        (("Spoken English aliases in this session:" :: lines)
        @ [
            "";
            "These files are yours. Edit a JSON alias or the matching `.centl` \
             source.";
          ])
