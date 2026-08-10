type cell_kind =
  | Directive
  | Invariant
  | Acceptance
  | Example
  | Non_goal
  | Question
  | Context

type cell = {
  id : int;
  kind : cell_kind;
  text : string;
  start_line : int;
  end_line : int;
}

type plan_entry = {
  cell_id : int;
  requirement_kind : cell_kind;
  objective : string;
  implementation_layer : Centl_sci_build_plan.layer;
  reusable_capabilities : string list;
  proposed_steps : string list;
  trust_notes : string list;
  unresolved : string list;
}

type ingest_result = {
  source_digest : string;
  stored_path : string;
  spec_path : string;
  plan_path : string;
  active_path : string;
  revision : int;
  cell_count : int;
  objective_count : int;
}

let schema_version = 1
let max_document_bytes = 4 * 1024 * 1024

let kind_text = function
  | Directive -> "DIRECTIVE"
  | Invariant -> "INVARIANT"
  | Acceptance -> "ACCEPTANCE"
  | Example -> "EXAMPLE"
  | Non_goal -> "NON_GOAL"
  | Question -> "QUESTION"
  | Context -> "CONTEXT"

let lower text = String.lowercase_ascii (String.trim text)

let contains needle text =
  Option.is_some (Centl_sci_interaction.find_substring ~needle text)

let starts_with_any prefixes text =
  List.exists (fun prefix -> String.starts_with ~prefix text) prefixes

let last_char_is value text =
  let text = String.trim text in
  String.length text > 0 && text.[String.length text - 1] = value

let rec strip_markup text =
  let text = String.trim text in
  if String.length text >= 2 then
    match text.[0] with
    | '#' | '-' | '*' | '>' when text.[1] = ' ' ->
        strip_markup (String.sub text 2 (String.length text - 2))
    | _ -> text
  else text

let classify text =
  let text = strip_markup text in
  let value = lower text in
  if
    starts_with_any
      [ "non-goal"; "non goal"; "out of scope"; "do not "; "don't " ]
      value
  then Non_goal
  else if
    starts_with_any [ "acceptance"; "expected:"; "test:"; "tests:" ] value
    || contains " should return " (" " ^ value ^ " ")
  then Acceptance
  else if starts_with_any [ "example"; "for example"; "e.g." ] value then
    Example
  else if
    starts_with_any [ "must "; "shall "; "never " ] value
    || contains " must " (" " ^ value ^ " ")
    || contains " shall " (" " ^ value ^ " ")
    || contains " must not " (" " ^ value ^ " ")
  then Invariant
  else if last_char_is '?' text then Question
  else if
    starts_with_any
      [
        "add ";
        "allow ";
        "build ";
        "centl should ";
        "change ";
        "create ";
        "enable ";
        "extend ";
        "implement ";
        "improve ";
        "i want ";
        "make ";
        "support ";
        "the user should ";
        "user should ";
        "we need ";
      ]
      value
    || contains " should " (" " ^ value ^ " ")
  then Directive
  else Context

let is_list_item text =
  let text = String.trim text in
  let length = String.length text in
  (length >= 2
  && (text.[0] = '-' || text.[0] = '*' || text.[0] = '>')
  && text.[1] = ' ')
  ||
  let rec digits index =
    if index >= length then false
    else
      match text.[index] with
      | '0' .. '9' -> digits (index + 1)
      | '.' -> index > 0 && index + 1 < length && text.[index + 1] = ' '
      | _ -> false
  in
  digits 0

let paragraphs content =
  let lines = String.split_on_char '\n' content in
  let flush current_start current_lines end_line acc =
    match current_lines with
    | [] -> acc
    | values ->
        let text = String.concat "\n" (List.rev values) |> String.trim in
        if text = "" then acc else (current_start, end_line, text) :: acc
  in
  let rec loop line_no current_start current_lines acc = function
    | [] ->
        flush current_start current_lines (max current_start (line_no - 1)) acc
        |> List.rev
    | line :: rest ->
        let trimmed = String.trim line in
        if trimmed = "" then
          let acc = flush current_start current_lines (line_no - 1) acc in
          loop (line_no + 1) (line_no + 1) [] acc rest
        else if is_list_item trimmed then
          let acc = flush current_start current_lines (line_no - 1) acc in
          loop (line_no + 1) (line_no + 1) []
            ((line_no, line_no, trimmed) :: acc) rest
        else
          let start_line = if current_lines = [] then line_no else current_start in
          loop (line_no + 1) start_line (line :: current_lines) acc rest
  in
  loop 1 1 [] [] lines

let cells_of_text content =
  paragraphs content
  |> List.mapi (fun index (start_line, end_line, text) ->
         {
           id = index + 1;
           kind = classify text;
           text = String.trim text;
           start_line;
           end_line;
         })

let json_strings values = `List (List.map (fun value -> `String value) values)

let cell_to_json cell =
  `Assoc
    [
      ("id", `Int cell.id);
      ("kind", `String (kind_text cell.kind));
      ("start_line", `Int cell.start_line);
      ("end_line", `Int cell.end_line);
      ("text", `String cell.text);
    ]

let plan_entry cell =
  match cell.kind with
  | Directive | Invariant ->
      let plan = Centl_sci_build_plan.plan cell.text in
      Some
        {
          cell_id = cell.id;
          requirement_kind = cell.kind;
          objective = cell.text;
          implementation_layer = plan.layer;
          reusable_capabilities = plan.reusable_capabilities;
          proposed_steps = plan.proposed_steps;
          trust_notes = plan.trust_notes;
          unresolved = plan.unresolved;
        }
  | Acceptance | Example | Non_goal | Question | Context -> None

let plan_entry_to_json entry =
  `Assoc
    [
      ("cell_id", `Int entry.cell_id);
      ("requirement_kind", `String (kind_text entry.requirement_kind));
      ("objective", `String entry.objective);
      ( "implementation_layer",
        `String (Centl_sci_build_plan.layer_text entry.implementation_layer) );
      ("reusable_capabilities", json_strings entry.reusable_capabilities);
      ("proposed_steps", json_strings entry.proposed_steps);
      ("trust_notes", json_strings entry.trust_notes);
      ("unresolved", json_strings entry.unresolved);
    ]

let count_kind kind cells =
  List.fold_left (fun total cell -> if cell.kind = kind then total + 1 else total) 0 cells

let read_file path =
  try
    if not (Sys.file_exists path) then Error ("document does not exist: " ^ path)
    else if Sys.is_directory path then Error ("document path is a directory: " ^ path)
    else
      let channel = open_in_bin path in
      Fun.protect
        ~finally:(fun () -> close_in_noerr channel)
        (fun () ->
          let length = in_channel_length channel in
          if length > max_document_bytes then
            Error
              (Printf.sprintf "document is %d bytes; MIRAGE currently admits at most %d bytes"
                 length max_document_bytes)
          else Ok (really_input_string channel length))
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let write_text path content =
  let temporary = path ^ ".tmp" in
  let channel =
    open_out_gen [ Open_wronly; Open_creat; Open_trunc; Open_text ] 0o600 temporary
  in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () ->
      output_string channel content;
      flush channel);
  Unix.rename temporary path

let unquote path =
  let path = String.trim path in
  let length = String.length path in
  if length >= 2 then
    let first = path.[0] and last = path.[length - 1] in
    if (first = '"' && last = '"') || (first = '\'' && last = '\'') then
      String.sub path 1 (length - 2)
    else path
  else path

let mirage_dir workspace = Filename.concat workspace.Centl_sci_workspace.generated "mirage"
let library_dir workspace = Filename.concat workspace.Centl_sci_workspace.root "library"
let active_path workspace = Filename.concat (mirage_dir workspace) "active.json"

let render_list title values =
  match values with
  | [] -> [ title ^ ": none" ]
  | values -> title ^ ":" :: List.map (fun value -> "  - " ^ value) values

let render_plan ~source_path ~source_digest cells entries =
  let header =
    [
      "# CENTL-MIRAGE development cycle";
      "";
      "Source: `" ^ source_path ^ "`  ";
      "Content ID (SHA-256): `" ^ source_digest ^ "`  ";
      "Specification cells: " ^ string_of_int (List.length cells) ^ "  ";
      "Implementation objectives: " ^ string_of_int (List.length entries) ^ "  ";
      "";
      "The original source remains authoritative. Every objective below retains its source cell ID.";
      "";
    ]
  in
  let render_entry entry =
    [
      Printf.sprintf "## Cell %d — %s" entry.cell_id
        (kind_text entry.requirement_kind);
      "";
      entry.objective;
      "";
      "Implementation layer: **"
      ^ Centl_sci_build_plan.layer_text entry.implementation_layer
      ^ "**";
      "";
    ]
    @ render_list "Reusable capabilities" entry.reusable_capabilities
    @ [ "" ]
    @ render_list "Proposed steps" entry.proposed_steps
    @ [ "" ]
    @ render_list "Trust notes" entry.trust_notes
    @ [ "" ]
    @ render_list "Unresolved" entry.unresolved
    @ [ "" ]
  in
  let footer =
    [
      "## Next MIRAGE phase";
      "";
      "Build a typed goal graph, compare every objective against the active capability graph, and derive explicit capability gaps before any code mutation.";
      "";
      "No remote AI service was required to create this cycle.";
      "";
    ]
  in
  String.concat "\n" (header @ List.concat_map render_entry entries @ footer)

let spec_json ~original_path ~stored_path ~source_digest cells entries =
  `Assoc
    [
      ("schema_version", `Int schema_version);
      ("system", `String "CENTL-MIRAGE");
      ("source_digest", `String source_digest);
      ("source_digest_algorithm", `String "sha256");
      ("source_original_path", `String original_path);
      ("source_stored_path", `String stored_path);
      ("cell_count", `Int (List.length cells));
      ("directive_count", `Int (count_kind Directive cells));
      ("invariant_count", `Int (count_kind Invariant cells));
      ("acceptance_count", `Int (count_kind Acceptance cells));
      ("example_count", `Int (count_kind Example cells));
      ("non_goal_count", `Int (count_kind Non_goal cells));
      ("question_count", `Int (count_kind Question cells));
      ("cells", `List (List.map cell_to_json cells));
      ("development_objectives", `List (List.map plan_entry_to_json entries));
    ]

let active_json ~source_digest ~stored_path ~spec_path ~plan_path ~revision =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("status", `String "active");
      ("phase", `String "specification_ingested");
      ("next_phase", `String "capability_gap_analysis");
      ("source_digest", `String source_digest);
      ("source_digest_algorithm", `String "sha256");
      ("source_stored_path", `String stored_path);
      ("specification_ir", `String spec_path);
      ("development_plan", `String plan_path);
      ("workspace_revision", `Int revision);
      ("network_required", `Bool false);
    ]

let ingest workspace path =
  let path = unquote path in
  match read_file path with
  | Error _ as error -> error
  | Ok content ->
      try
        Centl_sci_workspace.ensure workspace;
        let library = library_dir workspace in
        let generated = mirage_dir workspace in
        Centl_sci_workspace.ensure_directory library;
        Centl_sci_workspace.ensure_directory generated;
        let source_digest = Centl_sha256.hex_string content in
        let basename =
          match Filename.basename path with "" | "." | ".." -> "design.txt" | value -> value
        in
        let stored_path =
          Filename.concat library (source_digest ^ "-" ^ basename)
        in
        let spec_path = Filename.concat generated (source_digest ^ ".spec.json") in
        let plan_path = Filename.concat generated (source_digest ^ ".plan.md") in
        let cells = cells_of_text content in
        let entries = List.filter_map plan_entry cells in
        write_text stored_path content;
        Centl_sci_workspace.atomic_write_json spec_path
          (spec_json ~original_path:path ~stored_path ~source_digest cells entries);
        write_text plan_path
          (render_plan ~source_path:stored_path ~source_digest cells entries);
        let revision = Centl_sci_workspace.bump_revision workspace in
        let active_path = active_path workspace in
        Centl_sci_workspace.atomic_write_json active_path
          (active_json ~source_digest ~stored_path ~spec_path ~plan_path ~revision);
        Ok
          {
            source_digest;
            stored_path;
            spec_path;
            plan_path;
            active_path;
            revision;
            cell_count = List.length cells;
            objective_count = List.length entries;
          }
      with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render_ingest result =
  String.concat "\n"
    [
      "CENTL-MIRAGE cycle initiated.";
      "Content ID (SHA-256): " ^ result.source_digest;
      "Structure-library source: " ^ result.stored_path;
      "Specification IR: " ^ result.spec_path;
      "Development plan: " ^ result.plan_path;
      "Active cycle: " ^ result.active_path;
      "Specification cells: " ^ string_of_int result.cell_count;
      "Implementation objectives: " ^ string_of_int result.objective_count;
      "Workspace revision: " ^ string_of_int result.revision;
      "Next phase: capability-gap analysis.";
      "Network/paid AI required: no.";
    ]

let status workspace =
  let path = active_path workspace in
  if not (Sys.file_exists path) then
    "CENTL-MIRAGE has no active local development cycle."
  else
    try
      let channel = open_in path in
      let content =
        Fun.protect
          ~finally:(fun () -> close_in_noerr channel)
          (fun () -> really_input_string channel (in_channel_length channel))
      in
      "CENTL-MIRAGE active cycle:\n" ^ content
    with Sys_error message -> "CENTL-MIRAGE status could not be read: " ^ message
