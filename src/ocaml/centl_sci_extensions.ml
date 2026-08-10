type manifest = {
  name : string;
  enabled : bool;
  assurance : string;
  source : string;
  summary : string;
  workspace_revision : int;
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
      int_field "workspace_revision" json )
  with
  | Some name, Some enabled, Some assurance, Some source, Some summary, Some revision ->
      Ok { name; enabled; assurance; source; summary; workspace_revision = revision }
  | _ -> Error "invalid extension manifest"

let read_manifest workspace name =
  let path = Centl_sci_workspace.manifest_path workspace name in
  if not (Sys.file_exists path) then Error ("unknown local extension: " ^ name)
  else
    match read_json path with
    | Error message -> Error message
    | Ok json -> manifest_of_json json

let list workspace =
  if not (Sys.file_exists workspace.Centl_sci_workspace.extensions) then []
  else
    Sys.readdir workspace.extensions
    |> Array.to_list
    |> List.filter (fun name -> Filename.check_suffix name ".json")
    |> List.filter_map (fun filename ->
           let name = Filename.chop_suffix filename ".json" in
           match read_manifest workspace name with Ok value -> Some value | Error _ -> None)
    |> List.sort (fun left right -> String.compare left.name right.name)

let to_json manifest ~revision =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("name", `String manifest.name);
      ("enabled", `Bool manifest.enabled);
      ("assurance", `String manifest.assurance);
      ("source", `String manifest.source);
      ("summary", `String manifest.summary);
      ("workspace_revision", `Int revision);
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

let set_enabled workspace name enabled =
  match read_manifest workspace name with
  | Error message -> Error message
  | Ok manifest ->
      try
        Centl_sci_workspace.ensure workspace;
        let revision = Centl_sci_workspace.bump_revision workspace in
        let updated = { manifest with enabled; workspace_revision = revision } in
        write_json (Centl_sci_workspace.manifest_path workspace name)
          (to_json updated ~revision);
        Ok updated
      with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let source_path workspace manifest =
  if Filename.is_relative manifest.source then Filename.concat workspace.root manifest.source
  else manifest.source

let trash_dir workspace = Filename.concat workspace.generated "removed"

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
        if Sys.file_exists source then
          Unix.rename source
            (Filename.concat (trash_dir workspace)
               (name ^ suffix ^ Filename.extension source));
        Ok revision
      with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render_manifest manifest =
  String.concat "\n"
    [
      "Extension: " ^ manifest.name;
      "  enabled: " ^ string_of_bool manifest.enabled;
      "  assurance: " ^ manifest.assurance;
      "  source: " ^ manifest.source;
      "  workspace revision: " ^ string_of_int manifest.workspace_revision;
      "  summary: " ^ manifest.summary;
    ]

let render_list workspace =
  match list workspace with
  | [] -> "(no local extensions)"
  | values ->
      values
      |> List.map (fun item ->
             Printf.sprintf "%s  [%s]  %s" item.name
               (if item.enabled then "enabled" else "disabled") item.assurance)
      |> String.concat "\n"
