type manifest = {
  name : string;
  kind : string;
  enabled : bool;
  assurance : string;
  source : string;
  summary : string;
  provenance : string;
  dependencies : string list;
  tests : string list;
  workspace_revision : int;
  recorded_at_unix : float option;
}

type error = string

let assoc name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let string_field name json =
  match assoc name json with Some (`String value) -> Some value | _ -> None

let bool_field name json =
  match assoc name json with Some (`Bool value) -> Some value | _ -> None

let int_field name json =
  match assoc name json with Some (`Int value) -> Some value | _ -> None

let float_field name json =
  match assoc name json with
  | Some (`Float value) -> Some value
  | Some (`Int value) -> Some (float_of_int value)
  | _ -> None

let string_list_field name json =
  match assoc name json with
  | Some (`List values) ->
      let rec loop acc = function
        | [] -> Some (List.rev acc)
        | `String value :: rest -> loop (value :: acc) rest
        | _ -> None
      in
      loop [] values
  | None -> Some []
  | _ -> None

let read_json path =
  try Ok (Yojson.Safe.from_file path)
  with Sys_error message | Yojson.Json_error message -> Error message

let manifest_of_json json =
  match
    ( string_field "name" json,
      bool_field "enabled" json,
      string_field "assurance" json,
      string_field "source" json,
      string_field "summary" json,
      int_field "workspace_revision" json,
      string_list_field "dependencies" json,
      string_list_field "tests" json )
  with
  | Some name, Some enabled, Some assurance, Some source, Some summary,
    Some revision, Some dependencies, Some tests ->
      Ok
        {
          name;
          kind = Option.value ~default:"native_centl" (string_field "kind" json);
          enabled;
          assurance;
          source;
          summary;
          provenance =
            Option.value ~default:"legacy/local manifest"
              (string_field "provenance" json);
          dependencies;
          tests;
          workspace_revision = revision;
          recorded_at_unix = float_field "recorded_at_unix" json;
        }
  | _ -> Error "invalid extension manifest"

let read_manifest workspace name =
  let path = Centl_sci_workspace.manifest_path workspace name in
  if not (Sys.file_exists path) then Error ("unknown local extension: " ^ name)
  else
    match read_json path with
    | Error message -> Error message
    | Ok json -> manifest_of_json json

let local_dependency_name dependency =
  let dependency = String.trim dependency in
  let prefix = "extension:" in
  if String.starts_with ~prefix dependency then
    let name =
      String.sub dependency (String.length prefix)
        (String.length dependency - String.length prefix)
      |> String.trim
    in
    if name = "" then None else Some name
  else None

let order_by_local_dependencies manifests =
  let manifests =
    List.sort (fun left right -> String.compare left.name right.name) manifests
  in
  let by_name = List.map (fun manifest -> (manifest.name, manifest)) manifests in
  let state = Hashtbl.create (List.length manifests) in
  let ordered = ref [] in
  let rec visit manifest =
    match Hashtbl.find_opt state manifest.name with
    | Some `Done -> ()
    | Some `Visiting -> ()
    | None ->
        Hashtbl.replace state manifest.name `Visiting;
        manifest.dependencies
        |> List.filter_map local_dependency_name
        |> List.sort_uniq String.compare
        |> List.iter (fun name ->
               match List.assoc_opt name by_name with
               | Some dependency -> visit dependency
               | None -> ());
        Hashtbl.replace state manifest.name `Done;
        ordered := manifest :: !ordered
  in
  List.iter visit manifests;
  List.rev !ordered

let list workspace =
  if not (Sys.file_exists workspace.Centl_sci_workspace.extensions) then []
  else
    Sys.readdir workspace.extensions
    |> Array.to_list
    |> List.filter (fun name -> Filename.check_suffix name ".json")
    |> List.filter_map (fun filename ->
           let name = Filename.chop_suffix filename ".json" in
           match read_manifest workspace name with
           | Ok value -> Some value
           | Error _ -> None)
    |> order_by_local_dependencies

let strings values = `List (List.map (fun value -> `String value) values)

let to_json manifest ~revision =
  `Assoc
    [
      ("schema_version", `Int 2);
      ("name", `String manifest.name);
      ("kind", `String manifest.kind);
      ("enabled", `Bool manifest.enabled);
      ("assurance", `String manifest.assurance);
      ("source", `String manifest.source);
      ("summary", `String manifest.summary);
      ("provenance", `String manifest.provenance);
      ("dependencies", strings manifest.dependencies);
      ("tests", strings manifest.tests);
      ("workspace_revision", `Int revision);
      ( "recorded_at_unix",
        match manifest.recorded_at_unix with
        | None -> `Float (Unix.gettimeofday ())
        | Some value -> `Float value );
    ]

let write_json path json =
  let temporary = path ^ ".tmp" in
  let channel =
    open_out_gen [ Open_wronly; Open_creat; Open_trunc; Open_text ] 0o600 temporary
  in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () ->
      Yojson.Safe.pretty_to_channel channel json;
      output_char channel '\n';
      flush channel);
  Unix.rename temporary path

let source_path workspace manifest =
  if Filename.is_relative manifest.source then
    Filename.concat workspace.Centl_sci_workspace.root manifest.source
  else manifest.source

let read_text path =
  try
    let channel = open_in_bin path in
    Ok
      (Fun.protect
         ~finally:(fun () -> close_in_noerr channel)
         (fun () -> really_input_string channel (in_channel_length channel)))
  with
  | Sys_error message -> Error message
  | End_of_file -> Error ("unexpected end of file while reading extension source: " ^ path)

let validate_native_activation workspace manifest =
  let path = source_path workspace manifest in
  if not (Sys.file_exists path) then
    Error ("native extension source is missing: " ^ path)
  else if Sys.is_directory path then
    Error ("native extension source is a directory: " ^ path)
  else
    match read_text path with
    | Error message -> Error message
    | Ok source ->
        begin match Centl_parser.parse_statement_located source with
        | Error error ->
            Error
              (Printf.sprintf
                 "native extension %s cannot be enabled because its source does not parse at byte %d: %s"
                 manifest.name error.position error.message)
        | Ok located ->
            begin match located.statement with
            | Centl_parser.Define_value _ | Centl_parser.Define_function _ -> Ok ()
            | Centl_parser.Evaluate _ | Centl_parser.Assert _ ->
                Error
                  (Printf.sprintf
                     "native extension %s cannot be enabled because its source is not a value/function definition"
                     manifest.name)
            end
        end

let set_enabled workspace name enabled =
  match read_manifest workspace name with
  | Error message -> Error message
  | Ok manifest when enabled && manifest.kind <> "native_centl" ->
      Error
        (Printf.sprintf
           "local extension %s has kind %s. Caramels will not route it through the native CENTL definition loader; implement and validate its explicit runtime boundary before activation."
           manifest.name manifest.kind)
  | Ok manifest ->
      let activation_check =
        if enabled then validate_native_activation workspace manifest else Ok ()
      in
      begin match activation_check with
      | Error _ as error -> error
      | Ok () ->
          try
            Centl_sci_workspace.ensure workspace;
            let revision = Centl_sci_workspace.bump_revision workspace in
            let updated = { manifest with enabled; workspace_revision = revision } in
            write_json (Centl_sci_workspace.manifest_path workspace name)
              (to_json updated ~revision);
            Ok updated
          with Sys_error message | Unix.Unix_error (_, _, message) -> Error message
      end

let trash_dir workspace = Filename.concat workspace.Centl_sci_workspace.generated "removed"

let remove workspace name =
  match read_manifest workspace name with
  | Error message -> Error message
  | Ok manifest ->
      try
        Centl_sci_workspace.ensure workspace;
        Centl_sci_workspace.ensure_directory (trash_dir workspace);
        let revision = Centl_sci_workspace.bump_revision workspace in
        let suffix = Printf.sprintf ".r%d" revision in
        let manifest_path = Centl_sci_workspace.manifest_path workspace name in
        let source = source_path workspace manifest in
        let archived_manifest =
          Filename.concat (trash_dir workspace) (name ^ suffix ^ ".json")
        in
        Unix.rename manifest_path archived_manifest;
        if Sys.file_exists source && not (Sys.is_directory source) then
          Unix.rename source
            (Filename.concat (trash_dir workspace)
               (name ^ suffix ^ Filename.extension source));
        Ok revision
      with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render_manifest manifest =
  let dependencies =
    if manifest.dependencies = [] then "none"
    else String.concat ", " manifest.dependencies
  in
  let tests =
    if manifest.tests = [] then "none" else String.concat ", " manifest.tests
  in
  String.concat "\n"
    [
      "Extension: " ^ manifest.name;
      "  kind: " ^ manifest.kind;
      "  enabled: " ^ string_of_bool manifest.enabled;
      "  assurance: " ^ manifest.assurance;
      "  source: " ^ manifest.source;
      "  provenance: " ^ manifest.provenance;
      "  dependencies: " ^ dependencies;
      "  tests: " ^ tests;
      "  workspace revision: " ^ string_of_int manifest.workspace_revision;
      "  summary: " ^ manifest.summary;
    ]

let render_list workspace =
  match list workspace with
  | [] -> "(no local extensions)"
  | values ->
      values
      |> List.map (fun item ->
             Printf.sprintf "%s  [%s]  %s  <%s>" item.name
               (if item.enabled then "enabled" else "disabled") item.assurance
               item.kind)
      |> String.concat "\n"
