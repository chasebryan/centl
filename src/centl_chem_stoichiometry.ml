type matrix = {
  elements : string list;
  columns : string list;
  values : int list list;
}

type compound = {
  name : string;
  composition : Centl_chem_formula.composition;
}

let unique_elements compounds =
  compounds
  |> List.fold_left
       (fun acc c ->
         List.fold_left
           (fun acc (element, _) ->
             if List.mem element acc then acc else element :: acc)
           acc c.composition)
       []
  |> List.sort String.compare

let coefficient_row element compounds =
  List.map
    (fun compound ->
      match List.assoc_opt element compound.composition with
      | Some n -> n
      | None -> 0)
    compounds

let build_matrix ~reactants ~products =
  let columns = List.map (fun c -> c.name) (reactants @ products) in
  let compounds = reactants @ products in
  let elements = unique_elements compounds in
  let values =
    List.map
      (fun element ->
        let left = coefficient_row element reactants in
        let right = List.map (fun x -> -x) (coefficient_row element products) in
        left @ right)
      elements
  in
  { elements; columns; values }
