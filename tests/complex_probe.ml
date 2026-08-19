open Centl_complex_rational

let fail message =
  prerr_endline message;
  exit 2

let q text =
  try Q.of_string text
  with Invalid_argument _ | Failure _ -> fail ("invalid rational: " ^ text)

let print_component value =
  Printf.printf "%s/%s" (Z.to_string (Q.num value)) (Z.to_string (Q.den value))

let print_complex value =
  print_component value.real;
  print_char '\t';
  print_component value.imaginary;
  print_newline ()

let binary operation a b =
  match operation with
  | "add" -> Ok (add a b)
  | "sub" -> Ok (sub a b)
  | "mul" -> Ok (mul a b)
  | "div" -> div a b
  | _ -> fail ("unknown operation: " ^ operation)

let () =
  match Array.to_list Sys.argv with
  | [ _; operation; ar; ai; br; bi ] ->
      let a = make (q ar) (q ai) in
      let b = make (q br) (q bi) in
      begin match binary operation a b with
      | Ok value -> print_complex value
      | Error error -> fail (error_message error)
      end
  | [ _; "pow"; ar; ai; exponent ] ->
      let a = make (q ar) (q ai) in
      let exponent =
        try Z.of_string exponent with Invalid_argument _ -> fail "invalid exponent"
      in
      begin match pow a exponent with
      | Ok value -> print_complex value
      | Error error -> fail (error_message error)
      end
  | _ ->
      fail
        "usage: complex_probe (add|sub|mul|div) AR AI BR BI | complex_probe pow AR AI EXP"
