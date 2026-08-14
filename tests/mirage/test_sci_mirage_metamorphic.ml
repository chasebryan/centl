let trial source =
  {
    Centl_sci_mirage_cegis.iteration = 1;
    candidate_id = "candidate:cell:1:downstream_extension";
    source = Some source;
    examples_checked = 1;
    counterexamples = [];
    state = Centl_sci_mirage_cegis.Valid;
  }

let test_substitution_property_holds () =
  let example =
    {
      Centl_sci_mirage_cegis.cell_id = 3;
      source_text = "Acceptance: kinetic_energy(2, 3) returns 9";
      left = "kinetic_energy(2, 3)";
      right = "9";
    }
  in
  let cegis =
    {
      Centl_sci_mirage_cegis.examples = [ example ];
      trials =
        [ trial "kinetic_energy(mass, velocity) = 1/2 * mass * velocity^2" ];
      budget = 2;
      accepted_source =
        Some "kinetic_energy(mass, velocity) = 1/2 * mass * velocity^2";
    }
  in
  let report = Centl_sci_mirage_metamorphic.run cegis in
  Alcotest.(check bool)
    "has established properties" true
    (List.exists
       (fun property ->
         property.Centl_sci_mirage_metamorphic.status
         = Centl_sci_mirage_metamorphic.Established)
       report.properties);
  Alcotest.(check bool)
    "substitution checked" true
    (List.exists
       (fun property ->
         property.Centl_sci_mirage_metamorphic.kind
         = Centl_sci_mirage_metamorphic.Substitution
         && property.status = Centl_sci_mirage_metamorphic.Established)
       report.properties)

let () =
  Alcotest.run "CENTL-MIRAGE metamorphic"
    [
      ( "properties",
        [
          Alcotest.test_case "substitution" `Quick
            test_substitution_property_holds;
        ] );
    ]
