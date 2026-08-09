open Centl_physics
open Centl_physics_world

type linear_contact_status =
  | Initially_overlapping
  | Touching_at_start
  | No_contact_in_interval
  | Tangent_contact
  | Crossing_contact

let linear_contact_status_to_string = function
  | Initially_overlapping -> "initially_overlapping"
  | Touching_at_start -> "touching_at_start"
  | No_contact_in_interval -> "no_contact_in_interval"
  | Tangent_contact -> "tangent_contact"
  | Crossing_contact -> "crossing_contact"

type exact_contact_time =
  | Rational_contact_time of quantity
  | Quadratic_irrational_contact_time of {
      polynomial_a : quantity;
      polynomial_b : quantity;
      polynomial_c : quantity;
      discriminant : quantity;
      bracket_lower : quantity;
      bracket_upper : quantity;
    }

type linear_contact_certificate = {
  particle1_id : string;
  particle2_id : string;
  duration : quantity;
  status : linear_contact_status;
  polynomial_a : quantity;
  polynomial_b : quantity;
  polynomial_c : quantity;
  closest_time : quantity;
  minimum_clearance_squared : quantity;
  discriminant : quantity option;
  first_contact_time : exact_contact_time option;
}

let require_nonnegative_duration duration =
  require_dimension ~context:"linear contact duration" ~expected:dim_time
    duration.quantity_dimension;
  if Q.compare duration.si_value Q.zero < 0 then
    raise (Physics_error "linear contact duration must be nonnegative")

let time_of_si value = quantity_of_si value dim_time

let clamp_time duration value =
  if Q.compare value Q.zero <= 0 then time_of_si Q.zero
  else if Q.compare value duration.si_value >= 0 then duration
  else time_of_si value

let clearance_at ~a ~b ~c time =
  let t_squared = quantity_mul time time in
  quantity_add (quantity_add (quantity_mul a t_squared) (quantity_mul b time)) c

let perfect_square_root_z value =
  if Z.sign value < 0 then None
  else
    let root = Z.sqrt value in
    if Z.equal (Z.mul root root) value then Some root else None

let rational_square_root value =
  if Q.sign value < 0 then None
  else
    match
      (perfect_square_root_z (Q.num value), perfect_square_root_z (Q.den value))
    with
    | Some numerator, Some denominator -> Some (Q.make numerator denominator)
    | _ -> None

let first_crossing_time ~a ~b ~c ~discriminant ~closest_time =
  match rational_square_root discriminant.si_value with
  | Some root ->
      let numerator = Q.sub (Q.neg b.si_value) root in
      let denominator = Q.mul (Q.of_int 2) a.si_value in
      Rational_contact_time (time_of_si (Q.div numerator denominator))
  | None ->
      Quadratic_irrational_contact_time
        {
          polynomial_a = a;
          polynomial_b = b;
          polynomial_c = c;
          discriminant;
          bracket_lower = time_of_si Q.zero;
          bracket_upper = closest_time;
        }

let certify_linear_sphere_contact ~duration sphere1 sphere2 =
  require_nonnegative_duration duration;
  if String.equal sphere1.particle.id sphere2.particle.id then
    raise (Physics_error "linear contact pair requires distinct particle ids");
  let relative_position =
    vector_sub sphere1.particle.position sphere2.particle.position
  in
  let relative_velocity =
    vector_sub sphere1.particle.velocity sphere2.particle.velocity
  in
  let radius_sum = quantity_add sphere1.radius sphere2.radius in
  let radius_sum_squared = quantity_mul radius_sum radius_sum in
  let a = vector_norm_squared relative_velocity in
  let b =
    vector_dot relative_position relative_velocity
    |> quantity_scale (Q.of_int 2)
  in
  let c =
    quantity_sub (vector_norm_squared relative_position) radius_sum_squared
  in
  let initial_comparison = Q.compare c.si_value Q.zero in
  let closest_time =
    if Q.equal a.si_value Q.zero then time_of_si Q.zero
    else
      let vertex = Q.div (Q.neg b.si_value) (Q.mul (Q.of_int 2) a.si_value) in
      clamp_time duration vertex
  in
  let minimum_clearance_squared = clearance_at ~a ~b ~c closest_time in
  let discriminant =
    if Q.equal a.si_value Q.zero then None
    else
      Some
        (quantity_sub (quantity_mul b b)
           (quantity_scale (Q.of_int 4) (quantity_mul a c)))
  in
  let crossing_result discriminant =
    ( Crossing_contact,
      Some (first_crossing_time ~a ~b ~c ~discriminant ~closest_time) )
  in
  let status, first_contact_time =
    if initial_comparison < 0 then (Initially_overlapping, None)
    else if initial_comparison = 0 then
      (Touching_at_start, Some (Rational_contact_time (time_of_si Q.zero)))
    else
      let minimum_comparison =
        Q.compare minimum_clearance_squared.si_value Q.zero
      in
      if minimum_comparison > 0 then (No_contact_in_interval, None)
      else if minimum_comparison = 0 then
        match discriminant with
        | Some discriminant when Q.compare discriminant.si_value Q.zero > 0 ->
            crossing_result discriminant
        | _ -> (Tangent_contact, Some (Rational_contact_time closest_time))
      else
        match discriminant with
        | None ->
            raise
              (Physics_error
                 "internal linear-contact invariant: crossing requires \
                  relative motion")
        | Some discriminant -> crossing_result discriminant
  in
  {
    particle1_id = sphere1.particle.id;
    particle2_id = sphere2.particle.id;
    duration;
    status;
    polynomial_a = a;
    polynomial_b = b;
    polynomial_c = c;
    closest_time;
    minimum_clearance_squared;
    discriminant;
    first_contact_time;
  }
