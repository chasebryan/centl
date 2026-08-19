open Centl_physics
open Centl_physics_protocol
open Centl_physics_cherenkov

let cone_angle_json = function
  | None -> `Null
  | Some angle ->
      `Assoc
        [
          ("kind", `String "symbolic_arccos");
          ("cosine", `String (Q.to_string angle.cosine));
          ("symbolic_radians", `String angle.radians_symbolic);
          ("exact_cosine", `Bool true);
          ("floating_point_trigonometry", `Bool false);
        ]

let trust_boundary_json =
  `Assoc
    [
      ("condition", `String "v > c/n");
      ("angle_relation", `String "cos(theta) = c/(n*v) = 1/(beta*n)");
      ("medium_model", `String "scalar_refractive_index_at_frequency");
      ("dispersion_modelled", `Bool false);
      ("radiation_yield_modelled", `Bool false);
      ("energy_loss_modelled", `Bool false);
      ("particle_dynamics_modelled", `Bool false);
      ("floating_point_trigonometry", `Bool false);
    ]

let certificate_text certificate =
  let beta_n = Q.to_string certificate.beta_times_refractive_index in
  match certificate.status with
  | Below_threshold ->
      "no Cherenkov emission: beta*n=" ^ beta_n ^ " < 1"
  | At_threshold -> "Cherenkov threshold: beta*n=1; emission requires beta*n>1"
  | Emission ->
      begin match certificate.cone_angle with
      | None -> raise (Physics_error "Cherenkov emission certificate lost cone angle")
      | Some angle ->
          "Cherenkov emission: beta*n=" ^ beta_n ^ "; cos(theta)="
          ^ Q.to_string angle.cosine ^ "; theta=" ^ angle.radians_symbolic
          ^ " rad"
      end

let cherenkov_result fields =
  match
    check_fields
      [ "version"; "id"; "action"; "refractive_index"; "speed" ]
      fields
  with
  | Error _ as error -> error
  | Ok () ->
      begin match
        (string_field "refractive_index" fields, List.assoc_opt "speed" fields)
      with
      | Ok refractive_index_text, Some speed_json ->
          begin match
            (parse_q "refractive_index" refractive_index_text, quantity_input "speed" speed_json)
          with
          | Ok refractive_index, Ok speed ->
              begin try
                let certificate = certify_cherenkov ~refractive_index ~speed in
                Ok
                  (`Assoc
                     [
                       ("kind", `String "cherenkov_radiation_certificate");
                       ("exact", `Bool true);
                       ( "refractive_index",
                         `String (Q.to_string certificate.refractive_index) );
                       ("particle_speed", quantity_json_as certificate.particle_speed "m/s");
                       ( "vacuum_light_speed",
                         quantity_json_as certificate.vacuum_light_speed "m/s" );
                       ("threshold_speed", quantity_json_as certificate.threshold_speed "m/s");
                       ("beta", `String (Q.to_string certificate.beta));
                       ("threshold_beta", `String (Q.to_string certificate.threshold_beta));
                       ( "beta_times_refractive_index",
                         `String
                           (Q.to_string certificate.beta_times_refractive_index) );
                       ( "status",
                         `String (cherenkov_status_to_string certificate.status) );
                       ("emits", `Bool (cherenkov_emits certificate));
                       ("cone_angle", cone_angle_json certificate.cone_angle);
                       ("trust_boundary", trust_boundary_json);
                       ("text", `String (certificate_text certificate));
                     ])
              with Physics_error message -> Error message
              end
          | Error message, _ | _, Error message -> Error message
          end
      | Error message, _ -> Error message
      | _, None -> Error "missing speed"
      end
