module Element_map = Map.Make (String)
module Element_set = Set.Make (String)

type error =
  | Empty_formula
  | Formula_too_long
  | Nesting_too_deep
  | Unexpected_character of int * char
  | Unclosed_group
  | Empty_group
  | Invalid_subscript of string
  | Unknown_element of string
  | Empty_species
  | Invalid_coefficient of string
  | Reaction_too_long
  | Missing_arrow
  | Multiple_arrows
  | Empty_reaction_side of string
  | Too_many_species
  | No_elements
  | Impossible_balance
  | Underdetermined_balance of int
  | Zero_coefficient
  | Mixed_sign_coefficients
  | Matrix_failure of string

exception Chemistry_error of error

type formula = Z.t Element_map.t

type species = {
  formula_text : string;
  atoms : formula;
  input_coefficient : Z.t;
}

type reaction = { reactants : species list; products : species list }

type conservation = {
  element : string;
  reactants : Z.t;
  products : Z.t;
  conserved : bool;
}

type balanced_reaction = {
  reaction : reaction;
  reactant_coefficients : Z.t list;
  product_coefficients : Z.t list;
  conservation : conservation list;
  verified : bool;
}

let max_formula_length = 4096
let max_reaction_length = 16384
let max_nesting_depth = 64
let max_subscript_digits = 128
let max_species = 128

let error_message = function
  | Empty_formula -> "chemical formula must not be empty"
  | Formula_too_long -> "chemical formula exceeds the bounded parser limit"
  | Nesting_too_deep -> "chemical formula nesting exceeds the parser limit"
  | Unexpected_character (position, ch) ->
      Printf.sprintf "unexpected character %C at formula index %d" ch position
  | Unclosed_group -> "chemical formula contains an unclosed parenthesized group"
  | Empty_group -> "chemical formula contains an empty parenthesized group"
  | Invalid_subscript text ->
      Printf.sprintf "invalid chemical subscript %S (must be a positive integer)" text
  | Unknown_element symbol -> Printf.sprintf "unknown element symbol %s" symbol
  | Empty_species -> "reaction contains an empty species"
  | Invalid_coefficient text ->
      Printf.sprintf "invalid stoichiometric coefficient %S" text
  | Reaction_too_long -> "reaction exceeds the bounded parser limit"
  | Missing_arrow -> "reaction must contain exactly one -> arrow"
  | Multiple_arrows -> "reaction contains more than one -> arrow"
  | Empty_reaction_side side -> Printf.sprintf "reaction %s side is empty" side
  | Too_many_species -> "reaction contains too many species for one request"
  | No_elements -> "reaction contains no chemical elements"
  | Impossible_balance ->
      "reaction has no nonzero stoichiometric nullspace in the supported model"
  | Underdetermined_balance dimension ->
      Printf.sprintf
        "reaction balancing is underdetermined (nullspace dimension %d); no canonical result is admitted"
        dimension
  | Zero_coefficient ->
      "canonical balancing would require a zero coefficient; remove the unused species"
  | Mixed_sign_coefficients ->
      "stoichiometric nullspace does not admit one all-positive coefficient orientation"
  | Matrix_failure message -> "stoichiometric matrix failure: " ^ message

let protect f = try Ok (f ()) with Chemistry_error error -> Error error
let fail error = raise (Chemistry_error error)

let element_symbols =
  [
    "H"; "He"; "Li"; "Be"; "B"; "C"; "N"; "O"; "F"; "Ne"; "Na";
    "Mg"; "Al"; "Si"; "P"; "S"; "Cl"; "Ar"; "K"; "Ca"; "Sc"; "Ti";
    "V"; "Cr"; "Mn"; "Fe"; "Co"; "Ni"; "Cu"; "Zn"; "Ga"; "Ge"; "As";
    "Se"; "Br"; "Kr"; "Rb"; "Sr"; "Y"; "Zr"; "Nb"; "Mo"; "Tc"; "Ru";
    "Rh"; "Pd"; "Ag"; "Cd"; "In"; "Sn"; "Sb"; "Te"; "I"; "Xe"; "Cs";
    "Ba"; "La"; "Ce"; "Pr"; "Nd"; "Pm"; "Sm"; "Eu"; "Gd"; "Tb"; "Dy";
    "Ho"; "Er"; "Tm"; "Yb"; "Lu"; "Hf"; "Ta"; "W"; "Re"; "Os"; "Ir";
    "Pt"; "Au"; "Hg"; "Tl"; "Pb"; "Bi"; "Po"; "At"; "Rn"; "Fr"; "Ra";
    "Ac"; "Th"; "Pa"; "U"; "Np"; "Pu"; "Am"; "Cm"; "Bk"; "Cf"; "Es";
    "Fm"; "Md"; "No"; "Lr"; "Rf"; "Db"; "Sg"; "Bh"; "Hs"; "Mt"; "Ds";
    "Rg"; "Cn"; "Nh"; "Fl"; "Mc"; "Lv"; "Ts"; "Og";
  ]

let known_elements =
  List.fold_left (fun set symbol -> Element_set.add symbol set) Element_set.empty
    element_symbols

let is_uppercase ch = ch >= 'A' && ch <= 'Z'
let is_lowercase ch = ch >= 'a' && ch <= 'z'
let is_digit ch = ch >= '0' && ch <= '9'

let add_atom atoms symbol count =
  let previous =
    match Element_map.find_opt symbol atoms with Some value -> value | None -> Z.zero
  in
  Element_map.add symbol (Z.add previous count) atoms

let merge_formula left right =
  Element_map.fold (fun symbol count acc -> add_atom acc symbol count) right left

let scale_formula multiplier atoms =
  Element_map.map (fun count -> Z.mul multiplier count) atoms

let parse_positive_integer text =
  if String.length text = 0 || String.length text > max_subscript_digits then
    fail (Invalid_subscript text);
  let value =
    try Z.of_string text with Invalid_argument _ -> fail (Invalid_subscript text)
  in
  if Z.sign value <= 0 then fail (Invalid_subscript text);
  value

let parse_count text index =
  let length = String.length text in
  let rec scan i =
    if i < length && is_digit text.[i] then scan (i + 1) else i
  in
  let stop = scan index in
  if stop = index then (Z.one, index)
  else
    let raw = String.sub text index (stop - index) in
    (parse_positive_integer raw, stop)

let parse_formula_exn input =
  let text = String.trim input in
  let length = String.length text in
  if length = 0 then fail Empty_formula;
  if length > max_formula_length then fail Formula_too_long;
  let rec sequence depth index stop_on_close =
    if depth > max_nesting_depth then fail Nesting_too_deep;
    let rec loop i atoms saw_term =
      if i >= length then
        if stop_on_close then fail Unclosed_group
        else if not saw_term then fail Empty_formula
        else (atoms, i)
      else
        match text.[i] with
        | ')' ->
            if stop_on_close then
              if saw_term then (atoms, i + 1) else fail Empty_group
            else fail (Unexpected_character (i, ')'))
        | '(' ->
            let group, after_group = sequence (depth + 1) (i + 1) true in
            let multiplier, after_count = parse_count text after_group in
            loop after_count
              (merge_formula atoms (scale_formula multiplier group))
              true
        | ch when is_uppercase ch ->
            let symbol_end =
              if i + 1 < length && is_lowercase text.[i + 1] then i + 2 else i + 1
            in
            let symbol = String.sub text i (symbol_end - i) in
            if not (Element_set.mem symbol known_elements) then fail (Unknown_element symbol);
            let count, after_count = parse_count text symbol_end in
            loop after_count (add_atom atoms symbol count) true
        | ch -> fail (Unexpected_character (i, ch))
    in
    loop index Element_map.empty false
  in
  let atoms, final_index = sequence 0 0 false in
  if final_index <> length then fail (Unexpected_character (final_index, text.[final_index]));
  atoms

let parse_formula text = protect (fun () -> parse_formula_exn text)
let formula_bindings formula = Element_map.bindings formula
let atom_count formula symbol = match Element_map.find_opt symbol formula with Some n -> n | None -> Z.zero

let parse_input_coefficient text =
  let length = String.length text in
  let rec scan i = if i < length && is_digit text.[i] then scan (i + 1) else i in
  let stop = scan 0 in
  if stop = 0 then (Z.one, text)
  else
    let raw = String.sub text 0 stop in
    let coefficient =
      try Z.of_string raw with Invalid_argument _ -> fail (Invalid_coefficient raw)
    in
    if Z.sign coefficient <= 0 then fail (Invalid_coefficient raw);
    let formula_text = String.sub text stop (length - stop) |> String.trim in
    if formula_text = "" then fail Empty_species;
    (coefficient, formula_text)

let parse_species_exn input =
  let text = String.trim input in
  if text = "" then fail Empty_species;
  let input_coefficient, formula_text = parse_input_coefficient text in
  let atoms = parse_formula_exn formula_text in
  { formula_text; atoms; input_coefficient }

let parse_species text = protect (fun () -> parse_species_exn text)

let arrow_positions text =
  let length = String.length text in
  let rec loop i reversed =
    if i + 1 >= length then List.rev reversed
    else if text.[i] = '-' && text.[i + 1] = '>' then loop (i + 2) (i :: reversed)
    else loop (i + 1) reversed
  in
  loop 0 []

let parse_side_exn name text =
  let trimmed = String.trim text in
  if trimmed = "" then fail (Empty_reaction_side name);
  let parts = String.split_on_char '+' trimmed in
  if List.length parts > max_species then fail Too_many_species;
  List.map parse_species_exn parts

let parse_reaction_exn input =
  let text = String.trim input in
  if String.length text > max_reaction_length then fail Reaction_too_long;
  match arrow_positions text with
  | [] -> fail Missing_arrow
  | [ arrow ] ->
      let left = String.sub text 0 arrow in
      let right = String.sub text (arrow + 2) (String.length text - arrow - 2) in
      let reactants = parse_side_exn "reactant" left in
      let products = parse_side_exn "product" right in
      if List.length reactants + List.length products > max_species then fail Too_many_species;
      { reactants; products }
  | _ -> fail Multiple_arrows

let parse_reaction text = protect (fun () -> parse_reaction_exn text)

let reaction_elements reaction =
  let add_species set species =
    Element_map.fold (fun symbol _ acc -> Element_set.add symbol acc) species.atoms set
  in
  let set = List.fold_left add_species Element_set.empty reaction.reactants in
  let set = List.fold_left add_species set reaction.products in
  Element_set.elements set

let stoichiometric_matrix_exn reaction =
  let elements = reaction_elements reaction in
  if elements = [] then fail No_elements;
  let q_count species element = Q.of_bigint (atom_count species.atoms element) in
  let rows =
    List.map
      (fun element ->
        List.map (fun species -> q_count species element) reaction.reactants
        @ List.map (fun species -> Q.neg (q_count species element)) reaction.products)
      elements
  in
  match Centl_matrix.of_rows rows with
  | Ok matrix -> (elements, matrix)
  | Error error -> fail (Matrix_failure (Centl_matrix.error_message error))

let stoichiometric_matrix reaction = protect (fun () -> stoichiometric_matrix_exn reaction)

let normalize_null_vector_exn vector =
  if Array.length vector = 0 then fail Impossible_balance;
  let denominator_lcm =
    Array.fold_left (fun acc value -> Z.lcm acc (Q.den value)) Z.one vector
  in
  let integers =
    Array.map
      (fun value ->
        let scaled = Q.mul value (Q.of_bigint denominator_lcm) in
        if not (Z.equal (Q.den scaled) Z.one) then
          fail (Matrix_failure "nullspace denominator normalization failed");
        Q.num scaled)
      vector
  in
  if Array.exists (fun value -> Z.equal value Z.zero) integers then fail Zero_coefficient;
  let gcd =
    Array.fold_left (fun acc value -> Z.gcd acc (Z.abs value)) Z.zero integers
  in
  let primitive = Array.map (fun value -> Z.div value gcd) integers in
  let all_positive = Array.for_all (fun value -> Z.sign value > 0) primitive in
  let all_negative = Array.for_all (fun value -> Z.sign value < 0) primitive in
  if all_positive then primitive
  else if all_negative then Array.map Z.neg primitive
  else fail Mixed_sign_coefficients

let split_at count values =
  let rec loop remaining left right =
    if remaining = 0 then (List.rev left, right)
    else
      match right with
      | [] -> (List.rev left, [])
      | value :: rest -> loop (remaining - 1) (value :: left) rest
  in
  loop count [] values

let side_total species coefficients element =
  try
    List.fold_left2
      (fun total item coefficient ->
        Z.add total (Z.mul coefficient (atom_count item.atoms element)))
      Z.zero species coefficients
  with Invalid_argument _ -> fail (Matrix_failure "coefficient/species length mismatch")

let conservation_for reaction reactant_coefficients product_coefficients =
  reaction_elements reaction
  |> List.map (fun element ->
         let reactants = side_total reaction.reactants reactant_coefficients element in
         let products = side_total reaction.products product_coefficients element in
         { element; reactants; products; conserved = Z.equal reactants products })

let balance_reaction_exn reaction =
  let _, matrix = stoichiometric_matrix_exn reaction in
  let basis = Centl_matrix.nullspace matrix in
  let vector =
    match basis with
    | [] -> fail Impossible_balance
    | [ vector ] -> vector
    | vectors -> fail (Underdetermined_balance (List.length vectors))
  in
  let coefficients = normalize_null_vector_exn vector |> Array.to_list in
  let reactant_coefficients, product_coefficients =
    split_at (List.length reaction.reactants) coefficients
  in
  let conservation =
    conservation_for reaction reactant_coefficients product_coefficients
  in
  let verified = List.for_all (fun item -> item.conserved) conservation in
  if not verified then fail (Matrix_failure "independent conservation verification failed");
  { reaction; reactant_coefficients; product_coefficients; conservation; verified }

let balance_reaction reaction = protect (fun () -> balance_reaction_exn reaction)

let balance text =
  protect (fun () ->
      let reaction = parse_reaction_exn text in
      balance_reaction_exn reaction)

let render_term coefficient species =
  if Z.equal coefficient Z.one then species.formula_text
  else Z.to_string coefficient ^ " " ^ species.formula_text

let render_side coefficients species =
  try List.map2 render_term coefficients species |> String.concat " + "
  with Invalid_argument _ -> fail (Matrix_failure "coefficient/species length mismatch")

let render_balanced balanced =
  render_side balanced.reactant_coefficients balanced.reaction.reactants
  ^ " -> "
  ^ render_side balanced.product_coefficients balanced.reaction.products
