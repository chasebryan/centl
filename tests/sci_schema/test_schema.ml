let contains text fragment =
  let text_length = String.length text in
  let fragment_length = String.length fragment in
  let rec loop index =
    if index + fragment_length > text_length then false
    else if String.sub text index fragment_length = fragment then true
    else loop (index + 1)
  in
  fragment_length = 0 || loop 0

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
  let grammar = Centl_sci_schema.llama_grammar in
  Alcotest.(check bool) "grammar root" true (contains grammar "root ::=");
  List.iter
    (fun class_name ->
      Alcotest.(check bool)
        ("grammar admits " ^ class_name)
        true
        (contains grammar class_name))
    [
      "exact_expression";
      "polynomial_equation";
      "unit_conversion";
      "unsupported";
    ]
