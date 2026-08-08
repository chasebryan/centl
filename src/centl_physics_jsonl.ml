open Centl_physics
open Centl_physics_protocol

let exact_quantity_json_si quantity unit_symbol =
  `Assoc
    [
      ("kind", `String "quantity");
      ("exact", `Bool true);
      ("value", `String (Q.to_string quantity.si_value));
      ("unit", `String unit_symbol);
      ("si_value", `String (Q.to_string quantity.si_value));
      ("dimension", dimension_json quantity.quantity_dimension);
      ("text", `String (Q.to_string quantity.si_value ^ " " ^ unit_symbol));
    ]

let exact_vector_json_si vector unit_symbol =
  `Assoc
    [
      ("kind", `String "vector3");
      ("exact", `Bool true);
      ("x", `String (Q.to_string vector.x));
      ("y", `String (Q.to_string vector.y));
      ("z", `String (Q.to_string vector.z));
      ("unit", `String unit_symbol);
      ("dimension", dimension_json vector.vector_dimension);
      ( "text",
        `String
          (Printf.sprintf "%s,%s,%s %s" (Q.to_string vector.x)
             (Q.to_string vector.y) (Q.to_string vector.z) unit_symbol) );
    ]

let units_result () =
  let unit_json unit_def =
    `Assoc
      [
        ("symbol", `String unit_def.symbol);
        ("name", `String unit_def.name);
        ("scale_to_si", `String (Q.to_string unit_def.scale_to_si));
        ("dimension", dimension_json unit_def.unit_dimension);
      ]
  in
  `Assoc
    [
      ("kind", `String "physics_units");
      ("units", `List (List.map unit_json unit_catalog));
      ( "text",
        `String (Printf.sprintf "%d physics units" (List.length unit_catalog)) );
    ]

let capabilities_result limits =
  let strings values = `List (List.map (fun value -> `String value) values) in
  `Assoc
    [
      ("kind", `String "physics_capabilities");
      ("protocol_version", `Int 1);
      ( "actions",
        strings
          [
            "capabilities";
            "units";
            "convert";
            "constant";
            "simulate_particle";
            "elastic_collision_1d";
          ] );
      ( "force_models",
        strings
          [ "constant_force"; "uniform_gravity"; "hooke_spring"; "linear_drag" ]
      );
      ("integrators", strings [ "symplectic_euler" ]);
      ( "constants",
        strings (List.map (fun constant -> constant.constant_symbol) physical_constants)
      );
      ( "limits",
        `Assoc
          [
            ("max_request_bytes", `Int limits.max_request_bytes);
            ("max_requests", `Int limits.max_requests);
            ("max_steps", `Int limits.max_steps);
            ("max_trajectory_steps", `Int limits.max_trajectory_steps);
          ] );
      ( "text",
        `String
          "Exact-rational, dimension-safe particle mechanics with typed JSON requests and results." );
    ]

let convert_result fields =
  match
    check_fields
      [ "version"; "id"; "action"; "value"; "from_unit"; "to_unit" ]
      fields
  with
  | Error _ as error -> error
  | Ok () ->
      begin match
        ( string_field "value" fields,
          string_field "from_unit" fields,
          string_field "to_unit" fields )
      with
      | Ok value, Ok from_unit, Ok to_unit ->
          begin match parse_q "value" value with
          | Error _ as error -> error
          | Ok value ->
              begin try
                let input = quantity value from_unit in
                let converted = convert input to_unit in
                Ok
                  (`Assoc
                     [
                       ("kind", `String "unit_conversion");
                       ("input", quantity_json_as input from_unit);
                       ("result", `String (Q.to_string converted));
                       ("unit", `String to_unit);
                       ("exact", `Bool true);
                       ("text", `String (Q.to_string converted ^ " " ^ to_unit));
                     ])
              with Physics_error message -> Error message
              end
          end
      | Error message, _, _
      | _, Error message, _
      | _, _, Error message -> Error message
      end

let constant_result fields =
  match check_fields [ "version"; "id"; "action"; "symbol" ] fields with
  | Error _ as error -> error
  | Ok () ->
      begin match string_field "symbol" fields with
      | Error _ as error -> error
      | Ok symbol ->
          begin try
            let constant = constant symbol in
            Ok
              (`Assoc
                 [
                   ("kind", `String "physical_constant");
                   ("symbol", `String constant.constant_symbol);
                   ("name", `String constant.constant_name);
                   ( "value",
                     quantity_json_as constant.constant_value constant.display_unit );
                   ("provenance", `String constant.provenance);
                   ("exact", `Bool constant.exact_value);
                   ( "text",
                     `String
                       (constant.constant_symbol ^ "="
                      ^ quantity_to_string_as constant.constant_value
                          constant.display_unit) );
                 ])
          with Physics_error message -> Error message
          end
      end

let trajectory_json trajectory = `List (List.map particle_json trajectory)

let simulation_result limits fields =
  match
    check_fields
      [
        "version";
        "id";
        "action";
        "particle";
        "forces";
        "dt";
        "steps";
        "include_trajectory";
      ]
      fields
  with
  | Error _ as error -> error
  | Ok () ->
      begin match
        ( List.assoc_opt "particle" fields,
          List.assoc_opt "forces" fields,
          List.assoc_opt "dt" fields,
          int_field "steps" fields,
          bool_field_default "include_trajectory" false fields )
      with
      | ( Some particle_input_json,
          Some (`List force_json),
          Some dt_json,
          Ok steps,
          Ok include_trajectory ) ->
          if steps < 0 then Error "steps must be non-negative"
          else if steps > limits.max_steps then
            Error
              (Printf.sprintf "steps exceeds the protocol limit of %d"
                 limits.max_steps)
          else if include_trajectory && steps > limits.max_trajectory_steps then
            Error
              (Printf.sprintf
                 "trajectory output exceeds the protocol limit of %d steps"
                 limits.max_trajectory_steps)
          else
            begin match
              ( particle_input particle_input_json,
                force_list [] force_json,
                quantity_input "dt" dt_json )
            with
            | Ok particle, Ok forces, Ok dt ->
                begin try
                  let trajectory = simulate ~steps ~dt ~forces particle in
                  let final = final_state trajectory in
                  let initial_momentum = momentum particle in
                  let final_momentum = momentum final in
                  let initial_ke = kinetic_energy particle in
                  let final_ke = kinetic_energy final in
                  let result_fields =
                    [
                      ("kind", `String "particle_simulation");
                      ("integrator", `String "symplectic_euler");
                      ("steps", `Int steps);
                      ("dt", quantity_json_as dt "s");
                      ("initial", particle_json particle);
                      ("final", particle_json final);
                      ( "diagnostics",
                        `Assoc
                          [
                            ( "initial_momentum",
                              exact_vector_json_si initial_momentum "kg*m/s" );
                            ( "final_momentum",
                              exact_vector_json_si final_momentum "kg*m/s" );
                            ( "initial_kinetic_energy",
                              quantity_json_as initial_ke "J" );
                            ( "final_kinetic_energy",
                              quantity_json_as final_ke "J" );
                          ] );
                      ( "text",
                        `String
                          ("final position="
                          ^ vector_to_string_as final.position "m"
                          ^ " m; final velocity="
                          ^ vector_to_string_as final.velocity "m/s"
                          ^ " m/s") );
                    ]
                  in
                  let result_fields =
                    if include_trajectory then
                      result_fields @ [ ("trajectory", trajectory_json trajectory) ]
                    else result_fields
                  in
                  Ok (`Assoc result_fields)
                with Physics_error message -> Error message
                end
            | Error message, _, _
            | _, Error message, _
            | _, _, Error message -> Error message
            end
      | None, _, _, _, _ -> Error "missing particle"
      | _, None, _, _, _ -> Error "missing forces"
      | _, Some _, None, _, _ -> Error "missing dt"
      | _, Some _, _, Error message, _ -> Error message
      | _, Some _, _, _, Error message -> Error message
      | _, Some _, _, _, _ -> Error "forces must be an array"
      end
