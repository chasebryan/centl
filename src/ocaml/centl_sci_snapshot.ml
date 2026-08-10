let copy_file source target =
  let input = open_in_bin source in
  let output = open_out_bin target in
  Fun.protect
    ~finally:(fun () -> close_in_noerr input; close_out_noerr output)
    (fun () ->
      let buffer = Bytes.create 8192 in
      let rec loop () =
        match input input buffer 0 (Bytes.length buffer) with
        | 0 -> ()
        | count -> output output buffer 0 count; loop ()
      in
      loop ())

let regular_files directory =
  if not (Sys.file_exists directory) || not (Sys.is_directory directory) then []
  else
    Sys.readdir directory
    |> Array.to_list
    |> List.filter (fun name ->
           let path = Filename.concat directory name in
           Sys.file_exists path && not (Sys.is_directory path))

let copy_directory source target =
  Centl_sci_workspace.ensure_directory target;
  regular_files source
  |> List.iter (fun name ->
         copy_file (Filename.concat source name) (Filename.concat target name))

let remove_regular_files directory =
  regular_files directory
  |> List.iter (fun name -> Sys.remove (Filename.concat directory name))

let pointer_path workspace = Filename.concat workspace.Centl_sci_workspace.config "undo_snapshot"

let snapshot_root workspace = Filename.concat workspace.Centl_sci_workspace.generated "snapshots"

let write_pointer workspace path =
  let target = pointer_path workspace in
  let temporary = target ^ ".tmp" in
  let channel = open_out temporary in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel (path ^ "\n"));
  Unix.rename temporary target

let read_pointer workspace =
  try
    let channel = open_in (pointer_path workspace) in
    Fun.protect
      ~finally:(fun () -> close_in_noerr channel)
      (fun () -> Some (input_line channel |> String.trim))
  with Sys_error _ | End_of_file -> None

let create workspace =
  try
    Centl_sci_workspace.ensure workspace;
    let root = snapshot_root workspace in
    Centl_sci_workspace.ensure_directory root;
    let stamp = Int64.of_float (Unix.gettimeofday () *. 1_000_000.) in
    let path =
      Filename.concat root
        (Printf.sprintf "r%d-%Ld" (Centl_sci_workspace.read_revision workspace) stamp)
    in
    Centl_sci_workspace.ensure_directory path;
    copy_directory workspace.extensions (Filename.concat path "extensions");
    copy_directory workspace.modules_dir (Filename.concat path "modules");
    write_pointer workspace path;
    Ok path
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let restore_last workspace =
  match read_pointer workspace with
  | None -> Error "no reversible workspace snapshot is available"
  | Some path when path = "" || not (Sys.file_exists path) ->
      Error "the recorded workspace snapshot is unavailable"
  | Some path ->
      try
        Centl_sci_workspace.ensure workspace;
        remove_regular_files workspace.extensions;
        remove_regular_files workspace.modules_dir;
        copy_directory (Filename.concat path "extensions") workspace.extensions;
        copy_directory (Filename.concat path "modules") workspace.modules_dir;
        let revision = Centl_sci_workspace.bump_revision workspace in
        Sys.remove (pointer_path workspace);
        Ok revision
      with Sys_error message | Unix.Unix_error (_, _, message) -> Error message
