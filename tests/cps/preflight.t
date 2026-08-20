  $ ../../src/cps_main.exe preflight measured O2=1 H2=3
  input_source_class=measured
  result_source_class=derived_from_measured
  arithmetic_class=exact_over_supplied_values
  composition_validated=true
  species_count=2
  species=H2[H:2]:3,O2[O:2]:1 mol
  total_species_moles=4 mol
  elemental_inventory=H:6,O:2 mol-of-atoms
  N_A=602214076000000000000000 1/mol
  N_A_provenance=SI defining constant
  reaction_model=not_provided
  thermodynamics=not_evaluated
  kinetics=not_evaluated
  phase_pressure=not_evaluated
  safety_evidence=not_evaluated
  measurement_uncertainty=not_provided
  prediction=not_performed

  $ ../../src/cps_main.exe preflight exact H2=3 O2=1 | head -3
  input_source_class=declared_exact
  result_source_class=derived_exact
  arithmetic_class=exact_over_supplied_values

  $ ../../src/cps_main.exe --json preflight measured O2=1 H2=3 | grep -o '"prediction":{"status":"not_performed"'
  "prediction":{"status":"not_performed"

  $ ../../src/cps_main.exe --json preflight measured O2=1 H2=3 | grep -o '"composition_key":"H:2"'
  "composition_key":"H:2"

  $ ../../src/cps_main.exe preflight H2O=1 OH2=1 2>&1
  centl-cps: CPS composition contains duplicate species OH2 under the current formula model
  [1]

  $ ../../src/cps_main.exe preflight H2=-1 2>&1
  centl-cps: invalid CPS amount for H2: amount of substance must be non-negative
  [1]
