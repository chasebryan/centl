let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path =
  try Centl_sci_snapshot.remove_tree path with _ -> ()

let cell id kind text : Centl_sci_mirage_goal.spec_cell =
  { id; kind; text; start_line = id; end_line = id }

let build_report workspace =
  let graph =
    Centl_sci_mirage_goal.build workspace
      [ cell 1 "DIRECTIVE" "Implement quasar_flux_tensorization" ]
  in
  let obligations = Centl_sci_mirage_obligation.build graph in
  let candidates = Centl_sci_mirage_candidate.build graph obligations in
  let readiness = Centl_sci_mirage_readiness.build obligations candidates in
  Centl_sci_mirage_execution_plan.build readiness

let test_plan_contains_pending_work () =
  let root = temp_dir "centl-mirage-plan-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      let report = build_report workspace in
      match report.Centl_sci_mirage_execution_plan.candidates with
      | [ candidate ] ->
          Alcotest.(check bool) "has planned work" true
            (candidate.actions <> []);
          Alcotest.(check bool) "all actions planned" true
            (List.for_all
               (fun action -> String.equal action.Centl_sci_mirage_execution_plan.state "planned")
               candidate.actions)
      | _ -> Alcotest.fail "expected one candidate")

let test_artifact_denies_execution () =
  let root = temp_dir "centl-mirage-plan-file-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make (Filename.concat root "workspace") in
      let report = build_report workspace in
      match
        Centl_sci_mirage_execution_plan.construct
          (Filename.concat root "design.readiness.json") report
      with
      | Error message -> Alcotest.fail message
      | Ok (path, _) ->
          let text = Yojson.Safe.from_file path |> Yojson.Safe.to_string in
          Alcotest.(check bool) "execution not performed" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"execution_performed\":false" text));
          Alcotest.(check bool) "assurance unchanged" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"assurance_promoted\":false" text)))

let () =
  Alcotest.run "CENTL-MIRAGE execution plan"
    [
      ( "planning",
        [
          Alcotest.test_case "pending work is planned" `Quick test_plan_contains_pending_work;
          Alcotest.test_case "artifact does not claim execution" `Quick
            test_artifact_denies_execution;
        ] );
    ]
