let fail message = Alcotest.fail message

let iteration source =
  match Centl_parser.parse source with
  | Ok
      (Centl_Core.Function
         (name, [ body; Centl_Core.Symbol variable; lower; upper ]))
    when name = "sum" || name = "product" ->
      ( (if name = "sum" then Centl_iteration.Sum else Centl_iteration.Product),
        body,
        variable,
        lower,
        upper )
  | Ok _ -> fail ("expected a finite iteration: " ^ source)
  | Error error ->
      fail
        (Printf.sprintf "could not parse %s at %d: %s" source error.position
           error.message)

let limits ?(iterations = 100_000) ?(bits = 1_000_000) ?(nodes = 100_000) () =
  Centl_iteration.
    {
      max_iterations = iterations;
      max_work =
        (if iterations > max_int / 64 then max_int else iterations * 64);
      max_exact_bits = bits;
      max_expression_nodes = nodes;
      max_result_bytes = 1_048_576;
    }

let evaluate ?cancelled ?custom_limits source =
  let kind, body, variable, lower, upper = iteration source in
  let limits = Option.value custom_limits ~default:(limits ()) in
  Centl_iteration.evaluate ?cancelled limits kind body variable lower upper

let rational_text = function
  | Ok (Centl_Core.ExactRational value) ->
      if Z.equal value.Centl_Core.denominator Z.one then
        Z.to_string value.numerator
      else Z.to_string value.numerator ^ "/" ^ Z.to_string value.denominator
  | Ok (Centl_Core.ExactSymbolic _) -> fail "expected an exact rational result"
  | Error _ -> fail "expected a successful finite iteration"

let engine_text source =
  match Centl_engine.evaluate source with
  | Ok value -> Centl_engine.text_of_value value
  | Error error -> fail (Centl_engine.error_text error)

let engine_error_code ?(cancelled = Centl_engine.never_cancelled)
    ?(custom_limits = Centl_engine.default_evaluation_limits) source =
  match Centl_engine.evaluate_with_limits ~cancelled custom_limits source with
  | Ok value ->
      fail
        ("expected an engine failure, received "
        ^ Centl_engine.text_of_value value)
  | Error error -> error.code

let session_text session source =
  match Centl_engine.evaluate_in_session session source with
  | Ok result -> Centl_engine.text_of_session_result result
  | Error error -> fail (Centl_engine.error_text error)

let session_error_code session source =
  match Centl_engine.evaluate_in_session session source with
  | Ok result ->
      fail
        ("expected a session failure, received "
        ^ Centl_engine.text_of_session_result result)
  | Error error -> error.code

let json_member name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some value -> value
      | None -> fail ("missing JSON field " ^ name)
      end
  | _ -> fail "expected a JSON object"

let json_string name json =
  match json_member name json with
  | `String value -> value
  | _ -> fail ("expected JSON string field " ^ name)

let protocol_text json = json |> json_member "value" |> json_string "text"

let exact_examples () =
  Alcotest.(check string)
    "sum of squares" "338350"
    (evaluate "sum(k^2, k = 1, 100)" |> rational_text);
  Alcotest.(check string)
    "factorial product" "2432902008176640000"
    (evaluate "product(k, k = 1, 20)" |> rational_text);
  Alcotest.(check string)
    "harmonic rational" "25/12"
    (evaluate "sum(1/k, k = 1, 4)" |> rational_text);
  Alcotest.(check string)
    "empty sum" "0"
    (evaluate "sum(k, k = 4, 3)" |> rational_text);
  Alcotest.(check string)
    "empty product" "1"
    (evaluate "product(k, k = 4, 3)" |> rational_text);
  Alcotest.(check string)
    "negative inclusive range" "0"
    (evaluate "sum(k, k = -10, 10)" |> rational_text);
  Alcotest.(check string)
    "evaluated bounds" "9"
    (evaluate "sum(k, k = 1 + 1, 4)" |> rational_text)

let engine_examples () =
  Alcotest.(check string)
    "sum through public evaluator" "338350"
    (engine_text "sum(k^2, k = 1, 100)");
  Alcotest.(check string)
    "telescoping product" "11"
    (engine_text "product((k + 1)/k, k = 1, 10)");
  Alcotest.(check string)
    "negative inclusive range" "0"
    (engine_text "sum(k, k = -10, 10)");
  Alcotest.(check string)
    "evaluated bounds" "9"
    (engine_text "sum(k, k = 1 + 1, 4)");
  Alcotest.(check string)
    "iterative built-in body" "9"
    (engine_text "sum(factorial(k), k = 1, 3)");
  Alcotest.(check string)
    "empty sum identity" "0"
    (engine_text "sum(k^100, k = 1, 0)");
  Alcotest.(check string)
    "empty product identity" "1"
    (engine_text "product(1/0, k = 1, 0)")

let nested_and_substitution () =
  Alcotest.(check string)
    "dependent nested sum" "65"
    (engine_text "sum(sum(i*j, j = 1, i), i = 1, 4)");
  Alcotest.(check string)
    "nested product of triangular numbers" "180"
    (engine_text "product(sum(j, j = 1, i), i = 1, 4)");
  Alcotest.(check string)
    "inner iterator shadows outer iterator" "9"
    (engine_text "sum(sum(k, k = 1, 2), k = 1, 3)");
  Alcotest.(check string)
    "substitution enters the body" "30"
    (engine_text "substitute(sum(k*x, k = 1, 4), x = 3)");
  Alcotest.(check string)
    "substitution enters a dependent bound" "40"
    (engine_text "substitute(sum(k*x, k = 1, x), x = 4)");
  Alcotest.(check string)
    "substitution respects the iterator binder" "6"
    (engine_text "substitute(sum(k, k = 1, 3), k = 100)");
  Alcotest.(check string)
    "substitution reaches a free same-name bound" "6"
    (engine_text "substitute(sum(k, k = 1, k), k = 3)")

let session_scoping () =
  let session = Centl_engine.create_session () in
  ignore (session_text session "k = 10");
  Alcotest.(check string)
    "bounds use the session value while the body shadows it" "30"
    (session_text session "sum(k, k = k - 1, k + 1)");
  Alcotest.(check string)
    "iteration does not mutate the session binding" "10"
    (session_text session "k");
  Alcotest.(check string)
    "store completed sum" "total = 15"
    (session_text session "total = sum(j, j = 1, 5)");
  Alcotest.(check string)
    "stored sum remains exact" "15"
    (session_text session "total");
  Alcotest.(check string)
    "stored iteration renders with its binder assignment"
    "triangular(n) = sum(j, j = 1, n)"
    (session_text session "triangular(n) = sum(j, j = 1, n)");
  Alcotest.(check string)
    "finite iteration in a user function" "55"
    (session_text session "triangular(10)");
  Alcotest.(check string)
    "a same-name iterator is not a recursive reference" "k = 6"
    (session_text (Centl_engine.create_session ()) "k = sum(k, k = 1, 3)");
  Alcotest.(check string)
    "a free same-name bound remains a recursive reference"
    "recursive_definition"
    (session_error_code (Centl_engine.create_session ()) "n = sum(k, k = 1, n)")

let bounded_failures () =
  begin match
    evaluate ~custom_limits:(limits ~iterations:3 ()) "sum(k, k = 1, 4)"
  with
  | Error (Centl_iteration.Resource_limit _) -> ()
  | _ -> fail "expected an iteration resource limit"
  end;
  begin match evaluate "sum(k, k = pi, 4)" with
  | Error (Centl_iteration.Invalid_bound _) -> ()
  | _ -> fail "expected an invalid exact-integer bound"
  end;
  begin match evaluate "sum(1/k, k = 0, 2)" with
  | Error (Centl_iteration.Core_error Centl_Core.DivisionByZero) -> ()
  | _ -> fail "expected a term division-by-zero failure"
  end

let engine_resource_limits () =
  let iteration_limit =
    { Centl_engine.default_evaluation_limits with max_integer_iterations = 3 }
  in
  Alcotest.(check string)
    "single range limit" "resource_limit"
    (engine_error_code ~custom_limits:iteration_limit "sum(k, k = 1, 4)");
  let nested_limit =
    { Centl_engine.default_evaluation_limits with max_integer_iterations = 8 }
  in
  Alcotest.(check string)
    "nested ranges share one request budget" "resource_limit"
    (engine_error_code ~custom_limits:nested_limit
       "sum(sum(i + j, j = 1, 2), i = 1, 3)");
  let exact_nested_limit =
    { Centl_engine.default_evaluation_limits with max_integer_iterations = 9 }
  in
  begin match
    Centl_engine.evaluate_with_limits exact_nested_limit
      "sum(sum(i + j, j = 1, 2), i = 1, 3)"
  with
  | Ok value ->
      Alcotest.(check string)
        "exact aggregate budget is accepted" "21"
        (Centl_engine.text_of_value value)
  | Error error -> fail (Centl_engine.error_text error)
  end;
  let builtin_limit =
    { Centl_engine.default_evaluation_limits with max_integer_iterations = 8 }
  in
  Alcotest.(check string)
    "body built-ins share the request budget" "resource_limit"
    (engine_error_code ~custom_limits:builtin_limit
       "sum(factorial(k), k = 1, 3)");
  let traversal_limit =
    { Centl_engine.default_evaluation_limits with max_integer_iterations = 100 }
  in
  let large_exact_body = List.init 80 (fun _ -> "1") |> String.concat " + " in
  Alcotest.(check string)
    "term traversal consumes bounded work" "resource_limit"
    (engine_error_code ~custom_limits:traversal_limit
       (Printf.sprintf "sum(%s, k = 1, 100)" large_exact_body));
  let bit_limit =
    { Centl_engine.default_evaluation_limits with max_exact_bits = 8 }
  in
  Alcotest.(check string)
    "intermediate exact result limit" "resource_limit"
    (engine_error_code ~custom_limits:bit_limit "product(k, k = 1, 10)");
  let node_limit =
    { Centl_engine.default_evaluation_limits with max_expression_nodes = 10 }
  in
  Alcotest.(check string)
    "intermediate symbolic node limit" "resource_limit"
    (engine_error_code ~custom_limits:node_limit "sum(x, k = 1, 7)");
  let repeated_body = List.init 200 (fun _ -> "x") |> String.concat " + " in
  Alcotest.(check string)
    "hostile repeated symbolic body is rejected incrementally" "resource_limit"
    (engine_error_code (Printf.sprintf "sum(%s, k = 1, 5000)" repeated_body))

let reserved_names () =
  let error source =
    session_error_code (Centl_engine.create_session ()) source
  in
  Alcotest.(check string)
    "sum value definition" "reserved_name" (error "sum = 3");
  Alcotest.(check string)
    "product function definition" "reserved_name" (error "product(x) = x");
  Alcotest.(check string)
    "sum function parameter" "reserved_name" (error "f(sum) = sum");
  Alcotest.(check string)
    "product function parameter" "reserved_name"
    (error "f(product) = product");
  Alcotest.(check string)
    "built-in iterator name" "reserved_name"
    (engine_error_code "sum(pi, pi = 1, 3)")

let malformed_parser_forms () =
  [
    "sum(k, k, 1, 3)";
    "product(k, 1 = 1, 3)";
    "sum(k, k = 1)";
    "product(k, k = 1, 3, 4)";
    "sum(k, k = 1, )";
    "sum(k, k = 1, 3";
  ]
  |> List.iter (fun source ->
      match Centl_parser.parse source with
      | Error error ->
          Alcotest.(check bool)
            ("bounded parser position for " ^ source)
            true
            (error.position >= 0 && error.position <= String.length source)
      | Ok _ -> fail ("malformed finite iteration was accepted: " ^ source))

let cooperative_cancellation () =
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 5
  in
  match evaluate ~cancelled "sum(k, k = 1, 100)" with
  | Error Centl_iteration.Cancelled ->
      Alcotest.(check bool) "checked between terms" true (!checks >= 5)
  | _ -> fail "expected deterministic cooperative cancellation"

let engine_cancellation () =
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 50
  in
  Alcotest.(check string)
    "engine cancellation code" "cancelled"
    (engine_error_code ~cancelled "sum(k^2, k = 1, 1000)");
  let session = Centl_engine.create_session () in
  let checks = ref 0 in
  let cancelled () =
    incr checks;
    !checks >= 50
  in
  begin match
    Centl_engine.evaluate_in_session_with_limits ~cancelled
      Centl_engine.default_evaluation_limits session
      "partial = product(k + 1, k = 1, 1000)"
  with
  | Error error ->
      Alcotest.(check string) "session cancellation" "cancelled" error.code
  | Ok result ->
      fail
        ("expected a cancelled definition, received "
        ^ Centl_engine.text_of_session_result result)
  end;
  Alcotest.(check int)
    "cancelled finite result is not committed" 0
    (Centl_engine.session_binding_count session)

let machine_interfaces () =
  let stateless =
    Centl_engine.evaluate_request
      (`Assoc
         [ ("version", `Int 1); ("expression", `String "sum(k, k = 1, 10)") ])
  in
  Alcotest.(check string) "stateless JSON sum" "55" (protocol_text stateless);
  Alcotest.(check string)
    "stateless exact provenance" "exact"
    (stateless |> json_member "provenance" |> json_string "classification");
  let protocol = Centl_protocol.create () in
  ignore
    (Centl_protocol.handle_json protocol
       (`Assoc [ ("version", `Int 1); ("expression", `String "n = 6") ]));
  let persistent =
    Centl_protocol.handle_json protocol
      (`Assoc
         [
           ("version", `Int 1);
           ("id", `String "finite-product");
           ("expression", `String "product(k, k = 1, n)");
         ])
  in
  Alcotest.(check string)
    "persistent JSONL product" "720" (protocol_text persistent);
  Alcotest.(check string)
    "persistent request id" "finite-product"
    (json_string "id" persistent);
  let mcp = Centl_mcp.create () in
  ignore
    (Centl_mcp.handle_json mcp
       (`Assoc
          [
            ("jsonrpc", `String "2.0");
            ("id", `Int 1);
            ("method", `String "initialize");
            ( "params",
              `Assoc
                [
                  ("protocolVersion", `String "2025-11-25");
                  ("capabilities", `Assoc []);
                  ( "clientInfo",
                    `Assoc
                      [
                        ("name", `String "iteration-test");
                        ("version", `String "1");
                      ] );
                ] );
          ]));
  ignore
    (Centl_mcp.handle_json mcp
       (`Assoc
          [
            ("jsonrpc", `String "2.0");
            ("method", `String "notifications/initialized");
          ]));
  let response =
    match
      Centl_mcp.handle_json mcp
        (`Assoc
           [
             ("jsonrpc", `String "2.0");
             ("id", `String "nested-sum");
             ("method", `String "tools/call");
             ( "params",
               `Assoc
                 [
                   ("name", `String "centl_calculate");
                   ( "arguments",
                     `Assoc
                       [
                         ( "expression",
                           `String "sum(sum(i + j, j = 1, 2), i = 1, 3)" );
                       ] );
                 ] );
           ])
    with
    | Some response -> response
    | None -> fail "MCP finite iteration produced no response"
  in
  let structured =
    response |> json_member "result" |> json_member "structuredContent"
  in
  Alcotest.(check string) "MCP nested sum" "21" (protocol_text structured)

let () =
  Alcotest.run "centl finite iteration"
    [
      ( "finite iteration",
        [
          Alcotest.test_case "low-level exact examples" `Quick exact_examples;
          Alcotest.test_case "engine exact examples" `Quick engine_examples;
          Alcotest.test_case "nested and substitution semantics" `Quick
            nested_and_substitution;
          Alcotest.test_case "session scoping" `Quick session_scoping;
          Alcotest.test_case "bounded failures" `Quick bounded_failures;
          Alcotest.test_case "engine resource limits" `Quick
            engine_resource_limits;
          Alcotest.test_case "reserved names" `Quick reserved_names;
          Alcotest.test_case "malformed parser forms" `Quick
            malformed_parser_forms;
          Alcotest.test_case "cooperative cancellation" `Quick
            cooperative_cancellation;
          Alcotest.test_case "engine cancellation" `Quick engine_cancellation;
          Alcotest.test_case "machine interfaces" `Quick machine_interfaces;
        ] );
    ]
