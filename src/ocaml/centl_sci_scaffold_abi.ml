type contract = {
  name : string;
  kind : string;
  transport : string;
  activation : string;
  assurance : string;
  verified_core_modified : bool;
  network_access : string;
  filesystem_access : string;
}

type verdict = Valid_inactive of contract | Invalid of string

let assoc name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let string_field name json =
  match assoc name json with Some (`String value) -> Some value | _ -> None

let bool_field name json =
  match assoc name json with Some (`Bool value) -> Some value | _ -> None

let parse json =
  match
    ( string_field "name" json,
      string_field "kind" json,
      string_field "transport" json,
      string_field "activation" json,
      string_field "assurance" json,
      bool_field "verified_core_modified" json,
      string_field "network_access" json,
      string_field "filesystem_access" json )
  with
  | ( Some name,
      Some kind,
      Some transport,
      Some activation,
      Some assurance,
      Some verified_core_modified,
      Some network_access,
      Some filesystem_access ) ->
      Ok
        {
          name;
          kind;
          transport;
          activation;
          assurance;
          verified_core_modified;
          network_access;
          filesystem_access;
        }
  | _ -> Error "scaffold contract is missing required ABI fields"

let validate_contract contract =
  if contract.verified_core_modified then
    Invalid "scaffold contract claims to modify verified CENTL core"
  else if contract.activation <> "explicit_after_validation" then
    Invalid "scaffold activation is not explicit_after_validation"
  else if contract.transport <> "jsonl_stdio" then
    Invalid "scaffold transport is not the supported jsonl_stdio ABI"
  else if not (List.mem contract.kind [ "python_adapter"; "native_extension" ])
  then Invalid ("unsupported scaffold kind: " ^ contract.kind)
  else if
    let access = String.lowercase_ascii contract.network_access in
    Option.is_some
      (Centl_sci_interaction.find_substring ~needle:"granted" access)
    && Option.is_none
         (Centl_sci_interaction.find_substring ~needle:"not_granted" access)
    && Option.is_none
         (Centl_sci_interaction.find_substring ~needle:"not granted" access)
  then Invalid "scaffold contract grants network access"
  else if
    let access = String.lowercase_ascii contract.filesystem_access in
    Option.is_some
      (Centl_sci_interaction.find_substring ~needle:"granted" access)
    && Option.is_none
         (Centl_sci_interaction.find_substring ~needle:"not_granted" access)
    && Option.is_none
         (Centl_sci_interaction.find_substring ~needle:"not granted" access)
  then Invalid "scaffold contract grants filesystem access"
  else Valid_inactive contract

let inspect_file path =
  if not (Sys.file_exists path) then
    Invalid ("missing scaffold contract: " ^ path)
  else
    try
      match parse (Yojson.Safe.from_file path) with
      | Error message -> Invalid message
      | Ok contract -> validate_contract contract
    with Sys_error message | Yojson.Json_error message -> Invalid message

let inspect_workspace workspace name =
  let path =
    Filename.concat
      (Filename.concat
         (Filename.concat workspace.Centl_sci_workspace.generated "scaffolds")
         name)
      "scaffold.json"
  in
  inspect_file path

let activation_allowed verdict =
  match verdict with
  | Invalid message -> Error message
  | Valid_inactive contract ->
      Error
        ("scaffold " ^ contract.name
       ^ " validated as inactive JSONL ABI; generated external/native \
          scaffolds cannot enable themselves as native CENTL or verified core")

let render = function
  | Valid_inactive contract ->
      String.concat "\n"
        [
          "CENTL-SCi scaffold ABI";
          "name: " ^ contract.name;
          "kind: " ^ contract.kind;
          "transport: " ^ contract.transport;
          "activation: " ^ contract.activation;
          "verified core modified: no";
          "enabled: no";
        ]
  | Invalid message -> "CENTL-SCi scaffold ABI rejected: " ^ message
