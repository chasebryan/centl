type example = {
  cell_id : int;
  source_text : string;
  left : string;
  right : string;
}

type trial_state = Valid | Counterexample | Unsynthesizable | No_examples

type trial = {
  iteration : int;
  candidate_id : string;
  source : string option;
  examples_checked : int;
  counterexamples : string list;
  state : trial_state;
}

type report = {
  examples : example list;
  trials : trial list;
  budget : int;
  accepted_source : string option;
}

let default_budget = 2

let state_text = function
  | Valid -> "valid"
  | Counterexample -> "counterexample"
  | Unsynthesizable -> "unsynthesizable"
  | No_examples -> "no_examples"

let lower text = String.lowercase_ascii (String.trim text)

let strip_example_markup text =
  let rec loop text =
    let trimmed = String.trim text in
    if
      String.length trimmed >= 2
      && (trimmed.[0] = '-' || trimmed.[0] = '*')
      && trimmed.[1] = ' '
    then loop (String.sub trimmed 2 (String.length trimmed - 2))
    else if String.length trimmed >= 2 && trimmed.[0] = '>' && trimmed.[1] = ' '
    then loop (String.sub trimmed 2 (String.length trimmed - 2))
    else trimmed
  in
  loop text

let strip_known_prefixes text =
  let prefixes =
    [
      "acceptance:";
      "expected:";
      "test:";
      "tests:";
      "example:";
      "for example:";
      "e.g.";
    ]
  in
  let value = lower text in
  let rec loop = function
    | [] -> String.trim text
    | prefix :: rest ->
        if String.starts_with ~prefix value then
          String.sub text (String.length prefix)
            (String.length text - String.length prefix)
          |> String.trim
        else loop rest
  in
  loop prefixes

let split_expectation text =
  let text = text |> strip_example_markup |> strip_known_prefixes in
  match
    Centl_sci_interaction.find_substring ~needle:" returns " (lower text)
  with
  | Some index ->
      let left = String.sub text 0 index |> String.trim in
      let right =
        String.sub text
          (index + String.length " returns ")
          (String.length text - index - String.length " returns ")
        |> String.trim
      in
      if left = "" || right = "" then None else Some (left, right)
  | None ->
      begin match Centl_sci_interaction.find_substring ~needle:" = " text with
      | None -> None
      | Some index ->
          let left = String.sub text 0 index |> String.trim in
          let right =
            String.sub text (index + 3) (String.length text - index - 3)
            |> String.trim
          in
          if left = "" || right = "" then None else Some (left, right)
      end

let parses_expression source =
  match Centl_parser.parse_located source with Ok _ -> true | Error _ -> false

let example_of_cell (cell : Centl_sci_mirage_goal.spec_cell) =
  match String.uppercase_ascii cell.kind with
  | "EXAMPLE" | "ACCEPTANCE" ->
      begin match split_expectation cell.text with
      | None -> None
      | Some (left, right) ->
          if parses_expression left && parses_expression right then
            Some { cell_id = cell.id; source_text = cell.text; left; right }
          else None
      end
  | _ -> None

let examples_of_graph (graph : Centl_sci_mirage_goal.graph) =
  graph.nodes
  |> List.filter_map (fun (node : Centl_sci_mirage_goal.node) ->
      match (node.source_cell, node.kind) with
      | ( Some cell_id,
          ( Centl_sci_mirage_goal.Example_case
          | Centl_sci_mirage_goal.Acceptance_criterion ) ) ->
          example_of_cell
            {
              id = cell_id;
              kind =
                (match node.kind with
                | Centl_sci_mirage_goal.Example_case -> "EXAMPLE"
                | _ -> "ACCEPTANCE");
              text = node.label;
              start_line = 0;
              end_line = 0;
            }
      | _ -> None)

let session_value_text session source =
  match Centl_engine.evaluate_in_session_detailed session source with
  | Ok outcome -> (
      match outcome.result with
      | Centl_engine.Session_value value ->
          Ok (Centl_engine.text_of_value value)
      | Centl_engine.Defined_value (_, value) ->
          Ok (Centl_engine.text_of_value value)
      | Centl_engine.Defined_function (name, _, _) -> Ok ("defined:" ^ name))
  | Error error -> Error (Centl_engine.error_text error)

let load_source session source =
  match Centl_engine.evaluate_in_session_detailed session source with
  | Ok _ -> Ok ()
  | Error error -> Error (Centl_engine.error_text error)

let check_example session example =
  match
    ( session_value_text session example.left,
      session_value_text session example.right )
  with
  | Ok left, Ok right when String.equal left right -> None
  | Ok left, Ok right ->
      Some
        (Printf.sprintf "%s evaluated to %s, expected %s" example.left left
           right)
  | Error message, _ | _, Error message ->
      Some (Printf.sprintf "%s failed: %s" example.left message)

(* Copy bindings by evaluating the candidate source in a fresh session. *)
let session_with_source source =
  let session = Centl_engine.create_session () in
  match source with
  | None -> Ok session
  | Some source -> (
      match load_source session source with
      | Ok () -> Ok session
      | Error _ as error -> error)

let evaluate_candidate ~iteration ~examples candidate source =
  match session_with_source source with
  | Error message ->
      {
        iteration;
        candidate_id = candidate.Centl_sci_mirage_candidate.id;
        source;
        examples_checked = 0;
        counterexamples = [ message ];
        state = Unsynthesizable;
      }
  | Ok session ->
      if examples = [] then
        {
          iteration;
          candidate_id = candidate.id;
          source;
          examples_checked = 0;
          counterexamples = [];
          state = No_examples;
        }
      else
        let counterexamples =
          List.filter_map (check_example session) examples
        in
        {
          iteration;
          candidate_id = candidate.id;
          source;
          examples_checked = List.length examples;
          counterexamples;
          state = (if counterexamples = [] then Valid else Counterexample);
        }

let source_of_item = function
  | Some (item : Centl_sci_mirage_materialize.item) -> item.source
  | None -> None

let item_for materialization candidate_id =
  List.find_opt
    (fun item ->
      String.equal item.Centl_sci_mirage_materialize.candidate_id candidate_id)
    materialization.Centl_sci_mirage_materialize.items

let run ?(budget = default_budget) graph
    (candidates : Centl_sci_mirage_candidate.report)
    (materialization : Centl_sci_mirage_materialize.report) =
  let examples = examples_of_graph graph in
  let budget = max 1 budget in
  let trials =
    List.map
      (fun candidate ->
        let item =
          item_for materialization candidate.Centl_sci_mirage_candidate.id
        in
        let source = source_of_item item in
        let first =
          evaluate_candidate ~iteration:1 ~examples candidate source
        in
        match first.state with
        | Counterexample when budget > 1 && source = None ->
            [
              first;
              {
                first with
                iteration = 2;
                state = Unsynthesizable;
                counterexamples =
                  first.counterexamples
                  @ [
                      "no alternative deterministic generator is available \
                       after the first counterexample";
                    ];
              };
            ]
        | Counterexample when budget > 1 ->
            [
              first;
              {
                first with
                iteration = 2;
                state = Unsynthesizable;
                counterexamples =
                  first.counterexamples
                  @ [
                      "the verifier rejected the only deterministic lowering; \
                       MIRAGE will not invent a second implementation";
                    ];
              };
            ]
        | _ -> [ first ])
      candidates.candidates
    |> List.concat
  in
  let accepted_source =
    trials
    |> List.find_opt (fun trial -> trial.state = Valid && trial.source <> None)
    |> Option.map (fun trial -> trial.source)
    |> Option.join
  in
  { examples; trials; budget; accepted_source }

let example_to_json example =
  `Assoc
    [
      ("cell_id", `Int example.cell_id);
      ("source_text", `String example.source_text);
      ("left", `String example.left);
      ("right", `String example.right);
    ]

let trial_to_json trial =
  `Assoc
    [
      ("iteration", `Int trial.iteration);
      ("candidate_id", `String trial.candidate_id);
      ( "source",
        match trial.source with None -> `Null | Some value -> `String value );
      ("examples_checked", `Int trial.examples_checked);
      ( "counterexamples",
        `List (List.map (fun value -> `String value) trial.counterexamples) );
      ("state", `String (state_text trial.state));
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "cegis_search");
      ("example_count", `Int (List.length report.examples));
      ("trial_count", `Int (List.length report.trials));
      ("budget", `Int report.budget);
      ( "accepted_source",
        match report.accepted_source with
        | None -> `Null
        | Some value -> `String value );
      ( "cegis_semantics",
        `String
          "the verifier, not the generator, closes the loop; a valid trial \
           means only that extracted examples evaluated equal under the \
           candidate, not that the candidate is complete or verified core" );
      ("examples", `List (List.map example_to_json report.examples));
      ("trials", `List (List.map trial_to_json report.trials));
    ]

let output_path materialization_path =
  if String.ends_with ~suffix:".materialization.json" materialization_path then
    String.sub materialization_path 0
      (String.length materialization_path
      - String.length ".materialization.json")
    ^ ".cegis.json"
  else materialization_path ^ ".cegis.json"

let construct materialization_path graph candidates materialization =
  let report = run graph candidates materialization in
  let path = output_path materialization_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  let valid =
    List.fold_left
      (fun total trial -> if trial.state = Valid then total + 1 else total)
      0 report.trials
  in
  String.concat "\n"
    [
      "CENTL-MIRAGE CEGIS search";
      "extracted examples: " ^ string_of_int (List.length report.examples);
      "trials: " ^ string_of_int (List.length report.trials);
      "valid trials: " ^ string_of_int valid;
      "budget: " ^ string_of_int report.budget;
      "assurance promoted: no";
    ]
