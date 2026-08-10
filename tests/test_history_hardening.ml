let fail = Alcotest.fail

let remove_tree path =
  let rec remove path =
    match (Unix.lstat path).st_kind with
    | Unix.S_DIR ->
        Sys.readdir path
        |> Array.iter (fun child -> remove (Filename.concat path child));
        Unix.rmdir path
    | _ -> Unix.unlink path
  in
  try remove path with Unix.Unix_error (Unix.ENOENT, _, _) -> ()

let with_temp_directory action =
  let path = Filename.temp_file "centl-history-hardening-" "" in
  Unix.unlink path;
  Unix.mkdir path 0o700;
  Fun.protect ~finally:(fun () -> remove_tree path) (fun () -> action path)

let history_path root =
  Filename.concat (Filename.concat root "centl") "history.json"

let check_entries label expected history =
  Alcotest.(check (list string)) label expected (Centl_history.entries history)

let write_file path contents =
  let channel = open_out_bin path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel contents)

let read_file path =
  let channel = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr channel)
    (fun () -> really_input_string channel (in_channel_length channel))

let symlinked_history_directory_is_not_followed () =
  if Sys.win32 then ()
  else
    with_temp_directory (fun root ->
        let target = Filename.concat root "target" in
        Unix.mkdir target 0o700;
        let link = Filename.concat root "centl" in
        Unix.symlink target link;
        let path = history_path root in
        let history = Centl_history.create ~path () in
        Centl_history.add history "local-only";
        check_entries "symlinked directory keeps local history usable"
          [ "local-only" ] history;
        Alcotest.(check bool)
          "symlinked directory target is not written" false
          (Sys.file_exists (Filename.concat target "history.json")))

let symlinked_history_file_is_not_imported_or_followed () =
  if Sys.win32 then ()
  else
    with_temp_directory (fun root ->
        let directory = Filename.concat root "centl" in
        Unix.mkdir directory 0o700;
        let target = Filename.concat root "target-history.json" in
        let target_contents =
          "{\"version\":1,\"entries\":[\"must-not-import\"]}\n"
        in
        write_file target target_contents;
        Unix.chmod target 0o600;
        let path = history_path root in
        Unix.symlink target path;
        let history = Centl_history.create ~path () in
        check_entries "symlinked history file is not imported" [] history;
        Centl_history.add history "safe";
        check_entries "local append remains usable" [ "safe" ] history;
        Alcotest.(check string)
          "symlink target remains unchanged" target_contents (read_file target);
        Alcotest.(check bool)
          "history path is replaced by a regular file" true
          ((Unix.lstat path).st_kind = Unix.S_REG);
        check_entries "replacement contains only safe local history" [ "safe" ]
          (Centl_history.create ~path ()))

let symlinked_history_lock_is_not_followed () =
  if Sys.win32 then ()
  else
    with_temp_directory (fun root ->
        let directory = Filename.concat root "centl" in
        Unix.mkdir directory 0o700;
        let target = Filename.concat root "lock-target" in
        write_file target "sentinel\n";
        Unix.chmod target 0o644;
        let lock_path = Filename.concat directory "history.lock" in
        Unix.symlink target lock_path;
        let path = history_path root in
        let history = Centl_history.create ~path () in
        Centl_history.add history "local-only";
        check_entries "symlinked lock keeps local history usable" [ "local-only" ]
          history;
        Alcotest.(check bool)
          "history persistence is refused when lock is a symlink" false
          (Sys.file_exists path);
        Alcotest.(check int)
          "lock symlink target permissions are not changed" 0o644
          ((Unix.stat target).st_perm land 0o777))

let unsafe_history_directory_is_not_used () =
  if Sys.win32 then ()
  else
    with_temp_directory (fun root ->
        let directory = Filename.concat root "shared-state" in
        Unix.mkdir directory 0o700;
        Unix.chmod directory 0o770;
        let path = Filename.concat directory "history.json" in
        let history = Centl_history.create ~path () in
        Centl_history.add history "local-only";
        check_entries "unsafe directory keeps local history usable" [ "local-only" ]
          history;
        Alcotest.(check bool)
          "group-writable history directory is not persisted into" false
          (Sys.file_exists path))

let run_tests () =
  Alcotest.run "centl durable history hardening"
    [
      ( "filesystem boundaries",
        [
          Alcotest.test_case "symlinked history directory" `Quick
            symlinked_history_directory_is_not_followed;
          Alcotest.test_case "symlinked history file" `Quick
            symlinked_history_file_is_not_imported_or_followed;
          Alcotest.test_case "symlinked history lock" `Quick
            symlinked_history_lock_is_not_followed;
          Alcotest.test_case "unsafe history directory" `Quick
            unsafe_history_directory_is_not_used;
        ] );
    ]

let () =
  try run_tests ()
  with exn ->
    fail (Printexc.to_string exn)
