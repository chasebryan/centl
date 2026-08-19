open Centl_real_algebraic

let fail message =
  prerr_endline message;
  exit 2

let q text =
  try Q.of_string text
  with Invalid_argument _ | Failure _ -> fail ("invalid rational: " ^ text)

let polynomial text =
  if String.equal text "" then [||]
  else
    String.split_on_char ',' text
    |> List.map (fun coefficient ->
           try Z.of_string coefficient
           with Invalid_argument _ -> fail ("invalid coefficient: " ^ coefficient))
    |> Array.of_list

let () =
  match Array.to_list Sys.argv with
  | [ _; "count"; coefficients; lower; upper ] ->
      begin match root_count (polynomial coefficients) (q lower) (q upper) with
      | Ok count -> Printf.printf "%d\n" count
      | Error error -> fail (error_message error)
      end
  | _ -> fail "usage: algebraic_probe count C0,C1,... LOWER UPPER"
