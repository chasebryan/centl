let write_json path json =
  Centl_sci_workspace.ensure_directory (Filename.dirname path);
  Centl_sci_workspace.atomic_write_json path json

let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let cell id kind text =
  `Assoc
    [
      ("id", `Int id);
      ("kind", `String kind);
      ("start_line", `Int id);
      ("end_line", `Int id);
      ("text", `String text);
    ]

let spec cells =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("cells", `List cells);
    ]

let find_gap id graph =
  List.find_opt
    (fun gap -> gap.Centl_sci_mirage_goal.cell_id = id)
    graph.Centl_sci_mirage_goal.gaps

let test_opposite_hard_requirements_conflict () =
  let left : Centl_sci_mirage_goal.spec_cell =
    {
      id = 1;
      kind = "DIRECTIVE";
      text = "Add a network dependency for model inference";
      start_line = 1;
      end_line = 1;
    }
  in
  let right : Centl_sci_mirage_goal.spec_cell =
    {
      id = 2;
      kind = "NON_GOAL";
      text = "Do not add a network dependency for model inference";
      start_line = 2;
      end_line = 2;
    }
  in
  Alcotest.(check bool)
    "opposite matching requirements conflict" true
    (Centl_sci_mirage_goal.likely_conflict left right)

let test_unrelated_negative_requirement_does_not_conflict () =
  let left : Centl_sci_mirage_goal.spec_cell =
    {
      id = 1;
      kind = "DIRECTIVE";
      text = "Add exact polynomial interpolation";
      start_line = 1;
      end_line = 1;
    }
  in
  let right : Centl_sci_mirage_goal.spec_cell =
    {
      id = 2;
      kind = "NON_GOAL";
      text = "Do not add a network dependency";
      start_line = 2;
      end_line = 2;
    }
  in
  Alcotest.(check bool)
    "unrelated constraints stay separate" false
    (Centl_sci_mirage_goal.likely_conflict left right)

let test_gap_analysis_prefers_existing_composition () =
  let root = temp_dir "centl-mirage-goal-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      Centl_sci_workspace.ensure workspace;
      let graph =
        Centl_sci_mirage_goal.build workspace
          [
            {
              Centl_sci_mirage_goal.id = 1;
              kind = "DIRECTIVE";
              text = "Allow users to differentiate symbolic expressions";
              start_line = 1;
              end_line = 1;
            };
          ]
      in
      match find_gap 1 graph with
      | None -> Alcotest.fail "expected a gap classification"
      | Some gap ->
          Alcotest.(check string)
            "reuse before synthesis" "COMPOSABLE"
            (Centl_sci_mirage_goal.gap_status_text gap.status);
          Alcotest.(check bool)
            "diff capability matched" true
            (List.mem "diff" gap.capability_matches))

let test_existing_composition_is_satisfied () =
  let root = temp_dir "centl-mirage-satisfied-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      Centl_sci_workspace.ensure workspace;
      let graph =
        Centl_sci_mirage_goal.build workspace
          [
            {
              Centl_sci_mirage_goal.id = 1;
              kind = "DIRECTIVE";
              text = "compute gcd of 48 and 18";
              start_line = 1;
              end_line = 1;
            };
          ]
      in
      match find_gap 1 graph with
      | None -> Alcotest.fail "expected a gap classification"
      | Some gap ->
          Alcotest.(check string)
            "existing composition is satisfied" "SATISFIED"
            (Centl_sci_mirage_goal.gap_status_text gap.status))

let test_explicit_native_definition_requires_staging () =
  let root = temp_dir "centl-mirage-native-definition-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      Centl_sci_workspace.ensure workspace;
      let graph =
        Centl_sci_mirage_goal.build workspace
          [
            {
              Centl_sci_mirage_goal.id = 1;
              kind = "DIRECTIVE";
              text = "create a value named mirage_tau equal to 2*pi";
              start_line = 1;
              end_line = 1;
            };
          ]
      in
      match find_gap 1 graph with
      | None -> Alcotest.fail "expected a gap classification"
      | Some gap ->
          Alcotest.(check string)
            "a requested new binding is not mistaken for an already satisfied \
             composition"
            "EXTENSION_REQUIRED"
            (Centl_sci_mirage_goal.gap_status_text gap.status);
          Alcotest.(check bool)
            "generation capability may still be reused" true
            (List.mem "English-to-CENTL extension" gap.capability_matches))

let test_unknown_capability_requires_extension () =
  let root = temp_dir "centl-mirage-extension-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let graph =
        Centl_sci_mirage_goal.build workspace
          [
            {
              Centl_sci_mirage_goal.id = 1;
              kind = "DIRECTIVE";
              text = "Implement quasar_flux_tensorization";
              start_line = 1;
              end_line = 1;
            };
          ]
      in
      match find_gap 1 graph with
      | None -> Alcotest.fail "expected a gap classification"
      | Some gap ->
          Alcotest.(check string)
            "unknown objective is not fabricated" "EXTENSION_REQUIRED"
            (Centl_sci_mirage_goal.gap_status_text gap.status))

let test_spec_analysis_persists_graph () =
  let root = temp_dir "centl-mirage-graph-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let spec_path = Filename.concat root "design.spec.json" in
      write_json spec_path
        (spec
           [
             cell 1 "DIRECTIVE" "Add exact polynomial interpolation";
             cell 2 "ACCEPTANCE" "Acceptance: exact rational inputs stay exact";
             cell 3 "QUESTION" "Which interpolation basis should be exposed?";
           ]);
      match Centl_sci_mirage_goal.analyze workspace spec_path with
      | Error message -> Alcotest.fail message
      | Ok (path, graph) ->
          Alcotest.(check bool)
            "goal graph persisted" true (Sys.file_exists path);
          Alcotest.(check bool)
            "question becomes ambiguity" true
            (match find_gap 3 graph with
            | Some gap -> gap.status = Centl_sci_mirage_goal.Ambiguous
            | None -> false);
          Alcotest.(check bool)
            "acceptance refines prior objective" true
            (List.exists
               (fun edge ->
                 edge.Centl_sci_mirage_goal.kind = Centl_sci_mirage_goal.Refines
                 && edge.source = "cell:2" && edge.target = "cell:1")
               graph.edges);
          Alcotest.(check bool)
            "objective is validated by acceptance" true
            (List.exists
               (fun edge ->
                 edge.Centl_sci_mirage_goal.kind
                 = Centl_sci_mirage_goal.Validated_by
                 && edge.source = "cell:1" && edge.target = "cell:2")
               graph.edges))

let () =
  Alcotest.run "CENTL-MIRAGE goal graph"
    [
      ( "analysis",
        [
          Alcotest.test_case "opposite hard requirements" `Quick
            test_opposite_hard_requirements_conflict;
          Alcotest.test_case "unrelated negative requirement" `Quick
            test_unrelated_negative_requirement_does_not_conflict;
          Alcotest.test_case "reuse existing capability" `Quick
            test_gap_analysis_prefers_existing_composition;
          Alcotest.test_case "composed requirement satisfied" `Quick
            test_existing_composition_is_satisfied;
          Alcotest.test_case "explicit native definition" `Quick
            test_explicit_native_definition_requires_staging;
          Alcotest.test_case "unknown capability" `Quick
            test_unknown_capability_requires_extension;
          Alcotest.test_case "persist graph" `Quick
            test_spec_analysis_persists_graph;
        ] );
    ]
