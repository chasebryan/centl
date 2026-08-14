type t = {
  requirement_count : int;
  open_questions : int;
  blocked_requirements : int;
  admissible_candidates : int;
  established_properties : int;
  strongest_evidence : int;
  coverage : int;
}

let of_cycle ~graph ~obligations ~admission ~metamorphic ~lattice =
  let requirement_count =
    List.fold_left
      (fun total (node : Centl_sci_mirage_goal.node) ->
        match node.kind with
        | Centl_sci_mirage_goal.Requirement
        | Centl_sci_mirage_goal.Hard_invariant ->
            total + 1
        | _ -> total)
      0 graph.Centl_sci_mirage_goal.nodes
  in
  let open_questions =
    List.fold_left
      (fun total (node : Centl_sci_mirage_goal.node) ->
        if node.kind = Centl_sci_mirage_goal.Open_question then total + 1
        else total)
      0 graph.nodes
  in
  let blocked_requirements =
    List.length obligations.Centl_sci_mirage_obligation.blocked_cells
  in
  let admissible_candidates =
    List.fold_left
      (fun total candidate ->
        if
          candidate.Centl_sci_mirage_admission.state
          = Centl_sci_mirage_admission.Admissible
        then total + 1
        else total)
      0 admission.Centl_sci_mirage_admission.candidates
  in
  let established_properties =
    List.fold_left
      (fun total property ->
        if
          property.Centl_sci_mirage_metamorphic.status
          = Centl_sci_mirage_metamorphic.Established
        then total + 1
        else total)
      0 metamorphic.Centl_sci_mirage_metamorphic.properties
  in
  let strongest_evidence =
    List.fold_left
      (fun best candidate ->
        match candidate.Centl_sci_mirage_lattice.strongest_established with
        | None -> best
        | Some rank -> max best (Centl_sci_mirage_lattice.rank_order rank + 1))
      0 lattice.Centl_sci_mirage_lattice.candidates
  in
  {
    requirement_count;
    open_questions;
    blocked_requirements;
    admissible_candidates;
    established_properties;
    strongest_evidence;
    coverage = admissible_candidates + established_properties;
  }

let to_json progress =
  `Assoc
    [
      ("requirement_count", `Int progress.requirement_count);
      ("open_questions", `Int progress.open_questions);
      ("blocked_requirements", `Int progress.blocked_requirements);
      ("admissible_candidates", `Int progress.admissible_candidates);
      ("established_properties", `Int progress.established_properties);
      ("strongest_evidence", `Int progress.strongest_evidence);
      ("coverage", `Int progress.coverage);
    ]

let render progress =
  String.concat "\n"
    [
      "CENTL-MIRAGE progress";
      "requirements: " ^ string_of_int progress.requirement_count;
      "open questions: " ^ string_of_int progress.open_questions;
      "blocked requirements: " ^ string_of_int progress.blocked_requirements;
      "admissible candidates: " ^ string_of_int progress.admissible_candidates;
      "established properties: " ^ string_of_int progress.established_properties;
      "strongest evidence rank: " ^ string_of_int progress.strongest_evidence;
    ]
