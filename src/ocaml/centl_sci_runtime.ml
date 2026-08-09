type executor = Core | Physics
type plan = { executor : executor; request : Yojson.Safe.t }
type status = Established | Unresolved | Unsupported | Failed

type outcome = {
  ir : Centl_sci_ir.t;
  plan : plan option;
  response : Yojson.Safe.t option;
  status : status;
}

let status_text = function
  | Established -> "established"
  | Unresolved -> "unresolved"
  | Unsupported -> "unsupported"
  | Failed -> "failed"

let executor_text = function Core -> "centl" | Physics -> "centl-physics"

let core_limits =
  `Assoc
    [
      ("max_source_bytes", `Int 8_192);
      ("max_expression_nodes", `Int 20_000);
      ("max_exact_bits", `Int 262_144);
      ("max_integer_iterations", `Int 10_000);
      ("max_result_bytes", `Int 262_144);
      ("max_precision_digits", `Int 256);
      ("max_working_bits", `Int 4_096);
    ]

let core_request expression =
  `Assoc
    [
      ("version", `Int 1);
      ("op", `String "compute");
      ("expression", `String expression);
      ("limits", core_limits);
    ]

let plan = function
  | Centl_sci_ir.Exact_expression data ->
      Some { executor = Core; request = core_request data.expression }
  | Centl_sci_ir.Polynomial_equation data ->
      let expression =
        Printf.sprintf "solve((%s) = (%s), %s)" data.left data.right
          data.variable
      in
      Some { executor = Core; request = core_request expression }
  | Centl_sci_ir.Unit_conversion data ->
      Some
        {
          executor = Physics;
          request =
            `Assoc
              [
                ("version", `Int 1);
                ("action", `String "convert");
                ("value", `String data.value);
                ("from_unit", `String data.from_unit);
                ("to_unit", `String data.to_unit);
              ];
        }
  | Centl_sci_ir.Unsupported _ -> None

let assoc_field name = function
  | `Assoc fields -> List.assoc_opt name fields
  | _ -> None

let string_field name json =
  match assoc_field name json with
  | Some (`String value) -> Some value
  | _ -> None

let bool_field name json =
  match assoc_field name json with
  | Some (`Bool value) -> Some value
  | _ -> None

let resolution_status response =
  match assoc_field "resolution" response with
  | Some resolution -> string_field "status" resolution
  | None -> None

let classify executor response =
  match bool_field "ok" response with
  | Some false | None -> Failed
  | Some true ->
      begin match executor with
      | Physics -> Established
      | Core ->
          begin match resolution_status response with
          | Some ("computed" | "transformed" | "unchanged_proved") ->
              Established
          | Some ("residual" | "unsupported" | "indeterminate") -> Unresolved
          | Some _ | None -> Unresolved
          end
      end

let execute_plan plan =
  let line = Yojson.Safe.to_string plan.request in
  let response =
    match plan.executor with
    | Core ->
        let state = Centl_protocol.create () in
        Centl_protocol.handle_line state line
    | Physics ->
        let state = Centl_physics_protocol.create () in
        Centl_physics_server.handle_line state line
  in
  (response, classify plan.executor response)

let execute ir =
  match plan ir with
  | None -> { ir; plan = None; response = None; status = Unsupported }
  | Some execution_plan ->
      let response, status = execute_plan execution_plan in
      { ir; plan = Some execution_plan; response = Some response; status }

let plan_json plan =
  `Assoc
    [
      ("executor", `String (executor_text plan.executor));
      ("request", plan.request);
    ]

let to_json ~problem outcome =
  let fields =
    [
      ("sci_version", `String "0.0.1");
      ("problem", `String problem);
      ("status", `String (status_text outcome.status));
      ("interpretation", Centl_sci_ir.to_json outcome.ir);
      ( "execution",
        match outcome.plan with None -> `Null | Some value -> plan_json value );
      ( "centl_response",
        match outcome.response with None -> `Null | Some value -> value );
    ]
  in
  `Assoc fields

let result_text response =
  match assoc_field "value" response with
  | Some value -> string_field "text" value
  | None ->
      begin match assoc_field "physics" response with
      | Some physics -> string_field "text" physics
      | None ->
          begin match assoc_field "error" response with
          | Some error -> string_field "message" error
          | None -> None
          end
      end

let provenance_text response =
  match assoc_field "provenance" response with
  | Some provenance ->
      let classification = string_field "classification" provenance in
      let method_ = string_field "method" provenance in
      let backend = string_field "backend" provenance in
      begin match (classification, method_, backend) with
      | Some classification, Some method_, Some backend ->
          Some (Printf.sprintf "%s via %s (%s)" classification method_ backend)
      | _ -> None
      end
  | None -> None

let interpretation_text ir =
  Printf.sprintf "%s.%s -> %s" (Centl_sci_ir.domain ir)
    (Centl_sci_ir.problem_class ir)
    (Centl_sci_ir.operation ir)

let assumptions_text assumptions =
  match assumptions with [] -> "none" | values -> String.concat "; " values

let human ~problem:_ outcome =
  match outcome.ir with
  | Centl_sci_ir.Unsupported data ->
      String.concat "\n"
        [
          "Status: unsupported";
          "Interpretation: unsupported";
          "Reason: " ^ data.unsupported_reason;
          "Interpreter assumptions: "
          ^ assumptions_text data.unsupported_assumptions;
        ]
  | _ ->
      let response = Option.get outcome.response in
      let result =
        match result_text response with
        | Some value -> value
        | None -> Yojson.Safe.to_string response
      in
      let lines =
        [
          "Status: " ^ status_text outcome.status;
          "Result: " ^ result;
          "Interpretation: " ^ interpretation_text outcome.ir;
          "Interpreter assumptions: "
          ^ assumptions_text (Centl_sci_ir.assumptions outcome.ir);
        ]
      in
      let lines =
        match resolution_status response with
        | None -> lines
        | Some resolution -> lines @ [ "CENTL resolution: " ^ resolution ]
      in
      let lines =
        match provenance_text response with
        | None -> lines
        | Some provenance -> lines @ [ "CENTL provenance: " ^ provenance ]
      in
      String.concat "\n" lines
