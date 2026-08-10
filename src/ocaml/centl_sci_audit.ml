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
  manifest_errors : string list;
  packages : package_entry list;
  dependencies_valid : bool;
  dependency_issues : string list;
  warnings : string list;
}

let extension_entry workspace (manifest : Centl_sci_extensions.manifest) =
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

let package_entry workspace (package : Centl_sci_package.t) =
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
        |> List.filter (fun (member : Centl_sci_package.member_state) -> not member.present)
        |> List.map (fun (member : Centl_sci_package.member_state) -> member.name)
      in
      {
        name = package.name;
        valid = validation.valid;
        members = List.length validation.members;
        missing_members;
      }

let collect workspace =
  let manifest_values, manifest_errors = Centl_sci_extensions.scan workspace in
  let extensions = List.map (extension_entry workspace) manifest_values in
  let packages = Centl_sci_package.list workspace |> List.map (package_entry workspace) in
  let dependency_report = Centl_sci_dependencies.validate workspace in
  let dependency_issues =
    List.map Centl_sci_dependencies.issue_text dependency_report.issues
  in
  let warnings =
    manifest_errors
    @
    (extensions
    |> List.concat_map (fun (extension : extension_entry) ->
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
           structural @ activation))
    @
    (packages
    |> List.concat_map (fun (package : package_entry) ->
           if package.valid then []
           else [ "package " ^ package.name ^ " failed structural validation" ]))
    @ dependency_issues
  in
  {
    workspace_root = workspace.Centl_sci_workspace.root;
    revision = Centl_sci_workspace.read_revision workspace;
    extensions;
    manifest_errors;
    packages;
    dependencies_valid = dependency_report.valid;
    dependency_issues;
    warnings;
  }

let healthy report = report.warnings = []

let render report =
  let extension_lines =
    report.extensions
    |> List.map (fun extension ->
           Printf.sprintf "  - %s — %s — %s — assurance=%s" extension.name
             (if extension.enabled then "enabled" else "disabled")
             (if extension.structurally_valid then "valid" else "invalid")
             extension.assurance)
  in
  let package_lines =
    report.packages
    |> List.map (fun package ->
           Printf.sprintf "  - %s — %s — members=%d" package.name
             (if package.valid then "valid" else "invalid") package.members)
  in
  String.concat "\n"
    ([
       "Caramels workspace audit";
       "  workspace: " ^ report.workspace_root;
       "  revision: " ^ string_of_int report.revision;
       "  health: " ^ (if healthy report then "healthy" else "attention_required");
       "  verified core modified: false";
       "Extensions:";
     ]
    @ (if extension_lines = [] then [ "  - none" ] else extension_lines)
    @ [ "Packages:" ]
    @ (if package_lines = [] then [ "  - none" ] else package_lines)
    @ [ "Warnings:" ]
    @
    (if report.warnings = [] then [ "  - none" ]
     else List.map (fun warning -> "  - " ^ warning) report.warnings)
    @ [
        "Assurance note: workspace health is structural consistency, not a trust score.";
      ])

let to_json report =
  let extension_json extension =
    `Assoc
      [
        ("name", `String extension.name);
        ("kind", `String extension.kind);
        ("enabled", `Bool extension.enabled);
        ("assurance", `String extension.assurance);
        ("structurally_valid", `Bool extension.structurally_valid);
        ("notes", `List (List.map (fun note -> `String note) extension.notes));
      ]
  in
  let package_json package =
    `Assoc
      [
        ("name", `String package.name);
        ("valid", `Bool package.valid);
        ("members", `Int package.members);
        ( "missing_members",
          `List (List.map (fun member -> `String member) package.missing_members) );
      ]
  in
  `Assoc
    [
      ("schema_version", `Int 1);
      ("centl_sci_version", `String "0.0.2-Caramels");
      ("workspace", `String report.workspace_root);
      ("revision", `Int report.revision);
      ("health", `String (if healthy report then "healthy" else "attention_required"));
      ("verified_core_modified", `Bool false);
      ("extensions", `List (List.map extension_json report.extensions));
      ("manifest_errors", `List (List.map (fun value -> `String value) report.manifest_errors));
      ("packages", `List (List.map package_json report.packages));
      ("dependencies_valid", `Bool report.dependencies_valid);
      ("dependency_issues", `List (List.map (fun value -> `String value) report.dependency_issues));
      ("warnings", `List (List.map (fun value -> `String value) report.warnings));
      ("assurance_promoted", `Bool false);
    ]