type error = Formula_error of Centl_chemistry.error

type composition = {
  formula_text : string;
  atoms : (string * Z.t) list;
  total_atoms : Z.t;
}

let error_message = function
  | Formula_error error -> Centl_chemistry.error_message error

let analyze formula_text =
  match Centl_chemistry.parse_formula formula_text with
  | Error error -> Error (Formula_error error)
  | Ok formula ->
      let atoms = Centl_chemistry.formula_bindings formula in
      let total_atoms =
        List.fold_left
          (fun total (_, count) -> Z.add total count)
          Z.zero atoms
      in
      Ok { formula_text; atoms; total_atoms }

let atom_fraction composition element =
  match List.assoc_opt element composition.atoms with
  | None -> None
  | Some count ->
      Some
        (Q.div (Q.of_bigint count)
           (Q.of_bigint composition.total_atoms))

let exact_mass_fraction composition = atom_fraction composition
