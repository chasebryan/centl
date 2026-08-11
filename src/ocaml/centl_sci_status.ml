type t = {
  version : string;
  platform : string;
  workspace_root : string option;
  workspace_revision : int option;
  workspace_health : string option;
  enabled_native_extensions : string list;
  disabled_extensions : int;
  packages : int;
  gated : string list;
}

let platform () =
  if Sys.win32 then "windows"
  else
    match Sys.os_type with
    | "Unix" -> "unix/linux-reference"
    | value -> String.lowercase_ascii value

let collect () =
  match Centl_sci_workspace.default () with
  | None ->
      {
        version = "0.0.2-Caramels+";
        platform = platform ();
        workspace_root = None;
        workspace_revision = None;
        workspace_health = None;
        enabled_native_extensions = [];
        disabled_extensions = 0;
        packages = 0;
        gated =
          [
            "BUILD workspace operations require HOME or CENTL_WORKSPACE";
            "live workspace import activation remains gated until same-command \
             core-session reload is wired";
          ];
      }
  | Some workspace ->
      let extensions = Centl_sci_extensions.list workspace in
      let enabled_native_extensions =
        extensions
        |> List.filter (fun (extension : Centl_sci_extensions.manifest) ->
            extension.Centl_sci_extensions.enabled
            && extension.kind = "native_centl")
        |> List.map (fun (extension : Centl_sci_extensions.manifest) ->
            extension.name)
      in
      let disabled_extensions =
        extensions
        |> List.filter (fun (extension : Centl_sci_extensions.manifest) ->
            not extension.enabled)
        |> List.length
      in
      let audit = Centl_sci_audit.collect workspace in
      {
        version = "0.0.2-Caramels+";
        platform = platform ();
        workspace_root = Some workspace.root;
        workspace_revision = Some (Centl_sci_workspace.read_revision workspace);
        workspace_health =
          Some
            (if Centl_sci_audit.healthy audit then "healthy"
             else "attention_required");
        enabled_native_extensions;
        disabled_extensions;
        packages = List.length (Centl_sci_package.list workspace);
        gated =
          [
            "live workspace import activation remains gated until same-command \
             core-session reload is wired";
            "main centl calculator shared-editor migration remains a separate \
             integration item";
          ];
      }

let option_text = function None -> "unavailable" | Some value -> value

let int_option_text = function
  | None -> "unavailable"
  | Some value -> string_of_int value

let render status =
  String.concat "\n"
    ([
       "CENTL-SCi status";
       "  version: " ^ status.version;
       "  platform: " ^ status.platform;
       "  workspace: " ^ option_text status.workspace_root;
       "  workspace revision: " ^ int_option_text status.workspace_revision;
       "  workspace health: " ^ option_text status.workspace_health;
       ("  enabled native extensions: "
       ^
       if status.enabled_native_extensions = [] then "none"
       else String.concat ", " status.enabled_native_extensions);
       "  disabled extensions: " ^ string_of_int status.disabled_extensions;
       "  local packages: " ^ string_of_int status.packages;
       "  deliberately gated:";
     ]
    @ List.map (fun item -> "    - " ^ item) status.gated
    @ [
        "  assurance note: status reports local state and structural health; \
         it does not promote downstream assurance.";
      ])

let to_json status =
  let strings values = `List (List.map (fun value -> `String value) values) in
  `Assoc
    [
      ("schema_version", `Int 1);
      ("version", `String status.version);
      ("platform", `String status.platform);
      ( "workspace_root",
        match status.workspace_root with
        | None -> `Null
        | Some value -> `String value );
      ( "workspace_revision",
        match status.workspace_revision with
        | None -> `Null
        | Some value -> `Int value );
      ( "workspace_health",
        match status.workspace_health with
        | None -> `Null
        | Some value -> `String value );
      ("enabled_native_extensions", strings status.enabled_native_extensions);
      ("disabled_extensions", `Int status.disabled_extensions);
      ("packages", `Int status.packages);
      ("gated", strings status.gated);
      ("assurance_promoted", `Bool false);
    ]
