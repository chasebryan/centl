type handled = { message : string; changed : bool; revision : int option }
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
            "CENTL-SCi cannot determine a local workspace because HOME is \
             unavailable. Set CENTL_WORKSPACE to an explicit directory.";
          changed = false;
          revision = None;
        }
  | Some workspace -> action workspace

let write_text_file path text =
  let temporary = path ^ ".tmp" in
  let channel =
    open_out_gen
      [ Open_wronly; Open_creat; Open_trunc; Open_text ]
      0o600 temporary
  in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () ->
      output_string channel text;
      if text = "" || text.[String.length text - 1] <> '\n' then
        output_char channel '\n';
      flush channel);
  Unix.rename temporary path

let snapshot_or_message workspace action =
  match Centl_sci_snapshot.create workspace with
  | Ok _ -> action ()
  | Error message ->
      Handled
        {
          message =
            "Could not create the reversible workspace snapshot: " ^ message;
          changed = false;
          revision = None;
        }

let create_function ~replace source =
  workspace_result (fun workspace ->
      match Centl_parser.parse_statement_located source with
      | Error error ->
          Handled
            {
              message =
                Printf.sprintf
                  "I recognized a function-extension request, but the \
                   generated CENTL definition is invalid at byte %d: %s"
                  error.position error.message;
              changed = false;
              revision = None;
            }
      | Ok located ->
          begin match located.statement with
          | Centl_parser.Define_function (name, _, _) ->
              let path =
                Filename.concat workspace.modules_dir (name ^ ".centl")
              in
              if Sys.file_exists path && not replace then
                Handled
                  {
                    message =
                      Printf.sprintf
                        "Local function %s already exists at %s. Use a \
                         modification request rather than silently replacing \
                         it."
                        name path;
                    changed = false;
                    revision = None;
                  }
              else
                snapshot_or_message workspace (fun () ->
                    try
                      Centl_sci_workspace.ensure workspace;
                      write_text_file path source;
                      begin match
                        Centl_sci_workspace.write_manifest workspace ~name
                          ~enabled:true
                          ~assurance:Centl_sci_workspace.Locally_tested
                          ~source:("modules/" ^ name ^ ".centl")
                          ~summary:
                            "Local CENTL function created through BUILD mode"
                      with
                      | Error message ->
                          Handled
                            {
                              message =
                                "The CENTL source was written, but its \
                                 extension manifest could not be recorded: "
                                ^ message;
                              changed = true;
                              revision = None;
                            }
                      | Ok revision ->
                          Handled
                            {
                              message =
                                Printf.sprintf
                                  "Created local CENTL function %s.\n\
                                   Generated/validated source: %s\n\
                                   Source file: %s\n\
                                   Workspace revision: %d\n\
                                   Assurance: locally tested extension (not \
                                   verified core).\n\
                                   The extension is enabled and will be loaded \
                                   into the active downstream CENTL session."
                                  name source path revision;
                              changed = true;
                              revision = Some revision;
                            }
                      end
                    with
                    | Sys_error message | Unix.Unix_error (_, _, message) ->
                      Handled
                        {
                          message =
                            "Could not write the local extension: " ^ message;
                          changed = false;
                          revision = None;
                        })
          | Centl_parser.Define_value (name, _) ->
              Handled
                {
                  message =
                    Printf.sprintf
                      "%s is a value definition, not a function definition. \
                       Use `create value %s = ...` for that extension class."
                      source name;
                  changed = false;
                  revision = None;
                }
          | Centl_parser.Evaluate _ | Centl_parser.Assert _ ->
              Handled
                {
                  message =
                    "The proposed extension parses as an expression or \
                     assertion rather than a function definition.";
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
                  "I recognized a value-extension request, but the CENTL \
                   definition is invalid at byte %d: %s"
                  error.position error.message;
              changed = false;
              revision = None;
            }
      | Ok located ->
          begin match located.statement with
          | Centl_parser.Define_value (name, _) ->
              let path =
                Filename.concat workspace.modules_dir (name ^ ".centl")
              in
              if Sys.file_exists path && not replace then
                Handled
                  {
                    message =
                      Printf.sprintf
                        "Local value %s already exists at %s. Use a \
                         modification request rather than silently replacing \
                         it."
                        name path;
                    changed = false;
                    revision = None;
                  }
              else
                snapshot_or_message workspace (fun () ->
                    try
                      Centl_sci_workspace.ensure workspace;
                      write_text_file path source;
                      begin match
                        Centl_sci_workspace.write_manifest workspace ~name
                          ~enabled:true
                          ~assurance:Centl_sci_workspace.Locally_tested
                          ~source:("modules/" ^ name ^ ".centl")
                          ~summary:
                            "Local CENTL value created through BUILD mode"
                      with
                      | Error message ->
                          Handled
                            {
                              message =
                                "The CENTL source was written, but its \
                                 extension manifest could not be recorded: "
                                ^ message;
                              changed = true;
                              revision = None;
                            }
                      | Ok revision ->
                          Handled
                            {
                              message =
                                Printf.sprintf
                                  "Created local CENTL value %s.\n\
                                   Generated/validated source: %s\n\
                                   Source file: %s\n\
                                   Workspace revision: %d\n\
                                   Assurance: locally tested extension (not \
                                   verified core).\n\
                                   The extension is enabled and will be loaded \
                                   into the active downstream CENTL session."
                                  name source path revision;
                              changed = true;
                              revision = Some revision;
                            }
                      end
                    with
                    | Sys_error message | Unix.Unix_error (_, _, message) ->
                      Handled
                        {
                          message =
                            "Could not write the local extension: " ^ message;
                          changed = false;
                          revision = None;
                        })
          | Centl_parser.Define_function (name, _, _) ->
              Handled
                {
                  message =
                    Printf.sprintf
                      "%s is a function definition, not a value definition. \
                       Use `create function %s` instead."
                      source name;
                  changed = false;
                  revision = None;
                }
          | Centl_parser.Evaluate _ | Centl_parser.Assert _ ->
              Handled
                {
                  message =
                    "The proposed extension parses as an expression or \
                     assertion rather than a value definition.";
                  changed = false;
                  revision = None;
                }
          end)

let inspect_extension name =
  workspace_result (fun workspace ->
      match Centl_sci_extensions.read_manifest workspace name with
      | Error message -> Handled { message; changed = false; revision = None }
      | Ok manifest ->
          Handled
            {
              message = Centl_sci_extensions.render_manifest manifest;
              changed = false;
              revision = Some (Centl_sci_workspace.read_revision workspace);
            })

let set_extension_enabled name enabled =
  workspace_result (fun workspace ->
      snapshot_or_message workspace (fun () ->
          match Centl_sci_extensions.set_enabled workspace name enabled with
          | Error message ->
              Handled { message; changed = false; revision = None }
          | Ok manifest ->
              Handled
                {
                  message =
                    Printf.sprintf "%s local extension %s.\n%s"
                      (if enabled then "Enabled" else "Disabled")
                      name
                      (Centl_sci_extensions.render_manifest manifest);
                  changed = true;
                  revision = Some manifest.workspace_revision;
                }))

let remove_extension name =
  workspace_result (fun workspace ->
      snapshot_or_message workspace (fun () ->
          match Centl_sci_extensions.remove workspace name with
          | Error message ->
              Handled { message; changed = false; revision = None }
          | Ok revision ->
              Handled
                {
                  message =
                    Printf.sprintf
                      "Removed local extension %s from the active workspace \
                       and archived its files for recovery.\n\
                       Workspace revision: %d\n\
                       Use `undo` to restore the immediately previous \
                       workspace snapshot."
                      name revision;
                  changed = true;
                  revision = Some revision;
                }))

let undo () =
  workspace_result (fun workspace ->
      match Centl_sci_snapshot.restore_last workspace with
      | Error message -> Handled { message; changed = false; revision = None }
      | Ok revision ->
          Handled
            {
              message =
                Printf.sprintf
                  "Restored the previous local workspace snapshot.\n\
                   Workspace revision: %d\n\
                   Enabled extensions will be reloaded into the active \
                   downstream session."
                  revision;
              changed = true;
              revision = Some revision;
            })

let create_package name =
  workspace_result (fun workspace ->
      snapshot_or_message workspace (fun () ->
          match
            Centl_sci_package.create workspace ~name
              ~summary:"Local CENTL package created through BUILD mode"
          with
          | Error message ->
              Handled { message; changed = false; revision = None }
          | Ok package ->
              Handled
                {
                  message =
                    Centl_sci_package.render package
                    ^ "\n\
                       Packages group downstream extensions; they do not \
                       change extension assurance.";
                  changed = true;
                  revision = Some package.workspace_revision;
                }))

let list_packages () =
  workspace_result (fun workspace ->
      Handled
        {
          message = Centl_sci_package.render_list workspace;
          changed = false;
          revision = Some (Centl_sci_workspace.read_revision workspace);
        })

let show_package name =
  workspace_result (fun workspace ->
      match Centl_sci_package.read workspace name with
      | Error message -> Handled { message; changed = false; revision = None }
      | Ok package ->
          Handled
            {
              message = Centl_sci_package.render package;
              changed = false;
              revision = Some package.workspace_revision;
            })

let add_extension_to_package ~extension_name ~package_name =
  workspace_result (fun workspace ->
      snapshot_or_message workspace (fun () ->
          match
            Centl_sci_package.add_extension workspace ~package_name
              ~extension_name
          with
          | Error message ->
              Handled { message; changed = false; revision = None }
          | Ok package ->
              Handled
                {
                  message =
                    Centl_sci_package.render package
                    ^ "\n\
                       Package membership does not promote or alter the \
                       extension's assurance level.";
                  changed = true;
                  revision = Some package.workspace_revision;
                }))

let parse_package_membership rest =
  let lower = String.lowercase_ascii rest in
  match Centl_sci_interaction.find_substring ~needle:" to package " lower with
  | None -> None
  | Some index ->
      let extension_name = String.sub rest 0 index |> String.trim in
      let package_name =
        String.sub rest (index + 12) (String.length rest - index - 12)
        |> String.trim
      in
      if extension_name = "" || package_name = "" then None
      else Some (extension_name, package_name)

let split_name_target text =
  match String.index_opt text ' ' with
  | None -> None
  | Some index ->
      let name = String.sub text 0 index |> String.trim in
      let target =
        String.sub text (index + 1) (String.length text - index - 1)
        |> String.trim
      in
      if name = "" || target = "" then None else Some (name, target)

let scaffold kind rest =
  match split_name_target rest with
  | None ->
      Handled
        {
          message =
            "A scaffold needs a local name and a target. Example: `scaffold \
             python adapter telescope_reader astropy`.";
          changed = false;
          revision = None;
        }
  | Some (name, target) ->
      workspace_result (fun workspace ->
          snapshot_or_message workspace (fun () ->
              match Centl_sci_scaffold.create workspace ~kind ~name ~target with
              | Error message ->
                  Handled { message; changed = false; revision = None }
              | Ok (root, revision) ->
                  Handled
                    {
                      message =
                        Printf.sprintf
                          "Created inactive %s scaffold %s.\n\
                           Target: %s\n\
                           Path: %s\n\
                           Workspace revision: %d\n\
                           The scaffold is intentionally not activated or \
                           represented as verified core."
                          (match kind with
                          | Centl_sci_scaffold.Python_adapter ->
                              "Python adapter"
                          | Centl_sci_scaffold.Native_extension ->
                              "native extension")
                          name target root revision;
                      changed = true;
                      revision = Some revision;
                    }))

let prepare_upstream () =
  workspace_result (fun workspace ->
      match Centl_sci_scaffold.prepare_upstream workspace with
      | Error message -> Handled { message; changed = false; revision = None }
      | Ok path ->
          Handled
            {
              message =
                "Prepared a local upstream-contribution review artifact.\n\
                 Path: " ^ path
                ^ "\nNo branch, commit, push, or publication was performed.";
              changed = false;
              revision = Some (Centl_sci_workspace.read_revision workspace);
            })

let portable_command command =
  workspace_result (fun workspace ->
      match Centl_sci_portable.execute workspace command with
      | Error message -> Handled { message; changed = false; revision = None }
      | Ok result ->
          Handled
            {
              message = result.Centl_sci_portable.message;
              changed = result.changed;
              revision = result.revision;
            })

let render_plan input =
  let plan = Centl_sci_build_plan.plan input in
  Handled
    {
      message = Centl_sci_build_plan.render plan;
      changed = false;
      revision = None;
    }

let generated_change input =
  match Centl_sci_codegen.generate input with
  | Centl_sci_codegen.Not_generated -> None
  | Centl_sci_codegen.Needs_clarification message ->
      Some (Handled { message; changed = false; revision = None })
  | Centl_sci_codegen.Generated (Centl_sci_codegen.Function { replace; source })
    ->
      Some (create_function ~replace source)
  | Centl_sci_codegen.Generated (Centl_sci_codegen.Value { replace; source }) ->
      Some (create_value ~replace source)

let handle_direct trimmed lower =
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
        let packages = Centl_sci_package.render_list workspace in
        Handled
          {
            message =
              Centl_sci_workspace.describe workspace
              ^ "\n\nLocal extensions:\n" ^ extensions ^ "\n\nLocal packages:\n"
              ^ packages;
            changed = false;
            revision = Some (Centl_sci_workspace.read_revision workspace);
          })
  else if
    List.mem lower
      [ "extensions"; "list extensions"; "show extensions"; ":extensions" ]
  then
    workspace_result (fun workspace ->
        Handled
          {
            message = Centl_sci_extensions.render_list workspace;
            changed = false;
            revision = Some (Centl_sci_workspace.read_revision workspace);
          })
  else if
    List.mem lower [ "packages"; "list packages"; "show packages"; ":packages" ]
  then list_packages ()
  else if
    List.mem lower
      [ "initialize workspace"; "init workspace"; "create workspace" ]
  then
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
  else if List.mem lower [ "undo"; "undo last change"; "undo the last change" ]
  then undo ()
  else if
    List.mem lower
      [
        "prepare upstream contribution";
        "prepare this extension for upstream contribution";
        "prepare changes for upstream contribution";
      ]
  then prepare_upstream ()
  else
    match Centl_sci_portable.parse trimmed with
    | Some command -> portable_command command
    | None ->
        begin match drop_prefix_ci "create package " trimmed with
        | Some name when name <> "" -> create_package name
        | _ ->
            begin match drop_prefix_ci "show package " trimmed with
            | Some name when name <> "" -> show_package name
            | _ ->
                begin match drop_prefix_ci "add extension " trimmed with
                | Some rest when rest <> "" ->
                    begin match parse_package_membership rest with
                    | Some (extension_name, package_name) ->
                        add_extension_to_package ~extension_name ~package_name
                    | None ->
                        Handled
                          {
                            message =
                              "Package composition syntax: `add extension \
                               EXTENSION to package PACKAGE`.";
                            changed = false;
                            revision = None;
                          }
                    end
                | _ ->
                    begin match
                      drop_prefix_ci "scaffold python adapter " trimmed
                    with
                    | Some rest when rest <> "" ->
                        scaffold Centl_sci_scaffold.Python_adapter rest
                    | _ ->
                        begin match
                          drop_prefix_ci "scaffold native extension " trimmed
                        with
                        | Some rest when rest <> "" ->
                            scaffold Centl_sci_scaffold.Native_extension rest
                        | _ ->
                            begin match
                              drop_prefix_ci "create function " trimmed
                            with
                            | Some source when source <> "" ->
                                create_function ~replace:false source
                            | _ ->
                                begin match
                                  drop_prefix_ci "modify function " trimmed
                                with
                                | Some source when source <> "" ->
                                    create_function ~replace:true source
                                | _ ->
                                    begin match
                                      drop_prefix_ci "create value " trimmed
                                    with
                                    | Some source when source <> "" ->
                                        create_value ~replace:false source
                                    | _ ->
                                        begin match
                                          drop_prefix_ci "modify value " trimmed
                                        with
                                        | Some source when source <> "" ->
                                            create_value ~replace:true source
                                        | _ ->
                                            begin match
                                              drop_prefix_ci "inspect " trimmed
                                            with
                                            | Some name when name <> "" ->
                                                inspect_extension name
                                            | _ ->
                                                begin match
                                                  drop_prefix_ci "disable "
                                                    trimmed
                                                with
                                                | Some name when name <> "" ->
                                                    set_extension_enabled name
                                                      false
                                                | _ ->
                                                    begin match
                                                      drop_prefix_ci "enable "
                                                        trimmed
                                                    with
                                                    | Some name when name <> ""
                                                      ->
                                                        set_extension_enabled
                                                          name true
                                                    | _ ->
                                                        begin match
                                                          drop_prefix_ci
                                                            "remove " trimmed
                                                        with
                                                        | Some name
                                                          when name <> "" ->
                                                            remove_extension
                                                              name
                                                        | _ ->
                                                            if trimmed = "" then
                                                              Not_handled
                                                            else
                                                              render_plan
                                                                trimmed
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

let handle input =
  let trimmed = String.trim input in
  let lower = String.lowercase_ascii trimmed in
  match generated_change trimmed with
  | Some result -> result
  | None -> handle_direct trimmed lower
