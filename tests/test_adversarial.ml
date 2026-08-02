let check_property test = QCheck.Test.check_exn test

let member name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let is_error_object = function
  | `Assoc fields ->
      begin match
        (List.assoc_opt "code" fields, List.assoc_opt "message" fields)
      with
      | Some (`String _), Some (`String _) -> true
      | _ -> false
      end
  | _ -> false

let is_session_object = function
  | `Assoc fields ->
      begin match
        (List.assoc_opt "definitions" fields, List.assoc_opt "requests" fields)
      with
      | Some (`Int definitions), Some (`Int requests) ->
          definitions >= 0 && requests >= 0
      | _ -> false
      end
  | _ -> false

let is_protocol_response = function
  | `Assoc fields as response ->
      begin match
        ( List.assoc_opt "version" fields,
          List.assoc_opt "ok" fields,
          List.assoc_opt "session" fields )
      with
      | Some (`Int 1), Some (`Bool ok), Some session ->
          is_session_object session
          &&
          if ok then true
          else
            begin match member "error" response with
            | Some error -> is_error_object error
            | None -> false
            end
      | _ -> false
      end
  | _ -> false

let is_protocol_failure response =
  is_protocol_response response && member "ok" response = Some (`Bool false)

let escaped_string value = Printf.sprintf "%S" value

let arbitrary_bytes =
  QCheck.make ~print:escaped_string
    QCheck.Gen.(string_size ~gen:char (0 -- 256))

let parser_accepts_or_reports_bounded_error source =
  try
    match Centl_parser.parse source with
    | Ok _ -> true
    | Error (error : Centl_parser.error) ->
        error.position >= 0 && error.position <= String.length source
  with _ -> false

let parser_totality_property () =
  QCheck.Test.make ~name:"parser is total over bounded byte strings"
    ~count:2_000 arbitrary_bytes parser_accepts_or_reports_bounded_error
  |> check_property

let malformed_parser_corpus () =
  let malformed =
    [
      "";
      ".";
      "1e3";
      "1 +";
      "(1 + 2";
      "1 + 2)";
      "()";
      "f(,)";
      "x^^2";
      "1 / / 2";
      "x ! 0";
      "1 = = 1";
      "\000";
      "\255";
      String.make 512 '(' ^ "1";
    ]
  in
  List.iter
    (fun source ->
      match Centl_parser.parse source with
      | Error error ->
          Alcotest.(check bool)
            ("bounded position for " ^ escaped_string source)
            true
            (error.position >= 0 && error.position <= String.length source)
      | Ok _ ->
          Alcotest.failf "malformed parser input was accepted: %s"
            (escaped_string source))
    malformed

let left_deep_expression_is_bounded () =
  let term_count = 10_000 in
  let source = String.concat "+" (List.init term_count (Fun.const "1")) in
  match Centl_engine.evaluate source with
  | Ok (Centl_engine.Integer value) ->
      Alcotest.(check string)
        "large left-deep expression remains evaluable in one bounded pass"
        (string_of_int term_count) (Z.to_string value)
  | Ok _ -> Alcotest.fail "large exact sum returned a non-integer value"
  | Error error ->
      Alcotest.failf "large exact sum failed with %s: %s" error.code
        error.message

let repeated_derivative_binder_respects_result_limit () =
  let binder = String.make 500 'v' in
  let source = Printf.sprintf "sum(diff(foo(k), %s), k = 1, 100)" binder in
  let limits =
    { Centl_engine.default_evaluation_limits with max_result_bytes = 1_000 }
  in
  match Centl_engine.evaluate_with_limits limits source with
  | Error { code = "resource_limit"; _ } -> ()
  | Error error ->
      Alcotest.failf "long derivative binder failed with %s instead: %s"
        error.code error.message
  | Ok value ->
      Alcotest.failf "long derivative binder bypassed the byte limit: %s"
        (Centl_engine.text_of_value value)

let polynomial_integral_output_is_preflighted () =
  let limits =
    { Centl_engine.default_evaluation_limits with max_expression_nodes = 128 }
  in
  match Centl_engine.evaluate_with_limits limits "integrate(x^64, x)" with
  | Error { code = "resource_limit"; message; _ } ->
      Alcotest.(check string)
        "integration-specific output estimate"
        "the polynomial integral exceeds the expression-node limit" message
  | Error error ->
      Alcotest.failf "high-degree integral failed with %s instead: %s"
        error.code error.message
  | Ok value ->
      Alcotest.failf "high-degree integral bypassed output preflight: %s"
        (Centl_engine.text_of_value value)

let polynomial_integral_exact_bits_are_preflighted () =
  let large_coefficient = String.make 400 '9' in
  let source = Printf.sprintf "integrate(%s*x^64, x)" large_coefficient in
  let limits =
    {
      Centl_engine.default_evaluation_limits with
      max_expression_nodes = 20_000;
      max_exact_bits = 1_000;
    }
  in
  match Centl_engine.evaluate_with_limits limits source with
  | Error { code = "resource_limit"; _ } -> ()
  | Error error ->
      Alcotest.failf "large-coefficient integral failed with %s instead: %s"
        error.code error.message
  | Ok value ->
      Alcotest.failf "large-coefficient integral bypassed bit preflight: %s"
        (Centl_engine.text_of_value value)

let polynomial_integral_coprime_denominators_are_preflighted () =
  let denominators =
    [
      1009;
      1013;
      1019;
      1021;
      1031;
      1033;
      1039;
      1049;
      1051;
      1061;
      1063;
      1069;
      1087;
      1091;
      1093;
    ]
  in
  let terms =
    List.map (fun denominator -> Printf.sprintf "x/%d" denominator) denominators
  in
  let source =
    Printf.sprintf "integrate(%s, x = 0, 1)" (String.concat "+" terms)
  in
  let limits =
    { Centl_engine.default_evaluation_limits with max_exact_bits = 110 }
  in
  match Centl_engine.evaluate_with_limits limits source with
  | Error { code = "resource_limit"; message; _ } ->
      Alcotest.(check string)
        "coprime denominator growth is rejected before coefficient conversion"
        "the polynomial integral exceeds the exact-coefficient bit limit"
        message
  | Error error ->
      Alcotest.failf "coprime-denominator integral failed with %s instead: %s"
        error.code error.message
  | Ok value ->
      Alcotest.failf "coprime-denominator integral bypassed bit preflight: %s"
        (Centl_engine.text_of_value value)

let polynomial_integral_requires_a_bounded_profile () =
  let source = "integrate((x + 1)^8 / (x - x + 1), x = 0, 1)" in
  let limits =
    { Centl_engine.default_evaluation_limits with max_expression_nodes = 20 }
  in
  match Centl_engine.evaluate_with_limits limits source with
  | Ok value ->
      Alcotest.(check string)
        "an unprofiled denominator stays residual instead of entering the core"
        source
        (Centl_engine.text_of_value value)
  | Error error ->
      Alcotest.failf "unprofiled integral failed with %s: %s" error.code
        error.message

let unsupported_integral_respects_result_limit () =
  let within_limit_symbol = String.make 800 'u' in
  let within_limit_source =
    Printf.sprintf "integrate(f(%s), x)" within_limit_symbol
  in
  let limits =
    { Centl_engine.default_evaluation_limits with max_result_bytes = 1_024 }
  in
  begin match Centl_engine.evaluate_with_limits limits within_limit_source with
  | Ok value ->
      let rendered = Centl_engine.text_of_value value in
      Alcotest.(check string)
        "unsupported integral remains explicit" within_limit_source rendered;
      Alcotest.(check bool)
        "residual stays within the requested byte limit" true
        (String.length rendered <= limits.max_result_bytes)
  | Error error ->
      Alcotest.failf "bounded unsupported integral failed with %s: %s"
        error.code error.message
  end;
  let oversized_symbol = String.make 2_048 'v' in
  let oversized_source =
    Printf.sprintf "integrate(f(%s), x)" oversized_symbol
  in
  match Centl_engine.evaluate_with_limits limits oversized_source with
  | Error { code = "resource_limit"; _ } -> ()
  | Error error ->
      Alcotest.failf "oversized residual failed with %s instead: %s" error.code
        error.message
  | Ok value ->
      Alcotest.failf "unsupported integral bypassed the result-byte limit: %s"
        (Centl_engine.text_of_value value)

let integral_cancellation_precedes_extraction () =
  let cancellation_checks = ref 0 in
  let cancelled () =
    incr cancellation_checks;
    !cancellation_checks = 3
  in
  let expression =
    Centl_Core.Function
      ("integrate", [ Centl_Core.Symbol "x"; Centl_Core.Symbol "x" ])
  in
  match
    Centl_engine.resolve_with_limits ~cancelled
      Centl_engine.default_evaluation_limits expression
  with
  | Error { code = "cancelled"; _ } ->
      Alcotest.(check int)
        "top-level, body, then pre-extraction checkpoint" 3 !cancellation_checks
  | Error error ->
      Alcotest.failf "pre-integration cancellation failed with %s: %s"
        error.code error.message
  | Ok expression ->
      Alcotest.failf "integral ignored the pre-extraction cancellation: %s"
        (Centl_engine.expression_fragments expression
        |> Centl_engine.text_of_fragments)

let rational_of_dyadic mantissa exponent =
  if exponent >= 0 then Q.mul_2exp (Q.of_bigint mantissa) exponent
  else Q.div_2exp (Q.of_bigint mantissa) (-exponent)

let rational_of_enclosure_endpoint = rational_of_dyadic

let endpoint_interval ball =
  let lower, upper, exponent = Centl_arb.endpoints ball in
  let exponent = int_of_string exponent in
  ( rational_of_dyadic (Z.of_string lower) exponent,
    rational_of_dyadic (Z.of_string upper) exponent )

let endpoints_contain ball expected =
  try
    let lower, upper = endpoint_interval ball in
    Centl_arb.is_finite ball
    && Q.compare lower upper <= 0
    && Q.compare lower expected <= 0
    && Q.compare expected upper <= 0
  with _ -> false

let nonzero_small =
  QCheck.make QCheck.Gen.(oneof [ 1 -- 10_000; -10_000 -- -1 ])

let positive_small = QCheck.make QCheck.Gen.(1 -- 10_000)
let precision = QCheck.make QCheck.Gen.(8 -- 512)

let native_fraction_containment_property () =
  let input = QCheck.triple QCheck.int_small nonzero_small precision in
  QCheck.Test.make ~name:"native rational balls enclose their exact input"
    ~count:1_000 input (fun (numerator, denominator, precision) ->
      let expected = Q.make (Z.of_int numerator) (Z.of_int denominator) in
      let ball =
        Centl_arb.of_fraction (string_of_int numerator)
          (string_of_int denominator)
          precision
      in
      endpoints_contain ball expected)
  |> check_property

let native_arithmetic_containment_property () =
  let input =
    QCheck.quad QCheck.int_small positive_small nonzero_small positive_small
  in
  QCheck.Test.make ~name:"native arithmetic preserves exact containment"
    ~count:1_000 input (fun (a, b, c, d) ->
      let left_exact = Q.make (Z.of_int a) (Z.of_int b) in
      let right_exact = Q.make (Z.of_int c) (Z.of_int d) in
      let left =
        Centl_arb.of_fraction (string_of_int a) (string_of_int b) 192
      in
      let right =
        Centl_arb.of_fraction (string_of_int c) (string_of_int d) 192
      in
      endpoints_contain
        (Centl_arb.add left right 192)
        (Q.add left_exact right_exact)
      && endpoints_contain
           (Centl_arb.sub left right 192)
           (Q.sub left_exact right_exact)
      && endpoints_contain
           (Centl_arb.mul left right 192)
           (Q.mul left_exact right_exact)
      && endpoints_contain
           (Centl_arb.div left right 192)
           (Q.div left_exact right_exact))
  |> check_property

let decimal_outward_rounding_property () =
  let nonnegative_small = QCheck.make QCheck.Gen.(0 -- 10_000) in
  let exponent = QCheck.make QCheck.Gen.(-20 -- 20) in
  let digits = QCheck.make QCheck.Gen.(1 -- 30) in
  let input = QCheck.quad QCheck.int_small nonnegative_small exponent digits in
  QCheck.Test.make ~name:"verified decimal endpoints round outward" ~count:1_000
    input (fun (lower, width, exponent, digits) ->
      let lower_mantissa = Z.of_int lower in
      let upper_mantissa = Z.of_int (lower + width) in
      let lower = rational_of_enclosure_endpoint lower_mantissa exponent in
      let upper = rational_of_enclosure_endpoint upper_mantissa exponent in
      match
        Centl_engine.decimal_interval_of_dyadic lower_mantissa upper_mantissa
          exponent digits
      with
      | Error _ -> false
      | Ok (lower_text, upper_text, _) ->
          let printed_lower = Q.of_string lower_text in
          let printed_upper = Q.of_string upper_text in
          Q.compare printed_lower lower <= 0
          && Q.compare lower upper <= 0
          && Q.compare upper printed_upper <= 0
          && Q.compare printed_lower printed_upper <= 0)
  |> check_property

let malformed_native_fractions () =
  let malformed =
    [
      ("", "1");
      ("not-an-integer", "1");
      ("1.5", "2");
      ("1", "");
      ("1", "zero");
      ("1", "2x");
      ("1", "0");
      ("1", "-0");
    ]
  in
  List.iter
    (fun (numerator, denominator) ->
      let rejected =
        try
          ignore (Centl_arb.of_fraction numerator denominator 64);
          false
        with Invalid_argument _ -> true
      in
      Alcotest.(check bool)
        (Printf.sprintf "reject native fraction %S/%S" numerator denominator)
        true rejected)
    malformed

let enclosure_validator_rejects_reversed_bounds () =
  let magnitude = QCheck.make QCheck.Gen.(1 -- 1_000_000) in
  let input = QCheck.pair magnitude QCheck.int_small in
  QCheck.Test.make ~name:"enclosure validator rejects reversed endpoints"
    ~count:1_000 input (fun (distance, origin) ->
      let lower = Z.of_int (origin + distance) in
      let upper = Z.of_int origin in
      match
        Centl_Core.validate_enclosure lower upper Z.zero (Z.of_int 1_000_000)
      with
      | Centl_Core.InvalidEnclosure -> true
      | Centl_Core.ValidEnclosure _ -> false)
  |> check_property

let protocol_line_totality_property () =
  QCheck.Test.make ~name:"JSONL handler is total over bounded byte strings"
    ~count:2_000 arbitrary_bytes (fun line ->
      try
        let state = Centl_protocol.create () in
        let response = Centl_protocol.handle_line state line in
        is_protocol_response response
        && Yojson.Safe.from_string (Yojson.Safe.to_string response) = response
      with _ -> false)
  |> check_property

let invalid_json_value =
  let values : Yojson.Safe.t list =
    [
      `Null;
      `Bool false;
      `Bool true;
      `Int (-1);
      `Int 0;
      `Int 2;
      `Float 1.0;
      `String "1";
      `List [];
      `Assoc [];
    ]
  in
  QCheck.make ~print:Yojson.Safe.to_string (QCheck.Gen.oneof_list values)

let protocol_invalid_version_property () =
  QCheck.Test.make ~name:"JSONL rejects non-version-1 values" ~count:500
    invalid_json_value (fun version ->
      let state = Centl_protocol.create () in
      Centl_protocol.handle_json state
        (`Assoc [ ("version", version); ("expression", `String "1 + 1") ])
      |> is_protocol_failure)
  |> check_property

let malformed_json_protocol_corpus () =
  let malformed =
    [
      "";
      "{";
      "null";
      "[]";
      {|"request"|};
      {|{}|};
      {|{"version":1}|};
      {|{"version":"1","expression":"1 + 1"}|};
      {|{"version":1,"id":null,"expression":"1 + 1"}|};
      {|{"version":1,"id":{},"expression":"1 + 1"}|};
      {|{"version":1,"op":7}|};
      {|{"version":1,"op":"unknown"}|};
      {|{"version":1,"expression":[]}|};
      {|{"version":1,"expression":"1","limits":false}|};
      {|{"version":1,"expression":"1","limits":{"unknown":1}}|};
      {|{"version":1,"expression":"1","limits":{"max_source_bytes":0}}|};
      {|{"version":1,"op":"reset","expression":"1"}|};
    ]
  in
  List.iter
    (fun line ->
      let state = Centl_protocol.create () in
      let response = Centl_protocol.handle_line state line in
      Alcotest.(check bool)
        ("reject JSONL " ^ escaped_string line)
        true
        (is_protocol_failure response))
    malformed;
  let limits =
    { Centl_protocol.default_server_limits with max_request_bytes = 4 }
  in
  Alcotest.(check bool)
    "oversized JSONL request is structured" true
    (Centl_protocol.create ~limits ()
    |> Centl_protocol.oversized_line |> is_protocol_failure)

let is_mcp_response = function
  | `Assoc fields ->
      List.assoc_opt "jsonrpc" fields = Some (`String "2.0")
      && Option.is_some (List.assoc_opt "id" fields)
      && begin match
        (List.assoc_opt "result" fields, List.assoc_opt "error" fields)
      with
      | Some _, None -> true
      | None, Some (`Assoc error) ->
          begin match
            (List.assoc_opt "code" error, List.assoc_opt "message" error)
          with
          | Some (`Int _), Some (`String _) -> true
          | _ -> false
          end
      | _ -> false
      end
  | _ -> false

let is_mcp_notification_line line =
  try
    match Yojson.Safe.from_string line with
    | `Assoc fields ->
        List.assoc_opt "jsonrpc" fields = Some (`String "2.0")
        && begin match List.assoc_opt "method" fields with
        | Some (`String _) -> not (List.mem_assoc "id" fields)
        | _ -> false
        end
    | _ -> false
  with Yojson.Json_error _ -> false

let mcp_line_totality_property () =
  QCheck.Test.make ~name:"MCP handler is total over bounded byte strings"
    ~count:2_000 arbitrary_bytes (fun line ->
      try
        let state = Centl_mcp.create () in
        match Centl_mcp.handle_line state line with
        | None -> is_mcp_notification_line line
        | Some response ->
            is_mcp_response response
            && Yojson.Safe.from_string (Yojson.Safe.to_string response)
               = response
      with _ -> false)
  |> check_property

let mcp_error_code = function
  | `Assoc fields ->
      begin match List.assoc_opt "error" fields with
      | Some (`Assoc error) ->
          begin match List.assoc_opt "code" error with
          | Some (`Int code) -> Some code
          | _ -> None
          end
      | _ -> None
      end
  | _ -> None

let mcp_invalid_version_property () =
  QCheck.Test.make ~name:"MCP rejects invalid JSON-RPC versions" ~count:500
    invalid_json_value (fun version ->
      let state = Centl_mcp.create () in
      match
        Centl_mcp.handle_json state
          (`Assoc
             [
               ("jsonrpc", version); ("id", `Int 1); ("method", `String "ping");
             ])
      with
      | Some response -> mcp_error_code response = Some (-32600)
      | None -> false)
  |> check_property

let initialized_mcp () =
  let state = Centl_mcp.create () in
  ignore
    (Centl_mcp.handle_line state
       {|{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"adversarial-test","version":"1"}}}|});
  ignore
    (Centl_mcp.handle_line state
       {|{"jsonrpc":"2.0","method":"notifications/initialized"}|});
  state

let malformed_mcp_corpus () =
  let invalid_requests =
    [
      ("", -32700);
      ("{", -32700);
      ("null", -32600);
      ("[]", -32600);
      ({|{}|}, -32600);
      ({|{"jsonrpc":"1.0","id":1,"method":"ping"}|}, -32600);
      ({|{"jsonrpc":"2.0","id":1,"method":7}|}, -32600);
      ({|{"jsonrpc":"2.0","id":{},"method":"ping"}|}, -32600);
      ({|{"jsonrpc":"2.0","id":null,"method":"ping"}|}, -32600);
    ]
  in
  List.iter
    (fun (line, expected_code) ->
      let response =
        match Centl_mcp.handle_line (Centl_mcp.create ()) line with
        | Some response -> response
        | None -> Alcotest.failf "invalid MCP request had no response: %S" line
      in
      Alcotest.(check (option int))
        ("MCP error for " ^ escaped_string line)
        (Some expected_code) (mcp_error_code response))
    invalid_requests;
  let malformed_tools =
    [
      {|{"jsonrpc":"2.0","id":2,"method":"tools/call"}|};
      {|{"jsonrpc":"2.0","id":3,"method":"tools/call","params":null}|};
      {|{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{}}|};
      {|{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":7,"arguments":{}}}|};
      {|{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"centl_calculate","arguments":[]}}|};
      {|{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":null}}}|};
      {|{"jsonrpc":"2.0","id":8,"method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":"1","surprise":true}}}|};
      {|{"jsonrpc":"2.0","id":9,"method":"tools/call","params":{"name":"centl_reset","arguments":{"surprise":true}}}|};
    ]
  in
  let state = initialized_mcp () in
  List.iter
    (fun line ->
      let response =
        match Centl_mcp.handle_line state line with
        | Some response -> response
        | None ->
            Alcotest.failf "malformed MCP tool call had no response: %S" line
      in
      Alcotest.(check (option int))
        ("invalid MCP params for " ^ escaped_string line)
        (Some (-32602)) (mcp_error_code response))
    malformed_tools;
  let oversized = Centl_mcp.oversized_line (Centl_mcp.create ()) in
  Alcotest.(check (option int))
    "oversized MCP request" (Some (-32600))
    (Option.bind oversized mcp_error_code)

let () =
  Alcotest.run "centl adversarial"
    [
      ( "parser",
        [
          Alcotest.test_case "arbitrary bytes" `Quick parser_totality_property;
          Alcotest.test_case "malformed corpus" `Quick malformed_parser_corpus;
          Alcotest.test_case "hostile left-deep expression" `Quick
            left_deep_expression_is_bounded;
          Alcotest.test_case "repeated derivative binder byte limit" `Quick
            repeated_derivative_binder_respects_result_limit;
        ] );
      ( "native enclosure boundary",
        [
          Alcotest.test_case "fraction containment property" `Quick
            native_fraction_containment_property;
          Alcotest.test_case "arithmetic containment property" `Quick
            native_arithmetic_containment_property;
          Alcotest.test_case "decimal outward-rounding property" `Quick
            decimal_outward_rounding_property;
          Alcotest.test_case "malformed fractions" `Quick
            malformed_native_fractions;
          Alcotest.test_case "reversed endpoint property" `Quick
            enclosure_validator_rejects_reversed_bounds;
        ] );
      ( "integration boundary",
        [
          Alcotest.test_case "high-degree output preflight" `Quick
            polynomial_integral_output_is_preflighted;
          Alcotest.test_case "exact-coefficient bit preflight" `Quick
            polynomial_integral_exact_bits_are_preflighted;
          Alcotest.test_case "coprime-denominator bit preflight" `Quick
            polynomial_integral_coprime_denominators_are_preflighted;
          Alcotest.test_case "bounded profile required" `Quick
            polynomial_integral_requires_a_bounded_profile;
          Alcotest.test_case "unsupported residual byte limit" `Quick
            unsupported_integral_respects_result_limit;
          Alcotest.test_case "cancellation before extraction" `Quick
            integral_cancellation_precedes_extraction;
        ] );
      ( "JSONL",
        [
          Alcotest.test_case "arbitrary bytes" `Quick
            protocol_line_totality_property;
          Alcotest.test_case "invalid version property" `Quick
            protocol_invalid_version_property;
          Alcotest.test_case "malformed corpus" `Quick
            malformed_json_protocol_corpus;
        ] );
      ( "MCP",
        [
          Alcotest.test_case "arbitrary bytes" `Quick mcp_line_totality_property;
          Alcotest.test_case "invalid version property" `Quick
            mcp_invalid_version_property;
          Alcotest.test_case "malformed corpus" `Quick malformed_mcp_corpus;
        ] );
    ]
