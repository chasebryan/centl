open Centl_polynomial_gcd

type limits = {
  polynomial : Centl_multivariate_polynomial_protocol.limits;
  gcd : Centl_polynomial_gcd.limits;
  max_result_bytes : int;
}

let default_limits =
  {
    polynomial = Centl_multivariate_polynomial_protocol.default_limits;
    gcd = Centl_polynomial_gcd.default_limits;
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
      ("backend", `String "centl-exact-polynomial-gcd");
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

let error_code = function
  | Empty_variable | Mixed_variable _ -> "invalid_request"
  | Resource_limit _ -> "resource_limit"
  | Cancelled -> "cancelled"
  | Polynomial_error Centl_multivariate_polynomial.Cancelled -> "cancelled"
  | Polynomial_error _ -> "invalid_polynomial"
  | Internal_division_error _ -> "internal_error"

let enforce_result_limit limits ~method_ response =
  if String.length (Yojson.Safe.to_string response) > limits.max_result_bytes then
    failure ~method_ "resource_limit" "polynomial gcd result exceeds the byte limit"
  else response

let polynomial_json polynomial =
  Centl_multivariate_polynomial_protocol.polynomial_json polynomial

let capabilities limits =
  `Assoc
    [
      ("kind", `String "polynomial_gcd_capabilities");
      ("exact", `Bool true);
      ("univariate", `Bool true);
      ("explicit_variable", `Bool true);
      ("monic_nonzero_gcd", `Bool true);
      ("zero_zero_is_zero", `Bool true);
      ("cooperative_cancellation", `Bool true);
      ( "actions",
        `List [ `String "capabilities"; `String "gcd"; `String "coprime" ] );
      ( "limits",
        `Assoc
          [
            ("max_terms", `Int limits.gcd.division.max_terms);
            ("max_exact_bits", `Int limits.gcd.division.max_exact_bits);
            ("max_division_steps", `Int limits.gcd.division.max_steps);
            ("max_euclid_steps", `Int limits.gcd.max_euclid_steps);
            ("max_work", `Int limits.gcd.division.max_work);
            ("max_result_bytes", `Int limits.max_result_bytes);
          ] );
      ( "text",
        `String
          "Exact monic polynomial gcd and coprimality over Q[x] with an explicit admitted variable." );
    ]

let binary_action ?(cancelled = never_cancelled) limits ~method_ render fields =
  match
    check_fields [ "version"; "id"; "action"; "variable"; "left"; "right" ]
      fields
  with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match
        ( string_field "variable" fields,
          List.assoc_opt "left" fields,
          List.assoc_opt "right" fields )
      with
      | Error message, _, _ -> failure ~method_ "invalid_request" message
      | _, None, _ -> failure ~method_ "invalid_request" "missing left"
      | _, _, None -> failure ~method_ "invalid_request" "missing right"
      | Ok variable, Some left, Some right ->
          begin match
            ( parse_polynomial limits "left" left,
              parse_polynomial limits "right" right )
          with
          | Error message, _ | _, Error message ->
              failure ~method_ "invalid_request" message
          | Ok left, Ok right ->
              begin match render variable left right with
              | Error error ->
                  failure ~method_ (error_code error) (error_message error)
              | Ok result ->
                  success ~method_ result |> enforce_result_limit limits ~method_
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
    failure ~method_:action "cancelled" "polynomial gcd was cancelled"
  else
    match action with
    | "capabilities" ->
        begin match check_fields [ "version"; "id"; "action" ] fields with
        | Error message -> failure ~method_:action "invalid_request" message
        | Ok () -> success ~method_:action (capabilities limits)
        end
    | "gcd" ->
        binary_action ~cancelled limits ~method_:action
          (fun variable left right ->
            gcd ~limits:limits.gcd ~cancelled ~variable left right
            |> Result.map polynomial_json)
          fields
    | "coprime" ->
        binary_action ~cancelled limits ~method_:action
          (fun variable left right ->
            coprime ~limits:limits.gcd ~cancelled ~variable left right
            |> Result.map (fun coprime ->
                   `Assoc
                     [
                       ("kind", `String "polynomial_coprimality");
                       ("exact", `Bool true);
                       ("coprime", `Bool coprime);
                     ]))
          fields
    | _ ->
        failure ~method_:action "invalid_request"
          ("unknown polynomial gcd action " ^ action)

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
