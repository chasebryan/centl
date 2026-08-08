(* Closed mathematical claim verification foundation for CENTL.
   Read-only with respect to sessions: may evaluate through existing
   definitions but never mutates bindings.

   Supported decisive scopes:
   - closed_exact_rational: exact integer/rational comparisons
   - closed_real_enclosure: strict order/inequality from disjoint enclosures
   - univariate_rational_polynomial: one rational variable; false equalities
     via exact rational counterexamples (witness_checked). Zero-difference
     identities remain unknown (polynomial_soundness_theorem_pending) until
     the F* soundness lemma is fully proved.

   Free-form assumptions and multi-variable claims return unknown. *)

type relation =
  | Equal
  | Not_equal
  | Less_than
  | Less_or_equal
  | Greater_than
  | Greater_or_equal

type claim_variable = { name : string; domain : string }

type claim = {
  left : string;
  relation : relation;
  right : string;
  variables : claim_variable list;
  assumptions : string list;
}

type verdict = Verified | Refuted | Unknown | Invalid

type assurance_class =
  | Exact_algorithm
  | Certified_enclosure
  | Witness_checked
  | None_

type assurance = { class_ : assurance_class; theorem : string option }

type dyadic_bounds = {
  lower_mantissa : string;
  upper_mantissa : string;
  binary_exponent : int;
}

type side_value = {
  kind : string;
  text : string;
  numerator : string option;
  denominator : string option;
  dyadic : dyadic_bounds option;
  lower : string option;
  upper : string option;
  requested_digits : int option;
  working_bits : int option;
}

type counterexample = {
  bindings : (string * string) list;
  left : side_value;
  right : side_value;
}

type evidence = {
  left : side_value option;
  right : side_value option;
  comparison : string option;
  reason : string option;
  normalized_difference : string option;
  counterexample : counterexample option;
  dependencies : string list;
  left_resolution : Centl_engine.transformation_resolution option;
  right_resolution : Centl_engine.transformation_resolution option;
}

type verification = {
  schema : int;
  verdict : verdict;
  scope : string;
  method_ : string;
  claim : claim;
  evidence : evidence;
  assurance : assurance;
}

type verification_error = Centl_engine.error
type verification_result = (verification, verification_error) result

let is_operational_error error =
  Centl_engine.error_retryable error.Centl_engine.code
  || error.Centl_engine.code = "core_contract_violation"

let relation_of_string = function
  | "equal" -> Ok Equal
  | "not_equal" -> Ok Not_equal
  | "less_than" -> Ok Less_than
  | "less_or_equal" -> Ok Less_or_equal
  | "greater_than" -> Ok Greater_than
  | "greater_or_equal" -> Ok Greater_or_equal
  | other ->
      Error
        {
          Centl_engine.code = "invalid_claim";
          message = "unsupported claim relation " ^ other;
          position = None;
        }

let relation_name = function
  | Equal -> "equal"
  | Not_equal -> "not_equal"
  | Less_than -> "less_than"
  | Less_or_equal -> "less_or_equal"
  | Greater_than -> "greater_than"
  | Greater_or_equal -> "greater_or_equal"

let supported_relations =
  [
    "equal";
    "not_equal";
    "less_than";
    "less_or_equal";
    "greater_than";
    "greater_or_equal";
  ]

let verification_dependencies (verification : verification) =
  verification.evidence.dependencies

let verdict_name = function
  | Verified -> "verified"
  | Refuted -> "refuted"
  | Unknown -> "unknown"
  | Invalid -> "invalid"

let assurance_class_name = function
  | Exact_algorithm -> "exact_algorithm"
  | Certified_enclosure -> "certified_enclosure"
  | Witness_checked -> "witness_checked"
  | None_ -> "none"

let string_field name fields =
  match List.assoc_opt name fields with
  | Some (`String value) -> Ok value
  | Some _ ->
      Error
        {
          Centl_engine.code = "invalid_claim";
          message = name ^ " must be a string";
          position = None;
        }
  | None ->
      Error
        {
          Centl_engine.code = "invalid_claim";
          message = "claim requires " ^ name;
          position = None;
        }

let duplicate_field fields =
  let rec find seen = function
    | [] -> None
    | (name, _) :: _ when List.mem name seen -> Some name
    | (name, _) :: rest -> find (name :: seen) rest
  in
  find [] fields

let valid_identifier name =
  let length = String.length name in
  length > 0
  && Centl_parser.is_identifier_start name.[0]
  && String.for_all Centl_parser.is_identifier_continue name

let parse_variables = function
  | None -> Ok []
  | Some (`List values) ->
      let rec walk seen = function
        | [] -> Ok []
        | `Assoc fields :: rest ->
            begin match duplicate_field fields with
            | Some name ->
                Error
                  {
                    Centl_engine.code = "invalid_claim";
                    message = "duplicate variable field " ^ name;
                    position = None;
                  }
            | None ->
                let unknown =
                  List.find_opt
                    (fun (name, _) -> not (List.mem name [ "name"; "domain" ]))
                    fields
                in
                begin match unknown with
                | Some (name, _) ->
                    Error
                      {
                        Centl_engine.code = "invalid_claim";
                        message = "unknown variable field " ^ name;
                        position = None;
                      }
                | None ->
                    begin match
                      (string_field "name" fields, string_field "domain" fields)
                    with
                    | Ok name, Ok domain ->
                        if domain <> "rational" then
                          Error
                            {
                              Centl_engine.code = "invalid_claim";
                              message =
                                "only rational claim variable domains are \
                                 accepted";
                              position = None;
                            }
                        else if not (valid_identifier name) then
                          Error
                            {
                              Centl_engine.code = "invalid_claim";
                              message =
                                "variable name must be a valid identifier";
                              position = None;
                            }
                        else if List.mem name Centl_engine.reserved_names then
                          Error
                            {
                              Centl_engine.code = "invalid_claim";
                              message =
                                "claim variable cannot use a built-in name";
                              position = None;
                            }
                        else if List.mem name seen then
                          Error
                            {
                              Centl_engine.code = "invalid_claim";
                              message = "claim variable names must be unique";
                              position = None;
                            }
                        else
                          begin match walk (name :: seen) rest with
                          | Ok tail -> Ok ({ name; domain } :: tail)
                          | Error _ as error -> error
                          end
                    | (Error _ as error), _ | _, (Error _ as error) -> error
                    end
                end
            end
        | _ :: _ ->
            Error
              {
                Centl_engine.code = "invalid_claim";
                message = "variables entries must be objects";
                position = None;
              }
      in
      walk [] values
  | Some _ ->
      Error
        {
          Centl_engine.code = "invalid_claim";
          message = "variables must be an array";
          position = None;
        }

let parse_assumptions = function
  | None -> Ok []
  | Some (`List values) ->
      let rec walk = function
        | [] -> Ok []
        | `String value :: rest ->
            begin match walk rest with
            | Ok tail -> Ok (value :: tail)
            | Error _ as error -> error
            end
        | _ :: _ ->
            Error
              {
                Centl_engine.code = "invalid_claim";
                message = "assumptions must be strings";
                position = None;
              }
      in
      walk values
  | Some _ ->
      Error
        {
          Centl_engine.code = "invalid_claim";
          message = "assumptions must be an array";
          position = None;
        }

let claim_field_names =
  [ "left"; "right"; "relation"; "variables"; "assumptions" ]

let parse_claim fields =
  let ( let* ) = Result.bind in
  match duplicate_field fields with
  | Some name ->
      Error
        {
          Centl_engine.code = "invalid_claim";
          message = "duplicate claim field " ^ name;
          position = None;
        }
  | None ->
      let unknown =
        List.find_opt
          (fun (name, _) -> not (List.mem name claim_field_names))
          fields
      in
      begin match unknown with
      | Some (name, _) ->
          Error
            {
              Centl_engine.code = "invalid_claim";
              message = "unknown claim field " ^ name;
              position = None;
            }
      | None ->
          let* left = string_field "left" fields in
          let* right = string_field "right" fields in
          let* relation_name = string_field "relation" fields in
          let* relation = relation_of_string relation_name in
          let* variables =
            parse_variables (List.assoc_opt "variables" fields)
          in
          let* assumptions =
            parse_assumptions (List.assoc_opt "assumptions" fields)
          in
          Ok { left; relation; right; variables; assumptions }
      end

let empty_evidence =
  {
    left = None;
    right = None;
    comparison = None;
    reason = None;
    normalized_difference = None;
    counterexample = None;
    dependencies = [];
    left_resolution = None;
    right_resolution = None;
  }

let make_verification ~verdict ~scope ~method_ ~claim ~evidence ~assurance =
  { schema = 1; verdict; scope; method_; claim; evidence; assurance }

let rational_pair_of_value = function
  | Centl_engine.Integer value -> Some (value, Z.one)
  | Centl_engine.Rational (numerator, denominator) ->
      Some (numerator, denominator)
  | _ -> None

let exact_values_equal left right =
  match (rational_pair_of_value left, rational_pair_of_value right) with
  | Some left_pair, Some right_pair ->
      Centl_engine.compare_rational_pairs left_pair right_pair = 0
  | _ -> false

let side_value_of_exact = function
  | Centl_engine.Integer n ->
      {
        kind = "integer";
        text = Z.to_string n;
        numerator = Some (Z.to_string n);
        denominator = Some "1";
        dyadic = None;
        lower = None;
        upper = None;
        requested_digits = None;
        working_bits = None;
      }
  | Centl_engine.Rational (numerator, denominator) ->
      {
        kind = "rational";
        text = Z.to_string numerator ^ "/" ^ Z.to_string denominator;
        numerator = Some (Z.to_string numerator);
        denominator = Some (Z.to_string denominator);
        dyadic = None;
        lower = None;
        upper = None;
        requested_digits = None;
        working_bits = None;
      }
  | Centl_engine.Symbolic _ as value ->
      {
        kind = "symbolic";
        text = Centl_engine.text_of_value value;
        numerator = None;
        denominator = None;
        dyadic = None;
        lower = None;
        upper = None;
        requested_digits = None;
        working_bits = None;
      }
  | Centl_engine.Exact_sequence _ as value ->
      {
        kind = "sequence";
        text = Centl_engine.text_of_value value;
        numerator = None;
        denominator = None;
        dyadic = None;
        lower = None;
        upper = None;
        requested_digits = None;
        working_bits = None;
      }
  | Centl_engine.Real_enclosure enclosure as value ->
      {
        kind = "real_enclosure";
        text = Centl_engine.text_of_value value;
        numerator = None;
        denominator = None;
        dyadic =
          Some
            {
              lower_mantissa = Z.to_string enclosure.lower_mantissa;
              upper_mantissa = Z.to_string enclosure.upper_mantissa;
              binary_exponent = enclosure.binary_exponent;
            };
        lower = Some enclosure.lower_decimal;
        upper = Some enclosure.upper_decimal;
        requested_digits = Some enclosure.requested_digits;
        working_bits = Some enclosure.working_bits;
      }
  | Centl_engine.Equation_result _ as value ->
      {
        kind = "solution_set";
        text = Centl_engine.text_of_value value;
        numerator = None;
        denominator = None;
        dyadic = None;
        lower = None;
        upper = None;
        requested_digits = None;
        working_bits = None;
      }

let comparison_name = function
  | n when n < 0 -> "less"
  | n when n > 0 -> "greater"
  | _ -> "equal"

let relation_holds relation ordering =
  match relation with
  | Equal -> ordering = 0
  | Not_equal -> ordering <> 0
  | Less_than -> ordering < 0
  | Less_or_equal -> ordering <= 0
  | Greater_than -> ordering > 0
  | Greater_or_equal -> ordering >= 0

let evaluate_side ?(cancelled = Centl_engine.never_cancelled) limits session
    source =
  if cancelled () then
    Error
      {
        Centl_engine.code = "cancelled";
        message = "the request was cancelled";
        position = None;
      }
  else
    Centl_engine.evaluate_in_session_outcome_with_limits ~cancelled
      ~intent:Centl_engine.Compute_only limits session source

let closed_exact_rational_scope = "closed_exact_rational"
let closed_exact_rational_method = "closed_rational_comparison"
let closed_real_scope = "closed_real_enclosure"
let closed_real_method = "certified_enclosure_sign"
let univariate_poly_scope = "univariate_rational_polynomial"
let univariate_poly_method = "polynomial_zero_difference"
let univariate_witness_method = "exact_rational_counterexample"

let q_of_dyadic mantissa exponent =
  if exponent >= 0 then Q.mul_2exp (Q.of_bigint mantissa) exponent
  else Q.div_2exp (Q.of_bigint mantissa) (-exponent)

let q_bounds_of_value = function
  | Centl_engine.Integer value ->
      let q = Q.of_bigint value in
      Some (q, q)
  | Centl_engine.Rational (numerator, denominator) ->
      let q = Q.make numerator denominator in
      Some (q, q)
  | Centl_engine.Real_enclosure enclosure ->
      Some
        ( q_of_dyadic enclosure.lower_mantissa enclosure.binary_exponent,
          q_of_dyadic enclosure.upper_mantissa enclosure.binary_exponent )
  | _ -> None

let approximate_to_enclosure ?(cancelled = Centl_engine.never_cancelled) limits
    value =
  if cancelled () then
    Error
      {
        Centl_engine.code = "cancelled";
        message = "the request was cancelled";
        position = None;
      }
  else
    match value with
    | Centl_engine.Integer _ | Centl_engine.Rational _
    | Centl_engine.Real_enclosure _ ->
        Ok value
    | Centl_engine.Symbolic expression ->
        Centl_engine.approximate_with_limits ~cancelled limits expression
          (min 20 limits.max_precision_digits)
    | _ ->
        Error
          {
            Centl_engine.code = "unsupported_approximation";
            message = "the claim side cannot form a real enclosure";
            position = None;
          }

let certain_order left_lower left_upper right_lower right_upper =
  if Q.compare left_upper right_lower < 0 then Some (-1)
  else if Q.compare left_lower right_upper > 0 then Some 1
  else None

let is_named_constant name = List.mem name [ "pi"; "e"; "tau" ]

let rec expression_has_free_symbol = function
  | Centl_Core.Literal _ -> false
  | Centl_Core.Symbol name -> not (is_named_constant name)
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _) ->
      expression_has_free_symbol inner
  | Centl_Core.Binary (_, left, right) ->
      expression_has_free_symbol left || expression_has_free_symbol right
  | Centl_Core.Function (_, arguments) ->
      List.exists expression_has_free_symbol arguments
  | Centl_Core.Substitute (inner, _, replacement) ->
      expression_has_free_symbol inner || expression_has_free_symbol replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      expression_has_free_symbol inner
      || expression_has_free_symbol left
      || expression_has_free_symbol right

let expression_of_value = function
  | Centl_engine.Integer value -> Some (Centl_Core.Literal (value, Z.one))
  | Centl_engine.Rational (numerator, denominator) ->
      Some (Centl_Core.Literal (numerator, denominator))
  | Centl_engine.Symbolic expression -> Some expression
  | _ -> None

let value_has_free_symbol value =
  match expression_of_value value with
  | Some expression -> expression_has_free_symbol expression
  | None -> false

let rec free_symbol_names = function
  | Centl_Core.Literal _ -> []
  | Centl_Core.Symbol name -> if is_named_constant name then [] else [ name ]
  | Centl_Core.Negate inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _) ->
      free_symbol_names inner
  | Centl_Core.Binary (_, left, right) ->
      free_symbol_names left @ free_symbol_names right
  | Centl_Core.Function (_, arguments) ->
      List.concat_map free_symbol_names arguments
  | Centl_Core.Substitute (inner, variable, replacement) ->
      (free_symbol_names inner |> List.filter (( <> ) variable))
      @ free_symbol_names replacement
  | Centl_Core.Assuming (inner, left, _, right) ->
      free_symbol_names inner @ free_symbol_names left @ free_symbol_names right

let text_of_expression expression =
  Centl_engine.text_of_value (Centl_engine.Symbolic expression)

let rational_text numerator denominator =
  if Z.equal denominator Z.one then Z.to_string numerator
  else Z.to_string numerator ^ "/" ^ Z.to_string denominator

let polynomial_is_zero coefficients =
  List.for_all
    (fun coefficient -> Z.equal coefficient.Centl_Core.numerator Z.zero)
    coefficients

let witness_candidates =
  let integers =
    [
      0; 1; -1; 2; -2; 3; -3; 4; -4; 5; -5; 6; -6; 7; -7; 8; -8; 9; -9; 10; -10;
    ]
  in
  let fractions =
    [
      (1, 2);
      (-1, 2);
      (3, 2);
      (-3, 2);
      (1, 3);
      (-1, 3);
      (2, 3);
      (-2, 3);
      (1, 4);
      (-1, 4);
      (3, 4);
      (-3, 4);
      (5, 2);
      (-5, 2);
      (5, 3);
      (-5, 3);
      (7, 2);
      (-7, 2);
      (1, 5);
      (-1, 5);
      (2, 5);
      (-2, 5);
      (3, 5);
      (-3, 5);
      (4, 5);
      (-4, 5);
    ]
  in
  List.map (fun n -> (Z.of_int n, Z.one)) integers
  @ List.map (fun (n, d) -> (Z.of_int n, Z.of_int d)) fractions

let evaluate_at ?(cancelled = Centl_engine.never_cancelled) limits expression
    variable numerator denominator =
  if cancelled () then
    Error
      {
        Centl_engine.code = "cancelled";
        message = "the request was cancelled";
        position = None;
      }
  else
    let point = Centl_Core.Literal (numerator, denominator) in
    let substituted = Centl_Core.substitute expression variable point in
    Centl_engine.evaluate_expression_outcome_with_limits ~cancelled limits
      substituted

let find_equality_counterexample ?(cancelled = Centl_engine.never_cancelled)
    limits variable left_expression right_expression =
  let rec search = function
    | [] -> Ok None
    | (numerator, denominator) :: rest ->
        if cancelled () then
          Error
            {
              Centl_engine.code = "cancelled";
              message = "the request was cancelled";
              position = None;
            }
        else
          begin match
            evaluate_at ~cancelled limits left_expression variable numerator
              denominator
          with
          | Error error ->
              if is_operational_error error then Error error else search rest
          | Ok left_outcome ->
              begin match
                evaluate_at ~cancelled limits right_expression variable
                  numerator denominator
              with
              | Error error ->
                  if is_operational_error error then Error error
                  else search rest
              | Ok right_outcome ->
                  begin match
                    ( rational_pair_of_value left_outcome.value,
                      rational_pair_of_value right_outcome.value )
                  with
                  | Some left_pair, Some right_pair ->
                      if
                        Centl_engine.compare_rational_pairs left_pair right_pair
                        = 0
                      then search rest
                      else
                        Ok
                          (Some
                             {
                               bindings =
                                 [
                                   ( variable,
                                     rational_text numerator denominator );
                                 ];
                               left = side_value_of_exact left_outcome.value;
                               right = side_value_of_exact right_outcome.value;
                             })
                  | _ -> search rest
                  end
              end
          end
  in
  search witness_candidates

let unknown_quantified ~claim ~reason ~left ~right =
  make_verification ~verdict:Unknown ~scope:univariate_poly_scope
    ~method_:"claim_admission" ~claim
    ~evidence:
      {
        left;
        right;
        comparison = None;
        reason = Some reason;
        normalized_difference = None;
        counterexample = None;
        dependencies = [];
        left_resolution = None;
        right_resolution = None;
      }
    ~assurance:{ class_ = None_; theorem = None }

let verify_univariate_polynomial ~(claim : claim) ~cancelled limits variable
    left_value right_value =
  match (expression_of_value left_value, expression_of_value right_value) with
  | None, _ | _, None ->
      Ok
        (unknown_quantified ~claim ~reason:"sides_not_symbolic_or_exact"
           ~left:(Some (side_value_of_exact left_value))
           ~right:(Some (side_value_of_exact right_value)))
  | Some left_expression, Some right_expression ->
      let free =
        free_symbol_names left_expression @ free_symbol_names right_expression
        |> List.sort_uniq String.compare
      in
      let unexpected = List.filter (fun name -> name <> variable.name) free in
      if unexpected <> [] then
        Ok
          (unknown_quantified ~claim ~reason:"extra_free_variables"
             ~left:(Some (side_value_of_exact left_value))
             ~right:(Some (side_value_of_exact right_value)))
      else
        begin match claim.relation with
        | Less_than | Less_or_equal | Greater_than | Greater_or_equal ->
            Ok
              (unknown_quantified ~claim
                 ~reason:"quantified_order_not_implemented"
                 ~left:(Some (side_value_of_exact left_value))
                 ~right:(Some (side_value_of_exact right_value)))
        | Equal | Not_equal ->
            let difference =
              Centl_Core.Binary
                (Centl_Core.Subtract, left_expression, right_expression)
            in
            begin match Centl_Core.polynomial_of difference variable.name with
            | None ->
                Ok
                  (unknown_quantified ~claim
                     ~reason:"not_univariate_rational_polynomial"
                     ~left:(Some (side_value_of_exact left_value))
                     ~right:(Some (side_value_of_exact right_value)))
            | Some coefficients ->
                let normalized =
                  Centl_Core.polynomial_expression coefficients variable.name
                in
                let normalized_text = text_of_expression normalized in
                let zero = polynomial_is_zero coefficients in
                begin match (claim.relation, zero) with
                | Equal, true ->
                    (* Normalization is evidence, but the draft F* soundness
                       theorem still has unproved obligations. *)
                    Ok
                      (make_verification ~verdict:Unknown
                         ~scope:univariate_poly_scope
                         ~method_:univariate_poly_method ~claim
                         ~evidence:
                           {
                             left = Some (side_value_of_exact left_value);
                             right = Some (side_value_of_exact right_value);
                             comparison = Some "equal";
                             reason =
                               Some "polynomial_soundness_theorem_pending";
                             normalized_difference = Some normalized_text;
                             counterexample = None;
                             dependencies = [];
                             left_resolution = None;
                             right_resolution = None;
                           }
                         ~assurance:{ class_ = None_; theorem = None })
                | Not_equal, true ->
                    (* Identically equal polynomials refute universal disequality. *)
                    begin match
                      evaluate_at ~cancelled limits left_expression
                        variable.name Z.zero Z.one
                    with
                    | Error error ->
                        if is_operational_error error then Error error
                        else
                          Ok
                            (unknown_quantified ~claim
                               ~reason:"counterexample_evaluation_failed"
                               ~left:(Some (side_value_of_exact left_value))
                               ~right:(Some (side_value_of_exact right_value)))
                    | Ok left_outcome ->
                        begin match
                          evaluate_at ~cancelled limits right_expression
                            variable.name Z.zero Z.one
                        with
                        | Error error ->
                            if is_operational_error error then Error error
                            else
                              Ok
                                (unknown_quantified ~claim
                                   ~reason:"counterexample_evaluation_failed"
                                   ~left:(Some (side_value_of_exact left_value))
                                   ~right:
                                     (Some (side_value_of_exact right_value)))
                        | Ok right_outcome
                          when exact_values_equal left_outcome.value
                                 right_outcome.value ->
                            Ok
                              (make_verification ~verdict:Refuted
                                 ~scope:univariate_poly_scope
                                 ~method_:univariate_witness_method ~claim
                                 ~evidence:
                                   {
                                     left =
                                       Some (side_value_of_exact left_value);
                                     right =
                                       Some (side_value_of_exact right_value);
                                     comparison = Some "equal";
                                     reason = None;
                                     normalized_difference =
                                       Some normalized_text;
                                     counterexample =
                                       Some
                                         {
                                           bindings = [ (variable.name, "0") ];
                                           left =
                                             side_value_of_exact
                                               left_outcome.value;
                                           right =
                                             side_value_of_exact
                                               right_outcome.value;
                                         };
                                     dependencies = [];
                                     left_resolution = None;
                                     right_resolution = None;
                                   }
                                 ~assurance:
                                   { class_ = Witness_checked; theorem = None })
                        | Ok _ ->
                            Ok
                              (unknown_quantified ~claim
                                 ~reason:"counterexample_not_confirmed"
                                 ~left:(Some (side_value_of_exact left_value))
                                 ~right:(Some (side_value_of_exact right_value)))
                        end
                    end
                | Equal, false ->
                    begin match
                      find_equality_counterexample ~cancelled limits
                        variable.name left_expression right_expression
                    with
                    | Error error -> Error error
                    | Ok (Some counterexample) ->
                        Ok
                          (make_verification ~verdict:Refuted
                             ~scope:univariate_poly_scope
                             ~method_:univariate_witness_method ~claim
                             ~evidence:
                               {
                                 left = Some (side_value_of_exact left_value);
                                 right = Some (side_value_of_exact right_value);
                                 comparison = None;
                                 reason = None;
                                 normalized_difference = Some normalized_text;
                                 counterexample = Some counterexample;
                                 dependencies = [];
                                 left_resolution = None;
                                 right_resolution = None;
                               }
                             ~assurance:
                               { class_ = Witness_checked; theorem = None })
                    | Ok None ->
                        Ok
                          (unknown_quantified ~claim
                             ~reason:"no_counterexample_found"
                             ~left:(Some (side_value_of_exact left_value))
                             ~right:(Some (side_value_of_exact right_value)))
                    end
                | Not_equal, false ->
                    Ok
                      (unknown_quantified ~claim
                         ~reason:"universal_disequality_not_decided"
                         ~left:(Some (side_value_of_exact left_value))
                         ~right:(Some (side_value_of_exact right_value)))
                | ( (Less_than | Less_or_equal | Greater_than | Greater_or_equal),
                    _ ) ->
                    Ok
                      (unknown_quantified ~claim
                         ~reason:"quantified_order_not_implemented"
                         ~left:(Some (side_value_of_exact left_value))
                         ~right:(Some (side_value_of_exact right_value)))
                end
            end
        end

let parse_claim_expression source =
  match Centl_parser.parse_statement_located source with
  | Ok located ->
      begin match located.statement with
      | Centl_parser.Evaluate expression -> Some expression
      | Centl_parser.Define_value _ | Centl_parser.Define_function _
      | Centl_parser.Assert _ ->
          None
      end
  | Error _ -> None

let claim_dependencies session (claim : claim) =
  let names = List.map fst session.Centl_engine.bindings in
  let expressions =
    List.filter_map parse_claim_expression [ claim.left; claim.right ]
  in
  let referenced name =
    List.exists (Centl_engine.references_name name) expressions
  in
  let direct = List.filter referenced names in
  let binding_dependencies = function
    | Centl_engine.Bound_value binding -> binding.dependencies
    | Centl_engine.Bound_function binding -> binding.dependencies
  in
  let rec visit visited = function
    | [] -> visited
    | name :: rest when List.mem name visited -> visit visited rest
    | name :: rest ->
        let nested =
          match Centl_engine.lookup session name with
          | None -> []
          | Some binding -> binding_dependencies binding
        in
        visit (name :: visited) (nested @ rest)
  in
  visit [] direct |> List.sort_uniq String.compare

let with_dependencies session (claim : claim) (verification : verification) =
  let dependencies = claim_dependencies session claim in
  if dependencies = [] then verification
  else
    { verification with evidence = { verification.evidence with dependencies } }

let attach_resolutions (verification : verification) left_resolution
    right_resolution =
  {
    verification with
    evidence =
      {
        verification.evidence with
        left_resolution = Some left_resolution;
        right_resolution = Some right_resolution;
      };
  }

let verify_closed_rationals ~(claim : claim) left_value right_value =
  match
    (rational_pair_of_value left_value, rational_pair_of_value right_value)
  with
  | Some left_pair, Some right_pair ->
      let ordering = Centl_engine.compare_rational_pairs left_pair right_pair in
      let holds = relation_holds claim.relation ordering in
      let verdict = if holds then Verified else Refuted in
      make_verification ~verdict ~scope:closed_exact_rational_scope
        ~method_:closed_exact_rational_method ~claim
        ~evidence:
          {
            left = Some (side_value_of_exact left_value);
            right = Some (side_value_of_exact right_value);
            comparison = Some (comparison_name ordering);
            reason = None;
            normalized_difference = None;
            counterexample = None;
            dependencies = [];
            left_resolution = None;
            right_resolution = None;
          }
        ~assurance:{ class_ = Exact_algorithm; theorem = None }
  | _ ->
      make_verification ~verdict:Unknown ~scope:closed_exact_rational_scope
        ~method_:closed_exact_rational_method ~claim
        ~evidence:
          {
            left = Some (side_value_of_exact left_value);
            right = Some (side_value_of_exact right_value);
            comparison = None;
            reason = Some "sides_not_exact_rationals";
            normalized_difference = None;
            counterexample = None;
            dependencies = [];
            left_resolution = None;
            right_resolution = None;
          }
        ~assurance:{ class_ = None_; theorem = None }

let verify_closed_enclosures ~(claim : claim) ~cancelled limits left_value
    right_value =
  match claim.relation with
  | Equal ->
      Ok
        (make_verification ~verdict:Unknown ~scope:closed_real_scope
           ~method_:closed_real_method ~claim
           ~evidence:
             {
               left = Some (side_value_of_exact left_value);
               right = Some (side_value_of_exact right_value);
               comparison = None;
               reason = Some "real_equality_requires_exact_values";
               normalized_difference = None;
               counterexample = None;
               dependencies = [];
               left_resolution = None;
               right_resolution = None;
             }
           ~assurance:{ class_ = None_; theorem = None })
  | relation ->
      (* Sequential approximation: left first, then right. *)
      begin match approximate_to_enclosure ~cancelled limits left_value with
      | Error error ->
          if is_operational_error error then Error error
          else
            Ok
              (make_verification ~verdict:Unknown ~scope:closed_real_scope
                 ~method_:closed_real_method ~claim
                 ~evidence:
                   {
                     left = Some (side_value_of_exact left_value);
                     right = Some (side_value_of_exact right_value);
                     comparison = None;
                     reason = Some "enclosure_unavailable";
                     normalized_difference = None;
                     counterexample = None;
                     dependencies = [];
                     left_resolution = None;
                     right_resolution = None;
                   }
                 ~assurance:{ class_ = None_; theorem = None })
      | Ok left_approx ->
          if cancelled () then
            Error
              {
                Centl_engine.code = "cancelled";
                message = "the request was cancelled";
                position = None;
              }
          else
            begin match
              approximate_to_enclosure ~cancelled limits right_value
            with
            | Error error ->
                if is_operational_error error then Error error
                else
                  Ok
                    (make_verification ~verdict:Unknown ~scope:closed_real_scope
                       ~method_:closed_real_method ~claim
                       ~evidence:
                         {
                           left = Some (side_value_of_exact left_approx);
                           right = Some (side_value_of_exact right_value);
                           comparison = None;
                           reason = Some "enclosure_unavailable";
                           normalized_difference = None;
                           counterexample = None;
                           dependencies = [];
                           left_resolution = None;
                           right_resolution = None;
                         }
                       ~assurance:{ class_ = None_; theorem = None })
            | Ok right_approx ->
                begin match
                  (q_bounds_of_value left_approx, q_bounds_of_value right_approx)
                with
                | Some (ll, lu), Some (rl, ru) ->
                    begin match certain_order ll lu rl ru with
                    | Some ordering ->
                        let holds = relation_holds relation ordering in
                        let verdict = if holds then Verified else Refuted in
                        Ok
                          (make_verification ~verdict ~scope:closed_real_scope
                             ~method_:closed_real_method ~claim
                             ~evidence:
                               {
                                 left = Some (side_value_of_exact left_approx);
                                 right = Some (side_value_of_exact right_approx);
                                 comparison = Some (comparison_name ordering);
                                 reason = None;
                                 normalized_difference = None;
                                 counterexample = None;
                                 dependencies = [];
                                 left_resolution = None;
                                 right_resolution = None;
                               }
                             ~assurance:
                               { class_ = Certified_enclosure; theorem = None })
                    | None ->
                        Ok
                          (make_verification ~verdict:Unknown
                             ~scope:closed_real_scope
                             ~method_:closed_real_method ~claim
                             ~evidence:
                               {
                                 left = Some (side_value_of_exact left_approx);
                                 right = Some (side_value_of_exact right_approx);
                                 comparison = None;
                                 reason = Some "enclosures_overlap";
                                 normalized_difference = None;
                                 counterexample = None;
                                 dependencies = [];
                                 left_resolution = None;
                                 right_resolution = None;
                               }
                             ~assurance:{ class_ = None_; theorem = None })
                    end
                | _ ->
                    Ok
                      (make_verification ~verdict:Unknown
                         ~scope:closed_real_scope ~method_:closed_real_method
                         ~claim
                         ~evidence:
                           {
                             left = Some (side_value_of_exact left_value);
                             right = Some (side_value_of_exact right_value);
                             comparison = None;
                             reason = Some "sides_not_real_enclosures";
                             normalized_difference = None;
                             counterexample = None;
                             dependencies = [];
                             left_resolution = None;
                             right_resolution = None;
                           }
                         ~assurance:{ class_ = None_; theorem = None })
                end
            end
      end

let decide_closed ~(claim : claim) ~cancelled limits left_value right_value =
  match
    (rational_pair_of_value left_value, rational_pair_of_value right_value)
  with
  | Some _, Some _ -> Ok (verify_closed_rationals ~claim left_value right_value)
  | _ ->
      if value_has_free_symbol left_value || value_has_free_symbol right_value
      then
        Ok
          (make_verification ~verdict:Unknown ~scope:"open_claim"
             ~method_:"claim_admission" ~claim
             ~evidence:
               {
                 left = Some (side_value_of_exact left_value);
                 right = Some (side_value_of_exact right_value);
                 comparison = None;
                 reason = Some "free_variables_require_quantification";
                 normalized_difference = None;
                 counterexample = None;
                 dependencies = [];
                 left_resolution = None;
                 right_resolution = None;
               }
             ~assurance:{ class_ = None_; theorem = None })
      else
        verify_closed_enclosures ~claim ~cancelled limits left_value right_value

let verify ?(cancelled = Centl_engine.never_cancelled)
    ?(limits = Centl_engine.default_evaluation_limits) session fields =
  match parse_claim fields with
  | Error error -> Error error
  | Ok claim ->
      if claim.assumptions <> [] then
        Ok
          (make_verification ~verdict:Unknown
             ~scope:"unsupported_assumption_domain" ~method_:"claim_admission"
             ~claim
             ~evidence:
               {
                 empty_evidence with
                 reason = Some "free_form_assumptions_unsupported";
               }
             ~assurance:{ class_ = None_; theorem = None })
      else if List.length claim.variables > 1 then
        Ok
          (make_verification ~verdict:Unknown
             ~scope:"quantified_claim_not_implemented"
             ~method_:"claim_admission" ~claim
             ~evidence:
               {
                 empty_evidence with
                 reason = Some "multiple_variables_not_implemented";
               }
             ~assurance:{ class_ = None_; theorem = None })
      else if
        match claim.variables with
        | [ variable ] ->
            Option.is_some (Centl_engine.lookup session variable.name)
        | [] | _ :: _ :: _ -> false
      then
        Ok
          (make_verification ~verdict:Unknown ~scope:univariate_poly_scope
             ~method_:"claim_admission" ~claim
             ~evidence:
               {
                 empty_evidence with
                 reason = Some "quantified_variable_shadows_session_binding";
               }
             ~assurance:{ class_ = None_; theorem = None })
      else
        (* Sequential side evaluation: left first. *)
        begin match evaluate_side ~cancelled limits session claim.left with
        | Error error ->
            if is_operational_error error then Error error
            else
              Ok
                (make_verification ~verdict:Invalid
                   ~scope:closed_exact_rational_scope
                   ~method_:closed_exact_rational_method ~claim
                   ~evidence:
                     {
                       empty_evidence with
                       reason = Some error.Centl_engine.code;
                     }
                   ~assurance:{ class_ = None_; theorem = None })
        | Ok left_outcome ->
            if cancelled () then
              Error
                {
                  Centl_engine.code = "cancelled";
                  message = "the request was cancelled";
                  position = None;
                }
            else
              begin match
                evaluate_side ~cancelled limits session claim.right
              with
              | Error error ->
                  if is_operational_error error then Error error
                  else
                    Ok
                      (make_verification ~verdict:Invalid
                         ~scope:closed_exact_rational_scope
                         ~method_:closed_exact_rational_method ~claim
                         ~evidence:
                           {
                             empty_evidence with
                             reason = Some error.Centl_engine.code;
                           }
                         ~assurance:{ class_ = None_; theorem = None })
              | Ok right_outcome ->
                  begin match (left_outcome.result, right_outcome.result) with
                  | ( Centl_engine.Session_value left_value,
                      Centl_engine.Session_value right_value ) ->
                      let decided =
                        match claim.variables with
                        | [ variable ] ->
                            verify_univariate_polynomial ~claim ~cancelled
                              limits variable left_value right_value
                        | _ ->
                            decide_closed ~claim ~cancelled limits left_value
                              right_value
                      in
                      begin match decided with
                      | Error error -> Error error
                      | Ok verification ->
                          Ok
                            (with_dependencies session claim
                               (attach_resolutions verification
                                  left_outcome.resolution
                                  right_outcome.resolution))
                      end
                  | _ ->
                      Ok
                        (make_verification ~verdict:Invalid
                           ~scope:closed_exact_rational_scope
                           ~method_:closed_exact_rational_method ~claim
                           ~evidence:
                             {
                               empty_evidence with
                               reason = Some "claim_sides_must_be_expressions";
                             }
                           ~assurance:{ class_ = None_; theorem = None })
                  end
              end
        end

let json_of_dyadic (dyadic : dyadic_bounds) =
  `Assoc
    [
      ("lower_mantissa", `String dyadic.lower_mantissa);
      ("upper_mantissa", `String dyadic.upper_mantissa);
      ("binary_exponent", `Int dyadic.binary_exponent);
    ]

let json_of_side_value (side : side_value) =
  let fields = [ ("kind", `String side.kind); ("text", `String side.text) ] in
  let fields =
    match side.numerator with
    | None -> fields
    | Some numerator -> fields @ [ ("numerator", `String numerator) ]
  in
  let fields =
    match side.denominator with
    | None -> fields
    | Some denominator -> fields @ [ ("denominator", `String denominator) ]
  in
  let fields =
    match side.dyadic with
    | None -> fields
    | Some dyadic -> fields @ [ ("dyadic", json_of_dyadic dyadic) ]
  in
  let fields =
    match side.lower with
    | None -> fields
    | Some lower -> fields @ [ ("lower", `String lower) ]
  in
  let fields =
    match side.upper with
    | None -> fields
    | Some upper -> fields @ [ ("upper", `String upper) ]
  in
  let fields =
    match side.requested_digits with
    | None -> fields
    | Some digits -> fields @ [ ("requested_digits", `Int digits) ]
  in
  let fields =
    match side.working_bits with
    | None -> fields
    | Some bits -> fields @ [ ("working_bits", `Int bits) ]
  in
  `Assoc fields

let json_of_resolution_opt = function
  | None -> None
  | Some resolution -> Some (Centl_engine.json_of_resolution resolution)

let json_of_counterexample (counterexample : counterexample) =
  `Assoc
    [
      ( "bindings",
        `Assoc
          (List.map
             (fun (name, value) -> (name, `String value))
             counterexample.bindings) );
      ("left", json_of_side_value counterexample.left);
      ("right", json_of_side_value counterexample.right);
    ]

let json_of_evidence (evidence : evidence) =
  let fields = [] in
  let fields =
    match evidence.left with
    | None -> fields
    | Some left -> fields @ [ ("left", json_of_side_value left) ]
  in
  let fields =
    match evidence.right with
    | None -> fields
    | Some right -> fields @ [ ("right", json_of_side_value right) ]
  in
  let fields =
    match evidence.comparison with
    | None -> fields
    | Some comparison -> fields @ [ ("comparison", `String comparison) ]
  in
  let fields =
    match evidence.reason with
    | None -> fields
    | Some reason -> fields @ [ ("reason", `String reason) ]
  in
  let fields =
    match evidence.normalized_difference with
    | None -> fields
    | Some difference ->
        fields @ [ ("normalized_difference", `String difference) ]
  in
  let fields =
    match evidence.counterexample with
    | None -> fields
    | Some counterexample ->
        fields @ [ ("counterexample", json_of_counterexample counterexample) ]
  in
  let fields =
    match evidence.dependencies with
    | [] -> fields
    | dependencies ->
        fields
        @ [
            ( "dependencies",
              `List (List.map (fun name -> `String name) dependencies) );
          ]
  in
  let fields =
    match json_of_resolution_opt evidence.left_resolution with
    | None -> fields
    | Some resolution -> fields @ [ ("left_resolution", resolution) ]
  in
  let fields =
    match json_of_resolution_opt evidence.right_resolution with
    | None -> fields
    | Some resolution -> fields @ [ ("right_resolution", resolution) ]
  in
  `Assoc fields

let json_of_claim (claim : claim) =
  `Assoc
    [
      ("left", `String claim.left);
      ("relation", `String (relation_name claim.relation));
      ("right", `String claim.right);
      ( "variables",
        `List
          (List.map
             (fun variable ->
               `Assoc
                 [
                   ("name", `String variable.name);
                   ("domain", `String variable.domain);
                 ])
             claim.variables) );
      ( "assumptions",
        `List
          (List.map (fun assumption -> `String assumption) claim.assumptions) );
    ]

let json_of_assurance (assurance : assurance) =
  let fields = [ ("class", `String (assurance_class_name assurance.class_)) ] in
  let fields =
    match assurance.theorem with
    | None -> fields
    | Some theorem -> fields @ [ ("theorem", `String theorem) ]
  in
  `Assoc fields

let json_of_verification (verification : verification) =
  `Assoc
    [
      ("schema", `Int verification.schema);
      ("verdict", `String (verdict_name verification.verdict));
      ("scope", `String verification.scope);
      ("method", `String verification.method_);
      ("claim", json_of_claim verification.claim);
      ("evidence", json_of_evidence verification.evidence);
      ("assurance", json_of_assurance verification.assurance);
      ( "producer",
        `Assoc
          [
            ("name", `String "centl"); ("version", `String Centl_version.value);
          ] );
    ]

let text_of_verification (verification : verification) =
  let base =
    Printf.sprintf "verdict: %s (%s via %s)"
      (verdict_name verification.verdict)
      verification.scope verification.method_
  in
  let details =
    List.filter_map Fun.id
      [
        Option.map
          (fun comparison -> "comparison=" ^ comparison)
          verification.evidence.comparison;
        Option.map
          (fun reason -> "reason=" ^ reason)
          verification.evidence.reason;
      ]
  in
  let base =
    match details with
    | [] -> base
    | details -> base ^ "; " ^ String.concat "; " details
  in
  match verification.evidence.counterexample with
  | None -> base
  | Some counterexample ->
      let bindings =
        counterexample.bindings
        |> List.map (fun (name, value) -> name ^ "=" ^ value)
        |> String.concat ", "
      in
      base ^ "; counterexample={" ^ bindings ^ "}"

let json_byte_size json = String.length (Yojson.Safe.to_string json)

let enforce_response_limit ?(cancelled = Centl_engine.never_cancelled) limits
    response =
  if cancelled () then
    Error
      {
        Centl_engine.code = "cancelled";
        message = "the request was cancelled";
        position = None;
      }
  else
    let size = json_byte_size response in
    if size > limits.Centl_engine.max_result_bytes then
      Error
        {
          Centl_engine.code = "resource_limit";
          message = "the verification result exceeds the result-byte limit";
          position = None;
        }
    else Ok response
