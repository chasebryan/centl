let () =
  let schema = Yojson.Safe.from_string Centl_sci_schema.json_schema in
  match schema with
  | `Assoc fields ->
      begin match List.assoc_opt "oneOf" fields with
      | Some (`List variants) ->
          Alcotest.(check int) "problem class variants" 4 (List.length variants)
      | _ -> Alcotest.fail "SCi output schema must define oneOf variants"
      end
  | _ -> Alcotest.fail "SCi output schema must be a JSON object"
