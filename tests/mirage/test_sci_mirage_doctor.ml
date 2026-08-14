let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let test_doctor_without_cycle () =
  let root = temp_dir "centl-mirage-doctor-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      Centl_sci_workspace.ensure workspace;
      let report = Centl_sci_mirage_doctor.inspect workspace in
      Alcotest.(check bool) "not healthy without cycle" false report.healthy;
      Alcotest.(check bool)
        "names missing cycle" true
        (List.exists
           (fun check ->
             check.Centl_sci_mirage_doctor.name = "active_cycle" && not check.ok)
           report.checks))

let () =
  Alcotest.run "CENTL-MIRAGE doctor"
    [
      ( "health",
        [
          Alcotest.test_case "empty workspace" `Quick test_doctor_without_cycle;
        ] );
    ]
