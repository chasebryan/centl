open Centl_physics

let max_world_particles = 256

type world = { particles : particle list }

let validate_particle_ids particles =
  let rec loop seen = function
    | [] -> ()
    | particle :: rest ->
        if String.trim particle.id = "" then
          raise (Physics_error "world particle id must not be empty")
        else if List.mem particle.id seen then
          raise
            (Physics_error
               (Printf.sprintf "world particle id must be unique: %s" particle.id))
        else loop (particle.id :: seen) rest
  in
  loop [] particles

let world particles =
  if List.length particles > max_world_particles then
    raise
      (Physics_error
         (Printf.sprintf "world exceeds the %d-particle safety limit"
            max_world_particles));
  validate_particle_ids particles;
  { particles }

let world_momentum world =
  List.fold_left
    (fun total particle -> vector_add total (momentum particle))
    (zero_vector dim_momentum) world.particles

let world_kinetic_energy world =
  List.fold_left
    (fun total particle -> quantity_add total (kinetic_energy particle))
    (quantity_of_si Q.zero dim_energy) world.particles

let step_world_symplectic_euler ~dt ~forces state =
  world (List.map (step_symplectic_euler ~dt ~forces) state.particles)

type sphere = {
  particle : particle;
  radius : quantity;
}

let sphere ~particle ~radius =
  require_dimension ~context:"sphere radius" ~expected:dim_length
    radius.quantity_dimension;
  if Q.compare radius.si_value Q.zero <= 0 then
    raise (Physics_error "sphere radius must be positive");
  { particle; radius }

type contact_relation = Separated | Touching | Overlapping

let contact_relation_to_string = function
  | Separated -> "separated"
  | Touching -> "touching"
  | Overlapping -> "overlapping"

type sphere_contact = {
  particle1_id : string;
  particle2_id : string;
  relation : contact_relation;
  center_delta : vector3;
  distance_squared : quantity;
  radius_sum_squared : quantity;
}

let classify_sphere_contact sphere1 sphere2 =
  if String.equal sphere1.particle.id sphere2.particle.id then
    raise (Physics_error "contact pair requires distinct particle ids");
  let center_delta =
    vector_sub sphere1.particle.position sphere2.particle.position
  in
  let distance_squared = vector_norm_squared center_delta in
  let radius_sum = quantity_add sphere1.radius sphere2.radius in
  let radius_sum_squared = quantity_mul radius_sum radius_sum in
  let comparison =
    Q.compare distance_squared.si_value radius_sum_squared.si_value
  in
  let relation =
    if comparison > 0 then Separated
    else if comparison = 0 then Touching
    else Overlapping
  in
  {
    particle1_id = sphere1.particle.id;
    particle2_id = sphere2.particle.id;
    relation;
    center_delta;
    distance_squared;
    radius_sum_squared;
  }

type sphere_world = { spheres : sphere list }

let sphere_world spheres =
  ignore (world (List.map (fun sphere -> sphere.particle) spheres));
  { spheres }

let classify_sphere_contacts world =
  let rec loop acc = function
    | [] -> List.rev acc
    | first :: rest ->
        let acc =
          List.fold_left
            (fun acc second -> classify_sphere_contact first second :: acc)
            acc rest
        in
        loop acc rest
  in
  loop [] world.spheres

let touching_contacts world =
  List.filter
    (fun contact -> contact.relation = Touching)
    (classify_sphere_contacts world)
