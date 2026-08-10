let add session id ~revision =
  ignore
    (Centl_sci_session.add session ~input:("input " ^ string_of_int id)
       ~normalized:("normalized " ^ string_of_int id)
       ~mode:Centl_sci_interaction.Hybrid ~intent:"arithmetic"
       ~result:("result " ^ string_of_int id)
       ~details:("details " ^ string_of_int id) ~workspace_revision:revision)

let test_result_order_and_last () =
  let session = Centl_sci_session.create () in
  add session 1 ~revision:(Some 4);
  add session 2 ~revision:(Some 5);
  begin match Centl_sci_session.last session with
  | None -> Alcotest.fail "expected last result"
  | Some record ->
      Alcotest.(check int) "last id" 2 record.id;
      Alcotest.(check (option int)) "last revision" (Some 5)
        record.workspace_revision
  end;
  match Centl_sci_session.all session with
  | [ first; second ] ->
      Alcotest.(check int) "chronological first" 1 first.id;
      Alcotest.(check int) "chronological second" 2 second.id
  | _ -> Alcotest.fail "expected two chronological result records"

let test_bounded_retention () =
  let session = Centl_sci_session.create ~max_results:2 () in
  add session 1 ~revision:None;
  add session 2 ~revision:None;
  add session 3 ~revision:None;
  Alcotest.(check bool) "oldest evicted" true
    (Option.is_none (Centl_sci_session.find session 1));
  Alcotest.(check bool) "second retained" true
    (Option.is_some (Centl_sci_session.find session 2));
  Alcotest.(check bool) "third retained" true
    (Option.is_some (Centl_sci_session.find session 3));
  match Centl_sci_session.all session with
  | [ second; third ] ->
      Alcotest.(check int) "bounded first" 2 second.id;
      Alcotest.(check int) "bounded second" 3 third.id
  | _ -> Alcotest.fail "bounded result session should retain the two newest records"

let test_render_preserves_provenance () =
  let session = Centl_sci_session.create () in
  add session 1 ~revision:(Some 17);
  let record =
    match Centl_sci_session.last session with
    | Some record -> record
    | None -> Alcotest.fail "missing result record"
  in
  let rendered = Centl_sci_session.render record in
  Alcotest.(check bool) "revision rendered" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"workspace revision: 17"
          rendered));
  Alcotest.(check bool) "normalization rendered" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"normalized: normalized 1"
          rendered))

let () =
  Alcotest.run "CENTL-SCi Caramels result session"
    [
      ( "recall",
        [
          Alcotest.test_case "ordering and last" `Quick
            test_result_order_and_last;
          Alcotest.test_case "bounded retention" `Quick test_bounded_retention;
          Alcotest.test_case "provenance render" `Quick
            test_render_preserves_provenance;
        ] );
    ]
