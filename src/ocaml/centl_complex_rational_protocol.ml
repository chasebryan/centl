type limits = {
  max_source_bytes : int;
  max_exact_bits : int;
  max_result_bytes : int;
}

let default_limits =
  {
    max_source_bytes = 32_768;
    max_exact_bits = 1_000_000;
    max_result_bytes = 1_048_576;
  }

let never_cancelled () = false

let rational_json value =
  let numerator, denominator = Centl_complex_rational.q_pair value in
  `Assoc
    [
      ("numerator", `String (Z.to_string numerator));
      ("denominator", `String (Z.to_string denominator));
      ("text", `String (Centl_complex_rational.rational_text value));
    ]

let value_json value =
  `Assoc
    [
      ("kind", `String "complex_rational");
      ("exact", `Bool true);
      ("real", rational_json value.Centl_complex_rational.real);
      ("imaginary", rational_json value.Centl_complex_rational.imaginary);
      ("text", `String (Centl_complex_rational.text value));
    ]

let provenance () =
  `Assoc
    [
      ("schema", `Int 1);
      ( "producer",
        `Assoc
          [
            ("name", `String "centl");
            ("version", `String Centl_version.value);
          ] );
      ("classification", `String "exact");
      ("method", `String "exact_complex_rational_evaluation");
      ("backend", `String "centl-exact-complex");
    ]

let error_json ?position code message =
  let fields =
    [
      ("code", `String code);
      ("message", `String message);
      ("retryable", `Bool (String.equal code "resource_limit"));
    ]
  in
  let fields =
    match position with
    | None -> fields
    | Some position -> ("position", `Int position) :: fields
  in
  `Assoc fields

let failure ?position code message =
  `Assoc
    [
      ("version", `Int 1);
      ("ok", `Bool false);
      ("error", error_json ?position code message);
      ( "provenance",
        `Assoc
          [
            ("schema", `Int 1);
            ( "producer",
              `Assoc
                [
                  ("name", `String "centl");
                  ("version", `String Centl_version.value);
                ] );
            ("classification", `String "failure");
            ("method", `String "exact_complex_rational_evaluation");
            ("backend", `String "centl-exact-complex");
          ] );
    ]

let success value =
  `Assoc
    [
      ("version", `Int 1);
      ("ok", `Bool true);
      ("value", value_json value);
      ("provenance", provenance ());
    ]

let response_size json = String.length (Yojson.Safe.to_string json)

let error_of_complex = function
  | Centl_complex_rational.Zero_denominator_literal ->
      ("zero_denominator", "a literal denominator cannot be zero")
  | Centl_complex_rational.Division_by_zero ->
      ("division_by_zero", "division by zero complex rational")
  | Centl_complex_rational.Undefined_zero_power ->
      ("undefined_power", "0^0 is undefined")
  | Centl_complex_rational.Non_rational_component component ->
      ( "unsupported_exact_complex_component",
        component ^ " must evaluate to an exact rational" )
  | Centl_complex_rational.Unsupported_expression description ->
      ( "unsupported_exact_complex_expression",
        "unsupported exact complex-rational expression: " ^ description )
  | Centl_complex_rational.Resource_limit message -> ("resource_limit", message)
  | Centl_complex_rational.Cancelled ->
      ("cancelled", "complex-rational evaluation was cancelled")

let core_limits (limits : limits) =
  let defaults = Centl_complex_rational.default_evaluation_limits in
  Centl_complex_rational.
    {
      max_exact_bits = limits.max_exact_bits;
      max_power_exponent = defaults.max_power_exponent;
      max_work = defaults.max_work;
    }

let evaluate_source ?(limits = default_limits) ?(cancelled = never_cancelled)
    source =
  if String.length source > limits.max_source_bytes then
    failure "resource_limit" "the source exceeds the exact-complex byte limit"
  else if cancelled () then
    failure "cancelled" "complex-rational evaluation was cancelled"
  else
    match Centl_parser.parse_located source with
    | Error parse_error ->
        failure ~position:parse_error.position "syntax_error" parse_error.message
    | Ok located ->
        begin match
          Centl_complex_rational.evaluate_expression ~limits:(core_limits limits)
            ~cancelled located.expression
        with
        | None ->
            failure "not_exact_complex_request"
              "the expression does not request the exact complex-rational domain"
        | Some (Error error) ->
            let code, message = error_of_complex error in
            failure code message
        | Some (Ok value) ->
            if Centl_complex_rational.exact_bits value > limits.max_exact_bits then
              failure "resource_limit"
                "the exact complex-rational result exceeds the bit limit"
            else
              let response = success value in
              if response_size response > limits.max_result_bytes then
                failure "resource_limit"
                  "the exact complex-rational result exceeds the byte limit"
              else response
        end

let request_id fields =
  match List.assoc_opt "id" fields with
  | None -> Ok None
  | Some ((`String _ | `Int _ | `Intlit _) as id) -> Ok (Some id)
  | Some _ -> Error "id must be a string or integer"

let with_id id = function
  | `Assoc fields ->
      begin match id with
      | None -> `Assoc fields
      | Some id ->
          let rec insert = function
            | [] -> [ ("id", id) ]
            | (("version", _) as version) :: rest ->
                version :: ("id", id) :: rest
            | field :: rest -> field :: insert rest
          in
          `Assoc (insert fields)
      end
  | json -> json

let handle_json ?(limits = default_limits) ?(cancelled = never_cancelled) = function
  | `Assoc fields ->
      begin match request_id fields with
      | Error message -> failure "invalid_request" message
      | Ok id ->
          let respond response = with_id id response in
          begin match
            List.find_opt
              (fun (name, _) ->
                not (List.mem name [ "version"; "id"; "expression" ]))
              fields
          with
          | Some (name, _) ->
              respond (failure "invalid_request" ("unknown field " ^ name))
          | None ->
              begin match
                ( List.assoc_opt "version" fields,
                  List.assoc_opt "expression" fields )
              with
              | Some (`Int 1), Some (`String expression) ->
                  respond (evaluate_source ~limits ~cancelled expression)
              | Some (`Int version), _ when version <> 1 ->
                  respond (failure "invalid_request" "unsupported protocol version")
              | _, None -> respond (failure "invalid_request" "missing expression")
              | _ ->
                  respond
                    (failure "invalid_request"
                       "version must be 1 and expression must be a string")
              end
          end
      end
  | _ -> failure "invalid_request" "request must be a JSON object"
