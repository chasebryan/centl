open Centl_polynomial_content

type limits = {
  polynomial : Centl_multivariate_polynomial_protocol.limits;
  content : Centl_polynomial_content.limits;
  max_result_bytes : int;
}

let default_limits =
  {
    polynomial = Centl_multivariate_polynomial_protocol.default_limits;
    content = Centl_polynomial_content.default_limits;
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
      ("backend", `String "centl-exact-polynomial-content");
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

let content_value_json value =
  `Assoc
    [
      ("kind", `String "polynomial_content");
      ("exact", `Bool true);
      ("value", Centl_multivariate_polynomial_protocol.rational_json value);
      ("text", `String (Centl_multivariate_polynomial_protocol.rational_text value));
    ]

let decomposition_json
    (decomposition : Centl_polynomial_content.decomposition) =
  `Assoc
    [
      ("kind", `String "polynomial_content_decomposition");
      ("exact", `Bool true);
      ( "content",
        Centl_multivariate_polynomial_protocol.rational_json decomposition.content );
      ( "primitive_part",
        Centl_multivariate_polynomial_protocol.polynomial_json
          decomposition.primitive_part );
      ( "text",
        `String
          ("content="
          ^ Centl_multivariate_polynomial_protocol.rational_text
              decomposition.content) );
    ]

let parse_polynomial limits label json =
  Centl_multivariate_polynomial_protocol.parse_polynomial limits.polynomial label
    json

let error_code = function
  | Resource_limit _ -> "resource_limit"
  | Cancelled -> "cancelled"

let enforce_result_limit limits ~method_ response =
  if String.length (Yojson.Safe.to_string response) > limits.max_result_bytes then
    failure ~method_ "resource_limit"
      "polynomial content result exceeds the byte limit"
  else response

let capabilities limits =
  `Assoc
    [
      ("kind", `String "polynomial_content_capabilities");
      ("exact", `Bool true);
      ("positive_content_normalization", `Bool true);
      ("zero_content_is_zero", `Bool true);
      ("cooperative_cancellation", `Bool true);
      ( "actions",
        `List
          [
            `String "capabilities";
            `String "content";
            `String "primitive_part";
            `String "decompose";
          ] );
      ( "limits",
        `Assoc
          [
            ("max_terms", `Int limits.content.max_terms);
            ("max_exact_bits", `Int limits.content.max_exact_bits);
            ("max_work", `Int limits.content.max_work);
            ("max_result_bytes", `Int limits.max_result_bytes);
          ] );
      ( "text",
        `String
          "Exact positive rational polynomial content and primitive-part decomposition over Q." );
    ]

let polynomial_action ?(cancelled = never_cancelled) limits ~method_ render fields =
  match check_fields [ "version"; "id"; "action"; "polynomial" ] fields with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match List.assoc_opt "polynomial" fields with
      | None -> failure ~method_ "invalid_request" "missing polynomial"
      | Some json ->
          begin match parse_polynomial limits "polynomial" json with
          | Error message -> failure ~method_ "invalid_request" message
          | Ok polynomial ->
              begin match decompose ~limits:limits.content ~cancelled polynomial with
              | Error error ->
                  failure ~method_ (error_code error) (error_message error)
              | Ok decomposition ->
                  success ~method_ (render decomposition)
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
      "polynomial content decomposition was cancelled"
  else
    match action with
    | "capabilities" ->
        begin match check_fields [ "version"; "id"; "action" ] fields with
        | Error message -> failure ~method_:action "invalid_request" message
        | Ok () -> success ~method_:action (capabilities limits)
        end
    | "content" ->
        polynomial_action ~cancelled limits ~method_:action
          (fun (decomposition : Centl_polynomial_content.decomposition) ->
            content_value_json decomposition.content)
          fields
    | "primitive_part" ->
        polynomial_action ~cancelled limits ~method_:action
          (fun (decomposition : Centl_polynomial_content.decomposition) ->
            Centl_multivariate_polynomial_protocol.polynomial_json
              decomposition.primitive_part)
          fields
    | "decompose" ->
        polynomial_action ~cancelled limits ~method_:action decomposition_json fields
    | _ ->
        failure ~method_:action "invalid_request"
          ("unknown polynomial content action " ^ action)

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
