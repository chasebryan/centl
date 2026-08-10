let write_text path text =
  Centl_sci_workspace.ensure_directory (Filename.dirname path);
  let channel = open_out path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel text)

let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path =
  try Centl_sci_snapshot.remove_tree path with _ -> ()

let create_native_value workspace name source =
  Centl_sci_workspace.ensure workspace;
  write_text (Filename.concat workspace.Centl_sci_workspace.modules_dir (name ^ ".centl"))
    source;
  match
    Centl_sci_workspace.write_manifest workspace ~name ~enabled:true
      ~assurance:Centl_sci_workspace.Locally_tested
      ~source:("modules/" ^ name ^ ".centl")
      ~summary:"Caramels workspace test value"
  with
  | Ok _ -> ()
  | Error message -> Alcotest.fail message

let test_native_extension_validation () =
  let root = temp_dir "centl-caramels-validate-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      create_native_value workspace "tau" "tau = 2*pi\n";
      match Centl_sci_validate.validate workspace "tau" with
      | Error message -> Alcotest.fail message
      | Ok report ->
          Alcotest.(check bool) "structurally valid" true report.valid;
          Alcotest.(check string) "kind" "native_centl" report.kind;
          Alcotest.(check string) "assurance preserved"
            "locally_tested_extension" report.assurance)

let test_invalid_native_extension_is_not_promoted () =
  let root = temp_dir "centl-caramels-invalid-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      create_native_value workspace "broken" "broken = (\n";
      match Centl_sci_validate.validate workspace "broken" with
      | Error message -> Alcotest.fail message
      | Ok report ->
          Alcotest.(check bool) "invalid definition rejected" false report.valid;
          Alcotest.(check string) "assurance unchanged"
            "locally_tested_extension" report.assurance)

let test_export_import_and_undo () =
  let root = temp_dir "centl-caramels-portable-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let source = Centl_sci_workspace.make (Filename.concat root "source") in
      let target = Centl_sci_workspace.make (Filename.concat root "target") in
      let bundle = Filename.concat root "bundle" in
      create_native_value source "tau" "tau = 2*pi\n";
      begin match
        Centl_sci_package.create source ~name:"science"
          ~summary:"portable test package"
      with
      | Error message -> Alcotest.fail message
      | Ok _ ->
          begin match
            Centl_sci_package.add_extension source ~package_name:"science"
              ~extension_name:"tau"
          with
          | Error message -> Alcotest.fail message
          | Ok _ -> ()
          end
      end;
      create_native_value target "old_value" "old_value = 7\n";
      begin match Centl_sci_portable.export source (Some bundle) with
      | Error message -> Alcotest.fail message
      | Ok exported ->
          Alcotest.(check bool) "export is read-only" false exported.changed;
          Alcotest.(check bool) "bundle metadata exists" true
            (Sys.file_exists (Filename.concat bundle "bundle.json"))
      end;
      begin match Centl_sci_portable.import target bundle with
      | Error message -> Alcotest.fail message
      | Ok imported ->
          Alcotest.(check bool) "import changes downstream state" true imported.changed;
          Alcotest.(check bool) "imported tau source exists" true
            (Sys.file_exists (Filename.concat target.modules_dir "tau.centl"));
          Alcotest.(check bool) "old source replaced" false
            (Sys.file_exists (Filename.concat target.modules_dir "old_value.centl"));
          begin match Centl_sci_package.read target "science" with
          | Error message -> Alcotest.fail message
          | Ok package ->
              Alcotest.(check bool) "package membership survives" true
                (List.mem "tau" package.extensions)
          end
      end;
      begin match Centl_sci_snapshot.restore_last target with
      | Error message -> Alcotest.fail message
      | Ok _ ->
          Alcotest.(check bool) "undo restores old source" true
            (Sys.file_exists (Filename.concat target.modules_dir "old_value.centl"));
          Alcotest.(check bool) "undo removes imported source" false
            (Sys.file_exists (Filename.concat target.modules_dir "tau.centl"))
      end)

let () =
  Alcotest.run "CENTL-SCi Caramels workspace"
    [
      ( "validation",
        [
          Alcotest.test_case "native extension" `Quick
            test_native_extension_validation;
          Alcotest.test_case "invalid native extension" `Quick
            test_invalid_native_extension_is_not_promoted;
        ] );
      ( "portability",
        [
          Alcotest.test_case "export/import/undo" `Quick
            test_export_import_and_undo;
        ] );
    ]
