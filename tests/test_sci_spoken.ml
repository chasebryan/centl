let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let test_install_and_interpret () =
  let root = temp_dir "centl-spoken-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      Centl_sci_workspace.ensure workspace;
      match
        Centl_sci_spoken.install workspace ~name:"harmonic_mean"
          ~source:"harmonic_mean(a, b) = 2 / ((1/a) + (1/b))"
          ~phrases:[ "harmonic mean" ] ()
      with
      | Error message -> Alcotest.fail message
      | Ok _ -> (
          match
            Centl_sci_spoken.interpret ~workspace
              "What is the harmonic mean of 3 and 4?"
          with
          | Some (Centl_sci_ir.Exact_expression data) ->
              Alcotest.(check string)
                "lowered" "harmonic_mean(3, 4)" data.expression
          | _ -> Alcotest.fail "expected spoken lowering"))

let test_single_letter_is_refused () =
  let root = temp_dir "centl-spoken-short-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      Centl_sci_workspace.ensure workspace;
      match
        Centl_sci_spoken.install workspace ~name:"f" ~source:"f(x) = x + 1" ()
      with
      | Error _ -> ()
      | Ok _ -> Alcotest.fail "single-letter spoken alias should be refused")

let () =
  Alcotest.run "CENTL-SCi spoken aliases"
    [
      ( "spoken",
        [
          Alcotest.test_case "install and interpret" `Quick
            test_install_and_interpret;
          Alcotest.test_case "single letter refused" `Quick
            test_single_letter_is_refused;
        ] );
    ]
