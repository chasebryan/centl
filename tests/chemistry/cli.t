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

  $ ../../src/chemistry_main.exe --json balance 'Fe + O2 -> Fe2O3' | grep -o '"equation":"4 Fe + 3 O2 -> 2 Fe2O3"'
  "equation":"4 Fe + 3 O2 -> 2 Fe2O3"

  $ ../../src/chemistry_main.exe balance 'H2 + O2 -> H2O + H2O2' 2>&1
  centl-chem: reaction balancing is underdetermined (nullspace dimension 2); no canonical result is admitted
  [1]

  $ ../../src/chemistry_main.exe atoms 'Xx2' 2>&1
  centl-chem: unknown element symbol Xx
  [1]
