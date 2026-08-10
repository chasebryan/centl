type origin = Builtin | Local_extension | Local_package

type capability = {
  name : string;
  aliases : string list;
  category : string;
  origin : origin;
  assurance : string;
  summary : string;
}

let builtins =
  [
    {
      name = "exact arithmetic";
      aliases = [ "arithmetic"; "rational"; "fraction"; "decimal" ];
      category = "mathematics";
      origin = Builtin;
      assurance = "verified/exact CENTL core where admitted";
      summary = "exact integer/rational arithmetic and exact decimal literals";
    };
    {
      name = "polynomial solve";
      aliases = [ "solve"; "roots"; "equation"; "quadratic" ];
      category = "mathematics";
      origin = Builtin;
      assurance = "verified/exact admitted polynomial core";
      summary = "single-variable rational polynomial solving in the admitted domain";
    };
    {
      name = "mathematical verification";
      aliases = [ "verify"; "claim"; "contract"; "assert" ];
      category = "mathematics";
      origin = Builtin;
      assurance = "method-specific verifier evidence";
      summary = "closed mathematical claim checking with explicit verdicts";
    };
    {
      name = "certified approximation";
      aliases = [ "approx"; "approximate"; "digits"; "enclosure" ];
      category = "numerics";
      origin = Builtin;
      assurance = "bounded numerical enclosure";
      summary = "rigorous approximation using CENTL's native enclosure machinery";
    };
    {
      name = "unit conversion";
      aliases = [ "convert"; "units"; "measurement" ];
      category = "physics";
      origin = Builtin;
      assurance = "typed exact CENTL Physics operation";
      summary = "exact rational conversion across admitted physical units";
    };
    {
      name = "uniform gravity particle";
      aliases = [ "gravity"; "particle"; "simulate"; "mechanics" ];
      category = "physics";
      origin = Builtin;
      assurance = "typed deterministic CENTL Physics operation";
      summary = "bounded discrete particle mechanics under explicit uniform gravity";
    };
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
  |> List.map (fun (manifest : Centl_sci_extensions.manifest) ->
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
  |> List.map (fun (package : Centl_sci_package.t) ->
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
  |> List.filter_map (fun capability ->
         let relevance = score request_words capability in
         if relevance = 0 then None else Some (relevance, capability))
  |> List.sort (fun (left_score, left) (right_score, right) ->
         match Int.compare right_score left_score with
         | 0 -> String.compare left.name right.name
         | order -> order)
  |> List.map snd

let origin_text = function
  | Builtin -> "builtin"
  | Local_extension -> "local-extension"
  | Local_package -> "local-package"

let render capability =
  Printf.sprintf "%s [%s; %s] — %s" capability.name
    (origin_text capability.origin) capability.assurance capability.summary

let to_json capability =
  `Assoc
    [
      ("name", `String capability.name);
      ("aliases", `List (List.map (fun alias -> `String alias) capability.aliases));
      ("category", `String capability.category);
      ("origin", `String (origin_text capability.origin));
      ("assurance", `String capability.assurance);
      ("summary", `String capability.summary);
    ]