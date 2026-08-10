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
    contains "rust" text || contains "ocaml" text || contains " c " (" " ^ text ^ " ")
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
          [ "exact adapter ABI and dependency policy remain first-pass implementation work" ] )
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
          [ "first-pass BUILD planning does not auto-apply arbitrary core patches" ] )
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
  { layer; request; reusable_capabilities; proposed_steps; trust_notes; unresolved }

let bullets title values =
  if values = [] then []
  else title :: List.map (fun value -> "  - " ^ value) values

let render plan =
  String.concat "\n"
    ([
       "BUILD plan";
       "  request: " ^ plan.request;
       "  implementation layer: " ^ layer_text plan.layer;
     ]
    @ bullets "  reusable capabilities:" plan.reusable_capabilities
    @ bullets "  proposed first-pass steps:" plan.proposed_steps
    @ bullets "  trust/assurance:" plan.trust_notes
    @ bullets "  unresolved:" plan.unresolved)
