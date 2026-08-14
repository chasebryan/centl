let header =
  [
    "# CENTL-SCi workbook";
    "# Deterministic session export. Not verified-core assurance.";
    "# Replay supported lines with `centl --file PATH`.";
    "";
  ]

let recoverable_source record =
  match Centl_sci_fastpath.interpret record.Centl_sci_session.normalized with
  | Some (Centl_sci_ir.Exact_expression { expression; _ }) -> Some expression
  | Some (Centl_sci_ir.Polynomial_equation { left; right; variable; _ }) ->
      Some (Printf.sprintf "solve(%s = %s, %s)" left right variable)
  | _ -> (
      match Centl_parser.parse_located record.normalized with
      | Ok _ -> Some record.normalized
      | Error _ -> None)

let render_record record =
  let comment lines = List.map (fun line -> "# " ^ line) lines in
  let prelude =
    comment
      [
        Printf.sprintf "result %d" record.Centl_sci_session.id;
        "input: " ^ record.input;
        "result: " ^ record.result;
      ]
  in
  match recoverable_source record with
  | Some source -> prelude @ [ source; "" ]
  | None -> prelude @ [ "# (no replayable CENTL source recovered)"; "" ]

let render ?workspace session =
  let dialect =
    match workspace with
    | None -> (
        match Centl_sci_workspace.default () with
        | None -> []
        | Some workspace ->
            [
              "# live dialect";
              Centl_sci_journal.dialect_text workspace;
              "";
              "# session cells";
              "";
            ])
    | Some workspace ->
        [
          "# live dialect";
          Centl_sci_journal.dialect_text workspace;
          "";
          "# session cells";
          "";
        ]
  in
  let body =
    match Centl_sci_session.all session with
    | [] -> [ "# (empty session)"; "" ]
    | records -> List.concat_map render_record records
  in
  String.concat "\n" (header @ dialect @ body)

let export path session =
  try
    Centl_sci_workspace.ensure_directory (Filename.dirname path);
    let temporary = path ^ ".tmp" in
    let channel =
      open_out_gen
        [ Open_wronly; Open_creat; Open_trunc; Open_text ]
        0o600 temporary
    in
    Fun.protect
      ~finally:(fun () -> close_out_noerr channel)
      (fun () ->
        output_string channel (render session);
        flush channel);
    Unix.rename temporary path;
    Ok path
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message
