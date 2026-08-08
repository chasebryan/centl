let string_schema = `Assoc [ ("type", `String "string") ]
let boolean_schema = `Assoc [ ("type", `String "boolean") ]
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
let const_int value = `Assoc [ ("const", `Int value) ]
let one_of schemas = `Assoc [ ("oneOf", `List schemas) ]
let array_of item = `Assoc [ ("type", `String "array"); ("items", item) ]

let dimension_schema =
  strict_object
    [
      ("length", `Assoc [ ("type", `String "integer") ]);
      ("mass", `Assoc [ ("type", `String "integer") ]);
      ("time", `Assoc [ ("type", `String "integer") ]);
      ("current", `Assoc [ ("type", `String "integer") ]);
      ("temperature", `Assoc [ ("type", `String "integer") ]);
      ("amount", `Assoc [ ("type", `String "integer") ]);
      ("luminous_intensity", `Assoc [ ("type", `String "integer") ]);
      ("text", string_schema);
    ]
    [
      "length";
      "mass";
      "time";
      "current";
      "temperature";
      "amount";
      "luminous_intensity";
      "text";
    ]

let quantity_schema =
  strict_object
    [
      ("kind", const_string "quantity");
      ("exact", const_bool true);
      ("value", string_schema);
      ("unit", string_schema);
      ("si_value", string_schema);
      ("dimension", dimension_schema);
      ("text", string_schema);
    ]
    [ "kind"; "exact"; "value"; "unit"; "si_value"; "dimension"; "text" ]

let vector_schema =
  strict_object
    [
      ("kind", const_string "vector3");
      ("exact", const_bool true);
      ("x", string_schema);
      ("y", string_schema);
      ("z", string_schema);
      ("unit", string_schema);
      ("dimension", dimension_schema);
      ("text", string_schema);
    ]
    [ "kind"; "exact"; "x"; "y"; "z"; "unit"; "dimension"; "text" ]

let particle_schema =
  strict_object
    [
      ("kind", const_string "particle_state");
      ("id", string_schema);
      ("mass", quantity_schema);
      ("position", vector_schema);
      ("velocity", vector_schema);
    ]
    [ "kind"; "id"; "mass"; "position"; "velocity" ]

let capabilities_schema =
  let string_array = array_of string_schema in
  strict_object
    [
      ("kind", const_string "physics_capabilities");
      ("protocol_version", const_int 1);
      ("actions", string_array);
      ("force_models", string_array);
      ("integrators", string_array);
      ("constants", string_array);
      ( "limits",
        strict_object
          [
            ("max_request_bytes", nonnegative_integer_schema);
            ("max_requests", nonnegative_integer_schema);
            ("max_steps", nonnegative_integer_schema);
            ("max_trajectory_steps", nonnegative_integer_schema);
          ]
          [
            "max_request_bytes";
            "max_requests";
            "max_steps";
            "max_trajectory_steps";
          ] );
      ("text", string_schema);
    ]
    [
      "kind";
      "protocol_version";
      "actions";
      "force_models";
      "integrators";
      "constants";
      "limits";
      "text";
    ]

let unit_schema =
  strict_object
    [
      ("symbol", string_schema);
      ("name", string_schema);
      ("scale_to_si", string_schema);
      ("dimension", dimension_schema);
    ]
    [ "symbol"; "name"; "scale_to_si"; "dimension" ]

let units_schema =
  strict_object
    [
      ("kind", const_string "physics_units");
      ("units", array_of unit_schema);
      ("text", string_schema);
    ]
    [ "kind"; "units"; "text" ]

let conversion_schema =
  strict_object
    [
      ("kind", const_string "unit_conversion");
      ("input", quantity_schema);
      ("result", string_schema);
      ("unit", string_schema);
      ("exact", const_bool true);
      ("text", string_schema);
    ]
    [ "kind"; "input"; "result"; "unit"; "exact"; "text" ]

let constant_schema =
  strict_object
    [
      ("kind", const_string "physical_constant");
      ("symbol", string_schema);
      ("name", string_schema);
      ("value", quantity_schema);
      ("provenance", string_schema);
      ("exact", boolean_schema);
      ("text", string_schema);
    ]
    [ "kind"; "symbol"; "name"; "value"; "provenance"; "exact"; "text" ]

let simulation_schema =
  strict_object
    [
      ("kind", const_string "particle_simulation");
      ("integrator", const_string "symplectic_euler");
      ("steps", nonnegative_integer_schema);
      ("dt", quantity_schema);
      ("initial", particle_schema);
      ("final", particle_schema);
      ( "diagnostics",
        strict_object
          [
            ("initial_momentum", vector_schema);
            ("final_momentum", vector_schema);
            ("initial_kinetic_energy", quantity_schema);
            ("final_kinetic_energy", quantity_schema);
          ]
          [
            "initial_momentum";
            "final_momentum";
            "initial_kinetic_energy";
            "final_kinetic_energy";
          ] );
      ("text", string_schema);
      ("trajectory", array_of particle_schema);
    ]
    [ "kind"; "integrator"; "steps"; "dt"; "initial"; "final"; "diagnostics"; "text" ]

let collision_schema =
  strict_object
    [
      ("kind", const_string "elastic_collision_1d");
      ("velocity1_final", quantity_schema);
      ("velocity2_final", quantity_schema);
      ( "invariants",
        strict_object
          [
            ("momentum", boolean_schema);
            ("kinetic_energy", boolean_schema);
            ("initial_momentum", quantity_schema);
            ("final_momentum", quantity_schema);
            ("initial_kinetic_energy", quantity_schema);
            ("final_kinetic_energy", quantity_schema);
          ]
          [
            "momentum";
            "kinetic_energy";
            "initial_momentum";
            "final_momentum";
            "initial_kinetic_energy";
            "final_kinetic_energy";
          ] );
      ("exact", const_bool true);
      ("text", string_schema);
    ]
    [ "kind"; "velocity1_final"; "velocity2_final"; "invariants"; "exact"; "text" ]

let provenance_schema =
  strict_object
    [
      ("schema", const_int 1);
      ( "producer",
        strict_object
          [ ("name", const_string "centl"); ("version", string_schema) ]
          [ "name"; "version" ] );
      ("classification", const_string "physics");
      ("method", string_schema);
      ("backend", const_string "centl-physics");
    ]
    [ "schema"; "producer"; "classification"; "method"; "backend" ]

let output_schema =
  lazy
    (let success =
       strict_object
         [
           ("version", const_int 1);
           ("ok", const_bool true);
           ( "physics",
             one_of
               [
                 capabilities_schema;
                 units_schema;
                 conversion_schema;
                 constant_schema;
                 simulation_schema;
                 collision_schema;
               ] );
           ("provenance", provenance_schema);
         ]
         [ "version"; "ok"; "physics"; "provenance" ]
     in
     let failure =
       strict_object
         [
           ("version", const_int 1);
           ("ok", const_bool false);
           ( "error",
             strict_object
               [
                 ("code", string_schema);
                 ("message", string_schema);
                 ("retryable", boolean_schema);
               ]
               [ "code"; "message"; "retryable" ] );
           ("provenance", provenance_schema);
         ]
         [ "version"; "ok"; "error"; "provenance" ]
     in
     one_of [ success; failure ])
