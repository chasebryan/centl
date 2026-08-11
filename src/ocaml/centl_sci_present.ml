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

let contains_substring ~needle text =
  let needle_length = String.length needle in
  let text_length = String.length text in
  let rec loop index =
    if needle_length = 0 then true
    else if index + needle_length > text_length then false
    else if String.sub text index needle_length = needle then true
    else loop (index + 1)
  in
  loop 0

let strip_prefix prefix text =
  if String.starts_with ~prefix text then
    Some
      (String.sub text (String.length prefix)
         (String.length text - String.length prefix))
  else None

let strip_suffix suffix text =
  let suffix_length = String.length suffix in
  let text_length = String.length text in
  if
    suffix_length <= text_length
    && String.sub text (text_length - suffix_length) suffix_length = suffix
  then Some (String.sub text 0 (text_length - suffix_length))
  else None

let natural_approximation text =
  match strip_prefix "≈ [" text with
  | None -> text
  | Some body ->
      begin match strip_suffix "]" body with
      | None -> text
      | Some bounds ->
          begin match String.split_on_char ',' bounds with
          | [ lower; upper ] ->
              Printf.sprintf "Approximately between %s and %s"
                (String.trim lower) (String.trim upper)
          | _ -> text
          end
      end

let solution_set_text value =
  match
    ( string_field "kind" value,
      string_field "status" value,
      string_field "variable" value,
      assoc_field "solutions" value )
  with
  | Some "solution_set", Some "finite", Some variable, Some (`List solutions) ->
      let solution_text =
        List.map
          (fun solution ->
            match string_field "text" solution with
            | Some text -> text
            | None -> "")
          solutions
      in
      if List.exists (fun text -> text = "") solution_text then None
      else
        begin match solution_text with
        | [] -> Some "no solutions"
        | values ->
            Some
              (values
              |> List.map (fun value -> variable ^ " = " ^ value)
              |> String.concat " or ")
        end
  | _ -> None

let established_text outcome =
  match outcome.Centl_sci_runtime.response with
  | None -> "CENTL could not establish a result."
  | Some response ->
      begin match assoc_field "value" response with
      | Some value ->
          begin match solution_set_text value with
          | Some text -> text
          | None ->
              begin match string_field "text" value with
              | Some text -> natural_approximation text
              | None ->
                  begin match Centl_sci_runtime.result_text response with
                  | Some text -> natural_approximation text
                  | None -> "CENTL could not establish a result."
                  end
              end
          end
      | None ->
          begin match Centl_sci_runtime.result_text response with
          | Some text -> natural_approximation text
          | None -> "CENTL could not establish a result."
          end
      end

let unsupported_reason = function
  | Centl_sci_ir.Unsupported data -> Some data.unsupported_reason
  | _ -> None

let is_verification = function
  | Centl_sci_ir.Verification_claim _ -> true
  | _ -> false

let verification_result outcome =
  if not (is_verification outcome.Centl_sci_runtime.ir) then None
  else
    match outcome.Centl_sci_runtime.response with
    | None -> None
    | Some response -> Centl_sci_runtime.result_text response

let missing_information_text outcome =
  match unsupported_reason outcome.Centl_sci_runtime.ir with
  | None -> None
  | Some reason ->
      let reason = String.trim reason in
      let lower = String.lowercase_ascii reason in
      if String.starts_with ~prefix:"missing " lower then
        let detail =
          String.sub reason 8 (String.length reason - 8) |> String.trim
        in
        if detail = "" then
          Some "More information is required to solve this problem."
        else
          let detail =
            match strip_suffix "." detail with
            | Some value -> value
            | None -> detail
          in
          Some ("More information is required: " ^ detail ^ ".")
      else if contains_substring ~needle:"missing" lower then
        Some "More information is required to solve this problem."
      else None

let unsupported_text outcome =
  match missing_information_text outcome with
  | Some text -> text
  | None ->
      begin match unsupported_reason outcome.Centl_sci_runtime.ir with
      | Some reason when String.trim reason <> "" ->
          "CENTL-SCi cannot establish this request: " ^ String.trim reason ^ "."
      | _ -> "CENTL-SCi cannot solve this problem yet."
      end

let human outcome =
  match outcome.Centl_sci_runtime.status with
  | Centl_sci_runtime.Established -> established_text outcome
  | Centl_sci_runtime.Unresolved ->
      begin match verification_result outcome with
      | Some text -> text
      | None -> "CENTL could not establish a complete result."
      end
  | Centl_sci_runtime.Unsupported -> unsupported_text outcome
  | Centl_sci_runtime.Failed -> "CENTL could not establish a result."

let response_exact outcome =
  match outcome.Centl_sci_runtime.response with
  | None -> false
  | Some response ->
      begin match assoc_field "value" response with
      | Some value ->
          begin match bool_field "exact" value with
          | Some value -> value
          | None -> false
          end
      | None ->
          begin match assoc_field "physics" response with
          | Some physics ->
              begin match bool_field "exact" physics with
              | Some value -> value
              | None ->
                  begin match string_field "kind" physics with
                  | Some "particle_simulation" -> true
                  | _ -> false
                  end
              end
          | None -> false
          end
      end

let method_text = function
  | Centl_sci_ir.Exact_expression _ -> Some "CENTL exact/symbolic computation"
  | Centl_sci_ir.Polynomial_equation _ ->
      Some "CENTL polynomial equation solving"
  | Centl_sci_ir.Verification_claim _ ->
      Some "CENTL structured claim verification"
  | Centl_sci_ir.Unit_conversion _ -> Some "CENTL Physics unit conversion"
  | Centl_sci_ir.Physical_constant _ ->
      Some "CENTL Physics exact defining/conventional constant lookup"
  | Centl_sci_ir.Uniform_gravity_particle _ ->
      Some
        "CENTL Physics uniform-gravity particle simulation (symplectic Euler)"
  | Centl_sci_ir.Unsupported _ -> None

let variable_text = function
  | Centl_sci_ir.Polynomial_equation data -> Some data.variable
  | _ -> None

let failure_reason outcome =
  match outcome.Centl_sci_runtime.response with
  | None -> None
  | Some response ->
      begin match assoc_field "error" response with
      | Some error -> string_field "message" error
      | None -> None
      end

let mechanics_details outcome =
  match outcome.Centl_sci_runtime.ir with
  | Centl_sci_ir.Uniform_gravity_particle data ->
      [
        Printf.sprintf "Steps: %d" data.steps;
        Printf.sprintf "Time step: %s %s" data.dt_value data.dt_unit;
        "Integrator result is the exact discrete symplectic-Euler evolution of \
         the admitted model";
        "Not claimed to be the analytic continuous-time trajectory";
      ]
  | _ -> []

let verification_details outcome =
  if not (is_verification outcome.Centl_sci_runtime.ir) then []
  else
    match outcome.Centl_sci_runtime.response with
    | Some response ->
        begin match assoc_field "verification" response with
        | Some verification ->
            let fields = ref [] in
            let add label = function
              | Some value -> fields := !fields @ [ label ^ ": " ^ value ]
              | None -> ()
            in
            add "Verdict" (string_field "verdict" verification);
            add "Verification scope" (string_field "scope" verification);
            add "Verification method" (string_field "method" verification);
            begin match assoc_field "assurance" verification with
            | Some assurance ->
                add "Verification assurance" (string_field "class" assurance);
                add "Verification theorem" (string_field "theorem" assurance)
            | None -> ()
            end;
            begin match assoc_field "evidence" verification with
            | Some evidence ->
                add "Verification reason" (string_field "reason" evidence)
            | None -> ()
            end;
            !fields
        | None -> []
        end
    | None -> []

let details outcome =
  let lines = ref [ human outcome; ""; "Details:" ] in
  let add line = lines := !lines @ [ "  " ^ line ] in
  if response_exact outcome then
    add "Exact result within the admitted deterministic model";
  begin match variable_text outcome.Centl_sci_runtime.ir with
  | Some variable -> add ("Variable: " ^ variable)
  | None -> ()
  end;
  begin match method_text outcome.Centl_sci_runtime.ir with
  | Some method_ -> add ("Method: " ^ method_)
  | None -> ()
  end;
  List.iter add (mechanics_details outcome);
  List.iter add (verification_details outcome);
  begin match Centl_sci_ir.assumptions outcome.Centl_sci_runtime.ir with
  | [] -> ()
  | values -> add ("Assumptions: " ^ String.concat "; " values)
  end;
  begin match outcome.Centl_sci_runtime.status with
  | Centl_sci_runtime.Established ->
      add "Established by the authoritative CENTL execution path"
  | Centl_sci_runtime.Unresolved ->
      add "CENTL did not establish a complete result"
  | Centl_sci_runtime.Unsupported ->
      begin match unsupported_reason outcome.Centl_sci_runtime.ir with
      | Some reason when String.trim reason <> "" -> add ("Reason: " ^ reason)
      | _ -> ()
      end
  | Centl_sci_runtime.Failed ->
      begin match failure_reason outcome with
      | Some reason when String.trim reason <> "" -> add ("Reason: " ^ reason)
      | _ -> ()
      end
  end;
  String.concat "\n" !lines
