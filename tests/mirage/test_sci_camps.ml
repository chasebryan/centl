let test_occupation_does_not_declare_oasis () =
  let occupation = Centl_sci_camps.inspect () in
  Alcotest.(check bool) "oasis declared" false occupation.oasis_declared;
  Alcotest.(check string) "published" "0.14.0" occupation.published_oasis;
  Alcotest.(check bool) "camp occupied" true (occupation.occupied <> []);
  Alcotest.(check bool)
    "summary is a stay"
    true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"not an Oasis"
          occupation.summary))

let test_camp_001_forbids_oasis_declaration () =
  match Centl_sci_camps.find_record "CAMP-001" with
  | None -> Alcotest.fail "missing CAMP-001"
  | Some camp ->
      Alcotest.(check bool) "not declared" false camp.oasis_declared;
      Alcotest.(check string)
        "status" "occupied"
        (Centl_sci_camps.status_text camp.status);
      Alcotest.(check (option string))
        "artifact tag" (Some "fcf-camp-001") camp.artifact_tag;
      Alcotest.(check bool)
        "explains why Oasis is withheld" true
        (camp.why_not_oasis <> []);
      begin match Centl_sci_camps.to_json (Centl_sci_camps.inspect ()) with
      | `Assoc fields ->
          Alcotest.(check bool)
            "JSON never declares Oasis" true
            (List.assoc "oasis_declared_by_this_command" fields = `Bool false)
      | _ -> Alcotest.fail "camp JSON must be an object"
      end

let () =
  Alcotest.run "FCF Camps"
    [
      ( "occupation",
        [
          Alcotest.test_case "no Oasis" `Quick
            test_occupation_does_not_declare_oasis;
          Alcotest.test_case "CAMP-001" `Quick
            test_camp_001_forbids_oasis_declaration;
        ] );
    ]
