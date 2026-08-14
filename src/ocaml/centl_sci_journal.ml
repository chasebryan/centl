type cell = {
  kind : string;
  input : string;
  source : string option;
  result : string option;
  uses : string list;
  restart : string;
  name : string option;
}

let directory workspace =
  Filename.concat workspace.Centl_sci_workspace.history "growth"

let jsonl_path workspace = Filename.concat (directory workspace) "growth.jsonl"

let dialect_path workspace =
  Filename.concat (directory workspace) "dialect.centl"

let strings values = `List (List.map (fun value -> `String value) values)

let cell_to_json cell =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("kind", `String cell.kind);
      ("input", `String cell.input);
      ( "name",
        match cell.name with None -> `Null | Some value -> `String value );
      ( "source",
        match cell.source with None -> `Null | Some value -> `String value );
      ( "result",
        match cell.result with None -> `Null | Some value -> `String value );
      ("uses", strings cell.uses);
      ("restart", `String cell.restart);
      ("verified_core", `Bool false);
    ]

let option_string = function `String value -> Some value | `Null | _ -> None

let cell_of_json = function
  | `Assoc fields ->
      let field name = List.assoc_opt name fields in
      let string_field name =
        match field name with Some (`String value) -> Some value | _ -> None
      in
      let uses =
        match field "uses" with
        | Some (`List values) ->
            List.filter_map
              (function `String value -> Some value | _ -> None)
              values
        | _ -> []
      in
      begin match string_field "kind" with
      | None -> None
      | Some kind ->
          Some
            {
              kind;
              input = Option.value ~default:"" (string_field "input");
              source =
                (match field "source" with
                | Some value -> option_string value
                | None -> None);
              result =
                (match field "result" with
                | Some value -> option_string value
                | None -> None);
              uses;
              restart = Option.value ~default:"unknown" (string_field "restart");
              name =
                (match field "name" with
                | Some value -> option_string value
                | None -> None);
            }
      end
  | _ -> None

let read workspace =
  let path = jsonl_path workspace in
  if not (Sys.file_exists path) then []
  else
    let channel = open_in path in
    Fun.protect
      ~finally:(fun () -> close_in_noerr channel)
      (fun () ->
        let rec loop acc =
          match input_line channel with
          | line ->
              let line = String.trim line in
              if line = "" then loop acc
              else
                let cell =
                  try cell_of_json (Yojson.Safe.from_string line)
                  with Yojson.Json_error _ -> None
                in
                loop
                  (match cell with None -> acc | Some value -> value :: acc)
          | exception End_of_file -> List.rev acc
        in
        loop [])

let append workspace cell =
  try
    Centl_sci_workspace.ensure workspace;
    Centl_sci_workspace.ensure_directory (directory workspace);
    let path = jsonl_path workspace in
    let channel =
      open_out_gen
        [ Open_wronly; Open_append; Open_creat; Open_text ]
        0o600 path
    in
    Fun.protect
      ~finally:(fun () -> close_out_noerr channel)
      (fun () ->
        output_string channel (Yojson.Safe.to_string (cell_to_json cell));
        output_char channel '\n';
        flush channel);
    Ok ()
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let program_sources workspace =
  Centl_sci_extensions.list workspace
  |> List.filter (fun item ->
      item.Centl_sci_extensions.enabled && item.kind = "native_centl")
  |> List.filter_map (fun item ->
      let path = Centl_sci_extensions.source_path workspace item in
      try
        let channel = open_in path in
        Fun.protect
          ~finally:(fun () -> close_in_noerr channel)
          (fun () ->
            let buffer = Buffer.create 128 in
            begin try
              while true do
                Buffer.add_string buffer (input_line channel);
                Buffer.add_char buffer '\n'
              done
            with End_of_file -> ()
            end;
            let source = Buffer.contents buffer |> String.trim in
            if source = "" then None
            else Some (item.Centl_sci_extensions.name, source))
      with Sys_error _ -> None)

let dialect_text workspace =
  let programs = program_sources workspace in
  let cells = read workspace in
  let evidence =
    List.filter
      (fun cell ->
        (cell.kind = "create" || cell.kind = "already")
        && Option.is_some cell.result)
      cells
  in
  let header =
    [
      "# CENTL-SCi user dialect";
      "# Replay definitions with `centl --file PATH`.";
      "# Local programs are not verified CENTL core.";
      "";
    ]
  in
  let program_lines =
    match programs with
    | [] -> [ "# (no local programs enabled)"; "" ]
    | values ->
        List.concat_map
          (fun (name, source) ->
            let examples =
              evidence
              |> List.filter (fun cell -> cell.name = Some name)
              |> List.filter_map (fun cell ->
                  match (cell.source, cell.result) with
                  | Some _, Some result ->
                      Some
                        ("# session evidence: "
                        ^ Option.value ~default:name cell.source
                        ^ "  →  " ^ result)
                  | _ -> None)
            in
            [ source ] @ examples @ [ "" ])
          values
  in
  String.concat "\n" (header @ program_lines)

let write_dialect workspace =
  try
    Centl_sci_workspace.ensure_directory (directory workspace);
    Centl_sci_workspace.with_atomic_output (dialect_path workspace)
      (fun channel ->
        let text = dialect_text workspace in
        output_string channel text;
        if text = "" || text.[String.length text - 1] <> '\n' then
          output_char channel '\n');
    Ok (dialect_path workspace)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render workspace =
  let cells = read workspace in
  match cells with
  | [] ->
      "Growth journal is empty. Create a program or compute something; this \
       session will remember it here."
  | values ->
      let lines =
        List.mapi
          (fun index cell ->
            let name =
              match cell.name with None -> cell.kind | Some value -> value
            in
            let result =
              match cell.result with
              | None -> ""
              | Some value -> "  →  " ^ value
            in
            Printf.sprintf "%4d  [%s] %s%s" (index + 1) name cell.input result)
          values
      in
      String.concat "\n" ("Growth journal:" :: lines)

let export workspace path =
  let ( let* ) = Result.bind in
  let* dialect = write_dialect workspace in
  try
    Centl_sci_workspace.ensure_directory path;
    let copy source dest =
      if Sys.file_exists source then begin
        let channel = open_in source in
        let text =
          Fun.protect
            ~finally:(fun () -> close_in_noerr channel)
            (fun () -> really_input_string channel (in_channel_length channel))
        in
        Centl_sci_workspace.with_atomic_output dest (fun out ->
            output_string out text)
      end
    in
    copy dialect (Filename.concat path "dialect.centl");
    copy (jsonl_path workspace) (Filename.concat path "growth.jsonl");
    Centl_sci_workspace.with_atomic_output (Filename.concat path "README.md")
      (fun channel ->
        output_string channel
          "# CENTL-SCi exported dialect\n\n\
           This is a user-owned downstream dialect, not verified CENTL core.\n\n\
           Replay `dialect.centl` with `centl --file dialect.centl`.\n\
           `growth.jsonl` is the inspectable session journal.\n");
    Ok path
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message
