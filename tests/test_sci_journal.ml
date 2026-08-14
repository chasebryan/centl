let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let test_append_and_render () =
  let root = temp_dir "centl-journal-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      Centl_sci_workspace.ensure workspace;
      match
        Centl_sci_journal.append workspace
          {
            kind = "create";
            input = "let square(x) = x^2";
            source = Some "square(x) = x^2";
            result = Some "1";
            uses = [];
            restart = "hot_loaded";
            name = Some "square";
          }
      with
      | Error message -> Alcotest.fail message
      | Ok () ->
          let rendered = Centl_sci_journal.render workspace in
          Alcotest.(check bool)
            "journal names the create" true
            (Option.is_some
               (Centl_sci_interaction.find_substring ~needle:"square" rendered));
          Alcotest.(check bool)
            "not verified core in dialect" true
            (Option.is_some
               (Centl_sci_interaction.find_substring
                  ~needle:"not verified CENTL core"
                  (Centl_sci_journal.dialect_text workspace))))

let () =
  Alcotest.run "CENTL-SCi growth journal"
    [
      ( "journal",
        [ Alcotest.test_case "append and render" `Quick test_append_and_render ]
      );
    ]
