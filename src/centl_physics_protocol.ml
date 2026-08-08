open Centl_physics

type limits = {
  max_request_bytes : int;
  max_requests : int;
  max_steps : int;
  max_trajectory_steps : int;
}

let default_limits =
  {
    max_request_bytes = 65_536;
    max_requests = 10_000;
    max_steps = 100_000;
    max_trajectory_steps = 4_096;
  }

type state = { limits : limits; mutable requests : int }

let create ?(limits = default_limits) () = { limits; requests = 0 }
let limits state = state.limits

let provenance method_ =
  `Assoc
    [
      ("schema", `Int 1);
      ( "producer",
        `Assoc
          [
            ("name", `String "centl"); ("version", `String Centl_version.value);
          ] );
      ("classification", `String "physics");
      ("method", `String method_);
      ("backend", `String "centl-physics");
    ]

let rec insert_after_version id = function
  | [] -> [ ("id", id) ]
  | (("version", _) as version) :: rest -> version :: ("id", id) :: rest
  | field :: rest -> field :: insert_after_version id rest

let with_id id = function
  | `Assoc fields ->
      begin match id with
      | None -> `Assoc fields
      | Some id -> `Assoc (insert_after_version id fields)
      end
  | json -> json

let success ?id ~method_ physics =
  `Assoc
    [
      ("version", `Int 1);
      ("ok", `Bool true);
      ("physics", physics);
      ("provenance", provenance method_);
    ]
  |> with_id id

let failure ?id ~method_ code message =
  `Assoc
    [
      ("version", `Int 1);
      ("ok", `Bool false);
      ( "error",
        `Assoc
          [
            ("code", `String code);
            ("message", `String message);
            ("retryable", `Bool false);
          ] );
      ("provenance", provenance method_);
    ]
  |> with_id id

let request_id fields =
  match List.assoc_opt "id" fields with
  | None -> Ok None
  | Some ((`String _ | `Int _ | `Intlit _) as id) -> Ok (Some id)
  | Some _ -> Error "id must be a string or integer"

let string_field name fields =
  match List.assoc_opt name fields with
  | Some (`String value) -> Ok value
  | None -> Error ("missing " ^ name)
  | Some _ -> Error (name ^ " must be a string")

let int_field name fields =
  match List.assoc_opt name fields with
  | Some (`Int value) -> Ok value
  | None -> Error ("missing " ^ name)
  | Some _ -> Error (name ^ " must be an integer")

let bool_field_default name default fields =
  match List.assoc_opt name fields with
  | None -> Ok default
  | Some (`Bool value) -> Ok value
  | Some _ -> Error (name ^ " must be a boolean")

let check_fields allowed fields =
  match List.find_opt (fun (name, _) -> not (List.mem name allowed)) fields with
  | None -> Ok ()
  | Some (name, _) -> Error ("unknown field " ^ name)

let parse_q label text =
  try Ok (Q.of_string text)
  with Invalid_argument _ | Failure _ ->
    Error ("invalid " ^ label ^ ": " ^ text)

let dimension_json dimension =
  `Assoc
    [
      ("length", `Int dimension.length);
      ("mass", `Int dimension.mass);
      ("time", `Int dimension.time);
      ("current", `Int dimension.current);
      ("temperature", `Int dimension.temperature);
      ("amount", `Int dimension.amount);
      ("luminous_intensity", `Int dimension.luminous_intensity);
      ("text", `String (dimension_to_string dimension));
    ]

let quantity_json_as quantity unit_symbol =
  `Assoc
    [
      ("kind", `String "quantity");
      ("exact", `Bool true);
      ("value", `String (Q.to_string (convert quantity unit_symbol)));
      ("unit", `String unit_symbol);
      ("si_value", `String (Q.to_string quantity.si_value));
      ("dimension", dimension_json quantity.quantity_dimension);
      ("text", `String (quantity_to_string_as quantity unit_symbol));
    ]

let vector_json_as vector unit_symbol =
  let unit_def = unit_exn unit_symbol in
  require_dimension
    ~context:("render vector in " ^ unit_symbol)
    ~expected:unit_def.unit_dimension vector.vector_dimension;
  let component value = Q.to_string (Q.div value unit_def.scale_to_si) in
  `Assoc
    [
      ("kind", `String "vector3");
      ("exact", `Bool true);
      ("x", `String (component vector.x));
      ("y", `String (component vector.y));
      ("z", `String (component vector.z));
      ("unit", `String unit_symbol);
      ("dimension", dimension_json vector.vector_dimension);
      ( "text",
        `String (vector_to_string_as vector unit_symbol ^ " " ^ unit_symbol) );
    ]

let particle_json particle =
  `Assoc
    [
      ("kind", `String "particle_state");
      ("id", `String particle.id);
      ("mass", quantity_json_as particle.mass "kg");
      ("position", vector_json_as particle.position "m");
      ("velocity", vector_json_as particle.velocity "m/s");
    ]

let quantity_input label = function
  | `Assoc fields ->
      begin match check_fields [ "value"; "unit" ] fields with
      | Error _ as error -> error
      | Ok () ->
          begin match
            (string_field "value" fields, string_field "unit" fields)
          with
          | Ok value, Ok unit_symbol ->
              begin match parse_q (label ^ " value") value with
              | Error _ as error -> error
              | Ok value ->
                  begin try Ok (quantity value unit_symbol)
                  with Physics_error message -> Error message
                  end
              end
          | Error message, _ | _, Error message -> Error message
          end
      end
  | _ -> Error (label ^ " must be an object")

let vector_input label = function
  | `Assoc fields ->
      begin match check_fields [ "x"; "y"; "z"; "unit" ] fields with
      | Error _ as error -> error
      | Ok () ->
          begin match
            ( string_field "x" fields,
              string_field "y" fields,
              string_field "z" fields,
              string_field "unit" fields )
          with
          | Ok x, Ok y, Ok z, Ok unit_symbol ->
              begin match
                ( parse_q (label ^ " x") x,
                  parse_q (label ^ " y") y,
                  parse_q (label ^ " z") z )
              with
              | Ok x, Ok y, Ok z ->
                  begin try Ok (vector3 ~unit_symbol x y z)
                  with Physics_error message -> Error message
                  end
              | Error message, _, _ | _, Error message, _ | _, _, Error message
                ->
                  Error message
              end
          | Error message, _, _, _
          | _, Error message, _, _
          | _, _, Error message, _
          | _, _, _, Error message ->
              Error message
          end
      end
  | _ -> Error (label ^ " must be an object")

let particle_input = function
  | `Assoc fields ->
      begin match
        check_fields [ "id"; "mass"; "position"; "velocity" ] fields
      with
      | Error _ as error -> error
      | Ok () ->
          let id =
            match List.assoc_opt "id" fields with
            | None -> Ok "body"
            | Some (`String id) -> Ok id
            | Some _ -> Error "particle id must be a string"
          in
          begin match
            ( id,
              List.assoc_opt "mass" fields,
              List.assoc_opt "position" fields,
              List.assoc_opt "velocity" fields )
          with
          | Ok id, Some mass, Some position, Some velocity ->
              begin match
                ( quantity_input "particle mass" mass,
                  vector_input "particle position" position,
                  vector_input "particle velocity" velocity )
              with
              | Ok mass, Ok position, Ok velocity ->
                  begin try Ok (particle ~id ~mass ~position ~velocity)
                  with Physics_error message -> Error message
                  end
              | Error message, _, _ | _, Error message, _ | _, _, Error message
                ->
                  Error message
              end
          | Error message, _, _, _ -> Error message
          | _, None, _, _ -> Error "missing particle mass"
          | _, _, None, _ -> Error "missing particle position"
          | _, _, _, None -> Error "missing particle velocity"
          end
      end
  | _ -> Error "particle must be an object"

let force_input = function
  | `Assoc fields ->
      begin match string_field "kind" fields with
      | Error message -> Error message
      | Ok "constant_force" ->
          begin match
            ( check_fields [ "kind"; "vector" ] fields,
              List.assoc_opt "vector" fields )
          with
          | Error message, _ -> Error message
          | Ok (), None -> Error "constant_force requires vector"
          | Ok (), Some json ->
              begin match vector_input "constant force" json with
              | Error _ as error -> error
              | Ok vector ->
                  begin try Ok (constant_force vector)
                  with Physics_error message -> Error message
                  end
              end
          end
      | Ok "uniform_gravity" ->
          begin match
            ( check_fields [ "kind"; "acceleration" ] fields,
              List.assoc_opt "acceleration" fields )
          with
          | Error message, _ -> Error message
          | Ok (), None -> Error "uniform_gravity requires acceleration"
          | Ok (), Some json ->
              begin match vector_input "gravity acceleration" json with
              | Error _ as error -> error
              | Ok vector ->
                  begin try Ok (uniform_gravity vector)
                  with Physics_error message -> Error message
                  end
              end
          end
      | Ok "hooke_spring" ->
          begin match
            ( check_fields [ "kind"; "anchor"; "stiffness" ] fields,
              List.assoc_opt "anchor" fields,
              List.assoc_opt "stiffness" fields )
          with
          | Error message, _, _ -> Error message
          | Ok (), None, _ -> Error "hooke_spring requires anchor"
          | Ok (), _, None -> Error "hooke_spring requires stiffness"
          | Ok (), Some anchor, Some stiffness ->
              begin match
                ( vector_input "spring anchor" anchor,
                  quantity_input "spring stiffness" stiffness )
              with
              | Ok anchor, Ok stiffness ->
                  begin try Ok (hooke_force ~anchor ~stiffness)
                  with Physics_error message -> Error message
                  end
              | Error message, _ | _, Error message -> Error message
              end
          end
      | Ok "linear_drag" ->
          begin match
            ( check_fields [ "kind"; "coefficient" ] fields,
              List.assoc_opt "coefficient" fields )
          with
          | Error message, _ -> Error message
          | Ok (), None -> Error "linear_drag requires coefficient"
          | Ok (), Some coefficient ->
              begin match
                quantity_input "linear drag coefficient" coefficient
              with
              | Error _ as error -> error
              | Ok coefficient ->
                  begin try Ok (linear_drag coefficient)
                  with Physics_error message -> Error message
                  end
              end
          end
      | Ok kind -> Error ("unsupported force model: " ^ kind)
      end
  | _ -> Error "force must be an object"

let rec force_list acc = function
  | [] -> Ok (List.rev acc)
  | force :: rest ->
      begin match force_input force with
      | Ok force -> force_list (force :: acc) rest
      | Error _ as error -> error
      end
