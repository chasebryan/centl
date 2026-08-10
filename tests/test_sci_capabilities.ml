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

let create_tau workspace =
  Centl_sci_workspace.ensure workspace;
  write_text (Filename.concat workspace.Centl_sci_workspace.modules_dir "tau.centl")
    "tau = 2*pi\n";
  match
    Centl_sci_workspace.write_manifest workspace ~name:"tau" ~enabled:true
      ~assurance:Centl_sci_workspace.Locally_tested ~source:"modules/tau.centl"
      ~summary:"circle constant extension"
  with
  | Ok _ -> ()
  | Error message -> Alcotest.fail message

let test_builtin_constant_reuse () =
  let matches = Centl_sci_capabilities.search "Boltzmann constant" in
  Alcotest.(check bool) "physical constant capability found" true
    (List.exists
       (fun capability -> capability.Centl_sci_capabilities.name = "physical constants")
       matches)

let test_builtin_integration_reuse () =
  let matches = Centl_sci_capabilities.search "integrate a polynomial" in
  Alcotest.(check bool) "integration capability found" true
    (List.exists
       (fun capability -> capability.Centl_sci_capabilities.name = "integrate")
       matches)

let test_local_package_is_reusable_composition () =
  let root = temp_dir "centl-caramels-capability-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      create_tau workspace;
      begin match
        Centl_sci_package.create workspace ~name:"geometry"
          ~summary:"local geometry composition"
      with
      | Error message -> Alcotest.fail message
      | Ok _ -> ()
      end;
      begin match
        Centl_sci_package.add_extension workspace ~package_name:"geometry"
          ~extension_name:"tau"
      with
      | Error message -> Alcotest.fail message
      | Ok _ -> ()
      end;
      let capabilities = Centl_sci_capabilities.local_package_capabilities workspace in
      match capabilities with
      | [ capability ] ->
          Alcotest.(check string) "package name" "geometry" capability.name;
          Alcotest.(check bool) "extension alias preserved" true
            (List.mem "tau" capability.aliases);
          Alcotest.(check string) "no package trust promotion"
            "composition-only; member assurance preserved" capability.assurance;
          Alcotest.(check bool) "package origin" true
            (capability.origin = Centl_sci_capabilities.Local_package)
      | _ -> Alcotest.fail "expected exactly one local package capability")

let () =
  Alcotest.run "CENTL-SCi Caramels capabilities"
    [
      ( "reuse",
        [
          Alcotest.test_case "exact constant reuse" `Quick
            test_builtin_constant_reuse;
          Alcotest.test_case "integration reuse" `Quick
            test_builtin_integration_reuse;
          Alcotest.test_case "local package composition" `Quick
            test_local_package_is_reusable_composition;
        ] );
    ]
