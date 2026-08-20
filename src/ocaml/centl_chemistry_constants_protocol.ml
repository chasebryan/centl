let constant_request symbol =
  match Centl_chemistry_constants.constant symbol with
  | Error error ->
      Error
        (`Assoc
          [
            ("version", `Int 1);
            ("kind", `String "chemistry_error");
            ("code", `String "constant_unavailable");
            ("error", `String (Centl_chemistry_constants.error_message error));
          ])
  | Ok derived ->
      Ok
        (`Assoc
          [
            ("version", `Int 1);
            ("kind", `String "derived_chemistry_constant");
            ("symbol", `String derived.symbol);
            ("value", `String (Q.to_string derived.value));
            ("unit", `String derived.unit);
            ("definition", `String derived.definition);
            ("provenance", `String derived.provenance);
          ])
