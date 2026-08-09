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

let sphere_schema =
  strict_object
    [
      ("kind", const_string "sphere_body");
      ("particle", particle_schema);
      ("radius", quantity_schema);
    ]
    [ "kind"; "particle"; "radius" ]

let sphere_world_schema =
  strict_object
    [
      ("kind", const_string "sphere_world");
      ("sphere_count", nonnegative_integer_schema);
      ("spheres", array_of sphere_schema);
    ]
    [ "kind"; "sphere_count"; "spheres" ]

let contact_summary_schema =
  strict_object
    [
      ("pair_count", nonnegative_integer_schema);
      ("separated", nonnegative_integer_schema);
      ("touching", nonnegative_integer_schema);
      ("overlapping", nonnegative_integer_schema);
    ]
    [ "pair_count"; "separated"; "touching"; "overlapping" ]

let contact_schema =
  strict_object
    [
      ("particle1_id", string_schema);
      ("particle2_id", string_schema);
      ( "relation",
        one_of
          [
            const_string "separated";
            const_string "touching";
            const_string "overlapping";
          ] );
      ("center_delta", vector_schema);
      ("distance_squared", quantity_schema);
      ("radius_sum_squared", quantity_schema);
    ]
    [
      "particle1_id";
      "particle2_id";
      "relation";
      "center_delta";
      "distance_squared";
      "radius_sum_squared";
    ]

let trust_boundary_schema =
  strict_object
    [
      ("geometry", const_string "exact_pairwise_spheres");
      ("contact_test", const_string "distance_squared_vs_radius_sum_squared");
      ("response", const_string "frictionless_elastic_normal_impulse");
      ("resolution_scope", const_string "disjoint_touching_pairs_only");
      ("overlap_policy", const_string "defer_entire_world");
      ("shared_contact_policy", const_string "defer_entire_world");
      ("continuous_collision_detection", const_bool false);
      ("penetration_correction", const_bool false);
      ("friction", const_bool false);
      ("spin", const_bool false);
    ]
    [
      "geometry";
      "contact_test";
      "response";
      "resolution_scope";
      "overlap_policy";
      "shared_contact_policy";
      "continuous_collision_detection";
      "penetration_correction";
      "friction";
      "spin";
    ]

let pair_resolution_schema =
  strict_object
    [
      ("particle1_id", string_schema);
      ("particle2_id", string_schema);
      ( "status",
        one_of
          [ const_string "resolved"; const_string "separating_or_stationary" ] );
    ]
    [ "particle1_id"; "particle2_id"; "status" ]

let invariants_schema =
  strict_object
    [ ("momentum", boolean_schema); ("kinetic_energy", boolean_schema) ]
    [ "momentum"; "kinetic_energy" ]

let analysis_schema =
  strict_object
    [
      ("kind", const_string "sphere_contact_analysis");
      ("exact", const_bool true);
      ("world", sphere_world_schema);
      ("summary", contact_summary_schema);
      ("active_contacts", array_of contact_schema);
      ("trust_boundary", trust_boundary_schema);
      ("text", string_schema);
    ]
    [
      "kind";
      "exact";
      "world";
      "summary";
      "active_contacts";
      "trust_boundary";
      "text";
    ]

let completed_resolution_schema =
  strict_object
    [
      ("kind", const_string "isolated_elastic_sphere_contact_resolution");
      ("exact", const_bool true);
      ("solver", const_string "isolated_elastic_touching_contacts");
      ("decision", const_string "completed");
      ("world_changed", boolean_schema);
      ("initial_world", sphere_world_schema);
      ("world", sphere_world_schema);
      ("initial_contact_summary", contact_summary_schema);
      ("contact_evidence", array_of contact_schema);
      ("pair_resolutions", array_of pair_resolution_schema);
      ("invariants", invariants_schema);
      ("trust_boundary", trust_boundary_schema);
      ("text", string_schema);
    ]
    [
      "kind";
      "exact";
      "solver";
      "decision";
      "world_changed";
      "initial_world";
      "world";
      "initial_contact_summary";
      "contact_evidence";
      "pair_resolutions";
      "invariants";
      "trust_boundary";
      "text";
    ]

let overlap_deferred_schema =
  strict_object
    [
      ("kind", const_string "isolated_elastic_sphere_contact_resolution");
      ("exact", const_bool true);
      ("solver", const_string "isolated_elastic_touching_contacts");
      ("decision", const_string "deferred");
      ("reason", const_string "overlap_detected");
      ("world_changed", const_bool false);
      ("world", sphere_world_schema);
      ("initial_contact_summary", contact_summary_schema);
      ("overlaps", array_of contact_schema);
      ("trust_boundary", trust_boundary_schema);
      ("text", string_schema);
    ]
    [
      "kind";
      "exact";
      "solver";
      "decision";
      "reason";
      "world_changed";
      "world";
      "initial_contact_summary";
      "overlaps";
      "trust_boundary";
      "text";
    ]

let ambiguity_deferred_schema =
  strict_object
    [
      ("kind", const_string "isolated_elastic_sphere_contact_resolution");
      ("exact", const_bool true);
      ("solver", const_string "isolated_elastic_touching_contacts");
      ("decision", const_string "deferred");
      ("reason", const_string "ambiguous_simultaneous_contacts");
      ("world_changed", const_bool false);
      ("world", sphere_world_schema);
      ("initial_contact_summary", contact_summary_schema);
      ("ambiguous_particle_ids", array_of string_schema);
      ("touching_contacts", array_of contact_schema);
      ("trust_boundary", trust_boundary_schema);
      ("text", string_schema);
    ]
    [
      "kind";
      "exact";
      "solver";
      "decision";
      "reason";
      "world_changed";
      "world";
      "initial_contact_summary";
      "ambiguous_particle_ids";
      "touching_contacts";
      "trust_boundary";
      "text";
    ]

let enhanced_capabilities_schema =
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
            ("max_contact_pairs", nonnegative_integer_schema);
          ]
          [
            "max_request_bytes";
            "max_requests";
            "max_steps";
            "max_trajectory_steps";
            "max_contact_pairs";
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

let new_success_schema =
  strict_object
    [
      ("version", const_int 1);
      ("ok", const_bool true);
      ( "physics",
        one_of
          [
            enhanced_capabilities_schema;
            analysis_schema;
            completed_resolution_schema;
            overlap_deferred_schema;
            ambiguity_deferred_schema;
          ] );
      ("provenance", provenance_schema);
    ]
    [ "version"; "ok"; "physics"; "provenance" ]

let output_schema =
  lazy (one_of [ Lazy.force Centl_physics_mcp_output.output_schema; new_success_schema ])
