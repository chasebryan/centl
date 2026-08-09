let rec max_lengths acc = function
  | `Assoc fields ->
      let acc =
        match List.assoc_opt "maxLength" fields with
        | Some (`Int value) -> value :: acc
        | _ -> acc
      in
      List.fold_left (fun acc (_, value) -> max_lengths acc value) acc fields
  | `List values -> List.fold_left max_lengths acc values
  | _ -> acc

let () =
  let schema = Yojson.Safe.from_string Centl_sci_schema.json_schema in
  begin match schema with
  | `Assoc fields ->
      begin match List.assoc_opt "oneOf" fields with
      | Some (`List variants) ->
          Alcotest.(check int) "problem class variants" 4 (List.length variants)
      | _ -> Alcotest.fail "SCi output schema must define oneOf variants"
      end
  | _ -> Alcotest.fail "SCi output schema must be a JSON object"
  end;
  List.iter
    (fun value ->
      Alcotest.(check bool)
        "llama.cpp-safe bounded string" true (value <= 1_024))
    (max_lengths [] schema)
