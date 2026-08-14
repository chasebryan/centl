let catalog_json =
  {|{
  "schema": "centl-caravan-catalog-v1",
  "catalog_version": 2,
  "artifacts": [
    {
      "logical_path": "source/core.tar.gz",
      "artifact_id": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "length": 4,
      "distribution": "public-approved",
      "chunks": [{"offset": 0, "length": 4, "sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}]
    },
    {
      "logical_path": "releases/centl.tar.gz",
      "artifact_id": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      "length": 4,
      "distribution": "public-approved",
      "chunks": [{"offset": 0, "length": 4, "sha256": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}]
    },
    {
      "logical_path": "notes/readme.txt",
      "artifact_id": "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
      "length": 1,
      "distribution": "public-approved",
      "chunks": [{"offset": 0, "length": 1, "sha256": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"}]
    }
  ]
}|}

let parse_catalog () =
  let catalog = Centl_caravan.parse_catalog_string catalog_json in
  Alcotest.(check int) "version" 2 catalog.version;
  Alcotest.(check int) "artifact count" 3 (List.length catalog.entries)

let mission_filter_matches_join_rule () =
  let catalog = Centl_caravan.parse_catalog_string catalog_json in
  let selected =
    Centl_caravan.for_missions catalog
      [ Centl_caravan.Source; Centl_caravan.Releases ]
  in
  Alcotest.(check (list string))
    "mission paths"
    [ "source/core.tar.gz"; "releases/centl.tar.gz" ]
    (List.map
       (fun (artifact : Centl_caravan.artifact) -> artifact.logical_path)
       selected);
  Alcotest.(check bool)
    "notes is not a mission" true
    (Option.is_none (Centl_caravan.mission_of_path "notes/readme.txt"))

let inspect_never_joins () =
  let catalog = Centl_caravan.parse_catalog_string catalog_json in
  let report =
    Centl_caravan.inspect ~missions:[ Centl_caravan.Source ] catalog
  in
  Alcotest.(check int) "one public source artifact" 1 report.public_approved;
  Alcotest.(check int) "none held without a store" 0 report.locally_held;
  begin match Centl_caravan.to_json report with
  | `Assoc fields ->
      Alcotest.(check bool)
        "inspect does not join" true
        (List.assoc "join_or_enrollment_performed" fields = `Bool false);
      Alcotest.(check bool)
        "carriers do not define trust" true
        (List.assoc "carriers_define_trust" fields = `Bool false)
  | _ -> Alcotest.fail "inspect JSON must be an object"
  end

let unknown_schema_fails_closed () =
  match
    Centl_caravan.parse_catalog_string
      {|{"schema":"not-caravan","catalog_version":1,"artifacts":[]}|}
  with
  | exception Centl_caravan.Catalog_error message ->
      Alcotest.(check bool) "schema error" true (String.length message > 0)
  | _ -> Alcotest.fail "expected catalog schema rejection"

let () =
  Alcotest.run "caravan"
    [
      ( "catalog",
        [
          ("parse", `Quick, parse_catalog);
          ("missions", `Quick, mission_filter_matches_join_rule);
          ("inspect", `Quick, inspect_never_joins);
          ("unknown schema", `Quick, unknown_schema_fails_closed);
        ] );
    ]
