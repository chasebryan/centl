let test_default_corpus_is_deterministic () =
  let first = Centl_sci_mirage_fingerprint.observe_default () in
  let second = Centl_sci_mirage_fingerprint.observe_default () in
  Alcotest.(check string)
    "stable fingerprint" first.fingerprint second.fingerprint;
  Alcotest.(check int) "fingerprint length" 64 (String.length first.fingerprint);
  Alcotest.(check bool)
    "observations recorded" true
    (List.length first.observations
    = List.length Centl_sci_mirage_fingerprint.default_corpus);
  Alcotest.(check bool)
    "exact addition remains exact" true
    (List.exists
       (fun observation ->
         observation.Centl_sci_mirage_fingerprint.source = "0.1 + 0.2"
         && observation.text = "3/10" && observation.status = "ok")
       first.observations)

let test_error_is_an_observation () =
  let report = Centl_sci_mirage_fingerprint.observe [ "1 / 0" ] in
  match report.observations with
  | [ observation ] ->
      Alcotest.(check string) "status" "error" observation.status;
      Alcotest.(check string) "kind" "division_by_zero" observation.value_kind
  | _ -> Alcotest.fail "expected one observation"

let test_loaded_definition_cannot_silently_change_core () =
  let baseline = Centl_sci_mirage_fingerprint.observe_default () in
  let candidate =
    Centl_sci_mirage_fingerprint.observe_with_definitions [ "square(x) = x^2" ]
      Centl_sci_mirage_fingerprint.default_corpus
  in
  let report = Centl_sci_mirage_compare.compare_reports ~baseline ~candidate in
  Alcotest.(check bool)
    "unrelated local definition leaves core corpus intact" true
    report.core_preserved

let test_added_observations_do_not_break_core () =
  let baseline = Centl_sci_mirage_fingerprint.observe_default () in
  let candidate =
    Centl_sci_mirage_fingerprint.observe
      (Centl_sci_mirage_fingerprint.default_corpus @ [ "1 + 1" ])
  in
  let report = Centl_sci_mirage_compare.compare_reports ~baseline ~candidate in
  Alcotest.(check bool) "core preserved" true report.core_preserved;
  Alcotest.(check bool)
    "full corpus is not identical" false report.behavior_preserved

let test_compare_detects_change () =
  let baseline = Centl_sci_mirage_fingerprint.observe [ "1 + 1" ] in
  let candidate = Centl_sci_mirage_fingerprint.observe [ "1 + 2" ] in
  let same =
    Centl_sci_mirage_compare.compare_reports ~baseline ~candidate:baseline
  in
  Alcotest.(check bool)
    "identical corpus preserved" true same.behavior_preserved;
  let changed = Centl_sci_mirage_compare.compare_reports ~baseline ~candidate in
  Alcotest.(check bool)
    "different sources are not preserved" false changed.behavior_preserved

let () =
  Alcotest.run "CENTL-MIRAGE semantic fingerprints"
    [
      ( "fingerprint",
        [
          Alcotest.test_case "deterministic corpus" `Quick
            test_default_corpus_is_deterministic;
          Alcotest.test_case "errors are observations" `Quick
            test_error_is_an_observation;
          Alcotest.test_case "comparison" `Quick test_compare_detects_change;
          Alcotest.test_case "shadowing detected" `Quick
            test_loaded_definition_cannot_silently_change_core;
          Alcotest.test_case "added observations" `Quick
            test_added_observations_do_not_break_core;
        ] );
    ]
