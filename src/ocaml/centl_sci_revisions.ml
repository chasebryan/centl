type entry = {
  revision : int;
  timestamp_unix : float;
  actor : string;
  scope : string;
}

type t = { current_revision : int; entries : entry list; truncated : bool }

let max_entries = 100

let assoc name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let entry_of_json json =
  match
    ( assoc "revision" json,
      assoc "timestamp_unix" json,
      assoc "actor" json,
      assoc "scope" json )
  with
  | ( Some (`Int revision),
      Some (`Float timestamp_unix),
      Some (`String actor),
      Some (`String scope) ) ->
      Some { revision; timestamp_unix; actor; scope }
  | ( Some (`Int revision),
      Some (`Int timestamp_unix),
      Some (`String actor),
      Some (`String scope) ) ->
      Some
        { revision; timestamp_unix = float_of_int timestamp_unix; actor; scope }
  | _ -> None

let append_bounded entries entry =
  let entries = entries @ [ entry ] in
  if List.length entries <= max_entries then entries else List.tl entries

let read workspace =
  let path = Centl_sci_workspace.revision_log_path workspace in
  if not (Sys.file_exists path) then
    Ok
      {
        current_revision = Centl_sci_workspace.read_revision workspace;
        entries = [];
        truncated = false;
      }
  else
    try
      let channel = open_in path in
      Fun.protect
        ~finally:(fun () -> close_in_noerr channel)
        (fun () ->
          let entries = ref [] in
          let parsed_count = ref 0 in
          let rec loop () =
            match input_line channel with
            | line ->
                begin try
                  match Yojson.Safe.from_string line |> entry_of_json with
                  | Some entry ->
                      incr parsed_count;
                      entries := append_bounded !entries entry
                  | None -> ()
                with Yojson.Json_error _ -> ()
                end;
                loop ()
            | exception End_of_file -> ()
          in
          loop ();
          Ok
            {
              current_revision = Centl_sci_workspace.read_revision workspace;
              entries = !entries;
              truncated = !parsed_count > max_entries;
            })
    with Sys_error message -> Error message

let render_entry entry =
  Printf.sprintf "  - r%d — %.6f — %s — %s" entry.revision entry.timestamp_unix
    entry.actor entry.scope

let render history =
  String.concat "\n"
    ([
       "Caramels workspace revisions";
       "  current revision: " ^ string_of_int history.current_revision;
       "  shown entries: " ^ string_of_int (List.length history.entries);
       "  bounded view: last " ^ string_of_int max_entries
       ^ " parsed entries maximum";
     ]
    @ (if history.entries = [] then [ "  - no recorded revision events" ]
       else List.map render_entry history.entries)
    @
    if history.truncated then
      [
        "  note: older revision events exist but are omitted from this bounded \
         view";
      ]
    else [])

let to_json history =
  let entry_json entry =
    `Assoc
      [
        ("revision", `Int entry.revision);
        ("timestamp_unix", `Float entry.timestamp_unix);
        ("actor", `String entry.actor);
        ("scope", `String entry.scope);
      ]
  in
  `Assoc
    [
      ("schema_version", `Int 1);
      ("centl_sci_version", `String "0.0.2-Caramels+");
      ("current_revision", `Int history.current_revision);
      ("entries", `List (List.map entry_json history.entries));
      ("truncated", `Bool history.truncated);
      ("max_entries", `Int max_entries);
    ]
