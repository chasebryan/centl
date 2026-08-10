let candidate ~id ~strategy ~source_requirement ~capability_inputs =
  let state = Centl_sci_mirage_candidate.Planned in
  let obligation_ids = [ "obligation:1:candidate_parses" ] in
  let assurance = "test assurance; no promotion" in
  let mutates_workspace = false in
  let transaction_fingerprint =
    Centl_sci_mirage_candidate.transaction_fingerprint ~id ~cell_id:1
      ~source_requirement ~strategy ~state ~capability_inputs ~obligation_ids
      ~assurance ~mutates_workspace
  in
  {
    Centl_sci_mirage_candidate.id;
    cell_id = 1;
    source_requirement;
    strategy;
    state;
    capability_inputs;
    obligation_ids;
    assurance;
    mutates_workspace;
    transaction_fingerprint;
  }

let test_deterministic_native_source_materializes () =
  let value =
    candidate ~id:"candidate:cell:1:downstream_extension"
      ~strategy:Centl_sci_mirage_candidate.Downstream_extension
      ~source_requirement:"create a value named mirage_tau equal to 2*pi"
      ~capability_inputs:[]
  in
  let item = Centl_sci_mirage_materialize.materialize_candidate value in
  Alcotest.(check string) "materialized state" "materialized_source"
    (Centl_sci_mirage_materialize.state_text item.state);
  Alcotest.(check bool) "authoritative parser accepted source" true
    item.parser_validated;
  Alcotest.(check bool) "source retained" true (Option.is_some item.source);
  Alcotest.(check bool) "source digest retained" true
    (match item.source_sha256 with Some value -> String.length value = 64 | None -> false);
  Alcotest.(check int) "materialization identity length" 64
    (String.length item.materialization_fingerprint)

let test_unknown_requirement_is_blocked_not_guessed () =
  let value =
    candidate ~id:"candidate:cell:1:downstream_extension"
      ~strategy:Centl_sci_mirage_candidate.Downstream_extension
      ~source_requirement:"invent a brilliant new tensor language automatically"
      ~capability_inputs:[]
  in
  let item = Centl_sci_mirage_materialize.materialize_candidate value in
  Alcotest.(check string) "blocked state" "blocked"
    (Centl_sci_mirage_materialize.state_text item.state);
  Alcotest.(check bool) "no invented source" true (Option.is_none item.source);
  Alcotest.(check bool) "no parser claim" false item.parser_validated

let test_existing_composition_stays_declarative () =
  let value =
    candidate ~id:"candidate:cell:1:compose_existing"
      ~strategy:Centl_sci_mirage_candidate.Compose_existing
      ~source_requirement:"reuse exact rational arithmetic"
      ~capability_inputs:[ "exact_rational" ]
  in
  let item = Centl_sci_mirage_materialize.materialize_candidate value in
  Alcotest.(check string) "declarative state" "declarative_reuse"
    (Centl_sci_mirage_materialize.state_text item.state);
  Alcotest.(check bool) "no unnecessary generated source" true (Option.is_none item.source);
  Alcotest.(check bool) "syntax not falsely claimed" false item.parser_validated

let test_core_patch_never_auto_materializes () =
  let value =
    candidate ~id:"candidate:cell:1:isolated_core_patch"
      ~strategy:Centl_sci_mirage_candidate.Isolated_core_patch
      ~source_requirement:"change verified arithmetic semantics"
      ~capability_inputs:[]
  in
  let item = Centl_sci_mirage_materialize.materialize_candidate value in
  Alcotest.(check string) "core candidate blocked" "blocked"
    (Centl_sci_mirage_materialize.state_text item.state);
  Alcotest.(check bool) "core source not invented" true (Option.is_none item.source)

let test_artifact_denies_activation_and_promotion () =
  let root = Filename.temp_file "centl-mirage-materialize-" ".candidates.json" in
  let output = Centl_sci_mirage_materialize.output_path root in
  Fun.protect
    ~finally:(fun () ->
      (try Sys.remove root with _ -> ());
      (try Sys.remove output with _ -> ()))
    (fun () ->
      let value =
        candidate ~id:"candidate:cell:1:downstream_extension"
          ~strategy:Centl_sci_mirage_candidate.Downstream_extension
          ~source_requirement:"create a value named mirage_tau equal to 2*pi"
          ~capability_inputs:[]
      in
      let report : Centl_sci_mirage_candidate.report =
        { candidates = [ value ]; blocked_cells = [] }
      in
      match Centl_sci_mirage_materialize.construct root report with
      | Error message -> Alcotest.fail message
      | Ok (path, _) ->
          let text = Yojson.Safe.from_file path |> Yojson.Safe.to_string in
          Alcotest.(check bool) "workspace not mutated" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"workspace_mutated\":false" text));
          Alcotest.(check bool) "candidate not activated" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"candidate_activated\":false" text));
          Alcotest.(check bool) "assurance not promoted" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"\"assurance_promoted\":false" text)))

let () =
  Alcotest.run "CENTL-MIRAGE materialization"
    [
      ( "materialization",
        [
          Alcotest.test_case "deterministic native source" `Quick
            test_deterministic_native_source_materializes;
          Alcotest.test_case "unknown requirement blocks" `Quick
            test_unknown_requirement_is_blocked_not_guessed;
          Alcotest.test_case "existing composition is declarative" `Quick
            test_existing_composition_stays_declarative;
          Alcotest.test_case "core patch is never synthesized" `Quick
            test_core_patch_never_auto_materializes;
          Alcotest.test_case "artifact denies activation" `Quick
            test_artifact_denies_activation_and_promotion;
        ] );
    ]
