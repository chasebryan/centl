type layer =
  | Declarative
  | Native_centl
  | External_adapter
  | Native_extension
  | Core_patch
  | Upstream_contribution

type t = {
  layer : layer;
  request : string;
  reusable_capabilities : string list;
  proposed_steps : string list;
  trust_notes : string list;
  unresolved : string list;
}

let layer_text = function
  | Declarative -> "declarative local extension"
  | Native_centl -> "native CENTL module/package"
  | External_adapter -> "controlled external adapter"
  | Native_extension -> "generated native extension"
  | Core_patch -> "downstream CENTL core patch"
  | Upstream_contribution -> "upstream contribution preparation"

let lower input = String.lowercase_ascii (String.trim input)

let contains needle text =
  Option.is_some (Centl_sci_interaction.find_substring ~needle text)

let classify request =
  let text = lower request in
  if contains "upstream" text || contains "contribution" text then Upstream_contribution
  else if
    contains "equation solver" text || contains "parser" text
    || contains "runtime" text || contains "centl internals" text
    || contains "core" text
  then Core_patch
  else if
    contains "rust" text || contains "ocaml" text
    || contains " c " (" " ^ text ^ " ")
    || contains "native backend" text || contains "sparse matrix" text
  then Native_extension
  else if
    contains "python" text || contains "package" text || contains "sensor" text
    || contains "telescope" text || contains "external" text
  then External_adapter
  else if
    contains "unit" text || contains "constant" text || contains "alias" text
    || contains "formula" text
  then Declarative
  else Native_centl

let plan request =
  let layer = classify request in
  let discovered =
    Centl_sci_capabilities.search request |> List.map Centl_sci_capabilities.render
  in
  let reusable_capabilities, proposed_steps, trust_notes, unresolved =
    match layer with
    | Declarative ->
        ( [ "workspace manifests"; "CENTL parser"; "existing unit/constant machinery where applicable" ],
          [
            "inspect built-in and active workspace capabilities";
            "express the change as a local declarative/native CENTL definition where possible";
            "validate the declaration";
            "record provenance and workspace revision";
            "activate only in the downstream workspace";
          ],
          [ "local declarations do not become verified core" ],
          [] )
    | Native_centl ->
        ( [ "CENTL definitions"; "assertions/tests"; "workspace modules" ],
          [
            "derive a structured change request";
            "generate native CENTL source";
            "parse and validate generated source";
            "write the module and manifest";
            "make the capability visible to completion and session execution";
          ],
          [ "generated source remains a local extension until separately verified" ],
          [] )
    | External_adapter ->
        ( [ "workspace package metadata"; "external-backend assurance category" ],
          [
            "identify the external runtime or package boundary";
            "define a narrow adapter contract";
            "record dependencies and provenance";
            "generate adapter scaffolding and tests";
            "keep external results visibly outside verified-core assurance";
          ],
          [ "external code is not allowed to masquerade as verified CENTL computation" ],
          [ "exact adapter ABI and dependency policy remain Caramels implementation work" ] )
    | Native_extension ->
        ( [ "generated workspace area"; "native-extension assurance category" ],
          [
            "choose an implementation backend from the requirement";
            "generate isolated native extension scaffolding";
            "build through a controlled toolchain";
            "generate tests and interface metadata";
            "register the extension in the local workspace";
          ],
          [ "native generated code requires explicit validation before activation" ],
          [ "the stable native extension ABI is not frozen in Caramels" ] )
    | Core_patch ->
        ( [ "existing source tree"; "tests"; "verification/build gates" ],
          [
            "identify the smallest downstream source change";
            "generate a patch plan";
            "apply changes in an isolated downstream revision";
            "run the quality gates relevant to the touched layer";
            "record that the local system diverges from upstream";
          ],
          [ "core self-modification must not bypass upstream-grade engineering gates" ],
          [ "Caramels planning does not auto-apply arbitrary trusted-core patches" ] )
    | Upstream_contribution ->
        ( [ "workspace manifests"; "workspace revisions"; "upstream reference repository" ],
          [
            "isolate selected downstream changes";
            "identify upstream compatibility concerns";
            "collect tests, documentation, and assurance notes";
            "prepare a branch/patch summary for human review";
          ],
          [ "publishing upstream remains an explicit user choice" ],
          [ "automatic Git publication is outside the local runtime trust boundary" ] )
  in
  let reusable_capabilities =
    List.sort_uniq String.compare (discovered @ reusable_capabilities)
  in
  { layer; request; reusable_capabilities; proposed_steps; trust_notes; unresolved }

let bullets title values =
  if values = [] then []
  else title :: List.map (fun value -> "  - " ^ value) values

let drop_prefix_ci prefix text =
  let trimmed = String.trim text in
  let lowered = String.lowercase_ascii trimmed in
  let prefix_lower = String.lowercase_ascii prefix in
  if String.starts_with ~prefix:prefix_lower lowered then
    Some
      (String.sub trimmed (String.length prefix)
         (String.length trimmed - String.length prefix)
      |> String.trim)
  else None

let render_validation name =
  match Centl_sci_workspace.default () with
  | None ->
      "CENTL-SCi cannot locate the local workspace. Set CENTL_WORKSPACE or HOME before validating an extension."
  | Some workspace ->
      begin match Centl_sci_validate.validate workspace name with
      | Error message -> "Extension validation failed: " ^ message
      | Ok report -> Centl_sci_validate.render report
      end

let generic_text plan =
  String.concat "\n"
    ([
       "BUILD plan";
       "  request: " ^ plan.request;
       "  implementation layer: " ^ layer_text plan.layer;
     ]
    @ bullets "  existing/reusable capabilities:" plan.reusable_capabilities
    @ bullets "  proposed Caramels steps:" plan.proposed_steps
    @ bullets "  trust/assurance:" plan.trust_notes
    @ bullets "  unresolved:" plan.unresolved)

let render_core_plan plan =
  let summary = generic_text plan in
  match Centl_sci_workspace.default () with
  | None -> summary ^ "\n  artifact: not persisted because no local workspace is available"
  | Some workspace ->
      begin match Centl_sci_core_plan.persist workspace plan with
      | Error message -> summary ^ "\n  artifact error: " ^ message
      | Ok artifact ->
          summary
          ^ "\n  persisted downstream plan: " ^ artifact.markdown_path
          ^ "\n  machine plan: " ^ artifact.json_path
          ^ "\n  note: no trusted-core source was edited or published"
      end

let render plan =
  let request = lower plan.request in
  if
    List.mem request
      [
        "capabilities";
        "show capabilities";
        "list capabilities";
        "what can centl do";
        "what can you do";
      ]
  then
    "Available CENTL / CENTL-SCi capabilities:\n" ^ Centl_sci_capabilities.render_all ()
  else
    match drop_prefix_ci "show capability " plan.request with
    | Some query when query <> "" ->
        "Capability matches for `" ^ query ^ "`:\n"
        ^ Centl_sci_capabilities.render_matches query
    | _ ->
        begin match drop_prefix_ci "validate extension " plan.request with
        | Some name when name <> "" -> render_validation name
        | _ ->
            begin match drop_prefix_ci "validate " plan.request with
            | Some name when name <> "" -> render_validation name
            | _ ->
                begin match plan.layer with
                | Core_patch -> render_core_plan plan
                | _ -> generic_text plan
                end
            end
        end
