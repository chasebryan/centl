type provenance =
  | Exact_defined
  | Measured_interval
  | Unknown

type atomic_mass = {
  element : string;
  value : Q.t;
  provenance : provenance;
  source : string;
}

type result = {
  formula_text : string;
  molar_mass : Q.t;
  provenance : provenance;
  components : (string * Z.t * atomic_mass) list;
}

type error =
  | Formula_error of Centl_chemistry.error
  | Unknown_element of string

let error_message = function
  | Formula_error error -> Centl_chemistry.error_message error
  | Unknown_element element ->
      Printf.sprintf "no admissible atomic mass data for element %s" element

(* Deliberately small exact seed. The data model separates arithmetic from
   physical provenance. Expansion should add a curated atomic-weight source,
   not silently turn measured values into exact constants. *)
let atomic_mass_table =
  [
    ("H", { element = "H"; value = Q.of_int 1008; provenance = Measured_interval; source = "standard_atomic_weight" });
    ("C", { element = "C"; value = Q.of_int 12011; provenance = Measured_interval; source = "standard_atomic_weight" });
    ("O", { element = "O"; value = Q.of_int 15999; provenance = Measured_interval; source = "standard_atomic_weight" });
  ]

let find_mass element =
  match List.assoc_opt element atomic_mass_table with
  | Some value -> Ok value
  | None -> Error (Unknown_element element)

let calculate formula_text =
  match Centl_chemistry.parse_formula formula_text with
  | Error error -> Error (Formula_error error)
  | Ok formula ->
      let atoms = Centl_chemistry.formula_bindings formula in
      let rec collect acc provenance = function
        | [] ->
            let total =
              List.fold_left
                (fun sum (_, count, mass) ->
                  Q.add sum (Q.mul (Q.of_bigint count) mass.value))
                Q.zero acc
            in
            Ok { formula_text; molar_mass = total; provenance; components = List.rev acc }
        | (element, count) :: rest ->
            begin
              match find_mass element with
              | Error error -> Error error
              | Ok mass -> collect ((element, count, mass) :: acc) Measured_interval rest
            end
      in
      collect [] Exact_defined atoms
