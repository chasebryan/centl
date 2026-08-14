let test_workbook_recovers_exact_expression () =
  let session = Centl_sci_session.create () in
  ignore
    (Centl_sci_session.add session ~input:"What is 0.1 plus 0.2?"
       ~normalized:"What is 0.1 plus 0.2?" ~mode:Centl_sci_interaction.Hybrid
       ~intent:"arithmetic" ~result:"3/10" ~details:"exact"
       ~workspace_revision:None);
  let rendered = Centl_sci_workbook.render session in
  Alcotest.(check bool)
    "contains recovered source" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"0.1 + 0.2" rendered));
  Alcotest.(check bool)
    "does not claim verified core" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"Not verified-core"
          rendered))

let () =
  Alcotest.run "CENTL-SCi workbook"
    [
      ( "export",
        [
          Alcotest.test_case "recover expression" `Quick
            test_workbook_recovers_exact_expression;
        ] );
    ]
