type product = {
  name : string;
  kind : string;
  status : string;
  assurance : string;
  summary : string;
}

let family =
  [
    {
      name = "CENTL";
      kind = "exact calculator and numerical language";
      status = "Oasis candidate v0.15.0 Al-Nur for GNU/Linux x86_64";
      assurance = "verified core plus explicit numerical contract";
      summary =
        "Exact-first mathematics. Unqualified digits are never manufactured.";
    };
    {
      name = "CENTL-SCi";
      kind = "scientific interpreter";
      status = "v0.0.2-Caramels interaction generation";
      assurance = "deterministic interpreter; models cannot confer truth";
      summary = "Ordinary-language mathematics and physics over CENTL evidence.";
    };
    {
      name = "CENTL Physics";
      kind = "exact-first physics engine";
      status = "shipped with the Oasis native archive";
      assurance = "deterministic typed operations; deferred stays visible";
      summary = "Units, vectors, mechanics, and contact diagnostics.";
    };
    {
      name = "CENTL-MIRAGE";
      kind = "local self-development laboratory";
      status = "active development; not a silent public command of Oasis";
      assurance = "generated work never inherits verified-core status";
      summary =
        "Specification ingestion, composition, evidence, and reversible \
         staging.";
    };
    {
      name = "CENTL CARAVAN";
      kind = "preservation and availability laboratory";
      status = "Phase 1 laboratory in the v0.14.0 source baseline";
      assurance = "carriers provide bytes, never artifact authority";
      summary =
        "Content-addressed authenticated availability for approved FCF cargo.";
    };
    {
      name = "FCF Wellspring";
      kind = "research designation";
      status = "candidates recorded; none designated";
      assurance = "independent of Oasis qualification";
      summary =
        "A foundational finding, not a release, branch, or product name.";
    };
  ]

let render () =
  let render_one product =
    [
      product.name ^ " — " ^ product.kind;
      "  status: " ^ product.status;
      "  assurance: " ^ product.assurance;
      "  " ^ product.summary;
      "";
    ]
  in
  String.concat "\n"
    ([
       "Free Computation Foundation product family";
       "These names are distinct. Presence in source is not Oasis assurance.";
       "";
     ]
    @ List.concat_map render_one family)

let to_json () =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "FCF");
      ("artifact_kind", `String "product_family");
      ( "products",
        `List
          (List.map
             (fun product ->
               `Assoc
                 [
                   ("name", `String product.name);
                   ("kind", `String product.kind);
                   ("status", `String product.status);
                   ("assurance", `String product.assurance);
                   ("summary", `String product.summary);
                 ])
             family) );
    ]
