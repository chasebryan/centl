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

let add_native workspace =
  Centl_sci_workspace.ensure workspace;
  write_text
    (Filename.concat workspace.Centl_sci_workspace.modules_dir "tau.centl")
    "tau = 2*pi\n";
  match
    Centl_sci_workspace.write_manifest workspace ~name:"tau" ~enabled:true
      ~assurance:Centl_sci_workspace.Locally_tested ~source:"modules/tau.centl"
      ~summary:"status test"
  with
  | Ok _ -> ()
  | Error message -> Alcotest.fail message

let test_status_collects_local_state () =
  let root = temp_dir "centl-caramels-status-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      Unix.putenv "CENTL_WORKSPACE" root;
      let workspace = Centl_sci_workspace.make root in
      add_native workspace;
      begin match
        Centl_sci_package.create workspace ~name:"science"
          ~summary:"status package"
      with
      | Error message -> Alcotest.fail message
      | Ok _ -> ()
      end;
      let status = Centl_sci_status.collect () in
      Alcotest.(check string) "version" "0.0.2-Caramels" status.version;
      Alcotest.(check (option string))
        "workspace" (Some root) status.workspace_root;
      Alcotest.(check bool)
        "tau enabled" true
        (List.mem "tau" status.enabled_native_extensions);
      Alcotest.(check int) "one package" 1 status.packages;
      Alcotest.(check (option string))
        "health" (Some "healthy") status.workspace_health)

let test_status_json_never_promotes_assurance () =
  let status : Centl_sci_status.t =
    {
      version = "0.0.2-Caramels";
      platform = "unix/linux-reference";
      workspace_root = None;
      workspace_revision = None;
      workspace_health = None;
      enabled_native_extensions = [];
      disabled_extensions = 0;
      packages = 0;
      gated = [ "example gate" ];
    }
  in
  match Centl_sci_status.to_json status with
  | `Assoc fields ->
      begin match List.assoc_opt "assurance_promoted" fields with
      | Some (`Bool false) -> ()
      | _ -> Alcotest.fail "status JSON must state assurance_promoted=false"
      end
  | _ -> Alcotest.fail "status JSON must be an object"

let test_status_render_names_gates () =
  let status : Centl_sci_status.t =
    {
      version = "0.0.2-Caramels";
      platform = "unix/linux-reference";
      workspace_root = None;
      workspace_revision = None;
      workspace_health = None;
      enabled_native_extensions = [];
      disabled_extensions = 0;
      packages = 0;
      gated = [ "live import remains gated" ];
    }
  in
  let rendered = Centl_sci_status.render status in
  Alcotest.(check bool)
    "gate visible" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"live import remains gated"
          rendered));
  Alcotest.(check bool)
    "no assurance promotion" true
    (Option.is_some
       (Centl_sci_interaction.find_substring
          ~needle:"does not promote downstream assurance" rendered))

let () =
  Alcotest.run "CENTL-SCi Caramels status"
    [
      ( "status",
        [
          Alcotest.test_case "collect local state" `Quick
            test_status_collects_local_state;
          Alcotest.test_case "JSON assurance boundary" `Quick
            test_status_json_never_promotes_assurance;
          Alcotest.test_case "render gates" `Quick
            test_status_render_names_gates;
        ] );
    ]
