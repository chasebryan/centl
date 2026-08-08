open Centl_physics
open Centl_physics_protocol
open Centl_physics_jsonl
open Centl_physics_collision

let vector_equal a b =
  dim_equal a.vector_dimension b.vector_dimension
  && Q.equal a.x b.x && Q.equal a.y b.y && Q.equal a.z b.z

let total_momentum particle1 particle2 =
  vector_add (momentum particle1) (momentum particle2)

let total_kinetic_energy particle1 particle2 =
  quantity_add (kinetic_energy particle1) (kinetic_energy particle2)

let collision_3d_result fields =
  match
    check_fields [ "version"; "id"; "action"; "particle1"; "particle2" ] fields
  with
  | Error _ as error -> error
  | Ok () ->
      begin match
        (List.assoc_opt "particle1" fields, List.assoc_opt "particle2" fields)
      with
      | Some particle1_json, Some particle2_json ->
          begin match
            (particle_input particle1_json, particle_input particle2_json)
          with
          | Ok particle1, Ok particle2 ->
              begin try
                let initial_momentum = total_momentum particle1 particle2 in
                let initial_ke = total_kinetic_energy particle1 particle2 in
                let result = elastic_collision_3d_at_contact particle1 particle2 in
                let final_momentum =
                  total_momentum result.particle1 result.particle2
                in
                let final_ke =
                  total_kinetic_energy result.particle1 result.particle2
                in
                let status = contact_status_to_string result.status in
                Ok
                  (`Assoc
                     [
                       ("kind", `String "elastic_collision_3d_at_contact");
                       ("status", `String status);
                       ( "contact_assumption",
                         `String "caller_supplied_contact_with_distinct_centers" );
                       ("particle1_final", particle_json result.particle1);
                       ("particle2_final", particle_json result.particle2);
                       ( "invariants",
                         `Assoc
                           [
                             ( "momentum",
                               `Bool
                                 (vector_equal initial_momentum final_momentum)
                             );
                             ( "kinetic_energy",
                               `Bool (Q.equal initial_ke.si_value final_ke.si_value)
                             );
                             ( "initial_momentum",
                               exact_vector_json_si initial_momentum "kg*m/s" );
                             ( "final_momentum",
                               exact_vector_json_si final_momentum "kg*m/s" );
                             ( "initial_kinetic_energy",
                               quantity_json_as initial_ke "J" );
                             ( "final_kinetic_energy",
                               quantity_json_as final_ke "J" );
                           ] );
                       ("exact", `Bool true);
                       ( "text",
                         `String
                           (status ^ ": v1="
                          ^ vector_to_string_as result.particle1.velocity "m/s"
                          ^ " m/s; v2="
                          ^ vector_to_string_as result.particle2.velocity "m/s"
                          ^ " m/s") );
                     ])
              with Physics_error message -> Error message
              end
          | Error message, _ | _, Error message -> Error message
          end
      | None, _ -> Error "missing particle1"
      | _, None -> Error "missing particle2"
      end
