open Centl_polynomial_division

type limits = {
  polynomial : Centl_multivariate_polynomial_protocol.limits;
  division : Centl_polynomial_division.limits;
  max_result_bytes : int;
}

let default_limits =
  {
    polynomial = Centl_multivariate_polynomial_protocol.default_limits;
    division = Centl_polynomial_division.default_limits;
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
      ("backend", `String "centl-exact-polynomial-division");
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
  | Division_by_zero -> "division_by_zero"
  | Resource_limit _ -> "resource_limit"
  | Cancelled -> "cancelled"
  | Polynomial_error Centl_multivariate_polynomial.Cancelled -> "cancelled"
  | Polynomial_error _ -> "invalid_polynomial"

let enforce_result_limit limits ~method_ response =
  if String.length (Yojson.Safe.to_string response) > limits.max_result_bytes then
    failure ~method_ "resource_limit"
      "polynomial division result exceeds the byte limit"
  else response

let division_json (division : Centl_polynomial_division.division) =
  `Assoc
    [
      ("kind", `String "polynomial_division");
      ("exact", `Bool true);
      ( "quotient",
        Centl_multivariate_polynomial_protocol.polynomial_json division.quotient );
      ( "remainder",
        Centl_multivariate_polynomial_protocol.polynomial_json division.remainder );
    ]

let capabilities limits =
  `Assoc
    [
      ("kind", `String "polynomial_division_capabilities");
      ("exact", `Bool true);
      ("univariate", `Bool true);
      ("explicit_variable", `Bool true);
      ("cooperative_cancellation", `Bool true);
      ( "actions",
        `List
          [
            `String "capabilities";
            `String "divide";
            `String "quotient";
            `String "remainder";
          ] );
      ( "limits",
        `Assoc
          [
            ("max_terms", `Int limits.division.max_terms);
            ("max_exact_bits", `Int limits.division.max_exact_bits);
            ("max_steps", `Int limits.division.max_steps);
            ("max_work", `Int limits.division.max_work);
            ("max_result_bytes", `Int limits.max_result_bytes);
          ] );
      ( "text",
        `String
          "Exact univariate polynomial quotient and remainder over Q with an explicit admitted variable." );
    ]

let division_action ?(cancelled = never_cancelled) limits ~method_ render fields =
  match
    check_fields
      [ "version"; "id"; "action"; "variable"; "dividend"; "divisor" ]
      fields
  with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match
        ( string_field "variable" fields,
          List.assoc_opt "dividend" fields,
          List.assoc_opt "divisor" fields )
      with
      | Error message, _, _ -> failure ~method_ "invalid_request" message
      | _, None, _ -> failure ~method_ "invalid_request" "missing dividend"
      | _, _, None -> failure ~method_ "invalid_request" "missing divisor"
      | Ok variable, Some dividend, Some divisor ->
          begin match
            ( parse_polynomial limits "dividend" dividend,
              parse_polynomial limits "divisor" divisor )
          with
          | Error message, _ | _, Error message ->
              failure ~method_ "invalid_request" message
          | Ok dividend, Ok divisor ->
              begin match
                divide ~limits:limits.division ~cancelled ~variable dividend divisor
              with
              | Error error ->
                  failure ~method_ (error_code error) (error_message error)
              | Ok division ->
                  success ~method_ (render division)
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
    failure ~method_:action "cancelled" "polynomial division was cancelled"
  else
    match action with
    | "capabilities" ->
        begin match check_fields [ "version"; "id"; "action" ] fields with
        | Error message -> failure ~method_:action "invalid_request" message
        | Ok () -> success ~method_:action (capabilities limits)
        end
    | "divide" ->
        division_action ~cancelled limits ~method_:action division_json fields
    | "quotient" ->
        division_action ~cancelled limits ~method_:action
          (fun (division : Centl_polynomial_division.division) ->
            Centl_multivariate_polynomial_protocol.polynomial_json
              division.quotient)
          fields
    | "remainder" ->
        division_action ~cancelled limits ~method_:action
          (fun (division : Centl_polynomial_division.division) ->
            Centl_multivariate_polynomial_protocol.polynomial_json
              division.remainder)
          fields
    | _ ->
        failure ~method_:action "invalid_request"
          ("unknown polynomial division action " ^ action)

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
