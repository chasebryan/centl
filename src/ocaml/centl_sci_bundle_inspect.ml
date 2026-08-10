type assurance_count = {
  label : string;
  count : int;
}

type t = {
  path : string;
  source_revision : int option;
  extensions : int;
  enabled_native_extensions : string list;
  disabled_extensions : int;
  packages : int;
  assurance_counts : assurance_count list;
}

let assoc name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let source_revision path =
  let metadata = Filename.concat path "bundle.json" in
  try
    match Yojson.Safe.from_file metadata |> assoc "source_revision" with
    | Some (`Int value) -> Some value
    | _ -> None
  with Sys_error _ | Yojson.Json_error _ -> None

let increment label counts =
  let rec loop acc = function
    | [] -> List.rev ({ label; count = 1 } :: acc)
    | item :: rest when item.label = label ->
        List.rev_append acc ({ item with count = item.count + 1 } :: rest)
    | item :: rest -> loop (item :: acc) rest
  in
  loop [] counts

let assurance_counts extensions =
  extensions
  |> List.fold_left
       (fun counts extension -> increment extension.Centl_sci_extensions.assurance counts)
       []
  |> List.sort (fun left right -> String.compare left.label right.label)

let inspect path =
  let path = String.trim path in
  if path = "" then Error "bundle path must not be empty"
  else
    match Centl_sci_portable.validate_bundle path with
    | Error message -> Error ("bundle inspection rejected: " ^ message)
    | Ok () ->
        let bundle_workspace = Centl_sci_workspace.make ~name:"inspect-bundle" path in
        let extensions = Centl_sci_extensions.list bundle_workspace in
        let enabled_native_extensions =
          extensions
          |> List.filter (fun extension ->
                 extension.Centl_sci_extensions.enabled
                 && extension.kind = "native_centl")
          |> List.map (fun extension -> extension.name)
        in
        let disabled_extensions =
          extensions
          |> List.filter (fun extension -> not extension.enabled)
          |> List.length
        in
        Ok
          {
            path;
            source_revision = source_revision path;
            extensions = List.length extensions;
            enabled_native_extensions;
            disabled_extensions;
            packages = List.length (Centl_sci_package.list bundle_workspace);
            assurance_counts = assurance_counts extensions;
          }

let render_assurance item =
  Printf.sprintf "    - %s: %d" item.label item.count

let render bundle =
  String.concat "\n"
    ([
       "Caramels workspace bundle";
       "  path: " ^ bundle.path;
       "  source revision: "
       ^ (match bundle.source_revision with
         | None -> "unavailable"
         | Some value -> string_of_int value);
       "  extensions: " ^ string_of_int bundle.extensions;
       "  enabled native extensions: "
       ^ (if bundle.enabled_native_extensions = [] then "none"
          else String.concat ", " bundle.enabled_native_extensions);
       "  disabled extensions: " ^ string_of_int bundle.disabled_extensions;
       "  packages: " ^ string_of_int bundle.packages;
       "  assurance inventory:";
     ]
    @
    (if bundle.assurance_counts = [] then [ "    - none" ]
     else List.map render_assurance bundle.assurance_counts)
    @ [
        "  validation: accepted by the current Caramels bundle validator";
        "  mutation: none";
        "  assurance note: bundle inspection preserves recorded assurance and does not promote it.";
      ])

let to_json bundle =
  let assurance_json item =
    `Assoc [ ("label", `String item.label); ("count", `Int item.count) ]
  in
  `Assoc
    [
      ("schema_version", `Int 1);
      ("centl_sci_version", `String "0.0.2-Caramels");
      ("path", `String bundle.path);
      ( "source_revision",
        match bundle.source_revision with None -> `Null | Some value -> `Int value );
      ("extensions", `Int bundle.extensions);
      ( "enabled_native_extensions",
        `List
          (List.map (fun value -> `String value) bundle.enabled_native_extensions) );
      ("disabled_extensions", `Int bundle.disabled_extensions);
      ("packages", `Int bundle.packages);
      ("assurance_counts", `List (List.map assurance_json bundle.assurance_counts));
      ("mutation", `Bool false);
      ("assurance_promoted", `Bool false);
    ]
