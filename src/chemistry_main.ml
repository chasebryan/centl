open Centl_chemistry

let usage () =
  Printf.eprintf
    "Usage:\n\
    \  centl-chem atoms FORMULA\n\
    \  centl-chem balance 'REACTION'\n\
    \  centl-chem --json atoms FORMULA\n\
    \  centl-chem --json balance 'REACTION'\n";
  exit 2

let fail error =
  Printf.eprintf "centl-chem: %s\n" (error_message error);
  exit 1

let command_atoms formula_text =
  match parse_formula formula_text with
  | Error error -> fail error
  | Ok formula ->
      formula_bindings formula
      |> List.iter (fun (element, count) ->
             Printf.printf "%s=%s\n" element (Z.to_string count))

let command_balance reaction_text =
  match balance reaction_text with
  | Error error -> fail error
  | Ok balanced ->
      Printf.printf "%s\n" (render_balanced balanced);
      List.iter
        (fun item ->
          Printf.printf "%s: %s = %s\n" item.element
            (Z.to_string item.reactants) (Z.to_string item.products))
        balanced.conservation;
      Printf.printf "verified=%s\n" (if balanced.verified then "true" else "false")

let command_json request =
  match request with
  | Ok json -> print_endline (Yojson.Safe.to_string json)
  | Error json ->
      print_endline (Yojson.Safe.to_string json);
      exit 1

let () =
  match Array.to_list Sys.argv with
  | [ _; "atoms"; formula ] -> command_atoms formula
  | [ _; "balance"; reaction ] -> command_balance reaction
  | [ _; "--json"; "atoms"; formula ] ->
      command_json (Centl_chemistry_protocol.atoms_request formula)
  | [ _; "--json"; "balance"; reaction ] ->
      command_json (Centl_chemistry_protocol.balance_request reaction)
  | _ -> usage ()
