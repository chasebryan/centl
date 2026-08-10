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
        ] );
    ]
