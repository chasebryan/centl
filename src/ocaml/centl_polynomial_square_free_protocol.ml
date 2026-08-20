open Centl_polynomial_square_free

type limits = {
  polynomial : Centl_multivariate_polynomial_protocol.limits;
  square_free : Centl_polynomial_square_free.limits;
  max_result_bytes : int;
}

let default_limits =
  {
    polynomial = Centl_multivariate_polynomial_protocol.default_limits;
    square_free = Centl_polynomial_square_free.default_limits;
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
      ("backend", `String "centl-exact-polynomial-square-free");
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
  | Zero_polynomial -> "invalid_polynomial"
  | Resource_limit _ -> "resource_limit"
  | Cancelled -> "cancelled"
  | Polynomial_error Centl_multivariate_polynomial.Cancelled -> "cancelled"
  | Polynomial_error _ -> "invalid_polynomial"
  | Internal_division_error _
  | Internal_gcd_error _
  | Internal_factorization_error _ ->
      "internal_error"

let factor_json (factor : Centl_polynomial_square_free.factor) =
  `Assoc
    [
      ("multiplicity", `Int factor.multiplicity);
      ( "polynomial",
        Centl_multivariate_polynomial_protocol.polynomial_json factor.polynomial );
    ]

let factorization_json
    (factorization : Centl_polynomial_square_free.factorization) =
  `Assoc
    [
      ("kind", `String "polynomial_square_free_factorization");
      ("exact", `Bool true);
      ( "unit",
        Centl_multivariate_polynomial_protocol.rational_json factorization.unit );
      ("factor_semantics", `String "square_free_multiplicity_groups");
      ("irreducible_factorization", `Bool false);
      ("factors", `List (List.map factor_json factorization.factors));
      ("factor_count", `Int (List.length factorization.factors));
    ]

let enforce_result_limit limits ~method_ response =
  if String.length (Yojson.Safe.to_string response) > limits.max_result_bytes then
    failure ~method_ "resource_limit"
      "polynomial square-free factorization result exceeds the byte limit"
  else response

let capabilities limits =
  `Assoc
    [
      ("kind", `String "polynomial_square_free_capabilities");
      ("exact", `Bool true);
      ("univariate", `Bool true);
      ("explicit_variable", `Bool true);
      ("characteristic_zero", `Bool true);
      ("monic_nonconstant_groups", `Bool true);
      ("zero_polynomial_refused", `Bool true);
      ("irreducible_factorization", `Bool false);
      ("cooperative_cancellation", `Bool true);
      ("actions", `List [ `String "capabilities"; `String "factorize" ]);
      ( "limits",
        `Assoc
          [
            ("max_terms", `Int limits.square_free.division.max_terms);
            ("max_exact_bits", `Int limits.square_free.division.max_exact_bits);
            ("max_division_steps", `Int limits.square_free.division.max_steps);
            ("max_gcd_steps", `Int limits.square_free.max_gcd_steps);
            ("max_factor_steps", `Int limits.square_free.max_factor_steps);
            ("max_work", `Int limits.square_free.division.max_work);
            ("max_result_bytes", `Int limits.max_result_bytes);
          ] );
      ( "text",
        `String
          "Exact square-free multiplicity-group factorization over Q[x]; this is not irreducible factorization." );
    ]

let factorize_action ?(cancelled = never_cancelled) limits ~method_ fields =
  match
    check_fields [ "version"; "id"; "action"; "variable"; "polynomial" ] fields
  with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match
        (string_field "variable" fields, List.assoc_opt "polynomial" fields)
      with
      | Error message, _ -> failure ~method_ "invalid_request" message
      | _, None -> failure ~method_ "invalid_request" "missing polynomial"
      | Ok variable, Some json ->
          begin match parse_polynomial limits "polynomial" json with
          | Error message -> failure ~method_ "invalid_request" message
          | Ok polynomial ->
              begin match
                factorize ~limits:limits.square_free ~cancelled ~variable polynomial
              with
              | Error error ->
                  failure ~method_ (error_code error) (error_message error)
              | Ok factorization ->
                  success ~method_ (factorization_json factorization)
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
    failure ~method_:action "cancelled"
      "polynomial square-free factorization was cancelled"
  else
    match action with
    | "capabilities" ->
        begin match check_fields [ "version"; "id"; "action" ] fields with
        | Error message -> failure ~method_:action "invalid_request" message
        | Ok () -> success ~method_:action (capabilities limits)
        end
    | "factorize" -> factorize_action ~cancelled limits ~method_:action fields
    | _ ->
        failure ~method_:action "invalid_request"
          ("unknown polynomial square-free action " ^ action)

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
