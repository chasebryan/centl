type report = {
  published_oasis : string;
  current_version : string;
  declaration : bool;
  blockers : string list;
  summary : string;
}

let published_oasis = "0.15.0"

let layout_blockers root =
  let required =
    [
      "docs/OASIS.md";
      "docs/FCF-WELLSPRING.md";
      "scripts/oasis.py";
      "src/ocaml/centl_version.ml";
    ]
  in
  List.filter_map
    (fun relative ->
      let path = Filename.concat root relative in
      if Sys.file_exists path then None
      else Some ("missing required path: " ^ relative))
    required

let inspect ~root ~current_version ~branch =
  let blockers = layout_blockers root in
  let blockers =
    if String.equal current_version published_oasis then blockers
    else
      blockers
      @ [
          "current version " ^ current_version
          ^ " is not the published Oasis identity " ^ published_oasis;
        ]
  in
  let blockers =
    if String.equal branch "oasis" then blockers
    else
      blockers
      @ [
          "current branch " ^ branch
          ^ " is not oasis; Oasis is a promotion state, not a property of \
             every commit";
        ]
  in
  let declaration = false in
  let summary =
    if blockers = [] then
      "local identity matches the published Oasis version and branch name, but \
       this command does not run the Oasis gate and therefore cannot declare \
       Oasis"
    else
      "no new Oasis was found. CENTL v" ^ published_oasis
      ^ " remains the published Oasis release; this identity does not satisfy \
         the Oasis declaration requirements. FCF Camps are the stay when \
         Oasis cannot be declared; they are not Oasis."
  in
  { published_oasis; current_version; declaration; blockers; summary }

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL");
      ("artifact_kind", `String "oasis_identity_inspection");
      ("published_oasis", `String report.published_oasis);
      ("current_version", `String report.current_version);
      ("declaration", `Bool false);
      ("oasis_declared_by_this_command", `Bool false);
      ("blockers", `List (List.map (fun value -> `String value) report.blockers));
      ("summary", `String report.summary);
      ( "inspection_semantics",
        `String
          "this inspection never declares Oasis, never weakens a gate, and \
           never treats branch presence as qualification" );
    ]

let render report =
  let blockers =
    match report.blockers with
    | [] -> [ "blockers: none recorded by this local identity inspection" ]
    | values -> "blockers:" :: List.map (fun value -> "  - " ^ value) values
  in
  String.concat "\n"
    ([
       "CENTL Oasis identity inspection";
       "published Oasis: v" ^ report.published_oasis;
       "current version: " ^ report.current_version;
       "declaration: no";
       report.summary;
     ]
    @ blockers)
