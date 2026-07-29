type error = { position : int; message : string }

type token_kind =
  | Number of (Z.t * Z.t)
  | Identifier of string
  | Plus
  | Minus
  | Star
  | Slash
  | Caret
  | Comma
  | Equals
  | Not_equals
  | Less
  | Less_equal
  | Greater
  | Greater_equal
  | Left_paren
  | Right_paren
  | End

type token = { kind : token_kind; start : int }

let is_digit character = character >= '0' && character <= '9'

let token_name = function
  | Number _ -> "a number"
  | Identifier name -> Printf.sprintf "identifier %S" name
  | Plus -> "'+'"
  | Minus -> "'-'"
  | Star -> "'*'"
  | Slash -> "'/'"
  | Caret -> "'^'"
  | Comma -> "','"
  | Equals -> "'='"
  | Not_equals -> "'!='"
  | Less -> "'<'"
  | Less_equal -> "'<='"
  | Greater -> "'>'"
  | Greater_equal -> "'>='"
  | Left_paren -> "'('"
  | Right_paren -> "')'"
  | End -> "the end of the expression"

let decimal_value source start integer_end fraction_start finish =
  let integer_digits =
    if integer_end = start then "0"
    else String.sub source start (integer_end - start)
  in
  let fraction_digits =
    match fraction_start with
    | None -> ""
    | Some offset -> String.sub source offset (finish - offset)
  in
  let numerator = Z.of_string (integer_digits ^ fraction_digits) in
  let denominator = Z.pow (Z.of_int 10) (String.length fraction_digits) in
  (numerator, denominator)

let is_identifier_start character =
  (character >= 'a' && character <= 'z')
  || (character >= 'A' && character <= 'Z')
  || character = '_'

let is_identifier_continue character =
  is_identifier_start character || is_digit character

let lex source =
  let length = String.length source in
  let rec digits offset =
    if offset < length && is_digit source.[offset] then digits (offset + 1)
    else offset
  in
  let rec identifier offset =
    if offset < length && is_identifier_continue source.[offset] then
      identifier (offset + 1)
    else offset
  in
  let rec loop offset tokens =
    if offset >= length then
      Ok (Array.of_list (List.rev ({ kind = End; start = length } :: tokens)))
    else
      match source.[offset] with
      | ' ' | '\t' | '\r' | '\n' -> loop (offset + 1) tokens
      | '+' -> loop (offset + 1) ({ kind = Plus; start = offset } :: tokens)
      | '-' -> loop (offset + 1) ({ kind = Minus; start = offset } :: tokens)
      | '*' -> loop (offset + 1) ({ kind = Star; start = offset } :: tokens)
      | '/' -> loop (offset + 1) ({ kind = Slash; start = offset } :: tokens)
      | '^' -> loop (offset + 1) ({ kind = Caret; start = offset } :: tokens)
      | ',' -> loop (offset + 1) ({ kind = Comma; start = offset } :: tokens)
      | '=' -> loop (offset + 1) ({ kind = Equals; start = offset } :: tokens)
      | '!' when offset + 1 < length && source.[offset + 1] = '=' ->
          loop (offset + 2) ({ kind = Not_equals; start = offset } :: tokens)
      | '<' when offset + 1 < length && source.[offset + 1] = '=' ->
          loop (offset + 2) ({ kind = Less_equal; start = offset } :: tokens)
      | '<' -> loop (offset + 1) ({ kind = Less; start = offset } :: tokens)
      | '>' when offset + 1 < length && source.[offset + 1] = '=' ->
          loop (offset + 2) ({ kind = Greater_equal; start = offset } :: tokens)
      | '>' -> loop (offset + 1) ({ kind = Greater; start = offset } :: tokens)
      | '(' ->
          loop (offset + 1) ({ kind = Left_paren; start = offset } :: tokens)
      | ')' ->
          loop (offset + 1) ({ kind = Right_paren; start = offset } :: tokens)
      | character when is_digit character ->
          let integer_end = digits offset in
          if integer_end < length && source.[integer_end] = '.' then
            let fraction_start = integer_end + 1 in
            let finish = digits fraction_start in
            let value =
              decimal_value source offset integer_end (Some fraction_start)
                finish
            in
            loop finish ({ kind = Number value; start = offset } :: tokens)
          else
            let value =
              decimal_value source offset integer_end None integer_end
            in
            loop integer_end ({ kind = Number value; start = offset } :: tokens)
      | '.' when offset + 1 < length && is_digit source.[offset + 1] ->
          let fraction_start = offset + 1 in
          let finish = digits fraction_start in
          let value =
            decimal_value source offset offset (Some fraction_start) finish
          in
          loop finish ({ kind = Number value; start = offset } :: tokens)
      | character when is_identifier_start character ->
          let finish = identifier (offset + 1) in
          let name = String.sub source offset (finish - offset) in
          loop finish ({ kind = Identifier name; start = offset } :: tokens)
      | character ->
          Error
            {
              position = offset;
              message = Printf.sprintf "unexpected character %C" character;
            }
  in
  loop 0 []

let parse source =
  let ( let* ) result next = Result.bind result next in
  let* tokens = lex source in
  let current index = tokens.(index) in
  let rec expression index = additive index
  and additive index =
    let* left, index = multiplicative index in
    let rec continue left index =
      match (current index).kind with
      | Plus ->
          let* right, next = multiplicative (index + 1) in
          continue (Centl_Core.Binary (Centl_Core.Add, left, right)) next
      | Minus ->
          let* right, next = multiplicative (index + 1) in
          continue (Centl_Core.Binary (Centl_Core.Subtract, left, right)) next
      | _ -> Ok (left, index)
    in
    continue left index
  and multiplicative index =
    let* left, index = unary index in
    let rec continue left index =
      match (current index).kind with
      | Star ->
          let* right, next = unary (index + 1) in
          continue (Centl_Core.Binary (Centl_Core.Multiply, left, right)) next
      | Slash ->
          let* right, next = unary (index + 1) in
          continue (Centl_Core.Binary (Centl_Core.Divide, left, right)) next
      | _ -> Ok (left, index)
    in
    continue left index
  and unary index =
    match (current index).kind with
    | Plus -> unary (index + 1)
    | Minus ->
        let* inner, next = unary (index + 1) in
        Ok (Centl_Core.Negate inner, next)
    | _ -> power index
  and power index =
    let* base, next = primary index in
    match (current next).kind with
    | Caret ->
        let* exponent, finish = integer_exponent (next + 1) in
        Ok (Centl_Core.Power (base, exponent), finish)
    | _ -> Ok (base, next)
  and integer_exponent index =
    let sign, index =
      match (current index).kind with
      | Plus -> (Z.one, index + 1)
      | Minus -> (Z.minus_one, index + 1)
      | _ -> (Z.one, index)
    in
    match (current index).kind with
    | Number (numerator, denominator) when Z.equal denominator Z.one ->
        Ok (Z.mul sign numerator, index + 1)
    | Left_paren ->
        let* exponent, next = integer_exponent (index + 1) in
        let closing = current next in
        if closing.kind = Right_paren then Ok (Z.mul sign exponent, next + 1)
        else
          Error
            {
              position = closing.start;
              message =
                Printf.sprintf "expected ')', found %s"
                  (token_name closing.kind);
            }
    | token ->
        Error
          {
            position = (current index).start;
            message =
              Printf.sprintf "expected an integer exponent, found %s"
                (token_name token);
          }
  and closing_paren index =
    let closing = current index in
    if closing.kind = Right_paren then Ok ((), index + 1)
    else
      Error
        {
          position = closing.start;
          message =
            Printf.sprintf "expected ')', found %s" (token_name closing.kind);
        }
  and comma index =
    let separator = current index in
    if separator.kind = Comma then Ok (index + 1)
    else
      Error
        {
          position = separator.start;
          message =
            Printf.sprintf "expected ',', found %s" (token_name separator.kind);
        }
  and relation index =
    match (current index).kind with
    | Equals -> Ok (Centl_Core.Equal, index + 1)
    | Not_equals -> Ok (Centl_Core.NotEqual, index + 1)
    | Less -> Ok (Centl_Core.LessThan, index + 1)
    | Less_equal -> Ok (Centl_Core.LessOrEqual, index + 1)
    | Greater -> Ok (Centl_Core.GreaterThan, index + 1)
    | Greater_equal -> Ok (Centl_Core.GreaterOrEqual, index + 1)
    | kind ->
        Error
          {
            position = (current index).start;
            message =
              Printf.sprintf "expected a mathematical relation, found %s"
                (token_name kind);
          }
  and function_call name index =
    if name = "diff" then
      let* inner, next = expression index in
      let* next = comma next in
      begin match (current next).kind with
      | Identifier variable ->
          let* (), finish = closing_paren (next + 1) in
          Ok (Centl_Core.Differentiate (inner, variable), finish)
      | kind ->
          Error
            {
              position = (current next).start;
              message =
                Printf.sprintf "expected a differentiation variable, found %s"
                  (token_name kind);
            }
      end
    else if name = "substitute" then
      let* inner, next = expression index in
      let* next = comma next in
      begin match (current next).kind with
      | Identifier variable ->
          let equals = current (next + 1) in
          if equals.kind <> Equals then
            Error
              {
                position = equals.start;
                message =
                  Printf.sprintf "expected '=', found %s"
                    (token_name equals.kind);
              }
          else
            let* replacement, next = expression (next + 2) in
            let* (), finish = closing_paren next in
            Ok (Centl_Core.Substitute (inner, variable, replacement), finish)
      | kind ->
          Error
            {
              position = (current next).start;
              message =
                Printf.sprintf "expected a substitution variable, found %s"
                  (token_name kind);
            }
      end
    else if name = "assuming" then
      let* inner, next = expression index in
      let* next = comma next in
      let* left, next = expression next in
      let* relation, next = relation next in
      let* right, next = expression next in
      let* (), finish = closing_paren next in
      Ok (Centl_Core.Assuming (inner, left, relation, right), finish)
    else if name = "simplify" || name = "expand" || name = "factor" then
      let* argument, next = expression index in
      let* (), finish = closing_paren next in
      let command =
        match name with
        | "simplify" -> Centl_Core.Simplify argument
        | "expand" -> Centl_Core.Expand argument
        | "factor" -> Centl_Core.Factor argument
        | _ -> assert false
      in
      Ok (command, finish)
    else
      let* argument, next = expression index in
      let* (), finish = closing_paren next in
      Ok (Centl_Core.Function (name, argument), finish)
  and primary index =
    let token = current index in
    match token.kind with
    | Number (numerator, denominator) ->
        Ok (Centl_Core.Literal (numerator, denominator), index + 1)
    | Identifier name ->
        if (current (index + 1)).kind = Left_paren then
          function_call name (index + 2)
        else Ok (Centl_Core.Symbol name, index + 1)
    | Left_paren ->
        let* inner, next = expression (index + 1) in
        let closing = current next in
        if closing.kind = Right_paren then Ok (inner, next + 1)
        else
          Error
            {
              position = closing.start;
              message =
                Printf.sprintf "expected ')', found %s"
                  (token_name closing.kind);
            }
    | _ ->
        Error
          {
            position = token.start;
            message =
              Printf.sprintf "expected a number or '(', found %s"
                (token_name token.kind);
          }
  in
  let* result, next = expression 0 in
  let trailing = current next in
  match trailing.kind with
  | End -> Ok result
  | _ ->
      Error
        {
          position = trailing.start;
          message =
            Printf.sprintf "expected an operator, found %s"
              (token_name trailing.kind);
        }
