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
          [ ("name", `String "centl"); ("version", `String Centl_version.value) ]
      );
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
  with Invalid_argument _ | Failure _ -> Error ("invalid " ^ label ^ ": " ^ text)

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
  require_dimension ~context:("render vector in " ^ unit_symbol)
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
      ("text", `String (vector_to_string_as vector unit_symbol ^ " " ^ unit_symbol));
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
