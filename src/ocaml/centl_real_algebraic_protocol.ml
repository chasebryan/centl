open Centl_real_algebraic

type limits = {
  max_degree : int;
  max_coefficient_bits : int;
  max_endpoint_bits : int;
  max_refinement_steps : int;
  max_work : int;
  max_result_bytes : int;
}

let default_limits =
  {
    max_degree = 64;
    max_coefficient_bits = 16_384;
    max_endpoint_bits = 16_384;
    max_refinement_steps = 1_024;
    max_work = 2_000_000;
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

let polynomial_json polynomial =
  `Assoc
    [
      ("kind", `String "integer_polynomial");
      ("coefficient_order", `String "constant_to_leading");
      ("degree", `Int (Array.length polynomial - 1));
      ("coefficients", `List (Array.to_list polynomial |> List.map (fun value -> `String (Z.to_string value))));
      ("text", `String (polynomial_text polynomial));
    ]

let certificate_json certificate =
  `Assoc
    [
      ("kind", `String "real_algebraic_root");
      ("exact", `Bool true);
      ("classification", `String "algebraic_exact");
      ("polynomial", polynomial_json certificate.polynomial);
      ( "isolating_interval",
        `Assoc
          [
            ("lower", rational_json certificate.lower);
            ("upper", rational_json certificate.upper);
            ("open", `Bool true);
          ] );
      ("root_count", `Int 1);
      ("square_free", `Bool true);
      ("text", `String (text certificate));
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
      ("backend", `String "centl-exact-sturm");
    ]

let success ~method_ result =
  `Assoc
    [
      ("version", `Int 1);
      ("ok", `Bool true);
      ("result", result);
      ("provenance", provenance method_ "algebraic_exact");
    ]

let success_exact ~method_ result =
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

let error_of_algebraic = function
  | Zero_polynomial -> ("invalid_polynomial", error_message Zero_polynomial)
  | Constant_polynomial ->
      ("invalid_polynomial", error_message Constant_polynomial)
  | Invalid_interval -> ("invalid_interval", error_message Invalid_interval)
  | Endpoint_is_root -> ("endpoint_is_root", error_message Endpoint_is_root)
  | Non_square_free -> ("non_square_free", error_message Non_square_free)
  | Root_count_mismatch count ->
      ("root_count_mismatch", error_message (Root_count_mismatch count))

let check_fields allowed fields =
  match List.find_opt (fun (name, _) -> not (List.mem name allowed)) fields with
  | None -> Ok ()
  | Some (name, _) -> Error ("unknown field " ^ name)

let parse_z label = function
  | `String text ->
      begin
        try Ok (Z.of_string text)
        with Invalid_argument _ -> Error ("invalid integer in " ^ label ^ ": " ^ text)
      end
  | _ -> Error (label ^ " must contain integer strings")

let parse_q label = function
  | `String text ->
      begin
        try Ok (Q.of_string text)
        with Invalid_argument _ | Failure _ ->
          Error ("invalid exact rational in " ^ label ^ ": " ^ text)
      end
  | _ -> Error (label ^ " must be an exact-rational string")

let z_bits value = Z.numbits (Z.abs value)
let q_bits value = Z.numbits (Z.abs (Q.num value)) + Z.numbits (Q.den value)

let parse_polynomial limits = function
  | `List coefficients ->
      if List.length coefficients < 2 then
        Error "polynomial must contain at least two coefficients"
      else if List.length coefficients - 1 > limits.max_degree then
        Error "polynomial exceeds the degree limit"
      else
        let rec loop reversed total_bits = function
          | [] -> Ok (Array.of_list (List.rev reversed), total_bits)
          | coefficient :: rest ->
              begin match parse_z "polynomial" coefficient with
              | Error _ as error -> error
              | Ok coefficient ->
                  let total_bits = total_bits + z_bits coefficient in
                  if total_bits > limits.max_coefficient_bits then
                    Error "polynomial exceeds the coefficient-bit limit"
                  else loop (coefficient :: reversed) total_bits rest
              end
        in
        begin match loop [] 0 coefficients with
        | Error _ as error -> error
        | Ok (polynomial, _) ->
            begin match normalize_integer_polynomial polynomial with
            | Error error -> Error (error_message error)
            | Ok normalized ->
                if degree_z normalized > limits.max_degree then
                  Error "normalized polynomial exceeds the degree limit"
                else Ok normalized
            end
        end
  | _ -> Error "polynomial must be an array of integer strings"

let polynomial_field limits fields =
  match List.assoc_opt "polynomial" fields with
  | None -> Error "missing polynomial"
  | Some json -> parse_polynomial limits json

let rational_field limits name fields =
  match List.assoc_opt name fields with
  | None -> Error ("missing " ^ name)
  | Some json ->
      begin match parse_q name json with
      | Error _ as error -> error
      | Ok value ->
          if q_bits value > limits.max_endpoint_bits then
            Error (name ^ " exceeds the endpoint-bit limit")
          else Ok value
      end

let int_field name fields =
  match List.assoc_opt name fields with
  | Some (`Int value) -> Ok value
  | None -> Error ("missing " ^ name)
  | Some _ -> Error (name ^ " must be an integer")

let bounded_cube ceiling degree =
  if degree <= 0 then 0
  else if degree > ceiling / degree then ceiling + 1
  else
    let square = degree * degree in
    if square > ceiling / degree then ceiling + 1 else square * degree

let check_work limits polynomial multiplier =
  let degree = max 1 (degree_z polynomial) in
  let base = bounded_cube limits.max_work degree in
  if base > limits.max_work || multiplier > 0 && base > limits.max_work / multiplier then
    Error "algebraic operation exceeds the work limit"
  else Ok ()

let result_with_limit limits ~method_ result algebraic =
  let response = if algebraic then success ~method_ result else success_exact ~method_ result in
  if String.length (Yojson.Safe.to_string response) > limits.max_result_bytes then
    failure ~method_ "resource_limit" "algebraic result exceeds the byte limit"
  else response

let certify_action limits fields =
  let method_ = "certify" in
  match check_fields [ "version"; "id"; "action"; "polynomial"; "lower"; "upper" ] fields with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match
        ( polynomial_field limits fields,
          rational_field limits "lower" fields,
          rational_field limits "upper" fields )
      with
      | Error message, _, _ | _, Error message, _ | _, _, Error message ->
          failure ~method_ "invalid_request" message
      | Ok polynomial, Ok lower, Ok upper ->
          begin match check_work limits polynomial 1 with
          | Error message -> failure ~method_ "resource_limit" message
          | Ok () ->
              begin match make ~polynomial ~lower ~upper with
              | Error error ->
                  let code, message = error_of_algebraic error in
                  failure ~method_ code message
              | Ok certificate ->
                  result_with_limit limits ~method_ (certificate_json certificate) true
              end
          end
      end

let count_action limits fields =
  let method_ = "count_roots" in
  match check_fields [ "version"; "id"; "action"; "polynomial"; "lower"; "upper" ] fields with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match
        ( polynomial_field limits fields,
          rational_field limits "lower" fields,
          rational_field limits "upper" fields )
      with
      | Error message, _, _ | _, Error message, _ | _, _, Error message ->
          failure ~method_ "invalid_request" message
      | Ok polynomial, Ok lower, Ok upper ->
          begin match check_work limits polynomial 1 with
          | Error message -> failure ~method_ "resource_limit" message
          | Ok () ->
              begin match root_count polynomial lower upper with
              | Error error ->
                  let code, message = error_of_algebraic error in
                  failure ~method_ code message
              | Ok count ->
                  result_with_limit limits ~method_
                    (`Assoc
                       [
                         ("kind", `String "real_root_count");
                         ("exact", `Bool true);
                         ("count", `Int count);
                         ("polynomial", polynomial_json polynomial);
                         ("lower", rational_json lower);
                         ("upper", rational_json upper);
                         ("text", `String (string_of_int count));
                       ])
                    false
              end
          end
      end

let refine_action limits fields =
  let method_ = "refine" in
  match
    check_fields
      [ "version"; "id"; "action"; "polynomial"; "lower"; "upper"; "steps" ]
      fields
  with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match
        ( polynomial_field limits fields,
          rational_field limits "lower" fields,
          rational_field limits "upper" fields,
          int_field "steps" fields )
      with
      | Error message, _, _, _
      | _, Error message, _, _
      | _, _, Error message, _
      | _, _, _, Error message ->
          failure ~method_ "invalid_request" message
      | Ok polynomial, Ok lower, Ok upper, Ok steps ->
          if steps < 0 then failure ~method_ "invalid_request" "steps must be nonnegative"
          else if steps > limits.max_refinement_steps then
            failure ~method_ "resource_limit" "steps exceeds the refinement limit"
          else
            begin match check_work limits polynomial (max 1 (steps + 1)) with
            | Error message -> failure ~method_ "resource_limit" message
            | Ok () ->
                begin match make ~polynomial ~lower ~upper with
                | Error error ->
                    let code, message = error_of_algebraic error in
                    failure ~method_ code message
                | Ok certificate ->
                    begin match refine certificate steps with
                    | Rational_root value ->
                        result_with_limit limits ~method_
                          (`Assoc
                             [
                               ("kind", `String "rational");
                               ("exact", `Bool true);
                               ("value", rational_json value);
                               ("text", `String (rational_text value));
                             ])
                          false
                    | Isolating_interval certificate ->
                        result_with_limit limits ~method_
                          (certificate_json certificate) true
                    end
                end
            end
      end

let capabilities limits =
  `Assoc
    [
      ("kind", `String "real_algebraic_capabilities");
      ("exact", `Bool true);
      ( "actions",
        `List
          [
            `String "capabilities";
            `String "count_roots";
            `String "certify";
            `String "refine";
          ] );
      ( "limits",
        `Assoc
          [
            ("max_degree", `Int limits.max_degree);
            ("max_coefficient_bits", `Int limits.max_coefficient_bits);
            ("max_endpoint_bits", `Int limits.max_endpoint_bits);
            ("max_refinement_steps", `Int limits.max_refinement_steps);
            ("max_work", `Int limits.max_work);
            ("max_result_bytes", `Int limits.max_result_bytes);
          ] );
      ( "text",
        `String
          "Exact Sturm-certified isolation of square-free real algebraic roots." );
    ]

let dispatch limits action fields =
  match action with
  | "capabilities" ->
      begin match check_fields [ "version"; "id"; "action" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () -> result_with_limit limits ~method_:action (capabilities limits) false
      end
  | "count_roots" -> count_action limits fields
  | "certify" -> certify_action limits fields
  | "refine" -> refine_action limits fields
  | _ -> failure ~method_:action "invalid_request" ("unknown algebraic action " ^ action)

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
