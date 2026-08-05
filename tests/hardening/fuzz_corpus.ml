let fail category input message =
  let shown =
    let limit = min 48 (String.length input) in
    let buffer = Buffer.create ((limit * 2) + 3) in
    for index = 0 to limit - 1 do
      Buffer.add_string buffer (Printf.sprintf "%02x" (Char.code input.[index]))
    done;
    if limit < String.length input then Buffer.add_string buffer "...";
    Buffer.contents buffer
  in
  failwith
    (Printf.sprintf "%s corpus failure for %s: %s" category shown message)

let read_lines path =
  let channel = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr channel)
    (fun () ->
      let rec loop lines =
        match input_line channel with
        | line ->
            let length = String.length line in
            let line =
              if length > 0 && line.[length - 1] = '\r' then
                String.sub line 0 (length - 1)
              else line
            in
            if line = "" || line.[0] = '#' then loop lines
            else loop (line :: lines)
        | exception End_of_file -> List.rev lines
      in
      loop [])

let corpus_root =
  Option.value (Sys.getenv_opt "CENTL_CORPUS_ROOT") ~default:"tests/corpus"

let corpus name = read_lines (Filename.concat corpus_root name)

let read_file path =
  let channel = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr channel)
    (fun () -> really_input_string channel (in_channel_length channel))

let replace source index byte =
  let result = Bytes.of_string source in
  Bytes.set result index (Char.chr byte);
  Bytes.unsafe_to_string result

let insert source index byte =
  String.sub source 0 index
  ^ String.make 1 (Char.chr byte)
  ^ String.sub source index (String.length source - index)

let delete source index =
  String.sub source 0 index
  ^ String.sub source (index + 1) (String.length source - index - 1)

let reverse source =
  String.init (String.length source) (fun index ->
      source.[String.length source - index - 1])

let mutations seed =
  let seen = Hashtbl.create 256 in
  let values = ref [] in
  let add value =
    if String.length value <= 32_768 && not (Hashtbl.mem seen value) then (
      Hashtbl.add seen value ();
      values := value :: !values)
  in
  let length = String.length seed in
  let positions =
    List.sort_uniq Int.compare
      [
        0;
        min 1 length;
        length / 4;
        length / 2;
        3 * length / 4;
        max 0 (length - 1);
        length;
      ]
  in
  let boundary_bytes =
    [ 0; 10; 32; 34; 40; 41; 43; 44; 47; 61; 92; 123; 125; 127; 255 ]
  in
  add seed;
  add (reverse seed);
  add (seed ^ seed);
  List.iter
    (fun position ->
      add (String.sub seed 0 position);
      if position < length then add (delete seed position);
      List.iter
        (fun byte ->
          add (insert seed position byte);
          if position < length then add (replace seed position byte))
        boundary_bytes)
    positions;
  List.rev !values

let json_round_trips value =
  try Yojson.Safe.from_string (Yojson.Safe.to_string value) = value
  with Yojson.Json_error _ -> false

let protocol_response = function
  | `Assoc fields as response ->
      List.assoc_opt "version" fields = Some (`Int 1)
      && Option.is_some (List.assoc_opt "ok" fields)
      && Option.is_some (List.assoc_opt "session" fields)
      && json_round_trips response
  | _ -> false

let parser_case input =
  let check_error surface (error : Centl_parser.error) =
    if error.position < 0 || error.position > String.length input then
      fail surface input "reported an out-of-range byte position"
  in
  let check_spans surface spans =
    if spans = [] then fail surface input "accepted input without a root span";
    List.iter
      (fun (_, (span : Centl_parser.source_span)) ->
        if
          span.start < 0 || span.finish < span.start
          || span.finish > String.length input
        then fail surface input "returned an out-of-range source span")
      spans
  in
  begin match Centl_parser.parse input with
  | Ok _ -> ()
  | Error error -> check_error "parser compatibility wrapper" error
  end;
  begin match Centl_parser.parse_located input with
  | Ok located -> check_spans "located expression parser" located.spans
  | Error error -> check_error "located expression parser" error
  end;
  match Centl_parser.parse_statement_located input with
  | Ok located -> check_spans "located statement parser" located.statement_spans
  | Error error -> check_error "located statement parser" error

let jsonl_case input =
  let response = Centl_protocol.handle_line (Centl_protocol.create ()) input in
  if not (protocol_response response) then
    fail "JSONL" input "returned a malformed protocol response"

let valid_notification input =
  try
    match Yojson.Safe.from_string input with
    | `Assoc fields ->
        List.assoc_opt "jsonrpc" fields = Some (`String "2.0")
        && (not (List.mem_assoc "id" fields))
        && begin match List.assoc_opt "method" fields with
        | Some (`String _) -> true
        | _ -> false
        end
    | _ -> false
  with Yojson.Json_error _ -> false

let mcp_response = function
  | `Assoc fields as response ->
      List.assoc_opt "jsonrpc" fields = Some (`String "2.0")
      && Option.is_some (List.assoc_opt "id" fields)
      && begin match
        (List.assoc_opt "result" fields, List.assoc_opt "error" fields)
      with
      | Some _, None -> json_round_trips response
      | None, Some (`Assoc error) ->
          Option.is_some (List.assoc_opt "code" error)
          && Option.is_some (List.assoc_opt "message" error)
          && json_round_trips response
      | _ -> false
      end
  | _ -> false

let initialized_mcp () =
  let state = Centl_mcp.create () in
  ignore
    (Centl_mcp.handle_line state
       {|{"jsonrpc":"2.0","id":"fuzz-init","method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"centl-fuzz","version":"1"}}}|});
  ignore
    (Centl_mcp.handle_line state
       {|{"jsonrpc":"2.0","method":"notifications/initialized"}|});
  state

let mcp_case input =
  match Centl_mcp.handle_line (initialized_mcp ()) input with
  | None ->
      if not (valid_notification input) then
        fail "MCP" input "silently discarded a non-notification"
  | Some response ->
      if not (mcp_response response) then
        fail "MCP" input "returned a malformed JSON-RPC response"

let ensure_ball label ball =
  if not (Centl_arb.is_finite ball) then failwith (label ^ " returned nonfinite");
  let lower, upper, exponent = Centl_arb.endpoints ball in
  let lower = Z.of_string lower in
  let upper = Z.of_string upper in
  ignore (Z.of_string exponent);
  if Z.compare lower upper > 0 then failwith (label ^ " reversed its endpoints")

let decimal_integer text =
  let length = String.length text in
  let first_digit = if length > 0 && text.[0] = '-' then 1 else 0 in
  length > first_digit
  &&
  let rec digits index =
    index = length
    ||
    let byte = text.[index] in
    (byte >= '0' && byte <= '9') && digits (index + 1)
  in
  digits first_digit

let rational_of_dyadic mantissa exponent =
  if exponent >= 0 then Q.mul_2exp (Q.of_bigint mantissa) exponent
  else Q.div_2exp (Q.of_bigint mantissa) (-exponent)

let fraction_case numerator denominator =
  let valid =
    decimal_integer numerator
    && decimal_integer denominator
    && not (Z.equal (Z.of_string denominator) Z.zero)
  in
  match Centl_arb.of_fraction numerator denominator 192 with
  | exception Invalid_argument _ ->
      if valid then failwith "of_fraction rejected a valid decimal fraction"
  | ball ->
      if not valid then failwith "of_fraction accepted malformed decimal input";
      ensure_ball "of_fraction" ball;
      let lower, upper, exponent = Centl_arb.endpoints ball in
      let exponent = int_of_string exponent in
      let lower = rational_of_dyadic (Z.of_string lower) exponent in
      let upper = rational_of_dyadic (Z.of_string upper) exponent in
      let expected = Q.make (Z.of_string numerator) (Z.of_string denominator) in
      if Q.compare lower expected > 0 || Q.compare expected upper > 0 then
        failwith "of_fraction enclosure does not contain the exact fraction"

let native_operations numerator denominator =
  let value = Centl_arb.of_fraction numerator denominator 192 in
  let half = Centl_arb.of_fraction "1" "2" 192 in
  let positive = Centl_arb.add (Centl_arb.abs value) half 192 in
  let check label operation = ensure_ball label (operation ()) in
  check "neg" (fun () -> Centl_arb.neg value);
  check "abs" (fun () -> Centl_arb.abs value);
  check "add" (fun () -> Centl_arb.add value half 192);
  check "sub" (fun () -> Centl_arb.sub value half 192);
  check "mul" (fun () -> Centl_arb.mul value half 192);
  check "div" (fun () -> Centl_arb.div value half 192);
  List.iter
    (fun exponent ->
      check "pow" (fun () -> Centl_arb.pow positive exponent 192))
    [ -10; -1; 0; 1; 10 ];
  check "sqrt" (fun () -> Centl_arb.sqrt positive 192);
  check "exp" (fun () -> Centl_arb.exp half 192);
  check "log" (fun () -> Centl_arb.log positive 192);
  check "sin" (fun () -> Centl_arb.sin half 192);
  check "cos" (fun () -> Centl_arb.cos half 192);
  check "tan" (fun () -> Centl_arb.tan half 192);
  check "asin" (fun () -> Centl_arb.asin half 192);
  check "acos" (fun () -> Centl_arb.acos half 192);
  check "atan" (fun () -> Centl_arb.atan value 192);
  check "atan2" (fun () -> Centl_arb.atan2 value positive 192);
  check "sinh" (fun () -> Centl_arb.sinh half 192);
  check "cosh" (fun () -> Centl_arb.cosh half 192);
  check "tanh" (fun () -> Centl_arb.tanh half 192)

let fuzz_seeds category check seeds =
  List.fold_left
    (fun total seed ->
      let cases = mutations seed in
      List.iter
        (fun input ->
          try check input
          with error -> fail category input (Printexc.to_string error))
        cases;
      total + List.length cases)
    0 seeds

let fuzz_native seeds =
  List.fold_left
    (fun total seed ->
      match String.split_on_char '\t' seed with
      | [ numerator; denominator ] ->
          let numerator =
            if numerator = "@repeat-9-32000" then String.make 32_000 '9'
            else numerator
          in
          let numerator_cases = mutations numerator in
          let denominator_cases = mutations denominator in
          List.iter
            (fun value -> fraction_case value denominator)
            numerator_cases;
          List.iter (fraction_case numerator) denominator_cases;
          if String.length numerator <= 4_096 then
            begin try native_operations numerator denominator with
            | Invalid_argument _ -> ()
            | error -> fail "native" seed (Printexc.to_string error)
            end;
          total + List.length numerator_cases + List.length denominator_cases
      | _ -> fail "native corpus" seed "expected numerator<TAB>denominator")
    0 seeds

let () =
  Printexc.record_backtrace true;
  let multiline_seeds =
    [
      read_file (Filename.concat corpus_root "parser_multiline_sum.centl");
      read_file
        (Filename.concat corpus_root "parser_multiline_definition.centl");
    ]
  in
  let parser_count =
    fuzz_seeds "parser" parser_case
      ("" :: (corpus "parser.txt" @ multiline_seeds))
  in
  let jsonl_count = fuzz_seeds "JSONL" jsonl_case ("" :: corpus "jsonl.txt") in
  let mcp_count = fuzz_seeds "MCP" mcp_case ("" :: corpus "mcp.txt") in
  let native_count = fuzz_native (corpus "native.txt") in
  Printf.printf
    "deterministic fuzz corpus passed: parser=%d JSONL=%d MCP=%d native=%d\n%!"
    parser_count jsonl_count mcp_count native_count
