type origin =
  | Verified_core
  | Physics_engine
  | Caramels_runtime
  | Local_extension
  | Local_package

type capability = {
  name : string;
  aliases : string list;
  category : string;
  origin : origin;
  assurance : string;
  summary : string;
}

let origin_text = function
  | Verified_core -> "verified/core CENTL"
  | Physics_engine -> "deterministic CENTL Physics"
  | Caramels_runtime -> "CENTL-SCi Caramels runtime"
  | Local_extension -> "local downstream extension"
  | Local_package -> "local downstream package"

let builtins =
  [
    { name = "solve"; aliases = [ "equation"; "root"; "zero" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "supported equation-solving path" };
    { name = "diff"; aliases = [ "differentiate"; "derivative" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "symbolic differentiation for supported expressions" };
    { name = "integrate"; aliases = [ "integral"; "antiderivative" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "supported exact integration path" };
    { name = "simplify"; aliases = [ "canonicalize"; "simplification" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "supported symbolic simplification" };
    { name = "expand"; aliases = [ "polynomial expansion" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "supported symbolic expansion" };
    { name = "factor"; aliases = [ "factorization"; "factorisation" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "supported polynomial factoring domain" };
    { name = "substitute"; aliases = [ "substitution"; "replace variable" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "symbolic substitution" };
    { name = "approx"; aliases = [ "approximate"; "decimal"; "enclosure"; "significant digits" ]; category = "mathematics"; origin = Verified_core; assurance = "certified/existing"; summary = "precision-aware approximation/enclosure path, including deterministic Caramels natural-language lowering" };
    { name = "verify"; aliases = [ "claim"; "contract"; "assert" ]; category = "mathematics"; origin = Verified_core; assurance = "verification"; summary = "structured mathematical claim verification" };
    { name = "unit conversion"; aliases = [ "convert"; "units"; "dimension" ]; category = "physics"; origin = Physics_engine; assurance = "deterministic"; summary = "exact dimension-checked unit conversion" };
    { name = "physical constants"; aliases = [ "constant"; "speed of light"; "planck"; "boltzmann"; "avogadro" ]; category = "physics"; origin = Physics_engine; assurance = "deterministic exact catalog"; summary = "exact defining/conventional physics constants with provenance" };
    { name = "particle simulation"; aliases = [ "simulate"; "gravity"; "particle"; "mechanics" ]; category = "physics"; origin = Physics_engine; assurance = "deterministic model"; summary = "particle integration including explicit uniform gravity" };
    { name = "sphere contact analysis"; aliases = [ "sphere"; "contact"; "collision" ]; category = "physics"; origin = Physics_engine; assurance = "exact geometry"; summary = "exact sphere contact classification and bounded contact machinery" };
    { name = "workspace audit"; aliases = [ "audit workspace"; "check workspace"; "validate workspace"; "workspace consistency" ]; category = "build"; origin = Caramels_runtime; assurance = "read-only structural audit"; summary = "reports extension/package structure, assurance, activation state, and warnings without mutating verified core" };
    { name = "extension validation"; aliases = [ "validate extension"; "validate manifest"; "structural validation" ]; category = "build"; origin = Caramels_runtime; assurance = "structural only"; summary = "validates native definitions and generated adapter/native scaffold contracts without assurance promotion" };
    { name = "package validation"; aliases = [ "validate package"; "package membership"; "package composition" ]; category = "build"; origin = Caramels_runtime; assurance = "composition only"; summary = "checks package membership while preserving every member extension's assurance" };
    { name = "assurance explanation"; aliases = [ "assurance"; "assurance levels"; "explain assurance"; "trust boundary"; "provenance" ]; category = "build"; origin = Caramels_runtime; assurance = "read-only explanation"; summary = "explains what each downstream assurance label establishes and explicitly does not establish" };
    { name = "workspace revision history"; aliases = [ "revisions"; "revision history"; "workspace history"; "changes history" ]; category = "build"; origin = Caramels_runtime; assurance = "read-only bounded history"; summary = "shows the most recent bounded workspace revision events without mutating state" };
    { name = "workspace portability"; aliases = [ "export workspace"; "import workspace"; "bundle"; "portable workspace"; "restore workspace" ]; category = "build"; origin = Caramels_runtime; assurance = "validated reversible downstream operation"; summary = "exports and imports user-owned downstream state with validation, snapshot rollback, and no verified-core replacement" };
    { name = "English-to-CENTL extension"; aliases = [ "create function"; "create value"; "modify function"; "modify value"; "extend centl"; "generate centl" ]; category = "build"; origin = Caramels_runtime; assurance = "parser-validated local extension"; summary = "turns supported BUILD requests into native CENTL definitions, manifests, revisions, and live downstream session reloads" };
  ]

let words text =
  let buffer = Buffer.create (String.length text) in
  String.iter
    (fun character ->
      match Char.lowercase_ascii character with
      | 'a' .. 'z' | '0' .. '9' | '_' as c -> Buffer.add_char buffer c
      | _ -> Buffer.add_char buffer ' ')
    text;
  Buffer.contents buffer |> String.split_on_char ' '
  |> List.filter (fun value -> String.length value >= 3)
  |> List.sort_uniq String.compare

let phrase_matches request_words phrase =
  let phrase_words = words phrase in
  List.exists (fun word -> List.mem word request_words) phrase_words

let score request_words capability =
  let phrases = capability.name :: capability.category :: capability.aliases in
  List.fold_left
    (fun total phrase -> if phrase_matches request_words phrase then total + 1 else total)
    0 phrases

let local_extension_capabilities workspace =
  Centl_sci_extensions.list workspace
  |> List.map (fun manifest ->
         {
           name = manifest.name;
           aliases = [];
           category = "local-extension";
           origin = Local_extension;
           assurance = manifest.assurance;
           summary =
             Printf.sprintf "%s (%s, kind=%s)" manifest.summary
               (if manifest.enabled then "enabled" else "disabled") manifest.kind;
         })

let local_package_capabilities workspace =
  Centl_sci_package.list workspace
  |> List.map (fun package ->
         {
           name = package.name;
           aliases = package.extensions;
           category = "local-package";
           origin = Local_package;
           assurance = "composition-only; member assurance preserved";
           summary =
             Printf.sprintf "%s (%d extension%s)" package.summary
               (List.length package.extensions)
               (if List.length package.extensions = 1 then "" else "s");
         })

let local_capabilities () =
  match Centl_sci_workspace.default () with
  | None -> []
  | Some workspace ->
      local_extension_capabilities workspace @ local_package_capabilities workspace

let all () = builtins @ local_capabilities ()

let search request =
  let request_words = words request in
  all ()
  |> List.map (fun capability -> (score request_words capability, capability))
  |> List.filter (fun (value, _) -> value > 0)
  |> List.sort (fun (left_score, left) (right_score, right) ->
         let by_score = compare right_score left_score in
         if by_score <> 0 then by_score else String.compare left.name right.name)
  |> List.map snd

let render capability =
  Printf.sprintf "%s — %s — assurance: %s — %s" capability.name
    (origin_text capability.origin) capability.assurance capability.summary

let render_matches request =
  match search request with
  | [] -> "  - no obvious reusable capability matched this request"
  | values ->
      values
      |> List.map (fun capability -> "  - " ^ render capability)
      |> String.concat "\n"

let render_all () =
  all ()
  |> List.sort (fun left right ->
         let by_category = String.compare left.category right.category in
         if by_category <> 0 then by_category else String.compare left.name right.name)
  |> List.map (fun capability -> "  - " ^ render capability)
  |> String.concat "\n"
