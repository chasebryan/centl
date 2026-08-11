type description = {
  label : string;
  title : string;
  establishes : string list;
  does_not_establish : string list;
}

let catalog =
  [
    {
      label = "verified_extension";
      title = "Verified extension";
      establishes =
        [
          "the extension has an explicit verification basis recorded by its \
           integration path";
          "its verified claims are limited to that recorded basis";
        ];
      does_not_establish =
        [
          "that the extension is part of upstream verified CENTL core";
          "that every future modification remains verified";
        ];
    };
    {
      label = "validated_native_extension";
      title = "Validated native extension";
      establishes =
        [
          "the native extension passed the validation gates declared for that \
           local integration";
          "the extension has an explicit native boundary rather than being \
           treated as core";
        ];
      does_not_establish =
        [
          "formal verification equivalent to CENTL verified core";
          "correctness outside the tested/validated boundary";
        ];
    };
    {
      label = "locally_tested_extension";
      title = "Locally tested extension";
      establishes =
        [
          "the downstream extension is local/user-owned";
          "the extension has at least the structural/local testing basis \
           recorded by the workspace";
        ];
      does_not_establish =
        [
          "verified-core assurance";
          "formal proof";
          "correctness for inputs or domains not covered by its local tests";
        ];
    };
    {
      label = "external_backend";
      title = "External backend";
      establishes =
        [
          "results cross a declared external runtime/library boundary";
          "CENTL can preserve provenance that the computation was external";
        ];
      does_not_establish =
        [
          "that external results were established by verified CENTL core";
          "that the external dependency is trustworthy merely because it is \
           connected";
        ];
    };
    {
      label = "experimental_local_extension";
      title = "Experimental local extension";
      establishes =
        [
          "the capability is explicitly experimental and downstream";
          "its experimental status is not hidden from inspection";
        ];
      does_not_establish =
        [ "stability"; "validation completeness"; "verified-core assurance" ];
    };
    {
      label = "unverified_generated_extension";
      title = "Unverified generated extension";
      establishes =
        [
          "the artifact was generated and is tracked as downstream state";
          "its generated provenance remains visible";
        ];
      does_not_establish =
        [
          "that generated code is correct";
          "that it is safe to activate";
          "that it has been validated or verified";
        ];
    };
  ]

let find label = List.find_opt (fun item -> item.label = label) catalog

let bullets values =
  match values with
  | [] -> [ "    - none" ]
  | values -> List.map (fun value -> "    - " ^ value) values

let render_description description =
  String.concat "\n"
    ([ description.title ^ " (`" ^ description.label ^ "`)"; "  Establishes:" ]
    @ bullets description.establishes
    @ [ "  Does not establish:" ]
    @ bullets description.does_not_establish)

let render_catalog () =
  String.concat "\n\n" (List.map render_description catalog)
  ^ "\n\n\
     Assurance categories are not a single numeric ranking. They describe \
     different evidence and trust boundaries."

let render_manifest manifest =
  let header =
    [
      "Extension assurance: " ^ manifest.Centl_sci_extensions.name;
      "  kind: " ^ manifest.kind;
      "  enabled: " ^ string_of_bool manifest.enabled;
      "  assurance: " ^ manifest.assurance;
      "  provenance: " ^ manifest.provenance;
      "  source: " ^ manifest.source;
    ]
  in
  let description =
    match find manifest.assurance with
    | Some value -> render_description value
    | None ->
        String.concat "\n"
          [
            "Unknown/legacy assurance label (`" ^ manifest.assurance ^ "`)";
            "  This label is preserved for provenance, but Caramels does not \
             infer additional guarantees from an unknown assurance category.";
          ]
  in
  String.concat "\n" header ^ "\n\n" ^ description
  ^ "\n\n\
     This inspection does not change the extension or promote its assurance."
