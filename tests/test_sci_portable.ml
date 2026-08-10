let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path =
  try Centl_sci_snapshot.remove_tree path with _ -> ()

let write_text path text =
  Centl_sci_workspace.ensure_directory (Filename.dirname path);
  let channel = open_out path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel text)

let read_text path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr channel)
    (fun () -> really_input_string channel (in_channel_length channel))

let create_native_value workspace =
  Centl_sci_workspace.ensure workspace;
  write_text (Filename.concat workspace.Centl_sci_workspace.modules_dir "tau.centl")
    "tau = 2*pi\n";
  match
    Centl_sci_workspace.write_manifest workspace ~name:"tau" ~enabled:true
      ~assurance:Centl_sci_workspace.Locally_tested ~source:"modules/tau.centl"
      ~summary:"portable boundary test"
  with
  | Ok _ -> ()
  | Error message -> Alcotest.fail message

let make_bundle root =
  let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
  let bundle = Filename.concat root "bundle" in
  create_native_value workspace;
  begin match Centl_sci_portable.export workspace (Some bundle) with
  | Error message -> Alcotest.fail message
  | Ok _ -> ()
  end;
  bundle

let replace_assoc name value = function
  | `Assoc fields ->
      `Assoc
        (List.map
           (fun (field, current) ->
             if field = name then (field, value) else (field, current))
           fields)
  | json -> json

let expect_rejected needle = function
  | Ok () -> Alcotest.fail "bundle validation unexpectedly succeeded"
  | Error message ->
      Alcotest.(check bool) "rejection reason" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle message))

let test_manifest_traversal_is_rejected () =
  let root = temp_dir "centl-caramels-traversal-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let bundle = make_bundle root in
      let manifest_path = Filename.concat (Filename.concat bundle "extensions") "tau.json" in
      let manifest = Yojson.Safe.from_file manifest_path in
      Centl_sci_workspace.atomic_write_json manifest_path
        (replace_assoc "source" (`String "../outside.centl") manifest);
      Centl_sci_portable.validate_bundle bundle
      |> expect_rejected "normalized relative bundle namespace")

let test_absolute_manifest_source_is_rejected () =
  let root = temp_dir "centl-caramels-absolute-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let bundle = make_bundle root in
      let manifest_path = Filename.concat (Filename.concat bundle "extensions") "tau.json" in
      let manifest = Yojson.Safe.from_file manifest_path in
      Centl_sci_workspace.atomic_write_json manifest_path
        (replace_assoc "source" (`String "/tmp/outside.centl") manifest);
      Centl_sci_portable.validate_bundle bundle
      |> expect_rejected "normalized relative bundle namespace")

let test_symlink_is_rejected_before_copy () =
  let root = temp_dir "centl-caramels-symlink-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let bundle = make_bundle root in
      let outside = Filename.concat root "outside.txt" in
      write_text outside "outside\n";
      let data = Filename.concat bundle "data" in
      Centl_sci_workspace.ensure_directory data;
      Unix.symlink outside (Filename.concat data "escape-link");
      Centl_sci_portable.validate_bundle bundle
      |> expect_rejected "contains a symlink")

let test_snapshot_rejects_symlinked_workspace_state () =
  let root = temp_dir "centl-caramels-snapshot-symlink-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      Centl_sci_workspace.ensure workspace;
      let outside = Filename.concat root "outside.txt" in
      write_text outside "outside\n";
      Unix.symlink outside (Filename.concat workspace.data "escape-link");
      begin match Centl_sci_snapshot.create workspace with
      | Ok _ -> Alcotest.fail "snapshot unexpectedly followed symlinked workspace state"
      | Error message ->
          Alcotest.(check bool) "snapshot symlink rejection" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"symlinked workspace state" message))
      end;
      Alcotest.(check string) "outside file untouched" "outside\n" (read_text outside))

let test_snapshot_rejects_symlinked_snapshot_root () =
  let root = temp_dir "centl-caramels-snapshot-root-symlink-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      Centl_sci_workspace.ensure workspace;
      let outside = Filename.concat root "outside-snapshots" in
      Unix.mkdir outside 0o700;
      Unix.symlink outside (Centl_sci_snapshot.snapshot_root workspace);
      begin match Centl_sci_snapshot.create workspace with
      | Ok _ -> Alcotest.fail "snapshot unexpectedly accepted a symlinked snapshot root"
      | Error message ->
          Alcotest.(check bool) "snapshot-root symlink rejection" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"symlinked snapshot root" message))
      end)

let test_snapshot_rollback_does_not_advance_revision () =
  let root = temp_dir "centl-caramels-snapshot-rollback-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      Centl_sci_workspace.ensure workspace;
      let state = Filename.concat workspace.data "state.txt" in
      write_text state "before\n";
      let revision_before = Centl_sci_workspace.read_revision workspace in
      let snapshot =
        match Centl_sci_snapshot.create workspace with
        | Ok path -> path
        | Error message -> Alcotest.fail message
      in
      write_text state "after\n";
      begin match Centl_sci_snapshot.rollback workspace snapshot with
      | Error message -> Alcotest.fail message
      | Ok revision ->
          Alcotest.(check int) "rollback revision unchanged" revision_before revision
      end;
      Alcotest.(check int) "workspace revision unchanged" revision_before
        (Centl_sci_workspace.read_revision workspace);
      Alcotest.(check string) "snapshot surface restored" "before\n" (read_text state))

let test_snapshot_retains_only_latest_undo_state () =
  let root = temp_dir "centl-caramels-snapshot-bounded-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      Centl_sci_workspace.ensure workspace;
      let state = Filename.concat workspace.data "state.txt" in
      write_text state "first\n";
      let first =
        match Centl_sci_snapshot.create workspace with
        | Ok path -> path
        | Error message -> Alcotest.fail message
      in
      write_text state "second\n";
      let second =
        match Centl_sci_snapshot.create workspace with
        | Ok path -> path
        | Error message -> Alcotest.fail message
      in
      Alcotest.(check bool) "new snapshot retained" true (Sys.file_exists second);
      Alcotest.(check bool) "old snapshot pruned" false (Sys.file_exists first);
      Alcotest.(check int) "only one snapshot retained" 1
        (Array.length (Sys.readdir (Centl_sci_snapshot.snapshot_root workspace)));
      begin match Centl_sci_snapshot.restore_last workspace with
      | Error message -> Alcotest.fail message
      | Ok _ -> ()
      end;
      Alcotest.(check string) "latest undo state restored" "second\n" (read_text state))

let test_snapshot_rollback_rejects_outside_path () =
  let root = temp_dir "centl-caramels-snapshot-outside-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      Centl_sci_workspace.ensure workspace;
      let outside = Filename.concat root "outside-snapshot" in
      Unix.mkdir outside 0o700;
      begin match Centl_sci_snapshot.rollback workspace outside with
      | Ok _ -> Alcotest.fail "rollback unexpectedly accepted an unmanaged snapshot path"
      | Error message ->
          Alcotest.(check bool) "outside rollback rejected" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"outside the managed snapshot root" message))
      end)

let test_dependency_invalid_bundle_is_rejected () =
  let root = temp_dir "centl-caramels-dependency-import-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let bundle = make_bundle root in
      let manifest_path = Filename.concat (Filename.concat bundle "extensions") "tau.json" in
      let manifest = Yojson.Safe.from_file manifest_path in
      Centl_sci_workspace.atomic_write_json manifest_path
        (replace_assoc "dependencies" (`List [ `String "extension:missing" ]) manifest);
      Centl_sci_portable.validate_bundle bundle
      |> expect_rejected "dependency graph is not activation-ready")

let test_import_preserves_reload_signal () =
  let root = temp_dir "centl-caramels-import-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let bundle = make_bundle root in
      let active =
        Centl_sci_workspace.make ~name:"active" (Filename.concat root "active")
      in
      Centl_sci_workspace.ensure active;
      match Centl_sci_portable.import active bundle with
      | Error message -> Alcotest.fail message
      | Ok result ->
          Alcotest.(check bool) "import reports changed" true result.changed;
          Alcotest.(check bool) "import reports revision" true
            (Option.is_some result.revision);
          begin match Centl_sci_extensions.read_manifest active "tau" with
          | Error message -> Alcotest.fail message
          | Ok manifest ->
              Alcotest.(check bool) "imported extension remains enabled" true
                manifest.enabled
          end)

let () =
  Alcotest.run "CENTL-SCi Caramels portability"
    [
      ( "bundle boundary",
        [
          Alcotest.test_case "reject manifest traversal" `Quick
            test_manifest_traversal_is_rejected;
          Alcotest.test_case "reject absolute source" `Quick
            test_absolute_manifest_source_is_rejected;
          Alcotest.test_case "reject symlink" `Quick
            test_symlink_is_rejected_before_copy;
          Alcotest.test_case "snapshot rejects symlink" `Quick
            test_snapshot_rejects_symlinked_workspace_state;
          Alcotest.test_case "snapshot root rejects symlink" `Quick
            test_snapshot_rejects_symlinked_snapshot_root;
          Alcotest.test_case "rollback preserves revision" `Quick
            test_snapshot_rollback_does_not_advance_revision;
          Alcotest.test_case "snapshot retains one undo" `Quick
            test_snapshot_retains_only_latest_undo_state;
          Alcotest.test_case "rollback rejects outside path" `Quick
            test_snapshot_rollback_rejects_outside_path;
          Alcotest.test_case "reject dependency-invalid bundle" `Quick
            test_dependency_invalid_bundle_is_rejected;
          Alcotest.test_case "import preserves reload signal" `Quick
            test_import_preserves_reload_signal;
        ] );
    ]
