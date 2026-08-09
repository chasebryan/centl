open Centl_physics
open Centl_physics_collision
open Centl_physics_world
open Centl_physics_linear_contact

type event_step_deferred_reason =
  | Initial_overlap
  | Quadratic_irrational_event_time

let event_step_deferred_reason_to_string = function
  | Initial_overlap -> "initial_overlap"
  | Quadratic_irrational_event_time -> "quadratic_irrational_event_time"

type completed_event_step = {
  certificate : linear_contact_certificate;
  event_time : quantity option;
  response_status : contact_status option;
  contact_evidence : sphere_contact option;
  initial_sphere1 : sphere;
  initial_sphere2 : sphere;
  contact_sphere1 : sphere option;
  contact_sphere2 : sphere option;
  final_sphere1 : sphere;
  final_sphere2 : sphere;
  state_changed : bool;
  momentum_conserved : bool;
  kinetic_energy_conserved : bool;
}

type deferred_event_step = {
  reason : event_step_deferred_reason;
  certificate : linear_contact_certificate;
  sphere1 : sphere;
  sphere2 : sphere;
}

type event_step_result =
  | Completed of completed_event_step
  | Deferred of deferred_event_step

let require_nonnegative_time ~context dt =
  require_dimension ~context ~expected:dim_time dt.quantity_dimension;
  if Q.compare dt.si_value Q.zero < 0 then
    raise (Physics_error (context ^ " must be nonnegative"))

let advance_particle_linear ~dt particle =
  require_nonnegative_time ~context:"linear event-step duration" dt;
  let displacement = vector_times_quantity particle.velocity dt in
  let position = vector_add particle.position displacement in
  { particle with position }

let advance_sphere_linear ~dt body =
  { body with particle = advance_particle_linear ~dt body.particle }

let vector_equal a b =
  dim_equal a.vector_dimension b.vector_dimension
  && Q.equal a.x b.x
  && Q.equal a.y b.y
  && Q.equal a.z b.z

let quantity_equal a b =
  dim_equal a.quantity_dimension b.quantity_dimension && Q.equal a.si_value b.si_value

let particle_equal a b =
  String.equal a.id b.id
  && quantity_equal a.mass b.mass
  && vector_equal a.position b.position
  && vector_equal a.velocity b.velocity

let sphere_equal a b = particle_equal a.particle b.particle && quantity_equal a.radius b.radius

let pair_momentum sphere1 sphere2 =
  vector_add (momentum sphere1.particle) (momentum sphere2.particle)

let pair_kinetic_energy sphere1 sphere2 =
  quantity_add (kinetic_energy sphere1.particle) (kinetic_energy sphere2.particle)

let completed ~certificate ~event_time ~response_status ~contact_evidence
    ~initial_sphere1 ~initial_sphere2 ~contact_sphere1 ~contact_sphere2
    ~final_sphere1 ~final_sphere2 =
  let initial_momentum = pair_momentum initial_sphere1 initial_sphere2 in
  let final_momentum = pair_momentum final_sphere1 final_sphere2 in
  let initial_energy = pair_kinetic_energy initial_sphere1 initial_sphere2 in
  let final_energy = pair_kinetic_energy final_sphere1 final_sphere2 in
  Completed
    {
      certificate;
      event_time;
      response_status;
      contact_evidence;
      initial_sphere1;
      initial_sphere2;
      contact_sphere1;
      contact_sphere2;
      final_sphere1;
      final_sphere2;
      state_changed =
        not
          (sphere_equal initial_sphere1 final_sphere1
          && sphere_equal initial_sphere2 final_sphere2);
      momentum_conserved = vector_equal initial_momentum final_momentum;
      kinetic_energy_conserved = quantity_equal initial_energy final_energy;
    }

let resolve_rational_event ~duration ~certificate ~event_time sphere1 sphere2 =
  require_nonnegative_time ~context:"rational contact event time" event_time;
  if Q.compare event_time.si_value duration.si_value > 0 then
    raise
      (Physics_error
         "internal event-step invariant: contact time exceeds duration");
  let contact_sphere1 = advance_sphere_linear ~dt:event_time sphere1 in
  let contact_sphere2 = advance_sphere_linear ~dt:event_time sphere2 in
  let contact_evidence = classify_sphere_contact contact_sphere1 contact_sphere2 in
  if contact_evidence.relation <> Touching then
    raise
      (Physics_error
         "internal event-step invariant: certified rational event is not exact contact");
  let response =
    elastic_collision_3d_at_contact contact_sphere1.particle contact_sphere2.particle
  in
  let responded_sphere1 = { contact_sphere1 with particle = response.particle1 } in
  let responded_sphere2 = { contact_sphere2 with particle = response.particle2 } in
  let remaining = quantity_sub duration event_time in
  let final_sphere1 = advance_sphere_linear ~dt:remaining responded_sphere1 in
  let final_sphere2 = advance_sphere_linear ~dt:remaining responded_sphere2 in
  completed ~certificate ~event_time:(Some event_time)
    ~response_status:(Some response.status) ~contact_evidence:(Some contact_evidence)
    ~initial_sphere1:sphere1 ~initial_sphere2:sphere2
    ~contact_sphere1:(Some contact_sphere1) ~contact_sphere2:(Some contact_sphere2)
    ~final_sphere1 ~final_sphere2

let evolve_linear_sphere_pair_through_contact ~duration sphere1 sphere2 =
  let certificate = certify_linear_sphere_contact ~duration sphere1 sphere2 in
  match (certificate.status, certificate.first_contact_time) with
  | Initially_overlapping, _ ->
      Deferred
        {
          reason = Initial_overlap;
          certificate;
          sphere1;
          sphere2;
        }
  | No_contact_in_interval, None ->
      let final_sphere1 = advance_sphere_linear ~dt:duration sphere1 in
      let final_sphere2 = advance_sphere_linear ~dt:duration sphere2 in
      completed ~certificate ~event_time:None ~response_status:None
        ~contact_evidence:None ~initial_sphere1:sphere1 ~initial_sphere2:sphere2
        ~contact_sphere1:None ~contact_sphere2:None ~final_sphere1 ~final_sphere2
  | (Touching_at_start | Tangent_contact | Crossing_contact),
    Some (Rational_contact_time event_time) ->
      resolve_rational_event ~duration ~certificate ~event_time sphere1 sphere2
  | Crossing_contact, Some (Quadratic_irrational_contact_time _) ->
      Deferred
        {
          reason = Quadratic_irrational_event_time;
          certificate;
          sphere1;
          sphere2;
        }
  | _ ->
      raise
        (Physics_error
           "internal event-step invariant: inconsistent linear contact certificate")
