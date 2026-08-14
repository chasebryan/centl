let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let test_default_is_stage () =
  Alcotest.(check string)
    "default" "stage"
    (Centl_sci_mirage_policy.level_text Centl_sci_mirage_policy.default.level)

let test_stage_cannot_activate () =
  Alcotest.(check bool)
    "stage blocks activation" false
    (Centl_sci_mirage_policy.permits_activation Centl_sci_mirage_policy.default
       Centl_sci_mirage_candidate.Downstream_extension)

let test_local_cannot_activate_core () =
  let policy =
    { Centl_sci_mirage_policy.level = Local; network_publication = false }
  in
  Alcotest.(check bool)
    "local permits downstream" true
    (Centl_sci_mirage_policy.permits_activation policy
       Centl_sci_mirage_candidate.Downstream_extension);
  Alcotest.(check bool)
    "local still blocks core patches" false
    (Centl_sci_mirage_policy.permits_activation policy
       Centl_sci_mirage_candidate.Isolated_core_patch)

let test_round_trip () =
  let root = temp_dir "centl-mirage-policy-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let policy =
        { Centl_sci_mirage_policy.level = Observe; network_publication = false }
      in
      match Centl_sci_mirage_policy.store workspace policy with
      | Error message -> Alcotest.fail message
      | Ok _ -> (
          match Centl_sci_mirage_policy.load workspace with
          | Error message -> Alcotest.fail message
          | Ok loaded ->
              Alcotest.(check string)
                "loaded level" "observe"
                (Centl_sci_mirage_policy.level_text loaded.level);
              Alcotest.(check bool)
                "publication remains false" false loaded.network_publication))

let () =
  Alcotest.run "CENTL-MIRAGE policy"
    [
      ( "autonomy",
        [
          Alcotest.test_case "default" `Quick test_default_is_stage;
          Alcotest.test_case "stage" `Quick test_stage_cannot_activate;
          Alcotest.test_case "local" `Quick test_local_cannot_activate_core;
          Alcotest.test_case "persist" `Quick test_round_trip;
        ] );
    ]
