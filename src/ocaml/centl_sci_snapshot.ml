let copy_file source target =
  let input_channel = open_in_bin source in
  let output_channel = open_out_bin target in
  Fun.protect
    ~finally:(fun () ->
      close_in_noerr input_channel;
      close_out_noerr output_channel)
    (fun () ->
      let buffer = Bytes.create 8192 in
      let rec loop () =
        match input input_channel buffer 0 (Bytes.length buffer) with
        | 0 -> ()
        | count ->
            output output_channel buffer 0 count;
            loop ()
      in
      loop ())

let rec copy_tree source target =
  if not (Sys.file_exists source) then ()
  else if Sys.is_directory source then begin
    Centl_sci_workspace.ensure_directory target;
    Sys.readdir source
    |> Array.iter (fun name ->
           copy_tree (Filename.concat source name) (Filename.concat target name))
  end
  else begin
    Centl_sci_workspace.ensure_directory (Filename.dirname target);
    copy_file source target
  end

let rec remove_tree path =
  if not (Sys.file_exists path) then ()
  else if Sys.is_directory path then begin
    Sys.readdir path
    |> Array.iter (fun name -> remove_tree (Filename.concat path name));
    Unix.rmdir path
  end
  else Sys.remove path

let clear_directory directory =
  if Sys.file_exists directory && Sys.is_directory directory then
    Sys.readdir directory
    |> Array.iter (fun name -> remove_tree (Filename.concat directory name))
  else Centl_sci_workspace.ensure_directory directory

let pointer_path workspace =
  Filename.concat workspace.Centl_sci_workspace.config "undo_snapshot"

let snapshot_root workspace =
  Filename.concat workspace.Centl_sci_workspace.generated "snapshots"

let scaffolds_root workspace =
  Filename.concat workspace.Centl_sci_workspace.generated "scaffolds"

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

let copy_workspace_surface workspace path =
  copy_tree workspace.Centl_sci_workspace.extensions
    (Filename.concat path "extensions");
  copy_tree workspace.modules_dir (Filename.concat path "modules");
  copy_tree workspace.packages (Filename.concat path "packages");
  copy_tree (scaffolds_root workspace)
    (Filename.concat path "generated-scaffolds")

let create workspace =
  try
    Centl_sci_workspace.ensure workspace;
    let root = snapshot_root workspace in
    Centl_sci_workspace.ensure_directory root;
    let stamp = Int64.of_float (Unix.gettimeofday () *. 1_000_000.) in
    let path =
      Filename.concat root
        (Printf.sprintf "r%d-%Ld" (Centl_sci_workspace.read_revision workspace)
           stamp)
    in
    Centl_sci_workspace.ensure_directory path;
    copy_workspace_surface workspace path;
    write_pointer workspace path;
    Ok path
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let restore_surface workspace path =
  clear_directory workspace.Centl_sci_workspace.extensions;
  clear_directory workspace.modules_dir;
  clear_directory workspace.packages;
  clear_directory (scaffolds_root workspace);
  copy_tree (Filename.concat path "extensions") workspace.extensions;
  copy_tree (Filename.concat path "modules") workspace.modules_dir;
  copy_tree (Filename.concat path "packages") workspace.packages;
  copy_tree (Filename.concat path "generated-scaffolds")
    (scaffolds_root workspace)

let restore_last workspace =
  match read_pointer workspace with
  | None -> Error "no reversible workspace snapshot is available"
  | Some path when path = "" || not (Sys.file_exists path) ->
      Error "the recorded workspace snapshot is unavailable"
  | Some path ->
      try
        Centl_sci_workspace.ensure workspace;
        restore_surface workspace path;
        let revision = Centl_sci_workspace.bump_revision workspace in
        Sys.remove (pointer_path workspace);
        Ok revision
      with Sys_error message | Unix.Unix_error (_, _, message) -> Error message
