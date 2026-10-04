type compound = {
  formula : string;
  composition : Centl_chem_formula.composition;
}

type reaction = {
  reactants : compound list;
  products : compound list;
}

let make_compound formula =
  match Centl_chem_formula.parse_simple formula with
  | Some composition -> Some { formula; composition }
  | None -> None

let make reactants products =
  Some { reactants; products }
