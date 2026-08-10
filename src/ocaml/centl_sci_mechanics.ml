let find_substring ~needle text =
  Centl_sci_interaction.find_substring ~needle text

let strip_separators text =
  let text = String.trim text in
  let separator = function ',' | ';' | ':' | '.' -> true | _ -> false in
  let rec start index =
    if index >= String.length text then index
    else if separator text.[index] then start (index + 1)
    else index
  in
  let rec finish index =
    if index <= 0 then 0
    else if separator text.[index - 1] then finish (index - 1)
    else index
  in
  let first = start 0 in
  let last = finish (String.length text) in
  if last <= first then ""
  else String.sub text first (last - first) |> String.trim

let section ~from_marker ~to_marker text lower =
  match find_substring ~needle:from_marker lower with
  | None -> None
  | Some from_index ->
      let content_start = from_index + String.length from_marker in
      let remaining_lower =
        String.sub lower content_start (String.length lower - content_start)
      in
      begin match find_substring ~needle:to_marker remaining_lower with
      | None -> None
      | Some relative ->
          Some (String.sub text content_start relative |> strip_separators)
      end

let trailing ~marker text lower =
  match find_substring ~needle:marker lower with
  | None -> None
  | Some index ->
      let start = index + String.length marker in
      Some
        (String.sub text start (String.length text - start) |> strip_separators)

let split_first_space text =
  let text = strip_separators text in
  match String.index_opt text ' ' with
  | None -> None
  | Some index ->
      let left = String.sub text 0 index |> String.trim in
      let right =
        String.sub text (index + 1) (String.length text - index - 1)
        |> strip_separators
      in
      if left = "" || right = "" then None else Some (left, right)

let parse_quantity = split_first_space

let parse_vector text =
  let text = strip_separators text in
  match (String.index_opt text '(', String.index_opt text ')') with
  | Some open_index, Some close_index when close_index > open_index ->
      let body =
        String.sub text (open_index + 1) (close_index - open_index - 1)
      in
      let unit =
        String.sub text (close_index + 1) (String.length text - close_index - 1)
        |> strip_separators
      in
      begin match String.split_on_char ',' body |> List.map String.trim with
      | [ x; y; z ] when x <> "" && y <> "" && z <> "" && unit <> "" ->
          Some (x, y, z, unit)
      | _ -> None
      end
  | _ -> None

let parse_steps text =
  let cleaned = strip_separators text in
  let lower = String.lowercase_ascii cleaned in
  let cleaned =
    if String.ends_with ~suffix:" steps" lower then
      String.sub cleaned 0 (String.length cleaned - 6) |> String.trim
    else cleaned
  in
  match int_of_string_opt cleaned with
  | Some value when value > 0 && value <= 100_000 -> Some value
  | _ -> None

let looks_like_request input =
  let lower = String.lowercase_ascii (String.trim input) in
  String.starts_with ~prefix:"simulate particle" lower
  || String.starts_with ~prefix:"simulate a particle" lower
  || String.starts_with ~prefix:"simulate the particle" lower

let missing_fields input =
  if not (looks_like_request input) then []
  else
    let lower = String.lowercase_ascii input in
    [
      ("mass", "mass ");
      ("position", "position ");
      ("velocity", "velocity ");
      ("gravity", "gravity ");
      ("dt", "dt ");
      ("steps", "steps ");
    ]
    |> List.filter_map (fun (name, marker) ->
           if Option.is_some (find_substring ~needle:marker lower) then None
           else Some name)

let interpret input =
  if not (looks_like_request input) then None
  else
    let text = String.trim input in
    let lower = String.lowercase_ascii text in
    match
      ( section ~from_marker:"mass " ~to_marker:"position " text lower,
        section ~from_marker:"position " ~to_marker:"velocity " text lower,
        section ~from_marker:"velocity " ~to_marker:"gravity " text lower,
        section ~from_marker:"gravity " ~to_marker:"dt " text lower,
        section ~from_marker:"dt " ~to_marker:"steps " text lower,
        trailing ~marker:"steps " text lower )
    with
    | Some mass, Some position, Some velocity, Some gravity, Some dt, Some steps ->
        begin match
          ( parse_quantity mass,
            parse_vector position,
            parse_vector velocity,
            parse_vector gravity,
            parse_quantity dt,
            parse_steps steps )
        with
        | Some (mass_value, mass_unit),
          Some (position_x, position_y, position_z, position_unit),
          Some (velocity_x, velocity_y, velocity_z, velocity_unit),
          Some (gravity_x, gravity_y, gravity_z, gravity_unit),
          Some (dt_value, dt_unit), Some steps ->
            begin match
              Centl_sci_ir.of_json
                (`Assoc
                   [
                     ("schema_version", `Int 1);
                     ("domain", `String "physics");
                     ("problem_class", `String "uniform_gravity_particle");
                     ("operation", `String "simulate");
                     ("assumptions", `List []);
                     ("mass_value", `String mass_value);
                     ("mass_unit", `String mass_unit);
                     ("position_x", `String position_x);
                     ("position_y", `String position_y);
                     ("position_z", `String position_z);
                     ("position_unit", `String position_unit);
                     ("velocity_x", `String velocity_x);
                     ("velocity_y", `String velocity_y);
                     ("velocity_z", `String velocity_z);
                     ("velocity_unit", `String velocity_unit);
                     ("gravity_x", `String gravity_x);
                     ("gravity_y", `String gravity_y);
                     ("gravity_z", `String gravity_z);
                     ("gravity_unit", `String gravity_unit);
                     ("dt_value", `String dt_value);
                     ("dt_unit", `String dt_unit);
                     ("steps", `Int steps);
                   ])
            with
            | Ok ir -> Some ir
            | Error _ -> None
            end
        | _ -> None
        end
    | _ -> None

let example =
  "simulate a particle with mass 2 kg, position (0,0,10) m, velocity (1,0,0) m/s, gravity (0,0,-10) m/s^2, dt 1/10 s, steps 10"
