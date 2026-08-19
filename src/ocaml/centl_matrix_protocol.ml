open Centl_matrix

type limits = {
  max_rows : int;
  max_columns : int;
  max_entries : int;
  max_exact_bits : int;
  max_work : int;
  max_result_bytes : int;
}

let default_limits =
  {
    max_rows = 128;
    max_columns = 128;
    max_entries = 4_096;
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

let vector_text vector =
  Array.to_list vector |> List.map rational_text |> String.concat ", "
  |> fun inner -> "[" ^ inner ^ "]"

let vector_json vector =
  `Assoc
    [
      ("kind", `String "rational_vector");
      ("exact", `Bool true);
      ("length", `Int (Array.length vector));
      ("entries", `List (Array.to_list vector |> List.map rational_json));
      ("text", `String (vector_text vector));
    ]

let matrix_text matrix =
  matrix.entries
  |> Array.to_list
  |> List.map (fun row ->
         Array.to_list row |> List.map rational_text |> String.concat ", "
         |> fun inner -> "[" ^ inner ^ "]")
  |> String.concat ", "
  |> fun inner -> "[" ^ inner ^ "]"

let matrix_json matrix =
  `Assoc
    [
      ("kind", `String "rational_matrix");
      ("exact", `Bool true);
      ("rows", `Int matrix.rows);
      ("columns", `Int matrix.columns);
      ( "entries",
        `List
          (Array.to_list matrix.entries
          |> List.map (fun row ->
                 `List (Array.to_list row |> List.map rational_json))) );
      ("text", `String (matrix_text matrix));
    ]

let provenance method_ =
  `Assoc
    [
      ("schema", `Int 1);
      ( "producer",
        `Assoc
          [
            ("name", `String "centl");
            ("version", `String Centl_version.value);
          ] );
      ("classification", `String "exact");
      ("method", `String method_);
      ("backend", `String "centl-exact-matrix");
    ]

let failure_provenance method_ =
  `Assoc
    [
      ("schema", `Int 1);
      ( "producer",
        `Assoc
          [
            ("name", `String "centl");
            ("version", `String Centl_version.value);
          ] );
      ("classification", `String "failure");
      ("method", `String method_);
      ("backend", `String "centl-exact-matrix");
    ]

let success ~method_ result =
  `Assoc
    [
      ("version", `Int 1);
      ("ok", `Bool true);
      ("result", result);
      ("provenance", provenance method_);
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
      ("provenance", failure_provenance method_);
    ]

let error_of_matrix = function
  | Empty_matrix | Empty_row | Ragged_rows | Index_out_of_bounds as error ->
      ("invalid_matrix", error_message error)
  | Shape_mismatch _ as error -> ("dimension_mismatch", error_message error)
  | Not_square _ as error -> ("non_square_matrix", error_message error)
  | Singular_matrix -> ("singular_matrix", error_message Singular_matrix)
  | Right_hand_side_length_mismatch ->
      ("dimension_mismatch", error_message Right_hand_side_length_mismatch)

let parse_q label = function
  | `String text ->
      begin
        try Ok (Q.of_string text)
        with Invalid_argument _ | Failure _ ->
          Error ("invalid exact rational in " ^ label ^ ": " ^ text)
      end
  | _ -> Error (label ^ " entries must be exact-rational strings")

let bounded_product ceiling factors =
  List.fold_left
    (fun total factor ->
      if total > ceiling || factor > ceiling || factor <> 0 && total > ceiling / factor
      then ceiling + 1
      else total * factor)
    1 factors

let check_matrix_limits limits matrix =
  if matrix.rows > limits.max_rows then Error "matrix exceeds the row limit"
  else if matrix.columns > limits.max_columns then
    Error "matrix exceeds the column limit"
  else if bounded_product limits.max_entries [ matrix.rows; matrix.columns ] > limits.max_entries then
    Error "matrix exceeds the entry limit"
  else if exact_bits matrix > limits.max_exact_bits then
    Error "matrix exceeds the exact-bit limit"
  else Ok ()

let parse_matrix limits label = function
  | `List raw_rows ->
      if List.length raw_rows > limits.max_rows then
        Error (label ^ " exceeds the row limit")
      else
        let rec parse_rows reversed = function
          | [] -> Ok (List.rev reversed)
          | `List raw_row :: rest ->
              if List.length raw_row > limits.max_columns then
                Error (label ^ " exceeds the column limit")
              else
                let rec parse_entries reversed = function
                  | [] -> Ok (List.rev reversed)
                  | entry :: entries ->
                      begin match parse_q label entry with
                      | Error _ as error -> error
                      | Ok value -> parse_entries (value :: reversed) entries
                      end
                in
                begin match parse_entries [] raw_row with
                | Error _ as error -> error
                | Ok row -> parse_rows (row :: reversed) rest
                end
          | _ :: _ -> Error (label ^ " must be an array of row arrays")
        in
        begin match parse_rows [] raw_rows with
        | Error _ as error -> error
        | Ok rows ->
            begin match of_rows rows with
            | Error error -> Error (error_message error)
            | Ok matrix ->
                begin match check_matrix_limits limits matrix with
                | Ok () -> Ok matrix
                | Error message -> Error message
                end
            end
        end
  | _ -> Error (label ^ " must be a matrix array")

let vector_bits vector =
  Array.fold_left
    (fun total value ->
      total + Z.numbits (Z.abs (Q.num value)) + Z.numbits (Q.den value))
    0 vector

let parse_vector limits label = function
  | `List raw ->
      if List.length raw > limits.max_rows then Error (label ^ " exceeds the vector limit")
      else
        let rec parse reversed = function
          | [] ->
              let vector = Array.of_list (List.rev reversed) in
              if vector_bits vector > limits.max_exact_bits then
                Error (label ^ " exceeds the exact-bit limit")
              else Ok vector
          | entry :: rest ->
              begin match parse_q label entry with
              | Error _ as error -> error
              | Ok value -> parse (value :: reversed) rest
              end
        in
        parse [] raw
  | _ -> Error (label ^ " must be an array of exact-rational strings")

let parse_scalar label json = parse_q label json

let check_work limits work =
  if work > limits.max_work then Error "matrix operation exceeds the work limit"
  else Ok ()

let result_with_limit limits ~method_ result =
  let response = success ~method_ result in
  if String.length (Yojson.Safe.to_string response) > limits.max_result_bytes then
    failure ~method_ "resource_limit" "matrix result exceeds the byte limit"
  else response

let matrix_error_response ~method_ error =
  let code, message = error_of_matrix error in
  failure ~method_ code message

let matrix_result limits ~method_ computation =
  match computation with
  | Error error -> matrix_error_response ~method_ error
  | Ok matrix -> result_with_limit limits ~method_ (matrix_json matrix)

let rational_result limits ~method_ computation =
  match computation with
  | Error error -> matrix_error_response ~method_ error
  | Ok value -> result_with_limit limits ~method_ (rational_json value)

let integer_result limits ~method_ value =
  result_with_limit limits ~method_
    (`Assoc
       [
         ("kind", `String "integer");
         ("exact", `Bool true);
         ("value", `String (string_of_int value));
         ("text", `String (string_of_int value));
       ])

let matrix_field limits name fields =
  match List.assoc_opt name fields with
  | None -> Error ("missing " ^ name)
  | Some json -> parse_matrix limits name json

let vector_field limits name fields =
  match List.assoc_opt name fields with
  | None -> Error ("missing " ^ name)
  | Some json -> parse_vector limits name json

let scalar_field name fields =
  match List.assoc_opt name fields with
  | None -> Error ("missing " ^ name)
  | Some json -> parse_scalar name json

let check_fields allowed fields =
  match List.find_opt (fun (name, _) -> not (List.mem name allowed)) fields with
  | None -> Ok ()
  | Some (name, _) -> Error ("unknown field " ^ name)

let solve_json = function
  | No_solution ->
      `Assoc
        [
          ("kind", `String "linear_solution");
          ("exact", `Bool true);
          ("decision", `String "no_solution");
          ("text", `String "no solution");
        ]
  | Unique vector ->
      `Assoc
        [
          ("kind", `String "linear_solution");
          ("exact", `Bool true);
          ("decision", `String "unique");
          ("solution", vector_json vector);
          ("text", `String ("x = " ^ vector_text vector));
        ]
  | Infinite { particular; nullspace_basis } ->
      `Assoc
        [
          ("kind", `String "linear_solution");
          ("exact", `Bool true);
          ("decision", `String "infinite");
          ("particular", vector_json particular);
          ("nullspace_basis", `List (List.map vector_json nullspace_basis));
          ("parameter_count", `Int (List.length nullspace_basis));
          ("text", `String "infinite affine solution family");
        ]

let capabilities limits =
  let strings values = `List (List.map (fun value -> `String value) values) in
  `Assoc
    [
      ("kind", `String "matrix_capabilities");
      ("exact", `Bool true);
      ( "actions",
        strings
          [
            "capabilities";
            "add";
            "subtract";
            "scale";
            "multiply";
            "transpose";
            "trace";
            "determinant";
            "rref";
            "rank";
            "inverse";
            "solve";
            "nullspace";
          ] );
      ( "limits",
        `Assoc
          [
            ("max_rows", `Int limits.max_rows);
            ("max_columns", `Int limits.max_columns);
            ("max_entries", `Int limits.max_entries);
            ("max_exact_bits", `Int limits.max_exact_bits);
            ("max_work", `Int limits.max_work);
            ("max_result_bytes", `Int limits.max_result_bytes);
          ] );
      ("text", `String "Exact dense rational matrix algebra and linear systems.");
    ]

let binary_matrix_action limits ~method_ operation fields =
  match check_fields [ "version"; "id"; "action"; "left"; "right" ] fields with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match (matrix_field limits "left" fields, matrix_field limits "right" fields) with
      | Error message, _ | _, Error message -> failure ~method_ "invalid_request" message
      | Ok left, Ok right ->
          let work = bounded_product limits.max_work [ left.rows; left.columns; right.columns ] in
          begin match check_work limits work with
          | Error message -> failure ~method_ "resource_limit" message
          | Ok () -> matrix_result limits ~method_ (operation left right)
          end
      end

let unary_matrix_action limits ~method_ operation fields =
  match check_fields [ "version"; "id"; "action"; "matrix" ] fields with
  | Error message -> failure ~method_ "invalid_request" message
  | Ok () ->
      begin match matrix_field limits "matrix" fields with
      | Error message -> failure ~method_ "invalid_request" message
      | Ok matrix -> matrix_result limits ~method_ (Ok (operation matrix))
      end

let dispatch limits action fields =
  match action with
  | "capabilities" ->
      begin match check_fields [ "version"; "id"; "action" ] fields with
      | Ok () -> result_with_limit limits ~method_:action (capabilities limits)
      | Error message -> failure ~method_:action "invalid_request" message
      end
  | "add" -> binary_matrix_action limits ~method_:action add fields
  | "subtract" -> binary_matrix_action limits ~method_:action sub fields
  | "multiply" -> binary_matrix_action limits ~method_:action multiply fields
  | "transpose" -> unary_matrix_action limits ~method_:action transpose fields
  | "scale" ->
      begin match check_fields [ "version"; "id"; "action"; "matrix"; "scalar" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match (matrix_field limits "matrix" fields, scalar_field "scalar" fields) with
          | Error message, _ | _, Error message -> failure ~method_:action "invalid_request" message
          | Ok matrix, Ok scalar ->
              let result = scale scalar matrix in
              if exact_bits result > limits.max_exact_bits then
                failure ~method_:action "resource_limit" "matrix result exceeds the exact-bit limit"
              else result_with_limit limits ~method_:action (matrix_json result)
          end
      end
  | "trace" ->
      begin match check_fields [ "version"; "id"; "action"; "matrix" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match matrix_field limits "matrix" fields with
          | Error message -> failure ~method_:action "invalid_request" message
          | Ok matrix -> rational_result limits ~method_:action (trace matrix)
          end
      end
  | "determinant" ->
      begin match check_fields [ "version"; "id"; "action"; "matrix" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match matrix_field limits "matrix" fields with
          | Error message -> failure ~method_:action "invalid_request" message
          | Ok matrix ->
              let work = bounded_product limits.max_work [ matrix.rows; matrix.rows; matrix.rows ] in
              begin match check_work limits work with
              | Error message -> failure ~method_:action "resource_limit" message
              | Ok () -> rational_result limits ~method_:action (determinant matrix)
              end
          end
      end
  | "rref" ->
      begin match check_fields [ "version"; "id"; "action"; "matrix" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match matrix_field limits "matrix" fields with
          | Error message -> failure ~method_:action "invalid_request" message
          | Ok matrix ->
              let work = bounded_product limits.max_work [ matrix.rows; matrix.columns; matrix.columns ] in
              begin match check_work limits work with
              | Error message -> failure ~method_:action "resource_limit" message
              | Ok () ->
                  let result = rref matrix in
                  result_with_limit limits ~method_:action
                    (`Assoc
                       [
                         ("kind", `String "matrix_rref");
                         ("exact", `Bool true);
                         ("matrix", matrix_json result.matrix);
                         ("pivot_columns", `List (List.map (fun column -> `Int column) result.pivot_columns));
                         ("rank", `Int (List.length result.pivot_columns));
                         ("text", `String (matrix_text result.matrix));
                       ])
              end
          end
      end
  | "rank" ->
      begin match check_fields [ "version"; "id"; "action"; "matrix" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match matrix_field limits "matrix" fields with
          | Error message -> failure ~method_:action "invalid_request" message
          | Ok matrix ->
              let work = bounded_product limits.max_work [ matrix.rows; matrix.columns; matrix.columns ] in
              begin match check_work limits work with
              | Error message -> failure ~method_:action "resource_limit" message
              | Ok () -> integer_result limits ~method_:action (rank matrix)
              end
          end
      end
  | "inverse" ->
      begin match check_fields [ "version"; "id"; "action"; "matrix" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match matrix_field limits "matrix" fields with
          | Error message -> failure ~method_:action "invalid_request" message
          | Ok matrix ->
              let work = bounded_product limits.max_work [ matrix.rows; matrix.rows; matrix.rows ] in
              begin match check_work limits work with
              | Error message -> failure ~method_:action "resource_limit" message
              | Ok () -> matrix_result limits ~method_:action (inverse matrix)
              end
          end
      end
  | "solve" ->
      begin match check_fields [ "version"; "id"; "action"; "matrix"; "rhs" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match (matrix_field limits "matrix" fields, vector_field limits "rhs" fields) with
          | Error message, _ | _, Error message -> failure ~method_:action "invalid_request" message
          | Ok matrix, Ok rhs ->
              let work = bounded_product limits.max_work [ matrix.rows; matrix.columns + 1; matrix.columns + 1 ] in
              begin match check_work limits work with
              | Error message -> failure ~method_:action "resource_limit" message
              | Ok () ->
                  begin match solve matrix rhs with
                  | Error error -> matrix_error_response ~method_:action error
                  | Ok solution -> result_with_limit limits ~method_:action (solve_json solution)
                  end
              end
          end
      end
  | "nullspace" ->
      begin match check_fields [ "version"; "id"; "action"; "matrix" ] fields with
      | Error message -> failure ~method_:action "invalid_request" message
      | Ok () ->
          begin match matrix_field limits "matrix" fields with
          | Error message -> failure ~method_:action "invalid_request" message
          | Ok matrix ->
              let work = bounded_product limits.max_work [ matrix.rows; matrix.columns; matrix.columns ] in
              begin match check_work limits work with
              | Error message -> failure ~method_:action "resource_limit" message
              | Ok () ->
                  let basis = nullspace matrix in
                  result_with_limit limits ~method_:action
                    (`Assoc
                       [
                         ("kind", `String "nullspace_basis");
                         ("exact", `Bool true);
                         ("dimension", `Int (List.length basis));
                         ("basis", `List (List.map vector_json basis));
                         ("text", `String (Printf.sprintf "%d basis vector(s)" (List.length basis)));
                       ])
              end
          end
      end
  | _ -> failure ~method_:action "invalid_request" ("unknown matrix action " ^ action)

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
