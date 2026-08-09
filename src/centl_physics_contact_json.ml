open Centl_physics
open Centl_physics_protocol
open Centl_physics_jsonl
open Centl_physics_collision
open Centl_physics_world
open Centl_physics_contact_solver

let sphere_input = function
  | `Assoc fields ->
      begin match check_fields [ "particle"; "radius" ] fields with
      | Error _ as error -> error
      | Ok () ->
          begin match
            (List.assoc_opt "particle" fields, List.assoc_opt "radius" fields)
          with
          | Some particle_json, Some radius_json ->
              begin match
                (particle_input particle_json, quantity_input "sphere radius" radius_json)
              with
              | Ok particle, Ok radius ->
                  begin try Ok (sphere ~particle ~radius)
                  with Physics_error message -> Error message
                  end
              | Error message, _ | _, Error message -> Error message
              end
          | None, _ -> Error "missing sphere particle"
          | _, None -> Error "missing sphere radius"
          end
      end
  | _ -> Error "sphere must be an object"

let spheres_input fields =
  match List.assoc_opt "spheres" fields with
  | None -> Error "missing spheres"
  | Some (`List spheres) ->
      let rec loop index acc = function
        | [] ->
            begin try Ok (sphere_world (List.rev acc))
            with Physics_error message -> Error message
            end
        | json :: rest ->
            begin match sphere_input json with
            | Ok sphere -> loop (index + 1) (sphere :: acc) rest
            | Error message -> Error (Printf.sprintf "sphere %d: %s" index message)
            end
      in
      loop 0 [] spheres
  | Some _ -> Error "spheres must be an array"

let sphere_json sphere =
  `Assoc
    [
      ("particle", particle_json sphere.particle);
      ("radius", quantity_json_as sphere.radius "m");
    ]

let sphere_world_json world =
  `Assoc [ ("spheres", `List (List.map sphere_json world.spheres)) ]

let contact_json (contact : sphere_contact) =
  `Assoc
    [
      ("particle1_id", `String contact.particle1_id);
      ("particle2_id", `String contact.particle2_id);
      ( "relation",
        `String (contact_relation_to_string contact.relation) );
      ("center_delta", vector_json_as contact.center_delta "m");
      ("distance_squared", quantity_json_as contact.distance_squared "m^2");
      ( "radius_sum_squared",
        quantity_json_as contact.radius_sum_squared "m^2" );
    ]

let contact_summary (contacts : sphere_contact list) =
  let count relation =
    List.length
      (List.filter
         (fun (contact : sphere_contact) -> contact.relation = relation)
         contacts)
  in
  `Assoc
    [
      ("pair_count", `Int (List.length contacts));
      ("separated", `Int (count Separated));
      ("touching", `Int (count Touching));
      ("overlapping", `Int (count Overlapping));
    ]

let analyze_sphere_contacts_result fields =
  match check_fields [ "version"; "id"; "action"; "spheres" ] fields with
  | Error _ as error -> error
  | Ok () ->
      begin match spheres_input fields with
      | Error message -> Error message
      | Ok world ->
          let contacts = classify_sphere_contacts world in
          let active_contacts =
            List.filter
              (fun contact -> contact.relation <> Separated)
              contacts
          in
          Ok
            (`Assoc
               [
                 ("kind", `String "sphere_contact_analysis");
                 ("exact", `Bool true);
                 ("summary", contact_summary contacts);
                 ("active_contacts", `List (List.map contact_json active_contacts));
                 ("text", `String "Exact squared-distance sphere contact classification.");
               ])
      end

let vector_exact_equal a b =
  dim_equal a.vector_dimension b.vector_dimension
  && Q.equal a.x b.x && Q.equal a.y b.y && Q.equal a.z b.z

let particle_exact_equal first second =
  String.equal first.id second.id
  && dim_equal first.mass.quantity_dimension second.mass.quantity_dimension
  && Q.equal first.mass.si_value second.mass.si_value
  && vector_exact_equal first.position second.position
  && vector_exact_equal first.velocity second.velocity

let world_changed before after =
  List.exists2
    (fun first second -> not (particle_exact_equal first.particle second.particle))
    before.spheres after.spheres

let trust_boundary_json () =
  `Assoc
    [
      ("continuous_collision_detection", `Bool false);
      ("penetration_correction", `Bool false);
      ("friction", `Bool false);
      ("spin", `Bool false);
    ]

let invariants_json momentum kinetic_energy =
  `Assoc
    [
      ("momentum", `Bool momentum);
      ("kinetic_energy", `Bool kinetic_energy);
    ]

let resolve_isolated_elastic_sphere_contacts_result fields =
  match check_fields [ "version"; "id"; "action"; "spheres" ] fields with
  | Error _ as error -> error
  | Ok () ->
      begin match spheres_input fields with
      | Error message -> Error message
      | Ok world ->
          begin match resolve_isolated_elastic_touching_contacts world with
          | Completed completed ->
              Ok
                (`Assoc
                   [
                     ("kind", `String "isolated_elastic_sphere_contact_resolution");
                     ("exact", `Bool true);
                     ("decision", `String "completed");
                     ("world_changed", `Bool (world_changed world completed.world));
                     ( "world", sphere_world_json completed.world );
                     ( "pair_resolutions",
                       `List
                         (List.map
                            (fun pair ->
                              `Assoc
                                [
                                  ("particle1_id", `String pair.particle1_id);
                                  ("particle2_id", `String pair.particle2_id);
                                  ( "status",
                                    `String
                                      (contact_status_to_string pair.status) );
                                ])
                            completed.pair_resolutions) );
                     ( "invariants",
                       invariants_json completed.momentum_conserved
                         completed.kinetic_energy_conserved );
                     ("trust_boundary", trust_boundary_json ());
                   ])
          | Deferred (deferred_world, reason) ->
              let ambiguous_particle_ids =
                match reason with
                | Ambiguous_simultaneous_contacts ids -> ids
                | Overlap_detected _ -> []
              in
              Ok
                (`Assoc
                   [
                     ("kind", `String "isolated_elastic_sphere_contact_resolution");
                     ("exact", `Bool true);
                     ("decision", `String "deferred");
                     ("reason", `String (deferred_reason_to_string reason));
                     ("world_changed", `Bool false);
                     ("world", sphere_world_json deferred_world);
                     ( "ambiguous_particle_ids",
                       `List (List.map (fun id -> `String id) ambiguous_particle_ids) );
                     ("invariants", invariants_json true true);
                     ("trust_boundary", trust_boundary_json ());
                   ])
          end
      end
