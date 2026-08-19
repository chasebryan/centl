open Centl_polynomial_composition

type limits = {
  polynomial : Centl_multivariate_polynomial_protocol.limits;
  composition : Centl_polynomial_composition.limits;
  max_result_bytes : int;
}

let default_limits =
  {
    polynomial = Centl_multivariate_polynomial_protocol.default_limits;
    composition = Centl_polynomial_composition.default_limits;
    max_result_bytes = 1_048_576;
  }

let never_cancelled () = false

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
      ("backend", `String "centl-exact-polynomial-composition");
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

let check_fields allowed fields =
  match List.find_opt (fun (name, _) -> not (List.mem name allowed)) fields with
  | None -> Ok ()
  | Some (name, _) -> Error ("unknown field " ^ name)

let string_field name fields =
  match List.assoc_opt name fields with
  | Some (`String value) -> Ok value
  | None -> Error ("missing " ^ name)
  | Some _ -> Error (name ^ " must be a string")

let parse_polynomial limits label json =
  Centl_multivariate_polynomial_protocol.parse_polynomial limits.polynomial label
    json

let parse_substitutions limits = function
  | `List raw ->
      if List.length raw > limits.composition.max_substitutions then
        Error "too many polynomial substitutions"
      else
        let rec loop reversed = function
          | [] -> Ok (List.rev reversed)
          | `Assoc fields :: rest ->
              begin match check_fields [ "variable"; "polynomial" ] fields with
              | Error _ as error -> error
              | Ok () ->
                  begin match
                    (string_field "variable" fields, List.assoc_opt "polynomial" fields)
                  with
                  | Error message, _ -> Error message
                  | _, None -> Error "missing substitution polynomial"
                  | Ok variable, Some polynomial ->
                      begin match
                        parse_polynomial limits "substitution.polynomial" polynomial
                      with
                      | Error _ as error -> error
                      | Ok polynomial ->
                          loop ((variable, polynomial) :: reversed) rest
                      end
                  end
              end
          | _ :: _ -> Error "substitution must be an object"
        in
        loop [] raw
  | _ -> Error "substitutions must be an array"

let error_code = function
  | Empty_variable | Duplicate_substitution _ -> "invalid_request"
  | Power_exponent_limit _ | Resource_limit _ -> "resource_limit"
  | Polynomial_error Centl_multivariate_polynomial.Cancelled | Cancelled ->
      "cancelled"
  | Polynomial_error Centl_multivariate_polynomial.Undefined_zero_power ->
      "undefined_power"
  | Polynomial_error (Centl_multivariate_polynomial.Negative_power _) ->
      "unsupported_exact_polynomial_operation"
  | Polynomial_error _ -> "invalid_polynomial"

let enforce_result_limit limits ~method_ response =
  if String.length (Yojson.Safe.to_string response) > limits.max_result_bytes then
    failure ~method_ "resource_limit"
      "polynomial composition result exceeds the byte limit"
  else response

let capabilities limits =
  `Assoc
    [
      ("kind", `String "polynomial_composition_capabilities");
      ("exact", `Bool true);
      ("simultaneous", `Bool true);
      ("cooperative_cancellation", `Bool true);
      ("actions", `List [ `String "capabilities"; `String "compose" ]);
      ( "limits",
        `Assoc
          [
            ("max_substitutions", `Int limits.composition.max_substitutions);
            ("max_power_exponent", `Int limits.composition.max_power_exponent);
            ("max_terms", `Int limits.composition.max_terms);
            ("max_exact_bits", `Int limits.composition.max_exact_bits);
            ("max_work", `Int limits.composition.max_work);
            ("max_result_bytes", `Int limits.max_result_bytes);
          ] );
      ( "text",
        `String
          "Exact simultaneous polynomial substitution and composition over Q." );
    ]

let compose_action ?(cancelled = never_cancelled) limits fields =
  let method_ = "compose" in
  match
    check_fields [ "version"; "id"; "action"; "polynomial"; "substitutions" ]
      fields
  with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match
        (List.assoc_opt "polynomial" fields, List.assoc_opt "substitutions" fields)
      with
      | None, _ -> failure ~method_ "invalid_request" "missing polynomial"
      | _, None -> failure ~method_ "invalid_request" "missing substitutions"
      | Some polynomial, Some substitutions ->
          begin match
            (parse_polynomial limits "polynomial" polynomial,
             parse_substitutions limits substitutions)
          with
          | Error message, _ | _, Error message ->
              failure ~method_ "invalid_request" message
          | Ok polynomial, Ok substitutions ->
              begin match
                compose ~limits:limits.composition ~cancelled substitutions polynomial
              with
              | Error error ->
                  failure ~method_ (error_code error) (error_message error)
              | Ok result ->
                  success ~method_
                    (Centl_multivariate_polynomial_protocol.polynomial_json result)
                  |> enforce_result_limit limits ~method_
              end
          end
      end

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
            | (("version", _) as version) :: rest ->
                version :: ("id", id) :: rest
            | field :: rest -> field :: insert rest
          in
          `Assoc (insert fields)
      end
  | json -> json

let dispatch ?(cancelled = never_cancelled) limits action fields =
  if cancelled () && not (String.equal action "capabilities") then
    failure ~method_:action "cancelled" "polynomial composition was cancelled"
  else
    match action with
    | "capabilities" ->
        begin match check_fields [ "version"; "id"; "action" ] fields with
        | Error message -> failure ~method_:action "invalid_request" message
        | Ok () -> success ~method_:action (capabilities limits)
        end
    | "compose" -> compose_action ~cancelled limits fields
    | _ ->
        failure ~method_:action "invalid_request"
          ("unknown polynomial composition action " ^ action)

let handle_json ?(limits = default_limits) ?(cancelled = never_cancelled) = function
  | `Assoc fields ->
      begin match request_id fields with
      | Error message -> failure ~method_:"request" "invalid_request" message
      | Ok id ->
          let respond response = with_id id response in
          begin match List.assoc_opt "version" fields with
          | Some (`Int 1) ->
              begin match List.assoc_opt "action" fields with
              | Some (`String action) ->
                  respond (dispatch ~cancelled limits action fields)
              | Some _ ->
                  respond
                    (failure ~method_:"request" "invalid_request"
                       "action must be a string")
              | None ->
                  respond
                    (failure ~method_:"request" "invalid_request"
                       "missing action")
              end
          | Some (`Int _) ->
              respond
                (failure ~method_:"request" "invalid_request"
                   "unsupported protocol version")
          | _ ->
              respond
                (failure ~method_:"request" "invalid_request"
                   "version must be 1")
          end
      end
  | _ ->
      failure ~method_:"request" "invalid_request"
        "request must be a JSON object"
