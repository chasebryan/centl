type result = { message : string; changed : bool; revision : int option }
type command = Export of string option | Import of string

let drop_prefix_ci prefix text =
  let trimmed = String.trim text in
  let lower = String.lowercase_ascii trimmed in
  let prefix_lower = String.lowercase_ascii prefix in
  if String.starts_with ~prefix:prefix_lower lower then
    Some
      (String.sub trimmed (String.length prefix)
         (String.length trimmed - String.length prefix)
      |> String.trim)
  else None

let parse input =
  let trimmed = String.trim input in
  let lower = String.lowercase_ascii trimmed in
  if List.mem lower [ "export workspace"; "export my workspace" ] then
    Some (Export None)
  else
    match drop_prefix_ci "export workspace " trimmed with
    | Some path when path <> "" -> Some (Export (Some path))
    | _ ->
        begin match drop_prefix_ci "export my workspace " trimmed with
        | Some path when path <> "" -> Some (Export (Some path))
        | _ ->
            begin match drop_prefix_ci "import workspace " trimmed with
            | Some path when path <> "" -> Some (Import path)
            | _ -> None
            end
        end

let exports_root workspace =
  Filename.concat workspace.Centl_sci_workspace.generated "exports"

let scaffolds_root workspace =
  Filename.concat workspace.Centl_sci_workspace.generated "scaffolds"

let default_export_path workspace =
  let root = exports_root workspace in
  Centl_sci_workspace.ensure_directory root;
  let stamp = Int64.of_float (Unix.gettimeofday () *. 1_000_000.) in
  Filename.concat root
    (Printf.sprintf "caramels-r%d-%Ld"
       (Centl_sci_workspace.read_revision workspace)
       stamp)

let copy_if_exists source target =
  if Sys.file_exists source then Centl_sci_snapshot.copy_tree source target

let bundle_metadata workspace =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("format", `String "centl-caramels-workspace-bundle");
      ("centl_sci_version", `String "0.0.2-Caramels");
      ("workspace_name", `String workspace.Centl_sci_workspace.name);
      ("source_revision", `Int (Centl_sci_workspace.read_revision workspace));
      ("created_at_unix", `Float (Unix.gettimeofday ()));
      ("scope", `String "user-owned-downstream-state");
      ("includes_verified_core", `Bool false);
      ( "assurance_policy",
        `String
          "extension assurance is preserved; export/import never promotes \
           local or generated code to verified core" );
    ]

let export workspace target =
  try
    Centl_sci_workspace.ensure workspace;
    let target =
      match target with
      | Some path -> String.trim path
      | None -> default_export_path workspace
    in
    if target = "" then Error "workspace export path must not be empty"
    else if target = workspace.root then
      Error "workspace export target must not be the active workspace root"
    else if Sys.file_exists target then
      Error ("workspace export target already exists: " ^ target)
    else begin
      Centl_sci_workspace.ensure_directory target;
      copy_if_exists workspace.extensions (Filename.concat target "extensions");
      copy_if_exists workspace.modules_dir (Filename.concat target "modules");
      copy_if_exists workspace.packages (Filename.concat target "packages");
      copy_if_exists workspace.tests (Filename.concat target "tests");
      copy_if_exists workspace.data (Filename.concat target "data");
      copy_if_exists (scaffolds_root workspace)
        (Filename.concat (Filename.concat target "generated") "scaffolds");
      Centl_sci_workspace.atomic_write_json
        (Filename.concat target "bundle.json")
        (bundle_metadata workspace);
      Ok
        {
          message =
            "Exported the user-owned Caramels workspace bundle.\nPath: "
            ^ target
            ^ "\n\
               Included: extension manifests, native modules, packages, tests, \
               data, and generated scaffolds.\n\
               Excluded: verified CENTL core, history, undo snapshots, prior \
               exports, and local workspace identity/configuration.";
          changed = false;
          revision = Some (Centl_sci_workspace.read_revision workspace);
        }
    end
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let assoc name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let bundle_header path =
  let metadata = Filename.concat path "bundle.json" in
  if not (Sys.file_exists metadata) then
    Error "workspace bundle is missing bundle.json"
  else
    try
      let json = Yojson.Safe.from_file metadata in
      match
        ( assoc "schema_version" json,
          assoc "format" json,
          assoc "includes_verified_core" json )
      with
      | ( Some (`Int 1),
          Some (`String "centl-caramels-workspace-bundle"),
          Some (`Bool false) ) ->
          Ok ()
      | _ ->
          Error "workspace bundle metadata is not a recognized Caramels bundle"
    with Yojson.Json_error message | Sys_error message -> Error message

let rec reject_symlinks path =
  try
    let stat = Unix.lstat path in
    match stat.Unix.st_kind with
    | Unix.S_LNK -> Error ("workspace bundle contains a symlink: " ^ path)
    | Unix.S_DIR ->
        let entries = Sys.readdir path |> Array.to_list in
        let rec loop = function
          | [] -> Ok ()
          | name :: rest ->
              begin match reject_symlinks (Filename.concat path name) with
              | Ok () -> loop rest
              | Error _ as error -> error
              end
        in
        loop entries
    | Unix.S_REG -> Ok ()
    | _ ->
        Error
          ("workspace bundle contains an unsupported filesystem object: " ^ path)
  with Unix.Unix_error (_, _, message) | Sys_error message -> Error message

let safe_relative_source source =
  let source = String.trim source in
  source <> ""
  && Filename.is_relative source
  && (not (String.contains source '\\'))
  &&
  let components = String.split_on_char '/' source in
  components <> []
  && List.for_all
       (fun component ->
         component <> "" && component <> "." && component <> "..")
       components

let manifest_names workspace =
  if not (Sys.file_exists workspace.Centl_sci_workspace.extensions) then Ok []
  else
    let files =
      Sys.readdir workspace.extensions
      |> Array.to_list
      |> List.filter (fun name -> Filename.check_suffix name ".json")
    in
    let rec loop acc = function
      | [] -> Ok (List.rev acc)
      | filename :: rest ->
          let name = Filename.chop_suffix filename ".json" in
          begin match Centl_sci_extensions.read_manifest workspace name with
          | Error message ->
              Error ("invalid extension manifest " ^ filename ^ ": " ^ message)
          | Ok manifest when not (safe_relative_source manifest.source) ->
              Error
                (Printf.sprintf
                   "bundle extension %s has a source path outside the \
                    normalized relative bundle namespace: %s"
                   manifest.name manifest.source)
          | Ok manifest when manifest.enabled && manifest.kind <> "native_centl"
            ->
              Error
                (Printf.sprintf
                   "bundle extension %s is enabled but has non-native kind %s; \
                    Caramels will not import it as active"
                   manifest.name manifest.kind)
          | Ok _ -> loop (name :: acc) rest
          end
    in
    loop [] files

let validate_extensions workspace names =
  let rec loop = function
    | [] -> Ok ()
    | name :: rest ->
        begin match Centl_sci_validate.validate workspace name with
        | Error message ->
            Error ("could not validate extension " ^ name ^ ": " ^ message)
        | Ok report when report.valid -> loop rest
        | Ok report ->
            Error
              ("extension " ^ name ^ " failed structural validation: "
              ^ String.concat "; " report.checks)
        end
  in
  loop names

let validate_dependencies workspace =
  let report = Centl_sci_dependencies.validate workspace in
  match report.issues with
  | [] -> Ok ()
  | issues ->
      Error
        ("extension dependency graph is not activation-ready: "
        ^ String.concat "; " (List.map Centl_sci_dependencies.issue_text issues)
        )

let package_names workspace =
  if not (Sys.file_exists workspace.Centl_sci_workspace.packages) then []
  else Sys.readdir workspace.packages |> Array.to_list

let validate_packages workspace extension_names =
  let rec loop = function
    | [] -> Ok ()
    | name :: rest ->
        begin match Centl_sci_package.read workspace name with
        | Error message -> Error ("invalid package " ^ name ^ ": " ^ message)
        | Ok package ->
            begin match
              List.find_opt
                (fun extension -> not (List.mem extension extension_names))
                package.extensions
            with
            | Some extension ->
                Error
                  (Printf.sprintf
                     "package %s references extension %s, which is absent from \
                      the bundle"
                     package.name extension)
            | None -> loop rest
            end
        end
  in
  loop (package_names workspace)

let validate_bundle path =
  if (not (Sys.file_exists path)) || not (Sys.is_directory path) then
    Error ("workspace bundle directory does not exist: " ^ path)
  else
    match reject_symlinks path with
    | Error _ as error -> error
    | Ok () ->
        begin match bundle_header path with
        | Error _ as error -> error
        | Ok () ->
            let bundle_workspace =
              Centl_sci_workspace.make ~name:"import-bundle" path
            in
            begin match manifest_names bundle_workspace with
            | Error _ as error -> error
            | Ok names ->
                begin match validate_extensions bundle_workspace names with
                | Error _ as error -> error
                | Ok () ->
                    begin match validate_dependencies bundle_workspace with
                    | Error _ as error -> error
                    | Ok () ->
                        begin match
                          validate_packages bundle_workspace names
                        with
                        | Error _ as error -> error
                        | Ok () -> Ok ()
                        end
                    end
                end
            end
        end

let replace_surface workspace bundle =
  let bundle_workspace =
    Centl_sci_workspace.make ~name:"import-bundle" bundle
  in
  Centl_sci_snapshot.clear_directory workspace.Centl_sci_workspace.extensions;
  Centl_sci_snapshot.clear_directory workspace.modules_dir;
  Centl_sci_snapshot.clear_directory workspace.packages;
  Centl_sci_snapshot.clear_directory workspace.tests;
  Centl_sci_snapshot.clear_directory workspace.data;
  Centl_sci_snapshot.clear_directory (scaffolds_root workspace);
  copy_if_exists bundle_workspace.extensions workspace.extensions;
  copy_if_exists bundle_workspace.modules_dir workspace.modules_dir;
  copy_if_exists bundle_workspace.packages workspace.packages;
  copy_if_exists bundle_workspace.tests workspace.tests;
  copy_if_exists bundle_workspace.data workspace.data;
  copy_if_exists (scaffolds_root bundle_workspace) (scaffolds_root workspace)

let import workspace path =
  let path = String.trim path in
  if path = "" then Error "workspace import path must not be empty"
  else if path = workspace.Centl_sci_workspace.root then
    Error "workspace import source must not be the active workspace itself"
  else
    match validate_bundle path with
    | Error message ->
        Error ("workspace import rejected before mutation: " ^ message)
    | Ok () ->
        begin match Centl_sci_snapshot.create workspace with
        | Error message ->
            Error
              ("could not snapshot the current workspace before import: "
             ^ message)
        | Ok snapshot -> (
            try
              replace_surface workspace path;
              let revision = Centl_sci_workspace.bump_revision workspace in
              Ok
                {
                  message =
                    Printf.sprintf
                      "Imported a validated Caramels downstream workspace \
                       bundle.\n\
                       Source: %s\n\
                       Workspace revision: %d\n\
                       The previous downstream state is available through \
                       `undo`.\n\
                       Verified CENTL core, workspace identity, history, and \
                       configuration were not replaced."
                      path revision;
                  changed = true;
                  revision = Some revision;
                }
            with Sys_error message | Unix.Unix_error (_, _, message) ->
              begin match Centl_sci_snapshot.rollback workspace snapshot with
              | Ok revision ->
                  Error
                    (Printf.sprintf
                       "workspace import failed during mutation and was rolled \
                        back without advancing the workspace revision (still \
                        %d): %s"
                       revision message)
              | Error rollback_message ->
                  Error
                    (Printf.sprintf
                       "workspace import failed during mutation: %s; automatic \
                        rollback also failed: %s"
                       message rollback_message)
              end)
        end

let execute workspace = function
  | Export target -> export workspace target
  | Import path -> import workspace path
