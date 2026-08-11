let lstat path =
  try Some (Unix.lstat path)
  with Unix.Unix_error (Unix.ENOENT, _, _) -> None

let require_real_directory path =
  match lstat path with
  | Some stat when stat.Unix.st_kind = Unix.S_DIR -> ()
  | Some stat when stat.Unix.st_kind = Unix.S_LNK ->
      raise (Sys_error ("refusing symlinked workspace directory: " ^ path))
  | Some _ -> raise (Sys_error ("workspace path is not a directory: " ^ path))
  | None -> raise (Sys_error ("workspace directory is unavailable: " ^ path))

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
  require_real_directory workspace.Centl_sci_workspace.config;
  let target = pointer_path workspace in
  let temporary, channel =
    Filename.open_temp_file ~temp_dir:(Filename.dirname target) "undo-snapshot-" ".tmp"
  in
  Unix.chmod temporary 0o600;
  try
    Fun.protect
      ~finally:(fun () -> close_out_noerr channel)
      (fun () ->
        output_string channel (path ^ "\n");
        flush channel);
    Unix.rename temporary target
  with exn ->
    (try Sys.remove temporary with Sys_error _ -> ());
    raise exn

let read_pointer workspace =
  let path = pointer_path workspace in
  match lstat path with
  | None -> None
  | Some stat when stat.Unix.st_kind = Unix.S_REG ->
      begin
        try
          let channel = open_in path in
          Fun.protect
            ~finally:(fun () -> close_in_noerr channel)
            (fun () -> Some (input_line channel |> String.trim))
        with Sys_error _ | End_of_file -> None
      end
  | Some _ -> None

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

let ensure_snapshot_root workspace =
  require_real_directory workspace.Centl_sci_workspace.generated;
  let root = snapshot_root workspace in
  begin match lstat root with
  | None -> Unix.mkdir root 0o700
  | Some stat when stat.Unix.st_kind = Unix.S_DIR -> ()
  | Some stat when stat.Unix.st_kind = Unix.S_LNK ->
      raise (Sys_error ("refusing symlinked snapshot root: " ^ root))
  | Some _ -> raise (Sys_error ("snapshot root is not a directory: " ^ root))
  end;
  root

let rec create_snapshot_directory root revision stamp attempt =
  let path =
    Filename.concat root
      (Printf.sprintf "r%d-%Ld-%d" revision stamp attempt)
  in
  try
    Unix.mkdir path 0o700;
    path
  with
  | Unix.Unix_error (Unix.EEXIST, _, _) ->
      create_snapshot_directory root revision stamp (attempt + 1)

let owned_snapshot_path workspace path =
  if path = "" then false
  else
    let root = snapshot_root workspace in
    let basename = Filename.basename path in
    Filename.dirname path = root && basename <> "." && basename <> ".."

let prune_other_snapshots root keep =
  Sys.readdir root
  |> Array.iter (fun name ->
         let path = Filename.concat root name in
         if path <> keep then
           try remove_tree path
           with Sys_error _ | Unix.Unix_error (_, _, _) -> ())

let create workspace =
  try
    Centl_sci_workspace.ensure workspace;
    let root = ensure_snapshot_root workspace in
    let stamp = Int64.of_float (Unix.gettimeofday () *. 1_000_000.) in
    let path =
      create_snapshot_directory root (Centl_sci_workspace.read_revision workspace)
        stamp 0
    in
    begin
      try copy_workspace_surface workspace path
      with exn ->
        (try remove_tree path with _ -> ());
        raise exn
    end;
    write_pointer workspace path;
    (* Undo is intentionally one-level. Once the new snapshot is durable and
       pointed to, older snapshot directories are no longer reachable through
       the product surface and are pruned to keep repeated BUILD/MIRAGE cycles
       from accumulating duplicate workspace copies indefinitely. *)
    prune_other_snapshots root path;
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
  if not (owned_snapshot_path workspace path) then
    Error "workspace rollback snapshot path is outside the managed snapshot root"
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
  | Some path when not (owned_snapshot_path workspace path) ->
      Error "the recorded workspace snapshot path is outside the managed snapshot root"
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