open Centl_physics_contact_mcp_output

let null_schema = `Assoc [ ("type", `String "null") ]

let linear_contact_status_schema =
  one_of
    [
      const_string "initially_overlapping";
      const_string "touching_at_start";
      const_string "no_contact_in_interval";
      const_string "tangent_contact";
      const_string "crossing_contact";
    ]

let polynomial_schema =
  strict_object
    [ ("a", quantity_schema); ("b", quantity_schema); ("c", quantity_schema) ]
    [ "a"; "b"; "c" ]

let rational_bracket_schema =
  strict_object
    [ ("lower", quantity_schema); ("upper", quantity_schema) ]
    [ "lower"; "upper" ]

let rational_contact_time_schema =
  strict_object
    [ ("kind", const_string "rational"); ("time", quantity_schema) ]
    [ "kind"; "time" ]

let quadratic_irrational_contact_time_schema =
  strict_object
    [
      ("kind", const_string "quadratic_irrational");
      ("polynomial", polynomial_schema);
      ("discriminant", quantity_schema);
      ("rational_bracket", rational_bracket_schema);
    ]
    [ "kind"; "polynomial"; "discriminant"; "rational_bracket" ]

let first_contact_time_schema =
  one_of
    [
      null_schema;
      rational_contact_time_schema;
      quadratic_irrational_contact_time_schema;
    ]

let discriminant_schema = one_of [ null_schema; quantity_schema ]

let linear_contact_trust_boundary_schema =
  strict_object
    [
      ("motion_model", const_string "constant_velocity");
      ("geometry", const_string "exact_sphere_pair");
      ("interval", const_string "bounded_nonnegative_rational_time");
      ("contact_test", const_string "exact_squared_clearance_quadratic");
      ("time_sampling", const_bool false);
      ("floating_point_root_finding", const_bool false);
      ("force_integration", const_bool false);
      ("automatic_response", const_bool false);
      ("simultaneous_contact_solving", const_bool false);
    ]
    [
      "motion_model";
      "geometry";
      "interval";
      "contact_test";
      "time_sampling";
      "floating_point_root_finding";
      "force_integration";
      "automatic_response";
      "simultaneous_contact_solving";
    ]

let certificate_schema =
  strict_object
    [
      ("kind", const_string "linear_sphere_contact_certificate");
      ("exact", const_bool true);
      ("model", const_string "constant_velocity");
      ("particle1_id", string_schema);
      ("particle2_id", string_schema);
      ("duration", quantity_schema);
      ("status", linear_contact_status_schema);
      ("polynomial", polynomial_schema);
      ("closest_time", quantity_schema);
      ("minimum_clearance_squared", quantity_schema);
      ("discriminant", discriminant_schema);
      ("first_contact_time", first_contact_time_schema);
      ("trust_boundary", linear_contact_trust_boundary_schema);
      ("text", string_schema);
    ]
    [
      "kind";
      "exact";
      "model";
      "particle1_id";
      "particle2_id";
      "duration";
      "status";
      "polynomial";
      "closest_time";
      "minimum_clearance_squared";
      "discriminant";
      "first_contact_time";
      "trust_boundary";
      "text";
    ]

let linear_contact_success_schema =
  strict_object
    [
      ("version", const_int 1);
      ("ok", const_bool true);
      ("physics", certificate_schema);
      ("provenance", provenance_schema);
    ]
    [ "version"; "ok"; "physics"; "provenance" ]

let output_schema =
  lazy
    (one_of
       [
         Lazy.force Centl_physics_contact_mcp_output.output_schema;
         linear_contact_success_schema;
       ])
