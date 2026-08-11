type result_record = {
  id : int;
  input : string;
  normalized : string;
  mode : Centl_sci_interaction.mode;
  intent : string;
  result : string;
  details : string;
  workspace_revision : int option;
  timestamp : float;
}

type t = {
  mutable next_id : int;
  mutable results : result_record list;
  max_results : int;
}

let create ?(max_results = 100) () =
  { next_id = 1; results = []; max_results = max 1 max_results }

let trim max_results values =
  let rec take count acc = function
    | [] -> List.rev acc
    | _ when count <= 0 -> List.rev acc
    | value :: rest -> take (count - 1) (value :: acc) rest
  in
  take max_results [] values

let add session ~input ~normalized ~mode ~intent ~result ~details
    ~workspace_revision =
  let record =
    {
      id = session.next_id;
      input;
      normalized;
      mode;
      intent;
      result;
      details;
      workspace_revision;
      timestamp = Unix.gettimeofday ();
    }
  in
  session.next_id <- session.next_id + 1;
  session.results <- trim session.max_results (record :: session.results);
  record

let last session =
  match session.results with value :: _ -> Some value | [] -> None

let all session = List.rev session.results
let find session id = List.find_opt (fun item -> item.id = id) session.results

let render record =
  let revision =
    match record.workspace_revision with
    | None -> "unavailable"
    | Some value -> string_of_int value
  in
  String.concat "\n"
    [
      Printf.sprintf "Result %d" record.id;
      "  mode: " ^ Centl_sci_interaction.mode_text record.mode;
      "  intent: " ^ record.intent;
      "  input: " ^ record.input;
      "  normalized: " ^ record.normalized;
      "  workspace revision: " ^ revision;
      "  result: " ^ record.result;
    ]

let render_index session =
  match all session with
  | [] -> "(no results in this session)"
  | values ->
      values
      |> List.map (fun item -> Printf.sprintf "%4d  %s" item.id item.result)
      |> String.concat "\n"
