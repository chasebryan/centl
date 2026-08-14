type status = Candidate | Designated | Narrowed | Retired
type dimension = { name : string; satisfied : bool; evidence : string }

type wellspring_record = {
  id : string;
  title : string;
  status : status;
  date_identified : string;
  investigators : string list;
  originating_expedition : string;
  source_identity : string;
  core_finding : string;
  assumptions : string list;
  evidence : string list;
  independent_review : string;
  counterexamples : string list;
  downstream_avenues : string list;
  oasis_impact : string;
  security_constraints : string list;
  falsifiers : string list;
  references : string list;
  dimensions : dimension list;
}

type expedition = {
  id : string;
  date : string;
  records : wellspring_record list;
  designated : string list;
  summary : string;
}

let status_text = function
  | Candidate -> "candidate"
  | Designated -> "designated"
  | Narrowed -> "narrowed"
  | Retired -> "retired"

let required_dimension_names =
  [
    "foundational_significance";
    "generative_value";
    "evidence";
    "reproducibility_or_inspectability";
    "durability";
    "relevance";
    "falsifiability_and_limits";
  ]

let dimension_satisfied record name =
  List.exists
    (fun dimension -> String.equal dimension.name name && dimension.satisfied)
    record.dimensions

let all_dimensions_satisfied record =
  List.for_all (dimension_satisfied record) required_dimension_names

let independent_review_complete record =
  let value = String.lowercase_ascii (String.trim record.independent_review) in
  value <> ""
  && not
       (List.exists
          (fun needle ->
            Option.is_some (Centl_sci_interaction.find_substring ~needle value))
          [ "not performed"; "awaiting"; "incomplete"; "none" ])

let designation_permitted record =
  record.status = Designated
  && all_dimensions_satisfied record
  && independent_review_complete record
  && List.length record.downstream_avenues >= 2

let assess_designation record =
  if record.status <> Candidate && record.status <> Designated then
    (record.status, "record is already narrowed or retired")
  else if not (all_dimensions_satisfied record) then
    ( Candidate,
      "one or more Wellspring dimensions remain unsatisfied or only partially \
       evidenced" )
  else if not (independent_review_complete record) then
    ( Candidate,
      "independent reproduction or adversarial review is incomplete; founder \
       or model declaration cannot designate a Wellspring" )
  else if List.length record.downstream_avenues < 2 then
    (Candidate, "fewer than two distinct downstream avenues are recorded")
  else if record.status = Designated && designation_permitted record then
    (Designated, "all documented designation requirements are present")
  else
    ( Candidate,
      "the finding remains a Wellspring Candidate until independent review \
       designates it" )

let dimension name satisfied evidence = { name; satisfied; evidence }

let candidate_unjustified_certainty =
  {
    id = "WS-CAND-001";
    title = "Authority cannot confer truth";
    status = Candidate;
    date_identified = "2026-08-14";
    investigators = [ "CENTL/FCF research expedition" ];
    originating_expedition = "secret-oasis-2026-08-14";
    source_identity =
      "docs/NUMERICS.md + docs/CENTL-MIRAGE.md + docs/CARAVAN.md";
    core_finding =
      "A reusable computational principle: a producer of bytes, prose, or \
       proposals never becomes authority over mathematical meaning, artifact \
       identity, or assurance. Exactness is independent of transformation \
       success; model output is untrusted input; carriers provide \
       availability, not trust; generated code does not inherit verified-core \
       status; admission requires an evidence lattice rather than a reward \
       score.";
    assumptions =
      [
        "The claim is a unifying principle across CENTL surfaces, not a claim \
         that each constituent technique is unprecedented.";
        "Prior art exists independently in interval arithmetic, proof-carrying \
         code, and TUF.";
      ];
    evidence =
      [
        "Implemented numerical contract: exact values, enclosures, and \
         unresolved results remain distinguishable.";
        "F* validates dyadic endpoints before decimal rendering.";
        "CENTL-SCi treats local models as interpreters of intent.";
        "MIRAGE admission is hard-gated before any scoring.";
        "CARAVAN carriers cannot define trusted artifact identity.";
      ];
    independent_review =
      "not performed; this expedition records a candidate only";
    counterexamples =
      [
        "If a scientific result required manufacturing an unqualified digit, \
         the principle would be too strong.";
        "If model output could be shown to confer mathematical authority \
         without a deterministic checker, the interpreter/authority split \
         would fail.";
      ];
    downstream_avenues =
      [
        "stronger numerical and rendering contracts";
        "self-development admissibility without model authority";
        "preservation networks that separate availability from trust";
        "machine interfaces that cannot promote generated assurance";
      ];
    oasis_impact =
      "none by itself; any implementation still requires ordinary Oasis \
       qualification";
    security_constraints =
      [ "does not authorize publication of sensitive expedition materials" ];
    falsifiers =
      [
        "independent review shows the unification is only a rename of one \
         existing technique";
        "a required CENTL result cannot be stated without collapsing \
         exactness, transformation resolution, or assurance";
        "reproduction fails to locate the principle in more than one \
         independent surface";
      ];
    references =
      [
        "docs/NUMERICS.md";
        "docs/CENTL-MIRAGE.md";
        "docs/CARAVAN.md";
        "docs/FCF-WELLSPRING.md";
      ];
    dimensions =
      [
        dimension "foundational_significance" true
          "the claim is a reusable authority/evidence separation, not a local \
           speedup";
        dimension "generative_value" true
          "at least four distinct downstream surfaces are articulable";
        dimension "evidence" false
          "implementations and tests exist, but novelty of the unification is \
           not independently reviewed";
        dimension "reproducibility_or_inspectability" true
          "the argument and implementations are inspectable in this repository";
        dimension "durability" true
          "deleting any one prototype leaves the principle usable elsewhere";
        dimension "relevance" true
          "the finding is internal to FCF computational, trust, and \
           preservation work";
        dimension "falsifiability_and_limits" true
          "explicit falsifiers and prior-art limits are recorded";
      ];
  }

let candidate_justified_decimal =
  {
    id = "WS-CAND-002";
    title = "Justified outward decimal rendering of validated dyadic enclosures";
    status = Candidate;
    date_identified = "2026-08-14";
    investigators = [ "CENTL/FCF research expedition" ];
    originating_expedition = "secret-oasis-2026-08-14";
    source_identity = "src/fstar/Centl.Core.fst";
    core_finding =
      "After the verified core accepts dyadic enclosure endpoints and an \
       exponent budget, outward conversion onto a shared decimal scale is a \
       proved containment. Printed digits are therefore justified by the \
       enclosure rather than by host floating-point formatting.";
    assumptions =
      [
        "The trusted base still includes F*, extraction, OCaml, and the \
         numerical backend that produced the dyadic endpoints.";
        "The theorem does not by itself make an enclosure narrow enough for a \
         requested digit count.";
      ];
    evidence =
      [
        "Centl.Core defines enclosure validation and outward decimal \
         containment over exact integer inequalities.";
        "Host rendering consumes the validated representation rather than \
         formatting machine floats.";
        "Deterministic and differential tests cover justified-digit cases.";
      ];
    independent_review =
      "not performed; formal proof of the local theorem is not the same as \
       independent designation review";
    counterexamples =
      [
        "If a printed digit can be shown to escape the validated enclosure, \
         the claim is false.";
        "If rendering is found to pass through host floating-point before \
         justification, the claim is false.";
      ];
    downstream_avenues =
      [
        "machine protocol decimal endpoints with explicit justification";
        "SCi presentation that cannot invent digits";
        "later verified interval operations that shrink the numerical trust \
         boundary";
      ];
    oasis_impact =
      "already present in the Oasis numerical contract; designation would not \
       change the v0.14.0 release identity";
    security_constraints = [];
    falsifiers =
      [
        "a counterexample enclosure whose rendered decimal is not an outward \
         rounding";
        "prior art showing the exact theorem and interface are already \
         standard and FCF's claim overstates novelty";
      ];
    references = [ "src/fstar/Centl.Core.fst"; "docs/NUMERICS.md" ];
    dimensions =
      [
        dimension "foundational_significance" true
          "justified digits are a core exactness interface, not a formatter \
           convenience";
        dimension "generative_value" true
          "rendering, protocol, and SCi presentation are independent consumers";
        dimension "evidence" true
          "the local containment contract is defined and tested in the \
           verified core";
        dimension "reproducibility_or_inspectability" true
          "the F* definitions are inspectable and extractable";
        dimension "durability" true
          "the theorem remains if the current host renderer is replaced";
        dimension "relevance" true "the finding is native CENTL numerics";
        dimension "falsifiability_and_limits" true
          "explicit numerical counterexamples would demote the claim";
      ];
  }

let catalog = [ candidate_unjustified_certainty; candidate_justified_decimal ]

let run_expedition () =
  let found =
    List.map
      (fun (item : wellspring_record) ->
        let next_status, _ = assess_designation item in
        { item with status = next_status })
      catalog
  in
  let designated_ids =
    List.rev
      (List.fold_left
         (fun acc (item : wellspring_record) ->
           match item.status with
           | Designated -> item.id :: acc
           | Candidate | Narrowed | Retired -> acc)
         [] found)
  in
  {
    id = "secret-oasis-2026-08-14";
    date = "2026-08-14";
    records = found;
    designated = designated_ids;
    summary =
      (if designated_ids = [] then
         "The expedition found Wellspring Candidates and no designated FCF \
          Wellspring. Under-designation is required: independent review has \
          not occurred, and Oasis v0.14.0 remains a release qualification \
          rather than a discovery."
       else "The expedition designated: " ^ String.concat ", " designated_ids);
  }

let dimension_to_json dimension =
  `Assoc
    [
      ("name", `String dimension.name);
      ("satisfied", `Bool dimension.satisfied);
      ("evidence", `String dimension.evidence);
    ]

let strings values = `List (List.map (fun value -> `String value) values)

let record_to_json record =
  let status, designation_note = assess_designation record in
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "FCF");
      ("artifact_kind", `String "wellspring_record");
      ("id", `String record.id);
      ("title", `String record.title);
      ("status", `String (status_text status));
      ("date_identified", `String record.date_identified);
      ("investigators", strings record.investigators);
      ("originating_expedition", `String record.originating_expedition);
      ("source_identity", `String record.source_identity);
      ("core_finding", `String record.core_finding);
      ("assumptions", strings record.assumptions);
      ("evidence", strings record.evidence);
      ("independent_review", `String record.independent_review);
      ("counterexamples", strings record.counterexamples);
      ("downstream_avenues", strings record.downstream_avenues);
      ("oasis_impact", `String record.oasis_impact);
      ("security_constraints", strings record.security_constraints);
      ("falsifiers", strings record.falsifiers);
      ("references", strings record.references);
      ("dimensions", `List (List.map dimension_to_json record.dimensions));
      ("designation_permitted", `Bool (designation_permitted record));
      ("designation_note", `String designation_note);
    ]

let expedition_to_json expedition =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "FCF");
      ("artifact_kind", `String "wellspring_expedition");
      ("id", `String expedition.id);
      ("date", `String expedition.date);
      ("designated", strings expedition.designated);
      ("candidate_count", `Int (List.length expedition.records));
      ("summary", `String expedition.summary);
      ("records", `List (List.map record_to_json expedition.records));
    ]

let render_record record =
  let status, note = assess_designation record in
  String.concat "\n"
    [
      "FCF Wellspring record " ^ record.id;
      "title: " ^ record.title;
      "status: " ^ status_text status;
      ("designation permitted: "
      ^ if designation_permitted record then "yes" else "no");
      note;
      "core finding: " ^ record.core_finding;
    ]

let render_expedition expedition =
  let lines =
    [
      "FCF Wellspring expedition " ^ expedition.id;
      expedition.summary;
      ("designated Wellsprings: "
      ^
      match expedition.designated with
      | [] -> "none"
      | values -> String.concat ", " values);
      "records:";
    ]
    @ List.map
        (fun record ->
          let status, _ = assess_designation record in
          Printf.sprintf "  - %s (%s) %s" record.id (status_text status)
            record.title)
        expedition.records
  in
  String.concat "\n" lines

let find_record id =
  List.find_opt
    (fun (item : wellspring_record) -> String.equal item.id id)
    catalog

let construct_expedition path =
  let expedition = run_expedition () in
  try
    Centl_sci_workspace.atomic_write_json path (expedition_to_json expedition);
    Ok (path, expedition)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message
