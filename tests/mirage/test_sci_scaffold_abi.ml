let write_text path text =
  Centl_sci_workspace.ensure_directory (Filename.dirname path);
  let channel = open_out path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel text)

let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let valid_contract name =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("name", `String name);
      ("kind", `String "native_extension");
      ("transport", `String "jsonl_stdio");
      ("activation", `String "explicit_after_validation");
      ("assurance", `String "unverified_generated_extension");
      ("verified_core_modified", `Bool false);
      ("network_access", `String "not_granted_by_scaffold");
      ("filesystem_access", `String "not_granted_by_scaffold");
    ]

let test_valid_contract_stays_inactive () =
  let root = temp_dir "centl-scaffold-abi-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let path = Filename.concat root "scaffold.json" in
      Centl_sci_workspace.atomic_write_json path (valid_contract "orbit");
      match Centl_sci_scaffold_abi.inspect_file path with
      | Centl_sci_scaffold_abi.Invalid message -> Alcotest.fail message
      | Centl_sci_scaffold_abi.Valid_inactive contract ->
          Alcotest.(check string) "name" "orbit" contract.name;
          begin match
            Centl_sci_scaffold_abi.activation_allowed
              (Centl_sci_scaffold_abi.Valid_inactive contract)
          with
          | Ok _ -> Alcotest.fail "inactive scaffold must not self-enable"
          | Error message ->
              Alcotest.(check bool)
                "refuses enablement" true
                (Option.is_some
                   (Centl_sci_interaction.find_substring ~needle:"cannot enable"
                      message))
          end)

let test_core_modification_is_rejected () =
  match
    Centl_sci_scaffold_abi.validate_contract
      {
        name = "bad";
        kind = "native_extension";
        transport = "jsonl_stdio";
        activation = "explicit_after_validation";
        assurance = "unverified_generated_extension";
        verified_core_modified = true;
        network_access = "not_granted_by_scaffold";
        filesystem_access = "not_granted_by_scaffold";
      }
  with
  | Centl_sci_scaffold_abi.Valid_inactive _ ->
      Alcotest.fail "core-modifying scaffold must be invalid"
  | Centl_sci_scaffold_abi.Invalid message ->
      Alcotest.(check bool)
        "mentions verified core" true
        (Option.is_some
           (Centl_sci_interaction.find_substring ~needle:"verified CENTL core"
              message))

let () =
  Alcotest.run "CENTL-SCi scaffold ABI"
    [
      ( "abi",
        [
          Alcotest.test_case "inactive validation" `Quick
            test_valid_contract_stays_inactive;
          Alcotest.test_case "core modification rejected" `Quick
            test_core_modification_is_rejected;
        ] );
    ]
