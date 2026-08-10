let lstat path =
  try Some (Unix.lstat path)
  with Unix.Unix_error (Unix.ENOENT, _, _) -> None

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
  match lstat source with
  | None -> ()
  | Some stat ->
      begin match stat.Unix.st_kind with
      | Unix.S_REG ->
          Centl_sci_workspace.ensure_directory (Filename.dirname target);
          copy_file source target
      | Unix.S_DIR ->
          Centl_sci_workspace.ensure_directory target;
          Sys.readdir source
          |> Array.iter (fun name ->
                 copy_tree (Filename.concat source name) (Filename.concat target name))
      | Unix.S_LNK ->
          raise (Sys_error ("refusing to copy symlinked workspace state: " ^ source))
      | _ ->
          raise
            (Sys_error
               ("refusing to copy unsupported workspace filesystem object: " ^ source))
      end

let rec remove_tree path =
  match lstat path with
  | None -> ()
  | Some stat ->
      begin match stat.Unix.st_kind with
      | Unix.S_DIR ->
          Sys.readdir path
          |> Array.iter (fun name -> remove_tree (Filename.concat path name));
          Unix.rmdir path
      | Unix.S_REG | Unix.S_LNK -> Sys.remove path
      | _ ->
          raise
            (Sys_error
               ("refusing to remove unsupported workspace filesystem object: " ^ path))
      end

let clear_directory directory =
  match lstat directory with
  | None -> Centl_sci_workspace.ensure_directory directory
  | Some stat ->
      begin match stat.Unix.st_kind with
      | Unix.S_DIR ->
          Sys.readdir directory
          |> Array.iter (fun name -> remove_tree (Filename.concat directory name))
      | Unix.S_LNK ->
          raise (Sys_error ("refusing to traverse symlinked workspace directory: " ^ directory))
      | _ ->
          raise (Sys_error ("workspace path is not a directory: " ^ directory))
      end

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

let clear_pointer_if workspace expected =
  match read_pointer workspace with
  | Some path when path = expected ->
      begin
        try Sys.remove (pointer_path workspace)
        with Sys_error _ -> ()
      end
  | _ -> ()

let copy_workspace_surface workspace path =
  copy_tree workspace.Centl_sci_workspace.extensions
    (Filename.concat path "extensions");
  copy_tree workspace.modules_dir (Filename.concat path "modules");
  copy_tree workspace.packages (Filename.concat path "packages");
  copy_tree workspace.tests (Filename.concat path "tests");
  copy_tree workspace.data (Filename.concat path "data");
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
  clear_directory workspace.tests;
  clear_directory workspace.data;
  clear_directory (scaffolds_root workspace);
  copy_tree (Filename.concat path "extensions") workspace.extensions;
  copy_tree (Filename.concat path "modules") workspace.modules_dir;
  copy_tree (Filename.concat path "packages") workspace.packages;
  copy_tree (Filename.concat path "tests") workspace.tests;
  copy_tree (Filename.concat path "data") workspace.data;
  copy_tree (Filename.concat path "generated-scaffolds")
    (scaffolds_root workspace)

let rollback workspace path =
  if path = "" then Error "workspace rollback snapshot path is empty"
  else
    match lstat path with
    | None -> Error "the workspace rollback snapshot is unavailable"
    | Some stat when stat.Unix.st_kind <> Unix.S_DIR ->
        Error "the workspace rollback snapshot is not a directory"
    | Some _ ->
        try
          Centl_sci_workspace.ensure workspace;
          restore_surface workspace path;
          clear_pointer_if workspace path;
          Ok (Centl_sci_workspace.read_revision workspace)
        with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let restore_last workspace =
  match read_pointer workspace with
  | None -> Error "no reversible workspace snapshot is available"
  | Some path when path = "" -> Error "the recorded workspace snapshot is unavailable"
  | Some path ->
      begin match lstat path with
      | None -> Error "the recorded workspace snapshot is unavailable"
      | Some stat when stat.Unix.st_kind <> Unix.S_DIR ->
          Error "the recorded workspace snapshot is not a directory"
      | Some _ ->
          try
            Centl_sci_workspace.ensure workspace;
            restore_surface workspace path;
            let revision = Centl_sci_workspace.bump_revision workspace in
            clear_pointer_if workspace path;
            Ok revision
          with Sys_error message | Unix.Unix_error (_, _, message) -> Error message
      end
