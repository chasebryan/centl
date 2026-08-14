type proposal = {
  name : string;
  request : string;
  root : string;
  restart_required : bool;
  rebuild_required : bool;
}

let contains needle text =
  Option.is_some
    (Centl_sci_interaction.find_substring ~needle (String.lowercase_ascii text))

let wants text =
  let text = String.lowercase_ascii text in
  contains "verified core" text
  || contains "ocaml source" text
  || contains "ocaml host" text
  || contains "patch your source" text
  || contains "modify your source" text
  || contains "change your source" text
  || contains "edit your source" text
  || contains "rebuild yourself" text
  || contains "recompile yourself" text
  || contains "compiled into" text
  || contains "built-in interpreter" text
  || contains "builtin interpreter" text
  || contains "interpreter binary" text
  || contains "centl-sci binary" text
  || contains "patch yourself" text
     && (contains "source" text || contains "ocaml" text
       || contains "binary" text || contains "host" text)

let slug name_opt request =
  match name_opt with
  | Some name when Centl_sci_change_ir.valid_identifier name -> name
  | _ -> (
      match Centl_sci_recipe.lookup_request request with
      | Some recipe -> recipe.Centl_sci_recipe.name
      | None ->
          let digest = String.sub (Centl_sha256.hex_string request) 0 8 in
          "host_growth_" ^ digest)

let directory workspace =
  Filename.concat workspace.Centl_sci_workspace.generated "host-patches"

let root_for workspace name = Filename.concat (directory workspace) name

let write_text path text =
  Centl_sci_workspace.ensure_directory (Filename.dirname path);
  Centl_sci_workspace.with_atomic_output path (fun channel ->
      output_string channel text;
      if text = "" || text.[String.length text - 1] <> '\n' then
        output_char channel '\n')

let request_document ~name ~request ~source =
  String.concat "\n"
    [
      "# CENTL-SCi host-growth proposal";
      "";
      "name: " ^ name;
      "";
      "Request:";
      "";
      request;
      "";
      (match source with
      | None -> "No local CENTL source was attached."
      | Some value ->
          "Local CENTL source that already works in this session:\n\n```centl\n"
          ^ value ^ "\n```");
      "";
      "This proposal does not modify verified CENTL core.";
      "This proposal does not rewrite the running `centl-sci` process.";
      "Loading an OCaml host change requires an explicit rebuild and restart.";
      "";
    ]

let patch_document ~name ~source =
  String.concat "\n"
    [
      "# Suggested host change";
      "";
      "If this request is only a new exact function, keep it as a local \
       `.centl` program. That path is live without a restart.";
      "";
      "A compiled host change is justified only when the running interpreter \
       itself must learn a new English surface or a new OCaml module.";
      "";
      "Suggested review steps:";
      "";
      "1. Keep or add `modules/" ^ name ^ ".centl` as the live local program.";
      "2. If a spoken alias is enough, edit `spoken/" ^ name ^ ".json`.";
      "3. Only if the OCaml host must change, add a deterministic fast-path or \
       catalog entry in `src/ocaml/` and rebuild.";
      "4. Restart `centl-sci` after `dune build`.";
      "";
      (match source with
      | None -> "No generated CENTL body is attached."
      | Some value ->
          "Exact body to keep local until a host patch is reviewed:\n\n\
           ```centl\n" ^ value ^ "\n```");
      "";
      "Do not copy this file into verified F* core.";
      "";
    ]

let restart_json name =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("name", `String name);
      ("restart_required", `Bool true);
      ("rebuild_required", `Bool true);
      ("verified_core_modified", `Bool false);
      ("hot_loadable", `Bool false);
      ( "reason",
        `String
          "OCaml host and verified-core changes cannot be loaded into the \
           running centl-sci process" );
    ]

let propose workspace ~name ~request ~source =
  let name = slug name request in
  let root = root_for workspace name in
  try
    Centl_sci_workspace.ensure workspace;
    Centl_sci_workspace.ensure_directory root;
    write_text
      (Filename.concat root "request.md")
      (request_document ~name ~request ~source);
    write_text
      (Filename.concat root "host-patch.md")
      (patch_document ~name ~source);
    begin match source with
    | None -> ()
    | Some value -> write_text (Filename.concat root "proposed.centl") value
    end;
    Centl_sci_workspace.atomic_write_json
      (Filename.concat root "restart.json")
      (restart_json name);
    Ok { name; request; root; restart_required = true; rebuild_required = true }
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let list workspace =
  let directory = directory workspace in
  if not (Sys.file_exists directory) then []
  else
    Sys.readdir directory |> Array.to_list
    |> List.filter (fun name ->
        Sys.file_exists
          (Filename.concat (Filename.concat directory name) "restart.json"))
    |> List.sort String.compare

let render proposal =
  String.concat "\n"
    [
      "Host-growth proposal `" ^ proposal.name ^ "`.";
      "Path: " ^ proposal.root;
      "This is a reviewable artifact, not a live binary patch.";
      "Rebuild with `dune build`, then restart `centl-sci` to load host \
       changes.";
      "Verified CENTL core was not modified.";
    ]

let render_list workspace =
  match list workspace with
  | [] ->
      "No host-growth proposals are recorded. Local programs do not need a \
       restart. Ask me to patch OCaml source only when the compiled host \
       itself must change."
  | names ->
      let lines =
        List.map
          (fun name ->
            Printf.sprintf "  %s\n    %s\n    restart after: dune build" name
              (root_for workspace name))
          names
      in
      String.concat "\n"
        (("Host-growth proposals (rebuild + restart required):" :: lines)
        @ [
            "";
            "These cannot hot-load. The running process is unchanged until you \
             rebuild and restart.";
          ])
