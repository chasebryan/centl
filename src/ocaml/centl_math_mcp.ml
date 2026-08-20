let string_schema = `Assoc [ ("type", `String "string") ]
let integer_schema = `Assoc [ ("type", `String "integer") ]
let boolean_schema = `Assoc [ ("type", `String "boolean") ]
let object_schema = `Assoc [ ("type", `String "object") ]

let nonnegative_integer_schema =
  `Assoc [ ("type", `String "integer"); ("minimum", `Int 0) ]

let strict_object properties required =
  `Assoc
    [
      ("type", `String "object");
      ("additionalProperties", `Bool false);
      ("properties", `Assoc properties);
      ("required", `List (List.map (fun name -> `String name) required));
    ]

let const_string value = `Assoc [ ("const", `String value) ]
let const_bool value = `Assoc [ ("const", `Bool value) ]
let one_of schemas = `Assoc [ ("oneOf", `List schemas) ]
let array_of item = `Assoc [ ("type", `String "array"); ("items", item) ]

let rational_schema = string_schema
let matrix_schema = array_of (array_of rational_schema)
let vector_schema = array_of rational_schema
let integer_polynomial_schema = array_of string_schema

let power_schema =
  strict_object
    [
      ("variable", string_schema);
      ("exponent", nonnegative_integer_schema);
    ]
    [ "variable"; "exponent" ]

let polynomial_term_schema =
  strict_object
    [
      ("coefficient", rational_schema);
      ("powers", array_of power_schema);
    ]
    [ "coefficient"; "powers" ]

let polynomial_schema =
  strict_object [ ("terms", array_of polynomial_term_schema) ] [ "terms" ]

let substitution_schema =
  strict_object
    [ ("variable", string_schema); ("value", rational_schema) ]
    [ "variable"; "value" ]

let polynomial_substitution_schema =
  strict_object
    [ ("variable", string_schema); ("polynomial", polynomial_schema) ]
    [ "variable"; "polynomial" ]

let complex_request_schema =
  strict_object [ ("expression", string_schema) ] [ "expression" ]

let matrix_request_schema =
  one_of
    [
      strict_object [ ("action", const_string "capabilities") ] [ "action" ];
      strict_object
        [
          ("action", const_string "add");
          ("left", matrix_schema);
          ("right", matrix_schema);
        ]
        [ "action"; "left"; "right" ];
      strict_object
        [
          ("action", const_string "subtract");
          ("left", matrix_schema);
          ("right", matrix_schema);
        ]
        [ "action"; "left"; "right" ];
      strict_object
        [
          ("action", const_string "multiply");
          ("left", matrix_schema);
          ("right", matrix_schema);
        ]
        [ "action"; "left"; "right" ];
      strict_object
        [
          ("action", const_string "scale");
          ("matrix", matrix_schema);
          ("scalar", rational_schema);
        ]
        [ "action"; "matrix"; "scalar" ];
      strict_object
        [ ("action", const_string "transpose"); ("matrix", matrix_schema) ]
        [ "action"; "matrix" ];
      strict_object
        [ ("action", const_string "trace"); ("matrix", matrix_schema) ]
        [ "action"; "matrix" ];
      strict_object
        [ ("action", const_string "determinant"); ("matrix", matrix_schema) ]
        [ "action"; "matrix" ];
      strict_object
        [ ("action", const_string "rref"); ("matrix", matrix_schema) ]
        [ "action"; "matrix" ];
      strict_object
        [ ("action", const_string "rank"); ("matrix", matrix_schema) ]
        [ "action"; "matrix" ];
      strict_object
        [ ("action", const_string "inverse"); ("matrix", matrix_schema) ]
        [ "action"; "matrix" ];
      strict_object
        [
          ("action", const_string "solve");
          ("matrix", matrix_schema);
          ("rhs", vector_schema);
        ]
        [ "action"; "matrix"; "rhs" ];
      strict_object
        [ ("action", const_string "nullspace"); ("matrix", matrix_schema) ]
        [ "action"; "matrix" ];
    ]

let polynomial_request_schema =
  one_of
    [
      strict_object [ ("action", const_string "capabilities") ] [ "action" ];
      strict_object
        [
          ("action", const_string "add");
          ("left", polynomial_schema);
          ("right", polynomial_schema);
        ]
        [ "action"; "left"; "right" ];
      strict_object
        [
          ("action", const_string "subtract");
          ("left", polynomial_schema);
          ("right", polynomial_schema);
        ]
        [ "action"; "left"; "right" ];
      strict_object
        [
          ("action", const_string "multiply");
          ("left", polynomial_schema);
          ("right", polynomial_schema);
        ]
        [ "action"; "left"; "right" ];
      strict_object
        [
          ("action", const_string "differentiate");
          ("polynomial", polynomial_schema);
          ("variable", string_schema);
        ]
        [ "action"; "polynomial"; "variable" ];
      strict_object
        [
          ("action", const_string "substitute_rationals");
          ("polynomial", polynomial_schema);
          ("substitutions", array_of substitution_schema);
        ]
        [ "action"; "polynomial"; "substitutions" ];
      strict_object
        [
          ("action", const_string "coefficient");
          ("polynomial", polynomial_schema);
          ("powers", array_of power_schema);
        ]
        [ "action"; "polynomial"; "powers" ];
      strict_object
        [
          ("action", const_string "coefficient_array");
          ("polynomial", polynomial_schema);
        ]
        [ "action"; "polynomial" ];
      strict_object
        [
          ("action", const_string "variables");
          ("polynomial", polynomial_schema);
        ]
        [ "action"; "polynomial" ];
      strict_object
        [
          ("action", const_string "total_degree");
          ("polynomial", polynomial_schema);
        ]
        [ "action"; "polynomial" ];
    ]

let polynomial_composition_request_schema =
  one_of
    [
      strict_object [ ("action", const_string "capabilities") ] [ "action" ];
      strict_object
        [
          ("action", const_string "compose");
          ("polynomial", polynomial_schema);
          ("substitutions", array_of polynomial_substitution_schema);
        ]
        [ "action"; "polynomial"; "substitutions" ];
    ]

let polynomial_content_request_schema =
  one_of
    [
      strict_object [ ("action", const_string "capabilities") ] [ "action" ];
      strict_object
        [
          ("action", const_string "content");
          ("polynomial", polynomial_schema);
        ]
        [ "action"; "polynomial" ];
      strict_object
        [
          ("action", const_string "primitive_part");
          ("polynomial", polynomial_schema);
        ]
        [ "action"; "polynomial" ];
      strict_object
        [
          ("action", const_string "decompose");
          ("polynomial", polynomial_schema);
        ]
        [ "action"; "polynomial" ];
    ]

let polynomial_division_request_schema =
  let operation action =
    strict_object
      [
        ("action", const_string action);
        ("variable", string_schema);
        ("dividend", polynomial_schema);
        ("divisor", polynomial_schema);
      ]
      [ "action"; "variable"; "dividend"; "divisor" ]
  in
  one_of
    [
      strict_object [ ("action", const_string "capabilities") ] [ "action" ];
      operation "divide";
      operation "quotient";
      operation "remainder";
    ]

let polynomial_gcd_request_schema =
  let operation action =
    strict_object
      [
        ("action", const_string action);
        ("variable", string_schema);
        ("left", polynomial_schema);
        ("right", polynomial_schema);
      ]
      [ "action"; "variable"; "left"; "right" ]
  in
  one_of
    [
      strict_object [ ("action", const_string "capabilities") ] [ "action" ];
      operation "gcd";
      operation "coprime";
    ]

let polynomial_extended_gcd_request_schema =
  one_of
    [
      strict_object [ ("action", const_string "capabilities") ] [ "action" ];
      strict_object
        [
          ("action", const_string "extended_gcd");
          ("variable", string_schema);
          ("left", polynomial_schema);
          ("right", polynomial_schema);
        ]
        [ "action"; "variable"; "left"; "right" ];
    ]

let polynomial_square_free_request_schema =
  one_of
    [
      strict_object [ ("action", const_string "capabilities") ] [ "action" ];
      strict_object
        [
          ("action", const_string "factorize");
          ("variable", string_schema);
          ("polynomial", polynomial_schema);
        ]
        [ "action"; "variable"; "polynomial" ];
    ]

let algebraic_request_schema =
  one_of
    [
      strict_object [ ("action", const_string "capabilities") ] [ "action" ];
      strict_object
        [
          ("action", const_string "count_roots");
          ("polynomial", integer_polynomial_schema);
          ("lower", rational_schema);
          ("upper", rational_schema);
        ]
        [ "action"; "polynomial"; "lower"; "upper" ];
      strict_object
        [
          ("action", const_string "certify");
          ("polynomial", integer_polynomial_schema);
          ("lower", rational_schema);
          ("upper", rational_schema);
        ]
        [ "action"; "polynomial"; "lower"; "upper" ];
      strict_object
        [
          ("action", const_string "refine");
          ("polynomial", integer_polynomial_schema);
          ("lower", rational_schema);
          ("upper", rational_schema);
          ("steps", nonnegative_integer_schema);
        ]
        [ "action"; "polynomial"; "lower"; "upper"; "steps" ];
    ]

let input_schema =
  one_of
    [
      strict_object [ ("domain", const_string "capabilities") ] [ "domain" ];
      strict_object
        [
          ("domain", const_string "complex_rational");
          ("request", complex_request_schema);
        ]
        [ "domain"; "request" ];
      strict_object
        [
          ("domain", const_string "matrix");
          ("request", matrix_request_schema);
        ]
        [ "domain"; "request" ];
      strict_object
        [
          ("domain", const_string "multivariate_polynomial");
          ("request", polynomial_request_schema);
        ]
        [ "domain"; "request" ];
      strict_object
        [
          ("domain", const_string "polynomial_composition");
          ("request", polynomial_composition_request_schema);
        ]
        [ "domain"; "request" ];
      strict_object
        [
          ("domain", const_string "polynomial_content");
          ("request", polynomial_content_request_schema);
        ]
        [ "domain"; "request" ];
      strict_object
        [
          ("domain", const_string "polynomial_division");
          ("request", polynomial_division_request_schema);
        ]
        [ "domain"; "request" ];
      strict_object
        [
          ("domain", const_string "polynomial_gcd");
          ("request", polynomial_gcd_request_schema);
        ]
        [ "domain"; "request" ];
      strict_object
        [
          ("domain", const_string "polynomial_extended_gcd");
          ("request", polynomial_extended_gcd_request_schema);
        ]
        [ "domain"; "request" ];
      strict_object
        [
          ("domain", const_string "polynomial_square_free");
          ("request", polynomial_square_free_request_schema);
        ]
        [ "domain"; "request" ];
      strict_object
        [
          ("domain", const_string "real_algebraic");
          ("request", algebraic_request_schema);
        ]
        [ "domain"; "request" ];
    ]

let provenance_schema = object_schema
let domain_payload_schema = object_schema

let error_schema =
  strict_object
    [
      ("code", string_schema);
      ("message", string_schema);
      ("retryable", boolean_schema);
    ]
    [ "code"; "message"; "retryable" ]

let output_schema =
  one_of
    [
      strict_object
        [
          ("version", integer_schema);
          ("ok", const_bool true);
          ("domain", string_schema);
          ("value", domain_payload_schema);
          ("provenance", provenance_schema);
        ]
        [ "version"; "ok"; "domain"; "value"; "provenance" ];
      strict_object
        [
          ("version", integer_schema);
          ("ok", const_bool true);
          ("domain", string_schema);
          ("result", domain_payload_schema);
          ("provenance", provenance_schema);
        ]
        [ "version"; "ok"; "domain"; "result"; "provenance" ];
      strict_object
        [
          ("version", integer_schema);
          ("ok", const_bool false);
          ("domain", string_schema);
          ("error", error_schema);
          ("provenance", provenance_schema);
        ]
        [ "version"; "ok"; "domain"; "error"; "provenance" ];
      strict_object
        [
          ("version", integer_schema);
          ("ok", const_bool false);
          ("error", error_schema);
          ("provenance", provenance_schema);
        ]
        [ "version"; "ok"; "error"; "provenance" ];
    ]

let read_only_annotations =
  `Assoc
    [
      ("readOnlyHint", `Bool true);
      ("destructiveHint", `Bool false);
      ("idempotentHint", `Bool true);
      ("openWorldHint", `Bool false);
    ]

let tool_description =
  "Use CENTL's canonical exact-first P0 mathematics gateway. Compute exact complex-rational arithmetic, exact dense rational matrix and linear-system operations, canonical sparse multivariate polynomial operations, exact simultaneous polynomial composition, exact polynomial content and primitive-part decomposition, exact univariate polynomial quotient and remainder, exact monic polynomial gcd and coprimality, exact polynomial extended-gcd Bézout certificates, exact square-free multiplicity-group factorization over Q, or Sturm-certified real algebraic root isolation. Square-free groups are not claimed to be irreducible factors. Unsupported inputs and resource boundaries remain explicit; the tool never silently falls back from exact mathematics to floating point."

let tool () =
  `Assoc
    [
      ("name", `String "centl_math");
      ("title", `String "Compute with CENTL Mathematics");
      ("description", `String tool_description);
      ("inputSchema", input_schema);
      ("outputSchema", output_schema);
      ("annotations", read_only_annotations);
    ]

let ok = function
  | `Assoc fields -> List.assoc_opt "ok" fields = Some (`Bool true)
  | _ -> false

let request_of_arguments arguments =
  match List.assoc_opt "domain" arguments with
  | Some (`String domain) ->
      begin match
        List.find_opt
          (fun (name, _) -> not (List.mem name [ "domain"; "request" ]))
          arguments
      with
      | Some (name, _) -> Error ("unknown centl_math argument " ^ name)
      | None ->
          if String.equal domain "capabilities" then
            begin match List.assoc_opt "request" arguments with
            | None ->
                Ok
                  (`Assoc
                     [ ("version", `Int 1); ("domain", `String domain) ])
            | Some _ -> Error "centl_math capabilities does not accept request"
            end
          else if
            not
              (List.mem domain
                 [
                   "complex_rational";
                   "matrix";
                   "multivariate_polynomial";
                   "polynomial_composition";
                   "polynomial_content";
                   "polynomial_division";
                   "polynomial_gcd";
                   "polynomial_extended_gcd";
                   "polynomial_square_free";
                   "real_algebraic";
                 ])
          then Error ("unknown centl_math domain " ^ domain)
          else
            begin match List.assoc_opt "request" arguments with
            | Some (`Assoc _ as request) ->
                Ok
                  (`Assoc
                     [
                       ("version", `Int 1);
                       ("domain", `String domain);
                       ("request", request);
                     ])
            | None -> Error ("centl_math " ^ domain ^ " requires request")
            | Some _ -> Error "centl_math request must be an object"
            end
      end
  | Some _ -> Error "centl_math domain must be a string"
  | None -> Error "centl_math requires domain"

let validate_arguments arguments =
  match request_of_arguments arguments with
  | Ok _ -> Ok ()
  | Error _ as error -> error

let call ?(limits = Centl_math_gateway.default_limits)
    ?(cancelled = Centl_engine.never_cancelled) arguments =
  match request_of_arguments arguments with
  | Error message ->
      `Assoc
        [
          ("version", `Int 1);
          ("ok", `Bool false);
          ( "error",
            `Assoc
              [
                ("code", `String "invalid_request");
                ("message", `String message);
                ("retryable", `Bool false);
              ] );
          ( "provenance",
            Centl_engine.json_of_provenance ~classification:"failure"
              ~method_:"mcp_math_argument_validation" ~backend:"centl-mcp" );
        ]
  | Ok request -> Centl_math_gateway.handle_json ~limits ~cancelled request

let nested_text field response =
  match response with
  | `Assoc fields ->
      begin match List.assoc_opt field fields with
      | Some (`Assoc payload) ->
          begin match List.assoc_opt "text" payload with
          | Some (`String text) -> Some text
          | _ -> None
          end
      | _ -> None
      end
  | _ -> None

let text response =
  match nested_text "value" response with
  | Some text -> text
  | None ->
      begin match nested_text "result" response with
      | Some text -> text
      | None ->
          begin match response with
          | `Assoc fields ->
              begin match List.assoc_opt "error" fields with
              | Some (`Assoc error) ->
                  begin match List.assoc_opt "message" error with
                  | Some (`String message) -> message
                  | _ -> Yojson.Safe.to_string response
                  end
              | _ -> Yojson.Safe.to_string response
              end
          | _ -> Yojson.Safe.to_string response
          end
      end
