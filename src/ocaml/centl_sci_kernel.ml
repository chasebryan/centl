let rec callees acc = function
  | Centl_Core.Function (name, arguments) ->
      List.fold_left callees (name :: acc) arguments
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner ->
      callees acc inner
  | Centl_Core.Binary (_, left, right) -> callees (callees acc left) right
  | Centl_Core.Substitute (inner, _, replacement) ->
      callees (callees acc inner) replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      callees (callees (callees acc inner) left) right
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> acc

let uses_of_source source =
  match Centl_parser.parse_statement_located source with
  | Error _ -> []
  | Ok located -> (
      match located.statement with
      | Centl_parser.Define_function (name, parameters, body) ->
          callees [] body
          |> List.filter (fun callee ->
              callee <> name && not (List.mem callee parameters))
          |> List.sort_uniq String.compare
      | Centl_parser.Define_value (_, body) | Centl_parser.Evaluate body ->
          callees [] body |> List.sort_uniq String.compare
      | Centl_parser.Assert _ -> [])

let classify_use name =
  if List.mem name Centl_engine.reserved_names then "core"
  else
    match Centl_sci_workspace.default () with
    | None -> "unresolved"
    | Some workspace ->
        if
          Centl_sci_extensions.list workspace
          |> List.exists (fun item ->
              item.Centl_sci_extensions.enabled && item.name = name)
        then "local"
        else "unresolved"

let uses_line uses =
  match uses with
  | [] -> None
  | values ->
      Some
        ("Uses:\n"
        ^ String.concat "\n"
            (List.map
               (fun name ->
                 Printf.sprintf "  %s  (%s)" name (classify_use name))
               values))

let split_chain text =
  let text = String.trim text in
  match Centl_sci_codegen.split_at_ci " and then " text with
  | Some (left, right)
    when Centl_sci_program.wants_program left && String.trim right <> "" ->
      Some (String.trim left, String.trim right)
  | _ -> None

let unknown_call problem =
  let problem = String.trim problem in
  match Centl_parser.parse_statement_located problem with
  | Ok located -> (
      match located.statement with
      | Centl_parser.Evaluate (Centl_Core.Function (name, _))
        when (not (List.mem name Centl_engine.reserved_names))
             && Centl_sci_change_ir.valid_identifier name ->
          Some name
      | _ -> None)
  | Error _ -> None

let unknown_hint problem =
  match unknown_call problem with
  | None -> None
  | Some name ->
      let exists =
        match Centl_sci_workspace.default () with
        | None -> false
        | Some workspace ->
            Centl_sci_extensions.list workspace
            |> List.exists (fun item ->
                item.Centl_sci_extensions.enabled && item.name = name)
      in
      if exists then None
      else
        Some
          (Printf.sprintf
             "`%s` is not a live program in this session. Create it with:\n\
             \  make a function called %s that takes ... and computes ...\n\
              Or teach the session: teach yourself %s"
             name name name)

let restart_label = function
  | Centl_sci_program.Function | Centl_sci_program.Value
  | Centl_sci_program.Already_present ->
      "hot_loaded"
  | Centl_sci_program.Self_extend -> "inspect_only"
  | Centl_sci_program.Host_patch -> "restart_required"

let kind_label = function
  | Centl_sci_program.Function | Centl_sci_program.Value -> "create"
  | Centl_sci_program.Already_present -> "already"
  | Centl_sci_program.Self_extend -> "extend"
  | Centl_sci_program.Host_patch -> "host"

let record_program workspace plan ~input ~result =
  let uses =
    match plan.Centl_sci_program.source with
    | None -> []
    | Some source -> uses_of_source source
  in
  let cell =
    {
      Centl_sci_journal.kind = kind_label plan.kind;
      input;
      source = plan.source;
      result;
      uses;
      restart = restart_label plan.kind;
      name = plan.name;
    }
  in
  ignore (Centl_sci_journal.append workspace cell);
  ignore (Centl_sci_journal.write_dialect workspace);
  uses

let record_compute workspace ~input ~result =
  let uses = uses_of_source input in
  ignore
    (Centl_sci_journal.append workspace
       {
         kind = "compute";
         input;
         source = Some input;
         result = Some result;
         uses;
         restart = "none";
         name = None;
       })

let write_example_test workspace plan example result =
  match plan.Centl_sci_program.name with
  | None -> ()
  | Some name ->
      let path =
        Filename.concat workspace.Centl_sci_workspace.tests (name ^ ".centl")
      in
      let text =
        String.concat "\n"
          [
            "# Session evidence for " ^ name ^ ".";
            "# Not verified CENTL core.";
            example;
            "# → " ^ result;
            "";
          ]
      in
      begin try
        Centl_sci_workspace.ensure_directory workspace.Centl_sci_workspace.tests;
        Centl_sci_workspace.with_atomic_output path (fun channel ->
            output_string channel text)
      with Sys_error _ | Unix.Unix_error _ -> ()
      end
