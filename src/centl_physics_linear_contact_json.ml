open Centl_physics
open Centl_physics_protocol
open Centl_physics_world_json
open Centl_physics_linear_contact

let polynomial_json ~a ~b ~c =
  `Assoc
    [
      ("a", exact_quantity_si_json a "m^2/s^2");
      ("b", exact_quantity_si_json b "m^2/s");
      ("c", exact_quantity_si_json c "m^2");
    ]

let rational_bracket_json lower upper =
  `Assoc
    [
      ("lower", exact_quantity_si_json lower "s");
      ("upper", exact_quantity_si_json upper "s");
    ]

let exact_contact_time_json = function
  | Rational_contact_time time ->
      `Assoc
        [
          ("kind", `String "rational");
          ("time", exact_quantity_si_json time "s");
        ]
  | Quadratic_irrational_contact_time
      {
        polynomial_a;
        polynomial_b;
        polynomial_c;
        discriminant;
        bracket_lower;
        bracket_upper;
      } ->
      `Assoc
        [
          ("kind", `String "quadratic_irrational");
          ( "polynomial",
            polynomial_json ~a:polynomial_a ~b:polynomial_b ~c:polynomial_c );
          ("discriminant", exact_quantity_si_json discriminant "m^4/s^2");
          ("rational_bracket", rational_bracket_json bracket_lower bracket_upper);
        ]

let trust_boundary_json =
  `Assoc
    [
      ("motion_model", `String "constant_velocity");
      ("geometry", `String "exact_sphere_pair");
      ("interval", `String "bounded_nonnegative_rational_time");
      ("contact_test", `String "exact_squared_clearance_quadratic");
      ("time_sampling", `Bool false);
      ("floating_point_root_finding", `Bool false);
      ("force_integration", `Bool false);
      ("automatic_response", `Bool false);
      ("simultaneous_contact_solving", `Bool false);
    ]

let first_contact_text = function
  | None -> "none"
  | Some (Rational_contact_time time) -> Q.to_string time.si_value ^ " s"
  | Some (Quadratic_irrational_contact_time { bracket_lower; bracket_upper; _ }) ->
      Printf.sprintf "quadratic_irrational in [%s,%s] s"
        (Q.to_string bracket_lower.si_value)
        (Q.to_string bracket_upper.si_value)

let certificate_json certificate =
  `Assoc
    [
      ("kind", `String "linear_sphere_contact_certificate");
      ("exact", `Bool true);
      ("model", `String "constant_velocity");
      ("particle1_id", `String certificate.particle1_id);
      ("particle2_id", `String certificate.particle2_id);
      ("duration", exact_quantity_si_json certificate.duration "s");
      ("status", `String (linear_contact_status_to_string certificate.status));
      ( "polynomial",
        polynomial_json ~a:certificate.polynomial_a ~b:certificate.polynomial_b
          ~c:certificate.polynomial_c );
      ("closest_time", exact_quantity_si_json certificate.closest_time "s");
      ( "minimum_clearance_squared",
        exact_quantity_si_json certificate.minimum_clearance_squared "m^2" );
      ( "discriminant",
        match certificate.discriminant with
        | None -> `Null
        | Some value -> exact_quantity_si_json value "m^4/s^2" );
      ( "first_contact_time",
        match certificate.first_contact_time with
        | None -> `Null
        | Some value -> exact_contact_time_json value );
      ("trust_boundary", trust_boundary_json);
      ( "text",
        `String
          (Printf.sprintf "%s; first_contact=%s"
             (linear_contact_status_to_string certificate.status)
             (first_contact_text certificate.first_contact_time)) );
    ]

let linear_contact_result fields =
  match
    check_fields
      [ "version"; "id"; "action"; "sphere1"; "sphere2"; "duration" ]
      fields
  with
  | Error _ as error -> error
  | Ok () ->
      begin match
        ( List.assoc_opt "sphere1" fields,
          List.assoc_opt "sphere2" fields,
          List.assoc_opt "duration" fields )
      with
      | Some sphere1, Some sphere2, Some duration ->
          begin match
            ( sphere_input sphere1,
              sphere_input sphere2,
              quantity_input "linear contact duration" duration )
          with
          | Ok sphere1, Ok sphere2, Ok duration ->
              begin try
                Ok
                  (certificate_json
                     (certify_linear_sphere_contact ~duration sphere1 sphere2))
              with Physics_error message -> Error message
              end
          | Error message, _, _ | _, Error message, _ | _, _, Error message ->
              Error message
          end
      | None, _, _ -> Error "missing sphere1"
      | _, None, _ -> Error "missing sphere2"
      | _, _, None -> Error "missing duration"
      end
