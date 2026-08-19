open Centl_multivariate_polynomial

let fail message =
  prerr_endline message;
  exit 2

let q text =
  try Q.of_string text
  with Invalid_argument _ | Failure _ -> fail ("invalid rational: " ^ text)

let split_nonempty separator text =
  if String.equal text "" then [] else String.split_on_char separator text

let parse_power text =
  match String.split_on_char '^' text with
  | [ variable; exponent ] ->
      let exponent =
        try int_of_string exponent with Failure _ -> fail ("invalid exponent: " ^ text)
      in
      (variable, exponent)
  | _ -> fail ("invalid power: " ^ text)

let parse_term text =
  match String.split_on_char '|' text with
  | [ coefficient; powers ] ->
      let powers = split_nonempty ',' powers |> List.map parse_power in
      begin match term (q coefficient) powers with
      | Ok polynomial -> polynomial
      | Error error -> fail (error_message error)
      end
  | _ -> fail ("invalid term: " ^ text)

let parse_polynomial text =
  split_nonempty ';' text
  |> List.fold_left (fun polynomial encoded -> add polynomial (parse_term encoded)) zero

let qtext value =
  Printf.sprintf "%s/%s" (Z.to_string (Q.num value)) (Z.to_string (Q.den value))

let power_text (variable, exponent) = Printf.sprintf "%s^%d" variable exponent

let render polynomial =
  bindings polynomial
  |> List.map (fun (powers, coefficient) ->
         qtext coefficient ^ "|" ^ String.concat "," (List.map power_text powers))
  |> String.concat ";"

let parse_substitution text =
  split_nonempty ',' text
  |> List.map (fun assignment ->
         match String.split_on_char '=' assignment with
         | [ variable; value ] -> (variable, q value)
         | _ -> fail ("invalid substitution: " ^ assignment))

let () =
  match Array.to_list Sys.argv with
  | [ _; "add"; left; right ] ->
      print_endline (render (add (parse_polynomial left) (parse_polynomial right)))
  | [ _; "mul"; left; right ] ->
      begin match multiply (parse_polynomial left) (parse_polynomial right) with
      | Ok result -> print_endline (render result)
      | Error error -> fail (error_message error)
      end
  | [ _; "diff"; variable; polynomial ] ->
      begin match derivative variable (parse_polynomial polynomial) with
      | Ok result -> print_endline (render result)
      | Error error -> fail (error_message error)
      end
  | [ _; "sub"; substitutions; polynomial ] ->
      begin match
        substitute_rationals (parse_substitution substitutions)
          (parse_polynomial polynomial)
      with
      | Ok result -> print_endline (render result)
      | Error error -> fail (error_message error)
      end
  | _ ->
      fail
        "usage: multivariate_probe add P Q | mul P Q | diff VAR P | sub ASSIGNMENTS P"
