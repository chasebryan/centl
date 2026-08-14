let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let test_extracts_and_verifies_examples () =
  let root = temp_dir "centl-mirage-cegis-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      Centl_sci_workspace.ensure workspace;
      let document = Filename.concat root "design.md" in
      let channel = open_out document in
      Fun.protect
        ~finally:(fun () -> close_out_noerr channel)
        (fun () ->
          output_string channel
            "# Kinetic energy\n\n\
             CENTL should create a function named kinetic_energy that takes \
             mass and velocity and computes 1/2 * mass * velocity^2\n\n\
             The function must remain exact for rational inputs.\n\n\
             Acceptance: kinetic_energy(2, 3) returns 9\n\n\
             - Example: kinetic_energy(2, 4) = 16\n");
      match Centl_sci_mirage.ingest workspace document with
      | Error message -> Alcotest.fail message
      | Ok ingest -> (
          match Centl_sci_mirage_goal.analyze workspace ingest.spec_path with
          | Error message -> Alcotest.fail message
          | Ok (_, graph) ->
              let obligations = Centl_sci_mirage_obligation.build graph in
              let candidates =
                Centl_sci_mirage_candidate.build graph obligations
              in
              let materialization =
                Centl_sci_mirage_materialize.build candidates
              in
              let report =
                Centl_sci_mirage_cegis.run graph candidates materialization
              in
              Alcotest.(check bool)
                "extracted examples" true
                (List.length report.examples >= 2);
              Alcotest.(check bool)
                "at least one valid trial" true
                (List.exists
                   (fun trial ->
                     trial.Centl_sci_mirage_cegis.state
                     = Centl_sci_mirage_cegis.Valid
                     && trial.examples_checked >= 2)
                   report.trials);
              Alcotest.(check bool)
                "accepted generated source" true
                (match report.accepted_source with
                | Some source ->
                    Option.is_some
                      (Centl_sci_interaction.find_substring
                         ~needle:"kinetic_energy" source)
                | None -> false)))

let () =
  Alcotest.run "CENTL-MIRAGE CEGIS"
    [
      ( "search",
        [
          Alcotest.test_case "example verification" `Quick
            test_extracts_and_verifies_examples;
        ] );
    ]
