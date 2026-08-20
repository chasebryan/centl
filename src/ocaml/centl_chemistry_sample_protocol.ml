open Centl_chemistry_sample

let q_string value = `String (Q.to_string value)

let root_to_yojson = function
  | Exact_rational value ->
      `Assoc
        [
          ("status", `String "available");
          ("kind", `String "exact_rational");
          ("value", q_string value);
        ]
  | Exact_sqrt_rational radicand ->
      `Assoc
        [
          ("status", `String "available");
          ("kind", `String "exact_radical");
          ("expression", `String ("sqrt(" ^ Q.to_string radicand ^ ")"));
          ("radicand", q_string radicand);
        ]

let derived_root_to_yojson = function
  | Available root -> root_to_yojson root
  | Undefined reason ->
      `Assoc [ ("status", `String "undefined"); ("reason", `String reason) ]

let linear_stat name value unit_symbol =
  ( name,
    `Assoc
      [
        ("value", q_string value);
        ("unit", `String unit_symbol);
        ("semantic_class", `String "exact");
      ] )

let variance_stat name value unit_symbol =
  ( name,
    `Assoc
      [
        ("value", q_string value);
        ("base_unit", `String unit_symbol);
        ("unit_power", `Int 2);
        ("semantic_class", `String "exact");
      ] )

let root_stat name root unit_symbol =
  let payload =
    match root_to_yojson root with
    | `Assoc fields ->
        `Assoc
          (fields
          @ [
              ("unit", `String unit_symbol);
              ("semantic_class", `String "exact");
            ])
    | _ -> assert false
  in
  (name, payload)

let derived_root_stat name root unit_symbol =
  let payload =
    match derived_root_to_yojson root with
    | `Assoc fields ->
        let extra =
          match root with
          | Available _ ->
              [
                ("unit", `String unit_symbol);
                ("semantic_class", `String "exact");
              ]
          | Undefined _ -> []
        in
        `Assoc (fields @ extra)
    | _ -> assert false
  in
  (name, payload)

let summary_to_yojson summary =
  let sample_variance =
    match summary.sample_variance with
    | None ->
        `Assoc
          [
            ("status", `String "undefined");
            ("reason", `String "requires_at_least_two_observations");
          ]
    | Some value ->
        `Assoc
          [
            ("status", `String "available");
            ("value", q_string value);
            ("base_unit", `String summary.unit_symbol);
            ("unit_power", `Int 2);
            ("semantic_class", `String "exact");
          ]
  in
  let relative_standard_deviation =
    match derived_root_to_yojson summary.relative_standard_deviation with
    | `Assoc fields ->
        let extra =
          match summary.relative_standard_deviation with
          | Available _ ->
              [
                ("unit", `String "1");
                ("semantic_class", `String "exact");
                ("representation", `String "fraction_not_percent");
              ]
          | Undefined _ -> []
        in
        `Assoc (fields @ extra)
    | _ -> assert false
  in
  `Assoc
    [
      ("version", `Int 1);
      ("kind", `String "chemistry_sample_spread");
      ("unit", `String summary.unit_symbol);
      ("n", `Int summary.n);
      ( "observations",
        `List
          (List.map
             (fun value ->
               `Assoc
                 [
                   ("value", q_string value);
                   ("unit", `String summary.unit_symbol);
                   ("semantic_class", `String "exact_input");
                 ])
             summary.observations) );
      linear_stat "sum" summary.sum summary.unit_symbol;
      ( "sum_squares",
        `Assoc
          [
            ("value", q_string summary.sum_squares);
            ("base_unit", `String summary.unit_symbol);
            ("unit_power", `Int 2);
            ("semantic_class", `String "exact");
          ] );
      linear_stat "mean" summary.mean summary.unit_symbol;
      linear_stat "median" summary.median summary.unit_symbol;
      linear_stat "minimum" summary.minimum summary.unit_symbol;
      linear_stat "maximum" summary.maximum summary.unit_symbol;
      linear_stat "range" summary.range summary.unit_symbol;
      linear_stat "median_absolute_deviation" summary.median_absolute_deviation
        summary.unit_symbol;
      variance_stat "population_variance" summary.population_variance
        summary.unit_symbol;
      root_stat "population_standard_deviation"
        summary.population_standard_deviation summary.unit_symbol;
      ("sample_variance", sample_variance);
      derived_root_stat "sample_standard_deviation"
        summary.sample_standard_deviation summary.unit_symbol;
      derived_root_stat "standard_error_of_mean" summary.standard_error_of_mean
        summary.unit_symbol;
      ("relative_standard_deviation", relative_standard_deviation);
      ( "confidence_interval",
        `Assoc
          [
            ("status", `String "not_computed");
            ("reason", `String "requires_declared_confidence_model_and_level");
          ] );
      ( "quantiles",
        `Assoc
          [
            ("status", `String "not_computed");
            ("reason", `String "requires_declared_quantile_method");
          ] );
      ( "measurement_uncertainty",
        `Assoc
          [
            ("status", `String "not_provided");
            ( "reason",
              `String
                "sample_spread_is_not_a_measurement_uncertainty_budget" );
          ] );
    ]

let error_code = function
  | Empty_sample -> "empty_sample"
  | Too_many_observations -> "too_many_observations"
  | Invalid_observation _ -> "invalid_observation"
  | Unknown_unit _ -> "unknown_unit"

let error_to_yojson error =
  `Assoc
    [
      ("version", `Int 1);
      ("kind", `String "chemistry_sample_error");
      ("code", `String (error_code error));
      ("error", `String (error_message error));
    ]

let spread_request ~unit_symbol values =
  match summarize_strings ~unit_symbol values with
  | Ok summary -> Ok (summary_to_yojson summary)
  | Error error -> Error (error_to_yojson error)
