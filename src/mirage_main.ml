let usage () =
  String.concat "\n"
    [
      "Usage:";
      "  centl-mirage start PATH";
      "  centl-mirage cycle PATH";
      "  centl-mirage ingest PATH";
      "  centl-mirage analyze SPEC_IR.json";
      "  centl-mirage status";
      "  centl-mirage iterate";
      "  centl-mirage library";
      "  centl-mirage fingerprint";
      "  centl-mirage policy [observe|stage|local|core]";
      "  centl-mirage accept CANDIDATE_ID";
      "  centl-mirage reject CANDIDATE_ID";
      "  centl-mirage wellspring";
      "  centl-mirage wellspring RECORD_ID";
      "  centl-mirage oasis";
      "  centl-mirage doctor";
      "  centl-mirage explain CANDIDATE_ID";
      "";
      "CENTL-MIRAGE is the local self-development engine for CENTL-SCi.";
      "A model may propose meaning; it may not confer truth or assurance.";
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

let start path =
  let workspace = workspace_or_exit () in
  match Centl_sci_mirage_cycle.run workspace path with
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2
  | Ok cycle ->
      print_endline (Centl_sci_mirage_cycle.render cycle);
      if cycle.obligations.blocked_cells <> [] then
        print_endline
          "MIRAGE staged only non-mutating candidate transactions and halted \
           candidate synthesis for blocked source cells. Evidence execution \
           and admission assessment do not override those source-level blocks."
      else
        print_endline
          "MIRAGE completed a local development cycle: specification IR, goal \
           graph, CEGIS example search, semantic fingerprints, evidence \
           execution, admission, and review. No candidate source was activated \
           by the cycle itself and no assurance was promoted."

let status () =
  let workspace = workspace_or_exit () in
  print_endline (Centl_sci_mirage.status workspace)

let iterate () =
  let workspace = workspace_or_exit () in
  match Centl_sci_mirage_cycle.continue workspace with
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2
  | Ok cycle ->
      print_endline (Centl_sci_mirage_cycle.render cycle);
      print_endline
        "MIRAGE recomputed gaps from the stored source document. No source was \
         activated by iteration and no assurance was promoted."

let library () =
  let workspace = workspace_or_exit () in
  print_endline (Centl_sci_mirage.list_library workspace)

let fingerprint () =
  let report = Centl_sci_mirage_fingerprint.observe_default () in
  print_endline (Centl_sci_mirage_fingerprint.render report)

let policy_command = function
  | [] ->
      let workspace = workspace_or_exit () in
      begin match Centl_sci_mirage_policy.load workspace with
      | Error message ->
          prerr_endline ("centl-mirage: " ^ message);
          exit 2
      | Ok policy -> print_endline (Centl_sci_mirage_policy.render policy)
      end
  | [ level ] ->
      let workspace = workspace_or_exit () in
      begin match Centl_sci_mirage_policy.parse_level level with
      | Error message ->
          prerr_endline ("centl-mirage: " ^ message);
          exit 2
      | Ok level ->
          let policy =
            { Centl_sci_mirage_policy.level; network_publication = false }
          in
          begin match Centl_sci_mirage_policy.store workspace policy with
          | Error message ->
              prerr_endline ("centl-mirage: " ^ message);
              exit 2
          | Ok policy -> print_endline (Centl_sci_mirage_policy.render policy)
          end
      end
  | _ ->
      prerr_endline (usage ());
      exit 2

let persist_decision workspace decision =
  let report =
    {
      Centl_sci_mirage_accept.policy =
        (match Centl_sci_mirage_policy.load workspace with
        | Ok policy -> Centl_sci_mirage_policy.level_text policy.level
        | Error _ -> "unknown");
      decisions = [ decision ];
      workspace_mutated = decision.activated;
      assurance_promoted = false;
    }
  in
  match
    Centl_sci_mirage_cycle.active_string workspace "candidate_review_manifest"
  with
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2
  | Ok review_path ->
      begin match Centl_sci_mirage_accept.construct review_path report with
      | Error message ->
          prerr_endline ("centl-mirage: " ^ message);
          exit 2
      | Ok (path, report) ->
          Printf.printf "Acceptance record: %s\n%s\n" path
            (Centl_sci_mirage_accept.render report)
      end

let accept candidate_id =
  let workspace = workspace_or_exit () in
  match Centl_sci_mirage_cycle.accept_from_active workspace candidate_id with
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2
  | Ok decision -> persist_decision workspace decision

let reject candidate_id =
  let workspace = workspace_or_exit () in
  persist_decision workspace (Centl_sci_mirage_accept.reject_one candidate_id)

let wellspring = function
  | [] ->
      let expedition = Centl_sci_wellspring.run_expedition () in
      print_endline (Centl_sci_wellspring.render_expedition expedition)
  | [ id ] -> (
      match Centl_sci_wellspring.find_record id with
      | None ->
          prerr_endline ("centl-mirage: unknown Wellspring record " ^ id);
          exit 2
      | Some record -> print_endline (Centl_sci_wellspring.render_record record)
      )
  | _ ->
      prerr_endline (usage ());
      exit 2

let explain candidate_id =
  let workspace = workspace_or_exit () in
  match
    Centl_sci_mirage_cycle.active_string workspace
      "candidate_admission_assessment"
  with
  | Error message ->
      prerr_endline ("centl-mirage: " ^ message);
      exit 2
  | Ok path -> (
      match Centl_sci_mirage_cycle.load_admission path candidate_id with
      | Error message ->
          prerr_endline ("centl-mirage: " ^ message);
          exit 2
      | Ok admission ->
          print_endline
            (String.concat "\n"
               [
                 "CENTL-MIRAGE explanation";
                 "candidate: " ^ candidate_id;
                 "admission: "
                 ^ Centl_sci_mirage_admission.state_text admission.state;
                 "rationale: " ^ admission.rationale;
                 "activated: no";
                 "assurance promoted: no";
                 "Explanation reads the active cycle; it does not activate \
                  source or confer mathematical authority.";
               ]))

let doctor () =
  let workspace = workspace_or_exit () in
  print_endline
    (Centl_sci_mirage_doctor.render (Centl_sci_mirage_doctor.inspect workspace))

let oasis () =
  let root =
    match Sys.getenv_opt "CENTL_ROOT" with
    | Some value when String.trim value <> "" -> String.trim value
    | _ -> Sys.getcwd ()
  in
  let branch =
    let ic = Unix.open_process_in "git branch --show-current" in
    Fun.protect
      ~finally:(fun () -> ignore (Unix.close_process_in ic))
      (fun () ->
        try input_line ic |> String.trim with End_of_file -> "unknown")
  in
  let report =
    Centl_sci_oasis.inspect ~root ~current_version:Centl_version.value ~branch
  in
  print_endline (Centl_sci_oasis.render report);
  if report.declaration then 0 else 0

let main () =
  match Array.to_list Sys.argv with
  | [ _; "status" ] -> status ()
  | [ _; "iterate" ] -> iterate ()
  | [ _; "library" ] -> library ()
  | _ :: "start" :: path_parts when path_parts <> [] ->
      start (String.concat " " path_parts)
  | _ :: "cycle" :: path_parts when path_parts <> [] ->
      start (String.concat " " path_parts)
  | _ :: "ingest" :: path_parts when path_parts <> [] ->
      ingest (String.concat " " path_parts)
  | _ :: "analyze" :: path_parts when path_parts <> [] ->
      analyze (String.concat " " path_parts)
  | [ _; "fingerprint" ] -> fingerprint ()
  | _ :: "policy" :: rest -> policy_command rest
  | [ _; "accept"; candidate_id ] -> accept candidate_id
  | [ _; "reject"; candidate_id ] -> reject candidate_id
  | _ :: "wellspring" :: rest -> wellspring rest
  | [ _; "oasis" ] -> ignore (oasis ())
  | [ _; "doctor" ] -> doctor ()
  | [ _; "explain"; candidate_id ] -> explain candidate_id
  | [ _; "--version" ] ->
      print_endline "CENTL-MIRAGE local self-development cycle"
  | _ ->
      prerr_endline (usage ());
      exit 2

let () = main ()
