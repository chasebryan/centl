type dependency =
  | Local_extension of string
  | External of string
  | Opaque of string

type issue =
  | Missing_extension of { extension : string; dependency : string }
  | Inactive_extension of { extension : string; dependency : string }
  | Cycle of string list

type t = {
  valid : bool;
  issues : issue list;
  local_edges : (string * string list) list;
  external_dependencies : (string * string list) list;
  opaque_dependencies : (string * string list) list;
}

let drop_prefix prefix text =
  if String.starts_with ~prefix text then
    Some
      (String.sub text (String.length prefix)
         (String.length text - String.length prefix)
      |> String.trim)
  else None

let classify text =
  let text = String.trim text in
  match drop_prefix "extension:" text with
  | Some name when name <> "" -> Local_extension name
  | _ ->
      begin match drop_prefix "external:" text with
      | Some name when name <> "" -> External name
      | _ -> Opaque text
      end

let manifest_map workspace =
  Centl_sci_extensions.list workspace
  |> List.map (fun manifest -> (manifest.Centl_sci_extensions.name, manifest))

let assoc_manifest manifests name = List.assoc_opt name manifests

let classified_dependencies manifest =
  List.map classify manifest.Centl_sci_extensions.dependencies

let local_names manifest =
  classified_dependencies manifest
  |> List.filter_map (function Local_extension name -> Some name | _ -> None)

let external_names manifest =
  classified_dependencies manifest
  |> List.filter_map (function External name -> Some name | _ -> None)

let opaque_names manifest =
  classified_dependencies manifest
  |> List.filter_map (function
    | Opaque name when name <> "" -> Some name
    | _ -> None)

let local_issues manifests manifest =
  local_names manifest
  |> List.concat_map (fun dependency ->
      match assoc_manifest manifests dependency with
      | None ->
          [
            Missing_extension
              { extension = manifest.Centl_sci_extensions.name; dependency };
          ]
      | Some target
        when manifest.enabled && not target.Centl_sci_extensions.enabled ->
          [
            Inactive_extension
              { extension = manifest.Centl_sci_extensions.name; dependency };
          ]
      | Some _ -> [])

let cycle_key cycle = String.concat "\000" cycle

let canonical_cycle cycle =
  match cycle with
  | [] -> []
  | _ -> (
      let values =
        match List.rev cycle with
        | last :: rest_rev when last = List.hd cycle -> List.rev rest_rev
        | _ -> cycle
      in
      let rec rotations prefix suffix acc =
        match suffix with
        | [] -> acc
        | head :: tail ->
            let rotated = suffix @ List.rev prefix in
            rotations (head :: prefix) tail (rotated :: acc)
      in
      let candidates = rotations [] values [] in
      match candidates with
      | [] -> values
      | first :: rest ->
          List.fold_left
            (fun best candidate ->
              if String.compare (cycle_key candidate) (cycle_key best) < 0 then
                candidate
              else best)
            first rest)

let detect_cycles local_edges =
  let edge_map = local_edges in
  let state = Hashtbl.create (List.length local_edges) in
  let stack = ref [] in
  let cycles = ref [] in
  let rec suffix_from name = function
    | [] -> []
    | head :: tail ->
        if head = name then head :: tail else suffix_from name tail
  in
  let rec visit name =
    match Hashtbl.find_opt state name with
    | Some `Done -> ()
    | Some `Visiting ->
        let path = List.rev !stack in
        let suffix = suffix_from name path in
        if suffix <> [] then
          cycles := canonical_cycle (suffix @ [ name ]) :: !cycles
    | None ->
        Hashtbl.replace state name `Visiting;
        stack := name :: !stack;
        let dependencies =
          Option.value ~default:[] (List.assoc_opt name edge_map)
        in
        List.iter visit dependencies;
        begin match !stack with _ :: rest -> stack := rest | [] -> ()
        end;
        Hashtbl.replace state name `Done
  in
  List.iter (fun (name, _) -> visit name) local_edges;
  !cycles
  |> List.sort_uniq (fun left right ->
      String.compare (cycle_key left) (cycle_key right))
  |> List.map (fun cycle -> Cycle cycle)

let validate workspace =
  let manifests = manifest_map workspace in
  let manifest_values = List.map snd manifests in
  let local_edges =
    manifest_values
    |> List.map (fun (manifest : Centl_sci_extensions.manifest) ->
        (manifest.name, local_names manifest))
  in
  let external_dependencies =
    manifest_values
    |> List.filter_map (fun (manifest : Centl_sci_extensions.manifest) ->
        match external_names manifest with
        | [] -> None
        | values -> Some (manifest.name, values))
  in
  let opaque_dependencies =
    manifest_values
    |> List.filter_map (fun (manifest : Centl_sci_extensions.manifest) ->
        match opaque_names manifest with
        | [] -> None
        | values -> Some (manifest.name, values))
  in
  let issues =
    List.concat_map (local_issues manifests) manifest_values
    @ detect_cycles local_edges
  in
  let invalid =
    List.exists
      (function
        | Missing_extension _ | Cycle _ -> true | Inactive_extension _ -> false)
      issues
  in
  {
    valid = not invalid;
    issues;
    local_edges;
    external_dependencies;
    opaque_dependencies;
  }

let issue_text = function
  | Missing_extension { extension; dependency } ->
      Printf.sprintf "%s declares missing local extension dependency %s"
        extension dependency
  | Inactive_extension { extension; dependency } ->
      Printf.sprintf
        "%s is enabled but local extension dependency %s is disabled" extension
        dependency
  | Cycle cycle ->
      "local extension dependency cycle: " ^ String.concat " -> " cycle

let render report =
  String.concat "\n"
    ([
       "Caramels extension dependency report";
       "  structurally valid: " ^ string_of_bool report.valid;
       "  local dependency edges: "
       ^ string_of_int (List.length report.local_edges);
       "  issues: " ^ string_of_int (List.length report.issues);
       "Issues:";
     ]
    @ (if report.issues = [] then [ "  - none" ]
       else List.map (fun issue -> "  - " ^ issue_text issue) report.issues)
    @ [
        "Dependency syntax:";
        "  - extension:NAME declares a local CENTL extension dependency";
        "  - external:NAME records an external dependency without pretending \
         Caramels validated it";
        "  - unprefixed legacy dependency strings are preserved as opaque \
         provenance";
        "Assurance note: dependency validity is structural composition \
         evidence, not verified-core assurance.";
      ])

let to_json report =
  let edge_json (name, dependencies) =
    `Assoc
      [
        ("extension", `String name);
        ( "dependencies",
          `List (List.map (fun value -> `String value) dependencies) );
      ]
  in
  `Assoc
    [
      ("schema_version", `Int 1);
      ("centl_sci_version", `String "0.0.2-Caramels+");
      ("valid", `Bool report.valid);
      ( "issues",
        `List (List.map (fun issue -> `String (issue_text issue)) report.issues)
      );
      ("local_edges", `List (List.map edge_json report.local_edges));
      ( "external_dependencies",
        `List (List.map edge_json report.external_dependencies) );
      ( "opaque_dependencies",
        `List (List.map edge_json report.opaque_dependencies) );
      ("assurance_promoted", `Bool false);
    ]
