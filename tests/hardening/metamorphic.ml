type interval = { lower : Q.t; upper : Q.t }

let failf format = Printf.ksprintf failwith format

let member name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let string_member context name json =
  match member name json with
  | Some (`String value) -> value
  | _ -> failf "%s has no string field %s" context name

let rational_of_dyadic mantissa exponent =
  if exponent >= 0 then Q.mul_2exp (Q.of_bigint mantissa) exponent
  else Q.div_2exp (Q.of_bigint mantissa) (-exponent)

let interval label ball =
  if not (Centl_arb.is_finite ball) then
    failf "%s returned a nonfinite ball" label;
  let lower, upper, exponent = Centl_arb.endpoints ball in
  let exponent = int_of_string exponent in
  let result =
    {
      lower = rational_of_dyadic (Z.of_string lower) exponent;
      upper = rational_of_dyadic (Z.of_string upper) exponent;
    }
  in
  if Q.compare result.lower result.upper > 0 then
    failf "%s returned reversed endpoints" label;
  result

let contains enclosure exact =
  Q.compare enclosure.lower exact <= 0 && Q.compare exact enclosure.upper <= 0

let subset inner outer =
  Q.compare outer.lower inner.lower <= 0
  && Q.compare inner.upper outer.upper <= 0

let overlaps left right =
  Q.compare left.lower right.upper <= 0 && Q.compare right.lower left.upper <= 0

let width enclosure = Q.sub enclosure.upper enclosure.lower

let require_contains label enclosure exact =
  if not (contains enclosure exact) then
    failf "%s does not contain %s" label (Q.to_string exact)

let require_refines label low high =
  if not (subset high low) then
    failf "%s higher-precision interval escaped its lower-precision interval"
      label;
  if Q.compare (width high) (width low) > 0 then
    failf "%s higher-precision interval became wider" label

let require_overlap label left right =
  if not (overlaps left right) then
    failf "%s produced disjoint intervals for an exact identity" label

let ball_of_q value precision =
  Centl_arb.of_fraction
    (Z.to_string (Q.num value))
    (Z.to_string (Q.den value))
    precision

type generator = { mutable state : int64 }

let generator seed = { state = seed }

let next generator bound =
  generator.state <-
    Int64.logand
      Int64.(add (mul generator.state 1_103_515_245L) 12_345L)
      0x7fff_ffffL;
  Int64.rem generator.state (Int64.of_int bound) |> Int64.to_int

let seeded_rationals count =
  let random = generator 0x00c_e17L in
  List.init count (fun _ ->
      let numerator = next random 20_001 - 10_000 in
      let denominator = next random 997 + 1 in
      Q.make (Z.of_int numerator) (Z.of_int denominator))

let positive value =
  if Q.sign value > 0 then value
  else Q.add (Q.abs value) (Q.make Z.one (Z.of_int 997))

let numerical_metamorphisms rationals =
  let pi_low = Centl_arb.pi 96 |> interval "pi/96" in
  let pi_high = Centl_arb.pi 384 |> interval "pi/384" in
  require_refines "pi" pi_low pi_high;
  List.iteri
    (fun index value ->
      let label operation = Printf.sprintf "%s sample %d" operation index in
      let low_rational = ball_of_q value 96 |> interval (label "rational/96") in
      let high_rational =
        ball_of_q value 384 |> interval (label "rational/384")
      in
      require_contains (label "rational/96") low_rational value;
      require_contains (label "rational/384") high_rational value;
      require_refines (label "rational") low_rational high_rational;

      let positive_value = positive value in
      let low_positive = ball_of_q positive_value 96 in
      let high_positive = ball_of_q positive_value 384 in
      let sqrt_low =
        Centl_arb.sqrt low_positive 96 |> interval (label "sqrt/96")
      in
      let sqrt_high_ball = Centl_arb.sqrt high_positive 384 in
      let sqrt_high = interval (label "sqrt/384") sqrt_high_ball in
      require_refines (label "sqrt") sqrt_low sqrt_high;
      let square =
        Centl_arb.mul sqrt_high_ball sqrt_high_ball 384
        |> interval (label "sqrt(q)^2")
      in
      require_contains (label "sqrt(q)^2") square positive_value;

      let logarithm = Centl_arb.log high_positive 384 in
      let exponential =
        Centl_arb.exp logarithm 384 |> interval (label "exp(log(q))")
      in
      require_contains (label "exp(log(q))") exponential positive_value;

      let input = ball_of_q value 256 in
      let negative = Centl_arb.neg input in
      require_overlap
        (label "sin(-q) = -sin(q)")
        (Centl_arb.sin negative 256 |> interval (label "sin(-q)"))
        (Centl_arb.sin input 256 |> Centl_arb.neg |> interval (label "-sin(q)"));
      require_overlap (label "cos(-q) = cos(q)")
        (Centl_arb.cos negative 256 |> interval (label "cos(-q)"))
        (Centl_arb.cos input 256 |> interval (label "cos(q)"));
      require_overlap
        (label "tanh(-q) = -tanh(q)")
        (Centl_arb.tanh negative 256 |> interval (label "tanh(-q)"))
        (Centl_arb.tanh input 256 |> Centl_arb.neg
        |> interval (label "-tanh(q)")))
    rationals

let initialized_mcp () =
  let state = Centl_mcp.create () in
  ignore
    (Centl_mcp.handle_json state
       (`Assoc
          [
            ("jsonrpc", `String "2.0");
            ("id", `String "metamorphic-init");
            ("method", `String "initialize");
            ( "params",
              `Assoc
                [
                  ("protocolVersion", `String "2025-11-25");
                  ("capabilities", `Assoc []);
                  ( "clientInfo",
                    `Assoc
                      [
                        ("name", `String "centl-metamorphic");
                        ("version", `String "1");
                      ] );
                ] );
          ]));
  ignore
    (Centl_mcp.handle_json state
       (`Assoc
          [
            ("jsonrpc", `String "2.0");
            ("method", `String "notifications/initialized");
          ]));
  state

let mcp_texts state id expression =
  let response =
    Centl_mcp.handle_json state
      (`Assoc
         [
           ("jsonrpc", `String "2.0");
           ("id", `Int id);
           ("method", `String "tools/call");
           ( "params",
             `Assoc
               [
                 ("name", `String "centl_calculate");
                 ("arguments", `Assoc [ ("expression", `String expression) ]);
               ] );
         ])
  in
  match response with
  | Some response ->
      let result =
        match member "result" response with
        | Some result -> result
        | None ->
            failf "MCP failed for %s: %s" expression
              (Yojson.Safe.to_string response)
      in
      let content_text =
        match member "content" result with
        | Some (`List (first :: _)) -> string_member "MCP content" "text" first
        | _ -> failf "MCP returned no text content for %s" expression
      in
      let structured_text =
        match member "structuredContent" result with
        | Some structured ->
            begin match member "value" structured with
            | Some value -> string_member "MCP structured value" "text" value
            | None -> failf "MCP returned no structured value for %s" expression
            end
        | None -> failf "MCP returned no structured content for %s" expression
      in
      (content_text, structured_text)
  | None -> failf "MCP returned no response for %s" expression

let cross_surface_agreement rationals =
  let state = initialized_mcp () in
  List.iteri
    (fun index value ->
      let numerator = Q.num value in
      let denominator = Q.den value in
      let expression =
        Printf.sprintf "(%s/%s) + (%s/%s)" (Z.to_string numerator)
          (Z.to_string denominator) (Z.to_string denominator)
          (Z.to_string numerator)
      in
      let plain =
        match Centl_engine.evaluate expression with
        | Ok value -> Centl_engine.text_of_value value
        | Error error ->
            failf "plain surface failed with %s for %s" error.code expression
      in
      let direct_json =
        match Centl_engine.evaluate expression with
        | Ok value -> Centl_engine.json_of_value value
        | Error _ -> assert false
      in
      let request_json =
        Centl_engine.evaluate_request
          (`Assoc [ ("version", `Int 1); ("expression", `String expression) ])
      in
      let request_value =
        match member "value" request_json with
        | Some value -> value
        | None -> failf "JSON request returned no value for %s" expression
      in
      let mcp_content, mcp_structured = mcp_texts state index expression in
      let surfaces =
        [
          ("direct JSON", string_member "direct JSON" "text" direct_json);
          ("request JSON", string_member "request JSON" "text" request_value);
          ("MCP content", mcp_content);
          ("MCP structured", mcp_structured);
        ]
      in
      List.iter
        (fun (surface, text) ->
          if text <> plain then
            failf "%s disagreed with plain rendering for %s: %S <> %S" surface
              expression text plain)
        surfaces)
    rationals

let () =
  let rationals = seeded_rationals 128 in
  numerical_metamorphisms rationals;
  let nonzero = List.filter (fun value -> Q.sign value <> 0) rationals in
  let cross_surface =
    let rec take count values =
      if count = 0 then []
      else
        match values with
        | [] -> []
        | value :: rest -> value :: take (count - 1) rest
    in
    take 64 nonzero
  in
  cross_surface_agreement cross_surface;
  Printf.printf
    "metamorphic suite passed: intervals=%d cross_surface=%d seed=0x00ce17\n%!"
    (List.length rationals)
    (List.length cross_surface)
