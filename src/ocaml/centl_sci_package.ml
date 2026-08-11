type t = {
  name : string;
  version : string;
  extensions : string list;
  summary : string;
  workspace_revision : int;
}

type member_state = {
  name : string;
  present : bool;
  enabled : bool option;
  kind : string option;
  assurance : string option;
}

type validation = { package : t; members : member_state list; valid : bool }

let package_dir workspace name =
  Filename.concat workspace.Centl_sci_workspace.packages name

let manifest_path workspace name =
  Filename.concat (package_dir workspace name) "package.json"

let string_field name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some (`String value) -> Some value
      | _ -> None
      end
  | _ -> None

let int_field name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some (`Int value) -> Some value
      | _ -> None
      end
  | _ -> None

let string_list_field name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some (`List values) ->
          let rec loop acc = function
            | [] -> Some (List.rev acc)
            | `String value :: rest -> loop (value :: acc) rest
            | _ -> None
          in
          loop [] values
      | _ -> None
      end
  | _ -> None

let of_json json =
  match
    ( string_field "name" json,
      string_field "version" json,
      string_list_field "extensions" json,
      string_field "summary" json,
      int_field "workspace_revision" json )
  with
  | Some name, Some version, Some extensions, Some summary, Some revision ->
      Ok { name; version; extensions; summary; workspace_revision = revision }
  | _ -> Error "invalid local package manifest"

let read workspace name =
  let path = manifest_path workspace name in
  if not (Sys.file_exists path) then Error ("unknown local package: " ^ name)
  else
    try Yojson.Safe.from_file path |> of_json
    with Sys_error message | Yojson.Json_error message -> Error message

let write workspace (package : t) =
  let directory = package_dir workspace package.name in
  Centl_sci_workspace.ensure_directory directory;
  let json =
    `Assoc
      [
        ("schema_version", `Int 1);
        ("name", `String package.name);
        ("version", `String package.version);
        ( "extensions",
          `List (List.map (fun value -> `String value) package.extensions) );
        ("summary", `String package.summary);
        ("workspace_revision", `Int package.workspace_revision);
        ("provenance", `String "local user-owned CENTL package");
      ]
  in
  Centl_sci_workspace.atomic_write_json
    (manifest_path workspace package.name)
    json

let create workspace ~name ~summary =
  if not (Centl_sci_workspace.valid_extension_name name) then
    Error "package names may contain only letters, digits, '.', '-', and '_'"
  else if Sys.file_exists (manifest_path workspace name) then
    Error ("local package already exists: " ^ name)
  else
    try
      Centl_sci_workspace.ensure workspace;
      let revision = Centl_sci_workspace.bump_revision workspace in
      let package =
        {
          name;
          version = "0.0.1-local";
          extensions = [];
          summary;
          workspace_revision = revision;
        }
      in
      write workspace package;
      Ok package
    with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let add_extension workspace ~package_name ~extension_name =
  match Centl_sci_extensions.read_manifest workspace extension_name with
  | Error message -> Error message
  | Ok _ ->
      begin match read workspace package_name with
      | Error message -> Error message
      | Ok package when List.mem extension_name package.extensions -> Ok package
      | Ok package -> (
          try
            let revision = Centl_sci_workspace.bump_revision workspace in
            let updated =
              {
                package with
                extensions =
                  List.sort_uniq String.compare
                    (extension_name :: package.extensions);
                workspace_revision = revision;
              }
            in
            write workspace updated;
            Ok updated
          with Sys_error message | Unix.Unix_error (_, _, message) ->
            Error message)
      end

let list workspace =
  if not (Sys.file_exists workspace.Centl_sci_workspace.packages) then []
  else
    Sys.readdir workspace.packages
    |> Array.to_list
    |> List.filter_map (fun name ->
        match read workspace name with
        | Ok package -> Some package
        | Error _ -> None)
    |> List.sort (fun (left : t) (right : t) ->
        String.compare left.name right.name)

let member_state workspace name =
  match Centl_sci_extensions.read_manifest workspace name with
  | Error _ ->
      { name; present = false; enabled = None; kind = None; assurance = None }
  | Ok manifest ->
      {
        name;
        present = true;
        enabled = Some manifest.enabled;
        kind = Some manifest.kind;
        assurance = Some manifest.assurance;
      }

let validate workspace name =
  match read workspace name with
  | Error message -> Error message
  | Ok package ->
      let members = List.map (member_state workspace) package.extensions in
      let valid = List.for_all (fun member -> member.present) members in
      Ok { package; members; valid }

let render_member (member : member_state) =
  if not member.present then member.name ^ " — missing"
  else
    let enabled =
      match member.enabled with
      | Some true -> "enabled"
      | Some false -> "disabled"
      | None -> "unknown"
    in
    let kind = Option.value ~default:"unknown" member.kind in
    let assurance = Option.value ~default:"unknown" member.assurance in
    Printf.sprintf "%s — %s — kind=%s — assurance=%s" member.name enabled kind
      assurance

let render_validation (validation : validation) =
  String.concat "\n"
    ([
       "Package validation: " ^ validation.package.name;
       "  membership valid: " ^ string_of_bool validation.valid;
       "  package-level assurance: none (member assurance is preserved \
        individually)";
       "  members:";
     ]
    @
    match validation.members with
    | [] -> [ "    - none" ]
    | members ->
        List.map (fun member -> "    - " ^ render_member member) members)

let render (package : t) =
  String.concat "\n"
    [
      "Package: " ^ package.name;
      "  version: " ^ package.version;
      "  workspace revision: " ^ string_of_int package.workspace_revision;
      ("  extensions: "
      ^
      if package.extensions = [] then "none"
      else String.concat ", " package.extensions);
      "  summary: " ^ package.summary;
    ]

let render_list workspace =
  match list workspace with
  | [] -> "(no local packages)"
  | packages ->
      packages
      |> List.map (fun (package : t) ->
          Printf.sprintf "%s  %s  (%d extensions)" package.name package.version
            (List.length package.extensions))
      |> String.concat "\n"
