open Centl_physics_contact_mcp_output

let null_schema = `Assoc [ ("type", `String "null") ]

let cherenkov_status_schema =
  one_of
    [
      const_string "below_threshold";
      const_string "threshold";
      const_string "emission";
    ]

let cone_angle_schema =
  strict_object
    [
      ("kind", const_string "symbolic_arccos");
      ("cosine", string_schema);
      ("symbolic_radians", string_schema);
      ("exact_cosine", const_bool true);
      ("floating_point_trigonometry", const_bool false);
    ]
    [
      "kind";
      "cosine";
      "symbolic_radians";
      "exact_cosine";
      "floating_point_trigonometry";
    ]

let trust_boundary_schema =
  strict_object
    [
      ("condition", const_string "v > c/n");
      ( "angle_relation",
        const_string "cos(theta) = c/(n*v) = 1/(beta*n)" );
      ("medium_model", const_string "scalar_refractive_index_at_frequency");
      ("dispersion_modelled", const_bool false);
      ("radiation_yield_modelled", const_bool false);
      ("energy_loss_modelled", const_bool false);
      ("particle_dynamics_modelled", const_bool false);
      ("floating_point_trigonometry", const_bool false);
    ]
    [
      "condition";
      "angle_relation";
      "medium_model";
      "dispersion_modelled";
      "radiation_yield_modelled";
      "energy_loss_modelled";
      "particle_dynamics_modelled";
      "floating_point_trigonometry";
    ]

let certificate_schema =
  strict_object
    [
      ("kind", const_string "cherenkov_radiation_certificate");
      ("exact", const_bool true);
      ("refractive_index", string_schema);
      ("particle_speed", quantity_schema);
      ("vacuum_light_speed", quantity_schema);
      ("threshold_speed", quantity_schema);
      ("beta", string_schema);
      ("threshold_beta", string_schema);
      ("beta_times_refractive_index", string_schema);
      ("status", cherenkov_status_schema);
      ("emits", boolean_schema);
      ("cone_angle", one_of [ null_schema; cone_angle_schema ]);
      ("trust_boundary", trust_boundary_schema);
      ("text", string_schema);
    ]
    [
      "kind";
      "exact";
      "refractive_index";
      "particle_speed";
      "vacuum_light_speed";
      "threshold_speed";
      "beta";
      "threshold_beta";
      "beta_times_refractive_index";
      "status";
      "emits";
      "cone_angle";
      "trust_boundary";
      "text";
    ]

let success_schema =
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
         Lazy.force Centl_physics_linear_contact_mcp_output.output_schema;
         success_schema;
       ])
