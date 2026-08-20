let usage () =
  Printf.eprintf
    "Usage:\n\
    \  centl-cps preflight [measured|exact] FORMULA=MOLES [FORMULA=MOLES ...]\n\
    \  centl-cps --json preflight [measured|exact] FORMULA=MOLES [FORMULA=MOLES ...]\n";
  exit 2

let q_text = Q.to_string

let fail error =
  Printf.eprintf "centl-cps: %s\n" (Centl_cps.error_message error);
  exit 1

let result_source_class = function
  | Centl_chemistry_amount.Unspecified -> "derived_from_unspecified"
  | Centl_chemistry_amount.Measured -> "derived_from_measured"
  | Centl_chemistry_amount.Declared_exact -> "derived_exact"

let print_provenance source_class =
  Printf.printf "input_source_class=%s\n"
    (Centl_chemistry_amount.source_class_to_string source_class);
  Printf.printf "result_source_class=%s\n" (result_source_class source_class);
  Printf.printf "arithmetic_class=exact_over_supplied_values\n"

let render_species (item : Centl_cps.species_input) =
  Printf.sprintf "%s[%s]:%s" item.formula_text item.composition_key
    (q_text item.moles)

let render_elemental_moles items =
  items
  |> List.map (fun (element, moles) -> element ^ ":" ^ q_text moles)
  |> String.concat ","

let command_preflight source_class assignments =
  match Centl_cps.preflight ~source_class assignments with
  | Error error -> fail error
  | Ok result ->
      print_provenance result.source_class;
      Printf.printf "composition_validated=true\n";
      Printf.printf "species_count=%d\n" (List.length result.species);
      Printf.printf "species=%s mol\n"
        (String.concat "," (List.map render_species result.species));
      Printf.printf "total_species_moles=%s mol\n"
        (q_text result.total_species_moles);
      Printf.printf "elemental_inventory=%s mol-of-atoms\n"
        (render_elemental_moles result.elemental_moles);
      Printf.printf "N_A=%s 1/mol\n" (q_text result.avogadro_value);
      Printf.printf "N_A_provenance=%s\n" result.avogadro_provenance;
      Printf.printf "reaction_model=not_provided\n";
      Printf.printf "thermodynamics=not_evaluated\n";
      Printf.printf "kinetics=not_evaluated\n";
      Printf.printf "phase_pressure=not_evaluated\n";
      Printf.printf "safety_evidence=not_evaluated\n";
      Printf.printf "measurement_uncertainty=not_provided\n";
      Printf.printf "prediction=not_performed\n"

let command_json request =
  match request with
  | Ok json -> print_endline (Yojson.Safe.to_string json)
  | Error json ->
      print_endline (Yojson.Safe.to_string json);
      exit 1

let () =
  match Array.to_list Sys.argv with
  | _ :: "preflight" :: "measured" :: assignments when assignments <> [] ->
      command_preflight Centl_chemistry_amount.Measured assignments
  | _ :: "preflight" :: "exact" :: assignments when assignments <> [] ->
      command_preflight Centl_chemistry_amount.Declared_exact assignments
  | _ :: "preflight" :: assignments when assignments <> [] ->
      command_preflight Centl_chemistry_amount.Unspecified assignments
  | _ :: "--json" :: "preflight" :: "measured" :: assignments
    when assignments <> [] ->
      command_json
        (Centl_cps_protocol.request ~source_class:Centl_chemistry_amount.Measured
           assignments)
  | _ :: "--json" :: "preflight" :: "exact" :: assignments
    when assignments <> [] ->
      command_json
        (Centl_cps_protocol.request
           ~source_class:Centl_chemistry_amount.Declared_exact assignments)
  | _ :: "--json" :: "preflight" :: assignments when assignments <> [] ->
      command_json (Centl_cps_protocol.request assignments)
  | _ -> usage ()
