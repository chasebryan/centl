let fail = Alcotest.fail
let environment bindings name = List.assoc_opt name bindings

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
  let path = Filename.temp_file "centl-history-" "" in
  Unix.unlink path;
  Unix.mkdir path 0o700;
  Fun.protect ~finally:(fun () -> remove_tree path) (fun () -> action path)

let history_path root =
  Filename.concat (Filename.concat root "centl") "history.json"

let check_entries label expected history =
  Alcotest.(check (list string)) label expected (Centl_history.entries history)

let path_selection () =
  let unix_environment =
    environment [ ("XDG_STATE_HOME", "/state"); ("HOME", "/home/me") ]
  in
  Alcotest.(check (option string))
    "XDG state path"
    (Some (history_path "/state"))
    (Centl_history.state_path ~win32:false unix_environment);
  let fallback_environment =
    environment [ ("XDG_STATE_HOME", "relative"); ("HOME", "/home/me") ]
  in
  Alcotest.(check (option string))
    "relative XDG path falls back"
    (Some
       (history_path
          (Filename.concat (Filename.concat "/home/me" ".local") "state")))
    (Centl_history.state_path ~win32:false fallback_environment);
  let windows_environment =
    environment [ ("LOCALAPPDATA", "C:\\Users\\me\\Local") ]
  in
  Alcotest.(check (option string))
    "Windows local application data"
    (Some (history_path "C:\\Users\\me\\Local"))
    (Centl_history.state_path ~win32:true windows_environment);
  let windows_roaming = environment [ ("APPDATA", "C:\\Users\\me\\Roaming") ] in
  Alcotest.(check (option string))
    "Windows roaming application data fallback"
    (Some (history_path "C:\\Users\\me\\Roaming"))
    (Centl_history.state_path ~win32:true windows_roaming);
  let windows_fallback = environment [ ("USERPROFILE", "C:\\Users\\me") ] in
  let expected =
    history_path
      (Filename.concat (Filename.concat "C:\\Users\\me" "AppData") "Local")
  in
  Alcotest.(check (option string))
    "Windows profile fallback" (Some expected)
    (Centl_history.state_path ~win32:true windows_fallback)

let private_mode_platform_guard () =
  let calls = ref [] in
  let record _descriptor mode = calls := mode :: !calls in
  Centl_history.set_private_file_mode ~fchmod:record ~win32:true Unix.stdin;
  Alcotest.(check (list int)) "Windows skips unsupported fchmod" [] !calls;
  Centl_history.set_private_file_mode ~fchmod:record ~win32:false Unix.stdin;
  Alcotest.(check (list int))
    "Unix requests a private file mode" [ 0o600 ] !calls

let environment_opt_out () =
  let check label expected bindings =
    Alcotest.(check bool)
      label expected
      (Centl_history.environment_disables_persistence
         ~getenv:(environment bindings) ())
  in
  check "enabled by default" false [];
  check "NO_HISTORY presence disables" true [ ("CENTL_NO_HISTORY", "") ];
  check "explicit false disables" true [ ("CENTL_HISTORY", "false") ];
  check "explicit zero disables" true [ ("CENTL_HISTORY", "0") ];
  check "explicit true enables" false [ ("CENTL_HISTORY", "true") ]

let local_history_bounds () =
  let limits =
    { Centl_history.max_entries = 3; max_bytes = 256; max_entry_bytes = 16 }
  in
  let history = Centl_history.create ~persistent:false ~limits () in
  List.iter
    (Centl_history.add history)
    [ "one"; "one"; " "; "bad\027entry"; "two"; "three"; "four" ];
  check_entries "bounded, clean, de-duplicated entries"
    [ "two"; "three"; "four" ] history;
  Centl_history.clear history;
  check_entries "local clear" [] history

let round_trip_permissions_and_byte_bound () =
  with_temp_directory (fun root ->
      let path = history_path root in
      let limits =
        { Centl_history.max_entries = 10; max_bytes = 70; max_entry_bytes = 40 }
      in
      let history = Centl_history.create ~path ~limits () in
      Centl_history.add history "aaaaaaaaaaaaaaaaaaaaaaaa";
      Centl_history.add history "quoted \"value\" here";
      let loaded = Centl_history.create ~path ~limits () in
      check_entries "byte bound keeps the newest complete entry"
        [ "quoted \"value\" here" ]
        loaded;
      let metadata = Unix.stat path in
      Alcotest.(check bool)
        "serialized file respects byte bound" true
        (metadata.st_size <= limits.max_bytes);
      if not Sys.win32 then begin
        Alcotest.(check int)
          "history file is private" 0o600
          (metadata.st_perm land 0o777);
        let directory = Unix.stat (Filename.dirname path) in
        Alcotest.(check int)
          "history directory is private" 0o700
          (directory.st_perm land 0o777)
      end)

let stale_processes_merge_and_clear () =
  with_temp_directory (fun root ->
      let path = history_path root in
      let first = Centl_history.create ~path () in
      let stale = Centl_history.create ~path () in
      Centl_history.add first "first";
      Centl_history.add stale "second";
      check_entries "stale writers merge disk state" [ "first"; "second" ]
        (Centl_history.create ~path ());
      Centl_history.clear first;
      Centl_history.add stale "after-clear";
      check_entries "stale writers do not resurrect cleared entries"
        [ "after-clear" ]
        (Centl_history.create ~path ()))

let corruption_and_io_tolerance () =
  with_temp_directory (fun root ->
      let path = history_path root in
      let history = Centl_history.create ~path () in
      Centl_history.add history "before-corruption";
      let output = open_out_bin path in
      Fun.protect
        ~finally:(fun () -> close_out_noerr output)
        (fun () -> output_string output "{not valid JSON");
      let recovered = Centl_history.create ~path () in
      check_entries "corrupt file is ignored" [] recovered;
      Centl_history.add recovered "after-corruption";
      check_entries "corrupt file is replaced atomically" [ "after-corruption" ]
        (Centl_history.create ~path ()));
  with_temp_directory (fun root ->
      let blocked_parent = Filename.concat root "not-a-directory" in
      let output = open_out_bin blocked_parent in
      close_out output;
      let path = Filename.concat blocked_parent "history.json" in
      let history = Centl_history.create ~path () in
      Centl_history.add history "still-local";
      check_entries "storage failure leaves local history usable"
        [ "still-local" ] history;
      Centl_history.clear history;
      check_entries "clear tolerates storage failure" [] history)

let unknown_version_migration () =
  with_temp_directory (fun root ->
      let path = history_path root in
      Unix.mkdir (Filename.dirname path) 0o700;
      let output = open_out_bin path in
      Fun.protect
        ~finally:(fun () -> close_out_noerr output)
        (fun () ->
          output_string output
            "{\"version\":2,\"entries\":[\"must-not-import\"]}\n");
      let history = Centl_history.create ~path () in
      check_entries "unknown version is not imported" [] history;
      Centl_history.add history "first-v1-entry";
      check_entries "next append starts a clean version-1 history"
        [ "first-v1-entry" ]
        (Centl_history.create ~path ());
      let input = open_in_bin path in
      let json =
        Fun.protect
          ~finally:(fun () -> close_in_noerr input)
          (fun () -> Yojson.Safe.from_channel input)
      in
      let version =
        match json with
        | `Assoc fields -> List.assoc_opt "version" fields
        | _ -> None
      in
      Alcotest.(check (option int))
        "replacement uses disk format version 1" (Some 1)
        (match version with Some (`Int value) -> Some value | _ -> None))

let child_argument = "--centl-history-test-child"

let run_child path entry =
  let history = Centl_history.create ~path () in
  Centl_history.add history entry

let concurrent_processes_do_not_lose_entries () =
  with_temp_directory (fun root ->
      let path = history_path root in
      let children =
        List.init 8 (fun index ->
            let entry = Printf.sprintf "child-%d" index in
            Unix.create_process Sys.executable_name
              [| Sys.executable_name; child_argument; path; entry |]
              Unix.stdin Unix.stdout Unix.stderr)
      in
      List.iter
        (fun process_id ->
          match Unix.waitpid [] process_id with
          | _, Unix.WEXITED 0 -> ()
          | _ -> fail "history writer child failed")
        children;
      let actual =
        Centl_history.create ~path ()
        |> Centl_history.entries |> List.sort compare
      in
      let expected =
        List.init 8 (Printf.sprintf "child-%d") |> List.sort compare
      in
      Alcotest.(check (list string))
        "locked appends retain every process entry" expected actual)

let persistence_can_be_disabled () =
  with_temp_directory (fun root ->
      let path = history_path root in
      let history = Centl_history.create ~persistent:false ~path () in
      Centl_history.add history "session-only";
      check_entries "disabled persistence keeps local editing history"
        [ "session-only" ] history;
      Alcotest.(check bool)
        "disabled persistence creates no file" false (Sys.file_exists path))

let run_tests () =
  Alcotest.run "centl durable history"
    [
      ( "history",
        [
          Alcotest.test_case "state path selection" `Quick path_selection;
          Alcotest.test_case "platform file modes" `Quick
            private_mode_platform_guard;
          Alcotest.test_case "environment opt-out" `Quick environment_opt_out;
          Alcotest.test_case "local bounds" `Quick local_history_bounds;
          Alcotest.test_case "round-trip, mode, and bytes" `Quick
            round_trip_permissions_and_byte_bound;
          Alcotest.test_case "stale process merge and clear" `Quick
            stale_processes_merge_and_clear;
          Alcotest.test_case "corruption and I/O tolerance" `Quick
            corruption_and_io_tolerance;
          Alcotest.test_case "unknown-version migration" `Quick
            unknown_version_migration;
          Alcotest.test_case "concurrent processes" `Quick
            concurrent_processes_do_not_lose_entries;
          Alcotest.test_case "persistence opt-out" `Quick
            persistence_can_be_disabled;
        ] );
    ]

let () =
  if Array.length Sys.argv = 4 && Sys.argv.(1) = child_argument then
    run_child Sys.argv.(2) Sys.argv.(3)
  else run_tests ()
