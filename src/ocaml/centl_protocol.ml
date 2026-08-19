type server_limits = {
  max_request_bytes : int;
  max_requests : int;
  evaluation : Centl_engine.evaluation_limits;
}

let default_server_limits =
  {
    max_request_bytes = 65_536;
    max_requests = 10_000;
    evaluation = Centl_engine.default_evaluation_limits;
  }

type state = {
  session : Centl_engine.session;
  limits : server_limits;
  mutable requests : int;
}

let create ?(limits = default_server_limits) () =
  { session = Centl_engine.create_session (); limits; requests = 0 }

let session state = state.session
let limits state = state.limits

let json_error code message =
  Centl_engine.json_of_evaluation (Error { code; message; position = None })

let control_provenance method_ =
  Centl_engine.json_of_provenance ~classification:"control" ~method_
    ~backend:"centl-protocol"

let rec insert_after_version id = function
  | [] -> [ ("id", id) ]
  | (("version", _) as version) :: rest -> version :: ("id", id) :: rest
  | field :: rest -> field :: insert_after_version id rest

let with_id id = function
  | `Assoc fields ->
      begin match id with
      | None -> `Assoc fields
      | Some id -> `Assoc (insert_after_version id fields)
      end
  | json -> json

let with_session state = function
  | `Assoc fields ->
      `Assoc
        (fields
        @ [
            ( "session",
              `Assoc
                [
                  ( "definitions",
                    `Int (Centl_engine.session_binding_count state.session) );
                  ("requests", `Int state.requests);
                ] );
          ])
  | json -> json

let with_provenance provenance = function
  | `Assoc fields when Option.is_none (List.assoc_opt "provenance" fields) ->
      `Assoc (fields @ [ ("provenance", provenance) ])
  | json -> json

let response state ?id ?(provenance = control_provenance "protocol_operation")
    json =
  json |> with_id id |> with_provenance provenance |> with_session state

let invalid state ?id message =
  response state ?id (json_error "invalid_request" message)

let resource_failure state ?id message =
  response state ?id (json_error "resource_limit" message)

let cancelled state ?id () =
  response state ?id (json_error "cancelled" "the request was cancelled")

let admit state =
  if state.requests >= state.limits.max_requests then false
  else begin
    state.requests <- state.requests + 1;
    true
  end

let request_id fields =
  match List.assoc_opt "id" fields with
  | None -> Ok None
  | Some ((`String _ | `Int _ | `Intlit _) as id) -> Ok (Some id)
  | Some _ -> Error "id must be a string or integer"

let cancellation_target fields =
  match List.assoc_opt "target" fields with
  | Some ((`String _ | `Int _ | `Intlit _) as target) -> Ok target
  | None -> Error "cancel requires a target request id"
  | Some _ -> Error "cancel target must be a string or integer"

let operation fields =
  match List.assoc_opt "op" fields with
  | None -> Ok "evaluate"
  | Some (`String operation) -> Ok operation
  | Some _ -> Error "op must be a string"

let cancellable_request_id = function
  | `Assoc fields ->
      begin match
        (List.assoc_opt "version" fields, operation fields, request_id fields)
      with
      | Some (`Int 1), Ok operation, Ok (Some id)
        when List.mem operation
               [ "evaluate"; "compute"; "define"; "verify"; "math" ] ->
          Some id
      | _ -> None
      end
  | _ -> None

let cancellation_target_of_json = function
  | `Assoc fields ->
      begin match
        (List.assoc_opt "version" fields, operation fields, request_id fields)
      with
      | Some (`Int 1), Ok "cancel", Ok _ ->
          Result.to_option (cancellation_target fields)
      | _ -> None
      end
  | _ -> None

let request_limits state fields =
  Centl_engine.requested_evaluation_limits ~ceiling:state.limits.evaluation
    fields

let math_gateway_limits state =
  let evaluation = state.limits.evaluation in
  let result_bytes = evaluation.max_result_bytes in
  let complex =
    Centl_complex_rational_protocol.
      {
        max_source_bytes =
          min default_limits.max_source_bytes evaluation.max_source_bytes;
        max_exact_bits =
          min default_limits.max_exact_bits evaluation.max_exact_bits;
        max_result_bytes = min default_limits.max_result_bytes result_bytes;
      }
  in
  let matrix =
    Centl_matrix_protocol.
      {
        default_limits with
        max_exact_bits =
          min default_limits.max_exact_bits evaluation.max_exact_bits;
        max_result_bytes = min default_limits.max_result_bytes result_bytes;
      }
  in
  let polynomial =
    Centl_multivariate_polynomial_protocol.
      {
        default_limits with
        max_exact_bits =
          min default_limits.max_exact_bits evaluation.max_exact_bits;
        max_result_bytes = min default_limits.max_result_bytes result_bytes;
      }
  in
  let algebraic =
    Centl_real_algebraic_protocol.
      {
        default_limits with
        max_coefficient_bits =
          min default_limits.max_coefficient_bits evaluation.max_exact_bits;
        max_endpoint_bits =
          min default_limits.max_endpoint_bits evaluation.max_exact_bits;
        max_result_bytes = min default_limits.max_result_bytes result_bytes;
      }
  in
  Centl_math_gateway.
    {
      complex;
      matrix;
      polynomial;
      algebraic;
      max_result_bytes = result_bytes;
    }

let session_result state id evaluation =
  Centl_engine.json_of_detailed_session_evaluation evaluation
  |> response state ?id

let mathematical_domains =
  let domain operation supported_domain examples =
    `Assoc
      [
        ("operation", `String operation);
        ("supported_domain", `String supported_domain);
        ("examples", `List (List.map (fun value -> `String value) examples));
      ]
  in
  `List
    [
      domain "diff" Centl_engine.differentiation_domain
        [ "diff(x^3, x)"; "diff(sin(x), x)" ];
      domain "integrate" Centl_engine.integration_domain
        [ "integrate(x^2, x)"; "integrate(x^2, x = 0, 1)" ];
      domain "simplify" Centl_engine.polynomial_domain [ "simplify(2*x + 3*x)" ];
      domain "expand" Centl_engine.polynomial_domain [ "expand((x + 1)^3)" ];
      domain "factor" Centl_engine.factor_domain [ "factor(x^2 - 1)" ];
      domain "solve" Centl_engine.equation_domain
        [ "solve(2*x + 3 = 11, x)"; "solve(x^2 = 2, x)" ];
      domain "substitute" Centl_engine.substitution_domain
        [ "substitute(x^2 + 1, x = 3)" ];
      domain "math"
        "canonical exact-first P0 mathematics gateway"
        [
          "domain=complex_rational";
          "domain=matrix";
          "domain=multivariate_polynomial";
          "domain=real_algebraic";
        ];
    ]

let resolution_statuses =
  `List
    (List.map
       (fun status -> `String status)
       [
         "computed";
         "transformed";
         "unchanged_proved";
         "residual";
         "unsupported";
         "indeterminate";
       ])

let describe state id =
  let evaluation = state.limits.evaluation in
  response state ?id
    ~provenance:(control_provenance "describe")
    (`Assoc
       [
         ("version", `Int 1);
         ("ok", `Bool true);
         ( "capabilities",
           `Assoc
             [
               ("transport", `String "jsonl");
               ("stateful", `Bool true);
               ( "operations",
                 `List
                   (List.map
                      (fun operation -> `String operation)
                      [
                        "compute";
                        "define";
                        "evaluate";
                        "verify";
                        "math";
                        "cancel";
                        "reset";
                        "describe";
                        "session";
                        "help";
                        "ping";
                      ]) );
               ("resolution_statuses", resolution_statuses);
               ("mathematical_domains", mathematical_domains);
               ( "verification_scopes",
                 `List
                   [
                     `String "closed_exact_rational";
                     `String "closed_real_enclosure";
                     `String "univariate_rational_polynomial";
                     `String "open_claim";
                     `String "quantified_claim_not_implemented";
                     `String "unsupported_assumption_domain";
                   ] );
               ( "verification_verdicts",
                 `List
                   (List.map
                      (fun value -> `String value)
                      [ "verified"; "refuted"; "unknown"; "invalid" ]) );
               ( "assurance_classes",
                 `List
                   (List.map
                      (fun value -> `String value)
                      [
                        "exact_algorithm";
                        "certified_enclosure";
                        "witness_checked";
                        "none";
                      ]) );
               ( "cancellation",
                 `Assoc
                   [
                     ("request_scoped", `Bool true);
                     ("cooperative", `Bool true);
                     ("queued_requests", `Bool true);
                   ] );
               ( "limits",
                 `Assoc
                   [
                     ("max_request_bytes", `Int state.limits.max_request_bytes);
                     ("max_requests", `Int state.limits.max_requests);
                     ("max_source_bytes", `Int evaluation.max_source_bytes);
                     ( "max_expression_nodes",
                       `Int evaluation.max_expression_nodes );
                     ("max_exact_bits", `Int evaluation.max_exact_bits);
                     ( "max_integer_iterations",
                       `Int evaluation.max_integer_iterations );
                     ("max_result_bytes", `Int evaluation.max_result_bytes);
                     ("max_bindings", `Int evaluation.max_bindings);
                     ( "max_precision_digits",
                       `Int evaluation.max_precision_digits );
                     ("max_working_bits", `Int evaluation.max_working_bits);
                   ] );
             ] );
       ])

let inspect_session state id fields =
  if Option.is_some (List.assoc_opt "expression" fields) then
    invalid state ?id "session does not accept an expression"
  else
    response state ?id
      ~provenance:(control_provenance "session_inspection")
      (`Assoc
         [
           ("version", `Int 1);
           ("ok", `Bool true);
           ( "definitions",
             Centl_engine.json_of_session_definitions state.session );
         ])

let verify_request_fields fields =
  let allowed =
    [
      "version";
      "id";
      "op";
      "limits";
      "left";
      "right";
      "relation";
      "variables";
      "assumptions";
    ]
  in
  match List.find_opt (fun (name, _) -> not (List.mem name allowed)) fields with
  | Some (name, _) -> Error ("unknown field " ^ name)
  | None ->
      Ok
        (List.filter
           (fun (name, _) ->
             List.mem name
               [ "left"; "right"; "relation"; "variables"; "assumptions" ])
           fields)

let verify ?(cancelled = Centl_engine.never_cancelled) state id fields =
  if Option.is_some (List.assoc_opt "expression" fields) then
    invalid state ?id "verify does not accept expression; use left and right"
  else
    match verify_request_fields fields with
    | Error message -> invalid state ?id message
    | Ok claim_fields ->
        begin match request_limits state fields with
        | Error message -> invalid state ?id message
        | Ok limits ->
            if cancelled () then
              response state ?id
                (Centl_engine.json_of_evaluation
                   (Error
                      {
                        Centl_engine.code = "cancelled";
                        message = "the request was cancelled";
                        position = None;
                      }))
            else
              begin match
                Centl_verify.verify ~cancelled ~limits state.session
                  claim_fields
              with
              | Error error ->
                  response state ?id
                    (Centl_engine.json_of_evaluation (Error error))
              | Ok verification ->
                  let body =
                    `Assoc
                      [
                        ("version", `Int 1);
                        ("ok", `Bool true);
                        ( "verification",
                          Centl_verify.json_of_verification verification );
                      ]
                  in
                  let response_json =
                    response state ?id
                      ~provenance:
                        (Centl_engine.json_of_provenance
                           ~classification:"verification"
                           ~method_:"claim_verification" ~backend:"centl-verify")
                      body
                  in
                  begin match
                    Centl_verify.enforce_response_limit ~cancelled limits
                      response_json
                  with
                  | Ok json -> json
                  | Error error ->
                      response state ?id
                        (Centl_engine.json_of_evaluation (Error error))
                  end
              end
        end

let help state id fields =
  if Option.is_some (List.assoc_opt "expression" fields) then
    invalid state ?id "help does not accept an expression"
  else
    match List.assoc_opt "query" fields with
    | None ->
        response state ?id
          ~provenance:(control_provenance "syntax_help")
          (`Assoc
             [
               ("version", `Int 1);
               ("ok", `Bool true);
               ("help", Centl_syntax.json_help ());
             ])
    | Some (`String query) ->
        response state ?id
          ~provenance:(control_provenance "syntax_help")
          (`Assoc
             [
               ("version", `Int 1);
               ("ok", `Bool true);
               ("help", Centl_syntax.json_help ~query ());
             ])
    | Some _ -> invalid state ?id "help query must be a string"

let evaluate ?(cancelled = Centl_engine.never_cancelled)
    ?(intent = Centl_engine.Evaluate_or_define) state id fields =
  match (List.assoc_opt "expression" fields, request_limits state fields) with
  | Some (`String expression), Ok limits ->
      Centl_engine.evaluate_in_session_outcome_with_limits ~cancelled ~intent
        limits state.session expression
      |> session_result state id
  | Some (`String _), Error message -> invalid state ?id message
  | None, _ -> invalid state ?id "missing expression"
  | Some _, _ -> invalid state ?id "expression must be a string"

let math ?(cancelled = Centl_engine.never_cancelled) state id fields =
  let allowed = [ "version"; "id"; "op"; "domain"; "request" ] in
  match List.find_opt (fun (name, _) -> not (List.mem name allowed)) fields with
  | Some (name, _) -> invalid state ?id ("unknown field " ^ name)
  | None ->
      begin match List.assoc_opt "domain" fields with
      | None -> invalid state ?id "math requires a domain"
      | Some (`String domain) ->
          let gateway_fields =
            [ ("version", `Int 1); ("domain", `String domain) ]
            @
            match List.assoc_opt "request" fields with
            | None -> []
            | Some request -> [ ("request", request) ]
          in
          Centl_math_gateway.handle_json ~limits:(math_gateway_limits state)
            ~cancelled (`Assoc gateway_fields)
          |> response state ?id
      | Some _ -> invalid state ?id "math domain must be a string"
      end

let reset state id fields =
  if Option.is_some (List.assoc_opt "expression" fields) then
    invalid state ?id "reset does not accept an expression"
  else begin
    Centl_engine.reset_session state.session;
    response state ?id
      ~provenance:(control_provenance "reset")
      (`Assoc [ ("version", `Int 1); ("ok", `Bool true); ("reset", `Bool true) ])
  end

let cancel state id fields =
  match cancellation_target fields with
  | Error message -> invalid state ?id message
  | Ok target ->
      response state ?id
        ~provenance:(control_provenance "cancel")
        (`Assoc
           [
             ("version", `Int 1);
             ("ok", `Bool true);
             ( "cancellation",
               `Assoc [ ("target", target); ("status", `String "requested") ] );
           ])

let ping state id =
  response state ?id
    ~provenance:(control_provenance "ping")
    (`Assoc [ ("version", `Int 1); ("ok", `Bool true); ("pong", `Bool true) ])

let handle_json ?(cancelled = Centl_engine.never_cancelled) state = function
  | `Assoc fields ->
      begin match request_id fields with
      | Error message -> invalid state message
      | Ok id ->
          begin match List.assoc_opt "version" fields with
          | Some (`Int 1) ->
              begin match operation fields with
              | Error message -> invalid state ?id message
              | Ok "evaluate" -> evaluate ~cancelled state id fields
              | Ok "compute" ->
                  evaluate ~cancelled ~intent:Centl_engine.Compute_only state id
                    fields
              | Ok "define" ->
                  evaluate ~cancelled ~intent:Centl_engine.Define_only state id
                    fields
              | Ok "math" -> math ~cancelled state id fields
              | Ok "cancel" -> cancel state id fields
              | Ok "reset" -> reset state id fields
              | Ok "describe" -> describe state id
              | Ok "session" -> inspect_session state id fields
              | Ok "verify" -> verify ~cancelled state id fields
              | Ok "help" -> help state id fields
              | Ok "ping" -> ping state id
              | Ok name -> invalid state ?id ("unknown operation " ^ name)
              end
          | Some (`Int _) -> invalid state ?id "unsupported protocol version"
          | _ -> invalid state ?id "version must be 1"
          end
      end
  | _ -> invalid state "request must be a JSON object"

let handle_line ?(cancelled = Centl_engine.never_cancelled) state line =
  try
    let json = Yojson.Safe.from_string line in
    if Option.is_some (cancellation_target_of_json json) then
      handle_json ~cancelled state json
    else if admit state then handle_json ~cancelled state json
    else
      let id =
        match json with
        | `Assoc fields ->
            begin match request_id fields with Ok id -> id | Error _ -> None
            end
        | _ -> None
      in
      resource_failure state ?id "the process has reached its request limit"
  with Yojson.Json_error message ->
    if admit state then invalid state ("invalid JSON: " ^ message)
    else resource_failure state "the process has reached its request limit"

let oversized_line state =
  if not (admit state) then
    resource_failure state "the process has reached its request limit"
  else resource_failure state "the request exceeds the byte limit"

let queue_overflow state line =
  let id =
    match line with
    | None -> None
    | Some line ->
        begin try
          match Yojson.Safe.from_string line with
          | `Assoc fields ->
              begin match request_id fields with Ok id -> id | Error _ -> None
              end
          | _ -> None
        with Yojson.Json_error _ -> None
        end
  in
  resource_failure state ?id "the pending request queue reached its limit"

let ok = function
  | `Assoc fields -> List.assoc_opt "ok" fields = Some (`Bool true)
  | _ -> false

let cancelled_response = function
  | `Assoc fields ->
      begin match List.assoc_opt "error" fields with
      | Some (`Assoc error) ->
          List.assoc_opt "code" error = Some (`String "cancelled")
      | _ -> false
      end
  | _ -> false

let string_field name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some (`String value) -> Some value
      | _ -> None
      end
  | _ -> None

let resolution_text_annotation = function
  | `Assoc fields ->
      begin match List.assoc_opt "resolution" fields with
      | Some (`Assoc resolution) ->
          begin match List.assoc_opt "status" resolution with
          | Some
              (`String
                 (( "unchanged_proved" | "residual" | "unsupported"
                  | "indeterminate" ) as status)) ->
              let details =
                List.filter_map Fun.id
                  [
                    Option.map
                      (fun operation -> "operation=" ^ operation)
                      (string_field "operation" (`Assoc resolution));
                    Option.map
                      (fun reason -> "reason=" ^ reason)
                      (string_field "reason" (`Assoc resolution));
                    Option.map
                      (fun domain -> "supported_domain=" ^ domain)
                      (string_field "supported_domain" (`Assoc resolution));
                  ]
              in
              Some
                (Printf.sprintf "resolution: %s%s" status
                   (match details with
                   | [] -> ""
                   | details -> " (" ^ String.concat "; " details ^ ")"))
          | _ -> None
          end
      | _ -> None
      end
  | _ -> None

let text = function
  | `Assoc fields as response ->
      let body =
        begin match List.assoc_opt "value" fields with
        | Some (`Assoc value) ->
            begin match List.assoc_opt "text" value with
            | Some (`String text) -> text
            | _ -> Yojson.Safe.to_string response
            end
        | _ ->
            begin match List.assoc_opt "verification" fields with
            | Some verification ->
                begin match
                  ( string_field "verdict" verification,
                    string_field "scope" verification,
                    string_field "method" verification )
                with
                | Some verdict, Some scope, Some method_ ->
                    let base =
                      Printf.sprintf "verdict: %s (%s via %s)" verdict scope
                        method_
                    in
                    let details =
                      match verification with
                      | `Assoc fields ->
                          begin match List.assoc_opt "evidence" fields with
                          | Some evidence ->
                              let scalar_details =
                                List.filter_map Fun.id
                                  [
                                    Option.map
                                      (fun comparison ->
                                        "comparison=" ^ comparison)
                                      (string_field "comparison" evidence);
                                    Option.map
                                      (fun reason -> "reason=" ^ reason)
                                      (string_field "reason" evidence);
                                  ]
                              in
                              let counterexample =
                                match evidence with
                                | `Assoc evidence_fields ->
                                    begin match
                                      List.assoc_opt "counterexample"
                                        evidence_fields
                                    with
                                    | Some (`Assoc counterexample_fields) ->
                                        begin match
                                          List.assoc_opt "bindings"
                                            counterexample_fields
                                        with
                                        | Some (`Assoc bindings) ->
                                            let bindings =
                                              List.filter_map
                                                (fun (name, value) ->
                                                  match value with
                                                  | `String value ->
                                                      Some (name ^ "=" ^ value)
                                                  | _ -> None)
                                                bindings
                                            in
                                            Some
                                              ("counterexample={"
                                              ^ String.concat ", " bindings
                                              ^ "}")
                                        | _ -> None
                                        end
                                    | _ -> None
                                    end
                                | _ -> None
                              in
                              scalar_details @ Option.to_list counterexample
                          | None -> []
                          end
                      | _ -> []
                    in
                    begin match details with
                    | [] -> base
                    | details -> base ^ "; " ^ String.concat "; " details
                    end
                | _ -> Yojson.Safe.to_string response
                end
            | None ->
                begin match List.assoc_opt "error" fields with
                | Some (`Assoc error) ->
                    begin match List.assoc_opt "message" error with
                    | Some (`String message) ->
                        begin match List.assoc_opt "suggestion" error with
                        | Some (`String suggestion) ->
                            message ^ "\nsuggestion: " ^ suggestion
                        | _ -> message
                        end
                    | _ -> Yojson.Safe.to_string response
                    end
                | _ -> Yojson.Safe.to_string response
                end
            end
        end
      in
      begin match resolution_text_annotation response with
      | None -> body
      | Some annotation -> body ^ "\n" ^ annotation
      end
  | json -> Yojson.Safe.to_string json

type input = End | Line of string | Oversized

let read_line channel max_bytes =
  let buffer = Buffer.create (min max_bytes 4_096) in
  let rec read length oversized =
    match input_char channel with
    | '\n' -> if oversized then Oversized else Line (Buffer.contents buffer)
    | character ->
        if length < max_bytes then Buffer.add_char buffer character;
        read (length + 1) (oversized || length >= max_bytes)
    | exception End_of_file ->
        if length = 0 && not oversized then End
        else if oversized then Oversized
        else Line (Buffer.contents buffer)
  in
  read 0 false
