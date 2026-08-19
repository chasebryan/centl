let add_enhanced_actions = function
  | `List items ->
      `List
        (items
        @ [
            `String "analyze_sphere_contacts";
            `String "resolve_isolated_elastic_sphere_contacts";
            `String "certify_linear_sphere_contact";
            `String "cherenkov";
          ])
  | json -> json

let add_contact_limit = function
  | `Assoc fields ->
      `Assoc
        (fields
        @ [
            ( "max_contact_pairs",
              `Int Centl_physics_world_json.max_contact_pairs );
          ])
  | json -> json

let enhanced_capabilities_result limits =
  match Centl_physics_jsonl.capabilities_result limits with
  | `Assoc fields ->
      `Assoc
        (List.map
           (function
             | "actions", value -> ("actions", add_enhanced_actions value)
             | "limits", value -> ("limits", add_contact_limit value)
             | field -> field)
           fields)
  | json -> json
