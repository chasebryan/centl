open Centl_physics
open Centl_physics_protocol
open Centl_physics_jsonl

let collision_result fields =
  match
    check_fields
      [ "version"; "id"; "action"; "mass1"; "velocity1"; "mass2"; "velocity2" ]
      fields
  with
  | Error _ as error -> error
  | Ok () ->
      begin match
        ( List.assoc_opt "mass1" fields,
          List.assoc_opt "velocity1" fields,
          List.assoc_opt "mass2" fields,
          List.assoc_opt "velocity2" fields )
      with
      | Some mass1, Some velocity1, Some mass2, Some velocity2 ->
          begin match
            ( quantity_input "mass1" mass1,
              quantity_input "velocity1" velocity1,
              quantity_input "mass2" mass2,
              quantity_input "velocity2" velocity2 )
          with
          | Ok mass1, Ok velocity1, Ok mass2, Ok velocity2 ->
              begin try
                let v1_final, v2_final =
                  elastic_collision_1d ~mass1 ~velocity1 ~mass2 ~velocity2
                in
                let initial_momentum =
                  quantity_add
                    (quantity_mul mass1 velocity1)
                    (quantity_mul mass2 velocity2)
                in
                let final_momentum =
                  quantity_add
                    (quantity_mul mass1 v1_final)
                    (quantity_mul mass2 v2_final)
                in
                let half = Q.of_string "1/2" in
                let kinetic mass velocity =
                  quantity_mul mass (quantity_mul velocity velocity)
                  |> quantity_scale half
                in
                let initial_ke =
                  quantity_add (kinetic mass1 velocity1)
                    (kinetic mass2 velocity2)
                in
                let final_ke =
                  quantity_add (kinetic mass1 v1_final) (kinetic mass2 v2_final)
                in
                Ok
                  (`Assoc
                     [
                       ("kind", `String "elastic_collision_1d");
                       ("velocity1_final", quantity_json_as v1_final "m/s");
                       ("velocity2_final", quantity_json_as v2_final "m/s");
                       ( "invariants",
                         `Assoc
                           [
                             ( "momentum",
                               `Bool
                                 (Q.equal initial_momentum.si_value
                                    final_momentum.si_value) );
                             ( "kinetic_energy",
                               `Bool
                                 (Q.equal initial_ke.si_value final_ke.si_value)
                             );
                             ( "initial_momentum",
                               exact_quantity_json_si initial_momentum "kg*m/s"
                             );
                             ( "final_momentum",
                               exact_quantity_json_si final_momentum "kg*m/s" );
                             ( "initial_kinetic_energy",
                               quantity_json_as initial_ke "J" );
                             ( "final_kinetic_energy",
                               quantity_json_as final_ke "J" );
                           ] );
                       ("exact", `Bool true);
                       ( "text",
                         `String
                           ("v1="
                           ^ Q.to_string (convert v1_final "m/s")
                           ^ " m/s; v2="
                           ^ Q.to_string (convert v2_final "m/s")
                           ^ " m/s") );
                     ])
              with Physics_error message -> Error message
              end
          | Error message, _, _, _
          | _, Error message, _, _
          | _, _, Error message, _
          | _, _, _, Error message ->
              Error message
          end
      | None, _, _, _ -> Error "missing mass1"
      | _, None, _, _ -> Error "missing velocity1"
      | _, _, None, _ -> Error "missing mass2"
      | _, _, _, None -> Error "missing velocity2"
      end

let dispatch ?(cancelled = never_cancelled) state id action fields =
  try
    check_cancelled cancelled;
    let result =
      match action with
      | "capabilities" ->
          begin match check_fields [ "version"; "id"; "action" ] fields with
          | Ok () -> Ok (capabilities_result state.limits)
          | Error _ as error -> error
          end
      | "units" ->
          begin match check_fields [ "version"; "id"; "action" ] fields with
          | Ok () -> Ok (units_result ())
          | Error _ as error -> error
          end
      | "convert" -> convert_result fields
      | "constant" -> constant_result fields
      | "simulate_particle" -> simulation_result ~cancelled state.limits fields
      | "elastic_collision_1d" -> collision_result fields
      | name -> Error ("unknown physics action " ^ name)
    in
    match result with
    | Ok physics -> success ?id ~method_:action physics
    | Error message ->
        failure ?id ~method_:action "invalid_physics_request" message
  with Physics_cancelled ->
    failure ?id ~method_:action "cancelled" "physics computation cancelled"

let handle_json ?(cancelled = never_cancelled) state = function
  | `Assoc fields ->
      begin match request_id fields with
      | Error message -> failure ~method_:"request" "invalid_request" message
      | Ok id ->
          begin match List.assoc_opt "version" fields with
          | Some (`Int 1) ->
              begin match string_field "action" fields with
              | Ok action -> dispatch ~cancelled state id action fields
              | Error message ->
                  failure ?id ~method_:"request" "invalid_request" message
              end
          | Some (`Int _) ->
              failure ?id ~method_:"request" "invalid_request"
                "unsupported protocol version"
          | _ ->
              failure ?id ~method_:"request" "invalid_request"
                "version must be 1"
          end
      end
  | _ ->
      failure ~method_:"request" "invalid_request"
        "request must be a JSON object"

let admit state =
  if state.requests >= state.limits.max_requests then false
  else begin
    state.requests <- state.requests + 1;
    true
  end

let handle_line ?(cancelled = never_cancelled) state line =
  if not (admit state) then
    failure ~method_:"request" "resource_limit"
      "the process has reached its request limit"
  else if String.length line > state.limits.max_request_bytes then
    failure ~method_:"request" "resource_limit"
      "the request exceeds the byte limit"
  else
    try Yojson.Safe.from_string line |> handle_json ~cancelled state
    with Yojson.Json_error message ->
      failure ~method_:"request" "invalid_request" ("invalid JSON: " ^ message)

let text = function
  | `Assoc fields as response ->
      begin match List.assoc_opt "physics" fields with
      | Some (`Assoc physics) ->
          begin match List.assoc_opt "text" physics with
          | Some (`String text) -> text
          | _ -> Yojson.Safe.to_string response
          end
      | _ ->
          begin match List.assoc_opt "error" fields with
          | Some (`Assoc error) ->
              begin match List.assoc_opt "message" error with
              | Some (`String message) -> message
              | _ -> Yojson.Safe.to_string response
              end
          | _ -> Yojson.Safe.to_string response
          end
      end
  | json -> Yojson.Safe.to_string json
