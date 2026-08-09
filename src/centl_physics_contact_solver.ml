open Centl_physics
open Centl_physics_collision
open Centl_physics_world

type pair_resolution = {
  particle1_id : string;
  particle2_id : string;
  status : contact_status;
}

type deferred_reason =
  | Overlap_detected of sphere_contact list
  | Ambiguous_simultaneous_contacts of string list

type completed_resolution = {
  world : sphere_world;
  pair_resolutions : pair_resolution list;
  momentum_conserved : bool;
  kinetic_energy_conserved : bool;
}

type contact_resolution =
  | Completed of completed_resolution
  | Deferred of sphere_world * deferred_reason

let deferred_reason_to_string = function
  | Overlap_detected _ -> "overlap_detected"
  | Ambiguous_simultaneous_contacts _ -> "ambiguous_simultaneous_contacts"

let particle_world sphere_world =
  world (List.map (fun sphere -> sphere.particle) sphere_world.spheres)

let vector_exact_equal a b =
  dim_equal a.vector_dimension b.vector_dimension
  && Q.equal a.x b.x
  && Q.equal a.y b.y
  && Q.equal a.z b.z

let quantity_exact_equal a b =
  dim_equal a.quantity_dimension b.quantity_dimension
  && Q.equal a.si_value b.si_value

let exact_world_conservation before after =
  let before_world = particle_world before in
  let after_world = particle_world after in
  ( vector_exact_equal (world_momentum before_world) (world_momentum after_world),
    quantity_exact_equal
      (world_kinetic_energy before_world)
      (world_kinetic_energy after_world) )

let sphere_by_id sphere_world id =
  match
    List.find_opt
      (fun sphere -> String.equal sphere.particle.id id)
      sphere_world.spheres
  with
  | Some sphere -> sphere
  | None -> raise (Physics_error ("unknown sphere particle id: " ^ id))

let touching_count id contacts =
  List.fold_left
    (fun count contact ->
      if
        String.equal contact.particle1_id id
        || String.equal contact.particle2_id id
      then count + 1
      else count)
    0 contacts

let ambiguous_touching_ids sphere_world contacts =
  sphere_world.spheres
  |> List.filter (fun sphere -> touching_count sphere.particle.id contacts > 1)
  |> List.map (fun sphere -> sphere.particle.id)

let resolve_touching_pair sphere_world contact =
  let sphere1 = sphere_by_id sphere_world contact.particle1_id in
  let sphere2 = sphere_by_id sphere_world contact.particle2_id in
  let response =
    elastic_collision_3d_at_contact sphere1.particle sphere2.particle
  in
  ( [
      (response.particle1.id, response.particle1);
      (response.particle2.id, response.particle2);
    ],
    {
      particle1_id = response.particle1.id;
      particle2_id = response.particle2.id;
      status = response.status;
    } )

let replacement_for id replacements =
  match List.assoc_opt id replacements with Some particle -> Some particle | None -> None

let apply_replacements sphere_world replacements =
  let spheres =
    List.map
      (fun sphere ->
        match replacement_for sphere.particle.id replacements with
        | Some particle -> { sphere with particle }
        | None -> sphere)
      sphere_world.spheres
  in
  sphere_world spheres

let resolve_isolated_elastic_touching_contacts sphere_world =
  let contacts = classify_sphere_contacts sphere_world in
  let overlaps =
    List.filter (fun contact -> contact.relation = Overlapping) contacts
  in
  if overlaps <> [] then Deferred (sphere_world, Overlap_detected overlaps)
  else
    let touching =
      List.filter (fun contact -> contact.relation = Touching) contacts
    in
    let ambiguous_ids = ambiguous_touching_ids sphere_world touching in
    if ambiguous_ids <> [] then
      Deferred
        (sphere_world, Ambiguous_simultaneous_contacts ambiguous_ids)
    else
      let replacements, pair_resolutions =
        List.fold_left
          (fun (replacements, pair_resolutions) contact ->
            let pair_replacements, pair_resolution =
              resolve_touching_pair sphere_world contact
            in
            ( List.rev_append pair_replacements replacements,
              pair_resolution :: pair_resolutions ))
          ([], []) touching
      in
      let resolved_world = apply_replacements sphere_world replacements in
      let momentum_conserved, kinetic_energy_conserved =
        exact_world_conservation sphere_world resolved_world
      in
      Completed
        {
          world = resolved_world;
          pair_resolutions = List.rev pair_resolutions;
          momentum_conserved;
          kinetic_energy_conserved;
        }
