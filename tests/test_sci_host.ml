let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let test_host_wants_is_narrow () =
  Alcotest.(check bool)
    "source patch" true
    (Centl_sci_host.wants "patch your source to support harmonic mean");
  Alcotest.(check bool)
    "ordinary teach is not a host patch" false
    (Centl_sci_host.wants "teach yourself harmonic mean")

let test_proposal_declares_restart () =
  let root = temp_dir "centl-host-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      Centl_sci_workspace.ensure workspace;
      match
        Centl_sci_host.propose workspace ~name:(Some "harmonic_mean")
          ~request:"patch your source to add harmonic mean"
          ~source:(Some "harmonic_mean(a, b) = 2 / ((1/a) + (1/b))")
      with
      | Error message -> Alcotest.fail message
      | Ok proposal ->
          Alcotest.(check bool) "restart" true proposal.restart_required;
          Alcotest.(check bool) "rebuild" true proposal.rebuild_required;
          let rendered = Centl_sci_host.render proposal in
          Alcotest.(check bool)
            "no core rewrite" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"Verified CENTL core was not modified" rendered));
          Alcotest.(check bool)
            "restart.json exists" true
            (Sys.file_exists (Filename.concat proposal.root "restart.json")))

let () =
  Alcotest.run "CENTL-SCi host growth"
    [
      ( "host",
        [
          Alcotest.test_case "narrow trigger" `Quick test_host_wants_is_narrow;
          Alcotest.test_case "proposal restart" `Quick
            test_proposal_declares_restart;
        ] );
    ]
