type error =
  | Empty_formula
  | Malformed_formula of string
  | Unknown_element of string
  | Invalid_coefficient of string
  | Missing_reaction_arrow
  | Empty_reaction_side
  | Duplicate_species of string
  | Impossible_balance
  | Underdetermined_balance

let error_message = function
  | Empty_formula -> "chemical formula must not be empty"
  | Malformed_formula s -> "malformed chemical formula: " ^ s
  | Unknown_element s -> "unknown element symbol: " ^ s
  | Invalid_coefficient s -> "invalid stoichiometric coefficient: " ^ s
  | Missing_reaction_arrow -> "reaction must contain exactly one -> arrow"
  | Empty_reaction_side -> "reaction side must contain at least one species"
  | Duplicate_species s -> "species appears more than once on a reaction side: " ^ s
  | Impossible_balance -> "reaction has no positive stoichiometric balance"
  | Underdetermined_balance ->
      "reaction balance is not canonical: null space is not one-dimensional"

let known_elements =
  [ "H"; "He"; "Li"; "Be"; "B"; "C"; "N"; "O"; "F"; "Ne"; "Na"; "Mg";
    "Al"; "Si"; "P"; "S"; "Cl"; "Ar"; "K"; "Ca"; "Sc"; "Ti"; "V"; "Cr";
    "Mn"; "Fe"; "Co"; "Ni"; "Cu"; "Zn"; "Ga"; "Ge"; "As"; "Se"; "Br";
    "Kr"; "Rb"; "Sr"; "Y"; "Zr"; "Nb"; "Mo"; "Tc"; "Ru"; "Rh"; "Pd";
    "Ag"; "Cd"; "In"; "Sn"; "Sb"; "Te"; "I"; "Xe"; "Cs"; "Ba"; "La";
    "Ce"; "Pr"; "Nd"; "Pm"; "Sm"; "Eu"; "Gd"; "Tb"; "Dy"; "Ho"; "Er";
    "Tm"; "Yb"; "Lu"; "Hf"; "Ta"; "W"; "Re"; "Os"; "Ir"; "Pt"; "Au";
    "Hg"; "Tl"; "Pb"; "Bi"; "Po"; "At"; "Rn"; "Fr"; "Ra"; "Ac"; "Th";
    "Pa"; "U"; "Np"; "Pu"; "Am"; "Cm"; "Bk"; "Cf"; "Es"; "Fm"; "Md";
    "No"; "Lr"; "Rf"; "Db"; "Sg"; "Bh"; "Hs"; "Mt"; "Ds"; "Rg"; "Cn";
    "Nh"; "Fl"; "Mc"; "Lv"; "Ts"; "Og" ]

let is_known symbol = List.mem symbol known_elements

let parse_formula text =
  if String.trim text = "" then Error Empty_formula
  else
    let length = String.length text in
    let parse_number index =
      if index < length && text.[index] >= '0' && text.[index] <= '9' then
        let stop = ref index in
        while !stop < length && text.[!stop] >= '0' && text.[!stop] <= '9' do
          incr stop
        done;
        try
          let value = int_of_string (String.sub text index (!stop - index)) in
          if value <= 0 then Error (Malformed_formula text)
          else Ok (value, !stop)
        with Failure _ -> Error (Malformed_formula text)
      else Ok (1, index)
    in
    let add_atom count symbol atoms =
      let previous = try List.assoc symbol atoms with Not_found -> 0 in
      (symbol, previous + count) :: List.remove_assoc symbol atoms
    in
    let rec parse_group index parenthesized =
      let rec loop index atoms =
        if index >= length then
          if parenthesized then Error (Malformed_formula text)
          else Ok (atoms, index)
        else if parenthesized && text.[index] = ')' then
          (match parse_number (index + 1) with
           | Error e -> Error e
           | Ok (multiplier, next) ->
               Ok (List.map (fun (s, n) -> (s, n * multiplier)) atoms, next))
        else if text.[index] = '(' then
          (match parse_group (index + 1) true with
           | Error e -> Error e
           | Ok (inner, next) ->
               let atoms =
                 List.fold_left
                   (fun result (s, n) -> add_atom n s result) atoms inner
               in
               loop next atoms)
        else if text.[index] = ')' then Error (Malformed_formula text)
        else if text.[index] >= 'A' && text.[index] <= 'Z' then
          let next = ref (index + 1) in
          if !next < length && text.[!next] >= 'a' && text.[!next] <= 'z' then
            incr next;
          let symbol = String.sub text index (!next - index) in
          if not (is_known symbol) then Error (Unknown_element symbol)
          else
            (match parse_number !next with
             | Error e -> Error e
             | Ok (count, after_count) ->
                 loop after_count (add_atom count symbol atoms))
        else Error (Malformed_formula text)
      in
      loop index []
    in
    match parse_group 0 false with
    | Error e -> Error e
    | Ok (atoms, index) when index <> length -> Error (Malformed_formula text)
    | Ok (atoms, _) -> Ok (List.sort compare atoms)

type species = { formula : string; atoms : (string * int) list }
type reaction = { reactants : species list; products : species list }
type evidence = { element : string; reactant_atoms : int; product_atoms : int }
type balanced = { reaction : reaction; coefficients : int list; evidence : evidence list }

let parse_species formula =
  match parse_formula formula with
  | Error e -> Error e
  | Ok atoms -> Ok { formula; atoms }

let split_on_char character text =
  let rec loop index start pieces =
    if index = String.length text then
      List.rev (String.sub text start (index - start) :: pieces)
    else if text.[index] = character then
      loop (index + 1) (index + 1)
        (String.sub text start (index - start) :: pieces)
    else loop (index + 1) start pieces
  in
  loop 0 0 []

let parse_side side =
  let terms = List.map String.trim (split_on_char '+' side) in
  if terms = [] || List.exists (( = ) "") terms then Error Empty_reaction_side
  else
    let parse_term term =
      let index = ref 0 in
      while !index < String.length term && term.[!index] >= '0'
            && term.[!index] <= '9' do
        incr index
      done;
      let coefficient =
        if !index = 0 then 1
        else
          try int_of_string (String.sub term 0 !index)
          with Failure _ -> 0
      in
      if coefficient <= 0 then Error (Invalid_coefficient term)
      else
        match
          parse_species
            (String.trim
               (String.sub term !index (String.length term - !index)))
        with
        | Error e -> Error e
        | Ok species -> Ok (coefficient, species)
    in
    let rec collect seen result = function
      | [] -> Ok (List.rev result)
      | term :: rest ->
          (match parse_term term with
           | Error e -> Error e
           | Ok (coefficient, species) ->
               if List.mem species.formula seen then
                 Error (Duplicate_species species.formula)
               else
                 collect (species.formula :: seen)
                   ((coefficient, species) :: result) rest)
    in
    collect [] [] terms

let split_arrow text =
  match split_on_char '>' text with
  | [left; right] when String.length left > 0
                       && left.[String.length left - 1] = '-' ->
      Ok (String.sub left 0 (String.length left - 1), right)
  | _ -> Error Missing_reaction_arrow

let gcd_z a b = Z.gcd a b
let lcm_z a b = Z.div (Z.mul a b) (gcd_z a b)

let balance text =
  match split_arrow text with
  | Error e -> Error e
  | Ok (left, right) ->
      (match parse_side left, parse_side right with
       | Error e, _ | _, Error e -> Error e
       | Ok reactants, Ok products ->
           let reaction =
             { reactants = List.map snd reactants;
               products = List.map snd products }
           in
           let terms = reactants @ products in
           let elements =
             List.sort_uniq compare
               (List.concat
                  (List.map (fun (_, s) -> List.map fst s.atoms) terms))
           in
           let signed_terms =
             List.map (fun (_, s) -> (1, s)) reactants
             @ List.map (fun (_, s) -> (-1, s)) products
           in
           let rows =
             List.map
               (fun element ->
                 List.map
                   (fun (sign, species) ->
                     let count =
                       try List.assoc element species.atoms
                       with Not_found -> 0
                     in
                     Q.of_int (sign * count))
                   signed_terms)
               elements
           in
           let matrix = Array.of_list (List.map Array.of_list rows) in
           let columns = List.length terms in
           let rank = ref 0 and pivots = ref [] in
           for column = 0 to columns - 1 do
             let pivot = ref None in
             for row = !rank to Array.length matrix - 1 do
               if !pivot = None
                  && not (Q.equal matrix.(row).(column) Q.zero) then
                 pivot := Some row
             done;
             match !pivot with
             | None -> ()
             | Some row ->
                 let swap = matrix.(!rank) in
                 matrix.(!rank) <- matrix.(row);
                 matrix.(row) <- swap;
                 let divisor = matrix.(!rank).(column) in
                 for j = column to columns - 1 do
                   matrix.(!rank).(j) <- Q.div matrix.(!rank).(j) divisor
                 done;
                 for i = 0 to Array.length matrix - 1 do
                   if i <> !rank then
                     let factor = matrix.(i).(column) in
                     if not (Q.equal factor Q.zero) then
                       for j = column to columns - 1 do
                         matrix.(i).(j) <-
                           Q.sub matrix.(i).(j)
                             (Q.mul factor matrix.(!rank).(j))
                       done
                 done;
                 pivots := column :: !pivots;
                 incr rank
           done;
           if columns - !rank <> 1 then
             Error (if columns = !rank then Impossible_balance
                    else Underdetermined_balance)
           else
             let pivot_columns = List.rev !pivots in
             let free =
               List.find (fun c -> not (List.mem c pivot_columns))
                 (List.init columns (fun i -> i))
             in
             let solution = Array.make columns Q.zero in
             solution.(free) <- Q.one;
             for row = !rank - 1 downto 0 do
               let column = List.nth pivot_columns row in
               let remainder = ref Q.zero in
               for j = column + 1 to columns - 1 do
                 remainder := Q.add !remainder
                   (Q.mul matrix.(row).(j) solution.(j))
               done;
               solution.(column) <- Q.neg !remainder
             done;
             let denominator =
               Array.fold_left
                 (fun result value -> lcm_z result (Q.den value))
                 Z.one solution
             in
             let integer_values =
               Array.to_list
                 (Array.map
                    (fun value ->
                      Z.to_int
                        (Z.div (Z.mul (Q.num value) denominator)
                           (Q.den value)))
                    solution)
             in
             let divisor =
               List.fold_left
                 (fun result value ->
                   gcd_z result (Z.of_int (abs value)))
                 Z.zero integer_values
               |> Z.to_int
             in
             let coefficients = List.map (fun value -> value / divisor)
                 integer_values
             in
             if List.exists (fun value -> value <= 0) coefficients then
               Error Impossible_balance
             else
               let left_coefficients, right_coefficients =
                 let rec take count values left right =
                   if count = 0 then (List.rev left, List.rev right)
                   else
                     match values with
                     | [] -> (List.rev left, List.rev right)
                     | value :: rest -> take (count - 1) rest
                         (value :: left) right
                 in
                 take (List.length reactants) coefficients [] []
               in
               let count element side coefficients =
                 List.fold_left2
                   (fun total (_, species) coefficient ->
                     total + coefficient *
                       (try List.assoc element species.atoms
                        with Not_found -> 0))
                   0 side coefficients
               in
               let evidence =
                 List.map
                   (fun element ->
                     { element;
                       reactant_atoms =
                         count element reactants left_coefficients;
                       product_atoms =
                         count element products right_coefficients })
                   elements
               in
               Ok { reaction; coefficients; evidence }