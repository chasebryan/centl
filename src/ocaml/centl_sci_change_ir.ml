type action = Create | Modify
type target_kind = Value | Function | Module | Adapter | Native_extension | Core_patch

type t = {
  action : action;
  target_kind : target_kind;
  name : string;
  parameters : string list;
  implementation : string option;
  dependencies : string list;
  tests : string list;
  requested_assurance : string;
  provenance : string;
}

let action_text = function Create -> "create" | Modify -> "modify"

let target_kind_text = function
  | Value -> "value"
  | Function -> "function"
  | Module -> "module"
  | Adapter -> "adapter"
  | Native_extension -> "native_extension"
  | Core_patch -> "core_patch"

let valid_identifier name =
  let first = function
    | 'a' .. 'z' | 'A' .. 'Z' | '_' -> true
    | _ -> false
  in
  let rest = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
    | _ -> false
  in
  String.length name > 0
  && first name.[0]
  && String.for_all rest name

let validate change =
  if not (valid_identifier change.name) then Error "invalid target identifier"
  else if List.exists (fun value -> not (valid_identifier value)) change.parameters then
    Error "invalid parameter identifier"
  else
    match (change.target_kind, change.implementation) with
    | (Value | Function), None -> Error "native CENTL value/function needs an implementation"
    | Function, Some _ when change.parameters = [] ->
        Error "function change needs at least one parameter"
    | _ -> Ok change

let to_centl_source change =
  match validate change with
  | Error _ as error -> error
  | Ok change ->
      begin match (change.target_kind, change.implementation) with
      | Value, Some implementation ->
          Ok (change.name ^ " = " ^ String.trim implementation)
      | Function, Some implementation ->
          Ok
            (Printf.sprintf "%s(%s) = %s" change.name
               (String.concat ", " change.parameters)
               (String.trim implementation))
      | _ -> Error "change request is not a native CENTL value/function"
      end

let strings values = `List (List.map (fun value -> `String value) values)

let to_json change =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("action", `String (action_text change.action));
      ("target_kind", `String (target_kind_text change.target_kind));
      ("name", `String change.name);
      ("parameters", strings change.parameters);
      ( "implementation",
        match change.implementation with None -> `Null | Some value -> `String value );
      ("dependencies", strings change.dependencies);
      ("tests", strings change.tests);
      ("requested_assurance", `String change.requested_assurance);
      ("provenance", `String change.provenance);
    ]

let native_definition ~action ~target_kind ~name ~parameters ~implementation =
  {
    action;
    target_kind;
    name;
    parameters;
    implementation = Some implementation;
    dependencies = [];
    tests = [];
    requested_assurance = "locally-tested";
    provenance = "CENTL-SCi English-to-CENTL frontend";
  }
