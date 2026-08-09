open Centl_physics
open Centl_physics_protocol
open Centl_physics_collision
open Centl_physics_world
open Centl_physics_contact_solver

let max_contact_pairs = 4_096
let pair_count count = if count < 2 then 0 else count * (count - 1) / 2

let exact_quantity_si_json quantity unit_symbol =
  `Assoc
    [
      ("kind", `String "quantity");
      ("exact", `Bool true);
      ("value", `String (Q.to_string quantity.si_value));
      ("unit", `String unit_symbol);
      ("si_value", `String (Q.to_string quantity.si_value));
      ("dimension", dimension_json quantity.quantity_dimension);
      ("text", `String (Q.to_string quantity.si_value ^ " " ^ unit_symbol));
    ]

let exact_vector_si_json vector unit_symbol =
  `Assoc
    [
      ("kind", `String "vector3");
      ("exact", `Bool true);
      ("x", `String (Q.to_string vector.x));
      ("y", `String (Q.to_string vector.y));
      ("z", `String (Q.to_string vector.z));
      ("unit", `String unit_symbol);
      ("dimension", dimension_json vector.vector_dimension);
      ( "text",
        `String
          (Printf.sprintf "%s,%s,%s %s" (Q.to_string vector.x)
             (Q.to_string vector.y) (Q.to_string vector.z) unit_symbol) );
    ]

let sphere_json sphere =
  `Assoc
    [
      ("kind", `String "sphere_body");
      ("particle", particle_json sphere.particle);
      ("radius", quantity_json_as sphere.radius "m");
    ]

let sphere_world_json state =
  `Assoc
    [
      ("kind", `String "sphere_world");
      ("sphere_count", `Int (List.length state.spheres));
      ("spheres", `List (List.map sphere_json state.spheres));
    ]

let sphere_input = function
  | `Assoc fields ->
      begin match check_fields [ "particle"; "radius" ] fields with
      | Error _ as error -> error
      | Ok () ->
          begin match
            (List.assoc_opt "particle" fields, List.assoc_opt "radius" fields)
          with
          | Some particle, Some radius ->
              begin match
                (particle_input particle, quantity_input "sphere radius" radius)
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

let rec sphere_list acc = function
  | [] -> Ok (List.rev acc)
  | json :: rest ->
      begin match sphere_input json with
      | Ok sphere -> sphere_list (sphere :: acc) rest
      | Error _ as error -> error
      end

let sphere_world_input = function
  | `List values ->
      begin match sphere_list [] values with
      | Error _ as error -> error
      | Ok spheres ->
          begin try
            let pairs = pair_count (List.length spheres) in
            if pairs > max_contact_pairs then
              Error
                (Printf.sprintf
                   "sphere contact analysis would require %d pairs, exceeding \
                    the %d-pair machine-interface limit"
                   pairs max_contact_pairs)
            else Ok (sphere_world spheres)
          with Physics_error message -> Error message
          end
      end
  | _ -> Error "spheres must be an array"

let contact_json (contact : sphere_contact) =
  `Assoc
    [
      ("particle1_id", `String contact.particle1_id);
      ("particle2_id", `String contact.particle2_id);
      ("relation", `String (contact_relation_to_string contact.relation));
      ("center_delta", exact_vector_si_json contact.center_delta "m");
      ("distance_squared", exact_quantity_si_json contact.distance_squared "m^2");
      ( "radius_sum_squared",
        exact_quantity_si_json contact.radius_sum_squared "m^2" );
    ]

let count_relation relation contacts =
  List.fold_left
    (fun count (contact : sphere_contact) ->
      if contact.relation = relation then count + 1 else count)
    0 contacts

let contact_summary_json contacts =
  `Assoc
    [
      ("pair_count", `Int (List.length contacts));
      ("separated", `Int (count_relation Separated contacts));
      ("touching", `Int (count_relation Touching contacts));
      ("overlapping", `Int (count_relation Overlapping contacts));
    ]

let active_contacts contacts =
  List.filter
    (fun (contact : sphere_contact) -> contact.relation <> Separated)
    contacts

let touching_contacts_from contacts =
  List.filter
    (fun (contact : sphere_contact) -> contact.relation = Touching)
    contacts

let trust_boundary_json =
  `Assoc
    [
      ("geometry", `String "exact_pairwise_spheres");
      ("contact_test", `String "distance_squared_vs_radius_sum_squared");
      ("response", `String "frictionless_elastic_normal_impulse");
      ("resolution_scope", `String "disjoint_touching_pairs_only");
      ("overlap_policy", `String "defer_entire_world");
      ("shared_contact_policy", `String "defer_entire_world");
      ("continuous_collision_detection", `Bool false);
      ("penetration_correction", `Bool false);
      ("friction", `Bool false);
      ("spin", `Bool false);
    ]

let contact_analysis_result fields =
  match check_fields [ "version"; "id"; "action"; "spheres" ] fields with
  | Error _ as error -> error
  | Ok () ->
      begin match List.assoc_opt "spheres" fields with
      | None -> Error "missing spheres"
      | Some spheres_json ->
          begin match sphere_world_input spheres_json with
          | Error _ as error -> error
          | Ok state ->
              let contacts = classify_sphere_contacts state in
              let active = active_contacts contacts in
              Ok
                (`Assoc
                   [
                     ("kind", `String "sphere_contact_analysis");
                     ("exact", `Bool true);
                     ("world", sphere_world_json state);
                     ("summary", contact_summary_json contacts);
                     ("active_contacts", `List (List.map contact_json active));
                     ("trust_boundary", trust_boundary_json);
                     ( "text",
                       `String
                         (Printf.sprintf
                            "%d sphere(s), %d pair(s): %d touching, %d \
                             overlapping"
                            (List.length state.spheres)
                            (List.length contacts)
                            (count_relation Touching contacts)
                            (count_relation Overlapping contacts)) );
                   ])
          end
      end

let pair_resolution_json (resolution : pair_resolution) =
  `Assoc
    [
      ("particle1_id", `String resolution.particle1_id);
      ("particle2_id", `String resolution.particle2_id);
      ("status", `String (contact_status_to_string resolution.status));
    ]

let resolved_pair_count resolutions =
  List.fold_left
    (fun count (resolution : pair_resolution) ->
      if resolution.status = Resolved then count + 1 else count)
    0 resolutions

let completed_resolution_json initial contacts result =
  let impulses = resolved_pair_count result.pair_resolutions in
  `Assoc
    [
      ("kind", `String "isolated_elastic_sphere_contact_resolution");
      ("exact", `Bool true);
      ("solver", `String "isolated_elastic_touching_contacts");
      ("decision", `String "completed");
      ("world_changed", `Bool (impulses > 0));
      ("initial_world", sphere_world_json initial);
      ("world", sphere_world_json result.world);
      ("initial_contact_summary", contact_summary_json contacts);
      ( "contact_evidence",
        `List (List.map contact_json (touching_contacts_from contacts)) );
      ( "pair_resolutions",
        `List (List.map pair_resolution_json result.pair_resolutions) );
      ( "invariants",
        `Assoc
          [
            ("momentum", `Bool result.momentum_conserved);
            ("kinetic_energy", `Bool result.kinetic_energy_conserved);
          ] );
      ("trust_boundary", trust_boundary_json);
      ( "text",
        `String
          (Printf.sprintf
             "completed: %d touching pair(s), %d elastic impulse(s); \
              momentum=%b; kinetic_energy=%b"
             (List.length result.pair_resolutions)
             impulses result.momentum_conserved result.kinetic_energy_conserved)
      );
    ]

let overlap_deferred_json initial contacts overlaps =
  `Assoc
    [
      ("kind", `String "isolated_elastic_sphere_contact_resolution");
      ("exact", `Bool true);
      ("solver", `String "isolated_elastic_touching_contacts");
      ("decision", `String "deferred");
      ("reason", `String "overlap_detected");
      ("world_changed", `Bool false);
      ("world", sphere_world_json initial);
      ("initial_contact_summary", contact_summary_json contacts);
      ("overlaps", `List (List.map contact_json overlaps));
      ("trust_boundary", trust_boundary_json);
      ( "text",
        `String
          (Printf.sprintf
             "deferred: %d overlapping pair(s); CENTL does not perform \
              penetration correction"
             (List.length overlaps)) );
    ]

let ambiguity_deferred_json initial contacts ids =
  let touching = touching_contacts_from contacts in
  `Assoc
    [
      ("kind", `String "isolated_elastic_sphere_contact_resolution");
      ("exact", `Bool true);
      ("solver", `String "isolated_elastic_touching_contacts");
      ("decision", `String "deferred");
      ("reason", `String "ambiguous_simultaneous_contacts");
      ("world_changed", `Bool false);
      ("world", sphere_world_json initial);
      ("initial_contact_summary", contact_summary_json contacts);
      ("ambiguous_particle_ids", `List (List.map (fun id -> `String id) ids));
      ("touching_contacts", `List (List.map contact_json touching));
      ("trust_boundary", trust_boundary_json);
      ( "text",
        `String
          (Printf.sprintf
             "deferred: %d particle(s) participate in multiple simultaneous \
              touching contacts"
             (List.length ids)) );
    ]

let contact_resolution_result fields =
  match check_fields [ "version"; "id"; "action"; "spheres" ] fields with
  | Error _ as error -> error
  | Ok () ->
      begin match List.assoc_opt "spheres" fields with
      | None -> Error "missing spheres"
      | Some spheres_json ->
          begin match sphere_world_input spheres_json with
          | Error _ as error -> error
          | Ok state ->
              let contacts = classify_sphere_contacts state in
              begin match resolve_isolated_elastic_touching_contacts state with
              | Completed result ->
                  Ok (completed_resolution_json state contacts result)
              | Deferred (_, Overlap_detected overlaps) ->
                  Ok (overlap_deferred_json state contacts overlaps)
              | Deferred (_, Ambiguous_simultaneous_contacts ids) ->
                  Ok (ambiguity_deferred_json state contacts ids)
              end
          end
      end
