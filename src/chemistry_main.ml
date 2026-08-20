let print_error error =
  prerr_endline ("centl-chem: " ^ Centl_chemistry.error_message error)

let () =
  match Array.to_list Sys.argv with
  | [_; "atoms"; formula] ->
      (match Centl_chemistry.parse_formula formula with
       | Error error -> print_error error; exit 2
       | Ok atoms ->
           List.iter (fun (symbol, count) ->
             Printf.printf "%s=%d\n" symbol count) atoms)
  | [_; "balance"; reaction] ->
      (match Centl_chemistry.balance reaction with
       | Error error -> print_error error; exit 2
       | Ok balanced ->
           let reactants = balanced.reaction.reactants in
           let products = balanced.reaction.products in
           let rec render species coefficients =
             match species, coefficients with
             | [], [] -> []
             | s :: species, c :: coefficients ->
                 Printf.sprintf "%d %s" c s.formula
                 :: render species coefficients
             | _ -> []
           in
           let rec split count values left =
             if count = 0 then (List.rev left, values)
             else match values with
               | [] -> (List.rev left, [])
               | value :: rest -> split (count - 1) rest (value :: left)
           in
           let left, right =
             split (List.length reactants) balanced.coefficients []
           in
           Printf.printf "%s -> %s\n"
             (String.concat " + " (render reactants left))
             (String.concat " + " (render products right));
           List.iter (fun evidence ->
             Printf.printf "conserve %s: %d=%d\n"
               evidence.element
               evidence.reactant_atoms evidence.product_atoms)
             balanced.evidence)
  | _ ->
      prerr_endline "usage: centl-chem atoms FORMULA | balance 'REACTION'";
      exit 2