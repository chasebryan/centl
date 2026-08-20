open Centl_chemistry

let usage () =
  Printf.eprintf
    "Usage:\n\
    \  centl-chem atoms FORMULA\n\
    \  centl-chem balance 'REACTION'\n\
    \  centl-chem spread UNIT VALUE [VALUE ...]\n\
    \  centl-chem spread measured UNIT VALUE [VALUE ...]\n\
    \  centl-chem spread exact UNIT VALUE [VALUE ...]\n\
    \  centl-chem --json atoms FORMULA\n\
    \  centl-chem --json balance 'REACTION'\n\
    \  centl-chem --json spread UNIT VALUE [VALUE ...]\n\
    \  centl-chem --json spread measured UNIT VALUE [VALUE ...]\n\
    \  centl-chem --json spread exact UNIT VALUE [VALUE ...]\n";
  exit 2

let fail error =
  Printf.eprintf "centl-chem: %s\n" (error_message error);
  exit 1

let fail_sample error =
  Printf.eprintf "centl-chem: %s\n" (Centl_chemistry_sample.error_message error);
  exit 1

let command_atoms formula_text =
  match parse_formula formula_text with
  | Error error -> fail error
  | Ok formula ->
      formula_bindings formula
      |> List.iter (fun (element, count) ->
             Printf.printf "%s=%s\n" element (Z.to_string count))

let command_balance reaction_text =
  match balance reaction_text with
  | Error error -> fail error
  | Ok balanced ->
      Printf.printf "%s\n" (render_balanced balanced);
      List.iter
        (fun item ->
          Printf.printf "%s: %s = %s\n" item.element
            (Z.to_string item.reactants) (Z.to_string item.products))
        balanced.conservation;
      Printf.printf "verified=%s\n" (if balanced.verified then "true" else "false")

let q_text = Q.to_string

let command_spread observation_class unit_symbol values =
  match
    Centl_chemistry_sample.summarize_strings ~observation_class ~unit_symbol values
  with
  | Error error -> fail_sample error
  | Ok summary ->
      Printf.printf "source_class=%s\n"
        (Centl_chemistry_sample.observation_class_to_string
           summary.observation_class);
      Printf.printf "arithmetic_class=exact_over_reported_values\n";
      Printf.printf "n=%d\n" summary.n;
      Printf.printf "unit=%s\n" summary.unit_symbol;
      Printf.printf "observations=%s\n"
        (String.concat "," (List.map q_text summary.observations));
      Printf.printf "mean=%s %s\n" (q_text summary.mean) summary.unit_symbol;
      Printf.printf "median=%s %s\n" (q_text summary.median) summary.unit_symbol;
      Printf.printf "minimum=%s %s\n" (q_text summary.minimum) summary.unit_symbol;
      Printf.printf "maximum=%s %s\n" (q_text summary.maximum) summary.unit_symbol;
      Printf.printf "range=%s %s\n" (q_text summary.range) summary.unit_symbol;
      Printf.printf "mad=%s %s\n" (q_text summary.median_absolute_deviation)
        summary.unit_symbol;
      Printf.printf "population_variance=%s (%s)^2\n"
        (q_text summary.population_variance) summary.unit_symbol;
      Printf.printf "population_sd=%s %s\n"
        (Centl_chemistry_sample.root_to_string
           summary.population_standard_deviation)
        summary.unit_symbol;
      begin
        match summary.sample_variance with
        | None ->
            Printf.printf
              "sample_variance=undefined(requires_at_least_two_observations)\n"
        | Some value ->
            Printf.printf "sample_variance=%s (%s)^2\n" (q_text value)
              summary.unit_symbol
      end;
      Printf.printf "sample_sd=%s %s\n"
        (Centl_chemistry_sample.derived_root_to_string
           summary.sample_standard_deviation)
        summary.unit_symbol;
      Printf.printf "standard_error=%s %s\n"
        (Centl_chemistry_sample.derived_root_to_string
           summary.standard_error_of_mean)
        summary.unit_symbol;
      Printf.printf "rsd_fraction=%s\n"
        (Centl_chemistry_sample.derived_root_to_string
           summary.relative_standard_deviation);
      Printf.printf
        "confidence_interval=not_computed(requires_declared_confidence_model_and_level)\n";
      Printf.printf "measurement_uncertainty=not_provided\n"

let command_json request =
  match request with
  | Ok json -> print_endline (Yojson.Safe.to_string json)
  | Error json ->
      print_endline (Yojson.Safe.to_string json);
      exit 1

let () =
  match Array.to_list Sys.argv with
  | [ _; "atoms"; formula ] -> command_atoms formula
  | [ _; "balance"; reaction ] -> command_balance reaction
  | _ :: "spread" :: "measured" :: unit_symbol :: values when values <> [] ->
      command_spread Centl_chemistry_sample.Measured unit_symbol values
  | _ :: "spread" :: "exact" :: unit_symbol :: values when values <> [] ->
      command_spread Centl_chemistry_sample.Declared_exact unit_symbol values
  | _ :: "spread" :: unit_symbol :: values when values <> [] ->
      command_spread Centl_chemistry_sample.Measured unit_symbol values
  | [ _; "--json"; "atoms"; formula ] ->
      command_json (Centl_chemistry_protocol.atoms_request formula)
  | [ _; "--json"; "balance"; reaction ] ->
      command_json (Centl_chemistry_protocol.balance_request reaction)
  | _ :: "--json" :: "spread" :: "measured" :: unit_symbol :: values
    when values <> [] ->
      command_json
        (Centl_chemistry_sample_protocol.spread_request
           ~observation_class:Centl_chemistry_sample.Measured ~unit_symbol values)
  | _ :: "--json" :: "spread" :: "exact" :: unit_symbol :: values
    when values <> [] ->
      command_json
        (Centl_chemistry_sample_protocol.spread_request
           ~observation_class:Centl_chemistry_sample.Declared_exact ~unit_symbol
           values)
  | _ :: "--json" :: "spread" :: unit_symbol :: values when values <> [] ->
      command_json
        (Centl_chemistry_sample_protocol.spread_request ~unit_symbol values)
  | _ -> usage ()
