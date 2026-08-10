type origin = Verified_core | Physics_engine | Local_extension

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
  | Local_extension -> "local downstream extension"

let builtins =
  [
    { name = "solve"; aliases = [ "equation"; "root"; "zero" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "supported equation-solving path" };
    { name = "diff"; aliases = [ "differentiate"; "derivative" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "symbolic differentiation for supported expressions" };
    { name = "integrate"; aliases = [ "integral"; "antiderivative" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "supported exact integration path" };
    { name = "simplify"; aliases = [ "canonicalize"; "simplification" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "supported symbolic simplification" };
    { name = "expand"; aliases = [ "polynomial expansion" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "supported symbolic expansion" };
    { name = "factor"; aliases = [ "factorization"; "factorisation" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "supported polynomial factoring domain" };
    { name = "substitute"; aliases = [ "substitution"; "replace variable" ]; category = "mathematics"; origin = Verified_core; assurance = "core"; summary = "symbolic substitution" };
    { name = "approx"; aliases = [ "approximate"; "decimal"; "enclosure" ]; category = "mathematics"; origin = Verified_core; assurance = "certified/existing"; summary = "precision-aware approximation/enclosure path" };
    { name = "verify"; aliases = [ "claim"; "contract"; "assert" ]; category = "mathematics"; origin = Verified_core; assurance = "verification"; summary = "structured mathematical claim verification" };
    { name = "unit conversion"; aliases = [ "convert"; "units"; "dimension" ]; category = "physics"; origin = Physics_engine; assurance = "deterministic"; summary = "exact dimension-checked unit conversion" };
    { name = "physical constants"; aliases = [ "constant"; "speed of light"; "planck"; "boltzmann"; "avogadro" ]; category = "physics"; origin = Physics_engine; assurance = "deterministic exact catalog"; summary = "exact defining/conventional physics constants with provenance" };
    { name = "particle simulation"; aliases = [ "simulate"; "gravity"; "particle"; "mechanics" ]; category = "physics"; origin = Physics_engine; assurance = "deterministic model"; summary = "particle integration including explicit uniform gravity" };
    { name = "sphere contact analysis"; aliases = [ "sphere"; "contact"; "collision" ]; category = "physics"; origin = Physics_engine; assurance = "exact geometry"; summary = "exact sphere contact classification and bounded contact machinery" };
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

let local_capabilities () =
  match Centl_sci_workspace.default () with
  | None -> []
  | Some workspace ->
      Centl_sci_extensions.list workspace
      |> List.map (fun manifest ->
             {
               name = manifest.name;
               aliases = [];
               category = "local";
               origin = Local_extension;
               assurance = manifest.assurance;
               summary =
                 Printf.sprintf "%s (%s)" manifest.summary
                   (if manifest.enabled then "enabled" else "disabled");
             })

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
