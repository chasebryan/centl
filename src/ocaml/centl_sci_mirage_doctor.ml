type check = { name : string; ok : bool; detail : string }
type report = { checks : check list; healthy : bool }

let check name ok detail = { name; ok; detail }

let artifact workspace field =
  match Centl_sci_mirage_cycle.active_string workspace field with
  | Error message -> check field false message
  | Ok path ->
      if Sys.file_exists path then check field true path
      else check field false ("missing artifact: " ^ path)

let inspect workspace =
  let cycle_path = Centl_sci_mirage.active_path workspace in
  let active =
    if Sys.file_exists cycle_path then check "active_cycle" true cycle_path
    else check "active_cycle" false "no active MIRAGE cycle"
  in
  let policy =
    match Centl_sci_mirage_policy.load workspace with
    | Ok policy ->
        check "autonomy_policy" true
          (Centl_sci_mirage_policy.level_text policy.level)
    | Error message -> check "autonomy_policy" false message
  in
  let artifacts =
    if not active.ok then []
    else
      List.map (artifact workspace)
        [
          "specification_ir";
          "goal_graph";
          "candidate_transactions";
          "semantic_fingerprint";
          "candidate_admission_assessment";
        ]
  in
  let checks =
    (active :: policy :: artifacts) @ [ check "network" true "not required" ]
  in
  { checks; healthy = List.for_all (fun check -> check.ok) checks }

let render report =
  let lines =
    List.map
      (fun check ->
        let mark = if check.ok then "ok" else "attention" in
        Printf.sprintf "  [%s] %s — %s" mark check.name check.detail)
      report.checks
  in
  String.concat "\n"
    ([
       "CENTL-MIRAGE doctor";
       (if report.healthy then "cycle health: healthy"
        else "cycle health: attention_required");
       "This is structural health, not Oasis qualification or verified-core \
        assurance.";
     ]
    @ lines)
