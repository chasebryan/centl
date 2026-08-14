type extraction = {
  source : string;
  equivalent : string;
  cost_before : int;
  cost_after : int;
  classes : int;
  iterations : int;
  improved : bool;
}

type report = { extractions : extraction list; budget : int }

let default_budget = 8
let zero = Centl_Core.Literal (Z.zero, Z.one)
let one = Centl_Core.Literal (Z.one, Z.one)

let rec equal left right =
  match (left, right) with
  | Centl_Core.Literal (ln, ld), Centl_Core.Literal (rn, rd) ->
      Z.equal ln rn && Z.equal ld rd
  | Centl_Core.Symbol left, Centl_Core.Symbol right -> String.equal left right
  | Centl_Core.Negate left, Centl_Core.Negate right -> equal left right
  | Centl_Core.Binary (lop, ll, lr), Centl_Core.Binary (rop, rl, rr) ->
      lop = rop && equal ll rl && equal lr rr
  | Centl_Core.Power (lb, le), Centl_Core.Power (rb, re) ->
      equal lb rb && Z.equal le re
  | Centl_Core.Function (ln, la), Centl_Core.Function (rn, ra) ->
      String.equal ln rn
      && List.length la = List.length ra
      && List.for_all2 equal la ra
  | Centl_Core.Simplify left, Centl_Core.Simplify right
  | Centl_Core.Expand left, Centl_Core.Expand right
  | Centl_Core.Factor left, Centl_Core.Factor right ->
      equal left right
  | Centl_Core.Differentiate (le, lv), Centl_Core.Differentiate (re, rv)
  | Centl_Core.Derivative (le, lv), Centl_Core.Derivative (re, rv) ->
      String.equal lv rv && equal le re
  | Centl_Core.Substitute (le, lv, lr), Centl_Core.Substitute (re, rv, rr) ->
      String.equal lv rv && equal le re && equal lr rr
  | ( Centl_Core.Assuming (lt, ll, lrel, lr),
      Centl_Core.Assuming (rt, rl, rrel, rr) ) ->
      lrel = rrel && equal lt rt && equal ll rl && equal lr rr
  | _ -> false

let rec cost = function
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> 1
  | Centl_Core.Negate inner
  | Centl_Core.Simplify inner
  | Centl_Core.Expand inner
  | Centl_Core.Factor inner
  | Centl_Core.Power (inner, _)
  | Centl_Core.Differentiate (inner, _)
  | Centl_Core.Derivative (inner, _) ->
      1 + cost inner
  | Centl_Core.Binary (_, left, right) -> 1 + cost left + cost right
  | Centl_Core.Substitute (inner, _, replacement) ->
      1 + cost inner + cost replacement
  | Centl_Core.Function (_, arguments) ->
      1 + List.fold_left (fun total item -> total + cost item) 0 arguments
  | Centl_Core.Assuming (inner, left, _, right) ->
      1 + cost inner + cost left + cost right

let is_zero = function
  | Centl_Core.Literal (numerator, _) -> Z.equal numerator Z.zero
  | _ -> false

let is_one = function
  | Centl_Core.Literal (numerator, denominator) ->
      Z.equal numerator denominator && not (Z.equal denominator Z.zero)
  | _ -> false

let rec map_sub rewrite expression =
  match expression with
  | Centl_Core.Literal _ | Centl_Core.Symbol _ -> []
  | Centl_Core.Negate inner ->
      List.map (fun inner -> Centl_Core.Negate inner) (rewrite inner)
  | Centl_Core.Binary (op, left, right) ->
      List.map (fun left -> Centl_Core.Binary (op, left, right)) (rewrite left)
      @ List.map
          (fun right -> Centl_Core.Binary (op, left, right))
          (rewrite right)
  | Centl_Core.Power (base, exponent) ->
      List.map (fun base -> Centl_Core.Power (base, exponent)) (rewrite base)
  | Centl_Core.Function (name, arguments) ->
      let rec loop prefix = function
        | [] -> []
        | argument :: rest ->
            List.map
              (fun rewritten ->
                Centl_Core.Function
                  (name, List.rev_append prefix (rewritten :: rest)))
              (rewrite argument)
            @ loop (argument :: prefix) rest
      in
      loop [] arguments
  | Centl_Core.Simplify inner ->
      List.map (fun inner -> Centl_Core.Simplify inner) (rewrite inner)
  | Centl_Core.Expand inner ->
      List.map (fun inner -> Centl_Core.Expand inner) (rewrite inner)
  | Centl_Core.Factor inner ->
      List.map (fun inner -> Centl_Core.Factor inner) (rewrite inner)
  | Centl_Core.Differentiate (inner, variable) ->
      List.map
        (fun inner -> Centl_Core.Differentiate (inner, variable))
        (rewrite inner)
  | Centl_Core.Derivative (inner, variable) ->
      List.map
        (fun inner -> Centl_Core.Derivative (inner, variable))
        (rewrite inner)
  | Centl_Core.Substitute (inner, variable, replacement) ->
      List.map
        (fun inner -> Centl_Core.Substitute (inner, variable, replacement))
        (rewrite inner)
      @ List.map
          (fun replacement ->
            Centl_Core.Substitute (inner, variable, replacement))
          (rewrite replacement)
  | Centl_Core.Assuming (inner, left, relation, right) ->
      List.map
        (fun inner -> Centl_Core.Assuming (inner, left, relation, right))
        (rewrite inner)

let local_rules expression =
  match expression with
  | Centl_Core.Binary (Centl_Core.Add, left, right) when is_zero right ->
      [ left ]
  | Centl_Core.Binary (Centl_Core.Add, left, right) when is_zero left ->
      [ right ]
  | Centl_Core.Binary (Centl_Core.Subtract, left, right) when is_zero right ->
      [ left ]
  | Centl_Core.Binary (Centl_Core.Subtract, left, right) when equal left right
    ->
      [ zero ]
  | Centl_Core.Binary (Centl_Core.Multiply, left, right) when is_one right ->
      [ left ]
  | Centl_Core.Binary (Centl_Core.Multiply, left, right) when is_one left ->
      [ right ]
  | Centl_Core.Binary (Centl_Core.Multiply, left, right)
    when is_zero left || is_zero right ->
      [ zero ]
  | Centl_Core.Negate (Centl_Core.Negate inner) -> [ inner ]
  | Centl_Core.Power (base, exponent) when Z.equal exponent Z.one -> [ base ]
  | Centl_Core.Power (base, exponent)
    when Z.equal exponent Z.zero && not (is_zero base) ->
      [ one ]
  | Centl_Core.Binary
      (Centl_Core.Add, Centl_Core.Binary (Centl_Core.Add, a, b), c) ->
      [
        Centl_Core.Binary
          (Centl_Core.Add, a, Centl_Core.Binary (Centl_Core.Add, b, c));
        Centl_Core.Binary
          (Centl_Core.Add, c, Centl_Core.Binary (Centl_Core.Add, a, b));
      ]
  | Centl_Core.Binary
      (Centl_Core.Multiply, Centl_Core.Binary (Centl_Core.Multiply, a, b), c) ->
      [
        Centl_Core.Binary
          (Centl_Core.Multiply, a, Centl_Core.Binary (Centl_Core.Multiply, b, c));
        Centl_Core.Binary
          (Centl_Core.Multiply, c, Centl_Core.Binary (Centl_Core.Multiply, a, b));
      ]
  | Centl_Core.Binary
      (((Centl_Core.Add | Centl_Core.Multiply) as op), left, right) ->
      [ Centl_Core.Binary (op, right, left) ]
  | _ -> []

let rec step expression = local_rules expression @ map_sub step expression

let add_unique expression classes =
  if List.exists (equal expression) classes then classes
  else expression :: classes

let saturate ?(budget = default_budget) root =
  let budget = max 1 budget in
  let rec loop iteration classes =
    if iteration >= budget || List.length classes > 64 then (classes, iteration)
    else
      let next =
        List.fold_left
          (fun acc expression ->
            List.fold_left
              (fun acc item -> add_unique item acc)
              acc (step expression))
          classes classes
      in
      if List.length next = List.length classes then (classes, iteration)
      else loop (iteration + 1) next
  in
  loop 0 [ root ]

let extract classes =
  match classes with
  | [] -> None
  | first :: rest ->
      Some
        (List.fold_left
           (fun best candidate ->
             let best_cost = cost best and candidate_cost = cost candidate in
             if candidate_cost < best_cost then candidate
             else if candidate_cost > best_cost then best
             else if
               String.compare
                 (Centl_engine.text_of_value (Centl_engine.Symbolic candidate))
                 (Centl_engine.text_of_value (Centl_engine.Symbolic best))
               < 0
             then candidate
             else best)
           first rest)

let expression_of_source source =
  match Centl_parser.parse_located source with
  | Ok located -> Some located.expression
  | Error _ -> None

let body_of_definition source =
  match Centl_parser.parse_statement_located source with
  | Ok located -> (
      match located.statement with
      | Centl_parser.Define_function (_, _, body) -> Some body
      | Centl_parser.Define_value (_, body) -> Some body
      | _ -> None)
  | Error _ -> None

let extract_source source =
  match body_of_definition source with
  | None -> (
      match expression_of_source source with
      | None -> None
      | Some expression ->
          let classes, iterations = saturate expression in
          let chosen = Option.value ~default:expression (extract classes) in
          Some
            {
              source;
              equivalent =
                Centl_engine.text_of_value (Centl_engine.Symbolic chosen);
              cost_before = cost expression;
              cost_after = cost chosen;
              classes = List.length classes;
              iterations;
              improved = cost chosen < cost expression;
            })
  | Some body ->
      let classes, iterations = saturate body in
      let chosen = Option.value ~default:body (extract classes) in
      Some
        {
          source;
          equivalent = Centl_engine.text_of_value (Centl_engine.Symbolic chosen);
          cost_before = cost body;
          cost_after = cost chosen;
          classes = List.length classes;
          iterations;
          improved = cost chosen < cost body;
        }

let run materialization =
  let extractions =
    materialization.Centl_sci_mirage_materialize.items
    |> List.filter_map (fun item -> item.Centl_sci_mirage_materialize.source)
    |> List.filter_map extract_source
  in
  { extractions; budget = default_budget }

let extraction_to_json extraction =
  `Assoc
    [
      ("source", `String extraction.source);
      ("equivalent", `String extraction.equivalent);
      ("cost_before", `Int extraction.cost_before);
      ("cost_after", `Int extraction.cost_after);
      ("classes", `Int extraction.classes);
      ("iterations", `Int extraction.iterations);
      ("improved", `Bool extraction.improved);
    ]

let to_json report =
  `Assoc
    [
      ("schema_version", `Int 1);
      ("system", `String "CENTL-MIRAGE");
      ("artifact_kind", `String "equality_saturation");
      ("budget", `Int report.budget);
      ("extraction_count", `Int (List.length report.extractions));
      ( "rewrite_semantics",
        `String
          "bounded algebraic rewrite saturation searches equivalent forms; \
           extraction prefers lower syntactic cost and does not establish a \
           new mathematical theorem" );
      ("extractions", `List (List.map extraction_to_json report.extractions));
    ]

let output_path materialization_path =
  if String.ends_with ~suffix:".materialization.json" materialization_path then
    String.sub materialization_path 0
      (String.length materialization_path
      - String.length ".materialization.json")
    ^ ".rewrite.json"
  else materialization_path ^ ".rewrite.json"

let construct materialization_path materialization =
  let report = run materialization in
  let path = output_path materialization_path in
  try
    Centl_sci_workspace.atomic_write_json path (to_json report);
    Ok (path, report)
  with Sys_error message | Unix.Unix_error (_, _, message) -> Error message

let render report =
  let improved =
    List.fold_left
      (fun total extraction -> if extraction.improved then total + 1 else total)
      0 report.extractions
  in
  String.concat "\n"
    [
      "CENTL-MIRAGE equality saturation";
      "extractions: " ^ string_of_int (List.length report.extractions);
      "improved forms: " ^ string_of_int improved;
      "budget: " ^ string_of_int report.budget;
      "formal completeness: no";
    ]
