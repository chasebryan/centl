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

let particle_input_properties =
  [
    ("id", string_schema);
    ("mass", quantity_input_schema);
    ("position", vector_input_schema);
    ("velocity", vector_input_schema);
  ]

let particle_input_schema =
  strict_object particle_input_properties [ "mass"; "position"; "velocity" ]

let identified_particle_input_schema =
  strict_object particle_input_properties [ "id"; "mass"; "position"; "velocity" ]

let sphere_input_schema =
  strict_object
    [
      ("particle", identified_particle_input_schema);
      ("radius", quantity_input_schema);
    ]
    [ "particle"; "radius" ]

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
      strict_object
        [
          ("action", const_string "elastic_collision_3d_at_contact");
          ("particle1", particle_input_schema);
          ("particle2", particle_input_schema);
        ]
        [ "action"; "particle1"; "particle2" ];
      strict_object
        [
          ("action", const_string "analyze_sphere_contacts");
          ("spheres", array_of sphere_input_schema);
        ]
        [ "action"; "spheres" ];
      strict_object
        [
          ("action", const_string "resolve_isolated_elastic_sphere_contacts");
          ("spheres", array_of sphere_input_schema);
        ]
        [ "action"; "spheres" ];
    ]

let read_only_annotations =
  `Assoc
    [
      ("readOnlyHint", `Bool true);
      ("destructiveHint", `Bool false);
      ("idempotentHint", `Bool true);
      ("openWorldHint", `Bool false);
    ]

let tool () =
  `Assoc
    [
      ("name", `String "centl_physics");
      ("title", `String "Compute with CENTL Physics");
      ( "description",
        `String
          "Use CENTL's deterministic exact-rational particle mechanics. \
           Discover physics capabilities and units, convert compatible units, \
           inspect exact physical constants, simulate a dimension-checked \
           particle, solve ideal exact elastic collisions, analyze exact \
           sphere contact geometry, or resolve only isolated disjoint touching \
           sphere pairs. Overlaps and ambiguous simultaneous contacts are \
           returned as explicit deferred results rather than guessed." );
      ("inputSchema", input_schema);
      ("outputSchema", Lazy.force Centl_physics_contact_mcp_output.output_schema);
      ("annotations", read_only_annotations);
    ]

let ok = function
  | `Assoc fields -> List.assoc_opt "ok" fields = Some (`Bool true)
  | _ -> false

let action_fields = function
  | "capabilities" | "units" -> Some ([ "action" ], [ "action" ])
  | "convert" ->
      Some
        ( [ "action"; "value"; "from_unit"; "to_unit" ],
          [ "action"; "value"; "from_unit"; "to_unit" ] )
  | "constant" -> Some ([ "action"; "symbol" ], [ "action"; "symbol" ])
  | "simulate_particle" ->
      Some
        ( [ "action"; "particle"; "forces"; "dt"; "steps" ],
          [
            "action"; "particle"; "forces"; "dt"; "steps"; "include_trajectory";
          ] )
  | "elastic_collision_1d" ->
      Some
        ( [ "action"; "mass1"; "velocity1"; "mass2"; "velocity2" ],
          [ "action"; "mass1"; "velocity1"; "mass2"; "velocity2" ] )
  | "elastic_collision_3d_at_contact" ->
      Some
        ( [ "action"; "particle1"; "particle2" ],
          [ "action"; "particle1"; "particle2" ] )
  | "analyze_sphere_contacts" | "resolve_isolated_elastic_sphere_contacts" ->
      Some ([ "action"; "spheres" ], [ "action"; "spheres" ])
  | _ -> None

let validate_arguments arguments =
  match List.assoc_opt "action" arguments with
  | None -> Error "centl_physics requires action"
  | Some (`String action) ->
      begin match action_fields action with
      | None -> Error ("unknown centl_physics action " ^ action)
      | Some (required, allowed) ->
          begin match
            List.find_opt
              (fun (name, _) -> not (List.mem name allowed))
              arguments
          with
          | Some (name, _) -> Error ("unknown centl_physics argument " ^ name)
          | None ->
              begin match
                List.find_opt
                  (fun name -> not (List.mem_assoc name arguments))
                  required
              with
              | Some name -> Error ("centl_physics requires " ^ name)
              | None -> Ok ()
              end
          end
      end
  | Some _ -> Error "centl_physics action must be a string"

let call ?(cancelled = Centl_engine.never_cancelled) state arguments =
  if not (Centl_physics_server.admit state) then
    Centl_physics_protocol.failure ~method_:"request" "resource_limit"
      "the physics process has reached its request limit"
  else
    Centl_physics_server.handle_json ~cancelled state
      (`Assoc (("version", `Int 1) :: arguments))
