let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let cell id kind text : Centl_sci_mirage_goal.spec_cell =
  { id; kind; text; start_line = id; end_line = id }

let make_report workspace cells =
  let graph = Centl_sci_mirage_goal.build workspace cells in
  let obligations = Centl_sci_mirage_obligation.build graph in
  (graph, obligations, Centl_sci_mirage_candidate.build graph obligations)

let only_candidate report =
  match report.Centl_sci_mirage_candidate.candidates with
  | [ candidate ] -> candidate
  | _ -> Alcotest.fail "expected exactly one staged candidate"

let test_extension_is_staged_without_mutation () =
  let root = temp_dir "centl-mirage-candidate-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let requirement = "Implement quasar_flux_tensorization" in
      let _, _, report =
        make_report workspace [ cell 1 "DIRECTIVE" requirement ]
      in
      let candidate = only_candidate report in
      Alcotest.(check string)
        "strategy" "downstream_extension"
        (Centl_sci_mirage_candidate.strategy_text candidate.strategy);
      Alcotest.(check string)
        "source requirement retained" requirement candidate.source_requirement;
      Alcotest.(check bool)
        "transaction does not mutate workspace" false
        candidate.mutates_workspace;
      Alcotest.(check bool)
        "obligations attached" true
        (candidate.obligation_ids <> []);
      Alcotest.(check bool)
        "assurance is explicitly unverified" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"unverified"
              candidate.assurance));
      Alcotest.(check int)
        "sha256 fingerprint length" 64
        (String.length candidate.transaction_fingerprint))

let test_composition_retains_capability_inputs () =
  let root = temp_dir "centl-mirage-candidate-compose-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      Centl_sci_workspace.ensure workspace;
      let _, _, report =
        make_report workspace
          [
            cell 1 "DIRECTIVE"
              "Allow users to differentiate symbolic expressions";
          ]
      in
      let candidate = only_candidate report in
      Alcotest.(check string)
        "strategy" "compose_existing"
        (Centl_sci_mirage_candidate.strategy_text candidate.strategy);
      Alcotest.(check bool)
        "matched capabilities retained" true
        (candidate.capability_inputs <> []))

let test_blocked_source_creates_no_candidate () =
  let root = temp_dir "centl-mirage-candidate-blocked-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let _, _, report =
        make_report workspace
          [ cell 1 "QUESTION" "Which interpolation basis should be exposed?" ]
      in
      Alcotest.(check (list int))
        "blocked cell preserved" [ 1 ] report.blocked_cells;
      Alcotest.(check int)
        "no candidate invented" 0
        (List.length report.candidates))

let test_transaction_fingerprint_is_deterministic () =
  let root = temp_dir "centl-mirage-candidate-fingerprint-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let _, _, first =
        make_report workspace
          [ cell 1 "DIRECTIVE" "Implement quasar_flux_tensorization" ]
      in
      let _, _, second =
        make_report workspace
          [ cell 1 "DIRECTIVE" "Implement quasar_flux_tensorization" ]
      in
      Alcotest.(check string)
        "same staged transaction has same identity"
        (only_candidate first).transaction_fingerprint
        (only_candidate second).transaction_fingerprint)

let test_transaction_fingerprint_detects_plan_drift () =
  let root = temp_dir "centl-mirage-candidate-drift-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let _, _, extension_report =
        make_report workspace
          [ cell 1 "DIRECTIVE" "Implement quasar_flux_tensorization" ]
      in
      let _, _, composition_report =
        make_report workspace
          [
            cell 1 "DIRECTIVE"
              "Allow users to differentiate symbolic expressions";
          ]
      in
      Alcotest.(check bool)
        "different transaction structure changes identity" true
        ((only_candidate extension_report).transaction_fingerprint
       <> (only_candidate composition_report).transaction_fingerprint))

let test_transaction_fingerprint_detects_requirement_drift () =
  let root = temp_dir "centl-mirage-candidate-requirement-drift-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let _, _, first =
        make_report workspace
          [ cell 1 "DIRECTIVE" "Implement quasar_flux_tensorization" ]
      in
      let _, _, second =
        make_report workspace
          [ cell 1 "DIRECTIVE" "Implement pulsar_phase_tensorization" ]
      in
      let first = only_candidate first in
      let second = only_candidate second in
      Alcotest.(check string)
        "same strategy retained"
        (Centl_sci_mirage_candidate.strategy_text first.strategy)
        (Centl_sci_mirage_candidate.strategy_text second.strategy);
      Alcotest.(check bool)
        "different requirement changes identity" true
        (first.transaction_fingerprint <> second.transaction_fingerprint))

let test_construct_persists_transaction_artifact () =
  let root = temp_dir "centl-mirage-candidate-file-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let graph =
        Centl_sci_mirage_goal.build workspace
          [ cell 1 "DIRECTIVE" "Implement quasar_flux_tensorization" ]
      in
      let obligations = Centl_sci_mirage_obligation.build graph in
      let obligation_path = Filename.concat root "design.obligations.json" in
      match
        Centl_sci_mirage_candidate.construct obligation_path graph obligations
      with
      | Error message -> Alcotest.fail message
      | Ok (path, report) ->
          Alcotest.(check bool)
            "candidate artifact exists" true (Sys.file_exists path);
          Alcotest.(check string)
            "artifact suffix" "design.candidates.json" (Filename.basename path);
          Alcotest.(check int)
            "candidate persisted" 1
            (List.length report.candidates);
          let json = Yojson.Safe.from_file path in
          let fingerprint_semantics =
            match json with
            | `Assoc fields ->
                begin match List.assoc_opt "fingerprint_semantics" fields with
                | Some (`String value) -> value
                | _ -> ""
                end
            | _ -> ""
          in
          Alcotest.(check bool)
            "artifact denies proof semantics" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"not behavioral validation" fingerprint_semantics)))

let () =
  Alcotest.run "CENTL-MIRAGE candidate transactions"
    [
      ( "staging",
        [
          Alcotest.test_case "extension remains staged" `Quick
            test_extension_is_staged_without_mutation;
          Alcotest.test_case "composition records inputs" `Quick
            test_composition_retains_capability_inputs;
          Alcotest.test_case "blocked input produces no candidate" `Quick
            test_blocked_source_creates_no_candidate;
          Alcotest.test_case "transaction identity deterministic" `Quick
            test_transaction_fingerprint_is_deterministic;
          Alcotest.test_case "transaction identity detects plan drift" `Quick
            test_transaction_fingerprint_detects_plan_drift;
          Alcotest.test_case "transaction identity detects requirement drift"
            `Quick test_transaction_fingerprint_detects_requirement_drift;
          Alcotest.test_case "persist artifact" `Quick
            test_construct_persists_transaction_artifact;
        ] );
    ]
