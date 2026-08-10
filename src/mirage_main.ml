let usage () =
  String.concat "\n"
    [
      "Usage:";
      "  centl-mirage ingest PATH";
      "  centl-mirage status";
      "";
      "CENTL-MIRAGE is the local self-development engine for CENTL-SCi.";
    ]

let workspace_or_exit () =
  match Centl_sci_workspace.default () with
  | Some workspace -> workspace
  | None ->
      prerr_endline
        "centl-mirage: no local workspace is available; set CENTL_WORKSPACE or HOME";
      exit 2

let ingest path =
  let workspace = workspace_or_exit () in
  match Centl_sci_mirage.ingest workspace path with
  | Ok result ->
      print_endline (Centl_sci_mirage.render_ingest result);
      exit 0
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let status () =
  let workspace = workspace_or_exit () in
  print_endline (Centl_sci_mirage.status workspace)

let main () =
  match Array.to_list Sys.argv with
  | [ _; "status" ] -> status ()
  | _ :: "ingest" :: path_parts when path_parts <> [] ->
      ingest (String.concat " " path_parts)
  | [ _; "--version" ] -> print_endline "CENTL-MIRAGE development bootstrap"
  | _ ->
      prerr_endline (usage ());
      exit 2

let () = main ()
