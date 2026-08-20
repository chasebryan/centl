open Centl_chemistry

let usage () =
  Printf.eprintf
    "Usage:\n\
    \  centl-chem atoms FORMULA\n\
    \  centl-chem balance 'REACTION'\n\
    \  centl-chem particles [measured|exact] MOLES\n\
    \  centl-chem moles [measured|exact] ENTITY_COUNT\n\
    \  centl-chem stoich [measured|exact] 'REACTION' SOURCE_SPECIES SOURCE_MOLES TARGET_SPECIES\n\
    \  centl-chem limiting [measured|exact] 'REACTION' FORMULA=MOLES [FORMULA=MOLES ...]\n\
    \  centl-chem spread UNIT VALUE [VALUE ...]\n\
    \  centl-chem spread measured UNIT VALUE [VALUE ...]\n\
    \  centl-chem spread exact UNIT VALUE [VALUE ...]\n\
    \  centl-chem --json atoms FORMULA\n\
    \  centl-chem --json balance 'REACTION'\n\
    \  centl-chem --json particles [measured|exact] MOLES\n\
    \  centl-chem --json moles [measured|exact] ENTITY_COUNT\n\
    \  centl-chem --json stoich [measured|exact] 'REACTION' SOURCE_SPECIES SOURCE_MOLES TARGET_SPECIES\n\
    \  centl-chem --json limiting [measured|exact] 'REACTION' FORMULA=MOLES [FORMULA=MOLES ...]\n\
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

let fail_amount error =
  Printf.eprintf "centl-chem: %s\n" (Centl_chemistry_amount.error_message error);
  exit 1

let fail_limiting error =
  Printf.eprintf "centl-chem: %s\n" (Centl_chemistry_limiting.error_message error);
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

let command_constant symbol =
  match Centl_chemistry_constants.constant symbol with
  | Error error ->
      Printf.eprintf "centl-chem: %s\n"
        (Centl_chemistry_constants.error_message error);
      exit 1
  | Ok derived ->
      Printf.printf "%s=%s %s\n" derived.symbol (Q.to_string derived.value)
        derived.unit;
      Printf.printf "definition=%s\n" derived.definition;
      Printf.printf "provenance=%s\n" derived.provenance

let command_molar_mass formula =
  match Centl_chemistry_data.molar_mass formula with
  | Error error ->
      Printf.eprintf "centl-chem: %s\n"
        (Centl_chemistry_data.error_message error);
      exit 1
  | Ok result ->
      Printf.printf "formula=%s\n" result.formula;
      Printf.printf "lower=%s %s\n" (Q.to_string result.lower) result.unit;
      Printf.printf "upper=%s %s\n" (Q.to_string result.upper) result.unit;
      Printf.printf "exact=%s\n" (if result.exact then "true" else "false");
      List.iter
        (fun (item : Centl_chemistry_data.provenance) ->
          Printf.printf "provenance=%s@%s:%s\n" item.source
            item.dataset_version item.status)
        result.provenance

let parse_q_or_fail text =
  try Q.of_string text
  with Invalid_argument _ | Failure _ | Division_by_zero ->
    Printf.eprintf "centl-chem: invalid exact value %S\n" text;
    exit 1

let command_concentration moles volume =
  match
    Centl_chemistry_models.concentration ~moles:(parse_q_or_fail moles)
      ~volume_l:(parse_q_or_fail volume)
  with
  | Error error ->
      Printf.eprintf "centl-chem: %s\n"
        (Centl_chemistry_models.error_message error);
      exit 1
  | Ok result ->
      Printf.printf "concentration=%s %s\n" (Q.to_string result.value)
        result.unit;
      Printf.printf "arithmetic_class=%s\n" result.arithmetic_class

let command_dilution concentration initial_volume final_volume =
  match
    Centl_chemistry_models.dilution
      ~initial_concentration:(parse_q_or_fail concentration)
      ~initial_volume_l:(parse_q_or_fail initial_volume)
      ~final_volume_l:(parse_q_or_fail final_volume)
  with
  | Error error ->
      Printf.eprintf "centl-chem: %s\n"
        (Centl_chemistry_models.error_message error);
      exit 1
  | Ok result ->
      Printf.printf "final_concentration=%s %s\n"
        (Q.to_string result.final_concentration) result.unit;
      Printf.printf "arithmetic_class=%s\n" result.arithmetic_class

let command_yield actual theoretical =
  match
    Centl_chemistry_models.theoretical_yield
      ~actual:(parse_q_or_fail actual) ~theoretical:(parse_q_or_fail theoretical)
  with
  | Error error ->
      Printf.eprintf "centl-chem: %s\n"
        (Centl_chemistry_models.error_message error);
      exit 1
  | Ok result ->
      Printf.printf "percent_yield=%s %s\n" (Q.to_string result.percentage)
        result.unit;
      Printf.printf "arithmetic_class=%s\n" result.arithmetic_class

let command_gas moles temperature volume =
  match
    Centl_chemistry_models.ideal_gas_pressure
      ~moles:(parse_q_or_fail moles)
      ~temperature_k:(parse_q_or_fail temperature)
      ~volume_m3:(parse_q_or_fail volume)
  with
  | Error error ->
      Printf.eprintf "centl-chem: %s\n"
        (Centl_chemistry_models.error_message error);
      exit 1
  | Ok result ->
      Printf.printf "pressure=%s Pa\n" (Q.to_string result.pressure_pa);
      Printf.printf "model=%s\n" result.gas_model;
      Printf.printf "provenance=%s\n" result.constant_provenance

let command_charge electron_moles =
  match
    Centl_chemistry_models.charge_from_electron_moles
      (parse_q_or_fail electron_moles)
  with
  | Error error ->
      Printf.eprintf "centl-chem: %s\n"
        (Centl_chemistry_models.error_message error);
      exit 1
  | Ok result ->
      Printf.printf "charge=%s C\n" (Q.to_string result.charge_c);
      Printf.printf "provenance=%s\n" result.constant_provenance

let parse_enthalpy_assignment text =
  match String.split_on_char '=' text with
  | [ species; value ] when String.trim species <> "" ->
      begin
        try
          Ok
            {
              Centl_chemistry_thermo.species = String.trim species;
              value = Q.of_string (String.trim value);
              source_class = "supplied_measured_or_reference";
            }
        with Invalid_argument _ | Failure _ | Division_by_zero ->
          Error (Centl_chemistry_thermo.Invalid_enthalpy value)
      end
  | _ -> Error (Centl_chemistry_thermo.Invalid_enthalpy text)

let command_thermo reaction assignments =
  let rec parse reversed = function
    | [] -> Ok (List.rev reversed)
    | assignment :: rest ->
        begin
          match parse_enthalpy_assignment assignment with
          | Error error -> Error error
          | Ok value -> parse (value :: reversed) rest
        end
  in
  begin
    match parse [] assignments with
    | Error error ->
        Printf.eprintf "centl-chem: %s\n"
          (Centl_chemistry_thermo.error_message error);
        exit 1
    | Ok inputs ->
        begin
          match Centl_chemistry_thermo.calculate ~reaction_text:reaction inputs with
          | Error error ->
              Printf.eprintf "centl-chem: %s\n"
                (Centl_chemistry_thermo.error_message error);
              exit 1
          | Ok result ->
              Printf.printf "equation=%s\n" result.equation;
              Printf.printf "delta_h=%s %s\n" (Q.to_string result.value)
                result.unit;
              Printf.printf "source_class=%s\n" result.source_class;
              Printf.printf "arithmetic_class=%s\n" result.arithmetic_class;
              Printf.printf "reaction_verified=%s\n"
                (if result.verified then "true" else "false")
        end
  end

let q_text = Q.to_string

let amount_result_source_class = function
  | Centl_chemistry_amount.Unspecified -> "derived_from_unspecified"
  | Centl_chemistry_amount.Measured -> "derived_from_measured"
  | Centl_chemistry_amount.Declared_exact -> "derived_exact"

let print_amount_provenance source_class =
  Printf.printf "input_source_class=%s\n"
    (Centl_chemistry_amount.source_class_to_string source_class);
  Printf.printf "result_source_class=%s\n"
    (amount_result_source_class source_class);
  Printf.printf "arithmetic_class=exact_over_supplied_values\n"

let command_particles source_class moles_text =
  match Centl_chemistry_amount.entities_from_moles_text ~source_class moles_text with
  | Error error -> fail_amount error
  | Ok conversion ->
      print_amount_provenance conversion.source_class;
      Printf.printf "moles=%s mol\n" (q_text conversion.moles);
      Printf.printf "entities=%s\n" (q_text conversion.entities);
      Printf.printf "entities_integral=%s\n"
        (if conversion.entities_integral then "true" else "false");
      Printf.printf "entity_count_status=%s\n"
        (if conversion.entities_integral then "integral_count"
         else "nonintegral_mathematical_equivalent");
      Printf.printf "N_A=%s 1/mol\n" (q_text conversion.avogadro_value);
      Printf.printf "N_A_provenance=%s\n" conversion.avogadro_provenance

let command_moles source_class entities_text =
  match Centl_chemistry_amount.moles_from_entities_text ~source_class entities_text with
  | Error error -> fail_amount error
  | Ok conversion ->
      print_amount_provenance conversion.source_class;
      Printf.printf "entities=%s\n" (Z.to_string conversion.entity_count);
      Printf.printf "moles=%s mol\n" (q_text conversion.moles);
      Printf.printf "N_A=%s 1/mol\n" (q_text conversion.avogadro_value);
      Printf.printf "N_A_provenance=%s\n" conversion.avogadro_provenance

let command_stoich source_class reaction_text source_species source_moles
    target_species =
  match
    Centl_chemistry_amount.stoichiometric_moles_text ~source_class ~reaction_text
      ~source_species ~source_moles ~target_species
  with
  | Error error -> fail_amount error
  | Ok conversion ->
      print_amount_provenance conversion.source_class;
      Printf.printf "equation=%s\n" (render_balanced conversion.balanced);
      Printf.printf "source=%s\n" conversion.source_species;
      Printf.printf "source_coefficient=%s\n"
        (Z.to_string conversion.source_coefficient);
      Printf.printf "source_moles=%s mol\n" (q_text conversion.source_moles);
      Printf.printf "target=%s\n" conversion.target_species;
      Printf.printf "target_coefficient=%s\n"
        (Z.to_string conversion.target_coefficient);
      Printf.printf "target_moles=%s mol\n" (q_text conversion.target_moles);
      Printf.printf "reaction_verified=%s\n"
        (if conversion.balanced.verified then "true" else "false")

let render_amount_pairs pairs =
  pairs
  |> List.map (fun (species, moles) -> species ^ ":" ^ q_text moles)
  |> String.concat ","

let command_limiting source_class reaction_text assignments =
  match Centl_chemistry_limiting.solve ~source_class ~reaction_text assignments with
  | Error error -> fail_limiting error
  | Ok result ->
      print_amount_provenance result.source_class;
      Printf.printf "equation=%s\n" (render_balanced result.balanced);
      Printf.printf "extent=%s mol\n" (q_text result.extent_moles);
      Printf.printf "limiting_species=%s\n"
        (String.concat "," result.limiting_species);
      Printf.printf "co_limiting=%s\n"
        (if List.length result.limiting_species > 1 then "true" else "false");
      Printf.printf "remaining_reactants=%s mol\n"
        (render_amount_pairs result.remaining_reactants);
      Printf.printf "theoretical_products=%s mol\n"
        (render_amount_pairs result.theoretical_products);
      Printf.printf "reaction_verified=%s\n"
        (if result.balanced.verified then "true" else "false");
      Printf.printf "scope=amount_of_substance_only\n"

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
  | [ _; "particles"; "measured"; moles ] ->
      command_particles Centl_chemistry_amount.Measured moles
  | [ _; "particles"; "exact"; moles ] ->
      command_particles Centl_chemistry_amount.Declared_exact moles
  | [ _; "particles"; moles ] ->
      command_particles Centl_chemistry_amount.Unspecified moles
  | [ _; "moles"; "measured"; entities ] ->
      command_moles Centl_chemistry_amount.Measured entities
  | [ _; "moles"; "exact"; entities ] ->
      command_moles Centl_chemistry_amount.Declared_exact entities
  | [ _; "moles"; entities ] ->
      command_moles Centl_chemistry_amount.Unspecified entities
  | [ _; "stoich"; "measured"; reaction; source; amount; target ] ->
      command_stoich Centl_chemistry_amount.Measured reaction source amount target
  | [ _; "stoich"; "exact"; reaction; source; amount; target ] ->
      command_stoich Centl_chemistry_amount.Declared_exact reaction source amount
        target
  | [ _; "stoich"; reaction; source; amount; target ] ->
      command_stoich Centl_chemistry_amount.Unspecified reaction source amount target
  | _ :: "limiting" :: "measured" :: reaction :: assignments
    when assignments <> [] ->
      command_limiting Centl_chemistry_amount.Measured reaction assignments
  | _ :: "limiting" :: "exact" :: reaction :: assignments
    when assignments <> [] ->
      command_limiting Centl_chemistry_amount.Declared_exact reaction assignments
  | _ :: "limiting" :: reaction :: assignments when assignments <> [] ->
      command_limiting Centl_chemistry_amount.Unspecified reaction assignments
  | _ :: "spread" :: "measured" :: unit_symbol :: values when values <> [] ->
      command_spread Centl_chemistry_sample.Measured unit_symbol values
  | _ :: "spread" :: "exact" :: unit_symbol :: values when values <> [] ->
      command_spread Centl_chemistry_sample.Declared_exact unit_symbol values
  | _ :: "spread" :: unit_symbol :: values when values <> [] ->
      command_spread Centl_chemistry_sample.Measured unit_symbol values
  | [ _; "constant"; symbol ] -> command_constant symbol
  | [ _; "molar-mass"; formula ] -> command_molar_mass formula
  | [ _; "concentration"; moles; volume_l ] ->
      command_concentration moles volume_l
  | [ _; "dilution"; concentration; initial_volume; final_volume ] ->
      command_dilution concentration initial_volume final_volume
  | [ _; "yield"; actual; theoretical ] ->
      command_yield actual theoretical
  | [ _; "gas"; moles; temperature; volume ] ->
      command_gas moles temperature volume
  | [ _; "charge"; electron_moles ] -> command_charge electron_moles
  | _ :: "thermo" :: reaction :: assignments when assignments <> [] ->
      command_thermo reaction assignments
  | [ _; "--json"; "atoms"; formula ] ->
      command_json (Centl_chemistry_protocol.atoms_request formula)
  | [ _; "--json"; "balance"; reaction ] ->
      command_json (Centl_chemistry_protocol.balance_request reaction)
  | [ _; "--json"; "particles"; "measured"; moles ] ->
      command_json
        (Centl_chemistry_amount_protocol.entities_request
           ~source_class:Centl_chemistry_amount.Measured moles)
  | [ _; "--json"; "particles"; "exact"; moles ] ->
      command_json
        (Centl_chemistry_amount_protocol.entities_request
           ~source_class:Centl_chemistry_amount.Declared_exact moles)
  | [ _; "--json"; "particles"; moles ] ->
      command_json (Centl_chemistry_amount_protocol.entities_request moles)
  | [ _; "--json"; "moles"; "measured"; entities ] ->
      command_json
        (Centl_chemistry_amount_protocol.moles_request
           ~source_class:Centl_chemistry_amount.Measured entities)
  | [ _; "--json"; "moles"; "exact"; entities ] ->
      command_json
        (Centl_chemistry_amount_protocol.moles_request
           ~source_class:Centl_chemistry_amount.Declared_exact entities)
  | [ _; "--json"; "moles"; entities ] ->
      command_json (Centl_chemistry_amount_protocol.moles_request entities)
  | [ _; "--json"; "stoich"; "measured"; reaction; source; amount; target ] ->
      command_json
        (Centl_chemistry_amount_protocol.stoichiometry_request
           ~source_class:Centl_chemistry_amount.Measured ~reaction_text:reaction
           ~source_species:source ~source_moles:amount ~target_species:target)
  | [ _; "--json"; "stoich"; "exact"; reaction; source; amount; target ] ->
      command_json
        (Centl_chemistry_amount_protocol.stoichiometry_request
           ~source_class:Centl_chemistry_amount.Declared_exact
           ~reaction_text:reaction ~source_species:source ~source_moles:amount
           ~target_species:target)
  | [ _; "--json"; "stoich"; reaction; source; amount; target ] ->
      command_json
        (Centl_chemistry_amount_protocol.stoichiometry_request
           ~source_class:Centl_chemistry_amount.Unspecified
           ~reaction_text:reaction ~source_species:source ~source_moles:amount
           ~target_species:target)
  | _ :: "--json" :: "limiting" :: "measured" :: reaction :: assignments
    when assignments <> [] ->
      command_json
        (Centl_chemistry_limiting_protocol.request
           ~source_class:Centl_chemistry_amount.Measured ~reaction_text:reaction
           assignments)
  | _ :: "--json" :: "limiting" :: "exact" :: reaction :: assignments
    when assignments <> [] ->
      command_json
        (Centl_chemistry_limiting_protocol.request
           ~source_class:Centl_chemistry_amount.Declared_exact
           ~reaction_text:reaction assignments)
  | _ :: "--json" :: "limiting" :: reaction :: assignments
    when assignments <> [] ->
      command_json
        (Centl_chemistry_limiting_protocol.request ~reaction_text:reaction
           assignments)
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
  | [ _; "--json"; "constant"; symbol ] ->
      command_json (Centl_chemistry_constants_protocol.constant_request symbol)
  | [ _; "--json"; "molar-mass"; formula ] ->
      command_json (Centl_chemistry_data_protocol.molar_mass_request formula)
  | [ _; "--json"; "concentration"; moles; volume_l ] ->
      command_json
        (Centl_chemistry_models_protocol.concentration_request moles volume_l)
  | [ _; "--json"; "dilution"; concentration; initial_volume; final_volume ] ->
      command_json
        (Centl_chemistry_models_protocol.dilution_request concentration
           initial_volume final_volume)
  | [ _; "--json"; "yield"; actual; theoretical ] ->
      command_json
        (Centl_chemistry_models_protocol.yield_request actual theoretical)
  | _ -> usage ()
