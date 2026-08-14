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

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let test_cycle_reaches_review () =
  let root = temp_dir "centl-mirage-cycle-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let document = Filename.concat root "design.md" in
      write_text document
        "# Kinetic energy\n\n\
         CENTL should create a function named kinetic_energy that takes mass \
         and velocity and computes 1/2 * mass * velocity^2\n\n\
         The function must remain exact for rational inputs.\n\n\
         Acceptance: kinetic_energy(2, 3) returns 9\n\n\
         - Example: kinetic_energy(2, 4) = 16\n";
      match Centl_sci_mirage_cycle.run workspace document with
      | Error message -> Alcotest.fail message
      | Ok cycle -> (
          Alcotest.(check bool)
            "review artifact exists" true
            (Sys.file_exists cycle.review_path);
          Alcotest.(check bool)
            "fingerprint artifact exists" true
            (Sys.file_exists cycle.fingerprint_path);
          Alcotest.(check bool)
            "cegis artifact exists" true
            (Sys.file_exists cycle.cegis_path);
          Alcotest.(check bool)
            "cycle does not activate" false cycle.acceptance.workspace_mutated;
          Alcotest.(check bool)
            "assurance not promoted" false cycle.acceptance.assurance_promoted;
          Alcotest.(check int)
            "fingerprint length" 64
            (String.length cycle.fingerprint.fingerprint);
          Alcotest.(check bool)
            "examples extracted" true
            (List.length cycle.cegis.examples >= 2);
          Alcotest.(check bool)
            "rewrite artifact exists" true
            (Sys.file_exists cycle.rewrite_path);
          Alcotest.(check bool)
            "lattice artifact exists" true
            (Sys.file_exists cycle.lattice_path);
          Alcotest.(check bool)
            "progress recorded" true
            (cycle.progress.requirement_count >= 1);
          Alcotest.(check bool)
            "core corpus preserved" true cycle.compare.core_preserved;
          Alcotest.(check bool)
            "composition artifact exists" true
            (Sys.file_exists cycle.compose_path);
          match Centl_sci_mirage_cycle.continue workspace with
          | Error message -> Alcotest.fail message
          | Ok again ->
              Alcotest.(check bool)
                "iteration recomputes" true
                (Sys.file_exists again.fingerprint_path)))

let () =
  Alcotest.run "CENTL-MIRAGE cycle"
    [
      ( "cycle",
        [
          Alcotest.test_case "full local cycle" `Quick test_cycle_reaches_review;
        ] );
    ]
