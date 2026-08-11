let usage () =
  String.concat "\n"
    [
      "Usage:";
      "  centl-mirage start PATH";
      "  centl-mirage ingest PATH";
      "  centl-mirage analyze SPEC_IR.json";
      "  centl-mirage status";
      "";
      "CENTL-MIRAGE is the local self-development engine for CENTL-SCi.";
    ]

let workspace_or_exit () =
  match Centl_sci_workspace.default () with
  | Some workspace -> workspace
  | None ->
      prerr_endline
        "centl-mirage: no local workspace is available; set CENTL_WORKSPACE or \
         HOME";
      exit 2

let ingest_with workspace path =
  match Centl_sci_mirage.ingest workspace path with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let ingest path =
  let workspace = workspace_or_exit () in
  let result = ingest_with workspace path in
  print_endline (Centl_sci_mirage.render_ingest result)

let analyze_with workspace spec_path =
  match Centl_sci_mirage_goal.analyze workspace spec_path with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let analyze spec_path =
  let workspace = workspace_or_exit () in
  let path, graph = analyze_with workspace spec_path in
  Printf.printf "Goal graph: %s\n%s\n" path (Centl_sci_mirage_goal.render graph)

let obligations_with goal_path graph =
  match Centl_sci_mirage_obligation.construct goal_path graph with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let candidates_with obligations_path graph obligations =
  match
    Centl_sci_mirage_candidate.construct obligations_path graph obligations
  with
  | Ok result -> result
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2

let record_candidate_phase result goal_path graph obligations_path obligations
    candidates_path candidates =
  Centl_sci_workspace.atomic_write_json result.Centl_sci_mirage.active_path
    (`Assoc
       [
         ("schema_version", `Int 1);
         ("system", `String "CENTL-MIRAGE");
         ("status", `String "active");
         ("phase", `String "candidate_transactions_staged");
         ( "next_phase",
           `String
             (if obligations.Centl_sci_mirage_obligation.blocked_cells = [] then
                "candidate_synthesis_and_validation"
              else "resolve_blocking_requirements") );
         ("source_digest", `String result.source_digest);
         ("source_stored_path", `String result.stored_path);
         ("specification_ir", `String result.spec_path);
         ("development_plan", `String result.plan_path);
         ("goal_graph", `String goal_path);
         ("evidence_obligations", `String obligations_path);
         ("candidate_transactions", `String candidates_path);
         ("workspace_revision", `Int result.revision);
         ("goal_nodes", `Int (List.length graph.Centl_sci_mirage_goal.nodes));
         ("goal_edges", `Int (List.length graph.edges));
         ("goal_gaps", `Int (List.length graph.gaps));
         ("conflicts", `Int (List.length graph.conflicts));
         ( "evidence_obligation_count",
           `Int
             (List.length obligations.Centl_sci_mirage_obligation.obligations)
         );
         ( "candidate_transaction_count",
           `Int (List.length candidates.Centl_sci_mirage_candidate.candidates)
         );
         ( "candidate_blocked",
           `Bool (obligations.Centl_sci_mirage_obligation.blocked_cells <> [])
         );
         ( "blocked_cells",
           `List
             (List.map
                (fun id -> `Int id)
                obligations.Centl_sci_mirage_obligation.blocked_cells) );
         ("workspace_mutated", `Bool false);
         ("assurance_promoted", `Bool false);
         ("network_required", `Bool false);
       ])

let start path =
  let workspace = workspace_or_exit () in
  let result = ingest_with workspace path in
  let goal_path, graph = analyze_with workspace result.spec_path in
  let obligations_path, obligations = obligations_with goal_path graph in
  let candidates_path, candidates =
    candidates_with obligations_path graph obligations
  in
  record_candidate_phase result goal_path graph obligations_path obligations
    candidates_path candidates;
  print_endline (Centl_sci_mirage.render_ingest result);
  Printf.printf "Goal graph: %s\n%s\n" goal_path
    (Centl_sci_mirage_goal.render graph);
  Printf.printf "Evidence obligations: %s\n%s\n" obligations_path
    (Centl_sci_mirage_obligation.render obligations);
  Printf.printf "Candidate transactions: %s\n%s\n" candidates_path
    (Centl_sci_mirage_candidate.render candidates);
  if obligations.blocked_cells <> [] then
    print_endline
      "MIRAGE staged only non-mutating candidate transactions and halted \
       before synthesis for blocked source cells."
  else
    print_endline
      "MIRAGE staged non-mutating candidate transactions with explicit \
       evidence obligations. Next phase: candidate synthesis and validation."

let status () =
  let workspace = workspace_or_exit () in
  print_endline (Centl_sci_mirage.status workspace)

let main () =
  match Array.to_list Sys.argv with
  | [ _; "status" ] -> status ()
  | _ :: "start" :: path_parts when path_parts <> [] ->
      start (String.concat " " path_parts)
  | _ :: "ingest" :: path_parts when path_parts <> [] ->
      ingest (String.concat " " path_parts)
  | _ :: "analyze" :: path_parts when path_parts <> [] ->
      analyze (String.concat " " path_parts)
  | [ _; "--version" ] -> print_endline "CENTL-MIRAGE development bootstrap"
  | _ ->
      prerr_endline (usage ());
      exit 2

let () = main ()
