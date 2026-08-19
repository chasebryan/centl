type limits = {
  complex : Centl_complex_rational_protocol.limits;
  matrix : Centl_matrix_protocol.limits;
  polynomial : Centl_multivariate_polynomial_protocol.limits;
  algebraic : Centl_real_algebraic_protocol.limits;
  max_result_bytes : int;
}

let default_limits =
  {
    complex = Centl_complex_rational_protocol.default_limits;
    matrix = Centl_matrix_protocol.default_limits;
    polynomial = Centl_multivariate_polynomial_protocol.default_limits;
    algebraic = Centl_real_algebraic_protocol.default_limits;
    max_result_bytes = 1_048_576;
  }

let never_cancelled () = false

let producer =
  `Assoc
    [
      ("name", `String "centl");
      ("version", `String Centl_version.value);
    ]

let provenance classification method_ =
  `Assoc
    [
      ("schema", `Int 1);
      ("producer", producer);
      ("classification", `String classification);
      ("method", `String method_);
      ("backend", `String "centl-math-gateway");
    ]

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

let failure ?id code message =
  with_id id
    (`Assoc
       [
         ("version", `Int 1);
         ("ok", `Bool false);
         ( "error",
           `Assoc
             [
               ("code", `String code);
               ("message", `String message);
               ("retryable", `Bool (String.equal code "resource_limit"));
             ] );
         ("provenance", provenance "failure" "math_gateway_dispatch");
       ])

let check_fields allowed fields =
  match List.find_opt (fun (name, _) -> not (List.mem name allowed)) fields with
  | None -> Ok ()
  | Some (name, _) -> Error ("unknown field " ^ name)

let add_domain domain = function
  | `Assoc fields ->
      let rec insert = function
        | [] -> [ ("domain", `String domain) ]
        | (("ok", _) as ok) :: rest -> ok :: ("domain", `String domain) :: rest
        | field :: rest -> field :: insert rest
      in
      `Assoc (insert fields)
  | json -> json

let response_size response = String.length (Yojson.Safe.to_string response)

let enforce_result_limit limits ?id domain response =
  let response = add_domain domain response in
  if response_size response > limits.max_result_bytes then
    failure ?id "resource_limit"
      "the canonical mathematics response exceeds the byte limit"
  else response

let strings values = `List (List.map (fun value -> `String value) values)

let capabilities limits =
  `Assoc
    [
      ("kind", `String "centl_math_capabilities");
      ("exact_first", `Bool true);
      ("gateway_schema", `Int 1);
      ( "domains",
        `List
          [
            `Assoc
              [
                ("name", `String "complex_rational");
                ("classification", `String "exact");
                ("input", `String "CENTL expression string");
                ( "operations",
                  strings
                    [
                      "construct";
                      "add";
                      "subtract";
                      "multiply";
                      "divide";
                      "integer_power";
                      "conjugate";
                      "real_part";
                      "imaginary_part";
                      "norm2";
                    ] );
              ];
            `Assoc
              [
                ("name", `String "matrix");
                ("classification", `String "exact");
                ("input", `String "structured rational matrices");
                ( "operations",
                  strings
                    [
                      "add";
                      "subtract";
                      "scale";
                      "multiply";
                      "transpose";
                      "trace";
                      "determinant";
                      "rref";
                      "rank";
                      "inverse";
                      "solve";
                      "nullspace";
                    ] );
              ];
            `Assoc
              [
                ("name", `String "multivariate_polynomial");
                ("classification", `String "exact");
                ("input", `String "canonical sparse polynomials over Q");
                ( "operations",
                  strings
                    [
                      "add";
                      "subtract";
                      "multiply";
                      "differentiate";
                      "substitute_rationals";
                      "coefficient";
                      "coefficient_array";
                      "variables";
                      "total_degree";
                    ] );
              ];
            `Assoc
              [
                ("name", `String "real_algebraic");
                ("classification", `String "algebraic_exact");
                ("input", `String "integer polynomial plus rational interval");
                ( "operations",
                  strings [ "count_roots"; "certify"; "refine" ] );
              ];
          ] );
      ( "limits",
        `Assoc [ ("max_result_bytes", `Int limits.max_result_bytes) ] );
      ( "semantics",
        `Assoc
          [
            ("exact_inputs_stay_exact", `Bool true);
            ("floating_fallback", `Bool false);
            ("unsupported_is_explicit", `Bool true);
            ("domain_provenance_preserved", `Bool true);
          ] );
      ( "text",
        `String
          "Canonical exact-first gateway for the admitted P0 mathematics domains." );
    ]

let inner_request id fields =
  match List.assoc_opt "request" fields with
  | None -> Error "missing request"
  | Some (`Assoc inner_fields) ->
      begin match
        List.find_opt
          (fun (name, _) -> List.mem name [ "version"; "id" ])
          inner_fields
      with
      | Some (name, _) ->
          Error ("request." ^ name ^ " is owned by the mathematics gateway")
      | None ->
          let inherited_id =
            match id with None -> [] | Some id -> [ ("id", id) ]
          in
          Ok (`Assoc (("version", `Int 1) :: inherited_id @ inner_fields))
      end
  | Some _ -> Error "request must be an object"

let dispatch_domain limits ~cancelled id domain request =
  if cancelled () then failure ?id "cancelled" "the mathematics request was cancelled"
  else
    let response =
      match domain with
      | "complex_rational" ->
          Centl_complex_rational_protocol.handle_json ~limits:limits.complex request
      | "matrix" ->
          Centl_matrix_protocol.handle_json ~limits:limits.matrix ~cancelled request
      | "multivariate_polynomial" ->
          Centl_multivariate_polynomial_protocol.handle_json
            ~limits:limits.polynomial ~cancelled request
      | "real_algebraic" ->
          Centl_real_algebraic_protocol.handle_json ~limits:limits.algebraic
            ~cancelled request
      | _ ->
          failure ?id "unknown_math_domain"
            ("unknown mathematics domain " ^ domain)
    in
    enforce_result_limit limits ?id domain response

let handle_json ?(limits = default_limits) ?(cancelled = never_cancelled) = function
  | `Assoc fields ->
      begin match request_id fields with
      | Error message -> failure "invalid_request" message
      | Ok id ->
          begin match
            check_fields [ "version"; "id"; "domain"; "request" ] fields
          with
          | Error message -> failure ?id "invalid_request" message
          | Ok () ->
              begin match
                (List.assoc_opt "version" fields, List.assoc_opt "domain" fields)
              with
              | Some (`Int 1), Some (`String "capabilities") ->
                  begin match List.assoc_opt "request" fields with
                  | None | Some (`Assoc []) ->
                      let response =
                        with_id id
                          (`Assoc
                             [
                               ("version", `Int 1);
                               ("ok", `Bool true);
                               ("domain", `String "capabilities");
                               ("result", capabilities limits);
                               ( "provenance",
                                 provenance "exact"
                                   "math_gateway_capability_discovery" );
                             ])
                      in
                      if response_size response > limits.max_result_bytes then
                        failure ?id "resource_limit"
                          "the canonical mathematics response exceeds the byte limit"
                      else response
                  | Some _ ->
                      failure ?id "invalid_request"
                        "capabilities request must be omitted or empty"
                  end
              | Some (`Int 1), Some (`String domain) ->
                  begin match inner_request id fields with
                  | Error message -> failure ?id "invalid_request" message
                  | Ok request ->
                      dispatch_domain limits ~cancelled id domain request
                  end
              | Some (`Int version), _ when version <> 1 ->
                  failure ?id "invalid_request" "unsupported protocol version"
              | _, None -> failure ?id "invalid_request" "missing domain"
              | _ -> failure ?id "invalid_request" "version must be 1"
              end
          end
      end
  | _ -> failure "invalid_request" "request must be a JSON object"
