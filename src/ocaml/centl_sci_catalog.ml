type entry = {
  name : string;
  examples : string list;
  assurance : string;
  summary : string;
}

let examples_for name =
  match name with
  | "solve" ->
      [ "solve(x^2 - 5*x + 6 = 0, x)"; "Solve x^2 - 5*x + 6 = 0 for x." ]
  | "diff" ->
      [ "diff(x^3 + 2*x + 1, x)"; "differentiate x^3 + 2*x with respect to x" ]
  | "integrate" ->
      [
        "integrate(x^2, x = 0, 3)";
        "integrate x^2 with respect to x from 0 to 3";
      ]
  | "gcd" -> [ "gcd(48, 18)"; "What is the gcd of 48 and 18?" ]
  | "lcm" -> [ "lcm(4, 6)"; "lcm of 4 and 6" ]
  | "fibonacci" -> [ "fibonacci(10)"; "fibonacci of 10" ]
  | "sum" -> [ "sum(k^2, k = 1, 10)"; "sum of k^2 from 1 to 10" ]
  | "product" -> [ "product(k, k = 1, 5)"; "product of k from 1 to 5" ]
  | "sequence" -> [ "sequence(k^2, k = 1, 4)"; "sequence of k^2 from 1 to 4" ]
  | "approx" -> [ "approx(sqrt(2), 12)"; "Approximate sqrt(2) to 12 digits." ]
  | "verify" -> [ "Verify 0.1 + 0.2 equals 3/10." ]
  | "unit conversion" -> [ "Convert 100 centimeters to meters." ]
  | "physical constants" -> [ "What is the speed of light in vacuum?" ]
  | "factorial" -> [ "factorial(6)"; "factorial of 6" ]
  | "English-to-CENTL extension" ->
      [
        "make a function called square that takes x and computes x^2";
        "let harmonic_mean(a, b) = 2 / ((1/a) + (1/b))";
        "make a kinetic energy function";
      ]
  | "spoken aliases" -> [ "square of 6"; "harmonic mean of 3 and 4" ]
  | "user dialect" ->
      [ "let square(x) = x^2 and then square(6)"; "dialect"; "export dialect" ]
  | "reviewed publish" ->
      [ "publish status"; "pack contribution"; "open draft pull request" ]
  | _ -> []

let of_capability (capability : Centl_sci_capabilities.capability) =
  {
    name = capability.name;
    examples = examples_for capability.name;
    assurance = capability.assurance;
    summary = capability.summary;
  }

let entries ?workspace () =
  let extras =
    match workspace with
    | None -> []
    | Some workspace ->
        Centl_sci_capabilities.local_extension_capabilities workspace
        @ Centl_sci_capabilities.local_package_capabilities workspace
  in
  Centl_sci_capabilities.builtins @ extras |> List.map of_capability

let lookup ?workspace name =
  let name = String.lowercase_ascii (String.trim name) in
  List.find_opt
    (fun entry -> String.equal (String.lowercase_ascii entry.name) name)
    (entries ?workspace ())

let is_discovery_request text =
  let text = String.lowercase_ascii (String.trim text) in
  let text =
    if String.length text > 0 && text.[String.length text - 1] = '?' then
      String.sub text 0 (String.length text - 1) |> String.trim
    else text
  in
  List.mem text
    [
      "help";
      "catalog";
      "capabilities";
      "what can you do";
      "what can centl do";
      "what can centl-sci do";
      "what do you support";
      "what do you know";
      "list capabilities";
      "show catalog";
      "how do i write a program";
      "how do i create a program";
    ]

let render_entry entry =
  let examples =
    match entry.examples with
    | [] -> [ "  examples: none recorded" ]
    | values -> "  examples:" :: List.map (fun value -> "    " ^ value) values
  in
  String.concat "\n"
    ([ entry.name; "  " ^ entry.summary; "  assurance: " ^ entry.assurance ]
    @ examples)

let render ?workspace ?query () =
  let entries = entries ?workspace () in
  let entries =
    match query with
    | None | Some "" -> entries
    | Some query ->
        let matches = Centl_sci_capabilities.search query in
        let names =
          List.map
            (fun capability -> capability.Centl_sci_capabilities.name)
            matches
        in
        List.filter (fun entry -> List.mem entry.name names) entries
  in
  let body =
    match entries with
    | [] -> [ "No catalog entries matched." ]
    | values -> List.map render_entry values
  in
  String.concat "\n"
    ([
       "CENTL-SCi capability catalog";
       "These are deterministic surfaces. A model cannot add one by talking.";
       "";
     ]
    @ [ String.concat "\n\n" body ]
    @ [
        "";
        "Unsolved work can become a local MIRAGE cycle with `extend <request>`.";
      ])
