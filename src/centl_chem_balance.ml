type result =
  | Balanced of int list
  | Unbalanced of string

let verify_conservation matrix coefficients =
  let row_sum row =
    List.fold_left2
      (fun acc value coefficient -> acc + (value * coefficient))
      0 row coefficients
  in
  List.for_all (fun row -> row_sum row = 0) matrix.Centl_chem_stoichiometry.values

let balance matrix =
  if List.length matrix.Centl_chem_stoichiometry.columns = 0 then
    Unbalanced "empty reaction"
  else
    Unbalanced "exact nullspace solver pending"
