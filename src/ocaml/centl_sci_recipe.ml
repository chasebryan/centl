type t = {
  name : string;
  phrases : string list;
  parameters : string list;
  implementation : string;
  note : string;
}

let normalize text =
  let text = String.lowercase_ascii (String.trim text) in
  let buffer = Buffer.create (String.length text) in
  let pending_space = ref false in
  String.iter
    (function
      | ('a' .. 'z' | '0' .. '9') as character ->
          if !pending_space && Buffer.length buffer > 0 then
            Buffer.add_char buffer ' ';
          pending_space := false;
          Buffer.add_char buffer character
      | '_' | '-' | '/' | ' ' | '\t' -> pending_space := true
      | _ -> ())
    text;
  Buffer.contents buffer

let phrase_of_name name =
  let buffer = Buffer.create (String.length name) in
  String.iter
    (function
      | '_' -> Buffer.add_char buffer ' '
      | character -> Buffer.add_char buffer character)
    name;
  Buffer.contents buffer

let item ~name ~phrases ~parameters ~implementation ~note =
  {
    name;
    phrases = List.sort_uniq String.compare (phrase_of_name name :: phrases);
    parameters;
    implementation;
    note;
  }

let all =
  [
    item ~name:"square" ~phrases:[ "square" ] ~parameters:[ "x" ]
      ~implementation:"x^2"
      ~note:"conventional exact definition square(x) = x^2";
    item ~name:"cube" ~phrases:[ "cube" ] ~parameters:[ "x" ]
      ~implementation:"x^3" ~note:"conventional exact definition cube(x) = x^3";
    item ~name:"double" ~phrases:[ "double" ] ~parameters:[ "x" ]
      ~implementation:"2*x" ~note:"conventional exact definition double(x) = 2x";
    item ~name:"reciprocal"
      ~phrases:[ "reciprocal"; "multiplicative inverse" ]
      ~parameters:[ "x" ] ~implementation:"1/x"
      ~note:"conventional exact definition reciprocal(x) = 1/x";
    item ~name:"midpoint" ~phrases:[ "midpoint" ] ~parameters:[ "a"; "b" ]
      ~implementation:"(a + b) / 2"
      ~note:"conventional exact midpoint of two numbers";
    item ~name:"arithmetic_mean"
      ~phrases:[ "arithmetic mean"; "average of two" ]
      ~parameters:[ "a"; "b" ] ~implementation:"(a + b) / 2"
      ~note:"conventional exact arithmetic mean of two numbers";
    item ~name:"harmonic_mean" ~phrases:[ "harmonic mean" ]
      ~parameters:[ "a"; "b" ] ~implementation:"2 / ((1/a) + (1/b))"
      ~note:"conventional exact harmonic mean of two numbers";
    item ~name:"geometric_mean" ~phrases:[ "geometric mean" ]
      ~parameters:[ "a"; "b" ] ~implementation:"sqrt(a * b)"
      ~note:"conventional exact geometric mean of two nonnegative numbers";
    item ~name:"hypotenuse"
      ~phrases:[ "hypotenuse"; "pythagorean hypotenuse" ]
      ~parameters:[ "a"; "b" ] ~implementation:"sqrt(a^2 + b^2)"
      ~note:"exact Pythagorean hypotenuse identity";
    item ~name:"percent"
      ~phrases:[ "percent"; "percentage" ]
      ~parameters:[ "part"; "whole" ] ~implementation:"100 * part / whole"
      ~note:"conventional exact percentage part/whole";
    item ~name:"distance"
      ~phrases:[ "distance"; "euclidean distance" ]
      ~parameters:[ "x1"; "y1"; "x2"; "y2" ]
      ~implementation:"sqrt((x2 - x1)^2 + (y2 - y1)^2)"
      ~note:"exact Euclidean distance in the plane";
    item ~name:"slope" ~phrases:[ "slope" ]
      ~parameters:[ "x1"; "y1"; "x2"; "y2" ]
      ~implementation:"(y2 - y1) / (x2 - x1)"
      ~note:"exact slope between two points";
    item ~name:"circle_area"
      ~phrases:[ "circle area"; "area of a circle" ]
      ~parameters:[ "radius" ] ~implementation:"pi * radius^2"
      ~note:"conventional exact disk area";
    item ~name:"circle_circumference"
      ~phrases:[ "circle circumference"; "circumference" ]
      ~parameters:[ "radius" ] ~implementation:"2 * pi * radius"
      ~note:"conventional exact circle circumference";
    item ~name:"sphere_volume"
      ~phrases:[ "sphere volume"; "volume of a sphere" ]
      ~parameters:[ "radius" ] ~implementation:"(4/3) * pi * radius^3"
      ~note:"conventional exact ball volume";
    item ~name:"sphere_surface"
      ~phrases:[ "sphere surface"; "sphere surface area" ]
      ~parameters:[ "radius" ] ~implementation:"4 * pi * radius^2"
      ~note:"conventional exact sphere surface area";
    item ~name:"rectangle_area"
      ~phrases:[ "rectangle area"; "area of a rectangle" ]
      ~parameters:[ "width"; "height" ] ~implementation:"width * height"
      ~note:"conventional exact rectangle area";
    item ~name:"triangle_area"
      ~phrases:[ "triangle area"; "area of a triangle" ]
      ~parameters:[ "base"; "height" ] ~implementation:"(1/2) * base * height"
      ~note:"conventional exact triangle area";
    item ~name:"kinetic_energy" ~phrases:[ "kinetic energy" ]
      ~parameters:[ "mass"; "velocity" ]
      ~implementation:"1/2 * mass * velocity^2"
      ~note:"conventional exact definition KE = 1/2 m v^2";
    item ~name:"gravitational_potential_energy"
      ~phrases:[ "gravitational potential energy"; "potential energy" ]
      ~parameters:[ "mass"; "g"; "height" ] ~implementation:"mass * g * height"
      ~note:"conventional exact definition PE = m g h, with g supplied";
    item ~name:"momentum" ~phrases:[ "momentum" ]
      ~parameters:[ "mass"; "velocity" ] ~implementation:"mass * velocity"
      ~note:"conventional exact definition p = m v";
    item ~name:"work"
      ~phrases:[ "mechanical work"; "work" ]
      ~parameters:[ "force"; "distance" ] ~implementation:"force * distance"
      ~note:"conventional exact definition W = F d along the line of force";
    item ~name:"density" ~phrases:[ "density" ] ~parameters:[ "mass"; "volume" ]
      ~implementation:"mass / volume"
      ~note:"conventional exact definition density = mass / volume";
    item ~name:"average_speed" ~phrases:[ "average speed" ]
      ~parameters:[ "distance"; "time" ] ~implementation:"distance / time"
      ~note:"conventional exact definition average speed = distance / time";
  ]

let names_equal left right = String.equal (normalize left) (normalize right)

let lookup text =
  let text = normalize text in
  if text = "" then None
  else
    List.find_opt
      (fun recipe ->
        names_equal recipe.name text
        || List.exists (fun phrase -> names_equal phrase text) recipe.phrases)
      all

let strip_prefix_ci prefix text =
  let text = String.trim text in
  let lower = String.lowercase_ascii text in
  let prefix_lower = String.lowercase_ascii prefix in
  if String.starts_with ~prefix:prefix_lower lower then
    Some
      (String.sub text (String.length prefix)
         (String.length text - String.length prefix)
      |> String.trim)
  else None

let strip_wrapper text =
  let text = String.trim text in
  let prefixes =
    [
      "make me a ";
      "write me a ";
      "create me a ";
      "make a ";
      "create a ";
      "write a ";
      "add a ";
      "i need a ";
      "i want a ";
      "make ";
      "create ";
      "write ";
    ]
  in
  let rec strip_prefix = function
    | [] -> text
    | prefix :: rest -> (
        match strip_prefix_ci prefix text with
        | Some body when body <> "" -> body
        | _ -> strip_prefix rest)
  in
  let body = strip_prefix prefixes in
  let suffixes = [ " function"; " program"; " helper"; " definition" ] in
  let rec strip_suffix current = function
    | [] -> current
    | suffix :: rest ->
        let lower = String.lowercase_ascii current in
        if
          String.ends_with ~suffix lower
          && String.length current > String.length suffix
        then
          String.sub current 0 (String.length current - String.length suffix)
          |> String.trim
        else strip_suffix current rest
  in
  strip_suffix body suffixes

let lookup_request text =
  match lookup text with
  | Some _ as value -> value
  | None -> lookup (strip_wrapper text)

let source recipe =
  Printf.sprintf "%s(%s) = %s" recipe.name
    (String.concat ", " recipe.parameters)
    recipe.implementation
