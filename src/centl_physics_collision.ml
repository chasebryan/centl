open Centl_physics

type contact_status = Resolved | No_impulse

type contact_result = {
  status : contact_status;
  particle1 : particle;
  particle2 : particle;
}

let contact_status_to_string = function
  | Resolved -> "resolved"
  | No_impulse -> "separating_or_stationary"

let elastic_collision_3d_at_contact particle1 particle2 =
  let delta = vector_sub particle1.position particle2.position in
  let distance_squared = vector_norm_squared delta in
  if Q.equal distance_squared.si_value Q.zero then
    raise
      (Physics_error
         "3D elastic contact collision requires distinct particle centers");
  let relative_velocity = vector_sub particle1.velocity particle2.velocity in
  let normal_alignment = vector_dot relative_velocity delta in
  if Q.compare normal_alignment.si_value Q.zero >= 0 then
    { status = No_impulse; particle1; particle2 }
  else
    let normal_rate = quantity_div normal_alignment distance_squared in
    require_dimension ~context:"3D collision normal rate"
      ~expected:dim_frequency normal_rate.quantity_dimension;
    let normal_velocity = vector_times_quantity delta normal_rate in
    require_dimension ~context:"3D collision normal velocity"
      ~expected:dim_velocity normal_velocity.vector_dimension;
    let m1 = particle1.mass.si_value in
    let m2 = particle2.mass.si_value in
    let total_mass = Q.add m1 m2 in
    let two = Q.of_int 2 in
    let coefficient1 = Q.div (Q.mul two m2) total_mass in
    let coefficient2 = Q.div (Q.mul two m1) total_mass in
    let velocity1 =
      vector_sub particle1.velocity (vector_scale coefficient1 normal_velocity)
    in
    let velocity2 =
      vector_add particle2.velocity (vector_scale coefficient2 normal_velocity)
    in
    {
      status = Resolved;
      particle1 = { particle1 with velocity = velocity1 };
      particle2 = { particle2 with velocity = velocity2 };
    }
