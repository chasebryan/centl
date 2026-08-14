let take n values =
  let rec loop count acc = function
    | [] -> List.rev acc
    | _ when count = 0 -> List.rev acc
    | value :: rest -> loop (count - 1) (value :: acc) rest
  in
  loop n [] values

let related problem =
  Centl_sci_capabilities.search problem
  |> take 3
  |> List.map (fun capability ->
      capability.Centl_sci_capabilities.name ^ " — " ^ capability.summary)

let render ?problem () =
  let related =
    match problem with None -> [] | Some problem -> related problem
  in
  let related_lines =
    match related with
    | [] -> [ "I did not invent a mathematical answer." ]
    | values ->
        "Related deterministic capabilities:"
        :: List.map (fun value -> "  - " ^ value) values
  in
  String.concat "\n"
    (related_lines
    @ [
        "Try an explicit CENTL expression, `catalog`, `make a function called \
         square that takes x and computes x^2`, or `extend <request>` to start \
         a local MIRAGE cycle.";
        "A model suggestion would still have to pass the same parser and \
         evidence gates.";
      ])
