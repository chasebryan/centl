let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let cell id kind text : Centl_sci_mirage_goal.spec_cell =
  { id; kind; text; start_line = id; end_line = id }

let make_reports workspace cells =
  let graph = Centl_sci_mirage_goal.build workspace cells in
  let obligations = Centl_sci_mirage_obligation.build graph in
  let candidates = Centl_sci_mirage_candidate.build graph obligations in
  let materialization = Centl_sci_mirage_materialize.build candidates in
  ( obligations,
    candidates,
    materialization,
    Centl_sci_mirage_readiness.build obligations candidates materialization )

let only_readiness report =
  match report.Centl_sci_mirage_readiness.candidates with
  | [ candidate ] -> candidate
  | _ -> Alcotest.fail "expected exactly one candidate readiness record"

let find_check kind candidate =
  match
    List.find_opt
      (fun check -> String.equal check.Centl_sci_mirage_readiness.kind kind)
      candidate.Centl_sci_mirage_readiness.checks
  with
  | Some check -> check
  | None -> Alcotest.fail ("missing readiness check: " ^ kind)

let test_extension_keeps_execution_gates_pending () =
  let root = temp_dir "centl-mirage-readiness-extension-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let _, _, _, report =
        make_reports workspace
          [ cell 1 "DIRECTIVE" "Implement quasar_flux_tensorization" ]
      in
      let candidate = only_readiness report in
      Alcotest.(check bool)
        "execution still required" true candidate.execution_required;
      Alcotest.(check bool)
        "assurance not promoted" false candidate.assurance_promoted;
      let parse = find_check "candidate_parses" candidate in
      Alcotest.(check string)
        "parser gate pending" "execution_required"
        (Centl_sci_mirage_readiness.state_text parse.state);
      let trust = find_check "trust_boundary_explicit" candidate in
      Alcotest.(check string)
        "trust boundary structurally explicit" "structurally_established"
        (Centl_sci_mirage_readiness.state_text trust.state))

let test_materialized_parser_success_is_consumed () =
  let root = temp_dir "centl-mirage-readiness-parser-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let _, _, materialization, report =
        make_reports workspace
          [ cell 1 "DIRECTIVE" "create a value named mirage_tau equal to 2*pi" ]
      in
      let item =
        match materialization.Centl_sci_mirage_materialize.items with
        | [ item ] -> item
        | _ -> Alcotest.fail "expected one materialization item"
      in
      Alcotest.(check bool)
        "parser actually executed" true item.parser_validated;
      let candidate = only_readiness report in
      let parse = find_check "candidate_parses" candidate in
      Alcotest.(check string)
        "successful parser evidence consumed" "structurally_established"
        (Centl_sci_mirage_readiness.state_text parse.state);
      let regression = find_check "mandatory_regression" candidate in
      Alcotest.(check string)
        "regression remains pending" "execution_required"
        (Centl_sci_mirage_readiness.state_text regression.state);
      Alcotest.(check bool)
        "candidate still needs evidence execution" true
        candidate.execution_required)

let test_composition_records_reuse_as_structural_only () =
  let root = temp_dir "centl-mirage-readiness-compose-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      Centl_sci_workspace.ensure workspace;
      let _, _, _, report =
        make_reports workspace
          [
            cell 1 "DIRECTIVE"
              "Allow users to differentiate symbolic expressions";
          ]
      in
      let candidate = only_readiness report in
      let reuse = find_check "reuse_attempted" candidate in
      Alcotest.(check string)
        "reuse structurally established" "structurally_established"
        (Centl_sci_mirage_readiness.state_text reuse.state);
      Alcotest.(check bool)
        "regressions still required" true candidate.execution_required)

let test_blocked_cell_never_acquires_readiness_candidate () =
  let root = temp_dir "centl-mirage-readiness-blocked-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let _, _, _, report =
        make_reports workspace
          [ cell 1 "QUESTION" "Which interpolation basis should be exposed?" ]
      in
      Alcotest.(check (list int))
        "blocked cell preserved" [ 1 ] report.blocked_cells;
      Alcotest.(check int)
        "no readiness candidate invented" 0
        (List.length report.candidates))

let test_construct_persists_non_admissibility () =
  let root = temp_dir "centl-mirage-readiness-file-" in
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
      let candidates = Centl_sci_mirage_candidate.build graph obligations in
      let materialization = Centl_sci_mirage_materialize.build candidates in
      match
        Centl_sci_mirage_readiness.construct
          (Filename.concat root "design.candidates.json")
          obligations candidates materialization
      with
      | Error message -> Alcotest.fail message
      | Ok (path, _) ->
          Alcotest.(check string)
            "artifact suffix" "design.readiness.json" (Filename.basename path);
          let json = Yojson.Safe.from_file path in
          let text = Yojson.Safe.to_string json in
          Alcotest.(check bool)
            "artifact explicitly denies admission" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"admissible\":false" text));
          Alcotest.(check bool)
            "workspace remains untouched" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"workspace_mutated\":false" text));
          Alcotest.(check bool)
            "materialization semantics persisted" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"materialization_evidence_semantics\"" text)))

let () =
  Alcotest.run "CENTL-MIRAGE evidence readiness"
    [
      ( "readiness",
        [
          Alcotest.test_case "extension keeps executable gates pending" `Quick
            test_extension_keeps_execution_gates_pending;
          Alcotest.test_case "materialized parser evidence is consumed" `Quick
            test_materialized_parser_success_is_consumed;
          Alcotest.test_case "composition reuse is structural evidence" `Quick
            test_composition_records_reuse_as_structural_only;
          Alcotest.test_case "blocked source creates no readiness candidate"
            `Quick test_blocked_cell_never_acquires_readiness_candidate;
          Alcotest.test_case "persist readiness artifact" `Quick
            test_construct_persists_non_admissibility;
        ] );
    ]
