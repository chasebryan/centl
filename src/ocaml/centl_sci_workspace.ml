type t = {
  name : string;
  root : string;
  extensions : string;
  modules_dir : string;
  tests : string;
  data : string;
  config : string;
  history : string;
  packages : string;
  generated : string;
}

type assurance =
  | Verified_extension
  | Validated_native
  | Locally_tested
  | External_backend
  | Experimental_local
  | Unverified_generated

let assurance_text = function
  | Verified_extension -> "verified_extension"
  | Validated_native -> "validated_native_extension"
  | Locally_tested -> "locally_tested_extension"
  | External_backend -> "external_backend"
  | Experimental_local -> "experimental_local_extension"
  | Unverified_generated -> "unverified_generated_extension"

let nonempty_environment name =
  match Sys.getenv_opt name with
  | Some value when String.trim value <> "" -> Some (String.trim value)
  | _ -> None

let default_root () =
  match nonempty_environment "CENTL_WORKSPACE" with
  | Some root -> Some root
  | None ->
      begin match nonempty_environment "HOME" with
      | None -> None
      | Some home ->
          Some
            (Filename.concat
               (Filename.concat (Filename.concat home ".centl") "workspaces")
               "default")
      end

let make ?(name = "default") root =
  {
    name;
    root;
    extensions = Filename.concat root "extensions";
    modules_dir = Filename.concat root "modules";
    tests = Filename.concat root "tests";
    data = Filename.concat root "data";
    config = Filename.concat root "config";
    history = Filename.concat root "history";
    packages = Filename.concat root "packages";
    generated = Filename.concat root "generated";
  }

let default () = Option.map make (default_root ())

let rec ensure_directory path =
  if path = "" || path = Filename.dirname path then ()
  else if Sys.file_exists path then begin
    if not (Sys.is_directory path) then
      raise (Sys_error (path ^ " is not a directory"))
  end
  else begin
    ensure_directory (Filename.dirname path);
    try Unix.mkdir path 0o700
    with
    | Unix.Unix_error (Unix.EEXIST, _, _) when Sys.is_directory path -> ()
  end

let layout workspace =
  [
    workspace.root;
    workspace.extensions;
    workspace.modules_dir;
    workspace.tests;
    workspace.data;
    workspace.config;
    workspace.history;
    workspace.packages;
    workspace.generated;
  ]

let atomic_write_json path json =
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

let workspace_metadata_path workspace = Filename.concat workspace.root "workspace.json"

let ensure_workspace_metadata workspace =
  let path = workspace_metadata_path workspace in
  if not (Sys.file_exists path) then
    atomic_write_json path
      (`Assoc
         [
           ("schema_version", `Int 1);
           ("workspace_name", `String workspace.name);
           ("owner_model", `String "user-owned-downstream");
           ("upstream_project", `String "centl");
           ("created_by", `String "CENTL-SCi v0.0.2-Caramels");
           ("assurance_policy", `String "local extensions never silently inherit verified-core assurance");
         ])

let ensure workspace =
  List.iter ensure_directory (layout workspace);
  ensure_workspace_metadata workspace

let revision_path workspace = Filename.concat workspace.config "revision"
let revision_log_path workspace = Filename.concat workspace.history "revisions.jsonl"

let read_revision workspace =
  try
    let channel = open_in (revision_path workspace) in
    Fun.protect
      ~finally:(fun () -> close_in_noerr channel)
      (fun () ->
        match int_of_string_opt (input_line channel |> String.trim) with
        | Some value when value >= 0 -> value
        | _ -> 0)
  with Sys_error _ | End_of_file -> 0

let write_all channel text =
  output_string channel text;
  flush channel

let write_revision workspace revision =
  ensure workspace;
  let path = revision_path workspace in
  let temporary = path ^ ".tmp" in
  let channel =
    open_out_gen [ Open_wronly; Open_creat; Open_trunc; Open_text ] 0o600 temporary
  in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> write_all channel (string_of_int revision ^ "\n"));
  Unix.rename temporary path

let record_revision workspace revision =
  ensure workspace;
  let channel =
    open_out_gen [ Open_wronly; Open_creat; Open_append; Open_text ] 0o600
      (revision_log_path workspace)
  in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () ->
      let json =
        `Assoc
          [
            ("revision", `Int revision);
            ("timestamp_unix", `Float (Unix.gettimeofday ()));
            ("actor", `String "CENTL-SCi v0.0.2-Caramels");
            ("scope", `String "local-downstream-workspace");
          ]
      in
      Yojson.Safe.to_channel channel json;
      output_char channel '\n';
      flush channel)

let bump_revision workspace =
  let next = read_revision workspace + 1 in
  write_revision workspace next;
  record_revision workspace next;
  next

let manifest_path workspace name =
  Filename.concat workspace.extensions (name ^ ".json")

let valid_extension_name name =
  let length = String.length name in
  length > 0
  && length <= 96
  && String.for_all
       (function
         | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '_' | '.' -> true
         | _ -> false)
       name

let strings values = `List (List.map (fun value -> `String value) values)

let write_manifest workspace ~name ~enabled ~assurance ~source ~summary
    ?(kind = "native_centl") ?(provenance = "local BUILD request")
    ?(dependencies = []) ?(tests = []) () =
  if not (valid_extension_name name) then
    Error "extension names may contain only letters, digits, '.', '-', and '_'"
  else
    try
      ensure workspace;
      let revision = bump_revision workspace in
      let json =
        `Assoc
          [
            ("schema_version", `Int 2);
            ("name", `String name);
            ("kind", `String kind);
            ("enabled", `Bool enabled);
            ("assurance", `String (assurance_text assurance));
            ("source", `String source);
            ("summary", `String summary);
            ("provenance", `String provenance);
            ("dependencies", strings dependencies);
            ("tests", strings tests);
            ("workspace_revision", `Int revision);
            ("recorded_at_unix", `Float (Unix.gettimeofday ()));
          ]
      in
      atomic_write_json (manifest_path workspace name) json;
      Ok revision
    with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let to_json workspace =
  `Assoc
    [
      ("name", `String workspace.name);
      ("root", `String workspace.root);
      ("revision", `Int (read_revision workspace));
      ("metadata", `String (workspace_metadata_path workspace));
      ("revision_log", `String (revision_log_path workspace));
      ("extensions", `String workspace.extensions);
      ("modules", `String workspace.modules_dir);
      ("tests", `String workspace.tests);
      ("data", `String workspace.data);
      ("config", `String workspace.config);
      ("history", `String workspace.history);
      ("packages", `String workspace.packages);
      ("generated", `String workspace.generated);
    ]

let describe workspace =
  String.concat "\n"
    [
      "Workspace: " ^ workspace.name;
      "Root: " ^ workspace.root;
      "Revision: " ^ string_of_int (read_revision workspace);
      "Metadata: " ^ workspace_metadata_path workspace;
      "Revision ledger: " ^ revision_log_path workspace;
      "Extensions: " ^ workspace.extensions;
      "Modules: " ^ workspace.modules_dir;
      "Packages: " ^ workspace.packages;
      "Generated: " ^ workspace.generated;
    ]
