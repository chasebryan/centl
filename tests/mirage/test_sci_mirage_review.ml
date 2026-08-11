let admission_candidate state candidate_id transaction_fingerprint receipt_fingerprints =
  {
    Centl_sci_mirage_admission.candidate_id;
    transaction_fingerprint;
    state;
    expected_action_count = List.length receipt_fingerprints;
    passed_action_count = List.length receipt_fingerprints;
    pending_action_count = 0;
    blocked_action_count = 0;
    exact_action_coverage = true;
    receipt_fingerprints;
    rationale = "test admission";
  }

let admission candidates =
  { Centl_sci_mirage_admission.candidates; blocked_cells = [] }

let test_only_admissible_candidates_enter_review () =
  let admissible =
    admission_candidate Centl_sci_mirage_admission.Admissible "candidate-a"
      (String.make 64 'a') [ String.make 64 '1' ]
  in
  let pending =
    admission_candidate Centl_sci_mirage_admission.Pending "candidate-p"
      (String.make 64 'b') [ String.make 64 '2' ]
  in
  let blocked =
    admission_candidate Centl_sci_mirage_admission.Blocked "candidate-b"
      (String.make 64 'c') [ String.make 64 '3' ]
  in
  let report = Centl_sci_mirage_review.prepare (admission [ admissible; pending; blocked ]) in
  Alcotest.(check int) "review candidates" 1 (List.length report.candidates);
  Alcotest.(check int) "omitted candidates" 2 report.omitted_candidate_count;
  match report.candidates with
  | [ candidate ] ->
      Alcotest.(check string) "candidate id" "candidate-a" candidate.candidate_id;
      Alcotest.(check int) "review fingerprint length" 64
        (String.length candidate.review_fingerprint)
  | _ -> Alcotest.fail "expected one review candidate"

let test_review_fingerprint_binds_evidence () =
  let candidate receipts =
    admission_candidate Centl_sci_mirage_admission.Admissible "candidate-a"
      (String.make 64 'a') receipts
  in
  let first =
    Centl_sci_mirage_review.prepare (admission [ candidate [ String.make 64 '1' ] ])
  in
  let second =
    Centl_sci_mirage_review.prepare (admission [ candidate [ String.make 64 '2' ] ])
  in
  match (first.candidates, second.candidates) with
  | [ left ], [ right ] ->
      Alcotest.(check bool) "different receipt evidence changes review identity" true
        (not (String.equal left.review_fingerprint right.review_fingerprint))
  | _ -> Alcotest.fail "expected one review candidate in each report"

let test_json_requires_human_acceptance_without_activation () =
  let candidate =
    admission_candidate Centl_sci_mirage_admission.Admissible "candidate-a"
      (String.make 64 'a') [ String.make 64 '1' ]
  in
  let json =
    Centl_sci_mirage_review.prepare (admission [ candidate ])
    |> Centl_sci_mirage_review.to_json
  in
  let open Yojson.Safe.Util in
  Alcotest.(check int) "schema" 1 (json |> member "schema_version" |> to_int);
  Alcotest.(check bool) "human acceptance required" true
    (json |> member "human_acceptance_required" |> to_bool);
  Alcotest.(check bool) "source activation" false
    (json |> member "candidate_source_activated" |> to_bool);
  Alcotest.(check bool) "assurance promotion" false
    (json |> member "assurance_promoted" |> to_bool);
  match json |> member "candidates" |> to_list with
  | [ item ] ->
      Alcotest.(check bool) "human accepted" false
        (item |> member "human_accepted" |> to_bool)
  | _ -> Alcotest.fail "expected one review candidate in JSON"

let test_construct_persists_review_manifest () =
  let candidate =
    admission_candidate Centl_sci_mirage_admission.Admissible "candidate-a"
      (String.make 64 'a') [ String.make 64 '1' ]
  in
  let admission_path = Filename.temp_file "centl-mirage-review" ".admission.json" in
  let review_path = Centl_sci_mirage_review.output_path admission_path in
  Fun.protect
    ~finally:(fun () ->
      if Sys.file_exists admission_path then Sys.remove admission_path;
      if Sys.file_exists review_path then Sys.remove review_path)
    (fun () ->
      match Centl_sci_mirage_review.construct admission_path (admission [ candidate ]) with
      | Error message -> Alcotest.fail message
      | Ok (path, _) ->
          Alcotest.(check string) "derived path" review_path path;
          Alcotest.(check bool) "artifact exists" true (Sys.file_exists path);
          let json = Yojson.Safe.from_file path in
          let open Yojson.Safe.Util in
          Alcotest.(check string) "artifact kind" "candidate_review_manifest"
            (json |> member "artifact_kind" |> to_string);
          Alcotest.(check int) "review count" 1
            (json |> member "review_candidate_count" |> to_int))

let () =
  Alcotest.run "CENTL-SCi MIRAGE review"
    [
      ( "review",
        [
          Alcotest.test_case "admissible only" `Quick
            test_only_admissible_candidates_enter_review;
          Alcotest.test_case "fingerprint binds evidence" `Quick
            test_review_fingerprint_binds_evidence;
          Alcotest.test_case "human acceptance boundary" `Quick
            test_json_requires_human_acceptance_without_activation;
          Alcotest.test_case "persist manifest" `Quick
            test_construct_persists_review_manifest;
        ] );
    ]
