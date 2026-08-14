let document_text problem =
  String.concat "\n"
    [
      "# CENTL-SCi extension request";
      "";
      "CENTL should " ^ String.trim problem;
      "";
      "The result must remain exact when the admitted mathematics permits it.";
      "";
      "Do not add a network dependency.";
      "";
    ]

let write_request workspace problem =
  let problem = String.trim problem in
  if problem = "" then Error "extend requires a request"
  else
    try
      Centl_sci_workspace.ensure workspace;
      let digest = Centl_sha256.hex_string problem in
      let directory =
        Filename.concat workspace.Centl_sci_workspace.root "library"
      in
      Centl_sci_workspace.ensure_directory directory;
      let path = Filename.concat directory (digest ^ "-extension-request.md") in
      let temporary = path ^ ".tmp" in
      let channel =
        open_out_gen
          [ Open_wronly; Open_creat; Open_trunc; Open_text ]
          0o600 temporary
      in
      Fun.protect
        ~finally:(fun () -> close_out_noerr channel)
        (fun () ->
          output_string channel (document_text problem);
          flush channel);
      Unix.rename temporary path;
      Ok path
    with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let extend workspace problem =
  let ( let* ) = Result.bind in
  let* path = write_request workspace problem in
  let* cycle = Centl_sci_mirage_cycle.run workspace path in
  Ok
    (String.concat "\n"
       [
         "Started a local MIRAGE cycle from this request.";
         "Source: " ^ path;
         "This does not activate candidate source and does not promote \
          assurance.";
         "";
         Centl_sci_mirage_cycle.render cycle;
       ])
