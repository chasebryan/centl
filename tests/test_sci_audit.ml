let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let write_text path text =
  Centl_sci_workspace.ensure_directory (Filename.dirname path);
  let channel = open_out path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel text)

let add_native workspace ~name ~source =
  Centl_sci_workspace.ensure workspace;
  write_text
    (Filename.concat workspace.Centl_sci_workspace.modules_dir (name ^ ".centl"))
    source;
  match
    Centl_sci_workspace.write_manifest workspace ~name ~enabled:true
      ~assurance:Centl_sci_workspace.Locally_tested
      ~source:("modules/" ^ name ^ ".centl")
      ~summary:"audit test"
  with
  | Ok _ -> ()
  | Error message -> Alcotest.fail message

let test_healthy_is_structural_not_assurance () =
  let root = temp_dir "centl-caramels-audit-healthy-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      add_native workspace ~name:"tau" ~source:"tau = 2*pi\n";
      let audit = Centl_sci_audit.collect workspace in
      Alcotest.(check string) "health" "healthy" (Centl_sci_audit.health audit);
      let rendered = Centl_sci_audit.render audit in
      Alcotest.(check bool)
        "not a trust score" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"not a trust score"
              rendered));
      Alcotest.(check bool)
        "local assurance remains visible" true
        (Option.is_some
           (Centl_sci_interaction.find_substring
              ~needle:"locally_tested_extension" rendered)))

let test_attention_required_for_invalid_extension () =
  let root = temp_dir "centl-caramels-audit-attention-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace = Centl_sci_workspace.make root in
      add_native workspace ~name:"broken" ~source:"broken = (\n";
      let audit = Centl_sci_audit.collect workspace in
      Alcotest.(check string)
        "health" "attention_required"
        (Centl_sci_audit.health audit);
      Alcotest.(check int)
        "one invalid extension" 1
        (List.length (Centl_sci_audit.invalid_extensions audit));
      match Centl_sci_audit.to_json audit with
      | `Assoc fields ->
          begin match
            ( List.assoc_opt "health" fields,
              List.assoc_opt "invalid_extension_count" fields,
              List.assoc_opt "verified_core_modified" fields )
          with
          | ( Some (`String "attention_required"),
              Some (`Int 1),
              Some (`Bool false) ) ->
              ()
          | _ -> Alcotest.fail "audit JSON health/count/core boundary mismatch"
          end
      | _ -> Alcotest.fail "audit JSON must be an object")

let () =
  Alcotest.run "CENTL-SCi Caramels workspace audit"
    [
      ( "health",
        [
          Alcotest.test_case "healthy structural state" `Quick
            test_healthy_is_structural_not_assurance;
          Alcotest.test_case "attention required" `Quick
            test_attention_required_for_invalid_extension;
        ] );
    ]
