let protocol_version = "2025-11-25"

let supported_versions =
  [ "2025-11-25"; "2025-06-18"; "2025-03-26"; "2024-11-05" ]

type state = {
  protocol : Centl_protocol.state;
  mutable negotiated : string option;
  mutable initialized : bool;
}

let create ?limits () =
  {
    protocol = Centl_protocol.create ?limits ();
    negotiated = None;
    initialized = false;
  }

let protocol_state state = state.protocol

let jsonrpc_result id result =
  `Assoc [ ("jsonrpc", `String "2.0"); ("id", id); ("result", result) ]

let jsonrpc_error id code message =
  `Assoc
    [
      ("jsonrpc", `String "2.0");
      ("id", id);
      ("error", `Assoc [ ("code", `Int code); ("message", `String message) ]);
    ]

let request_id fields =
  match List.assoc_opt "id" fields with
  | Some ((`String _ | `Int _ | `Intlit _) as id) -> Ok (Some id)
  | Some _ -> Error "id must be a string or integer"
  | None -> Ok None

let cancellable_request_id = function
  | `Assoc fields ->
      begin match
        ( List.assoc_opt "jsonrpc" fields,
          List.assoc_opt "id" fields,
          List.assoc_opt "method" fields,
          List.assoc_opt "params" fields )
      with
      | ( Some (`String "2.0"),
          Some ((`String _ | `Int _ | `Intlit _) as id),
          Some (`String "tools/call"),
          Some (`Assoc parameters) ) ->
          begin match List.assoc_opt "name" parameters with
          | Some (`String name)
            when List.mem name
                   [ "centl_compute"; "centl_define"; "centl_calculate" ] ->
              Some id
          | _ -> None
          end
      | _ -> None
      end
  | _ -> None

let cancellation_target_of_json = function
  | `Assoc fields ->
      begin match
        ( List.assoc_opt "jsonrpc" fields,
          List.assoc_opt "id" fields,
          List.assoc_opt "method" fields,
          List.assoc_opt "params" fields )
      with
      | ( Some (`String "2.0"),
          None,
          Some (`String "notifications/cancelled"),
          Some (`Assoc parameters) ) ->
          begin match
            ( List.assoc_opt "requestId" parameters,
              List.assoc_opt "reason" parameters )
          with
          | ( Some ((`String _ | `Int _ | `Intlit _) as id),
              (None | Some (`String _)) ) ->
              Some id
          | _ -> None
          end
      | _ -> None
      end
  | _ -> None

let string_schema = `Assoc [ ("type", `String "string") ]
let integer_schema = `Assoc [ ("type", `String "integer") ]

let nonnegative_integer_schema =
  `Assoc [ ("type", `String "integer"); ("minimum", `Int 0) ]

let boolean_schema = `Assoc [ ("type", `String "boolean") ]

let integer_string_schema =
  `Assoc [ ("type", `String "string"); ("pattern", `String "^-?[0-9]+$") ]

let positive_integer_string_schema =
  `Assoc [ ("type", `String "string"); ("pattern", `String "^[1-9][0-9]*$") ]

let schema_ref name = `Assoc [ ("$ref", `String ("#/$defs/" ^ name)) ]

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
let const_int value = `Assoc [ ("const", `Int value) ]

let enum_string values =
  `Assoc
    [
      ("type", `String "string");
      ("enum", `List (List.map (fun value -> `String value) values));
    ]

let tool_output_schema =
  lazy
    (let rational_components =
       strict_object
         [
           ("numerator", integer_string_schema);
           ("denominator", positive_integer_string_schema);
         ]
         [ "numerator"; "denominator" ]
     in
     let rational_solution =
       strict_object
         [
           ("numerator", integer_string_schema);
           ("denominator", positive_integer_string_schema);
           ("text", string_schema);
         ]
         [ "numerator"; "denominator"; "text" ]
     in
     let real_quadratic_solution =
       strict_object
         [
           ("kind", const_string "real_quadratic");
           ("exact", const_bool true);
           ("branch", enum_string [ "lower"; "upper" ]);
           ("center", schema_ref "rational_components");
           ("radicand", schema_ref "rational_components");
           ("text", string_schema);
         ]
         [ "kind"; "exact"; "branch"; "center"; "radicand"; "text" ]
     in
     let condition =
       strict_object
         [
           ("left", string_schema);
           ( "relation",
             enum_string
               [
                 "equal";
                 "not_equal";
                 "less_than";
                 "less_or_equal";
                 "greater_than";
                 "greater_or_equal";
               ] );
           ("right", string_schema);
           ("text", string_schema);
         ]
         [ "left"; "relation"; "right"; "text" ]
     in
     let integer_value =
       strict_object
         [
           ("kind", const_string "integer");
           ("exact", const_bool true);
           ("value", integer_string_schema);
           ("text", string_schema);
         ]
         [ "kind"; "exact"; "value"; "text" ]
     in
     let rational_value =
       strict_object
         [
           ("kind", const_string "rational");
           ("exact", const_bool true);
           ("numerator", integer_string_schema);
           ("denominator", positive_integer_string_schema);
           ("text", string_schema);
         ]
         [ "kind"; "exact"; "numerator"; "denominator"; "text" ]
     in
     let symbolic_value =
       strict_object
         [
           ("kind", const_string "symbolic");
           ("exact", const_bool true);
           ("expression", string_schema);
           ("text", string_schema);
           ( "conditions",
             `Assoc
               [ ("type", `String "array"); ("items", schema_ref "condition") ]
           );
         ]
         [ "kind"; "exact"; "expression"; "text" ]
     in
     let sequence_value =
       strict_object
         [
           ("kind", const_string "sequence");
           ("exact", const_bool true);
           ("length", nonnegative_integer_schema);
           ( "items",
             `Assoc
               [
                 ("type", `String "array");
                 ( "items",
                   `Assoc
                     [
                       ( "oneOf",
                         `List
                           [
                             schema_ref "integer_value";
                             schema_ref "rational_value";
                             schema_ref "symbolic_value";
                           ] );
                     ] );
               ] );
           ("text", string_schema);
         ]
         [ "kind"; "exact"; "length"; "items"; "text" ]
     in
     let real_enclosure =
       let dyadic =
         strict_object
           [
             ("lower_mantissa", integer_string_schema);
             ("upper_mantissa", integer_string_schema);
             ("binary_exponent", integer_schema);
           ]
           [ "lower_mantissa"; "upper_mantissa"; "binary_exponent" ]
       in
       let decimal =
         strict_object
           [
             ("lower", string_schema);
             ("upper", string_schema);
             ("requested_significant_digits", integer_schema);
             ("certified_significant_digits", integer_schema);
           ]
           [
             "lower";
             "upper";
             "requested_significant_digits";
             "certified_significant_digits";
           ]
       in
       let precision =
         strict_object
           [
             ("working_bits", integer_schema);
             ("backend", const_string "flint-arb");
             ("rigorous", const_bool true);
           ]
           [ "working_bits"; "backend"; "rigorous" ]
       in
       strict_object
         [
           ("kind", const_string "real_enclosure");
           ("exact", const_bool false);
           ("text", string_schema);
           ("dyadic", dyadic);
           ("decimal", decimal);
           ("precision", precision);
         ]
         [ "kind"; "exact"; "text"; "dyadic"; "decimal"; "precision" ]
     in
     let solution_set =
       let equation =
         strict_object
           [ ("left", string_schema); ("right", string_schema) ]
           [ "left"; "right" ]
       in
       strict_object
         [
           ("kind", const_string "solution_set");
           ("exact", const_bool true);
           ("resolved", boolean_schema);
           ("status", enum_string [ "finite"; "none"; "all"; "unresolved" ]);
           ("variable", string_schema);
           ( "solutions",
             `Assoc
               [
                 ("type", `String "array");
                 ( "items",
                   `Assoc
                     [
                       ( "oneOf",
                         `List
                           [
                             schema_ref "rational_solution";
                             schema_ref "real_quadratic_solution";
                           ] );
                     ] );
               ] );
           ("equation", equation);
           ("text", string_schema);
         ]
         [
           "kind";
           "exact";
           "resolved";
           "status";
           "variable";
           "solutions";
           "equation";
           "text";
         ]
     in
     let value_definition =
       strict_object
         [
           ("kind", const_string "definition");
           ("exact", const_bool true);
           ("definition_kind", const_string "value");
           ("name", string_schema);
           ("value", schema_ref "mathematical_value");
           ("text", string_schema);
         ]
         [ "kind"; "exact"; "definition_kind"; "name"; "value"; "text" ]
     in
     let function_definition =
       strict_object
         [
           ("kind", const_string "definition");
           ("exact", const_bool true);
           ("definition_kind", const_string "function");
           ("name", string_schema);
           ( "parameters",
             `Assoc [ ("type", `String "array"); ("items", string_schema) ] );
           ("expression", string_schema);
           ("text", string_schema);
         ]
         [
           "kind";
           "exact";
           "definition_kind";
           "name";
           "parameters";
           "expression";
           "text";
         ]
     in
     let mathematical_value =
       `Assoc
         [
           ( "oneOf",
             `List
               [
                 schema_ref "integer_value";
                 schema_ref "rational_value";
                 schema_ref "symbolic_value";
                 schema_ref "sequence_value";
                 schema_ref "real_enclosure";
                 schema_ref "solution_set";
               ] );
         ]
     in
     let result_value =
       `Assoc
         [
           ( "oneOf",
             `List
               [
                 schema_ref "mathematical_value";
                 schema_ref "value_definition";
                 schema_ref "function_definition";
               ] );
         ]
     in
     let error =
       let range =
         strict_object
           [
             ("start", nonnegative_integer_schema);
             ("end", nonnegative_integer_schema);
           ]
           [ "start"; "end" ]
       in
       let details =
         strict_object
           [ ("category", const_string "limit"); ("limit", string_schema) ]
           [ "category"; "limit" ]
       in
       strict_object
         [
           ("code", string_schema);
           ("message", string_schema);
           ("position", nonnegative_integer_schema);
           ("range", range);
           ("retryable", boolean_schema);
           ("suggestion", string_schema);
           ("details", details);
         ]
         [ "code"; "message"; "retryable" ]
     in
     let session =
       strict_object
         [
           ("definitions", nonnegative_integer_schema);
           ("requests", nonnegative_integer_schema);
         ]
         [ "definitions"; "requests" ]
     in
     let provenance =
       let producer =
         strict_object
           [ ("name", const_string "centl"); ("version", string_schema) ]
           [ "name"; "version" ]
       in
       strict_object
         [
           ("schema", const_int 1);
           ("producer", producer);
           ("classification", string_schema);
           ("method", string_schema);
           ("backend", string_schema);
         ]
         [ "schema"; "producer"; "classification"; "method"; "backend" ]
     in
     let resolution =
       strict_object
         [
           ( "status",
             enum_string
               [
                 "computed";
                 "transformed";
                 "unchanged_proved";
                 "residual";
                 "unsupported";
                 "indeterminate";
               ] );
           ("operation", string_schema);
           ("reason", string_schema);
           ("supported_domain", string_schema);
         ]
         [ "status" ]
     in
     let definitions =
       `Assoc
         [
           ("rational_components", rational_components);
           ("rational_solution", rational_solution);
           ("real_quadratic_solution", real_quadratic_solution);
           ("condition", condition);
           ("integer_value", integer_value);
           ("rational_value", rational_value);
           ("symbolic_value", symbolic_value);
           ("sequence_value", sequence_value);
           ("real_enclosure", real_enclosure);
           ("solution_set", solution_set);
           ("value_definition", value_definition);
           ("function_definition", function_definition);
           ("mathematical_value", mathematical_value);
           ("result_value", result_value);
           ("error", error);
           ("session", session);
           ("provenance", provenance);
           ("resolution", resolution);
         ]
     in
     `Assoc
       [
         ("$defs", definitions);
         ("type", `String "object");
         ("additionalProperties", `Bool false);
         ( "properties",
           `Assoc
             [
               ("version", const_int 1);
               ("ok", boolean_schema);
               ("value", schema_ref "result_value");
               ("error", schema_ref "error");
               ("session", schema_ref "session");
               ("provenance", schema_ref "provenance");
               ("resolution", schema_ref "resolution");
             ] );
         ( "required",
           `List
             [
               `String "version";
               `String "ok";
               `String "session";
               `String "provenance";
             ] );
         ( "oneOf",
           `List
             [
               `Assoc
                 [
                   ("properties", `Assoc [ ("ok", const_bool true) ]);
                   ("required", `List [ `String "value"; `String "resolution" ]);
                   ("not", `Assoc [ ("required", `List [ `String "error" ]) ]);
                 ];
               `Assoc
                 [
                   ("properties", `Assoc [ ("ok", const_bool false) ]);
                   ("required", `List [ `String "error" ]);
                   ("not", `Assoc [ ("required", `List [ `String "value" ]) ]);
                 ];
             ] );
       ])

let replace_association name value fields =
  List.map
    (fun ((field_name, _) as field) ->
      if field_name = name then (name, value) else field)
    fields

let restrict_result_value result_value =
  match Lazy.force tool_output_schema with
  | `Assoc fields ->
      let definitions =
        match List.assoc_opt "$defs" fields with
        | Some (`Assoc definitions) ->
            `Assoc (replace_association "result_value" result_value definitions)
        | _ -> assert false
      in
      `Assoc (replace_association "$defs" definitions fields)
  | _ -> assert false

let compute_output_schema =
  lazy (restrict_result_value (schema_ref "mathematical_value"))

let define_output_schema =
  lazy
    (restrict_result_value
       (`Assoc
          [
            ( "oneOf",
              `List
                [
                  schema_ref "value_definition";
                  schema_ref "function_definition";
                ] );
          ]))

let protocol_session_schema =
  strict_object
    [
      ("definitions", nonnegative_integer_schema);
      ("requests", nonnegative_integer_schema);
    ]
    [ "definitions"; "requests" ]

let control_provenance_schema method_ =
  strict_object
    [
      ("schema", const_int 1);
      ( "producer",
        strict_object
          [ ("name", const_string "centl"); ("version", string_schema) ]
          [ "name"; "version" ] );
      ("classification", const_string "control");
      ("method", const_string method_);
      ("backend", const_string "centl-protocol");
    ]
    [ "schema"; "producer"; "classification"; "method"; "backend" ]

let capabilities_output_schema =
  lazy
    (let string_array =
       `Assoc [ ("type", `String "array"); ("items", string_schema) ]
     in
     let domain =
       strict_object
         [
           ("operation", string_schema);
           ("supported_domain", string_schema);
           ("examples", string_array);
         ]
         [ "operation"; "supported_domain"; "examples" ]
     in
     let cancellation =
       strict_object
         [
           ("request_scoped", boolean_schema);
           ("cooperative", boolean_schema);
           ("queued_requests", boolean_schema);
         ]
         [ "request_scoped"; "cooperative"; "queued_requests" ]
     in
     let limits =
       strict_object
         [
           ("max_request_bytes", nonnegative_integer_schema);
           ("max_requests", nonnegative_integer_schema);
           ("max_source_bytes", nonnegative_integer_schema);
           ("max_expression_nodes", nonnegative_integer_schema);
           ("max_exact_bits", nonnegative_integer_schema);
           ("max_integer_iterations", nonnegative_integer_schema);
           ("max_result_bytes", nonnegative_integer_schema);
           ("max_bindings", nonnegative_integer_schema);
           ("max_precision_digits", nonnegative_integer_schema);
           ("max_working_bits", nonnegative_integer_schema);
         ]
         [
           "max_request_bytes";
           "max_requests";
           "max_source_bytes";
           "max_expression_nodes";
           "max_exact_bits";
           "max_integer_iterations";
           "max_result_bytes";
           "max_bindings";
           "max_precision_digits";
           "max_working_bits";
         ]
     in
     let capabilities =
       strict_object
         [
           ("transport", const_string "jsonl");
           ("stateful", const_bool true);
           ("operations", string_array);
           ("resolution_statuses", string_array);
           ( "mathematical_domains",
             `Assoc [ ("type", `String "array"); ("items", domain) ] );
           ("cancellation", cancellation);
           ("limits", limits);
         ]
         [
           "transport";
           "stateful";
           "operations";
           "resolution_statuses";
           "mathematical_domains";
           "cancellation";
           "limits";
         ]
     in
     strict_object
       [
         ("version", const_int 1);
         ("ok", const_bool true);
         ("capabilities", capabilities);
         ("provenance", control_provenance_schema "describe");
         ("session", protocol_session_schema);
       ]
       [ "version"; "ok"; "capabilities"; "provenance"; "session" ])

let session_output_schema =
  lazy
    (let string_array =
       `Assoc [ ("type", `String "array"); ("items", string_schema) ]
     in
     let definition =
       strict_object
         [
           ("kind", enum_string [ "value"; "function" ]);
           ("name", string_schema);
           ("parameters", string_array);
           ("expression", string_schema);
           ("dependencies", string_array);
         ]
         [ "kind"; "name"; "expression"; "dependencies" ]
     in
     strict_object
       [
         ("version", const_int 1);
         ("ok", const_bool true);
         ( "definitions",
           `Assoc [ ("type", `String "array"); ("items", definition) ] );
         ("provenance", control_provenance_schema "session_inspection");
         ("session", protocol_session_schema);
       ]
       [ "version"; "ok"; "definitions"; "provenance"; "session" ])

let help_output_schema =
  lazy
    (let entry =
       strict_object
         [
           ("section", string_schema);
           ("form", string_schema);
           ("meaning", string_schema);
         ]
         [ "section"; "form"; "meaning" ]
     in
     let example =
       strict_object
         [
           ("kind", string_schema);
           ("calculation", string_schema);
           ("result", string_schema);
         ]
         [ "kind"; "calculation"; "result" ]
     in
     let help =
       strict_object
         [
           ("query", string_schema);
           ("entries", `Assoc [ ("type", `String "array"); ("items", entry) ]);
           ("examples", `Assoc [ ("type", `String "array"); ("items", example) ]);
         ]
         [ "entries"; "examples" ]
     in
     strict_object
       [
         ("version", const_int 1);
         ("ok", const_bool true);
         ("help", help);
         ("provenance", control_provenance_schema "syntax_help");
         ("session", protocol_session_schema);
       ]
       [ "version"; "ok"; "help"; "provenance"; "session" ])

let reset_output_schema =
  lazy
    (let session =
       strict_object
         [
           ("definitions", nonnegative_integer_schema);
           ("requests", nonnegative_integer_schema);
         ]
         [ "definitions"; "requests" ]
     in
     let producer =
       strict_object
         [ ("name", const_string "centl"); ("version", string_schema) ]
         [ "name"; "version" ]
     in
     let provenance =
       strict_object
         [
           ("schema", const_int 1);
           ("producer", producer);
           ("classification", const_string "control");
           ("method", const_string "reset");
           ("backend", const_string "centl-protocol");
         ]
         [ "schema"; "producer"; "classification"; "method"; "backend" ]
     in
     strict_object
       [
         ("version", const_int 1);
         ("ok", const_bool true);
         ("reset", const_bool true);
         ("session", session);
         ("provenance", provenance);
       ]
       [ "version"; "ok"; "reset"; "session"; "provenance" ])

let limits_schema =
  let integer minimum maximum description =
    `Assoc
      [
        ("type", `String "integer");
        ("minimum", `Int minimum);
        ("maximum", `Int maximum);
        ("description", `String description);
      ]
  in
  let limits = Centl_protocol.default_server_limits.evaluation in
  `Assoc
    [
      ("type", `String "object");
      ("additionalProperties", `Bool false);
      ( "properties",
        `Assoc
          [
            ( "max_source_bytes",
              integer 1 limits.max_source_bytes
                "Maximum UTF-8 source bytes for this calculation." );
            ( "max_expression_nodes",
              integer 1 limits.max_expression_nodes
                "Maximum expression nodes after session expansion." );
            ( "max_exact_bits",
              integer 1 limits.max_exact_bits
                "Maximum aggregate exact-result bits, checked before and after \
                 evaluation." );
            ( "max_integer_iterations",
              integer 1 limits.max_integer_iterations
                "Maximum iterations for factorial, combinatorics, or sequences."
            );
            ( "max_result_bytes",
              integer 1 limits.max_result_bytes
                "Maximum serialized mathematical-value bytes and retained \
                 session-value bytes." );
            ( "max_bindings",
              integer 0 limits.max_bindings
                "Maximum immutable definitions in this session." );
            ( "max_precision_digits",
              integer 1 limits.max_precision_digits
                "Maximum requested significant decimal digits." );
            ( "max_working_bits",
              integer 64 limits.max_working_bits
                "Maximum Arb working precision in bits." );
          ] );
    ]

let calculate_tool () =
  `Assoc
    [
      ("name", `String "centl_calculate");
      ("title", `String "Calculate with CENTL");
      ( "description",
        `String
          "Evaluate exact mathematics or define an immutable session value or \
           function. Quadratic equations return certified exact rational or \
           real-quadratic solutions; approximation is rigorous and explicit." );
      ( "inputSchema",
        `Assoc
          [
            ("type", `String "object");
            ("additionalProperties", `Bool false);
            ( "properties",
              `Assoc
                [
                  ( "expression",
                    `Assoc
                      [
                        ("type", `String "string");
                        ( "description",
                          `String "A CENTL expression or definition." );
                      ] );
                  ("limits", limits_schema);
                ] );
            ("required", `List [ `String "expression" ]);
          ] );
      ("outputSchema", Lazy.force tool_output_schema);
      ( "annotations",
        `Assoc
          [
            ("readOnlyHint", `Bool false);
            ("destructiveHint", `Bool false);
            ("idempotentHint", `Bool false);
            ("openWorldHint", `Bool false);
          ] );
    ]

let compute_tool () =
  `Assoc
    [
      ("name", `String "centl_compute");
      ("title", `String "Compute with CENTL");
      ( "description",
        `String
          "Read-only exact, symbolic, or rigorously enclosed mathematical \
           computation. Rejects definitions and reports explicit \
           transformation resolution." );
      ( "inputSchema",
        strict_object
          [
            ( "expression",
              `Assoc
                [
                  ("type", `String "string");
                  ( "description",
                    `String "A CENTL expression, not a definition." );
                ] );
            ("limits", limits_schema);
          ]
          [ "expression" ] );
      ("outputSchema", Lazy.force compute_output_schema);
      ( "annotations",
        `Assoc
          [
            ("readOnlyHint", `Bool true);
            ("destructiveHint", `Bool false);
            ("idempotentHint", `Bool true);
            ("openWorldHint", `Bool false);
          ] );
    ]

let define_tool () =
  `Assoc
    [
      ("name", `String "centl_define");
      ("title", `String "Define immutable CENTL state");
      ( "description",
        `String
          "Create one immutable session value or function definition. Rejects \
           ordinary expressions." );
      ( "inputSchema",
        strict_object
          [
            ( "definition",
              `Assoc
                [
                  ("type", `String "string");
                  ( "description",
                    `String "A CENTL immutable value or function definition." );
                ] );
            ("limits", limits_schema);
          ]
          [ "definition" ] );
      ("outputSchema", Lazy.force define_output_schema);
      ( "annotations",
        `Assoc
          [
            ("readOnlyHint", `Bool false);
            ("destructiveHint", `Bool false);
            ("idempotentHint", `Bool false);
            ("openWorldHint", `Bool false);
          ] );
    ]

let read_only_annotations =
  `Assoc
    [
      ("readOnlyHint", `Bool true);
      ("destructiveHint", `Bool false);
      ("idempotentHint", `Bool true);
      ("openWorldHint", `Bool false);
    ]

let capabilities_tool () =
  `Assoc
    [
      ("name", `String "centl_capabilities");
      ("title", `String "Describe CENTL capabilities");
      ( "description",
        `String
          "Return supported mathematical domains, resolution statuses, \
           operations, cancellation behavior, and hard limits." );
      ("inputSchema", strict_object [] []);
      ("outputSchema", Lazy.force capabilities_output_schema);
      ("annotations", read_only_annotations);
    ]

let session_tool () =
  `Assoc
    [
      ("name", `String "centl_session");
      ("title", `String "Inspect CENTL session");
      ( "description",
        `String
          "Return immutable session definitions and their direct dependencies \
           without mutating state." );
      ("inputSchema", strict_object [] []);
      ("outputSchema", Lazy.force session_output_schema);
      ("annotations", read_only_annotations);
    ]

let help_tool () =
  `Assoc
    [
      ("name", `String "centl_help");
      ("title", `String "Get focused CENTL syntax help");
      ( "description",
        `String
          "Search CENTL's canonical syntax catalog by operation, form, or \
           meaning." );
      ( "inputSchema",
        strict_object
          [
            ( "query",
              `Assoc
                [
                  ("type", `String "string");
                  ( "description",
                    `String "Optional syntax or operation search text." );
                ] );
          ]
          [] );
      ("outputSchema", Lazy.force help_output_schema);
      ("annotations", read_only_annotations);
    ]

let reset_tool () =
  `Assoc
    [
      ("name", `String "centl_reset");
      ("title", `String "Reset CENTL session");
      ("description", `String "Forget every definition in this CENTL process.");
      ( "inputSchema",
        `Assoc
          [
            ("type", `String "object");
            ("properties", `Assoc []);
            ("additionalProperties", `Bool false);
          ] );
      ("outputSchema", Lazy.force reset_output_schema);
      ( "annotations",
        `Assoc
          [
            ("readOnlyHint", `Bool false);
            ("destructiveHint", `Bool true);
            ("idempotentHint", `Bool true);
            ("openWorldHint", `Bool false);
          ] );
    ]

let initialize state id fields =
  if Option.is_some state.negotiated then
    jsonrpc_error id (-32600) "CENTL is already initialized"
  else
    match List.assoc_opt "params" fields with
    | Some (`Assoc parameters) ->
        begin match
          ( List.assoc_opt "protocolVersion" parameters,
            List.assoc_opt "capabilities" parameters,
            List.assoc_opt "clientInfo" parameters )
        with
        | Some (`String requested), Some (`Assoc _), Some (`Assoc client_info)
          when match
                 ( List.assoc_opt "name" client_info,
                   List.assoc_opt "version" client_info )
               with
               | Some (`String _), Some (`String _) -> true
               | _ -> false ->
            let negotiated =
              if List.mem requested supported_versions then requested
              else protocol_version
            in
            state.negotiated <- Some negotiated;
            jsonrpc_result id
              (`Assoc
                 [
                   ("protocolVersion", `String negotiated);
                   ( "capabilities",
                     `Assoc
                       [ ("tools", `Assoc [ ("listChanged", `Bool false) ]) ] );
                   ( "serverInfo",
                     `Assoc
                       [
                         ("name", `String "centl");
                         ("title", `String "CENTL exact mathematics");
                         ("version", `String Centl_version.value);
                       ] );
                   ( "instructions",
                     `String
                       "Use read-only centl_compute for mathematics and \
                        centl_define for immutable session definitions. \
                        centl_calculate remains available for compatibility. \
                        Definitions persist until centl_reset or process exit."
                   );
                 ])
        | _ ->
            jsonrpc_error id (-32602)
              "initialize requires protocolVersion, capabilities, and \
               clientInfo"
        end
    | _ -> jsonrpc_error id (-32602) "initialize requires params"

let tool_result protocol_response =
  let succeeded = Centl_protocol.ok protocol_response in
  `Assoc
    [
      ( "content",
        `List
          [
            `Assoc
              [
                ("type", `String "text");
                ("text", `String (Centl_protocol.text protocol_response));
              ];
          ] );
      ("structuredContent", protocol_response);
      ("isError", `Bool (not succeeded));
    ]

let cancelled_response = function
  | Some (`Assoc fields) ->
      begin match List.assoc_opt "result" fields with
      | Some (`Assoc result) ->
          begin match List.assoc_opt "structuredContent" result with
          | Some structured -> Centl_protocol.cancelled_response structured
          | None -> false
          end
      | _ -> false
      end
  | _ -> false

let evaluate_tool ?(cancelled = Centl_engine.never_cancelled) ~tool_name
    ~operation ~argument_name state id arguments =
  let unknown =
    List.find_opt
      (fun (name, _) -> not (List.mem name [ argument_name; "limits" ]))
      arguments
  in
  match (unknown, List.assoc_opt argument_name arguments) with
  | Some (name, _), _ ->
      jsonrpc_error id (-32602) ("unknown " ^ tool_name ^ " argument " ^ name)
  | None, Some (`String expression) ->
      let fields =
        [ ("version", `Int 1); ("expression", `String expression) ]
      in
      let fields =
        if operation = "evaluate" then fields
        else fields @ [ ("op", `String operation) ]
      in
      let fields =
        match List.assoc_opt "limits" arguments with
        | None -> fields
        | Some limits -> fields @ [ ("limits", limits) ]
      in
      begin match Centl_protocol.request_limits state.protocol fields with
      | Error message -> jsonrpc_error id (-32602) message
      | Ok _ ->
          Centl_protocol.handle_json ~cancelled state.protocol (`Assoc fields)
          |> tool_result |> jsonrpc_result id
      end
  | None, _ ->
      jsonrpc_error id (-32602) (tool_name ^ " requires " ^ argument_name)

let calculate ?cancelled state id arguments =
  evaluate_tool ?cancelled ~tool_name:"centl_calculate" ~operation:"evaluate"
    ~argument_name:"expression" state id arguments

let compute ?cancelled state id arguments =
  evaluate_tool ?cancelled ~tool_name:"centl_compute" ~operation:"compute"
    ~argument_name:"expression" state id arguments

let define ?cancelled state id arguments =
  evaluate_tool ?cancelled ~tool_name:"centl_define" ~operation:"define"
    ~argument_name:"definition" state id arguments

let protocol_control state id operation fields =
  Centl_protocol.handle_json state.protocol
    (`Assoc (("version", `Int 1) :: ("op", `String operation) :: fields))
  |> tool_result |> jsonrpc_result id

let capabilities state id arguments =
  if arguments <> [] then
    jsonrpc_error id (-32602) "centl_capabilities accepts no arguments"
  else protocol_control state id "describe" []

let inspect_session state id arguments =
  if arguments <> [] then
    jsonrpc_error id (-32602) "centl_session accepts no arguments"
  else protocol_control state id "session" []

let help state id arguments =
  let unknown = List.find_opt (fun (name, _) -> name <> "query") arguments in
  match (unknown, List.assoc_opt "query" arguments) with
  | Some (name, _), _ ->
      jsonrpc_error id (-32602) ("unknown centl_help argument " ^ name)
  | None, None -> protocol_control state id "help" []
  | None, Some (`String query) ->
      protocol_control state id "help" [ ("query", `String query) ]
  | None, Some _ ->
      jsonrpc_error id (-32602) "centl_help query must be a string"

let reset state id arguments =
  if arguments <> [] then
    jsonrpc_error id (-32602) "centl_reset accepts no arguments"
  else
    Centl_protocol.handle_json state.protocol
      (`Assoc [ ("version", `Int 1); ("op", `String "reset") ])
    |> tool_result |> jsonrpc_result id

let call_tool ?(cancelled = Centl_engine.never_cancelled) state id fields =
  match List.assoc_opt "params" fields with
  | Some (`Assoc parameters) ->
      begin match
        (List.assoc_opt "name" parameters, List.assoc_opt "arguments" parameters)
      with
      | Some (`String "centl_compute"), Some (`Assoc arguments) ->
          compute ~cancelled state id arguments
      | Some (`String "centl_compute"), None ->
          jsonrpc_error id (-32602) "centl_compute requires arguments"
      | Some (`String "centl_define"), Some (`Assoc arguments) ->
          define ~cancelled state id arguments
      | Some (`String "centl_define"), None ->
          jsonrpc_error id (-32602) "centl_define requires arguments"
      | Some (`String "centl_capabilities"), Some (`Assoc arguments) ->
          capabilities state id arguments
      | Some (`String "centl_capabilities"), None -> capabilities state id []
      | Some (`String "centl_session"), Some (`Assoc arguments) ->
          inspect_session state id arguments
      | Some (`String "centl_session"), None -> inspect_session state id []
      | Some (`String "centl_help"), Some (`Assoc arguments) ->
          help state id arguments
      | Some (`String "centl_help"), None -> help state id []
      | Some (`String "centl_calculate"), Some (`Assoc arguments) ->
          calculate ~cancelled state id arguments
      | Some (`String "centl_calculate"), None ->
          jsonrpc_error id (-32602) "centl_calculate requires arguments"
      | Some (`String "centl_reset"), Some (`Assoc arguments) ->
          reset state id arguments
      | Some (`String "centl_reset"), None -> reset state id []
      | Some (`String name), _ ->
          jsonrpc_error id (-32602) ("unknown tool " ^ name)
      | _ -> jsonrpc_error id (-32602) "tools/call requires a tool name"
      end
  | _ -> jsonrpc_error id (-32602) "tools/call requires params"

let handle_request ?(cancelled = Centl_engine.never_cancelled) state id
    method_name fields =
  match method_name with
  | "initialize" -> initialize state id fields
  | "ping" -> jsonrpc_result id (`Assoc [])
  | _ when not state.initialized ->
      jsonrpc_error id (-32002) "CENTL is not initialized"
  | "tools/list" ->
      jsonrpc_result id
        (`Assoc
           [
             ( "tools",
               `List
                 [
                   compute_tool ();
                   define_tool ();
                   capabilities_tool ();
                   session_tool ();
                   help_tool ();
                   calculate_tool ();
                   reset_tool ();
                 ] );
           ])
  | "tools/call" -> call_tool ~cancelled state id fields
  | _ -> jsonrpc_error id (-32601) ("method not found: " ^ method_name)

let handle_notification state method_name =
  match method_name with
  | "notifications/initialized" when Option.is_some state.negotiated ->
      state.initialized <- true
  | "notifications/cancelled" -> ()
  | _ -> ()

let handle_json ?(cancelled = Centl_engine.never_cancelled) state = function
  | `Assoc fields ->
      begin match
        (List.assoc_opt "jsonrpc" fields, List.assoc_opt "method" fields)
      with
      | Some (`String "2.0"), Some (`String method_name) ->
          begin match request_id fields with
          | Error message -> Some (jsonrpc_error `Null (-32600) message)
          | Ok (Some id) ->
              Some (handle_request ~cancelled state id method_name fields)
          | Ok None ->
              handle_notification state method_name;
              None
          end
      | _ -> Some (jsonrpc_error `Null (-32600) "invalid JSON-RPC request")
      end
  | _ -> Some (jsonrpc_error `Null (-32600) "invalid JSON-RPC request")

let handle_line ?(cancelled = Centl_engine.never_cancelled) state line =
  try
    let json = Yojson.Safe.from_string line in
    if Option.is_some (cancellation_target_of_json json) then
      handle_json ~cancelled state json
    else if Centl_protocol.admit state.protocol then
      handle_json ~cancelled state json
    else
      match json with
      | `Assoc fields ->
          begin match request_id fields with
          | Ok None -> None
          | Ok (Some id) ->
              Some
                (jsonrpc_error id (-32000)
                   "the process has reached its request limit")
          | Error message -> Some (jsonrpc_error `Null (-32600) message)
          end
      | _ -> Some (jsonrpc_error `Null (-32600) "invalid JSON-RPC request")
  with Yojson.Json_error _ ->
    if Centl_protocol.admit state.protocol then
      Some (jsonrpc_error `Null (-32700) "parse error")
    else
      Some
        (jsonrpc_error `Null (-32000)
           "the process has reached its request limit")

let oversized_line state =
  ignore (Centl_protocol.admit state.protocol);
  Some (jsonrpc_error `Null (-32600) "the request exceeds the byte limit")

let queue_overflow = function
  | None ->
      Some
        (jsonrpc_error `Null (-32000)
           "the pending request queue reached its limit")
  | Some line ->
      begin try
        match Yojson.Safe.from_string line with
        | `Assoc fields ->
            begin match request_id fields with
            | Ok (Some id) ->
                Some
                  (jsonrpc_error id (-32000)
                     "the pending request queue reached its limit")
            | Ok None -> None
            | Error message -> Some (jsonrpc_error `Null (-32600) message)
            end
        | _ -> Some (jsonrpc_error `Null (-32600) "invalid JSON-RPC request")
      with Yojson.Json_error _ ->
        Some (jsonrpc_error `Null (-32700) "parse error")
      end
