(*
   Deterministic natural-language lowering for the concrete-mathematics and
   geometry primitives that already exist in CENTL's exact core.

   This module is deliberately narrower than a general parser.  It only emits
   an exact_expression IR when the request matches a closed vocabulary and all
   extracted arguments are made of safe calculator characters.  The core still
   parses and establishes the result; this module never evaluates anything.
*)

let find_substring = Centl_sci_interaction.find_substring

let trim_terminal text =
  let text = String.trim text in
  let rec finish length =
    if length = 0 then 0
    else
      match text.[length - 1] with
      | '?' | '.' | '!' -> finish (length - 1)
      | _ -> length
  in
  let length = finish (String.length text) in
  String.sub text 0 length |> String.trim

let drop_prefix_ci prefix text =
  let lower = String.lowercase_ascii text in
  let prefix = String.lowercase_ascii prefix in
  if String.starts_with ~prefix lower then
    Some
      (String.sub text (String.length prefix)
         (String.length text - String.length prefix)
      |> String.trim)
  else None

let split_once_ci needle text =
  let lower = String.lowercase_ascii text in
  match find_substring ~needle:(String.lowercase_ascii needle) lower with
  | None -> None
  | Some index ->
      let left = String.sub text 0 index |> String.trim in
      let right =
        String.sub text
          (index + String.length needle)
          (String.length text - index - String.length needle)
        |> String.trim
      in
      Some (left, right)

let strip_articles text =
  let rec loop value =
    match drop_prefix_ci "the " value with
    | Some rest when rest <> "" -> loop rest
    | _ -> value
  in
  loop (String.trim text)

let normalize_word_separators text =
  String.map (function '-' -> ' ' | character -> character) text

let word_value = function
  | "zero" -> Some 0
  | "one" | "first" -> Some 1
  | "two" | "second" -> Some 2
  | "three" | "third" -> Some 3
  | "four" | "fourth" -> Some 4
  | "five" | "fifth" -> Some 5
  | "six" | "sixth" -> Some 6
  | "seven" | "seventh" -> Some 7
  | "eight" | "eighth" -> Some 8
  | "nine" | "ninth" -> Some 9
  | "ten" | "tenth" -> Some 10
  | "eleven" | "eleventh" -> Some 11
  | "twelve" | "twelfth" -> Some 12
  | "thirteen" | "thirteenth" -> Some 13
  | "fourteen" | "fourteenth" -> Some 14
  | "fifteen" | "fifteenth" -> Some 15
  | "sixteen" | "sixteenth" -> Some 16
  | "seventeen" | "seventeenth" -> Some 17
  | "eighteen" | "eighteenth" -> Some 18
  | "nineteen" | "nineteenth" -> Some 19
  | _ -> None

let tens_value = function
  | "twenty" | "twentieth" -> Some 20
  | "thirty" | "thirtieth" -> Some 30
  | "forty" | "fortieth" -> Some 40
  | "fifty" | "fiftieth" -> Some 50
  | "sixty" | "sixtieth" -> Some 60
  | "seventy" | "seventieth" -> Some 70
  | "eighty" | "eightieth" -> Some 80
  | "ninety" | "ninetieth" -> Some 90
  | _ -> None

let ordinal_digits text =
  let text = String.trim text in
  let length = String.length text in
  if length <= 2 then None
  else
    let suffix = String.sub text (length - 2) 2 |> String.lowercase_ascii in
    let number = String.sub text 0 (length - 2) in
    if
      List.mem suffix [ "st"; "nd"; "rd"; "th" ]
      && String.for_all (function '0' .. '9' -> true | _ -> false) number
    then Some number
    else None

let word_number text =
  let words =
    text |> String.lowercase_ascii |> normalize_word_separators
    |> String.split_on_char ' '
    |> List.filter (fun value -> value <> "" && value <> "and")
  in
  match words with
  | [ word ] ->
      begin match word_value word with
      | Some value -> Some (string_of_int value)
      | None ->
          begin match tens_value word with
          | Some value -> Some (string_of_int value)
          | None -> None
          end
      end
  | [ tens; ones ] ->
      begin match (tens_value tens, word_value ones) with
      | Some tens, Some ones when ones > 0 && ones < 10 ->
          Some (string_of_int (tens + ones))
      | _ -> None
      end
  | _ -> None

let normalize_number_like text =
  match word_number text with
  | Some value -> value
  | None ->
      begin match ordinal_digits text with Some value -> value | None -> text
      end

let scalar_char = function
  | 'a' .. 'z'
  | 'A' .. 'Z'
  | '0' .. '9'
  | '_' | ' ' | '.' | '+' | '-' | '*' | '/' | '^' | '(' | ')' ->
      true
  | _ -> false

let scalar text =
  let text = trim_terminal text |> strip_articles |> normalize_number_like in
  if
    text = ""
    || (not (String.for_all scalar_char text))
    || not
         (String.exists
            (function
              | '0' .. '9' | 'a' .. 'z' | 'A' .. 'Z' -> true | _ -> false)
            text)
  then None
  else Some text

let integer text =
  let text = trim_terminal text |> normalize_number_like in
  if
    text = ""
    || (not
          (String.for_all
             (function '0' .. '9' | '+' | '-' -> true | _ -> false)
             text))
    || not (String.exists (function '0' .. '9' -> true | _ -> false) text)
  then None
  else Some text

let numeric text =
  let text = trim_terminal text in
  if
    text = ""
    || (not
          (String.for_all
             (function
               | '0' .. '9' | '+' | '-' | '.' | '/' | 'e' | 'E' -> true
               | _ -> false)
             text))
    || not (String.exists (function '0' .. '9' -> true | _ -> false) text)
  then None
  else Some text

let native_ir expression =
  match
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

let call name args =
  match List.filter_map scalar args with
  | values when List.length values = List.length args ->
      native_ir (name ^ "(" ^ String.concat ", " values ^ ")")
  | _ -> None

let labelled_pair ~first ~second text =
  match drop_prefix_ci (first ^ " ") text with
  | None -> None
  | Some body ->
      begin match split_once_ci (" and " ^ second ^ " ") body with
      | Some (left, right) when left <> "" && right <> "" ->
          begin match (scalar left, scalar right) with
          | Some left, Some right -> Some (left, right)
          | _ -> None
          end
      | _ -> None
      end

let unary_geometry name prefixes text =
  let rec choose = function
    | [] -> None
    | prefix :: rest ->
        begin match drop_prefix_ci prefix text with
        | Some value ->
            begin match scalar value with
            | Some value -> call name [ value ]
            | None -> None
            end
        | None -> choose rest
        end
  in
  choose prefixes

let binary_geometry name prefixes text =
  let rec choose = function
    | [] -> None
    | prefix :: rest ->
        begin match drop_prefix_ci prefix text with
        | Some body ->
            let labelled =
              match labelled_pair ~first:"width" ~second:"height" body with
              | Some _ as result -> result
              | None ->
                  begin match
                    labelled_pair ~first:"base" ~second:"height" body
                  with
                  | Some _ as result -> result
                  | None -> labelled_pair ~first:"length" ~second:"width" body
                  end
            in
            begin match labelled with
            | Some (left, right) -> call name [ left; right ]
            | None ->
                begin match split_once_ci " by " body with
                | Some (left, right) ->
                    begin match (scalar left, scalar right) with
                    | Some left, Some right -> call name [ left; right ]
                    | _ -> None
                    end
                | None -> None
                end
            end
        | None -> choose rest
        end
  in
  choose prefixes

let point text =
  let text = String.trim text in
  match (String.index_opt text '(', String.index_opt text ')') with
  | Some open_index, Some close_index when close_index > open_index ->
      let body =
        String.sub text (open_index + 1) (close_index - open_index - 1)
      in
      begin match String.split_on_char ',' body |> List.map String.trim with
      | [ x; y ] when x <> "" && y <> "" ->
          begin match (scalar x, scalar y) with
          | Some x, Some y -> Some (x, y, close_index)
          | _ -> None
          end
      | _ -> None
      end
  | _ -> None

let points_call name text =
  match point text with
  | None -> None
  | Some (x1, y1, first_close) ->
      let remaining =
        String.sub text (first_close + 1) (String.length text - first_close - 1)
        |> String.trim
      in
      let remaining =
        match drop_prefix_ci "and " remaining with
        | Some value -> value
        | None ->
            begin match drop_prefix_ci "to " remaining with
            | Some value -> value
            | None -> remaining
            end
      in
      begin match point remaining with
      | Some (x2, y2, _) -> call name [ x1; y1; x2; y2 ]
      | None -> None
      end

let range text =
  let integer_pair left right =
    match (integer left, integer right) with
    | Some lower, Some upper -> Some (lower, upper)
    | _ -> None
  in
  let bound_pair body =
    match split_once_ci " to " body with
    | Some (lower, upper) -> integer_pair lower upper
    | None ->
        begin match split_once_ci " through " body with
        | Some (lower, upper) -> integer_pair lower upper
        | None ->
            begin match split_once_ci " thru " body with
            | Some (lower, upper) -> integer_pair lower upper
            | None ->
                begin match split_once_ci " and " body with
                | Some (lower, upper) -> integer_pair lower upper
                | None -> None
                end
            end
        end
  in
  match split_once_ci " from " text with
  | Some (left, bounds) ->
      begin match bound_pair bounds with
      | Some (lower, upper) -> Some (left, lower, upper)
      | None -> None
      end
  | None ->
      begin match split_once_ci " between " text with
      | Some (left, bounds) ->
          begin match bound_pair bounds with
          | Some (lower, upper) -> Some (left, lower, upper)
          | None -> None
          end
      | None -> None
      end

let sequence_expression descriptor =
  let descriptor = String.lowercase_ascii (strip_articles descriptor) in
  match descriptor with
  | "integer" | "integers" | "number" | "numbers" -> Some "k"
  | "square" | "squares" | "k squared" | "k^2" -> Some "k^2"
  | "cube" | "cubes" | "k cubed" | "k^3" -> Some "k^3"
  | "factorial" | "factorials" -> Some "factorial(k)"
  | "fibonacci numbers" | "fibonacci" -> Some "fibonacci(k)"
  | value ->
      begin match drop_prefix_ci "powers of " value with
      | Some base ->
          begin match scalar base with
          | Some base -> Some (base ^ "^k")
          | None -> None
          end
      | None -> None
      end

let finite_operation body =
  match range body with
  | None -> None
  | Some (description, lower, upper) ->
      let description = strip_articles description in
      let lower_description = String.lowercase_ascii description in
      let operation, descriptor =
        if
          String.starts_with ~prefix:"sum of " lower_description
          || String.starts_with ~prefix:"sum " lower_description
          || String.starts_with ~prefix:"add " lower_description
        then
          let value =
            match drop_prefix_ci "sum of " description with
            | Some value -> value
            | None ->
                begin match drop_prefix_ci "sum " description with
                | Some value -> value
                | None ->
                    drop_prefix_ci "add " description
                    |> Option.value ~default:""
                end
          in
          (`Sum, value)
        else if
          String.starts_with ~prefix:"product of " lower_description
          || String.starts_with ~prefix:"product " lower_description
          || String.starts_with ~prefix:"multiply " lower_description
        then
          let value =
            match drop_prefix_ci "product of " description with
            | Some value -> value
            | None ->
                begin match drop_prefix_ci "product " description with
                | Some value -> value
                | None ->
                    drop_prefix_ci "multiply " description
                    |> Option.value ~default:""
                end
          in
          (`Product, value)
        else if
          String.starts_with ~prefix:"list " lower_description
          || String.starts_with ~prefix:"show " lower_description
          || String.starts_with ~prefix:"sequence of " lower_description
        then
          let value =
            match drop_prefix_ci "list " description with
            | Some value -> value
            | None ->
                begin match drop_prefix_ci "show " description with
                | Some value -> value
                | None ->
                    drop_prefix_ci "sequence of " description
                    |> Option.value ~default:""
                end
          in
          (`Sequence, value)
        else (`Sequence, description)
      in
      begin match sequence_expression descriptor with
      | None -> None
      | Some expression ->
          let name =
            match operation with
            | `Sum -> "sum"
            | `Product -> "product"
            | `Sequence -> "sequence"
          in
          native_ir
            (Printf.sprintf "%s(%s, k = %s, %s)" name expression lower upper)
      end

let first_sequence body =
  match drop_prefix_ci "first " body with
  | None -> None
  | Some rest ->
      let descriptions =
        [
          (" squares", "k^2");
          (" cubes", "k^3");
          (" fibonacci numbers", "fibonacci(k)");
          (" integers", "k");
          (" numbers", "k");
          (" factorials", "factorial(k)");
        ]
      in
      let rec choose = function
        | [] -> None
        | (suffix, expression) :: tail ->
            if String.ends_with ~suffix (String.lowercase_ascii rest) then
              let count =
                String.sub rest 0 (String.length rest - String.length suffix)
                |> String.trim
              in
              begin match integer count with
              | Some count ->
                  native_ir
                    (Printf.sprintf "sequence(%s, k = 1, %s)" expression count)
              | None -> None
              end
            else choose tail
      in
      choose descriptions

let primitive_phrase body =
  let body = strip_articles body in
  let lower = String.lowercase_ascii body in
  let one_of prefixes name =
    let rec choose = function
      | [] -> None
      | prefix :: rest ->
          begin match drop_prefix_ci prefix body with
          | Some value ->
              begin match scalar value with
              | Some value -> call name [ value ]
              | None -> None
              end
          | None -> choose rest
          end
    in
    choose prefixes
  in
  match one_of [ "factorial of "; "factorial " ] "factorial" with
  | Some _ as result -> result
  | None ->
      begin match one_of [ "fibonacci of "; "fibonacci " ] "fibonacci" with
      | Some _ as result -> result
      | None ->
          begin match split_once_ci " factorial" body with
          | Some (value, "") ->
              begin match scalar value with
              | Some value -> call "factorial" [ value ]
              | _ -> None
              end
          | _ ->
              begin match split_once_ci " fibonacci number" body with
              | Some (value, "") ->
                  let value =
                    if
                      String.ends_with ~suffix:"st" value
                      || String.ends_with ~suffix:"nd" value
                      || String.ends_with ~suffix:"rd" value
                      || String.ends_with ~suffix:"th" value
                    then String.sub value 0 (String.length value - 2)
                    else value
                  in
                  begin match scalar value with
                  | Some value -> call "fibonacci" [ value ]
                  | None -> None
                  end
              | _ ->
                  let divisor_aliases =
                    [ "gcd of "; "gcd "; "greatest common divisor of " ]
                  in
                  let multiple_aliases =
                    [ "lcm of "; "lcm "; "least common multiple of " ]
                  in
                  let binary_of prefixes name =
                    let rec choose = function
                      | [] -> None
                      | prefix :: rest ->
                          begin match drop_prefix_ci prefix body with
                          | Some values ->
                              begin match split_once_ci " and " values with
                              | Some (left, right) ->
                                  begin match (scalar left, scalar right) with
                                  | Some left, Some right ->
                                      call name [ left; right ]
                                  | _ -> None
                                  end
                              | None -> None
                              end
                          | None -> choose rest
                          end
                    in
                    choose prefixes
                  in
                  begin match binary_of divisor_aliases "gcd" with
                  | Some _ as result -> result
                  | None ->
                      begin match binary_of multiple_aliases "lcm" with
                      | Some _ as result -> result
                      | None ->
                          begin match split_once_ci " choose " body with
                          | Some (n, k) ->
                              begin match (scalar n, scalar k) with
                              | Some n, Some k -> call "choose" [ n; k ]
                              | _ -> None
                              end
                          | None ->
                              begin match split_once_ci " from " body with
                              | Some (left, n)
                                when String.starts_with ~prefix:"choose " lower
                                ->
                                  begin match drop_prefix_ci "choose " left with
                                  | Some k ->
                                      begin match (scalar k, scalar n) with
                                      | Some k, Some n -> call "choose" [ n; k ]
                                      | _ -> None
                                      end
                                  | None -> None
                                  end
                              | _ -> None
                              end
                          end
                      end
                  end
              end
          end
      end

let geometry_phrase body =
  match
    unary_geometry "circle_area"
      [
        "area of a circle with radius ";
        "area of a circle radius ";
        "area of circle with radius ";
        "circle area with radius ";
      ]
      body
  with
  | Some _ as result -> result
  | None ->
      begin match
        unary_geometry "circumference"
          [
            "circumference of a circle with radius ";
            "circumference of a circle radius ";
            "circle circumference ";
          ]
          body
      with
      | Some _ as result -> result
      | None ->
          begin match
            unary_geometry "sphere_area"
              [
                "surface area of a sphere with radius ";
                "surface area of a sphere radius ";
                "sphere area ";
              ]
              body
          with
          | Some _ as result -> result
          | None ->
              begin match
                unary_geometry "sphere_volume"
                  [
                    "volume of a sphere with radius ";
                    "volume of a sphere radius ";
                    "sphere volume ";
                  ]
                  body
              with
              | Some _ as result -> result
              | None ->
                  begin match
                    unary_geometry "square_area"
                      [
                        "area of a square with side "; "area of a square side ";
                      ]
                      body
                  with
                  | Some _ as result -> result
                  | None ->
                      begin match
                        binary_geometry "rectangle_area"
                          [
                            "area of a rectangle with "; "area of a rectangle ";
                          ]
                          body
                      with
                      | Some _ as result -> result
                      | None ->
                          begin match
                            binary_geometry "rectangle_perimeter"
                              [
                                "perimeter of a rectangle with ";
                                "perimeter of a rectangle ";
                              ]
                              body
                          with
                          | Some _ as result -> result
                          | None ->
                              begin match
                                binary_geometry "triangle_area"
                                  [
                                    "area of a triangle with ";
                                    "area of a triangle ";
                                  ]
                                  body
                              with
                              | Some _ as result -> result
                              | None ->
                                  begin match
                                    binary_geometry "hypot"
                                      [ "hypotenuse of "; "hypotenuse " ]
                                      body
                                  with
                                  | Some _ as result -> result
                                  | None ->
                                      begin match
                                        points_call "distance"
                                          (match
                                             drop_prefix_ci "distance between "
                                               body
                                           with
                                          | Some value -> value
                                          | None ->
                                              drop_prefix_ci "distance from "
                                                body
                                              |> Option.value ~default:"")
                                      with
                                      | Some _ as result -> result
                                      | None ->
                                          points_call "slope"
                                            (match
                                               drop_prefix_ci "slope between "
                                                 body
                                             with
                                            | Some value -> value
                                            | None ->
                                                drop_prefix_ci "slope from "
                                                  body
                                                |> Option.value ~default:"")
                                      end
                                  end
                              end
                          end
                      end
                  end
              end
          end
      end

let direct_call body =
  match (String.index_opt body '(', String.rindex_opt body ')') with
  | Some open_index, Some close_index
    when open_index > 0
         && close_index = String.length body - 1
         && close_index > open_index ->
      let name =
        String.sub body 0 open_index |> String.trim |> String.lowercase_ascii
      in
      let known =
        [
          "assuming";
          "approx";
          "asin";
          "acos";
          "atan";
          "atan2";
          "abs";
          "circle_area";
          "circumference";
          "choose";
          "cos";
          "cosh";
          "cylinder_volume";
          "degrees";
          "diff";
          "distance";
          "expand";
          "factor";
          "factorial";
          "fibonacci";
          "gcd";
          "hypot";
          "integrate";
          "lcm";
          "log";
          "permutations";
          "product";
          "radians";
          "rectangle_area";
          "rectangle_perimeter";
          "recurrence";
          "sequence";
          "simplify";
          "sin";
          "sinh";
          "slope";
          "solve";
          "square_area";
          "sphere_area";
          "sphere_volume";
          "sqrt";
          "substitute";
          "sum";
          "tan";
          "tanh";
          "triangle_area";
          "trapezoid_area";
        ]
      in
      if not (List.mem name known) then None
      else
        let expression =
          String.sub body 0 (String.length body) |> String.trim
        in
        if
          String.for_all
            (function
              | 'a' .. 'z'
              | 'A' .. 'Z'
              | '0' .. '9'
              | '_' | ' ' | '.' | '+' | '-' | '*' | '/' | '^' | '(' | ')' | ','
              | '=' ->
                  true
              | _ -> false)
            expression
        then native_ir expression
        else None
  | _ -> None

let body_of_request problem =
  let cleaned = trim_terminal problem in
  let rec strip value =
    let prefixes =
      [
        "what is ";
        "calculate ";
        "compute ";
        "evaluate ";
        "find ";
        "give me ";
        "tell me ";
      ]
    in
    match
      List.find_map (fun prefix -> drop_prefix_ci prefix value) prefixes
    with
    | Some rest when rest <> "" -> strip rest
    | _ -> strip_articles value
  in
  strip cleaned

let direct_atom body =
  let lower = String.lowercase_ascii (String.trim body) in
  match lower with
  | "pi" | "e" | "tau" -> native_ir lower
  | _ ->
      begin match numeric body with Some value -> native_ir value | _ -> None
      end

let interpret problem =
  let body = body_of_request problem in
  match direct_atom body with
  | Some _ as result -> result
  | None ->
      begin match direct_call body with
      | Some _ as result -> result
      | None ->
          begin match primitive_phrase body with
          | Some _ as result -> result
          | None ->
              begin match geometry_phrase body with
              | Some _ as result -> result
              | None ->
                  begin match finite_operation body with
                  | Some _ as result -> result
                  | None -> first_sequence body
                  end
              end
          end
      end
