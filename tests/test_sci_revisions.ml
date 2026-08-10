let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path =
  try Centl_sci_snapshot.remove_tree path with _ -> ()

let test_revision_history_tracks_workspace () =
  let root = temp_dir "centl-caramels-revisions-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      Centl_sci_workspace.ensure workspace;
      ignore (Centl_sci_workspace.bump_revision workspace);
      ignore (Centl_sci_workspace.bump_revision workspace);
      ignore (Centl_sci_workspace.bump_revision workspace);
      match Centl_sci_revisions.read workspace with
      | Error message -> Alcotest.fail message
      | Ok history ->
          Alcotest.(check int) "current revision" 3 history.current_revision;
          Alcotest.(check int) "three ledger entries" 3
            (List.length history.entries);
          Alcotest.(check bool) "not truncated" false history.truncated;
          begin match history.entries with
          | [ first; second; third ] ->
              Alcotest.(check int) "first revision" 1 first.revision;
              Alcotest.(check int) "second revision" 2 second.revision;
              Alcotest.(check int) "third revision" 3 third.revision
          | _ -> Alcotest.fail "expected ordered revision entries"
          end)

let test_revision_history_is_bounded () =
  let root = temp_dir "centl-caramels-revisions-bounded-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      Centl_sci_workspace.ensure workspace;
      for _ = 1 to 105 do
        ignore (Centl_sci_workspace.bump_revision workspace)
      done;
      match Centl_sci_revisions.read workspace with
      | Error message -> Alcotest.fail message
      | Ok history ->
          Alcotest.(check int) "current revision" 105 history.current_revision;
          Alcotest.(check int) "bounded entries" 100
            (List.length history.entries);
          Alcotest.(check bool) "truncated" true history.truncated;
          begin match history.entries with
          | first :: _ -> Alcotest.(check int) "oldest retained" 6 first.revision
          | [] -> Alcotest.fail "expected bounded entries"
          end;
          begin match List.rev history.entries with
          | last :: _ -> Alcotest.(check int) "newest retained" 105 last.revision
          | [] -> Alcotest.fail "expected bounded entries"
          end)

let test_revision_json_reports_bound () =
  let history : Centl_sci_revisions.t =
    { current_revision = 0; entries = []; truncated = false }
  in
  match Centl_sci_revisions.to_json history with
  | `Assoc fields ->
      begin match List.assoc_opt "max_entries" fields with
      | Some (`Int value) ->
          Alcotest.(check int) "max entries" Centl_sci_revisions.max_entries value
      | _ -> Alcotest.fail "revision JSON missing max_entries"
      end
  | _ -> Alcotest.fail "revision history JSON must be an object"

let () =
  Alcotest.run "CENTL-SCi Caramels revision history"
    [
      ( "history",
        [
          Alcotest.test_case "tracks workspace revisions" `Quick
            test_revision_history_tracks_workspace;
          Alcotest.test_case "bounded to newest entries" `Quick
            test_revision_history_is_bounded;
          Alcotest.test_case "JSON bound" `Quick
            test_revision_json_reports_bound;
        ] );
    ]
