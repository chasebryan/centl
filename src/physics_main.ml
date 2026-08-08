open Centl_physics

let usage () =
  Printf.eprintf
    "Usage:\n\
    \  centl-physics units\n\
    \  centl-physics convert VALUE FROM_UNIT TO_UNIT\n\
    \  centl-physics constant SYMBOL\n\
    \  centl-physics gravity MASS_KG X,Y,Z_M VX,VY,VZ_MPS GX,GY,GZ_MPS2 DT_S \
     STEPS\n";
  exit 2

let parse_q label text =
  try Q.of_string text
  with Invalid_argument _ | Failure _ ->
    raise (Physics_error (Printf.sprintf "invalid %s rational: %s" label text))

let parse_int label text =
  try int_of_string text
  with Failure _ ->
    raise (Physics_error (Printf.sprintf "invalid %s integer: %s" label text))

let parse_triplet label text =
  match String.split_on_char ',' text with
  | [ x; y; z ] -> (parse_q label x, parse_q label y, parse_q label z)
  | _ ->
      raise
        (Physics_error
           (Printf.sprintf
              "%s must contain exactly three comma-separated values" label))

let print_unit unit_def =
  Printf.printf "%s\t%s\tscale=%s\tdimension=%s\n" unit_def.symbol unit_def.name
    (Q.to_string unit_def.scale_to_si)
    (dimension_to_string unit_def.unit_dimension)

let command_units () = List.iter print_unit unit_catalog

let command_convert value from_unit to_unit =
  let input = quantity (parse_q "value" value) from_unit in
  Printf.printf "%s\n" (Q.to_string (convert input to_unit))

let command_constant symbol =
  let c = constant symbol in
  Printf.printf "%s=%s\n" c.constant_symbol
    (quantity_to_string_as c.constant_value c.display_unit);
  Printf.printf "name=%s\n" c.constant_name;
  Printf.printf "provenance=%s\n" c.provenance;
  Printf.printf "exact=%s\n" (if c.exact_value then "true" else "false")

let command_gravity mass_text position_text velocity_text gravity_text dt_text
    steps_text =
  let px, py, pz = parse_triplet "position" position_text in
  let vx, vy, vz = parse_triplet "velocity" velocity_text in
  let gx, gy, gz = parse_triplet "gravity" gravity_text in
  let body =
    particle ~id:"body"
      ~mass:(quantity (parse_q "mass" mass_text) "kg")
      ~position:(vector3 ~unit_symbol:"m" px py pz)
      ~velocity:(vector3 ~unit_symbol:"m/s" vx vy vz)
  in
  let gravity = uniform_gravity (vector3 ~unit_symbol:"m/s^2" gx gy gz) in
  let dt = quantity (parse_q "dt" dt_text) "s" in
  let steps = parse_int "steps" steps_text in
  let trajectory = simulate ~steps ~dt ~forces:[ gravity ] body in
  let final = final_state trajectory in
  Printf.printf "integrator=symplectic-euler\n";
  Printf.printf "steps=%d\n" steps;
  Printf.printf "position=%s m\n" (vector_to_string_as final.position "m");
  Printf.printf "velocity=%s m/s\n" (vector_to_string_as final.velocity "m/s")

let () =
  try
    match Array.to_list Sys.argv with
    | [ _; "units" ] -> command_units ()
    | [ _; "convert"; value; from_unit; to_unit ] ->
        command_convert value from_unit to_unit
    | [ _; "constant"; symbol ] -> command_constant symbol
    | [ _; "gravity"; mass; position; velocity; gravity; dt; steps ] ->
        command_gravity mass position velocity gravity dt steps
    | _ -> usage ()
  with Physics_error message ->
    Printf.eprintf "centl-physics: %s\n" message;
    exit 1
