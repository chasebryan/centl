let assoc name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.fail ("missing JSON field " ^ name)
      end
  | _ -> Alcotest.fail "expected JSON object"

let string name json =
  match assoc name json with
  | `String value -> value
  | _ -> Alcotest.fail ("expected string field " ^ name)

let bool name json =
  match assoc name json with
  | `Bool value -> value
  | _ -> Alcotest.fail ("expected boolean field " ^ name)

let quantity value unit_symbol =
  `Assoc [ ("value", `String value); ("unit", `String unit_symbol) ]

let vector x y z unit_symbol =
  `Assoc
    [
      ("x", `String x);
      ("y", `String y);
      ("z", `String z);
      ("unit", `String unit_symbol);
    ]

let particle id mass (px, py, pz) (vx, vy, vz) =
  `Assoc
    [
      ("id", `String id);
      ("mass", quantity mass "kg");
      ("position", vector px py pz "m");
      ("velocity", vector vx vy vz "m/s");
    ]

let request fields =
  let state = Centl_physics_protocol.create () in
  Centl_physics_server.handle_json state
    (`Assoc (("version", `Int 1) :: fields))
