type status = Occupied | Left | Retired

type camp = {
  id : string;
  title : string;
  status : status;
  date_occupied : string;
  expedition : string;
  published_oasis : string;
  oasis_declared : bool;
  artifact_tag : string option;
  why_not_oasis : string list;
  oasis_still_possible : string;
  in_bounds : string list;
  out_of_bounds : string list;
}

type occupation = {
  published_oasis : string;
  occupied : camp list;
  oasis_declared : bool;
  summary : string;
}

let status_text = function
  | Occupied -> "occupied"
  | Left -> "left"
  | Retired -> "retired"

let published_oasis = Centl_sci_oasis.published_oasis

let camp_001 =
  {
    id = "CAMP-001";
    title = "Laboratory waystation";
    status = Occupied;
    date_occupied = "2026-08-14";
    expedition = "secret-oasis-2026-08-14";
    published_oasis;
    oasis_declared = false;
    artifact_tag = Some "fcf-camp-001";
    why_not_oasis =
      [
        "current identity is not the oasis branch";
        "a camp inspect path cannot declare Oasis";
        "laboratory SCi, MIRAGE, and CARAVAN surfaces stay outside the \
         installed product";
        "declaring Oasis here would skip or weaken the official gate";
      ];
    oasis_still_possible =
      "Oasis is the steadily advanced snapshot of current main and mirage. \
       CENTL v0.15.0 is that snapshot on the oasis tip. This camp inspect \
       path does not declare it.";
    in_bounds =
      [
        "inspect-only Oasis, Wellspring, Camp, and CARAVAN commands";
        "MIRAGE local cycles that cannot activate source by themselves";
        "CARAVAN Phase 1 laboratory coverage";
        "SCi English workshop as a laboratory surface";
      ];
    out_of_bounds =
      [
        "Oasis declaration or SemVer publication from this camp";
        "Wellspring designation without independent review";
        "changing the signed join-caravan scheme";
        "website visual redesign";
        "public volunteer CARAVAN enrollment";
      ];
  }

let records = [ camp_001 ]

let find_record id =
  List.find_opt (fun camp -> String.equal camp.id id) records

let occupied () = List.filter (fun camp -> camp.status = Occupied) records

let inspect () =
  let occupied = occupied () in
  let summary =
    match occupied with
    | [] ->
        "no FCF Camp is occupied. CENTL v" ^ published_oasis
        ^ " remains the published Oasis release. This command does not declare \
           Oasis."
    | camps ->
        let names = String.concat ", " (List.map (fun camp -> camp.id) camps) in
        "FCF Camp occupied: " ^ names
        ^ ". This is a stay, not an Oasis. CENTL v" ^ published_oasis
        ^ " remains the published Oasis release."
  in
  {
    published_oasis;
    occupied;
    oasis_declared = false;
    summary;
  }

let to_json occupation =
  let camp_json camp =
    `Assoc
      [
        ("id", `String camp.id);
        ("title", `String camp.title);
        ("status", `String (status_text camp.status));
        ("date_occupied", `String camp.date_occupied);
        ("expedition", `String camp.expedition);
        ("published_oasis", `String camp.published_oasis);
        ("oasis_declared", `Bool false);
        ( "artifact_tag",
          match camp.artifact_tag with
          | None -> `Null
          | Some tag -> `String tag );
        ( "why_not_oasis",
          `List (List.map (fun value -> `String value) camp.why_not_oasis) );
        ("oasis_still_possible", `String camp.oasis_still_possible);
        ( "in_bounds",
          `List (List.map (fun value -> `String value) camp.in_bounds) );
        ( "out_of_bounds",
          `List (List.map (fun value -> `String value) camp.out_of_bounds) );
      ]
  in
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "FCF");
      ("artifact_kind", `String "fcf_camp_inspection");
      ("published_oasis", `String occupation.published_oasis);
      ("oasis_declared", `Bool false);
      ("oasis_declared_by_this_command", `Bool false);
      ( "occupied",
        `List (List.map camp_json occupation.occupied) );
      ("summary", `String occupation.summary);
      ( "inspection_semantics",
        `String
          "a Camp is a stay. This inspection never declares Oasis, never \
           weakens a gate, and never treats camp occupation as qualification" );
    ]

let render_camp camp =
  String.concat "\n"
    ([
       "FCF Camp " ^ camp.id;
       "title: " ^ camp.title;
       "status: " ^ status_text camp.status;
       "occupied: " ^ camp.date_occupied;
       "published Oasis: v" ^ camp.published_oasis;
       "Oasis declared: no";
       (match camp.artifact_tag with
       | None -> "named artifact: none"
       | Some tag -> "named artifact: " ^ tag);
       "why this is not Oasis:";
     ]
    @ List.map (fun value -> "  - " ^ value) camp.why_not_oasis
    @ [ camp.oasis_still_possible ])

let render occupation =
  let camps =
    match occupation.occupied with
    | [] -> [ "occupied camps: none" ]
    | values ->
        "occupied camps:"
        :: List.map (fun camp -> "  - " ^ camp.id ^ " " ^ camp.title) values
  in
  String.concat "\n"
    ([
       "FCF Camp inspection";
       "published Oasis: v" ^ occupation.published_oasis;
       "Oasis declared: no";
       occupation.summary;
     ]
    @ camps)
