open Centl_physics
open Centl_physics_protocol

let exact_quantity_json_si quantity unit_symbol =
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

let exact_vector_json_si vector unit_symbol =
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
