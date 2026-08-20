open Centl_chemistry_sample

let unwrap = function
  | Ok value -> value
  | Error error -> Alcotest.failf "unexpected sample error: %s" (error_message error)

let check_q label expected actual =
  Alcotest.(check string) label expected (Q.to_string actual)

let test_exact_and_radical_spread () =
  let summary = unwrap (summarize_strings ~unit_symbol:"g" [ "1"; "3" ]) in
  Alcotest.(check int) "n" 2 summary.n;
  check_q "mean" "2" summary.mean;
  check_q "median" "2" summary.median;
  check_q "range" "2" summary.range;
  check_q "mad" "1" summary.median_absolute_deviation;
  check_q "population variance" "1" summary.population_variance;
  begin
    match summary.population_standard_deviation with
    | Exact_rational value -> check_q "population sd" "1" value
    | Exact_sqrt_rational value ->
        Alcotest.failf "population sd should be rational, got sqrt(%s)" (Q.to_string value)
  end;
  begin
    match summary.sample_variance with
    | None -> Alcotest.fail "sample variance unexpectedly undefined"
    | Some value -> check_q "sample variance" "2" value
  end;
  begin
    match summary.sample_standard_deviation with
    | Available (Exact_sqrt_rational value) -> check_q "sample sd radicand" "2" value
    | Available (Exact_rational value) ->
        Alcotest.failf "sample sd should be radical, got %s" (Q.to_string value)
    | Undefined reason -> Alcotest.failf "sample sd undefined: %s" reason
  end;
  begin
    match summary.standard_error_of_mean with
    | Available (Exact_rational value) -> check_q "standard error" "1" value
    | Available (Exact_sqrt_rational value) ->
        Alcotest.failf "standard error should be rational, got sqrt(%s)" (Q.to_string value)
    | Undefined reason -> Alcotest.failf "standard error undefined: %s" reason
  end

let test_five_replicate_spread () =
  let summary =
    unwrap
      (summarize_strings ~unit_symbol:"g"
         [ "10.01"; "10.04"; "9.98"; "10.03"; "9.99" ])
  in
  Alcotest.(check int) "n" 5 summary.n;
  check_q "sum" "1001/20" summary.sum;
  check_q "mean" "1001/100" summary.mean;
  check_q "median" "1001/100" summary.median;
  check_q "minimum" "499/50" summary.minimum;
  check_q "maximum" "251/25" summary.maximum;
  check_q "range" "3/50" summary.range;
  check_q "mad" "1/50" summary.median_absolute_deviation;
  check_q "population variance" "13/25000" summary.population_variance;
  begin
    match summary.sample_variance with
    | Some value -> check_q "sample variance" "13/20000" value
    | None -> Alcotest.fail "sample variance unexpectedly undefined"
  end;
  begin
    match summary.relative_standard_deviation with
    | Available (Exact_sqrt_rational value) -> check_q "rsd radicand" "1/154154" value
    | Available (Exact_rational value) ->
        Alcotest.failf "RSD should be radical, got %s" (Q.to_string value)
    | Undefined reason -> Alcotest.failf "RSD undefined: %s" reason
  end

let test_single_observation_semantics () =
  let summary = unwrap (summarize_strings ~unit_symbol:"mol" [ "3/2" ]) in
  Alcotest.(check int) "n" 1 summary.n;
  begin
    match summary.sample_variance with
    | None -> ()
    | Some value -> Alcotest.failf "sample variance should be undefined, got %s" (Q.to_string value)
  end;
  begin
    match summary.sample_standard_deviation with
    | Undefined "requires_at_least_two_observations" -> ()
    | Undefined reason -> Alcotest.failf "wrong undefined reason: %s" reason
    | Available _ -> Alcotest.fail "sample sd should be undefined"
  end

let test_invalid_rational_refusal () =
  match summarize_strings ~unit_symbol:"g" [ "1/0" ] with
  | Error (Invalid_observation "1/0") -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "division-by-zero observation was accepted"

let test_unknown_unit_refusal () =
  match summarize_strings ~unit_symbol:"bananas" [ "1"; "2" ] with
  | Error (Unknown_unit "bananas") -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "unknown unit was accepted"

let test_observation_limit () =
  let values = List.init (max_observations + 1) (fun _ -> "1") in
  match summarize_strings ~unit_symbol:"g" values with
  | Error Too_many_observations -> ()
  | Error error -> Alcotest.failf "wrong error: %s" (error_message error)
  | Ok _ -> Alcotest.fail "oversized sample was accepted"

let () =
  Alcotest.run "CENTL Chemistry sample spread"
    [
      ( "spread",
        [
          Alcotest.test_case "rational and radical" `Quick test_exact_and_radical_spread;
          Alcotest.test_case "five replicates" `Quick test_five_replicate_spread;
          Alcotest.test_case "single observation" `Quick test_single_observation_semantics;
        ] );
      ( "refusals",
        [
          Alcotest.test_case "invalid rational" `Quick test_invalid_rational_refusal;
          Alcotest.test_case "unknown unit" `Quick test_unknown_unit_refusal;
          Alcotest.test_case "observation limit" `Quick test_observation_limit;
        ] );
    ]
