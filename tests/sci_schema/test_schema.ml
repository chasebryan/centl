let contains text fragment =
  let text_length = String.length text in
  let fragment_length = String.length fragment in
  let rec loop index =
    if index + fragment_length > text_length then false
    else if String.sub text index fragment_length = fragment then true
    else loop (index + 1)
  in
  fragment_length = 0 || loop 0

let variant_class = function
  | `Assoc fields ->
      begin match List.assoc_opt "properties" fields with
      | Some (`Assoc properties) ->
          begin match List.assoc_opt "problem_class" properties with
          | Some (`Assoc problem_class) ->
              begin match List.assoc_opt "enum" problem_class with
              | Some (`List [ `String class_name ]) -> Some class_name
              | _ -> None
              end
          | _ -> None
          end
      | _ -> None
      end
  | _ -> None

let () =
  let schema = Yojson.Safe.from_string Centl_sci_schema.json_schema in
  begin match schema with
  | `Assoc fields ->
      begin match List.assoc_opt "oneOf" fields with
      | Some (`List variants) ->
          Alcotest.(check int) "problem class variants" 7 (List.length variants);
          List.iter
            (fun class_name ->
              Alcotest.(check bool)
                ("schema admits " ^ class_name)
                true
                (List.exists
                   (fun variant -> variant_class variant = Some class_name)
                   variants))
            [
              "exact_expression";
              "polynomial_equation";
              "verification_claim";
              "unit_conversion";
              "physical_constant";
              "uniform_gravity_particle";
              "unsupported";
            ]
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
      "physical_constant";
      "uniform_gravity_particle";
      "unsupported";
    ]
