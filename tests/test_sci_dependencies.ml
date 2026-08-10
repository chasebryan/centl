let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path =
  try Centl_sci_snapshot.remove_tree path with _ -> ()

let write_manifest workspace ~name ~enabled ~dependencies =
  match
    Centl_sci_workspace.write_manifest_detailed workspace ~name ~enabled
      ~assurance:Centl_sci_workspace.Experimental_local
      ~source:("modules/" ^ name ^ ".centl")
      ~summary:"dependency graph test" ~kind:"native_centl"
      ~provenance:"Caramels dependency test" ~dependencies ~tests:[]
  with
  | Ok _ -> ()
  | Error message -> Alcotest.fail message

let has_issue predicate report = List.exists predicate report.Centl_sci_dependencies.issues

let contains needle text =
  Option.is_some (Centl_sci_interaction.find_substring ~needle text)

let test_missing_local_dependency () =
  let root = temp_dir "centl-caramels-dependency-missing-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      write_manifest workspace ~name:"alpha" ~enabled:true
        ~dependencies:[ "extension:beta" ];
      let report = Centl_sci_dependencies.validate workspace in
      Alcotest.(check bool) "missing local dependency invalidates graph" false report.valid;
      Alcotest.(check bool) "missing dependency is reported" true
        (has_issue
           (function
             | Centl_sci_dependencies.Missing_extension
                 { extension = "alpha"; dependency = "beta" } -> true
             | _ -> false)
           report))

let test_disabled_dependency_is_warning_not_structural_failure () =
  let root = temp_dir "centl-caramels-dependency-disabled-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      write_manifest workspace ~name:"beta" ~enabled:false ~dependencies:[];
      write_manifest workspace ~name:"alpha" ~enabled:true
        ~dependencies:[ "extension:beta" ];
      let report = Centl_sci_dependencies.validate workspace in
      Alcotest.(check bool) "inactive target does not corrupt graph structure" true report.valid;
      Alcotest.(check bool) "inactive dependency remains visible" true
        (has_issue
           (function
             | Centl_sci_dependencies.Inactive_extension
                 { extension = "alpha"; dependency = "beta" } -> true
             | _ -> false)
           report))

let test_cycle_is_rejected () =
  let root = temp_dir "centl-caramels-dependency-cycle-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      write_manifest workspace ~name:"alpha" ~enabled:true
        ~dependencies:[ "extension:beta" ];
      write_manifest workspace ~name:"beta" ~enabled:true
        ~dependencies:[ "extension:alpha" ];
      let report = Centl_sci_dependencies.validate workspace in
      Alcotest.(check bool) "cycle invalidates graph" false report.valid;
      Alcotest.(check bool) "cycle is reported" true
        (has_issue
           (function Centl_sci_dependencies.Cycle _ -> true | _ -> false)
           report))

let test_external_and_opaque_dependencies_are_preserved () =
  let root = temp_dir "centl-caramels-dependency-provenance-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      write_manifest workspace ~name:"reader" ~enabled:false
        ~dependencies:[ "external:astropy"; "legacy-runtime" ];
      let report = Centl_sci_dependencies.validate workspace in
      Alcotest.(check bool) "external provenance is not falsely validated" true report.valid;
      Alcotest.(check bool) "external dependency preserved" true
        (List.mem ("reader", [ "astropy" ]) report.external_dependencies);
      Alcotest.(check bool) "opaque dependency preserved" true
        (List.mem ("reader", [ "legacy-runtime" ]) report.opaque_dependencies))

let test_extension_listing_orders_local_dependencies_first () =
  let root = temp_dir "centl-caramels-dependency-order-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      write_manifest workspace ~name:"alpha" ~enabled:true
        ~dependencies:[ "extension:zeta" ];
      write_manifest workspace ~name:"zeta" ~enabled:true ~dependencies:[];
      let names =
        Centl_sci_extensions.list workspace
        |> List.map (fun manifest -> manifest.Centl_sci_extensions.name)
      in
      Alcotest.(check (list string)) "dependency precedes dependent"
        [ "zeta"; "alpha" ] names)

let test_activation_rejects_missing_local_dependency () =
  let root = temp_dir "centl-caramels-activation-missing-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      write_manifest workspace ~name:"alpha" ~enabled:false
        ~dependencies:[ "extension:beta" ];
      match Centl_sci_extensions.read_manifest workspace "alpha" with
      | Error message -> Alcotest.fail message
      | Ok manifest ->
          begin match
            Centl_sci_extensions.validate_local_dependencies_for_activation workspace
              manifest
          with
          | Ok () -> Alcotest.fail "activation dependency validation unexpectedly succeeded"
          | Error message ->
              Alcotest.(check bool) "missing dependency refusal" true
                (contains "required local extension beta is missing" message)
          end)

let test_activation_rejects_disabled_local_dependency () =
  let root = temp_dir "centl-caramels-activation-disabled-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      write_manifest workspace ~name:"beta" ~enabled:false ~dependencies:[];
      write_manifest workspace ~name:"alpha" ~enabled:false
        ~dependencies:[ "extension:beta" ];
      match Centl_sci_extensions.read_manifest workspace "alpha" with
      | Error message -> Alcotest.fail message
      | Ok manifest ->
          begin match
            Centl_sci_extensions.validate_local_dependencies_for_activation workspace
              manifest
          with
          | Ok () -> Alcotest.fail "disabled dependency unexpectedly allowed activation"
          | Error message ->
              Alcotest.(check bool) "disabled dependency refusal" true
                (contains "required local extension beta is disabled" message)
          end)

let test_disabling_required_extension_is_rejected () =
  let root = temp_dir "centl-caramels-disable-required-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      write_manifest workspace ~name:"alpha" ~enabled:true ~dependencies:[];
      write_manifest workspace ~name:"beta" ~enabled:true
        ~dependencies:[ "extension:alpha" ];
      let revision = Centl_sci_workspace.read_revision workspace in
      begin match Centl_sci_extensions.set_enabled workspace "alpha" false with
      | Ok _ -> Alcotest.fail "required extension was unexpectedly disabled"
      | Error message ->
          Alcotest.(check bool) "dependent refusal" true
            (contains "required by enabled local extension beta" message)
      end;
      Alcotest.(check int) "refusal does not mutate revision" revision
        (Centl_sci_workspace.read_revision workspace))

let test_removing_required_extension_is_rejected () =
  let root = temp_dir "centl-caramels-remove-required-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      write_manifest workspace ~name:"alpha" ~enabled:true ~dependencies:[];
      write_manifest workspace ~name:"beta" ~enabled:true
        ~dependencies:[ "extension:alpha" ];
      let revision = Centl_sci_workspace.read_revision workspace in
      begin match Centl_sci_extensions.remove workspace "alpha" with
      | Ok _ -> Alcotest.fail "required extension was unexpectedly removed"
      | Error message ->
          Alcotest.(check bool) "dependent refusal" true
            (contains "required by enabled local extension beta" message)
      end;
      Alcotest.(check int) "refusal does not mutate revision" revision
        (Centl_sci_workspace.read_revision workspace);
      Alcotest.(check bool) "manifest remains present" true
        (Sys.file_exists (Centl_sci_workspace.manifest_path workspace "alpha")))

let () =
  Alcotest.run "CENTL-SCi Caramels dependencies"
    [
      ( "graph",
        [
          Alcotest.test_case "missing local dependency" `Quick
            test_missing_local_dependency;
          Alcotest.test_case "disabled dependency warning" `Quick
            test_disabled_dependency_is_warning_not_structural_failure;
          Alcotest.test_case "cycle" `Quick test_cycle_is_rejected;
          Alcotest.test_case "external/opaque provenance" `Quick
            test_external_and_opaque_dependencies_are_preserved;
          Alcotest.test_case "dependency-aware extension order" `Quick
            test_extension_listing_orders_local_dependencies_first;
          Alcotest.test_case "activation rejects missing dependency" `Quick
            test_activation_rejects_missing_local_dependency;
          Alcotest.test_case "activation rejects disabled dependency" `Quick
            test_activation_rejects_disabled_local_dependency;
          Alcotest.test_case "disable required extension is rejected" `Quick
            test_disabling_required_extension_is_rejected;
          Alcotest.test_case "remove required extension is rejected" `Quick
            test_removing_required_extension_is_rejected;
        ] );
    ]
