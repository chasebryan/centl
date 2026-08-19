open Centl_matrix

let fail message =
  prerr_endline message;
  exit 2

let q text =
  try Q.of_string text
  with Invalid_argument _ | Failure _ -> fail ("invalid rational: " ^ text)

let parse_matrix text =
  let rows =
    String.split_on_char ';' text
    |> List.map (fun row -> String.split_on_char ',' row |> List.map q)
  in
  match of_rows rows with
  | Ok value -> value
  | Error error -> fail (error_message error)

let qtext value =
  Printf.sprintf "%s/%s" (Z.to_string (Q.num value)) (Z.to_string (Q.den value))

let matrix_text matrix =
  to_rows matrix
  |> List.map (fun row -> String.concat "," (List.map qtext row))
  |> String.concat ";"

let () =
  match Array.to_list Sys.argv with
  | [ _; "det"; matrix_text_input ] ->
      begin match determinant (parse_matrix matrix_text_input) with
      | Ok value -> print_endline (qtext value)
      | Error error -> fail (error_message error)
      end
  | [ _; "inverse"; matrix_text_input ] ->
      begin match inverse (parse_matrix matrix_text_input) with
      | Ok value -> print_endline (matrix_text value)
      | Error error -> fail (error_message error)
      end
  | [ _; "mul"; left; right ] ->
      begin match multiply (parse_matrix left) (parse_matrix right) with
      | Ok value -> print_endline (matrix_text value)
      | Error error -> fail (error_message error)
      end
  | _ -> fail "usage: matrix_probe det M | inverse M | mul A B"
