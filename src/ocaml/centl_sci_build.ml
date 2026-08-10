type handled = {
  message : string;
  changed : bool;
  revision : int option;
}

type result = Handled of handled | Not_handled

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

let workspace_result action =
  match Centl_sci_workspace.default () with
  | None ->
      Handled
        {
          message =
            "CENTL-SCi cannot determine a local workspace because HOME is unavailable. Set CENTL_WORKSPACE to an explicit directory.";
          changed = false;
          revision = None;
        }
  | Some workspace -> action workspace

let write_text_file path text =
  let temporary = path ^ ".tmp" in
  let channel =
    open_out_gen [ Open_wronly; Open_creat; Open_trunc; Open_text ] 0o600 temporary
  in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () ->
      output_string channel text;
      if text = "" || text.[String.length text - 1] <> '\n' then output_char channel '\n';
      flush channel);
  Unix.rename temporary path

let create_function ~replace source =
  workspace_result (fun workspace ->
      match Centl_parser.parse_statement_located source with
      | Error error ->
          Handled
            {
              message =
                Printf.sprintf
                  "I recognized a function-extension request, but the generated CENTL definition is invalid at byte %d: %s"
                  error.position error.message;
              changed = false;
              revision = None;
            }
      | Ok located ->
          begin match located.statement with
          | Centl_parser.Define_function (name, _, _) ->
              let path = Filename.concat workspace.modules_dir (name ^ ".centl") in
              if Sys.file_exists path && not replace then
                Handled
                  {
                    message =
                      Printf.sprintf
                        "Local function %s already exists at %s. Use a modification request rather than silently replacing it."
                        name path;
                    changed = false;
                    revision = None;
                  }
              else
                begin
                  try
                    Centl_sci_workspace.ensure workspace;
                    write_text_file path source;
                    begin match
                      Centl_sci_workspace.write_manifest workspace ~name
                        ~enabled:true ~assurance:Centl_sci_workspace.Locally_tested
                        ~source:("modules/" ^ name ^ ".centl")
                        ~summary:"Local CENTL function created through BUILD mode"
                    with
                    | Error message ->
                        Handled
                          {
                            message =
                              "The CENTL source was written, but its extension manifest could not be recorded: "
                              ^ message;
                            changed = true;
                            revision = None;
                          }
                    | Ok revision ->
                        Handled
                          {
                            message =
                              Printf.sprintf
                                "Created local CENTL function %s.\nSource: %s\nWorkspace revision: %d\nAssurance: locally tested extension (not verified core)."
                                name path revision;
                            changed = true;
                            revision = Some revision;
                          }
                    end
                  with
                  | Sys_error message | Unix.Unix_error (_, _, message) ->
                      Handled
                        {
                          message = "Could not write the local extension: " ^ message;
                          changed = false;
                          revision = None;
                        }
                end
          | Centl_parser.Define_value (name, _) ->
              Handled
                {
                  message =
                    Printf.sprintf
                      "%s is a value definition, not a function definition. Use `create value %s = ...` for that extension class."
                      source name;
                  changed = false;
                  revision = None;
                }
          | Centl_parser.Evaluate _ | Centl_parser.Assert _ ->
              Handled
                {
                  message =
                    "The proposed extension parses as an expression or assertion rather than a function definition.";
                  changed = false;
                  revision = None;
                }
          end)

let create_value ~replace source =
  workspace_result (fun workspace ->
      match Centl_parser.parse_statement_located source with
      | Error error ->
          Handled
            {
              message =
                Printf.sprintf
                  "I recognized a value-extension request, but the CENTL definition is invalid at byte %d: %s"
                  error.position error.message;
              changed = false;
              revision = None;
            }
      | Ok located ->
          begin match located.statement with
          | Centl_parser.Define_value (name, _) ->
              let path = Filename.concat workspace.modules_dir (name ^ ".centl") in
              if Sys.file_exists path && not replace then
                Handled
                  {
                    message =
                      Printf.sprintf
                        "Local value %s already exists at %s. Use a modification request rather than silently replacing it."
                        name path;
                    changed = false;
                    revision = None;
                  }
              else
                begin
                  try
                    Centl_sci_workspace.ensure workspace;
                    write_text_file path source;
                    begin match
                      Centl_sci_workspace.write_manifest workspace ~name
                        ~enabled:true ~assurance:Centl_sci_workspace.Locally_tested
                        ~source:("modules/" ^ name ^ ".centl")
                        ~summary:"Local CENTL value created through BUILD mode"
                    with
                    | Error message ->
                        Handled
                          {
                            message =
                              "The CENTL source was written, but its extension manifest could not be recorded: "
                              ^ message;
                            changed = true;
                            revision = None;
                          }
                    | Ok revision ->
                        Handled
                          {
                            message =
                              Printf.sprintf
                                "Created local CENTL value %s.\nSource: %s\nWorkspace revision: %d\nAssurance: locally tested extension (not verified core)."
                                name path revision;
                            changed = true;
                            revision = Some revision;
                          }
                    end
                  with
                  | Sys_error message | Unix.Unix_error (_, _, message) ->
                      Handled
                        {
                          message = "Could not write the local extension: " ^ message;
                          changed = false;
                          revision = None;
                        }
                end
          | Centl_parser.Define_function (name, _, _) ->
              Handled
                {
                  message =
                    Printf.sprintf
                      "%s is a function definition, not a value definition. Use `create function %s` instead."
                      source name;
                  changed = false;
                  revision = None;
                }
          | Centl_parser.Evaluate _ | Centl_parser.Assert _ ->
              Handled
                {
                  message =
                    "The proposed extension parses as an expression or assertion rather than a value definition.";
                  changed = false;
                  revision = None;
                }
          end)

let inspect_extension name =
  workspace_result (fun workspace ->
      match Centl_sci_extensions.read_manifest workspace name with
      | Error message ->
          Handled { message; changed = false; revision = None }
      | Ok manifest ->
          Handled
            {
              message = Centl_sci_extensions.render_manifest manifest;
              changed = false;
              revision = Some (Centl_sci_workspace.read_revision workspace);
            })

let set_extension_enabled name enabled =
  workspace_result (fun workspace ->
      match Centl_sci_extensions.set_enabled workspace name enabled with
      | Error message -> Handled { message; changed = false; revision = None }
      | Ok manifest ->
          Handled
            {
              message =
                Printf.sprintf "%s local extension %s.\n%s"
                  (if enabled then "Enabled" else "Disabled") name
                  (Centl_sci_extensions.render_manifest manifest);
              changed = true;
              revision = Some manifest.workspace_revision;
            })

let remove_extension name =
  workspace_result (fun workspace ->
      match Centl_sci_extensions.remove workspace name with
      | Error message -> Handled { message; changed = false; revision = None }
      | Ok revision ->
          Handled
            {
              message =
                Printf.sprintf
                  "Removed local extension %s from the active workspace and archived its files for recovery.\nWorkspace revision: %d"
                  name revision;
              changed = true;
              revision = Some revision;
            })

let render_plan input =
  let plan = Centl_sci_build_plan.plan input in
  Handled
    {
      message = Centl_sci_build_plan.render plan;
      changed = false;
      revision = None;
    }

let handle input =
  let trimmed = String.trim input in
  let lower = String.lowercase_ascii trimmed in
  if
    List.mem lower
      [
        "workspace";
        "show workspace";
        "inspect workspace";
        "show my workspace";
        "show me everything i've changed from upstream";
        "show me everything i’ve changed from upstream";
        ":changes";
      ]
  then
    workspace_result (fun workspace ->
        let extensions = Centl_sci_extensions.render_list workspace in
        Handled
          {
            message = Centl_sci_workspace.describe workspace ^ "\n\nLocal changes:\n" ^ extensions;
            changed = false;
            revision = Some (Centl_sci_workspace.read_revision workspace);
          })
  else if List.mem lower [ "extensions"; "list extensions"; "show extensions"; ":extensions" ] then
    workspace_result (fun workspace ->
        Handled
          {
            message = Centl_sci_extensions.render_list workspace;
            changed = false;
            revision = Some (Centl_sci_workspace.read_revision workspace);
          })
  else if List.mem lower [ "initialize workspace"; "init workspace"; "create workspace" ] then
    workspace_result (fun workspace ->
        try
          Centl_sci_workspace.ensure workspace;
          Handled
            {
              message =
                "Initialized local CENTL workspace.\n"
                ^ Centl_sci_workspace.describe workspace;
              changed = true;
              revision = Some (Centl_sci_workspace.read_revision workspace);
            }
        with Sys_error message | Unix.Unix_error (_, _, message) ->
          Handled
            {
              message = "Could not initialize the local workspace: " ^ message;
              changed = false;
              revision = None;
            })
  else
    match drop_prefix_ci "create function " trimmed with
    | Some source when source <> "" -> create_function ~replace:false source
    | _ ->
        begin match drop_prefix_ci "modify function " trimmed with
        | Some source when source <> "" -> create_function ~replace:true source
        | _ ->
            begin match drop_prefix_ci "create value " trimmed with
            | Some source when source <> "" -> create_value ~replace:false source
            | _ ->
                begin match drop_prefix_ci "modify value " trimmed with
                | Some source when source <> "" -> create_value ~replace:true source
                | _ ->
                    begin match drop_prefix_ci "inspect " trimmed with
                    | Some name when name <> "" -> inspect_extension name
                    | _ ->
                        begin match drop_prefix_ci "disable " trimmed with
                        | Some name when name <> "" -> set_extension_enabled name false
                        | _ ->
                            begin match drop_prefix_ci "enable " trimmed with
                            | Some name when name <> "" -> set_extension_enabled name true
                            | _ ->
                                begin match drop_prefix_ci "remove " trimmed with
                                | Some name when name <> "" -> remove_extension name
                                | _ ->
                                    if trimmed = "" then Not_handled
                                    else render_plan trimmed
                                end
                            end
                        end
                    end
                end
            end
        end
