type error = { position : int; message : string }

(* Source locations deliberately live beside the verified expression tree.  The
   extracted F* AST remains the semantic boundary; these spans are host-only
   diagnostic metadata and therefore cannot affect evaluation. *)
type source_span = { start : int; finish : int }

type located_expression = {
  expression : Centl_Core.expression;
  spans : (Centl_Core.expression * source_span) list;
}

module Expression_spans = Hashtbl.Make (struct
  type t = Centl_Core.expression

  let equal = ( == )
  let hash expression = Hashtbl.hash_param 16 32 expression
end)

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

let parse_located source =
  let ( let* ) result next = Result.bind result next in
  let* tokens = lex source in
  let current index = tokens.(index) in
  let spans = ref [] in
  let span_index = Expression_spans.create (Array.length tokens) in
  let locate_at start finish expression =
    let span = { start; finish = (current finish).start } in
    spans := (expression, span) :: !spans;
    Expression_spans.replace span_index expression span;
    expression
  in
  let locate start finish expression =
    locate_at (current start).start finish expression
  in
  let span_start expression =
    match Expression_spans.find_opt span_index expression with
    | Some span -> span.start
    | None -> 0
  in
  let rec expression index = additive index
  and additive index =
    let* left, index = multiplicative index in
    let rec continue left index =
      match (current index).kind with
      | Plus ->
          let* right, next = multiplicative (index + 1) in
          let combined =
            locate_at (span_start left) next
              (Centl_Core.Binary (Centl_Core.Add, left, right))
          in
          continue combined next
      | Minus ->
          let* right, next = multiplicative (index + 1) in
          let combined =
            locate_at (span_start left) next
              (Centl_Core.Binary (Centl_Core.Subtract, left, right))
          in
          continue combined next
      | _ -> Ok (left, index)
    in
    continue left index
  and multiplicative index =
    let* left, index = unary index in
    let rec continue left index =
      match (current index).kind with
      | Star ->
          let* right, next = unary (index + 1) in
          let combined =
            locate_at (span_start left) next
              (Centl_Core.Binary (Centl_Core.Multiply, left, right))
          in
          continue combined next
      | Slash ->
          let* right, next = unary (index + 1) in
          let combined =
            locate_at (span_start left) next
              (Centl_Core.Binary (Centl_Core.Divide, left, right))
          in
          continue combined next
      | _ -> Ok (left, index)
    in
    continue left index
  and unary index =
    match (current index).kind with
    | Plus -> unary (index + 1)
    | Minus ->
        let* inner, next = unary (index + 1) in
        Ok (locate index next (Centl_Core.Negate inner), next)
    | _ -> power index
  and power index =
    let* base, next = primary index in
    match (current next).kind with
    | Caret ->
        let* exponent, finish = integer_exponent (next + 1) in
        Ok
          ( locate_at (span_start base) finish
              (Centl_Core.Power (base, exponent)),
            finish )
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
  and function_call name call_start index =
    let called finish expression = locate call_start finish expression in
    if name = "solve" then
      let* left, next = expression index in
      let equals = current next in
      if equals.kind <> Equals then
        Error
          {
            position = equals.start;
            message =
              Printf.sprintf "expected '=', found %s" (token_name equals.kind);
          }
      else
        let* right, next = expression (next + 1) in
        let* next = comma next in
        begin match (current next).kind with
        | Identifier variable ->
            let* (), finish = closing_paren (next + 1) in
            Ok
              ( called finish
                  (Centl_Core.Function
                     ("solve", [ left; right; Centl_Core.Symbol variable ])),
                finish )
        | kind ->
            Error
              {
                position = (current next).start;
                message =
                  Printf.sprintf "expected a solution variable, found %s"
                    (token_name kind);
              }
        end
    else if name = "diff" then
      let* inner, next = expression index in
      let* next = comma next in
      begin match (current next).kind with
      | Identifier variable ->
          let* (), finish = closing_paren (next + 1) in
          Ok (called finish (Centl_Core.Differentiate (inner, variable)), finish)
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
            Ok
              ( called finish
                  (Centl_Core.Substitute (inner, variable, replacement)),
                finish )
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
      Ok
        ( called finish (Centl_Core.Assuming (inner, left, relation, right)),
          finish )
    else if name = "integrate" then
      let* body, next = expression index in
      let* next = comma next in
      begin match (current next).kind with
      | Identifier variable ->
          begin match (current (next + 1)).kind with
          | Right_paren ->
              let finish = next + 2 in
              Ok
                ( called finish
                    (Centl_Core.Function
                       ("integrate", [ body; Centl_Core.Symbol variable ])),
                  finish )
          | Equals ->
              let* lower, next = expression (next + 2) in
              let* next = comma next in
              let* upper, next = expression next in
              let* (), finish = closing_paren next in
              Ok
                ( called finish
                    (Centl_Core.Function
                       ( "integrate",
                         [ body; Centl_Core.Symbol variable; lower; upper ] )),
                  finish )
          | kind ->
              Error
                {
                  position = (current (next + 1)).start;
                  message =
                    Printf.sprintf "expected ')' or '=', found %s"
                      (token_name kind);
                }
          end
      | kind ->
          Error
            {
              position = (current next).start;
              message =
                Printf.sprintf "expected an integration variable, found %s"
                  (token_name kind);
            }
      end
    else if name = "sum" || name = "product" || name = "sequence" then
      let* body, next = expression index in
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
            let* lower, next = expression (next + 2) in
            let* next = comma next in
            let* upper, next = expression next in
            let* (), finish = closing_paren next in
            Ok
              ( called finish
                  (Centl_Core.Function
                     (name, [ body; Centl_Core.Symbol variable; lower; upper ])),
                finish )
      | kind ->
          Error
            {
              position = (current next).start;
              message =
                Printf.sprintf "expected an iteration variable, found %s"
                  (token_name kind);
            }
      end
    else if name = "recurrence" then
      let* initial, next = expression index in
      let* next = comma next in
      begin match (current next).kind with
      | Identifier previous ->
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
            let* step, next = expression (next + 2) in
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
                  let* lower, next = expression (next + 2) in
                  let* next = comma next in
                  let* upper, next = expression next in
                  let* (), finish = closing_paren next in
                  Ok
                    ( called finish
                        (Centl_Core.Function
                           ( "recurrence",
                             [
                               initial;
                               step;
                               Centl_Core.Symbol previous;
                               Centl_Core.Symbol variable;
                               lower;
                               upper;
                             ] )),
                      finish )
            | kind ->
                Error
                  {
                    position = (current next).start;
                    message =
                      Printf.sprintf "expected a recurrence index, found %s"
                        (token_name kind);
                  }
            end
      | kind ->
          Error
            {
              position = (current next).start;
              message =
                Printf.sprintf "expected a recurrence value name, found %s"
                  (token_name kind);
            }
      end
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
      Ok (called finish command, finish)
    else
      let rec arguments values index =
        match (current index).kind with
        | Right_paren -> Ok (List.rev values, index + 1)
        | _ ->
            let* argument, next = expression index in
            begin match (current next).kind with
            | Comma -> arguments (argument :: values) (next + 1)
            | Right_paren -> Ok (List.rev (argument :: values), next + 1)
            | kind ->
                Error
                  {
                    position = (current next).start;
                    message =
                      Printf.sprintf "expected ',' or ')', found %s"
                        (token_name kind);
                  }
            end
      in
      let* arguments, finish = arguments [] index in
      Ok (called finish (Centl_Core.Function (name, arguments)), finish)
  and primary index =
    let token = current index in
    match token.kind with
    | Number (numerator, denominator) ->
        let finish = index + 1 in
        Ok
          ( locate index finish (Centl_Core.Literal (numerator, denominator)),
            finish )
    | Identifier name ->
        if (current (index + 1)).kind = Left_paren then
          function_call name index (index + 2)
        else
          let finish = index + 1 in
          Ok (locate index finish (Centl_Core.Symbol name), finish)
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
  | End -> Ok { expression = result; spans = List.rev !spans }
  | _ ->
      Error
        {
          position = trailing.start;
          message =
            Printf.sprintf "expected an operator, found %s"
              (token_name trailing.kind);
        }

let parse source =
  Result.map (fun located -> located.expression) (parse_located source)

type statement =
  | Evaluate of Centl_Core.expression
  | Define_value of string * Centl_Core.expression
  | Define_function of string * string list * Centl_Core.expression

type located_statement = {
  statement : statement;
  statement_spans : (Centl_Core.expression * source_span) list;
  definition_name_span : source_span option;
  parameter_spans : (string * source_span) list;
  parameter_list_span : source_span option;
}

let parse_statement_located source =
  let ( let* ) result next = Result.bind result next in
  let* tokens = lex source in
  let current index = tokens.(index) in
  let parse_right_hand_side ?definition_name_span ?(parameter_spans = [])
      ?parameter_list_span offset make_statement =
    let source_length = String.length source in
    match parse_located (String.sub source offset (source_length - offset)) with
    | Ok located ->
        let statement_spans =
          List.map
            (fun (expression, (span : source_span)) ->
              ( expression,
                { start = span.start + offset; finish = span.finish + offset }
              ))
            located.spans
        in
        Ok
          {
            statement = make_statement located.expression;
            statement_spans;
            definition_name_span;
            parameter_spans;
            parameter_list_span;
          }
    | Error error -> Error { error with position = error.position + offset }
  in
  let value_definition name =
    let offset = (current 2).start in
    let definition_name_span =
      {
        start = (current 0).start;
        finish = (current 0).start + String.length name;
      }
    in
    parse_right_hand_side ~definition_name_span offset (fun expression ->
        Define_value (name, expression))
  in
  let function_definition name parameter_spans right_hand_side =
    let offset = (current right_hand_side).start in
    let definition_name_span =
      {
        start = (current 0).start;
        finish = (current 0).start + String.length name;
      }
    in
    let closing_paren = current (right_hand_side - 2) in
    let parameter_list_span =
      { start = (current 1).start; finish = closing_paren.start + 1 }
    in
    let parameters = List.map fst parameter_spans in
    parse_right_hand_side ~definition_name_span ~parameter_spans
      ~parameter_list_span offset (fun expression ->
        Define_function (name, parameters, expression))
  in
  let rec parameters index collected =
    match (current index).kind with
    | Identifier parameter ->
        let parameter_span =
          {
            start = (current index).start;
            finish = (current index).start + String.length parameter;
          }
        in
        begin match (current (index + 1)).kind with
        | Comma ->
            parameters (index + 2) ((parameter, parameter_span) :: collected)
        | Right_paren ->
            Some (List.rev ((parameter, parameter_span) :: collected), index + 2)
        | _ -> None
        end
    | _ -> None
  in
  if Array.length tokens < 2 then
    Result.map
      (fun located ->
        {
          statement = Evaluate located.expression;
          statement_spans = located.spans;
          definition_name_span = None;
          parameter_spans = [];
          parameter_list_span = None;
        })
      (parse_located source)
  else
    match ((current 0).kind, (current 1).kind) with
    | Identifier name, Equals -> value_definition name
    | Identifier name, Left_paren ->
        let header =
          match (current 2).kind with
          | Right_paren -> Some ([], 3)
          | _ -> parameters 2 []
        in
        begin match header with
        | Some (parameters, next) when (current next).kind = Equals ->
            function_definition name parameters (next + 1)
        | _ ->
            Result.map
              (fun located ->
                {
                  statement = Evaluate located.expression;
                  statement_spans = located.spans;
                  definition_name_span = None;
                  parameter_spans = [];
                  parameter_list_span = None;
                })
              (parse_located source)
        end
    | _ ->
        Result.map
          (fun located ->
            {
              statement = Evaluate located.expression;
              statement_spans = located.spans;
              definition_name_span = None;
              parameter_spans = [];
              parameter_list_span = None;
            })
          (parse_located source)

let parse_statement source =
  Result.map (fun located -> located.statement) (parse_statement_located source)
