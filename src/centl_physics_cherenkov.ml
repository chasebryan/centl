open Centl_physics

type cherenkov_status = Below_threshold | At_threshold | Emission

type cone_angle = { cosine : Q.t; radians_symbolic : string }

type cherenkov_certificate = {
  refractive_index : Q.t;
  particle_speed : quantity;
  vacuum_light_speed : quantity;
  threshold_speed : quantity;
  beta : Q.t;
  threshold_beta : Q.t;
  beta_times_refractive_index : Q.t;
  status : cherenkov_status;
  cone_angle : cone_angle option;
}

let cherenkov_status_to_string = function
  | Below_threshold -> "below_threshold"
  | At_threshold -> "threshold"
  | Emission -> "emission"

let cherenkov_emits certificate =
  match certificate.status with Emission -> true | _ -> false

let certify_cherenkov ~refractive_index ~speed =
  require_dimension ~context:"Cherenkov particle speed" ~expected:dim_velocity
    speed.quantity_dimension;
  if Q.compare refractive_index Q.zero <= 0 then
    raise (Physics_error "Cherenkov refractive index must be positive");
  if Q.compare speed.si_value Q.zero < 0 then
    raise (Physics_error "Cherenkov particle speed must be non-negative");
  let vacuum_light_speed = (constant "c").constant_value in
  let threshold_beta = Q.div Q.one refractive_index in
  let threshold_speed = quantity_scale threshold_beta vacuum_light_speed in
  let beta = Q.div speed.si_value vacuum_light_speed.si_value in
  let beta_times_refractive_index = Q.mul beta refractive_index in
  let comparison = Q.compare beta_times_refractive_index Q.one in
  let status =
    if comparison < 0 then Below_threshold
    else if comparison = 0 then At_threshold
    else Emission
  in
  let cone_angle =
    if comparison > 0 then
      let cosine = Q.div Q.one beta_times_refractive_index in
      Some
        {
          cosine;
          radians_symbolic = "acos(" ^ Q.to_string cosine ^ ")";
        }
    else None
  in
  {
    refractive_index;
    particle_speed = speed;
    vacuum_light_speed;
    threshold_speed;
    beta;
    threshold_beta;
    beta_times_refractive_index;
    status;
    cone_angle;
  }
