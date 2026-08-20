let provenance_to_json provenance =
  `Assoc
    [
      ("source", `String provenance.Centl_chemistry_data.source);
      ("dataset_version", `String provenance.dataset_version);
      ("status", `String provenance.status);
    ]

let molar_mass_request formula =
  match Centl_chemistry_data.molar_mass formula with
  | Error error ->
      Error
        (`Assoc
          [
            ("version", `Int 1);
            ("kind", `String "chemistry_error");
            ("code", `String "molar_mass_unavailable");
            ("error", `String (Centl_chemistry_data.error_message error));
          ])
  | Ok result ->
      Ok
        (`Assoc
          [
            ("version", `Int 1);
            ("kind", `String "molar_mass_interval");
            ("formula", `String result.formula);
            ("lower", `String (Q.to_string result.lower));
            ("upper", `String (Q.to_string result.upper));
            ("unit", `String result.unit);
            ("exact", `Bool result.exact);
            ("provenance", `List (List.map provenance_to_json result.provenance));
          ])
