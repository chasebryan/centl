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

let replace_all ~needle ~replacement text =
  if needle = "" then text
  else
    let buffer = Buffer.create (String.length text) in
    let needle_length = String.length needle in
    let rec loop offset =
      if offset >= String.length text then ()
      else
        match
          find_substring ~needle
            (String.sub text offset (String.length text - offset))
        with
        | None ->
            Buffer.add_substring buffer text offset (String.length text - offset)
        | Some relative ->
            let index = offset + relative in
            Buffer.add_substring buffer text offset (index - offset);
            Buffer.add_string buffer replacement;
            loop (index + needle_length)
    in
    loop 0;
    Buffer.contents buffer

let drop_prefix_ci prefix text =
  let lower = String.lowercase_ascii text in
  let prefix = String.lowercase_ascii prefix in
  if String.starts_with ~prefix lower then
    Some
      (String.sub text (String.length prefix)
         (String.length text - String.length prefix)
      |> String.trim)
  else None

let is_numeric_char = function
  | '0' .. '9' | '+' | '-' | '.' | '/' | 'e' | 'E' -> true
  | _ -> false

let numeric_token text =
  String.length text > 0
  && String.for_all is_numeric_char text
  && String.exists (function '0' .. '9' -> true | _ -> false) text

let arithmetic_char = function
  | '0' .. '9'
  | ' ' | '\t' | '.' | '+' | '-' | '*' | '/' | '^' | '(' | ')' | 'e' | 'E' ->
      true
  | _ -> false

let contains_operator text =
  String.exists
    (function '+' | '-' | '*' | '/' | '^' -> true | _ -> false)
    text

let normalize_arithmetic text =
  String.lowercase_ascii text
  |> replace_all ~needle:" multiplied by " ~replacement:" * "
  |> replace_all ~needle:" divided by " ~replacement:" / "
  |> replace_all ~needle:" plus " ~replacement:" + "
  |> replace_all ~needle:" minus " ~replacement:" - "
  |> replace_all ~needle:" times " ~replacement:" * "
  |> String.trim

let exact_expression problem =
  let cleaned = trim_terminal problem in
  let candidate =
    match drop_prefix_ci "what is " cleaned with
    | Some value -> Some value
    | None ->
        begin match drop_prefix_ci "calculate " cleaned with
        | Some value -> Some value
        | None ->
            begin match drop_prefix_ci "compute " cleaned with
            | Some value -> Some value
            | None ->
                begin match drop_prefix_ci "evaluate " cleaned with
                | Some value -> Some value
                | None ->
                    if String.for_all arithmetic_char cleaned then Some cleaned
                    else None
                end
            end
        end
  in
  match candidate with
  | None -> None
  | Some candidate ->
      let expression = normalize_arithmetic candidate in
      if
        expression = ""
        || (not (String.for_all arithmetic_char expression))
        || not (contains_operator expression)
      then None
      else
        begin match
          Centl_sci_ir.of_json
            (`Assoc
               [
                 ("schema_version", `Int 1);
                 ("domain", `String "mathematics");
                 ("problem_class", `String "exact_expression");
                 ("operation", `String "compute");
                 ("assumptions", `List []);
                 ("expression", `String expression);
               ])
        with
        | Ok ir -> Some ir
        | Error _ -> None
        end

let canonical_unit text =
  match String.lowercase_ascii (String.trim text) with
  | "m" | "meter" | "meters" | "metre" | "metres" -> Some "m"
  | "cm" | "centimeter" | "centimeters" | "centimetre" | "centimetres" ->
      Some "cm"
  | "mm" | "millimeter" | "millimeters" | "millimetre" | "millimetres" ->
      Some "mm"
  | "km" | "kilometer" | "kilometers" | "kilometre" | "kilometres" -> Some "km"
  | "s" | "second" | "seconds" -> Some "s"
  | "ms" | "millisecond" | "milliseconds" -> Some "ms"
  | "min" | "minute" | "minutes" -> Some "min"
  | "h" | "hour" | "hours" -> Some "h"
  | "kg" | "kilogram" | "kilograms" -> Some "kg"
  | "g" | "gram" | "grams" -> Some "g"
  | "a" | "ampere" | "amperes" -> Some "A"
  | "k" | "kelvin" | "kelvins" -> Some "K"
  | "mol" | "mole" | "moles" -> Some "mol"
  | "cd" | "candela" | "candelas" -> Some "cd"
  | "m/s" | "meter per second" | "meters per second" | "metre per second"
  | "metres per second" ->
      Some "m/s"
  | "m/s^2" | "meter per second squared" | "meters per second squared"
  | "metre per second squared" | "metres per second squared" ->
      Some "m/s^2"
  | "n" | "newton" | "newtons" -> Some "N"
  | "j" | "joule" | "joules" -> Some "J"
  | "pa" | "pascal" | "pascals" -> Some "Pa"
  | "hz" | "hertz" -> Some "Hz"
  | "c" | "coulomb" | "coulombs" -> Some "C"
  | "w" | "watt" | "watts" -> Some "W"
  | "v" | "volt" | "volts" -> Some "V"
  | _ -> None

let unit_conversion problem =
  let cleaned = trim_terminal problem in
  match drop_prefix_ci "convert " cleaned with
  | None -> None
  | Some body ->
      let lower = String.lowercase_ascii body in
      begin match find_substring ~needle:" to " lower with
      | None -> None
      | Some to_index ->
          let source = String.sub body 0 to_index |> String.trim in
          let target =
            String.sub body (to_index + 4) (String.length body - to_index - 4)
            |> String.trim
          in
          begin match find_substring ~needle:" " source with
          | None -> None
          | Some space ->
              let value = String.sub source 0 space |> String.trim in
              let from_text =
                String.sub source (space + 1) (String.length source - space - 1)
                |> String.trim
              in
              begin match (canonical_unit from_text, canonical_unit target) with
              | Some from_unit, Some to_unit when numeric_token value ->
                  begin match
                    Centl_sci_ir.of_json
                      (`Assoc
                         [
                           ("schema_version", `Int 1);
                           ("domain", `String "physics");
                           ("problem_class", `String "unit_conversion");
                           ("operation", `String "convert");
                           ("assumptions", `List []);
                           ("value", `String value);
                           ("from_unit", `String from_unit);
                           ("to_unit", `String to_unit);
                         ])
                  with
                  | Ok ir -> Some ir
                  | Error _ -> None
                  end
              | _ -> None
              end
          end
      end

let equation_char = function
  | 'a' .. 'z'
  | 'A' .. 'Z'
  | '0' .. '9'
  | '_' | ' ' | '\t' | '.' | '+' | '-' | '*' | '/' | '^' | '(' | ')' ->
      true
  | _ -> false

let polynomial_equation problem =
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
            |> String.trim
          in
          begin match find_substring ~needle:"=" equation with
          | None -> None
          | Some equal_index ->
              let left = String.sub equation 0 equal_index |> String.trim in
              let right =
                String.sub equation (equal_index + 1)
                  (String.length equation - equal_index - 1)
                |> String.trim
              in
              if
                left = "" || right = "" || variable = ""
                || (not (String.for_all equation_char left))
                || not (String.for_all equation_char right)
              then None
              else
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
          end
      end

let interpret problem =
  match unit_conversion problem with
  | Some _ as result -> result
  | None ->
      begin match polynomial_equation problem with
      | Some _ as result -> result
      | None ->
          begin match Centl_sci_spoken_poly.interpret problem with
          | Some _ as result -> result
          | None -> exact_expression problem
          end
      end
