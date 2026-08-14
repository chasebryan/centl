let test_expedition_does_not_designate () =
  let expedition = Centl_sci_wellspring.run_expedition () in
  Alcotest.(check bool)
    "no designated Wellspring" true
    (expedition.designated = []);
  Alcotest.(check bool)
    "records exist" true
    (List.length expedition.records >= 2);
  Alcotest.(check bool)
    "all remain candidates" true
    (List.for_all
       (fun record -> record.Centl_sci_wellspring.status = Candidate)
       expedition.records)

let test_designation_requires_independent_review () =
  match Centl_sci_wellspring.find_record "WS-CAND-001" with
  | None -> Alcotest.fail "missing WS-CAND-001"
  | Some record ->
      Alcotest.(check bool)
        "not permitted" false
        (Centl_sci_wellspring.designation_permitted record);
      let status, note = Centl_sci_wellspring.assess_designation record in
      Alcotest.(check string)
        "status" "candidate"
        (Centl_sci_wellspring.status_text status);
      Alcotest.(check bool)
        "explains why designation is withheld" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"independent" note)
        || Option.is_some
             (Centl_sci_interaction.find_substring ~needle:"unsatisfied" note))

let test_oasis_inspect_never_declares () =
  let report =
    Centl_sci_oasis.inspect ~root:"." ~current_version:Centl_version.value
      ~branch:"main"
  in
  Alcotest.(check bool) "declaration" false report.declaration;
  Alcotest.(check string) "published" "0.14.0" report.published_oasis;
  Alcotest.(check bool)
    "branch blocker" true
    (List.exists
       (fun blocker ->
         Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"not oasis" blocker))
       report.blockers)

let () =
  Alcotest.run "FCF Wellspring"
    [
      ( "expedition",
        [
          Alcotest.test_case "no designation" `Quick
            test_expedition_does_not_designate;
          Alcotest.test_case "review required" `Quick
            test_designation_requires_independent_review;
          Alcotest.test_case "oasis inspect" `Quick
            test_oasis_inspect_never_declares;
        ] );
    ]
