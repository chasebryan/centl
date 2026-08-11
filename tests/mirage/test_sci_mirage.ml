let write_text path text =
  Centl_sci_workspace.ensure_directory (Filename.dirname path);
  let channel = open_out path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () -> output_string channel text)

let temp_dir prefix =
  let path = Filename.temp_file prefix "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let cleanup path = try Centl_sci_snapshot.remove_tree path with _ -> ()

let test_cell_classification () =
  let cells =
    Centl_sci_mirage.cells_of_text
      "# Design\n\n\
       CENTL should add a recurrence solver.\n\n\
       The solver must preserve exact rational inputs.\n\n\
       Acceptance: fibonacci(10) returns 55.\n\n\
       - Example: fibonacci(6) = 8\n\
       - Do not add a network dependency.\n\n\
       What if the recurrence is under-specified?\n"
  in
  let kinds = List.map (fun cell -> cell.Centl_sci_mirage.kind) cells in
  Alcotest.(check bool)
    "directive detected" true
    (List.mem Centl_sci_mirage.Directive kinds);
  Alcotest.(check bool)
    "invariant detected" true
    (List.mem Centl_sci_mirage.Invariant kinds);
  Alcotest.(check bool)
    "acceptance detected" true
    (List.mem Centl_sci_mirage.Acceptance kinds);
  Alcotest.(check bool)
    "example detected" true
    (List.mem Centl_sci_mirage.Example kinds);
  Alcotest.(check bool)
    "non-goal detected" true
    (List.mem Centl_sci_mirage.Non_goal kinds);
  Alcotest.(check bool)
    "question detected" true
    (List.mem Centl_sci_mirage.Question kinds)

let test_ingestion_creates_local_cycle () =
  let root = temp_dir "centl-mirage-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let document = Filename.concat root "design.md" in
      write_text document
        "# Exact sequence design\n\n\
         CENTL should add a sequence helper.\n\n\
         The result must remain exact.\n\n\
         Acceptance: sequence terms are deterministic.\n";
      match Centl_sci_mirage.ingest workspace document with
      | Error message -> Alcotest.fail message
      | Ok result ->
          Alcotest.(check bool)
            "stored source exists" true
            (Sys.file_exists result.stored_path);
          Alcotest.(check bool)
            "specification IR exists" true
            (Sys.file_exists result.spec_path);
          Alcotest.(check bool)
            "development plan exists" true
            (Sys.file_exists result.plan_path);
          Alcotest.(check bool)
            "active cycle exists" true
            (Sys.file_exists result.active_path);
          Alcotest.(check bool) "cells extracted" true (result.cell_count >= 4);
          Alcotest.(check bool)
            "objectives extracted" true
            (result.objective_count >= 2);
          Alcotest.(check int) "workspace revision recorded" 1 result.revision;
          let spec = Yojson.Safe.from_file result.spec_path in
          begin match spec with
          | `Assoc fields ->
              begin match List.assoc_opt "system" fields with
              | Some (`String "CENTL-MIRAGE") -> ()
              | _ -> Alcotest.fail "specification IR must identify CENTL-MIRAGE"
              end;
              begin match List.assoc_opt "source_digest" fields with
              | Some (`String digest) ->
                  Alcotest.(check string)
                    "digest is stable result identity" result.source_digest
                    digest
              | _ -> Alcotest.fail "specification IR must retain source digest"
              end
          | _ -> Alcotest.fail "specification IR must be a JSON object"
          end)

let test_document_size_limit () =
  let root = temp_dir "centl-mirage-limit-" in
  Fun.protect
    ~finally:(fun () -> cleanup root)
    (fun () ->
      let workspace =
        Centl_sci_workspace.make (Filename.concat root "workspace")
      in
      let document = Filename.concat root "large.txt" in
      let channel = open_out_bin document in
      Fun.protect
        ~finally:(fun () -> close_out_noerr channel)
        (fun () ->
          output_string channel
            (String.make (Centl_sci_mirage.max_document_bytes + 1) 'x'));
      match Centl_sci_mirage.ingest workspace document with
      | Ok _ -> Alcotest.fail "oversized document should be rejected"
      | Error message ->
          Alcotest.(check bool)
            "limit failure is explicit" true
            (Option.is_some
               (Centl_sci_interaction.find_substring ~needle:"admits at most"
                  message)))

let () =
  Alcotest.run "CENTL-MIRAGE"
    [
      ( "specification ingestion",
        [
          Alcotest.test_case "cell classification" `Quick
            test_cell_classification;
          Alcotest.test_case "local cycle artifacts" `Quick
            test_ingestion_creates_local_cycle;
          Alcotest.test_case "document size limit" `Quick
            test_document_size_limit;
        ] );
    ]
