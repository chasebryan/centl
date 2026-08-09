type error = { code : string; message : string }

type t =
  | Exact_expression of {
      expression : string;
      exact_assumptions : string list;
    }
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
  | Unsupported of { unsupported_reason : string; unsupported_assumptions : string list }

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
                validate_text ~field:"assumption" ~max_bytes:max_assumption_bytes
                  assumption
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
    let* left = validate_text ~field:"left" ~max_bytes:max_model_text_bytes left in
    let* right =
      validate_text ~field:"right" ~max_bytes:max_model_text_bytes right
    in
    let* variable = validate_text ~field:"variable" ~max_bytes:64 variable in
    if not (valid_identifier variable) then
      fail "invalid_ir" "variable must be a CENTL identifier"
    else if contains_any left [ ','; '='; ';' ] || contains_any right [ ','; '='; ';' ]
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
  let* value = validate_text ~field:"value" ~max_bytes:max_value_bytes value in
  let* from_unit =
    validate_text ~field:"from_unit" ~max_bytes:max_unit_bytes from_unit
  in
  let* to_unit = validate_text ~field:"to_unit" ~max_bytes:max_unit_bytes to_unit in
  Ok
    (Unit_conversion
       { value; from_unit; to_unit; conversion_assumptions = assumptions })

let parse_unsupported fields =
  let allowed = "reason" :: common_fields in
  let* () = check_fields allowed fields in
  let* assumptions =
    require_common fields ~domain:"unsupported" ~problem_class:"unsupported"
      ~operation:"unsupported"
  in
  let* reason = string_field "reason" fields in
  let* reason = validate_text ~field:"reason" ~max_bytes:max_reason_bytes reason in
  Ok
    (Unsupported
       { unsupported_reason = reason; unsupported_assumptions = assumptions })

let of_json = function
  | `Assoc fields ->
      begin match List.assoc_opt "problem_class" fields with
      | Some (`String "exact_expression") -> parse_exact_expression fields
      | Some (`String "polynomial_equation") -> parse_polynomial_equation fields
      | Some (`String "unit_conversion") -> parse_unit_conversion fields
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
  | Unsupported value -> value.unsupported_assumptions

let domain = function
  | Exact_expression _ | Polynomial_equation _ -> "mathematics"
  | Unit_conversion _ -> "physics"
  | Unsupported _ -> "unsupported"

let problem_class = function
  | Exact_expression _ -> "exact_expression"
  | Polynomial_equation _ -> "polynomial_equation"
  | Unit_conversion _ -> "unit_conversion"
  | Unsupported _ -> "unsupported"

let operation = function
  | Exact_expression _ -> "compute"
  | Polynomial_equation _ -> "solve"
  | Unit_conversion _ -> "convert"
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
      `Assoc (common data.exact_assumptions @ [ ("expression", `String data.expression) ])
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
  | Unsupported data ->
      `Assoc
        (common data.unsupported_assumptions
        @ [ ("reason", `String data.unsupported_reason) ])

let json_schema =
  {|{"type":"object","properties":{"schema_version":{"type":"integer","const":1},"domain":{"type":"string","enum":["mathematics","physics","unsupported"]},"problem_class":{"type":"string","enum":["exact_expression","polynomial_equation","unit_conversion","unsupported"]},"operation":{"type":"string","enum":["compute","solve","convert","unsupported"]},"assumptions":{"type":"array","maxItems":16,"items":{"type":"string","maxLength":512}},"expression":{"type":"string","maxLength":4096},"left":{"type":"string","maxLength":4096},"relation":{"type":"string","enum":["equal"]},"right":{"type":"string","maxLength":4096},"variable":{"type":"string","maxLength":64},"value":{"type":"string","maxLength":256},"from_unit":{"type":"string","maxLength":64},"to_unit":{"type":"string","maxLength":64},"reason":{"type":"string","maxLength":1024}},"required":["schema_version","domain","problem_class","operation","assumptions"],"additionalProperties":false}|}
