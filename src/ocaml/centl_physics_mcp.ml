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

let quantity_input_schema =
  strict_object
    [ ("value", string_schema); ("unit", string_schema) ]
    [ "value"; "unit" ]

let vector_input_schema =
  strict_object
    [
      ("x", string_schema);
      ("y", string_schema);
      ("z", string_schema);
      ("unit", string_schema);
    ]
    [ "x"; "y"; "z"; "unit" ]

let particle_input_schema =
  strict_object
    [
      ("id", string_schema);
      ("mass", quantity_input_schema);
      ("position", vector_input_schema);
      ("velocity", vector_input_schema);
    ]
    [ "mass"; "position"; "velocity" ]

let force_input_schema =
  one_of
    [
      strict_object
        [
          ("kind", const_string "constant_force");
          ("vector", vector_input_schema);
        ]
        [ "kind"; "vector" ];
      strict_object
        [
          ("kind", const_string "uniform_gravity");
          ("acceleration", vector_input_schema);
        ]
        [ "kind"; "acceleration" ];
      strict_object
        [
          ("kind", const_string "hooke_spring");
          ("anchor", vector_input_schema);
          ("stiffness", quantity_input_schema);
        ]
        [ "kind"; "anchor"; "stiffness" ];
      strict_object
        [
          ("kind", const_string "linear_drag");
          ("coefficient", quantity_input_schema);
        ]
        [ "kind"; "coefficient" ];
    ]

let input_schema =
  one_of
    [
      strict_object [ ("action", const_string "capabilities") ] [ "action" ];
      strict_object [ ("action", const_string "units") ] [ "action" ];
      strict_object
        [
          ("action", const_string "convert");
          ("value", string_schema);
          ("from_unit", string_schema);
          ("to_unit", string_schema);
        ]
        [ "action"; "value"; "from_unit"; "to_unit" ];
      strict_object
        [ ("action", const_string "constant"); ("symbol", string_schema) ]
        [ "action"; "symbol" ];
      strict_object
        [
          ("action", const_string "simulate_particle");
          ("particle", particle_input_schema);
          ("forces", array_of force_input_schema);
          ("dt", quantity_input_schema);
          ( "steps",
            `Assoc
              [
                ("type", `String "integer");
                ("minimum", `Int 0);
                ("maximum", `Int 100_000);
              ] );
          ("include_trajectory", boolean_schema);
        ]
        [ "action"; "particle"; "forces"; "dt"; "steps" ];
      strict_object
        [
          ("action", const_string "elastic_collision_1d");
          ("mass1", quantity_input_schema);
          ("velocity1", quantity_input_schema);
          ("mass2", quantity_input_schema);
          ("velocity2", quantity_input_schema);
        ]
        [ "action"; "mass1"; "velocity1"; "mass2"; "velocity2" ];
    ]
