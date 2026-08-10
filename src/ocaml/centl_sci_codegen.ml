type change =
  | Function of { replace : bool; source : string }
  | Value of { replace : bool; source : string }

type result = Generated of change | Not_generated | Needs_clarification of string

let lower text = String.lowercase_ascii (String.trim text)

let find_substring ~needle text =
  Centl_sci_interaction.find_substring ~needle text

let split_at_ci needle text =
  let lower_text = lower text in
  match find_substring ~needle:(String.lowercase_ascii needle) lower_text with
  | None -> None
  | Some index ->
      let left = String.sub text 0 index |> String.trim in
      let right =
        String.sub text (index + String.length needle)
          (String.length text - index - String.length needle)
        |> String.trim
      in
      Some (left, right)

let strip_prefix_ci prefix text =
  let text = String.trim text in
  let lower_text = lower text in
  let prefix_lower = String.lowercase_ascii prefix in
  if String.starts_with ~prefix:prefix_lower lower_text then
    Some
      (String.sub text (String.length prefix)
         (String.length text - String.length prefix)
      |> String.trim)
  else None

let valid_identifier = Centl_sci_change_ir.valid_identifier

let split_parameters text =
  let normalized =
    text
    |> Centl_sci_interaction.replace_all ~needle:" and " ~replacement:","
    |> Centl_sci_interaction.replace_all ~needle:" " ~replacement:""
  in
  String.split_on_char ',' normalized
  |> List.map String.trim
  |> List.filter (fun value -> value <> "")

let validate_source expected source =
  match Centl_parser.parse_statement_located source with
  | Error error ->
      Error
        (Printf.sprintf
           "I generated a CENTL definition, but it does not parse at byte %d: %s. Make the implementation expression more explicit."
           error.position error.message)
  | Ok located ->
      begin match (expected, located.statement) with
      | `Function, Centl_parser.Define_function _ -> Ok source
      | `Value, Centl_parser.Define_value _ -> Ok source
      | `Function, _ -> Error "The generated source is not a CENTL function definition."
      | `Value, _ -> Error "The generated source is not a CENTL value definition."
      end

let generate_native ~replace ~target_kind ~name ~parameters ~implementation =
  let action =
    if replace then Centl_sci_change_ir.Modify else Centl_sci_change_ir.Create
  in
  let request =
    Centl_sci_change_ir.native_definition ~action ~target_kind ~name ~parameters
      ~implementation
  in
  match Centl_sci_change_ir.to_centl_source request with
  | Error message -> Needs_clarification ("Invalid change request: " ^ message ^ ".")
  | Ok source ->
      let expected =
        match target_kind with
        | Centl_sci_change_ir.Function -> `Function
        | Centl_sci_change_ir.Value -> `Value
        | _ -> `Value
      in
      begin match validate_source expected source with
      | Error message -> Needs_clarification message
      | Ok source ->
          begin match target_kind with
          | Centl_sci_change_ir.Function -> Generated (Function { replace; source })
          | Centl_sci_change_ir.Value -> Generated (Value { replace; source })
          | _ -> Not_generated
          end
      end

let parse_function ~replace text =
  let prefixes =
    if replace then
      [
        "modify a function named ";
        "modify function named ";
        "change a function named ";
        "change function named ";
      ]
    else
      [
        "create a function named ";
        "create function named ";
        "make a function named ";
        "make function named ";
        "add a function named ";
        "add function named ";
      ]
  in
  let rec body = function
    | [] -> None
    | prefix :: rest ->
        begin match strip_prefix_ci prefix text with
        | Some value -> Some value
        | None -> body rest
        end
  in
  match body prefixes with
  | None -> Not_generated
  | Some request ->
      begin match split_at_ci " that takes " request with
      | None ->
          Needs_clarification
            "A generated function needs a name, parameter list, and implementation. Example: create a function named kinetic_energy that takes mass and velocity and computes 1/2 * mass * velocity^2"
      | Some (name, _) when not (valid_identifier name) ->
          Needs_clarification
            ("`" ^ name ^ "` is not a valid CENTL function identifier.")
      | Some (name, tail) ->
          let implementation =
            match split_at_ci " and computes " tail with
            | Some value -> Some value
            | None -> split_at_ci " and returns " tail
          in
          begin match implementation with
          | None ->
              Needs_clarification
                "The function parameters were recognized, but its implementation is missing. Use `and computes ...` or `and returns ...`."
          | Some (parameters_text, expression) ->
              let parameters = split_parameters parameters_text in
              if
                parameters = []
                || List.exists (fun value -> not (valid_identifier value)) parameters
              then
                Needs_clarification
                  "One or more function parameters are not valid CENTL identifiers."
              else if String.trim expression = "" then
                Needs_clarification
                  "The generated function needs a non-empty implementation expression."
              else
                generate_native ~replace ~target_kind:Centl_sci_change_ir.Function
                  ~name ~parameters ~implementation:(String.trim expression)
          end
      end

let parse_value ~replace text =
  let prefixes =
    if replace then
      [
        "modify a value named ";
        "modify value named ";
        "change a value named ";
        "change value named ";
      ]
    else
      [
        "create a value named ";
        "create value named ";
        "make a value named ";
        "make value named ";
        "add a value named ";
        "add value named ";
      ]
  in
  let rec body = function
    | [] -> None
    | prefix :: rest ->
        begin match strip_prefix_ci prefix text with
        | Some value -> Some value
        | None -> body rest
        end
  in
  match body prefixes with
  | None -> Not_generated
  | Some request ->
      let assignment =
        match split_at_ci " equal to " request with
        | Some value -> Some value
        | None ->
            begin match split_at_ci " equals " request with
            | Some value -> Some value
            | None -> split_at_ci " as " request
            end
      in
      begin match assignment with
      | None ->
          Needs_clarification
            "A generated value needs a name and expression. Example: create a value named tau equal to 2*pi"
      | Some (name, _) when not (valid_identifier name) ->
          Needs_clarification
            ("`" ^ name ^ "` is not a valid CENTL value identifier.")
      | Some (_, expression) when String.trim expression = "" ->
          Needs_clarification "The generated value needs a non-empty expression."
      | Some (name, expression) ->
          generate_native ~replace ~target_kind:Centl_sci_change_ir.Value
            ~name ~parameters:[] ~implementation:(String.trim expression)
      end

let generate text =
  match parse_function ~replace:false text with
  | Generated _ as result | Needs_clarification _ as result -> result
  | Not_generated ->
      begin match parse_function ~replace:true text with
      | Generated _ as result | Needs_clarification _ as result -> result
      | Not_generated ->
          begin match parse_value ~replace:false text with
          | Generated _ as result | Needs_clarification _ as result -> result
          | Not_generated -> parse_value ~replace:true text
          end
      end
