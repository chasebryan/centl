type report = {
  name : string;
  kind : string;
  valid : bool;
  checks : string list;
  assurance : string;
}

let read_text path =
  try
    let channel = open_in_bin path in
    Ok
      (Fun.protect
         ~finally:(fun () -> close_in_noerr channel)
         (fun () -> really_input_string channel (in_channel_length channel)))
  with
  | Sys_error message -> Error message
  | End_of_file -> Error ("unexpected end of file while reading " ^ path)

let assoc name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let string_field name json =
  match assoc name json with Some (`String value) -> Some value | _ -> None

let int_field name json =
  match assoc name json with Some (`Int value) -> Some value | _ -> None

let native_definition workspace manifest =
  let path = Centl_sci_extensions.source_path workspace manifest in
  if not (Sys.file_exists path) then
    Error ("native CENTL source is missing: " ^ path)
  else
    match read_text path with
    | Error message -> Error message
    | Ok source ->
        begin match Centl_parser.parse_statement_located source with
        | Error error ->
            Error
              (Printf.sprintf "native CENTL source does not parse at byte %d: %s"
                 error.position error.message)
        | Ok located ->
            begin match located.statement with
            | Centl_parser.Define_value _ | Centl_parser.Define_function _ ->
                Ok
                  [
                    "manifest resolves to an existing source file";
                    "source parses as one native CENTL value/function definition";
                    "manifest assurance remains downstream/local";
                  ]
            | Centl_parser.Evaluate _ | Centl_parser.Assert _ ->
                Error "native extension source is not a value/function definition"
            end
        end

let scaffold workspace manifest =
  let contract_path = Centl_sci_extensions.source_path workspace manifest in
  if not (Sys.file_exists contract_path) then
    Error ("scaffold contract is missing: " ^ contract_path)
  else
    try
      let json = Yojson.Safe.from_file contract_path in
      let expected_kind = manifest.Centl_sci_extensions.kind in
      match
        ( int_field "schema_version" json,
          string_field "kind" json,
          string_field "source" json,
          string_field "test" json,
          string_field "activation" json )
      with
      | Some 1, Some kind, Some source, Some test, Some activation
        when kind = expected_kind ->
          let root = Filename.dirname contract_path in
          let source_path = Filename.concat root source in
          let test_path = Filename.concat root test in
          if not (Sys.file_exists source_path) then
            Error ("scaffold source is missing: " ^ source_path)
          else if not (Sys.file_exists test_path) then
            Error ("scaffold validation artifact is missing: " ^ test_path)
          else if activation <> "explicit_after_validation" then
            Error "scaffold activation policy is not explicit_after_validation"
          else
            Ok
              [
                "scaffold contract schema is recognized";
                "manifest kind matches scaffold contract";
                "generated source and validation artifact exist";
                "activation remains explicit after validation";
                "structural validation does not grant verified-core assurance";
              ]
      | _ -> Error "scaffold contract is incomplete or inconsistent with its manifest"
    with Yojson.Json_error message | Sys_error message -> Error message

let validate workspace name =
  match Centl_sci_extensions.read_manifest workspace name with
  | Error message -> Error message
  | Ok manifest ->
      let result =
        match manifest.kind with
        | "native_centl" -> native_definition workspace manifest
        | "python_adapter" | "native_extension" -> scaffold workspace manifest
        | other -> Error ("unsupported extension kind for Caramels validation: " ^ other)
      in
      begin match result with
      | Error message ->
          Ok
            {
              name = manifest.name;
              kind = manifest.kind;
              valid = false;
              checks = [ message ];
              assurance = manifest.assurance;
            }
      | Ok checks ->
          Ok
            {
              name = manifest.name;
              kind = manifest.kind;
              valid = true;
              checks;
              assurance = manifest.assurance;
            }
      end

let render report =
  String.concat "\n"
    ([
       "Caramels extension validation";
       "  name: " ^ report.name;
       "  kind: " ^ report.kind;
       "  valid: " ^ string_of_bool report.valid;
       "  assurance: " ^ report.assurance;
       "Checks:";
     ]
    @ List.map (fun check -> "  - " ^ check) report.checks
    @ [
        "Assurance note: structural validation does not grant verified-core assurance.";
      ])

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("centl_sci_version", `String "0.0.2-Caramels");
      ("name", `String report.name);
      ("kind", `String report.kind);
      ("valid", `Bool report.valid);
      ("checks", `List (List.map (fun check -> `String check) report.checks));
      ("assurance", `String report.assurance);
      ("assurance_promoted", `Bool false);
    ]