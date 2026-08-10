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

let verification_request left relation right =
  `Assoc
    [
      ("version", `Int 1);
      ("op", `String "verify");
      ("left", `String left);
      ("relation", `String relation);
      ("right", `String right);
    ]

let quantity value unit_symbol =
  `Assoc [ ("value", `String value); ("unit", `String unit_symbol) ]

let vector x y z unit_symbol =
  `Assoc
    [
      ("x", `String x);
      ("y", `String y);
      ("z", `String z);
      ("unit", `String unit_symbol);
    ]

let identifier_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true
  | _ -> false

let digit = function '0' .. '9' -> true | _ -> false

let starts_at text index needle =
  let needle_length = String.length needle in
  index >= 0
  && index + needle_length <= String.length text
  && String.sub text index needle_length = needle

let normalize_polynomial_side ~variable text =
  let variable_length = String.length variable in
  if variable_length = 0 then text
  else
    let buffer = Buffer.create (String.length text + 8) in
    let rec loop index =
      if index >= String.length text then Buffer.contents buffer
      else
        let preceding_factor =
          index > 0 && (digit text.[index - 1] || text.[index - 1] = ')')
        in
        let variable_here = starts_at text index variable in
        let boundary_after =
          let next = index + variable_length in
          next >= String.length text || not (identifier_char text.[next])
        in
        if preceding_factor && variable_here && boundary_after then begin
          Buffer.add_char buffer '*';
          Buffer.add_string buffer variable;
          loop (index + variable_length)
        end
        else begin
          Buffer.add_char buffer text.[index];
          loop (index + 1)
        end
    in
    loop 0

let plan = function
  | Centl_sci_ir.Exact_expression data ->
      Some { executor = Core; request = core_request data.expression }
  | Centl_sci_ir.Polynomial_equation data ->
      let left = normalize_polynomial_side ~variable:data.variable data.left in
      let right = normalize_polynomial_side ~variable:data.variable data.right in
      let expression =
        Printf.sprintf "solve((%s) = (%s), %s)" left right data.variable
      in
      Some { executor = Core; request = core_request expression }
  | Centl_sci_ir.Verification_claim data ->
      Some
        {
          executor = Core;
          request = verification_request data.left data.relation data.right;
        }
  | Centl_sci_ir.Unit_conversion data ->
      let from_unit = Centl_sci_units.canonical_or_original data.from_unit in
      let to_unit = Centl_sci_units.canonical_or_original data.to_unit in
      Some
        {
          executor = Physics;
          request =
            `Assoc
              [
                ("version", `Int 1);
                ("action", `String "convert");
                ("value", `String data.value);
                ("from_unit", `String from_unit);
                ("to_unit", `String to_unit);
              ];
        }
  | Centl_sci_ir.Physical_constant data ->
      Some
        {
          executor = Physics;
          request =
            `Assoc
              [
                ("version", `Int 1);
                ("action", `String "constant");
                ("symbol", `String data.symbol);
              ];
        }
  | Centl_sci_ir.Uniform_gravity_particle data ->
      Some
        {
          executor = Physics;
          request =
            `Assoc
              [
                ("version", `Int 1);
                ("action", `String "simulate_particle");
                ( "particle",
                  `Assoc
                    [
                      ("id", `String "body");
                      ("mass", quantity data.mass_value data.mass_unit);
                      ( "position",
                        vector data.position_x data.position_y data.position_z
                          data.position_unit );
                      ( "velocity",
                        vector data.velocity_x data.velocity_y data.velocity_z
                          data.velocity_unit );
                    ] );
                ( "forces",
                  `List
                    [
                      `Assoc
                        [
                          ("kind", `String "uniform_gravity");
                          ( "acceleration",
                            vector data.gravity_x data.gravity_y data.gravity_z
                              data.gravity_unit );
                        ];
                    ] );
                ("dt", quantity data.dt_value data.dt_unit);
                ("steps", `Int data.steps);
                ("include_trajectory", `Bool false);
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

let verification_verdict response =
  match assoc_field "verification" response with
  | Some verification -> string_field "verdict" verification
  | None -> None

let classify executor response =
  match bool_field "ok" response with
  | Some false | None -> Failed
  | Some true ->
      begin match executor with
      | Physics -> Established
      | Core ->
          begin match verification_verdict response with
          | Some ("verified" | "refuted") -> Established
          | Some ("unknown" | "invalid") -> Unresolved
          | Some _ -> Unresolved
          | None ->
              begin match resolution_status response with
              | Some ("computed" | "transformed" | "unchanged_proved") -> Established
              | Some ("residual" | "unsupported" | "indeterminate") -> Unresolved
              | Some _ | None -> Unresolved
              end
          end
      end

let execute_plan ?core_state plan =
  let line = Yojson.Safe.to_string plan.request in
  let response =
    match plan.executor with
    | Core ->
        let state =
          match core_state with
          | Some value -> value
          | None -> Centl_protocol.create ()
        in
        Centl_protocol.handle_line state line
    | Physics ->
        let state = Centl_physics_protocol.create () in
        Centl_physics_server.handle_line state line
  in
  (response, classify plan.executor response)

let execute ?core_state ir =
  match plan ir with
  | None -> { ir; plan = None; response = None; status = Unsupported }
  | Some execution_plan ->
      let response, status = execute_plan ?core_state execution_plan in
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
      ("sci_version", `String "0.0.2-Caramels");
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

let vector_text json =
  match
    (string_field "x" json, string_field "y" json, string_field "z" json,
     string_field "unit" json)
  with
  | Some x, Some y, Some z, Some unit_symbol ->
      Some (Printf.sprintf "(%s, %s, %s) %s" x y z unit_symbol)
  | _ -> None

let simulation_text physics =
  match
    (string_field "kind" physics, string_field "integrator" physics,
     assoc_field "final" physics)
  with
  | Some "particle_simulation", Some integrator, Some final ->
      begin match (assoc_field "position" final, assoc_field "velocity" final) with
      | Some position, Some velocity ->
          begin match (vector_text position, vector_text velocity) with
          | Some position_text, Some velocity_text ->
              Some
                (Printf.sprintf
                   "Final position %s; final velocity %s; discrete integrator: %s"
                   position_text velocity_text integrator)
          | _ -> None
          end
      | _ -> None
      end
  | _ -> None

let verification_text response =
  match assoc_field "verification" response with
  | None -> None
  | Some verification ->
      begin match string_field "verdict" verification with
      | Some "verified" -> Some "Verified."
      | Some "refuted" -> Some "Refuted."
      | Some "unknown" ->
          begin match assoc_field "evidence" verification with
          | Some evidence ->
              begin match string_field "reason" evidence with
              | Some reason -> Some ("Unknown: " ^ reason ^ ".")
              | None -> Some "Unknown."
              end
          | None -> Some "Unknown."
          end
      | Some "invalid" ->
          begin match assoc_field "evidence" verification with
          | Some evidence ->
              begin match string_field "reason" evidence with
              | Some reason -> Some ("Invalid claim: " ^ reason ^ ".")
              | None -> Some "Invalid claim."
              end
          | None -> Some "Invalid claim."
          end
      | Some verdict -> Some ("Verification verdict: " ^ verdict ^ ".")
      | None -> None
      end

let result_text response =
  match assoc_field "value" response with
  | Some value -> string_field "text" value
  | None ->
      begin match verification_text response with
      | Some _ as value -> value
      | None ->
          begin match assoc_field "physics" response with
          | Some physics ->
              begin match string_field "text" physics with
              | Some value -> Some value
              | None ->
                  begin match string_field "result" physics with
                  | Some value -> Some value
                  | None -> simulation_text physics
                  end
              end
          | None ->
              begin match assoc_field "error" response with
              | Some error -> string_field "message" error
              | None -> None
              end
          end
      end
