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

let complex_resource_limits limits =
  let core = Centl_complex_rational.default_evaluation_limits in
  `Assoc
    [
      ("max_source_bytes", `Int limits.complex.max_source_bytes);
      ("max_exact_bits", `Int limits.complex.max_exact_bits);
      ("max_power_exponent", `Int core.max_power_exponent);
      ("max_work", `Int core.max_work);
      ("max_result_bytes", `Int limits.complex.max_result_bytes);
      ("cooperative_cancellation", `Bool true);
    ]

let polynomial_composition_limits limits =
  let defaults = Centl_polynomial_composition.default_limits in
  let polynomial = limits.polynomial in
  let composition =
    Centl_polynomial_composition.
      {
        max_substitutions = min defaults.max_substitutions polynomial.max_variables;
        max_power_exponent = min defaults.max_power_exponent polynomial.max_exponent;
        max_terms = min defaults.max_terms polynomial.max_terms;
        max_exact_bits = min defaults.max_exact_bits polynomial.max_exact_bits;
        max_work = min defaults.max_work polynomial.max_work;
      }
  in
  Centl_polynomial_composition_protocol.
    {
      polynomial;
      composition;
      max_result_bytes = min polynomial.max_result_bytes limits.max_result_bytes;
    }

let polynomial_composition_resource_limits limits =
  let limits = polynomial_composition_limits limits in
  `Assoc
    [
      ("max_substitutions", `Int limits.composition.max_substitutions);
      ("max_power_exponent", `Int limits.composition.max_power_exponent);
      ("max_terms", `Int limits.composition.max_terms);
      ("max_exact_bits", `Int limits.composition.max_exact_bits);
      ("max_work", `Int limits.composition.max_work);
      ("max_result_bytes", `Int limits.max_result_bytes);
      ("cooperative_cancellation", `Bool true);
    ]

let polynomial_content_limits limits =
  let defaults = Centl_polynomial_content.default_limits in
  let polynomial = limits.polynomial in
  let content =
    Centl_polynomial_content.
      {
        max_terms = min defaults.max_terms polynomial.max_terms;
        max_exact_bits = min defaults.max_exact_bits polynomial.max_exact_bits;
        max_work = min defaults.max_work polynomial.max_work;
      }
  in
  Centl_polynomial_content_protocol.
    {
      polynomial;
      content;
      max_result_bytes = min polynomial.max_result_bytes limits.max_result_bytes;
    }

let polynomial_content_resource_limits limits =
  let limits = polynomial_content_limits limits in
  `Assoc
    [
      ("max_terms", `Int limits.content.max_terms);
      ("max_exact_bits", `Int limits.content.max_exact_bits);
      ("max_work", `Int limits.content.max_work);
      ("max_result_bytes", `Int limits.max_result_bytes);
      ("cooperative_cancellation", `Bool true);
    ]

let polynomial_division_limits limits =
  let defaults = Centl_polynomial_division.default_limits in
  let polynomial = limits.polynomial in
  let division =
    Centl_polynomial_division.
      {
        max_terms = min defaults.max_terms polynomial.max_terms;
        max_exact_bits = min defaults.max_exact_bits polynomial.max_exact_bits;
        max_steps = min defaults.max_steps polynomial.max_work;
        max_work = min defaults.max_work polynomial.max_work;
      }
  in
  Centl_polynomial_division_protocol.
    {
      polynomial;
      division;
      max_result_bytes = min polynomial.max_result_bytes limits.max_result_bytes;
    }

let polynomial_division_resource_limits limits =
  let limits = polynomial_division_limits limits in
  `Assoc
    [
      ("max_terms", `Int limits.division.max_terms);
      ("max_exact_bits", `Int limits.division.max_exact_bits);
      ("max_steps", `Int limits.division.max_steps);
      ("max_work", `Int limits.division.max_work);
      ("max_result_bytes", `Int limits.max_result_bytes);
      ("cooperative_cancellation", `Bool true);
    ]

let polynomial_gcd_limits limits =
  let defaults = Centl_polynomial_gcd.default_limits in
  let polynomial = limits.polynomial in
  let division =
    Centl_polynomial_division.
      {
        max_terms = min defaults.division.max_terms polynomial.max_terms;
        max_exact_bits =
          min defaults.division.max_exact_bits polynomial.max_exact_bits;
        max_steps = min defaults.division.max_steps polynomial.max_work;
        max_work = min defaults.division.max_work polynomial.max_work;
      }
  in
  let gcd =
    Centl_polynomial_gcd.
      {
        division;
        max_euclid_steps = min defaults.max_euclid_steps polynomial.max_work;
      }
  in
  Centl_polynomial_gcd_protocol.
    {
      polynomial;
      gcd;
      max_result_bytes = min polynomial.max_result_bytes limits.max_result_bytes;
    }

let polynomial_gcd_resource_limits limits =
  let limits = polynomial_gcd_limits limits in
  `Assoc
    [
      ("max_terms", `Int limits.gcd.division.max_terms);
      ("max_exact_bits", `Int limits.gcd.division.max_exact_bits);
      ("max_division_steps", `Int limits.gcd.division.max_steps);
      ("max_euclid_steps", `Int limits.gcd.max_euclid_steps);
      ("max_work", `Int limits.gcd.division.max_work);
      ("max_result_bytes", `Int limits.max_result_bytes);
      ("cooperative_cancellation", `Bool true);
    ]

let polynomial_extended_gcd_limits limits =
  let defaults = Centl_polynomial_extended_gcd.default_limits in
  let polynomial = limits.polynomial in
  let division =
    Centl_polynomial_division.
      {
        max_terms = min defaults.division.max_terms polynomial.max_terms;
        max_exact_bits =
          min defaults.division.max_exact_bits polynomial.max_exact_bits;
        max_steps = min defaults.division.max_steps polynomial.max_work;
        max_work = min defaults.division.max_work polynomial.max_work;
      }
  in
  let extended_gcd =
    Centl_polynomial_extended_gcd.
      {
        division;
        max_euclid_steps = min defaults.max_euclid_steps polynomial.max_work;
      }
  in
  Centl_polynomial_extended_gcd_protocol.
    {
      polynomial;
      extended_gcd;
      max_result_bytes = min polynomial.max_result_bytes limits.max_result_bytes;
    }

let polynomial_extended_gcd_resource_limits limits =
  let limits = polynomial_extended_gcd_limits limits in
  `Assoc
    [
      ("max_terms", `Int limits.extended_gcd.division.max_terms);
      ("max_exact_bits", `Int limits.extended_gcd.division.max_exact_bits);
      ("max_division_steps", `Int limits.extended_gcd.division.max_steps);
      ("max_euclid_steps", `Int limits.extended_gcd.max_euclid_steps);
      ("max_work", `Int limits.extended_gcd.division.max_work);
      ("max_result_bytes", `Int limits.max_result_bytes);
      ("cooperative_cancellation", `Bool true);
    ]

let polynomial_square_free_limits limits =
  let defaults = Centl_polynomial_square_free.default_limits in
  let polynomial = limits.polynomial in
  let division =
    Centl_polynomial_division.
      {
        max_terms = min defaults.division.max_terms polynomial.max_terms;
        max_exact_bits =
          min defaults.division.max_exact_bits polynomial.max_exact_bits;
        max_steps = min defaults.division.max_steps polynomial.max_work;
        max_work = min defaults.division.max_work polynomial.max_work;
      }
  in
  let square_free =
    Centl_polynomial_square_free.
      {
        division;
        max_gcd_steps = min defaults.max_gcd_steps polynomial.max_work;
        max_factor_steps = min defaults.max_factor_steps polynomial.max_work;
      }
  in
  Centl_polynomial_square_free_protocol.
    {
      polynomial;
      square_free;
      max_result_bytes = min polynomial.max_result_bytes limits.max_result_bytes;
    }

let polynomial_square_free_resource_limits limits =
  let limits = polynomial_square_free_limits limits in
  `Assoc
    [
      ("max_terms", `Int limits.square_free.division.max_terms);
      ("max_exact_bits", `Int limits.square_free.division.max_exact_bits);
      ("max_division_steps", `Int limits.square_free.division.max_steps);
      ("max_gcd_steps", `Int limits.square_free.max_gcd_steps);
      ("max_factor_steps", `Int limits.square_free.max_factor_steps);
      ("max_work", `Int limits.square_free.division.max_work);
      ("max_result_bytes", `Int limits.max_result_bytes);
      ("cooperative_cancellation", `Bool true);
    ]

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
                ("limits", complex_resource_limits limits);
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
                ("name", `String "polynomial_composition");
                ("classification", `String "exact");
                ("input", `String "sparse Q-polynomial plus polynomial substitutions");
                ("operations", strings [ "compose" ]);
                ("limits", polynomial_composition_resource_limits limits);
              ];
            `Assoc
              [
                ("name", `String "polynomial_content");
                ("classification", `String "exact");
                ("input", `String "canonical sparse polynomial over Q");
                ("operations", strings [ "content"; "primitive_part"; "decompose" ]);
                ("limits", polynomial_content_resource_limits limits);
              ];
            `Assoc
              [
                ("name", `String "polynomial_division");
                ("classification", `String "exact");
                ("input", `String "univariate sparse Q-polynomials plus explicit variable");
                ("operations", strings [ "divide"; "quotient"; "remainder" ]);
                ("limits", polynomial_division_resource_limits limits);
              ];
            `Assoc
              [
                ("name", `String "polynomial_gcd");
                ("classification", `String "exact");
                ("input", `String "univariate sparse Q-polynomials plus explicit variable");
                ("operations", strings [ "gcd"; "coprime" ]);
                ("limits", polynomial_gcd_resource_limits limits);
              ];
            `Assoc
              [
                ("name", `String "polynomial_extended_gcd");
                ("classification", `String "exact");
                ("input", `String "univariate sparse Q-polynomials plus explicit variable");
                ("operations", strings [ "extended_gcd" ]);
                ("limits", polynomial_extended_gcd_resource_limits limits);
              ];
            `Assoc
              [
                ("name", `String "polynomial_square_free");
                ("classification", `String "exact");
                ("input", `String "univariate sparse Q-polynomial plus explicit variable");
                ("operations", strings [ "factorize" ]);
                ("limits", polynomial_square_free_resource_limits limits);
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
          Centl_complex_rational_protocol.handle_json ~limits:limits.complex
            ~cancelled request
      | "matrix" ->
          Centl_matrix_protocol.handle_json ~limits:limits.matrix ~cancelled request
      | "multivariate_polynomial" ->
          Centl_multivariate_polynomial_protocol.handle_json
            ~limits:limits.polynomial ~cancelled request
      | "polynomial_composition" ->
          Centl_polynomial_composition_protocol.handle_json
            ~limits:(polynomial_composition_limits limits) ~cancelled request
      | "polynomial_content" ->
          Centl_polynomial_content_protocol.handle_json
            ~limits:(polynomial_content_limits limits) ~cancelled request
      | "polynomial_division" ->
          Centl_polynomial_division_protocol.handle_json
            ~limits:(polynomial_division_limits limits) ~cancelled request
      | "polynomial_gcd" ->
          Centl_polynomial_gcd_protocol.handle_json
            ~limits:(polynomial_gcd_limits limits) ~cancelled request
      | "polynomial_extended_gcd" ->
          Centl_polynomial_extended_gcd_protocol.handle_json
            ~limits:(polynomial_extended_gcd_limits limits) ~cancelled request
      | "polynomial_square_free" ->
          Centl_polynomial_square_free_protocol.handle_json
            ~limits:(polynomial_square_free_limits limits) ~cancelled request
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