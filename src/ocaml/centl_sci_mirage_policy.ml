type level = Observe | Stage | Local | Core
type t = { level : level; network_publication : bool }

let default = { level = Stage; network_publication = false }

let level_text = function
  | Observe -> "observe"
  | Stage -> "stage"
  | Local -> "local"
  | Core -> "core"

let parse_level = function
  | "observe" -> Ok Observe
  | "stage" -> Ok Stage
  | "local" -> Ok Local
  | "core" -> Ok Core
  | value -> Error ("unknown MIRAGE autonomy policy: " ^ value)

let path workspace =
  Filename.concat workspace.Centl_sci_workspace.config "mirage-policy.json"

let of_json = function
  | `Assoc fields ->
      begin match List.assoc_opt "level" fields with
      | Some (`String value) ->
          begin match parse_level value with
          | Error _ as error -> error
          | Ok level -> Ok { level; network_publication = false }
          end
      | _ -> Error "MIRAGE policy is missing a level"
      end
  | _ -> Error "MIRAGE policy must be a JSON object"

let to_json policy =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "autonomy_policy");
      ("level", `String (level_text policy.level));
      ("network_publication", `Bool false);
      ( "policy_semantics",
        `String
          "observe analyzes only; stage synthesizes and validates without \
           activation; local permits explicit activation of admissible \
           downstream candidates; core still cannot silently promote generated \
           material to verified-core or publish over the network" );
    ]

let load workspace =
  let path = path workspace in
  if not (Sys.file_exists path) then Ok default
  else
    try of_json (Yojson.Safe.from_file path)
    with Sys_error message | Yojson.Json_error message -> Error message

let store workspace policy =
  try
    Centl_sci_workspace.ensure workspace;
    Centl_sci_workspace.atomic_write_json (path workspace) (to_json policy);
    Ok policy
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let permits_activation policy strategy =
  match (policy.level, strategy) with
  | Observe, _ | Stage, _ -> false
  | Local, Centl_sci_mirage_candidate.Isolated_core_patch -> false
  | Local, _ -> true
  | Core, Centl_sci_mirage_candidate.Isolated_core_patch -> false
  | Core, _ -> true

let render policy =
  String.concat "\n"
    [
      "CENTL-MIRAGE autonomy policy";
      "level: " ^ level_text policy.level;
      "network publication: never";
      "verified-core promotion: never automatic";
    ]
