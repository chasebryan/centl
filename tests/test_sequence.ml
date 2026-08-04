let fail message = Alcotest.fail message

let value source =
  match Centl_engine.evaluate source with
  | Ok value -> Centl_engine.text_of_value value
  | Error error -> fail (Centl_engine.error_text error)

let error_code ?(limits = Centl_engine.default_evaluation_limits)
    ?(cancelled = Centl_engine.never_cancelled) source =
  match Centl_engine.evaluate_with_limits ~cancelled limits source with
  | Ok result ->
      fail ("expected an error, received " ^ Centl_engine.text_of_value result)
  | Error error -> error.code

let session_value session source =
  match Centl_engine.evaluate_in_session session source with
  | Ok result -> Centl_engine.text_of_session_result result
  | Error error -> fail (Centl_engine.error_text error)

let session_error session source =
  match Centl_engine.evaluate_in_session session source with
  | Ok result ->
      fail
        ("expected an error, received "
        ^ Centl_engine.text_of_session_result result)
  | Error error -> error.code

let session_value_with_limits limits session source =
  match Centl_engine.evaluate_in_session_with_limits limits session source with
  | Ok result -> Centl_engine.text_of_session_result result
  | Error error -> fail (Centl_engine.error_text error)

let session_error_with_limits limits session source =
  match Centl_engine.evaluate_in_session_with_limits limits session source with
  | Ok result ->
      fail
        ("expected an error, received "
        ^ Centl_engine.text_of_session_result result)
  | Error error -> error.code

let member name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some value -> value
      | None -> fail ("missing JSON member " ^ name)
      end
  | _ -> fail "expected a JSON object"

let string_member name json =
  match member name json with
  | `String value -> value
  | _ -> fail ("expected string member " ^ name)

let bool_member name json =
  match member name json with
  | `Bool value -> value
  | _ -> fail ("expected Boolean member " ^ name)

let int_member name json =
  match member name json with
  | `Int value -> value
  | _ -> fail ("expected integer member " ^ name)

let error_code_of_json json = json |> member "error" |> string_member "code"

let sequence_items json =
  match member "items" json with
  | `List items -> items
  | _ -> fail "expected a sequence items array"

let check_sequence_response label expected_text expected_items response =
  Alcotest.(check bool) (label ^ " succeeds") true (bool_member "ok" response);
  let sequence = member "value" response in
  Alcotest.(check string)
    (label ^ " kind") "sequence"
    (string_member "kind" sequence);
  Alcotest.(check bool) (label ^ " exact") true (bool_member "exact" sequence);
  Alcotest.(check int)
    (label ^ " length")
    (List.length expected_items)
    (int_member "length" sequence);
  Alcotest.(check string)
    (label ^ " text") expected_text
    (string_member "text" sequence);
  let items = sequence_items sequence in
  Alcotest.(check (list string))
    (label ^ " item text") expected_items
    (List.map (string_member "text") items);
  Alcotest.(check (list bool))
    (label ^ " exact items")
    (List.map (Fun.const true) expected_items)
    (List.map (bool_member "exact") items);
  let provenance = member "provenance" response in
  Alcotest.(check string)
    (label ^ " provenance classification")
    "exact_sequence"
    (string_member "classification" provenance);
  Alcotest.(check string)
    (label ^ " provenance method")
    "finite_iteration"
    (string_member "method" provenance);
  Alcotest.(check string)
    (label ^ " provenance backend")
    "centl-iteration"
    (string_member "backend" provenance)

let exact_sequences () =
  Alcotest.(check string)
    "squares" "[1, 4, 9, 16, 25]"
    (value "sequence(k^2, k = 1, 5)");
  Alcotest.(check string)
    "rational elements" "[1/3, 2/3, 1]"
    (value "sequence(k/3, k = 1, 3)");
  Alcotest.(check string)
    "symbolic elements" "[x, x + 1, x + 2]"
    (value "sequence(x + k, k = 0, 2)");
  Alcotest.(check string) "empty range" "[]" (value "sequence(1/0, k = 2, 1)");
  Alcotest.(check string)
    "empty range skips expensive concrete work" "[]"
    (value "sequence(factorial(100000), k = 2, 1)");
  Alcotest.(check string)
    "empty range skips oversized powers" "[]"
    (value "sequence(2^1000000, k = 2, 1)");
  Alcotest.(check string)
    "empty sum remains lazy" "0"
    (value "sum(factorial(100000), k = 2, 1)");
  Alcotest.(check string)
    "empty product remains lazy" "1"
    (value "product(2^1000000, k = 2, 1)")

let exact_recurrences () =
  Alcotest.(check string)
    "factorials" "[1, 1, 2, 6, 24, 120]"
    (value "recurrence(1, a = a*n, n = 0, 5)");
  Alcotest.(check string)
    "geometric" "[3, 6, 12, 24]"
    (value "recurrence(3, a = 2*a, n = 4, 7)");
  Alcotest.(check string)
    "index-aware" "[10, 12, 15, 19]"
    (value "recurrence(10, a = a+n, n = 1, 4)");
  Alcotest.(check string)
    "empty recurrence does not evaluate initial" "[]"
    (value "recurrence(1/0, a = a, n = 3, 2)");
  Alcotest.(check string)
    "empty recurrence skips initial and step work" "[]"
    (value "recurrence(factorial(100000), a = factorial(100000), n = 2, 1)")

let lexical_scope () =
  let session = Centl_engine.create_session () in
  ignore (session_value session "k = 10");
  ignore (session_value session "a = 100");
  Alcotest.(check string)
    "sequence body shadows session index" "[1, 2, 3]"
    (session_value session "sequence(k, k = 1, 3)");
  Alcotest.(check string)
    "sequence bounds use outer scope" "[9, 10, 11]"
    (session_value session "sequence(k, k = k - 1, k + 1)");
  Alcotest.(check string)
    "recurrence value and index shadow bindings" "[1, 2, 4]"
    (session_value session "recurrence(1, a = a + k, k = 0, 2)");
  Alcotest.(check string)
    "capture-avoiding sequence substitution" "[k + 1, k + 2]"
    (value "substitute(sequence(x + k, k = 1, 2), x = k)")

let definitions () =
  let session = Centl_engine.create_session () in
  Alcotest.(check string)
    "store sequence" "s = [1, 4, 9]"
    (session_value session "s = sequence(k^2, k = 1, 3)");
  Alcotest.(check string)
    "load sequence" "[1, 4, 9]"
    (session_value session "s");
  Alcotest.(check string)
    "sequence is not a scalar" "sequence_not_expression"
    (session_error session "s + 1");
  Alcotest.(check string)
    "define sequence function" "squares(n) = sequence(k^2, k = 1, n)"
    (session_value session "squares(n) = sequence(k^2, k = 1, n)");
  Alcotest.(check string)
    "call sequence function" "[1, 4, 9, 16]"
    (session_value session "squares(4)");
  Alcotest.(check string)
    "define recurrence function"
    "factorials(n) = recurrence(1, a = a * k, k = 0, n)"
    (session_value session "factorials(n) = recurrence(1, a = a*k, k = 0, n)");
  Alcotest.(check string)
    "call recurrence function" "[1, 1, 2, 6, 24]"
    (session_value session "factorials(4)")

let session_iteration_boundaries () =
  let session = Centl_engine.create_session () in
  ignore (session_value session "f(x) = x");
  Alcotest.(check string)
    "empty session sequence skips invalid body expansion" "[]"
    (session_value session "sequence(f(1, 2), k = 2, 1)");
  Alcotest.(check string)
    "empty session recurrence skips invalid initial and step expansion" "[]"
    (session_value session "recurrence(f(1, 2), a = f(1, 2), n = 2, 1)");
  Alcotest.(check string)
    "empty sequence definition stays lazy" "empty = []"
    (session_value session "empty = sequence(f(1, 2), k = 2, 1)");
  Alcotest.(check string)
    "nonempty session sequence expands its body" "invalid_arguments"
    (session_error session "sequence(f(1, 2), k = 1, 1)");
  ignore
    (session_value session "large(x) = x + x + x + x + x + x + x + x + x + x");
  let tight_nodes =
    { Centl_engine.default_evaluation_limits with max_expression_nodes = 12 }
  in
  Alcotest.(check string)
    "empty range does not expand a large session function" "[]"
    (session_value_with_limits tight_nodes session
       "sequence(large(k), k = 2, 1)");
  Alcotest.(check string)
    "nonempty range enforces deferred expansion limits" "resource_limit"
    (session_error_with_limits tight_nodes session
       "sequence(large(k), k = 1, 1)");
  Alcotest.(check string)
    "sum rejects a one-term sequence" "exact_iteration_required"
    (error_code "sum(sequence(j, j = 1, 2), k = 1, 1)");
  Alcotest.(check string)
    "product rejects a one-term recurrence" "exact_iteration_required"
    (error_code "product(recurrence(1, a = a + j, j = 0, 1), k = 1, 1)");
  ignore (session_value session "stored = sequence(j, j = 1, 2)");
  Alcotest.(check string)
    "sum rejects a stored sequence term" "exact_iteration_required"
    (session_error session "sum(stored, k = 1, 1)");
  List.iter
    (fun transformation ->
      Alcotest.(check string)
        (transformation ^ " rejects a sequence")
        "sequence_not_expression"
        (error_code (transformation ^ "(sequence(k, k = 1, 2))")))
    [ "simplify"; "expand"; "factor" ];
  Alcotest.(check string)
    "nested approximation cannot claim exact provenance"
    "approximation_not_expression"
    (error_code "assuming(approx(sqrt(2)), x > 0)")

let renderer_roundtrip () =
  let session = Centl_engine.create_session () in
  ignore (session_value session "a = 2/3");
  ignore (session_value session "b = -2");
  let rational_power =
    session_value session "f(n) = sequence(a^2 + k, k = 1, n)"
  in
  let negative_power =
    session_value session "g(n) = sequence(b^2 + k, k = 1, n)"
  in
  let rational_divisor =
    session_value session "h(n) = sequence(k / a, k = 1, n)"
  in
  let nested_power = session_value session "nested(t) = (x^2)^3" in
  Alcotest.(check string)
    "rational power is parenthesized" "f(n) = sequence((2/3)^2 + k, k = 1, n)"
    rational_power;
  Alcotest.(check string)
    "negative power is parenthesized" "g(n) = sequence((-2)^2 + k, k = 1, n)"
    negative_power;
  Alcotest.(check string)
    "rational divisor is parenthesized" "h(n) = sequence(k / (2/3), k = 1, n)"
    rational_divisor;
  Alcotest.(check string)
    "nested power base is parenthesized" "nested(t) = (x^2)^3" nested_power;
  let replay = Centl_engine.create_session () in
  List.iter
    (fun source -> ignore (session_value replay source))
    [ rational_power; negative_power; rational_divisor; nested_power ];
  Alcotest.(check string)
    "rational power round trip" "[13/9]"
    (session_value replay "f(1)");
  Alcotest.(check string)
    "negative power round trip" "[5]"
    (session_value replay "g(1)");
  Alcotest.(check string)
    "rational divisor round trip" "[3/2]"
    (session_value replay "h(1)");
  Alcotest.(check string)
    "nested power round trip" "(x^2)^3"
    (session_value replay "nested(0)")

let invalid_forms () =
  Alcotest.(check string)
    "same recurrence binders" "invalid_arguments"
    (error_code "recurrence(1, a = a + 1, a = 0, 3)");
  Alcotest.(check string)
    "reserved sequence index" "reserved_name"
    (error_code "sequence(pi, pi = 1, 3)");
  Alcotest.(check string)
    "reserved recurrence binder" "reserved_name"
    (error_code "recurrence(1, sum = sum + n, n = 0, 3)");
  Alcotest.(check string)
    "substitution cannot sanitize a reserved sequence index" "reserved_name"
    (error_code "substitute(sequence(x, pi = 1, 2), x = pi)");
  Alcotest.(check string)
    "substitution cannot split invalid recurrence binders" "invalid_arguments"
    (error_code "substitute(recurrence(1, a = a + x, a = 0, 2), x = a)");
  Alcotest.(check string)
    "approximate element" "exact_sequence_required"
    (error_code "sequence(approx(k), k = 1, 2)");
  Alcotest.(check string)
    "nested sequence element" "exact_sequence_required"
    (error_code "sequence(sequence(j, j = 1, 2), k = 1, 2)");
  [
    "sequence(k, k, 1, 3)";
    "sequence(k, k = 1)";
    "recurrence(1, a + 1, n = 0, 3)";
    "recurrence(1, a = a + n, 0, 3)";
    "recurrence(1, a = a + n, n = 0)";
  ]
  |> List.iter (fun source ->
      match Centl_parser.parse source with
      | Error error ->
          Alcotest.(check bool)
            ("bounded parser position for " ^ source)
            true
            (error.position >= 0 && error.position <= String.length source)
      | Ok _ -> fail ("malformed sequence form was accepted: " ^ source))

let limits_and_cancellation () =
  let request_with_result_limit limit expression =
    Centl_engine.evaluate_request
      (`Assoc
         [
           ("version", `Int 1);
           ("expression", `String expression);
           ("limits", `Assoc [ ("max_result_bytes", `Int limit) ]);
         ])
  in
  let iteration_limits =
    { Centl_engine.default_evaluation_limits with max_integer_iterations = 3 }
  in
  Alcotest.(check string)
    "sequence iteration limit" "resource_limit"
    (error_code ~limits:iteration_limits "sequence(k, k = 1, 4)");
  Alcotest.(check string)
    "recurrence iteration limit" "resource_limit"
    (error_code ~limits:iteration_limits "recurrence(1, a = a + n, n = 0, 3)");
  let bit_limits =
    { Centl_engine.default_evaluation_limits with max_exact_bits = 64 }
  in
  Alcotest.(check string)
    "sequence term bit preflight" "resource_limit"
    (error_code ~limits:bit_limits "sequence(k^1000, k = 2, 2)");
  Alcotest.(check string)
    "recurrence term bit preflight" "resource_limit"
    (error_code ~limits:bit_limits "recurrence(2, a = a^1000, n = 0, 1)");
  let rational_bit_limits =
    { Centl_engine.default_evaluation_limits with max_exact_bits = 100 }
  in
  Alcotest.(check string)
    "rational addition enforces actual aggregate bits" "resource_limit"
    (error_code ~limits:rational_bit_limits "1 / ((2^40) * (2^40)) + 1/3");
  let symbolic_bit_limits =
    { Centl_engine.default_evaluation_limits with max_exact_bits = 5 }
  in
  Alcotest.(check string)
    "symbolic power exponent counts toward exact bits" "resource_limit"
    (error_code ~limits:symbolic_bit_limits "x^1000");
  let bit_state = Centl_protocol.create () in
  ignore
    (Centl_protocol.handle_json bit_state
       (`Assoc
          [
            ("version", `Int 1);
            ("id", `String "define-bits");
            ("expression", `String "d = 2^40");
          ]));
  let bounded_rational =
    Centl_protocol.handle_json bit_state
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "bounded-bits");
           ("expression", `String "1/(d*d) + 1/3");
           ("limits", `Assoc [ ("max_exact_bits", `Int 100) ]);
         ])
  in
  Alcotest.(check string)
    "persistent JSONL enforces rational result bits" "resource_limit"
    (error_code_of_json bounded_rational);
  let node_limits =
    { Centl_engine.default_evaluation_limits with max_expression_nodes = 40 }
  in
  Alcotest.(check string)
    "recurrence substitution node preflight" "resource_limit"
    (error_code ~limits:node_limits "recurrence(x, a = a + a + a + a, n = 0, 3)");
  let stateless_limited =
    Centl_engine.evaluate_request
      (`Assoc
         [
           ("version", `Int 1);
           ("expression", `String "sequence(k, k = 1, 4)");
           ("limits", `Assoc [ ("max_integer_iterations", `Int 3) ]);
         ])
  in
  Alcotest.(check string)
    "stateless JSON honors request limits" "resource_limit"
    (error_code_of_json stateless_limited);
  let result_limits =
    { Centl_engine.default_evaluation_limits with max_result_bytes = 128 }
  in
  Alcotest.(check string)
    "aggregate result limit" "resource_limit"
    (error_code ~limits:result_limits "sequence(k^10, k = 1, 100)");
  Alcotest.(check string)
    "default limit accounts for serialized sequence items" "resource_limit"
    (error_code "sequence(0, k = 1, 100000)");
  let machine_limit = 4_096 in
  let machine_response =
    Centl_protocol.handle_json (Centl_protocol.create ())
      (`Assoc
         [
           ("version", `Int 1);
           ("expression", `String "sequence(0, k = 1, 20)");
           ("limits", `Assoc [ ("max_result_bytes", `Int machine_limit) ]);
         ])
  in
  Alcotest.(check bool)
    "small machine response succeeds" true
    (bool_member "ok" machine_response);
  Alcotest.(check bool)
    "successful structured value fits its result-byte limit" true
    (String.length (Yojson.Safe.to_string (member "value" machine_response))
    <= machine_limit);
  let conditional_sequence =
    request_with_result_limit 1_284 "sequence(assuming(x + k, y > k), k = 1, 3)"
  in
  Alcotest.(check bool)
    "conditional symbolic sequence fits a safe tight budget" true
    (bool_member "ok" conditional_sequence);
  Alcotest.(check bool)
    "conditional sequence value respects its tight budget" true
    (String.length (Yojson.Safe.to_string (member "value" conditional_sequence))
    <= 1_284);
  let oversized_integer = String.make 1_000 '9' in
  Alcotest.(check string)
    "serialized integer duplication is preflighted" "resource_limit"
    (request_with_result_limit 1_200 oversized_integer |> error_code_of_json);
  let rational_digits = String.make 900 '9' in
  Alcotest.(check string)
    "serialized rational duplication is preflighted" "resource_limit"
    (request_with_result_limit 2_100
       (rational_digits ^ "/1" ^ String.make 899 '0')
    |> error_code_of_json);
  let long_symbol = String.make 1_000 'x' in
  Alcotest.(check string)
    "serialized symbolic duplication is preflighted" "resource_limit"
    (request_with_result_limit 1_200 long_symbol |> error_code_of_json);
  let condition_symbol = String.make 700 'y' in
  Alcotest.(check string)
    "serialized symbolic conditions are preflighted" "resource_limit"
    (request_with_result_limit 1_800
       ("assuming(" ^ condition_symbol ^ ", " ^ condition_symbol ^ " > 0)")
    |> error_code_of_json);
  let equation_symbol = String.make 700 'z' in
  Alcotest.(check string)
    "serialized equations are preflighted" "resource_limit"
    (request_with_result_limit 1_200 ("solve(" ^ equation_symbol ^ " = 0, x)")
    |> error_code_of_json);
  Alcotest.(check string)
    "unresolved equation boundary includes schema overhead" "resource_limit"
    (request_with_result_limit 1_566 ("solve(" ^ equation_symbol ^ " = 0, x)")
    |> error_code_of_json);
  Alcotest.(check string)
    "maximum-precision enclosure includes numeric metadata" "resource_limit"
    (request_with_result_limit 6_351 "approx(pi, 1000)" |> error_code_of_json);
  let successful_payloads =
    [
      String.make 100 '8';
      String.make 100 '8' ^ "/1" ^ String.make 99 '0';
      String.make 100 's';
      "assuming(x, y > 0)";
      "approx(pi, 50)";
      "solve(x^2 - 1 = 0, x)";
    ]
  in
  List.iter
    (fun expression ->
      let response = request_with_result_limit machine_limit expression in
      Alcotest.(check bool)
        ("bounded scalar response succeeds: " ^ expression)
        true
        (bool_member "ok" response);
      Alcotest.(check bool)
        ("bounded scalar value fits: " ^ expression)
        true
        (String.length (Yojson.Safe.to_string (member "value" response))
        <= machine_limit))
    successful_payloads;
  let definition_limits =
    { Centl_engine.default_evaluation_limits with max_result_bytes = 1_000 }
  in
  let definition_session = Centl_engine.create_session () in
  let reject_definition label source =
    Alcotest.(check string)
      label "resource_limit"
      (session_error_with_limits definition_limits definition_session source);
    Alcotest.(check int)
      (label ^ " is atomic") 0
      (Centl_engine.session_binding_count definition_session)
  in
  reject_definition "long value-definition name is preflighted"
    (String.make 800 'v' ^ " = 1");
  reject_definition "long function-definition name is preflighted"
    (String.make 800 'f' ^ "(x) = x");
  reject_definition "long function body is preflighted"
    ("f(x) = " ^ String.make 800 'b');
  let long_parameter = String.make 800 'p' in
  reject_definition "long function parameter is preflighted"
    ("f(" ^ long_parameter ^ ") = " ^ long_parameter);
  reject_definition "stored sequence definition wrapper is preflighted"
    (String.make 800 's' ^ " = sequence(k, k = 1, 2)");
  Alcotest.(check string)
    "small definition still fits a low result limit" "a = 1"
    (session_value_with_limits definition_limits definition_session "a = 1");
  let retention_session = Centl_engine.create_session () in
  let retention_limit = 2_500 in
  let retention_limits =
    {
      Centl_engine.default_evaluation_limits with
      max_result_bytes = retention_limit;
    }
  in
  ignore
    (session_value_with_limits retention_limits retention_session
       "first = sequence(0, k = 1, 20)");
  Alcotest.(check string)
    "stored sequence bytes aggregate across a session" "resource_limit"
    (session_error_with_limits retention_limits retention_session
       "second = sequence(0, k = 1, 20)");
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 30
  in
  Alcotest.(check string)
    "cooperative cancellation" "cancelled"
    (error_code ~cancelled "recurrence(1, a = a + n, n = 0, 1000)")

let machine_schema () =
  let compatible_request =
    Centl_engine.evaluate_request
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "one-shot");
           ("op", `String "evaluate");
           ("expression", `String "1 + 1");
         ])
  in
  Alcotest.(check bool)
    "stateless JSON accepts explicit evaluate" true
    (bool_member "ok" compatible_request);
  Alcotest.(check string)
    "stateless JSON echoes request id" "one-shot"
    (string_member "id" compatible_request);
  let response =
    Centl_engine.evaluate_request
      (`Assoc
         [
           ("version", `Int 1); ("expression", `String "sequence(k/2, k = 1, 3)");
         ])
  in
  check_sequence_response "stateless JSON" "[1/2, 1, 3/2]" [ "1/2"; "1"; "3/2" ]
    response;
  let sequence = member "value" response in
  begin match member "items" sequence with
  | `List [ first; second; third ] ->
      Alcotest.(check string)
        "first kind" "rational"
        (string_member "kind" first);
      Alcotest.(check string)
        "second kind" "integer"
        (string_member "kind" second);
      Alcotest.(check string)
        "third kind" "rational"
        (string_member "kind" third)
  | _ -> fail "sequence items have the wrong shape"
  end

let persistent_jsonl () =
  let state = Centl_protocol.create () in
  let request = Centl_protocol.handle_line state in
  let definition =
    request {|{"version":1,"id":"bound","expression":"n = 4"}|}
  in
  Alcotest.(check bool)
    "JSONL definition succeeds" true
    (bool_member "ok" definition);
  Alcotest.(check int)
    "JSONL definition retained" 1
    (definition |> member "session" |> int_member "definitions");
  let sequence =
    request
      {|{"version":1,"id":"sequence","expression":"sequence(k/2, k = 1, n)"}|}
  in
  Alcotest.(check string)
    "JSONL sequence id" "sequence"
    (string_member "id" sequence);
  check_sequence_response "persistent JSONL sequence" "[1/2, 1, 3/2, 2]"
    [ "1/2"; "1"; "3/2"; "2" ] sequence;
  Alcotest.(check int)
    "JSONL sequence uses retained definition" 1
    (sequence |> member "session" |> int_member "definitions");
  let recurrence =
    request
      {|{"version":1,"id":"recurrence","expression":"recurrence(1, a = a*k, k = 0, n)"}|}
  in
  Alcotest.(check string)
    "JSONL recurrence id" "recurrence"
    (string_member "id" recurrence);
  check_sequence_response "persistent JSONL recurrence" "[1, 1, 2, 6, 24]"
    [ "1"; "1"; "2"; "6"; "24" ]
    recurrence;
  Alcotest.(check int)
    "JSONL request accounting" 3
    (recurrence |> member "session" |> int_member "requests")

let persistent_failures () =
  let state = Centl_protocol.create () in
  let request = Centl_protocol.handle_line state in
  let malformed =
    request
      {|{"version":1,"id":"bad-sequence","expression":"sequence(k, k = 1)"}|}
  in
  Alcotest.(check string)
    "malformed JSONL id" "bad-sequence"
    (string_member "id" malformed);
  Alcotest.(check string)
    "malformed JSONL sequence" "syntax_error"
    (error_code_of_json malformed);
  Alcotest.(check string)
    "malformed JSONL provenance" "failure"
    (malformed |> member "provenance" |> string_member "classification");
  let bounded =
    request
      {|{"version":1,"id":"bounded-sequence","expression":"sequence(k, k = 1, 4)","limits":{"max_integer_iterations":3}}|}
  in
  Alcotest.(check string)
    "bounded JSONL sequence" "resource_limit"
    (error_code_of_json bounded);
  let bounded_recurrence =
    request
      {|{"version":1,"id":"bounded-recurrence","expression":"recurrence(1, a = a + k, k = 0, 3)","limits":{"max_integer_iterations":3}}|}
  in
  Alcotest.(check string)
    "bounded JSONL recurrence" "resource_limit"
    (error_code_of_json bounded_recurrence)

let initialized_mcp () =
  let state = Centl_mcp.create () in
  begin match
    Centl_mcp.handle_line state
      {|{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"sequence-test","version":"1"}}}|}
  with
  | Some _ -> ()
  | None -> fail "MCP initialize produced no response"
  end;
  begin match
    Centl_mcp.handle_line state
      {|{"jsonrpc":"2.0","method":"notifications/initialized"}|}
  with
  | None -> ()
  | Some _ -> fail "MCP initialized notification produced a response"
  end;
  state

let mcp_calculate ?(cancelled = Centl_engine.never_cancelled) ?limits state id
    expression =
  let arguments =
    match limits with
    | None -> [ ("expression", `String expression) ]
    | Some limits ->
        [ ("expression", `String expression); ("limits", `Assoc limits) ]
  in
  let request =
    `Assoc
      [
        ("jsonrpc", `String "2.0");
        ("id", id);
        ("method", `String "tools/call");
        ( "params",
          `Assoc
            [
              ("name", `String "centl_calculate");
              ("arguments", `Assoc arguments);
            ] );
      ]
  in
  match
    Centl_mcp.handle_line ~cancelled state (Yojson.Safe.to_string request)
  with
  | Some response -> response
  | None -> fail "MCP calculation produced no response"

let mcp_structured response =
  response |> member "result" |> member "structuredContent"

let check_mcp_sequence label expected_text expected_items response =
  let result = member "result" response in
  Alcotest.(check bool)
    (label ^ " is not a tool error")
    false
    (bool_member "isError" result);
  begin match member "content" result with
  | `List [ content ] ->
      Alcotest.(check string)
        (label ^ " text content") expected_text
        (string_member "text" content)
  | _ -> fail "MCP result content did not contain exactly one item"
  end;
  check_sequence_response label expected_text expected_items
    (member "structuredContent" result)

let mcp_interfaces () =
  let state = initialized_mcp () in
  ignore (mcp_calculate state (`String "define") "n = 4");
  let sequence =
    mcp_calculate state (`String "sequence") "sequence(k/2, k = 1, n)"
  in
  Alcotest.(check string)
    "MCP sequence id" "sequence"
    (string_member "id" sequence);
  check_mcp_sequence "MCP sequence" "[1/2, 1, 3/2, 2]"
    [ "1/2"; "1"; "3/2"; "2" ] sequence;
  let recurrence =
    mcp_calculate state (`String "recurrence")
      "recurrence(1, a = a*k, k = 0, n)"
  in
  check_mcp_sequence "MCP recurrence" "[1, 1, 2, 6, 24]"
    [ "1"; "1"; "2"; "6"; "24" ]
    recurrence

let mcp_failures () =
  let state = initialized_mcp () in
  let malformed =
    mcp_calculate state (`String "bad-recurrence")
      "recurrence(1, a = a + k, k = 0)"
  in
  Alcotest.(check bool)
    "malformed MCP recurrence is a tool error" true
    (malformed |> member "result" |> bool_member "isError");
  Alcotest.(check string)
    "malformed MCP recurrence" "syntax_error"
    (malformed |> mcp_structured |> error_code_of_json);
  let bounded =
    mcp_calculate
      ~limits:[ ("max_integer_iterations", `Int 2) ]
      state (`String "bounded-sequence") "sequence(k, k = 1, 3)"
  in
  Alcotest.(check bool)
    "bounded MCP sequence is a tool error" true
    (bounded |> member "result" |> bool_member "isError");
  Alcotest.(check string)
    "bounded MCP sequence" "resource_limit"
    (bounded |> mcp_structured |> error_code_of_json);
  let cancelled =
    mcp_calculate
      ~cancelled:(fun () -> true)
      state (`String "cancelled") "recurrence(1, a = a + k, k = 0, 1000)"
  in
  Alcotest.(check string)
    "cancelled MCP recurrence" "cancelled"
    (cancelled |> mcp_structured |> error_code_of_json);
  Alcotest.(check string)
    "cancelled MCP provenance" "cancelled"
    (cancelled |> mcp_structured |> member "provenance"
    |> string_member "classification")

let () =
  Alcotest.run "centl exact sequences"
    [
      ( "sequence and recurrence",
        [
          Alcotest.test_case "exact sequences" `Quick exact_sequences;
          Alcotest.test_case "exact recurrences" `Quick exact_recurrences;
          Alcotest.test_case "lexical scope" `Quick lexical_scope;
          Alcotest.test_case "definitions" `Quick definitions;
          Alcotest.test_case "session and scalar boundaries" `Quick
            session_iteration_boundaries;
          Alcotest.test_case "renderer round trip" `Quick renderer_roundtrip;
          Alcotest.test_case "invalid forms" `Quick invalid_forms;
          Alcotest.test_case "limits and cancellation" `Quick
            limits_and_cancellation;
          Alcotest.test_case "machine schema" `Quick machine_schema;
          Alcotest.test_case "persistent JSONL" `Quick persistent_jsonl;
          Alcotest.test_case "persistent JSONL failures" `Quick
            persistent_failures;
          Alcotest.test_case "MCP interfaces" `Quick mcp_interfaces;
          Alcotest.test_case "MCP failures" `Quick mcp_failures;
        ] );
    ]
