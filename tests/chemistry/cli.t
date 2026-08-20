  $ ../../src/chemistry_main.exe atoms 'Ca(OH)2'
  Ca=1
  H=2
  O=2

  $ ../../src/chemistry_main.exe balance 'Fe + O2 -> Fe2O3'
  4 Fe + 3 O2 -> 2 Fe2O3
  Fe: 4 = 4
  O: 6 = 6
  verified=true

  $ ../../src/chemistry_main.exe balance 'C2H6 + O2 -> CO2 + H2O'
  2 C2H6 + 7 O2 -> 4 CO2 + 6 H2O
  C: 4 = 4
  H: 12 = 12
  O: 14 = 14
  verified=true

  $ ../../src/chemistry_main.exe balance 'KMnO4 + HCl -> KCl + MnCl2 + H2O + Cl2'
  2 KMnO4 + 16 HCl -> 2 KCl + 2 MnCl2 + 8 H2O + 5 Cl2
  Cl: 16 = 16
  H: 16 = 16
  K: 2 = 2
  Mn: 2 = 2
  O: 8 = 8
  verified=true

  $ ../../src/chemistry_main.exe spread g 10.01 10.04 9.98 10.03 9.99
  source_class=measured
  arithmetic_class=exact_over_reported_values
  n=5
  unit=g
  observations=1001/100,251/25,499/50,1003/100,999/100
  mean=1001/100 g
  median=1001/100 g
  minimum=499/50 g
  maximum=251/25 g
  range=3/50 g
  mad=1/50 g
  population_variance=13/25000 (g)^2
  population_sd=sqrt(13/25000) g
  sample_variance=13/20000 (g)^2
  sample_sd=sqrt(13/20000) g
  standard_error=sqrt(13/100000) g
  rsd_fraction=sqrt(1/154154)
  confidence_interval=not_computed(requires_declared_confidence_model_and_level)
  measurement_uncertainty=not_provided

  $ ../../src/chemistry_main.exe spread exact mol 1/3 2/3 | head -2
  source_class=declared_exact
  arithmetic_class=exact_over_reported_values

  $ ../../src/chemistry_main.exe --json balance 'Fe + O2 -> Fe2O3' | grep -o '"equation":"4 Fe + 3 O2 -> 2 Fe2O3"'
  "equation":"4 Fe + 3 O2 -> 2 Fe2O3"

  $ ../../src/chemistry_main.exe --json spread g 1 3 | grep -o '"source_class":"measured"'
  "source_class":"measured"

  $ ../../src/chemistry_main.exe --json spread exact mol 1/3 2/3 | grep -o '"source_class":"declared_exact"'
  "source_class":"declared_exact"

  $ ../../src/chemistry_main.exe balance 'H2 + O2 -> H2O + H2O2' 2>&1
  centl-chem: reaction balancing is underdetermined (nullspace dimension 2); no canonical result is admitted
  [1]

  $ ../../src/chemistry_main.exe atoms 'Xx2' 2>&1
  centl-chem: unknown element symbol Xx
  [1]

  $ ../../src/chemistry_main.exe spread g 1/0 2 2>&1
  centl-chem: invalid reported observation "1/0"
  [1]
