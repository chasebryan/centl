let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path =
  try Centl_sci_snapshot.remove_tree path with _ -> ()

let cell id kind text : Centl_sci_mirage_goal.spec_cell =
  { id; kind; text; start_line = id; end_line = id }

let has_kind kind report =
  List.exists
    (fun obligation -> obligation.Centl_sci_mirage_obligation.kind = kind)
    report.Centl_sci_mirage_obligation.obligations

let test_extension_obligations_keep_assurance_honest () =
  let root = temp_dir "centl-mirage-obligations-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      let graph =
        Centl_sci_mirage_goal.build workspace
          [ cell 1 "DIRECTIVE" "Implement quasar_flux_tensorization" ]
      in
      let report = Centl_sci_mirage_obligation.build graph in
      Alcotest.(check bool) "candidate is not pre-blocked" true
        (report.blocked_cells = []);
      Alcotest.(check bool) "parser/build validation required" true
        (has_kind Centl_sci_mirage_obligation.Candidate_parses report);
      Alcotest.(check bool) "regression evidence required" true
        (has_kind Centl_sci_mirage_obligation.Mandatory_regression report);
      Alcotest.(check bool) "rollback required" true
        (has_kind Centl_sci_mirage_obligation.Rollback_available report);
      Alcotest.(check bool) "trust boundary stays explicit" true
        (has_kind Centl_sci_mirage_obligation.Trust_boundary_explicit report))

let test_ambiguity_blocks_synthesis () =
  let root = temp_dir "centl-mirage-ambiguity-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      let graph =
        Centl_sci_mirage_goal.build workspace
          [ cell 1 "QUESTION" "Which interpolation basis should be exposed?" ]
      in
      let report = Centl_sci_mirage_obligation.build graph in
      Alcotest.(check (list int)) "question blocks its source cell" [ 1 ]
        report.blocked_cells;
      Alcotest.(check bool) "clarification obligation emitted" true
        (has_kind Centl_sci_mirage_obligation.Clarification_required report))

let test_composition_requires_reuse_attempt () =
  let root = temp_dir "centl-mirage-reuse-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      Centl_sci_workspace.ensure workspace;
      let graph =
        Centl_sci_mirage_goal.build workspace
          [ cell 1 "DIRECTIVE" "Allow users to differentiate symbolic expressions" ]
      in
      let report = Centl_sci_mirage_obligation.build graph in
      Alcotest.(check bool) "reuse obligation emitted" true
        (has_kind Centl_sci_mirage_obligation.Reuse_attempted report))

let test_construct_persists_machine_readable_report () =
  let root = temp_dir "centl-mirage-obligation-file-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      let graph =
        Centl_sci_mirage_goal.build workspace
          [ cell 1 "DIRECTIVE" "Implement quasar_flux_tensorization" ]
      in
      let goal_path = Filename.concat root "design.goals.json" in
      match Centl_sci_mirage_obligation.construct goal_path graph with
      | Error message -> Alcotest.fail message
      | Ok (path, report) ->
          Alcotest.(check bool) "obligations artifact exists" true
            (Sys.file_exists path);
          Alcotest.(check string) "artifact suffix" "design.obligations.json"
            (Filename.basename path);
          Alcotest.(check bool) "artifact contains obligations" true
            (report.obligations <> []))

let () =
  Alcotest.run "CENTL-MIRAGE evidence obligations"
    [
      ( "construction",
        [
          Alcotest.test_case "extension assurance" `Quick
            test_extension_obligations_keep_assurance_honest;
          Alcotest.test_case "ambiguity blocks synthesis" `Quick
            test_ambiguity_blocks_synthesis;
          Alcotest.test_case "composition reuses capabilities" `Quick
            test_composition_requires_reuse_attempt;
          Alcotest.test_case "persist artifact" `Quick
            test_construct_persists_machine_readable_report;
        ] );
    ]
