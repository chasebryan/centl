type error = { position : int; message : string }

type token_kind =
  | Number of (Z.t * Z.t)
  | Plus
  | Minus
  | Star
  | Slash
  | Left_paren
  | Right_paren
  | End

type token = { kind : token_kind; start : int }

let is_digit character = character >= '0' && character <= '9'

let token_name = function
  | Number _ -> "a number"
  | Plus -> "'+'"
  | Minus -> "'-'"
  | Star -> "'*'"
  | Slash -> "'/'"
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

let lex source =
  let length = String.length source in
  let rec digits offset =
    if offset < length && is_digit source.[offset] then digits (offset + 1)
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
    | _ -> primary index
  and primary index =
    let token = current index in
    match token.kind with
    | Number (numerator, denominator) ->
        Ok (Centl_Core.Literal (numerator, denominator), index + 1)
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
