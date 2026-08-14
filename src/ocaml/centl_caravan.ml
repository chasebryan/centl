type mission = Source | Releases | Semantic | Recovery
type chunk = { offset : int; length : int; sha256 : string }

type artifact = {
  logical_path : string;
  artifact_id : string;
  length : int;
  distribution : string;
  mission : mission option;
  chunks : chunk list;
}

type catalog = { version : int; entries : artifact list }

type artifact_coverage = {
  logical_path : string;
  artifact_id : string;
  length : int;
  mission : mission option;
  locally_held : bool;
}

type report = {
  catalog_version : int;
  missions : mission list;
  public_approved : int;
  locally_held : int;
  missing_locally : int;
  rows : artifact_coverage list;
  summary : string;
}

exception Catalog_error of string

let catalog_schema = "centl-caravan-catalog-v1"
let missions = [ Source; Releases; Semantic; Recovery ]

let mission_name = function
  | Source -> "source"
  | Releases -> "releases"
  | Semantic -> "semantic"
  | Recovery -> "recovery"

let mission_of_name = function
  | "source" -> Some Source
  | "releases" -> Some Releases
  | "semantic" -> Some Semantic
  | "recovery" -> Some Recovery
  | "all" -> None
  | _ -> None

let mission_of_path logical_path =
  match String.split_on_char '/' logical_path with
  | first :: _ -> (
      match mission_of_name first with
      | Some _ as mission -> mission
      | None -> None)
  | [] -> None

let hex64 value =
  String.length value = 64
  && String.for_all
       (function '0' .. '9' | 'a' .. 'f' -> true | _ -> false)
       value

let require_hex64 field value =
  if hex64 value then value
  else
    raise
      (Catalog_error (field ^ " must be 64 lowercase hexadecimal characters"))

let member name = function
  | `Assoc fields -> (
      match List.assoc_opt name fields with
      | Some value -> value
      | None -> raise (Catalog_error ("missing catalog field " ^ name)))
  | _ -> raise (Catalog_error "catalog value must be an object")

let as_string field = function
  | `String value -> value
  | _ -> raise (Catalog_error (field ^ " must be a string"))

let as_int field = function
  | `Int value -> value
  | _ -> raise (Catalog_error (field ^ " must be an integer"))

let as_list field = function
  | `List value -> value
  | _ -> raise (Catalog_error (field ^ " must be an array"))

let parse_chunk json =
  match json with
  | `Assoc _ ->
      let offset = member "offset" json |> as_int "chunk offset" in
      let length = member "length" json |> as_int "chunk length" in
      let sha256 =
        member "sha256" json |> as_string "chunk sha256"
        |> require_hex64 "chunk sha256"
      in
      if offset < 0 || length <= 0 then
        raise (Catalog_error "chunk bounds are invalid");
      { offset; length; sha256 }
  | _ -> raise (Catalog_error "chunk record must be an object")

let parse_artifact json =
  let logical_path = member "logical_path" json |> as_string "logical_path" in
  let artifact_id = member "artifact_id" json |> as_string "artifact_id" in
  let length = member "length" json |> as_int "length" in
  let distribution = member "distribution" json |> as_string "distribution" in
  let chunks =
    member "chunks" json |> as_list "chunks" |> List.map parse_chunk
  in
  if length < 0 then
    raise (Catalog_error "artifact length must be non-negative");
  if not (String.starts_with ~prefix:"sha256:" artifact_id) then
    raise (Catalog_error "artifact_id must use sha256:<digest>");
  let digest = String.sub artifact_id 7 (String.length artifact_id - 7) in
  ignore (require_hex64 "artifact_id" digest);
  {
    logical_path;
    artifact_id;
    length;
    distribution;
    mission = mission_of_path logical_path;
    chunks;
  }

let parse_catalog json =
  match json with
  | `Assoc _ ->
      let schema = member "schema" json |> as_string "schema" in
      if not (String.equal schema catalog_schema) then
        raise (Catalog_error "unsupported CARAVAN catalog schema");
      let version = member "catalog_version" json |> as_int "catalog_version" in
      if version < 1 then
        raise (Catalog_error "catalog_version must be a positive integer");
      let entries =
        member "artifacts" json |> as_list "artifacts"
        |> List.map parse_artifact
      in
      { version; entries }
  | _ -> raise (Catalog_error "catalog must be a JSON object")

let parse_catalog_string text =
  try parse_catalog (Yojson.Safe.from_string text)
  with Yojson.Json_error message -> raise (Catalog_error message)

let parse_catalog_file path =
  if not (Sys.file_exists path) then
    raise (Catalog_error ("catalog file does not exist: " ^ path));
  parse_catalog_string (In_channel.with_open_bin path In_channel.input_all)

let normalize_missions names =
  let rec loop acc = function
    | [] ->
        if acc = [] then
          raise (Catalog_error "at least one CARAVAN mission is required")
        else acc
    | "all" :: rest ->
        let missing =
          List.filter
            (fun mission -> not (List.exists (fun item -> item = mission) acc))
            missions
        in
        loop (acc @ missing) rest
    | name :: rest -> (
        match mission_of_name name with
        | None -> raise (Catalog_error ("unknown CARAVAN mission: " ^ name))
        | Some mission ->
            if List.exists (fun item -> item = mission) acc then loop acc rest
            else loop (acc @ [ mission ]) rest)
  in
  loop [] names

let public_artifacts (catalog : catalog) =
  List.filter
    (fun (artifact : artifact) ->
      String.equal artifact.distribution "public-approved")
    catalog.entries

let for_missions (catalog : catalog) selected =
  public_artifacts catalog
  |> List.filter (fun (artifact : artifact) ->
      match artifact.mission with
      | Some mission -> List.exists (fun item -> item = mission) selected
      | None -> false)

let object_path store digest =
  Filename.concat
    (Filename.concat
       (Filename.concat (Filename.concat store "objects") "sha256")
       (String.sub digest 0 2))
    digest

let file_digest path =
  let payload = In_channel.with_open_bin path In_channel.input_all in
  Centl_sha256.hex_string payload

let holds store (artifact : artifact) =
  if not (String.starts_with ~prefix:"sha256:" artifact.artifact_id) then false
  else
    let digest =
      String.sub artifact.artifact_id 7 (String.length artifact.artifact_id - 7)
    in
    let path = object_path store digest in
    if not (Sys.file_exists path) then false
    else
      try
        let actual = file_digest path in
        String.equal actual digest
        && String.length (In_channel.with_open_bin path In_channel.input_all)
           = artifact.length
      with Sys_error _ -> false

let inspect ?store ~missions (catalog : catalog) =
  let selected = for_missions catalog missions in
  let rows =
    List.map
      (fun (artifact : artifact) ->
        {
          logical_path = artifact.logical_path;
          artifact_id = artifact.artifact_id;
          length = artifact.length;
          mission = artifact.mission;
          locally_held =
            (match store with
            | None -> false
            | Some root -> holds root artifact);
        })
      selected
  in
  let locally_held =
    List.filter (fun (item : artifact_coverage) -> item.locally_held) rows
  in
  let missing =
    List.filter (fun (item : artifact_coverage) -> not item.locally_held) rows
  in
  let summary =
    Printf.sprintf
      "CARAVAN inspect: %d public-approved artifact(s) for the selected \
       missions; %d held locally; %d missing. This command never joins, \
       enrolls, or lets a carrier define trust."
      (List.length rows) (List.length locally_held) (List.length missing)
  in
  {
    catalog_version = catalog.version;
    missions;
    public_approved = List.length rows;
    locally_held = List.length locally_held;
    missing_locally = List.length missing;
    rows;
    summary;
  }

let mission_json mission =
  match mission with
  | None -> `Null
  | Some value -> `String (mission_name value)

let to_json report =
  `Assoc
    [
      ("schema", `String "centl-caravan-inspect-v1");
      ("catalog_version", `Int report.catalog_version);
      ( "missions",
        `List
          (List.map
             (fun mission -> `String (mission_name mission))
             report.missions) );
      ("public_approved", `Int report.public_approved);
      ("locally_held", `Int report.locally_held);
      ("missing_locally", `Int report.missing_locally);
      ("join_or_enrollment_performed", `Bool false);
      ("carriers_define_trust", `Bool false);
      ("summary", `String report.summary);
      ( "artifacts",
        `List
          (List.map
             (fun (item : artifact_coverage) ->
               `Assoc
                 [
                   ("logical_path", `String item.logical_path);
                   ("artifact_id", `String item.artifact_id);
                   ("length", `Int item.length);
                   ("mission", mission_json item.mission);
                   ("locally_held", `Bool item.locally_held);
                 ])
             report.rows) );
    ]

let render report =
  let buffer = Buffer.create 256 in
  Buffer.add_string buffer report.summary;
  Buffer.add_char buffer '\n';
  List.iter
    (fun (item : artifact_coverage) ->
      Buffer.add_string buffer
        (Printf.sprintf "  %s %s %s\n" item.logical_path item.artifact_id
           (if item.locally_held then "held" else "missing")))
    report.rows;
  Buffer.contents buffer
