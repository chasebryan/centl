let trim_terminal text =
  let text = String.trim text in
  let rec finish length =
    if length = 0 then 0
    else
      match text.[length - 1] with
      | '?' | '.' -> finish (length - 1)
      | _ -> length
  in
  let length = finish (String.length text) in
  String.sub text 0 length |> String.trim

let find_substring ~needle text =
  let needle_length = String.length needle in
  let text_length = String.length text in
  let rec loop index =
    if needle_length = 0 then Some index
    else if index + needle_length > text_length then None
    else if String.sub text index needle_length = needle then Some index
    else loop (index + 1)
  in
  loop 0

let rfind_substring ~needle text =
  let needle_length = String.length needle in
  let rec loop index =
    if needle_length = 0 then Some index
    else if index < 0 then None
    else if String.sub text index needle_length = needle then Some index
    else loop (index - 1)
  in
  loop (String.length text - needle_length)

let drop_prefix_ci prefix text =
  let lower = String.lowercase_ascii text in
  let prefix_lower = String.lowercase_ascii prefix in
  if String.starts_with ~prefix:prefix_lower lower then
    Some
      (String.sub text (String.length prefix) (String.length text - String.length prefix)
      |> String.trim)
  else None

let valid_identifier text =
  let is_first = function
    | 'a' .. 'z' | 'A' .. 'Z' | '_' -> true
    | _ -> false
  in
  let is_rest = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
    | _ -> false
  in
  let rec rest index =
    if index = String.length text then true
    else if is_rest text.[index] then rest (index + 1)
    else false
  in
  String.length text > 0 && is_first text.[0] && rest 1

let numeric_token text =
  let valid = function
    | '0' .. '9' | '.' | '/' -> true
    | _ -> false
  in
  String.length text > 0
  && String.for_all valid text
  && String.exists (function '0' .. '9' -> true | _ -> false) text

let canonical_number = function "zero" -> Some "0" | token when numeric_token token -> Some token | _ -> None

let words text =
  String.lowercase_ascii text |> String.split_on_char ' '
  |> List.filter (fun token -> token <> "")

let parse_term ~variable = function
  | token :: "squared" :: rest when token = variable -> Some (variable ^ "^2", rest)
  | token :: rest when token = variable -> Some (variable, rest)
  | coefficient :: token :: "squared" :: rest
    when token = variable && Option.is_some (canonical_number coefficient) ->
      let coefficient = Option.get (canonical_number coefficient) in
      Some (coefficient ^ "*" ^ variable ^ "^2", rest)
  | coefficient :: token :: rest
    when token = variable && Option.is_some (canonical_number coefficient) ->
      let coefficient = Option.get (canonical_number coefficient) in
      Some (coefficient ^ "*" ^ variable, rest)
  | coefficient :: "times" :: token :: "squared" :: rest
    when token = variable && Option.is_some (canonical_number coefficient) ->
      let coefficient = Option.get (canonical_number coefficient) in
      Some (coefficient ^ "*" ^ variable ^ "^2", rest)
  | coefficient :: "times" :: token :: rest
    when token = variable && Option.is_some (canonical_number coefficient) ->
      let coefficient = Option.get (canonical_number coefficient) in
      Some (coefficient ^ "*" ^ variable, rest)
  | token :: rest ->
      begin match canonical_number token with
      | Some number -> Some (number, rest)
      | None -> None
      end
  | [] -> None

let parse_expression ~variable text =
  let rec loop acc tokens =
    match tokens with
    | [] -> Some (String.concat " " (List.rev acc))
    | ("plus" | "minus" as operator) :: rest ->
        begin match parse_term ~variable rest with
        | Some (term, remaining) ->
            let symbol = if operator = "plus" then "+" else "-" in
            loop (term :: symbol :: acc) remaining
        | None -> None
        end
    | _ -> None
  in
  match words text with
  | "minus" :: rest ->
      begin match parse_term ~variable rest with
      | Some (term, remaining) -> loop [ "-" ^ term ] remaining
      | None -> None
      end
  | tokens ->
      begin match parse_term ~variable tokens with
      | Some (term, remaining) -> loop [ term ] remaining
      | None -> None
      end

let interpret problem =
  let cleaned = trim_terminal problem in
  match drop_prefix_ci "solve " cleaned with
  | None -> None
  | Some body ->
      let lower = String.lowercase_ascii body in
      begin match rfind_substring ~needle:" for " lower with
      | None -> None
      | Some for_index ->
          let equation = String.sub body 0 for_index |> String.trim in
          let variable =
            String.sub body (for_index + 5) (String.length body - for_index - 5)
            |> String.trim |> String.lowercase_ascii
          in
          if not (valid_identifier variable) then None
          else
            let equation_lower = String.lowercase_ascii equation in
            begin match find_substring ~needle:" equals " equation_lower with
            | None -> None
            | Some equal_index ->
                let after_equal = equal_index + String.length " equals " in
                let right_length = String.length equation - after_equal in
                let left = String.sub equation 0 equal_index |> String.trim in
                let right = String.sub equation after_equal right_length |> String.trim in
                let remaining_right = String.lowercase_ascii right in
                if Option.is_some (find_substring ~needle:" equals " remaining_right) then None
                else
                  begin match
                    (parse_expression ~variable left, parse_expression ~variable right)
                  with
                  | Some left, Some right ->
                      begin match
                        Centl_sci_ir.of_json
                          (`Assoc
                             [
                               ("schema_version", `Int 1);
                               ("domain", `String "mathematics");
                               ("problem_class", `String "polynomial_equation");
                               ("operation", `String "solve");
                               ("assumptions", `List []);
                               ("left", `String left);
                               ("relation", `String "equal");
                               ("right", `String right);
                               ("variable", `String variable);
                             ])
                      with
                      | Ok ir -> Some ir
                      | Error _ -> None
                      end
                  | _ -> None
                  end
            end
      end
