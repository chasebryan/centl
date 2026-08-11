let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let write_text path text =
  Centl_sci_workspace.ensure_directory (Filename.dirname path);
  let channel = open_out path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel text)

let create_disabled_native workspace ~name ~source =
  Centl_sci_workspace.ensure workspace;
  write_text
    (Filename.concat workspace.Centl_sci_workspace.modules_dir (name ^ ".centl"))
    source;
  match
    Centl_sci_workspace.write_manifest workspace ~name ~enabled:false
      ~assurance:Centl_sci_workspace.Locally_tested
      ~source:("modules/" ^ name ^ ".centl")
      ~summary:"activation test"
  with
  | Ok revision -> revision
  | Error message -> Alcotest.fail message

let test_valid_native_can_enable () =
  let root = temp_dir "centl-caramels-enable-valid-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      let before =
        create_disabled_native workspace ~name:"tau" ~source:"tau = 2*pi\n"
      in
      match Centl_sci_extensions.set_enabled workspace "tau" true with
      | Error message -> Alcotest.fail message
      | Ok manifest ->
          Alcotest.(check bool) "enabled" true manifest.enabled;
          Alcotest.(check bool)
            "revision advances" true
            (manifest.workspace_revision > before))

let test_invalid_native_enable_is_rejected_without_revision () =
  let root = temp_dir "centl-caramels-enable-invalid-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      let before =
        create_disabled_native workspace ~name:"broken" ~source:"broken = (\n"
      in
      begin match Centl_sci_extensions.set_enabled workspace "broken" true with
      | Ok _ -> Alcotest.fail "invalid native source must not be enabled"
      | Error message ->
          Alcotest.(check bool)
            "parse failure is explicit" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"cannot be enabled because its source does not parse"
                  message))
      end;
      Alcotest.(check int)
        "failed enable does not mutate revision" before
        (Centl_sci_workspace.read_revision workspace);
      match Centl_sci_extensions.read_manifest workspace "broken" with
      | Error message -> Alcotest.fail message
      | Ok manifest ->
          Alcotest.(check bool)
            "manifest remains disabled" false manifest.enabled)

let test_disabling_does_not_require_valid_source () =
  let root = temp_dir "centl-caramels-disable-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      Centl_sci_workspace.ensure workspace;
      write_text
        (Filename.concat workspace.modules_dir "broken.centl")
        "broken = (\n";
      begin match
        Centl_sci_workspace.write_manifest workspace ~name:"broken"
          ~enabled:true ~assurance:Centl_sci_workspace.Locally_tested
          ~source:"modules/broken.centl" ~summary:"disable invalid source test"
      with
      | Error message -> Alcotest.fail message
      | Ok _ -> ()
      end;
      match Centl_sci_extensions.set_enabled workspace "broken" false with
      | Error message -> Alcotest.fail message
      | Ok manifest -> Alcotest.(check bool) "disabled" false manifest.enabled)

let () =
  Alcotest.run "CENTL-SCi Caramels extension lifecycle"
    [
      ( "activation",
        [
          Alcotest.test_case "valid native enable" `Quick
            test_valid_native_can_enable;
          Alcotest.test_case "invalid native refused" `Quick
            test_invalid_native_enable_is_rejected_without_revision;
          Alcotest.test_case "invalid source can be disabled" `Quick
            test_disabling_does_not_require_valid_source;
        ] );
    ]
