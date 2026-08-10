type error = { code : string; message : string }

type t =
  | Exact_expression of { expression : string; exact_assumptions : string list }
  | Polynomial_equation of {
      left : string;
      right : string;
      variable : string;
      equation_assumptions : string list;
    }
  | Unit_conversion of {
      value : string;
      from_unit : string;
      to_unit : string;
      conversion_assumptions : string list;
    }
  | Physical_constant of {
      symbol : string;
      constant_assumptions : string list;
    }
  | Uniform_gravity_particle of {
      mass_value : string;
      mass_unit : string;
      position_x : string;
      position_y : string;
      position_z : string;
      position_unit : string;
      velocity_x : string;
      velocity_y : string;
      velocity_z : string;
      velocity_unit : string;
      gravity_x : string;
      gravity_y : string;
      gravity_z : string;
      gravity_unit : string;
      dt_value : string;
      dt_unit : string;
      steps : int;
      mechanics_assumptions : string list;
    }
  | Unsupported of {
      unsupported_reason : string;
      unsupported_assumptions : string list;
    }

let ( let* ) = Result.bind
let fail code message = Error { code; message }
let string_of_error error = error.code ^ ": " ^ error.message
let max_model_text_bytes = 4_096
let max_assumptions = 16
let max_assumption_bytes = 512
let max_value_bytes = 256
let max_unit_bytes = 64
let max_reason_bytes = 1_024

let has_control text =
  let rec loop index =
    if index = String.length text then false
    else
      let code = Char.code text.[index] in
      if code < 32 || code = 127 then true else loop (index + 1)
  in
  loop 0

let validate_text ~field ~max_bytes text =
  if String.length text = 0 then fail "invalid_ir" (field ^ " must not be empty")
  else if String.length text > max_bytes then
    fail "resource_limit" (field ^ " exceeds the CENTL-SCi byte limit")
  else if has_control text then
    fail "invalid_ir" (field ^ " contains a control character")
  else Ok text

let valid_identifier text =
  let is_first = function
    | 'a' .. 'z' | 'A' .. 'Z' | '_' -> true
    | _ -> false
  in
  let is_rest = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
    | _ -> false
  in
  let rec rest index =
    if index = String.length text then true
    else if is_rest text.[index] then rest (index + 1)
    else false
  in
  String.length text > 0 && is_first text.[0] && rest 1

let contains_any text characters =
  let rec loop index =
    if index = String.length text then false
    else if List.mem text.[index] characters then true
    else loop (index + 1)
  in
  loop 0

let check_no_duplicates fields =
  let rec loop seen = function
    | [] -> Ok ()
    | (name, _) :: rest ->
        if List.mem name seen then fail "invalid_ir" ("duplicate field " ^ name)
        else loop (name :: seen) rest
  in
  loop [] fields

let check_fields allowed fields =
  let* () = check_no_duplicates fields in
  match List.find_opt (fun (name, _) -> not (List.mem name allowed)) fields with
  | None -> Ok ()
  | Some (name, _) -> fail "invalid_ir" ("unknown field " ^ name)

let string_field name fields =
  match List.assoc_opt name fields with
  | Some (`String value) -> Ok value
  | None -> fail "invalid_ir" ("missing field " ^ name)
  | Some _ -> fail "invalid_ir" (name ^ " must be a string")

let int_field name fields =
  match List.assoc_opt name fields with
  | Some (`Int value) -> Ok value
  | None -> fail "invalid_ir" ("missing field " ^ name)
  | Some _ -> fail "invalid_ir" (name ^ " must be an integer")

let assumptions_field fields =
  match List.assoc_opt "assumptions" fields with
  | Some (`List assumptions) ->
      if List.length assumptions > max_assumptions then
        fail "resource_limit" "too many interpreter assumptions"
      else
        let rec parse acc = function
          | [] -> Ok (List.rev acc)
          | `String assumption :: rest ->
              let* assumption =
                validate_text ~field:"assumption"
                  ~max_bytes:max_assumption_bytes assumption
              in
              parse (assumption :: acc) rest
          | _ -> fail "invalid_ir" "assumptions must contain only strings"
        in
        parse [] assumptions
  | None -> fail "invalid_ir" "missing field assumptions"
  | Some _ -> fail "invalid_ir" "assumptions must be an array"

let common_fields =
  [ "schema_version"; "domain"; "problem_class"; "operation"; "assumptions" ]

let require_common fields ~domain ~problem_class ~operation =
  let* version = int_field "schema_version" fields in
  if version <> 1 then fail "invalid_ir" "schema_version must be 1"
  else
    let* actual_domain = string_field "domain" fields in
    let* actual_class = string_field "problem_class" fields in
    let* actual_operation = string_field "operation" fields in
    if actual_domain <> domain then
      fail "invalid_ir" ("domain must be " ^ domain)
    else if actual_class <> problem_class then
      fail "invalid_ir" ("problem_class must be " ^ problem_class)
    else if actual_operation <> operation then
      fail "invalid_ir" ("operation must be " ^ operation)
    else assumptions_field fields

let validate_value field value = validate_text ~field ~max_bytes:max_value_bytes value
let validate_unit field value = validate_text ~field ~max_bytes:max_unit_bytes value

let parse_exact_expression fields =
  let allowed = "expression" :: common_fields in
  let* () = check_fields allowed fields in
  let* assumptions =
    require_common fields ~domain:"mathematics"
      ~problem_class:"exact_expression" ~operation:"compute"
  in
  let* expression = string_field "expression" fields in
  let* expression =
    validate_text ~field:"expression" ~max_bytes:max_model_text_bytes expression
  in
  Ok (Exact_expression { expression; exact_assumptions = assumptions })

let parse_polynomial_equation fields =
  let allowed = [ "left"; "right"; "relation"; "variable" ] @ common_fields in
  let* () = check_fields allowed fields in
  let* assumptions =
    require_common fields ~domain:"mathematics"
      ~problem_class:"polynomial_equation" ~operation:"solve"
  in
  let* relation = string_field "relation" fields in
  if relation <> "equal" then
    fail "invalid_ir" "polynomial_equation relation must be equal"
  else
    let* left = string_field "left" fields in
    let* right = string_field "right" fields in
    let* variable = string_field "variable" fields in
    let* left =
      validate_text ~field:"left" ~max_bytes:max_model_text_bytes left
    in
    let* right =
      validate_text ~field:"right" ~max_bytes:max_model_text_bytes right
    in
    let* variable = validate_text ~field:"variable" ~max_bytes:64 variable in
    if not (valid_identifier variable) then
      fail "invalid_ir" "variable must be a CENTL identifier"
    else if
      contains_any left [ ','; '='; ';' ]
      || contains_any right [ ','; '='; ';' ]
    then
      fail "invalid_ir"
        "equation sides may not contain commas, equality signs, or semicolons"
    else
      Ok
        (Polynomial_equation
           { left; right; variable; equation_assumptions = assumptions })

let parse_unit_conversion fields =
  let allowed = [ "value"; "from_unit"; "to_unit" ] @ common_fields in
  let* () = check_fields allowed fields in
  let* assumptions =
    require_common fields ~domain:"physics" ~problem_class:"unit_conversion"
      ~operation:"convert"
  in
  let* value = string_field "value" fields in
  let* from_unit = string_field "from_unit" fields in
  let* to_unit = string_field "to_unit" fields in
  let* value = validate_value "value" value in
  let* from_unit = validate_unit "from_unit" from_unit in
  let* to_unit = validate_unit "to_unit" to_unit in
  Ok
    (Unit_conversion
       { value; from_unit; to_unit; conversion_assumptions = assumptions })

let supported_constant_symbol = function
  | "c" | "h" | "e" | "k_B" | "N_A" | "g0" -> true
  | _ -> false

let parse_physical_constant fields =
  let* () = check_fields ("symbol" :: common_fields) fields in
  let* assumptions =
    require_common fields ~domain:"physics" ~problem_class:"physical_constant"
      ~operation:"constant"
  in
  let* symbol = string_field "symbol" fields in
  let* symbol = validate_text ~field:"symbol" ~max_bytes:32 symbol in
  if supported_constant_symbol symbol then
    Ok (Physical_constant { symbol; constant_assumptions = assumptions })
  else
    fail "invalid_ir"
      "physical constant is outside the exact defining/conventional Caramels catalog"

let parse_uniform_gravity_particle fields =
  let specific =
    [
      "mass_value"; "mass_unit";
      "position_x"; "position_y"; "position_z"; "position_unit";
      "velocity_x"; "velocity_y"; "velocity_z"; "velocity_unit";
      "gravity_x"; "gravity_y"; "gravity_z"; "gravity_unit";
      "dt_value"; "dt_unit"; "steps";
    ]
  in
  let* () = check_fields (specific @ common_fields) fields in
  let* assumptions =
    require_common fields ~domain:"physics"
      ~problem_class:"uniform_gravity_particle" ~operation:"simulate"
  in
  let* mass_value = string_field "mass_value" fields in
  let* mass_unit = string_field "mass_unit" fields in
  let* position_x = string_field "position_x" fields in
  let* position_y = string_field "position_y" fields in
  let* position_z = string_field "position_z" fields in
  let* position_unit = string_field "position_unit" fields in
  let* velocity_x = string_field "velocity_x" fields in
  let* velocity_y = string_field "velocity_y" fields in
  let* velocity_z = string_field "velocity_z" fields in
  let* velocity_unit = string_field "velocity_unit" fields in
  let* gravity_x = string_field "gravity_x" fields in
  let* gravity_y = string_field "gravity_y" fields in
  let* gravity_z = string_field "gravity_z" fields in
  let* gravity_unit = string_field "gravity_unit" fields in
  let* dt_value = string_field "dt_value" fields in
  let* dt_unit = string_field "dt_unit" fields in
  let* steps = int_field "steps" fields in
  let* mass_value = validate_value "mass_value" mass_value in
  let* mass_unit = validate_unit "mass_unit" mass_unit in
  let* position_x = validate_value "position_x" position_x in
  let* position_y = validate_value "position_y" position_y in
  let* position_z = validate_value "position_z" position_z in
  let* position_unit = validate_unit "position_unit" position_unit in
  let* velocity_x = validate_value "velocity_x" velocity_x in
  let* velocity_y = validate_value "velocity_y" velocity_y in
  let* velocity_z = validate_value "velocity_z" velocity_z in
  let* velocity_unit = validate_unit "velocity_unit" velocity_unit in
  let* gravity_x = validate_value "gravity_x" gravity_x in
  let* gravity_y = validate_value "gravity_y" gravity_y in
  let* gravity_z = validate_value "gravity_z" gravity_z in
  let* gravity_unit = validate_unit "gravity_unit" gravity_unit in
  let* dt_value = validate_value "dt_value" dt_value in
  let* dt_unit = validate_unit "dt_unit" dt_unit in
  if steps <= 0 then fail "invalid_ir" "steps must be positive"
  else if steps > 100_000 then
    fail "resource_limit" "steps exceed the physics protocol limit"
  else
    Ok
      (Uniform_gravity_particle
         {
           mass_value; mass_unit;
           position_x; position_y; position_z; position_unit;
           velocity_x; velocity_y; velocity_z; velocity_unit;
           gravity_x; gravity_y; gravity_z; gravity_unit;
           dt_value; dt_unit; steps;
           mechanics_assumptions = assumptions;
         })

let parse_unsupported fields =
  let allowed = "reason" :: common_fields in
  let* () = check_fields allowed fields in
  let* assumptions =
    require_common fields ~domain:"unsupported" ~problem_class:"unsupported"
      ~operation:"unsupported"
  in
  let* reason = string_field "reason" fields in
  let* reason =
    validate_text ~field:"reason" ~max_bytes:max_reason_bytes reason
  in
  Ok
    (Unsupported
       { unsupported_reason = reason; unsupported_assumptions = assumptions })

let of_json = function
  | `Assoc fields ->
      begin match List.assoc_opt "problem_class" fields with
      | Some (`String "exact_expression") -> parse_exact_expression fields
      | Some (`String "polynomial_equation") -> parse_polynomial_equation fields
      | Some (`String "unit_conversion") -> parse_unit_conversion fields
      | Some (`String "physical_constant") -> parse_physical_constant fields
      | Some (`String "uniform_gravity_particle") -> parse_uniform_gravity_particle fields
      | Some (`String "unsupported") -> parse_unsupported fields
      | Some (`String value) ->
          fail "unsupported_problem_class" ("unsupported problem_class " ^ value)
      | Some _ -> fail "invalid_ir" "problem_class must be a string"
      | None -> fail "invalid_ir" "missing field problem_class"
      end
  | _ -> fail "invalid_ir" "model output must be a JSON object"

let of_string text =
  if String.length text > 32_768 then
    fail "resource_limit" "model output exceeds the CENTL-SCi byte limit"
  else
    try Yojson.Safe.from_string text |> of_json
    with Yojson.Json_error message ->
      fail "invalid_model_output" ("invalid JSON: " ^ message)

let assumptions = function
  | Exact_expression value -> value.exact_assumptions
  | Polynomial_equation value -> value.equation_assumptions
  | Unit_conversion value -> value.conversion_assumptions
  | Physical_constant value -> value.constant_assumptions
  | Uniform_gravity_particle value -> value.mechanics_assumptions
  | Unsupported value -> value.unsupported_assumptions

let domain = function
  | Exact_expression _ | Polynomial_equation _ -> "mathematics"
  | Unit_conversion _ | Physical_constant _ | Uniform_gravity_particle _ -> "physics"
  | Unsupported _ -> "unsupported"

let problem_class = function
  | Exact_expression _ -> "exact_expression"
  | Polynomial_equation _ -> "polynomial_equation"
  | Unit_conversion _ -> "unit_conversion"
  | Physical_constant _ -> "physical_constant"
  | Uniform_gravity_particle _ -> "uniform_gravity_particle"
  | Unsupported _ -> "unsupported"

let operation = function
  | Exact_expression _ -> "compute"
  | Polynomial_equation _ -> "solve"
  | Unit_conversion _ -> "convert"
  | Physical_constant _ -> "constant"
  | Uniform_gravity_particle _ -> "simulate"
  | Unsupported _ -> "unsupported"

let strings values = `List (List.map (fun value -> `String value) values)

let to_json value =
  let common assumptions =
    [
      ("schema_version", `Int 1);
      ("domain", `String (domain value));
      ("problem_class", `String (problem_class value));
      ("operation", `String (operation value));
      ("assumptions", strings assumptions);
    ]
  in
  match value with
  | Exact_expression data ->
      `Assoc
        (common data.exact_assumptions
        @ [ ("expression", `String data.expression) ])
  | Polynomial_equation data ->
      `Assoc
        (common data.equation_assumptions
        @ [
            ("left", `String data.left);
            ("relation", `String "equal");
            ("right", `String data.right);
            ("variable", `String data.variable);
          ])
  | Unit_conversion data ->
      `Assoc
        (common data.conversion_assumptions
        @ [
            ("value", `String data.value);
            ("from_unit", `String data.from_unit);
            ("to_unit", `String data.to_unit);
          ])
  | Physical_constant data ->
      `Assoc
        (common data.constant_assumptions @ [ ("symbol", `String data.symbol) ])
  | Uniform_gravity_particle data ->
      `Assoc
        (common data.mechanics_assumptions
        @ [
            ("mass_value", `String data.mass_value);
            ("mass_unit", `String data.mass_unit);
            ("position_x", `String data.position_x);
            ("position_y", `String data.position_y);
            ("position_z", `String data.position_z);
            ("position_unit", `String data.position_unit);
            ("velocity_x", `String data.velocity_x);
            ("velocity_y", `String data.velocity_y);
            ("velocity_z", `String data.velocity_z);
            ("velocity_unit", `String data.velocity_unit);
            ("gravity_x", `String data.gravity_x);
            ("gravity_y", `String data.gravity_y);
            ("gravity_z", `String data.gravity_z);
            ("gravity_unit", `String data.gravity_unit);
            ("dt_value", `String data.dt_value);
            ("dt_unit", `String data.dt_unit);
            ("steps", `Int data.steps);
          ])
  | Unsupported data ->
      `Assoc
        (common data.unsupported_assumptions
        @ [ ("reason", `String data.unsupported_reason) ])

let json_schema = Centl_sci_schema.json_schema
