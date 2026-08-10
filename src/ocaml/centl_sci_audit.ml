type extension_entry = {
  name : string;
  kind : string;
  enabled : bool;
  assurance : string;
  structurally_valid : bool;
  notes : string list;
}

type package_entry = {
  name : string;
  valid : bool;
  members : int;
  missing_members : string list;
}

type t = {
  workspace_root : string;
  revision : int;
  extensions : extension_entry list;
  packages : package_entry list;
  dependencies_valid : bool;
  dependency_issues : string list;
  warnings : string list;
}

let extension_entry workspace manifest =
  match Centl_sci_validate.validate workspace manifest.Centl_sci_extensions.name with
  | Error message ->
      {
        name = manifest.name;
        kind = manifest.kind;
        enabled = manifest.enabled;
        assurance = manifest.assurance;
        structurally_valid = false;
        notes = [ message ];
      }
  | Ok report ->
      {
        name = manifest.name;
        kind = manifest.kind;
        enabled = manifest.enabled;
        assurance = manifest.assurance;
        structurally_valid = report.valid;
        notes = report.checks;
      }

let package_entry workspace package =
  match Centl_sci_package.validate workspace package.Centl_sci_package.name with
  | Error message ->
      {
        name = package.name;
        valid = false;
        members = List.length package.extensions;
        missing_members = [ message ];
      }
  | Ok validation ->
      let missing_members =
        validation.members
        |> List.filter (fun member -> not member.Centl_sci_package.present)
        |> List.map (fun member -> member.name)
      in
      {
        name = package.name;
        valid = validation.valid;
        members = List.length validation.members;
        missing_members;
      }

let collect workspace =
  let extensions =
    Centl_sci_extensions.list workspace |> List.map (extension_entry workspace)
  in
  let packages = Centl_sci_package.list workspace |> List.map (package_entry workspace) in
  let dependency_report = Centl_sci_dependencies.validate workspace in
  let dependency_issues =
    List.map Centl_sci_dependencies.issue_text dependency_report.issues
  in
  let warnings =
    extensions
    |> List.concat_map (fun extension ->
           let structural =
             if extension.structurally_valid then []
             else [ "extension " ^ extension.name ^ " failed structural validation" ]
           in
           let activation =
             if extension.enabled && extension.kind <> "native_centl" then
               [
                 Printf.sprintf
                   "extension %s is enabled with non-native kind %s; it must not enter the native CENTL loader"
                   extension.name extension.kind;
               ]
             else []
           in
           structural @ activation)
    @
    (packages
    |> List.concat_map (fun package ->
           if package.valid then []
           else
             [
               "package " ^ package.name ^ " has invalid or missing membership";
             ]))
    @ dependency_issues
  in
  {
    workspace_root = workspace.Centl_sci_workspace.root;
    revision = Centl_sci_workspace.read_revision workspace;
    extensions;
    packages;
    dependencies_valid = dependency_report.valid;
    dependency_issues;
    warnings;
  }

let strings values = `List (List.map (fun value -> `String value) values)

let extension_json entry =
  `Assoc
    [
      ("name", `String entry.name);
      ("kind", `String entry.kind);
      ("enabled", `Bool entry.enabled);
      ("assurance", `String entry.assurance);
      ("structurally_valid", `Bool entry.structurally_valid);
      ("notes", strings entry.notes);
    ]

let package_json entry =
  `Assoc
    [
      ("name", `String entry.name);
      ("valid", `Bool entry.valid);
      ("members", `Int entry.members);
      ("missing_members", strings entry.missing_members);
    ]

let to_json audit =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("centl_sci_version", `String "0.0.2-Caramels");
      ("workspace_root", `String audit.workspace_root);
      ("revision", `Int audit.revision);
      ("extensions", `List (List.map extension_json audit.extensions));
      ("packages", `List (List.map package_json audit.packages));
      ("dependencies_valid", `Bool audit.dependencies_valid);
      ("dependency_issues", strings audit.dependency_issues);
      ("warnings", strings audit.warnings);
      ("verified_core_modified", `Bool false);
    ]

let render_extension entry =
  Printf.sprintf "  - %s — kind=%s — %s — assurance=%s — structural=%s"
    entry.name entry.kind (if entry.enabled then "enabled" else "disabled")
    entry.assurance (if entry.structurally_valid then "valid" else "invalid")

let render_package entry =
  Printf.sprintf "  - %s — members=%d — membership=%s" entry.name entry.members
    (if entry.valid then "valid" else "invalid")

let render audit =
  String.concat "\n"
    ([
       "Caramels workspace audit";
       "  root: " ^ audit.workspace_root;
       "  revision: " ^ string_of_int audit.revision;
       "  verified core modified by audit: false";
       "  dependency graph structurally valid: "
       ^ string_of_bool audit.dependencies_valid;
       "Extensions:";
     ]
    @
    (if audit.extensions = [] then [ "  - none" ]
     else List.map render_extension audit.extensions)
    @ [ "Packages:" ]
    @
    (if audit.packages = [] then [ "  - none" ]
     else List.map render_package audit.packages)
    @ [ "Dependency issues:" ]
    @
    (if audit.dependency_issues = [] then [ "  - none" ]
     else List.map (fun issue -> "  - " ^ issue) audit.dependency_issues)
    @ [ "Warnings:" ]
    @
    (if audit.warnings = [] then [ "  - none" ]
     else List.map (fun warning -> "  - " ^ warning) audit.warnings)
    @ [
        "Assurance note: this audit checks local structural/workspace consistency only; it does not promote downstream code to verified CENTL core.";
      ])
