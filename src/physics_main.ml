open Centl_physics
open Centl_physics_cherenkov

let usage () =
  Printf.eprintf
    "Usage:\n\
    \  centl-physics units\n\
    \  centl-physics convert VALUE FROM_UNIT TO_UNIT\n\
    \  centl-physics constant SYMBOL\n\
    \  centl-physics cherenkov REFRACTIVE_INDEX SPEED_MPS\n\
    \  centl-physics gravity MASS_KG X,Y,Z_M VX,VY,VZ_MPS GX,GY,GZ_MPS2 DT_S \
     STEPS\n\
    \  centl-physics --serve\n";
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

let command_cherenkov refractive_index_text speed_text =
  let certificate =
    certify_cherenkov
      ~refractive_index:(parse_q "refractive index" refractive_index_text)
      ~speed:(quantity (parse_q "speed" speed_text) "m/s")
  in
  Printf.printf "status=%s\n"
    (cherenkov_status_to_string certificate.status);
  Printf.printf "emits=%s\n"
    (if cherenkov_emits certificate then "true" else "false");
  Printf.printf "refractive_index=%s\n"
    (Q.to_string certificate.refractive_index);
  Printf.printf "speed=%s m/s\n"
    (Q.to_string (convert certificate.particle_speed "m/s"));
  Printf.printf "threshold_speed=%s m/s\n"
    (Q.to_string (convert certificate.threshold_speed "m/s"));
  Printf.printf "beta=%s\n" (Q.to_string certificate.beta);
  Printf.printf "threshold_beta=%s\n" (Q.to_string certificate.threshold_beta);
  Printf.printf "beta_n=%s\n"
    (Q.to_string certificate.beta_times_refractive_index);
  begin match certificate.cone_angle with
  | None ->
      Printf.printf "cos_theta=none\n";
      Printf.printf "theta=none\n"
  | Some angle ->
      Printf.printf "cos_theta=%s\n" (Q.to_string angle.cosine);
      Printf.printf "theta=%s rad\n" angle.radians_symbolic
  end;
  Printf.printf "exact_trigonometric_relation=true\n"

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

let command_serve () =
  let state = Centl_physics_protocol.create () in
  let rec loop () =
    match input_line stdin with
    | line ->
        let response = Centl_physics_server.handle_line state line in
        Yojson.Safe.to_string response |> print_endline;
        flush stdout;
        loop ()
    | exception End_of_file -> ()
  in
  loop ()

let () =
  try
    match Array.to_list Sys.argv with
    | [ _; "units" ] -> command_units ()
    | [ _; "convert"; value; from_unit; to_unit ] ->
        command_convert value from_unit to_unit
    | [ _; "constant"; symbol ] -> command_constant symbol
    | [ _; "cherenkov"; refractive_index; speed ] ->
        command_cherenkov refractive_index speed
    | [ _; "gravity"; mass; position; velocity; gravity; dt; steps ] ->
        command_gravity mass position velocity gravity dt steps
    | [ _; "--serve" ] -> command_serve ()
    | _ -> usage ()
  with Physics_error message ->
    Printf.eprintf "centl-physics: %s\n" message;
    exit 1
