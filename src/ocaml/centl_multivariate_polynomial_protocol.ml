open Centl_multivariate_polynomial

type limits = {
  max_terms : int;
  max_variables : int;
  max_powers_per_term : int;
  max_exponent : int;
  max_exact_bits : int;
  max_work : int;
  max_result_bytes : int;
}

let default_limits =
  {
    max_terms = 4_096;
    max_variables = 128;
    max_powers_per_term = 128;
    max_exponent = 1_000_000;
    max_exact_bits = 1_000_000;
    max_work = 8_000_000;
    max_result_bytes = 1_048_576;
  }

let rational_text value =
  let numerator = Q.num value in
  let denominator = Q.den value in
  if Z.equal denominator Z.one then Z.to_string numerator
  else Z.to_string numerator ^ "/" ^ Z.to_string denominator

let rational_json value =
  `Assoc
    [
      ("numerator", `String (Z.to_string (Q.num value)));
      ("denominator", `String (Z.to_string (Q.den value)));
      ("text", `String (rational_text value));
    ]

let power_json (variable, exponent) =
  `Assoc
    [ ("variable", `String variable); ("exponent", `Int exponent) ]

let monomial_text powers =
  powers
  |> List.map (fun (variable, exponent) ->
         if exponent = 1 then variable
         else Printf.sprintf "%s^%d" variable exponent)
  |> String.concat "*"

let term_text powers coefficient =
  if powers = [] then rational_text coefficient
  else
    let monomial = monomial_text powers in
    if Q.equal coefficient Q.one then monomial
    else if Q.equal coefficient Q.minus_one then "-" ^ monomial
    else rational_text coefficient ^ "*" ^ monomial

let polynomial_text polynomial =
  match bindings polynomial with
  | [] -> "0"
  | terms ->
      terms
      |> List.map (fun (powers, coefficient) -> term_text powers coefficient)
      |> String.concat " + "

let term_json (powers, coefficient) =
  `Assoc
    [
      ("coefficient", rational_json coefficient);
      ("powers", `List (List.map power_json powers));
    ]

let polynomial_json polynomial =
  `Assoc
    [
      ("kind", `String "multivariate_rational_polynomial");
      ("exact", `Bool true);
      ("term_count", `Int (term_count polynomial));
      ("variables", `List (List.map (fun variable -> `String variable) (variables polynomial)));
      ("terms", `List (List.map term_json (bindings polynomial)));
      ("text", `String (polynomial_text polynomial));
    ]

let provenance method_ classification =
  `Assoc
    [
      ("schema", `Int 1);
      ( "producer",
        `Assoc
          [
            ("name", `String "centl");
            ("version", `String Centl_version.value);
          ] );
      ("classification", `String classification);
      ("method", `String method_);
      ("backend", `String "centl-exact-multivariate-polynomial");
    ]

let success ~method_ result =
  `Assoc
    [
      ("version", `Int 1);
      ("ok", `Bool true);
      ("result", result);
      ("provenance", provenance method_ "exact");
    ]

let failure ~method_ code message =
  `Assoc
    [
      ("version", `Int 1);
      ("ok", `Bool false);
      ( "error",
        `Assoc
          [
            ("code", `String code);
            ("message", `String message);
            ("retryable", `Bool (String.equal code "resource_limit"));
          ] );
      ("provenance", provenance method_ "failure");
    ]

let error_of_polynomial = function
  | Empty_variable -> ("invalid_polynomial", error_message Empty_variable)
  | Negative_exponent (variable, exponent) ->
      ("invalid_polynomial", error_message (Negative_exponent (variable, exponent)))
  | Exponent_overflow variable ->
      ("resource_limit", error_message (Exponent_overflow variable))
  | Undefined_zero_power -> ("undefined_power", error_message Undefined_zero_power)
  | Negative_power exponent ->
      ("unsupported_exact_polynomial_operation", error_message (Negative_power exponent))
  | Duplicate_substitution variable ->
      ("invalid_request", error_message (Duplicate_substitution variable))

let parse_q label = function
  | `String text ->
      begin
        try Ok (Q.of_string text)
        with Invalid_argument _ | Failure _ ->
          Error ("invalid exact rational in " ^ label ^ ": " ^ text)
      end
  | _ -> Error (label ^ " must be an exact-rational string")

let check_fields allowed fields =
  match List.find_opt (fun (name, _) -> not (List.mem name allowed)) fields with
  | None -> Ok ()
  | Some (name, _) -> Error ("unknown field " ^ name)

let string_field name fields =
  match List.assoc_opt name fields with
  | Some (`String value) -> Ok value
  | None -> Error ("missing " ^ name)
  | Some _ -> Error (name ^ " must be a string")

let int_field name fields =
  match List.assoc_opt name fields with
  | Some (`Int value) -> Ok value
  | None -> Error ("missing " ^ name)
  | Some _ -> Error (name ^ " must be an integer")

let parse_power limits = function
  | `Assoc fields ->
      begin match check_fields [ "variable"; "exponent" ] fields with
      | Error _ as error -> error
      | Ok () ->
          begin match (string_field "variable" fields, int_field "exponent" fields) with
          | Error message, _ | _, Error message -> Error message
          | Ok variable, Ok exponent ->
              if String.equal variable "" then Error "power variable must not be empty"
              else if exponent < 0 then Error "power exponent must be nonnegative"
              else if exponent > limits.max_exponent then Error "power exponent exceeds the limit"
              else Ok (variable, exponent)
          end
      end
  | _ -> Error "power must be an object"

let parse_powers limits = function
  | `List raw ->
      if List.length raw > limits.max_powers_per_term then
        Error "term exceeds the powers-per-term limit"
      else
        let rec loop reversed = function
          | [] -> Ok (List.rev reversed)
          | power :: rest ->
              begin match parse_power limits power with
              | Error _ as error -> error
              | Ok power -> loop (power :: reversed) rest
              end
        in
        loop [] raw
  | _ -> Error "powers must be an array"

let parse_term limits = function
  | `Assoc fields ->
      begin match check_fields [ "coefficient"; "powers" ] fields with
      | Error _ as error -> error
      | Ok () ->
          begin match (List.assoc_opt "coefficient" fields, List.assoc_opt "powers" fields) with
          | None, _ -> Error "missing coefficient"
          | _, None -> Error "missing powers"
          | Some coefficient, Some powers ->
              begin match (parse_q "coefficient" coefficient, parse_powers limits powers) with
              | Error message, _ | _, Error message -> Error message
              | Ok coefficient, Ok powers ->
                  begin match term coefficient powers with
                  | Error error -> Error (error_message error)
                  | Ok polynomial -> Ok polynomial
                  end
              end
          end
      end
  | _ -> Error "term must be an object"

let parse_polynomial limits label = function
  | `Assoc fields ->
      begin match check_fields [ "terms" ] fields with
      | Error _ as error -> error
      | Ok () ->
          begin match List.assoc_opt "terms" fields with
          | None -> Error ("missing " ^ label ^ ".terms")
          | Some (`List raw_terms) ->
              if List.length raw_terms > limits.max_terms then
                Error (label ^ " exceeds the term limit")
              else
                let rec loop polynomial = function
                  | [] -> Ok polynomial
                  | raw :: rest ->
                      begin match parse_term limits raw with
                      | Error _ as error -> error
                      | Ok parsed -> loop (add polynomial parsed) rest
                      end
                in
                begin match loop zero raw_terms with
                | Error _ as error -> error
                | Ok polynomial ->
                    if List.length (variables polynomial) > limits.max_variables then
                      Error (label ^ " exceeds the variable limit")
                    else if exact_bits polynomial > limits.max_exact_bits then
                      Error (label ^ " exceeds the exact-bit limit")
                    else Ok polynomial
                end
          | Some _ -> Error (label ^ ".terms must be an array")
          end
      end
  | _ -> Error (label ^ " must be an object")

let bounded_product ceiling left right =
  if left < 0 || right < 0 then ceiling + 1
  else if left = 0 || right = 0 then 0
  else if left > ceiling / right then ceiling + 1
  else left * right

let check_output limits ~method_ polynomial =
  if term_count polynomial > limits.max_terms then
    failure ~method_ "resource_limit" "polynomial result exceeds the term limit"
  else if List.length (variables polynomial) > limits.max_variables then
    failure ~method_ "resource_limit" "polynomial result exceeds the variable limit"
  else if exact_bits polynomial > limits.max_exact_bits then
    failure ~method_ "resource_limit" "polynomial result exceeds the exact-bit limit"
  else
    let response = success ~method_ (polynomial_json polynomial) in
    if String.length (Yojson.Safe.to_string response) > limits.max_result_bytes then
      failure ~method_ "resource_limit" "polynomial result exceeds the byte limit"
    else response

let polynomial_field limits name fields =
  match List.assoc_opt name fields with
  | None -> Error ("missing " ^ name)
  | Some json -> parse_polynomial limits name json

let substitution_field limits fields =
  match List.assoc_opt "substitutions" fields with
  | None -> Error "missing substitutions"
  | Some (`List raw) ->
      if List.length raw > limits.max_variables then Error "too many substitutions"
      else
        let rec loop reversed seen = function
          | [] -> Ok (List.rev reversed)
          | `Assoc fields :: rest ->
              begin match check_fields [ "variable"; "value" ] fields with
              | Error _ as error -> error
              | Ok () ->
                  begin match (string_field "variable" fields, List.assoc_opt "value" fields) with
                  | Error message, _ -> Error message
                  | _, None -> Error "missing substitution value"
                  | Ok variable, Some value ->
                      if List.mem variable seen then Error ("duplicate substitution for " ^ variable)
                      else
                        begin match parse_q "substitution value" value with
                        | Error _ as error -> error
                        | Ok value -> loop ((variable, value) :: reversed) (variable :: seen) rest
                        end
                  end
              end
          | _ :: _ -> Error "substitution must be an object"
        in
        loop [] [] raw
  | Some _ -> Error "substitutions must be an array"

let binary_action limits ~method_ operation fields =
  match check_fields [ "version"; "id"; "action"; "left"; "right" ] fields with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match (polynomial_field limits "left" fields, polynomial_field limits "right" fields) with
      | Error message, _ | _, Error message -> failure ~method_ "invalid_request" message
      | Ok left, Ok right ->
          let work = bounded_product limits.max_work (term_count left) (term_count right) in
          if work > limits.max_work then
            failure ~method_ "resource_limit" "polynomial operation exceeds the work limit"
          else
            begin match operation left right with
            | Error error ->
                let code, message = error_of_polynomial error in
                failure ~method_ code message
            | Ok polynomial -> check_output limits ~method_ polynomial
            end
      end

let capabilities limits =
  let strings values = `List (List.map (fun value -> `String value) values) in
  `Assoc
    [
      ("kind", `String "multivariate_polynomial_capabilities");
      ("exact", `Bool true);
      ( "actions",
        strings
          [
            "capabilities";
            "add";
            "subtract";
            "multiply";
            "differentiate";
            "substitute_rationals";
            "coefficient";
            "variables";
            "total_degree";
          ] );
      ( "limits",
        `Assoc
          [
            ("max_terms", `Int limits.max_terms);
            ("max_variables", `Int limits.max_variables);
            ("max_powers_per_term", `Int limits.max_powers_per_term);
            ("max_exponent", `Int limits.max_exponent);
            ("max_exact_bits", `Int limits.max_exact_bits);
            ("max_work", `Int limits.max_work);
            ("max_result_bytes", `Int limits.max_result_bytes);
          ] );
      ("text", `String "Exact sparse multivariate polynomials over Q.");
    ]

let dispatch limits action fields =
  match action with
  | "capabilities" ->
      begin match check_fields [ "version"; "id"; "action" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () -> success ~method_:action (capabilities limits)
      end
  | "add" -> binary_action limits ~method_:action (fun left right -> Ok (add left right)) fields
  | "subtract" -> binary_action limits ~method_:action (fun left right -> Ok (sub left right)) fields
  | "multiply" -> binary_action limits ~method_:action multiply fields
  | "differentiate" ->
      begin match check_fields [ "version"; "id"; "action"; "polynomial"; "variable" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match (polynomial_field limits "polynomial" fields, string_field "variable" fields) with
          | Error message, _ | _, Error message -> failure ~method_:action "invalid_request" message
          | Ok polynomial, Ok variable ->
              begin match derivative variable polynomial with
              | Error error ->
                  let code, message = error_of_polynomial error in
                  failure ~method_:action code message
              | Ok result -> check_output limits ~method_:action result
              end
          end
      end
  | "substitute_rationals" ->
      begin match check_fields [ "version"; "id"; "action"; "polynomial"; "substitutions" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match (polynomial_field limits "polynomial" fields, substitution_field limits fields) with
          | Error message, _ | _, Error message -> failure ~method_:action "invalid_request" message
          | Ok polynomial, Ok substitutions ->
              begin match substitute_rationals substitutions polynomial with
              | Error error ->
                  let code, message = error_of_polynomial error in
                  failure ~method_:action code message
              | Ok result -> check_output limits ~method_:action result
              end
          end
      end
  | "coefficient" ->
      begin match check_fields [ "version"; "id"; "action"; "polynomial"; "powers" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match (polynomial_field limits "polynomial" fields, List.assoc_opt "powers" fields) with
          | Error message, _ -> failure ~method_:action "invalid_request" message
          | _, None -> failure ~method_:action "invalid_request" "missing powers"
          | Ok polynomial, Some powers ->
              begin match parse_powers limits powers with
              | Error message -> failure ~method_:action "invalid_request" message
              | Ok powers ->
                  begin match coefficient polynomial powers with
                  | Error error ->
                      let code, message = error_of_polynomial error in
                      failure ~method_:action code message
                  | Ok value -> success ~method_:action (rational_json value)
                  end
              end
          end
      end
  | "variables" ->
      begin match check_fields [ "version"; "id"; "action"; "polynomial" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match polynomial_field limits "polynomial" fields with
          | Error message -> failure ~method_:action "invalid_request" message
          | Ok polynomial ->
              let values = variables polynomial in
              success ~method_:action
                (`Assoc
                   [
                     ("kind", `String "polynomial_variables");
                     ("exact", `Bool true);
                     ("variables", `List (List.map (fun value -> `String value) values));
                     ("text", `String (String.concat ", " values));
                   ])
          end
      end
  | "total_degree" ->
      begin match check_fields [ "version"; "id"; "action"; "polynomial" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match polynomial_field limits "polynomial" fields with
          | Error message -> failure ~method_:action "invalid_request" message
          | Ok polynomial ->
              begin match total_degree polynomial with
              | None ->
                  success ~method_:action
                    (`Assoc
                       [
                         ("kind", `String "polynomial_degree");
                         ("exact", `Bool true);
                         ("defined", `Bool false);
                         ("text", `String "undefined for zero polynomial");
                       ])
              | Some degree ->
                  success ~method_:action
                    (`Assoc
                       [
                         ("kind", `String "polynomial_degree");
                         ("exact", `Bool true);
                         ("defined", `Bool true);
                         ("degree", `Int degree);
                         ("text", `String (string_of_int degree));
                       ])
              end
          end
      end
  | _ -> failure ~method_:action "invalid_request" ("unknown polynomial action " ^ action)

let request_id fields =
  match List.assoc_opt "id" fields with
  | None -> Ok None
  | Some ((`String _ | `Int _ | `Intlit _) as id) -> Ok (Some id)
  | Some _ -> Error "id must be a string or integer"

let with_id id = function
  | `Assoc fields ->
      begin match id with
      | None -> `Assoc fields
      | Some id ->
          let rec insert = function
            | [] -> [ ("id", id) ]
            | (("version", _) as version) :: rest -> version :: ("id", id) :: rest
            | field :: rest -> field :: insert rest
          in
          `Assoc (insert fields)
      end
  | json -> json

let handle_json ?(limits = default_limits) = function
  | `Assoc fields ->
      begin match request_id fields with
      | Error message -> failure ~method_:"request" "invalid_request" message
      | Ok id ->
          let respond response = with_id id response in
          begin match List.assoc_opt "version" fields with
          | Some (`Int 1) ->
              begin match List.assoc_opt "action" fields with
              | Some (`String action) -> respond (dispatch limits action fields)
              | Some _ -> respond (failure ~method_:"request" "invalid_request" "action must be a string")
              | None -> respond (failure ~method_:"request" "invalid_request" "missing action")
              end
          | Some (`Int _) -> respond (failure ~method_:"request" "invalid_request" "unsupported protocol version")
          | _ -> respond (failure ~method_:"request" "invalid_request" "version must be 1")
          end
      end
  | _ -> failure ~method_:"request" "invalid_request" "request must be a JSON object"
