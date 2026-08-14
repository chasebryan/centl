let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let with_home home action =
  let previous = Sys.getenv_opt "HOME" in
  Unix.putenv "HOME" home;
  Fun.protect
    ~finally:(fun () ->
      match previous with
      | Some value -> Unix.putenv "HOME" value
      | None -> Unix.putenv "HOME" "")
    action

let test_branch_allowlist () =
  Alcotest.(check bool)
    "safe" true
    (Centl_sci_publish.valid_branch "centl-sci/contrib-deadbeef");
  Alcotest.(check bool)
    "oasis forbidden as branch" false
    (Centl_sci_publish.valid_branch "oasis");
  Alcotest.(check bool)
    "injection forbidden" false
    (Centl_sci_publish.valid_branch "centl-sci/contrib-x; rm -rf /")

let test_contributor_grant_does_not_commit () =
  let home = temp_dir "centl-publish-home-" in
  Fun.protect
    ~finally:(fun () -> cleanup home)
    (fun () ->
      with_home home (fun () ->
          match Centl_sci_publish.handle "grant contributor publish" with
          | Error message -> Alcotest.fail message
          | Ok _ -> (
              match Centl_sci_publish.read_grant () with
              | Error message -> Alcotest.fail message
              | Ok grant ->
                  Alcotest.(check bool) "no commit" false grant.allow_commit;
                  Alcotest.(check bool) "no pr" false grant.allow_pr)))

let test_owner_grant_requires_acceptance () =
  match Centl_sci_publish.handle "grant owner publish" with
  | Ok _ -> Alcotest.fail "owner grant must require the acceptance phrase"
  | Error message ->
      Alcotest.(check bool)
        "explains the phrase" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"I accept" message))

let test_english_push_does_not_claim_network () =
  match Centl_sci_publish.handle "push this to github" with
  | Error message -> Alcotest.fail message
  | Ok message ->
      Alcotest.(check bool)
        "no silent push" true
        (Option.is_some
           (Centl_sci_interaction.find_substring
              ~needle:"will not push English straight" message));
      Alcotest.(check bool)
        "no 100 percent claim" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"not 100% secure"
              message)
        || Option.is_some
             (Centl_sci_interaction.find_substring
                ~needle:"No system is 100% secure" message))

let test_oasis_verbs_do_not_declare () =
  match Centl_sci_publish.handle "declare oasis" with
  | Error message -> Alcotest.fail message
  | Ok message ->
      Alcotest.(check bool)
        "no declaration" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"declaration: no"
              message));
      Alcotest.(check bool)
        "v0.14.0 remains published" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"v0.14.0" message))

let test_self_merge_is_refused () =
  match Centl_sci_publish.handle "approve this pull request" with
  | Ok _ -> Alcotest.fail "self-approval must be refused"
  | Error message ->
      Alcotest.(check bool)
        "refuses self-approve" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"will not self-approve"
              message))

let test_pack_is_local () =
  let root = temp_dir "centl-publish-ws-" in
  let home = temp_dir "centl-publish-home2-" in
  Fun.protect
    ~finally:(fun () ->
      cleanup root;
      cleanup home)
    (fun () ->
      with_home home (fun () ->
          Unix.putenv "CENTL_WORKSPACE" root;
          let workspace = Centl_sci_workspace.make root in
          Centl_sci_workspace.ensure workspace;
          match Centl_sci_publish.handle "pack contribution" with
          | Error message -> Alcotest.fail message
          | Ok message ->
              Alcotest.(check bool)
                "no network" true
                (Option.is_some
                   (Centl_sci_interaction.find_substring
                      ~needle:"No network was used" message))))

let () =
  Alcotest.run "CENTL-SCi reviewed publish"
    [
      ( "publish",
        [
          Alcotest.test_case "branch allowlist" `Quick test_branch_allowlist;
          Alcotest.test_case "contributor grant" `Quick
            test_contributor_grant_does_not_commit;
          Alcotest.test_case "owner acceptance" `Quick
            test_owner_grant_requires_acceptance;
          Alcotest.test_case "english push is a plan" `Quick
            test_english_push_does_not_claim_network;
          Alcotest.test_case "pack is local" `Quick test_pack_is_local;
          Alcotest.test_case "oasis verbs inspect only" `Quick
            test_oasis_verbs_do_not_declare;
          Alcotest.test_case "self merge refused" `Quick
            test_self_merge_is_refused;
        ] );
    ]
