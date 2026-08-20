open Centl_chemistry_sample_protocol
open Yojson.Safe.Util

let unwrap = function
  | Ok json -> json
  | Error json ->
      Alcotest.failf "unexpected sample protocol error: %s"
        (Yojson.Safe.to_string json)

let test_protocol_spread () =
  let json =
    unwrap
      (spread_request ~unit_symbol:"g"
         [ "10.01"; "10.04"; "9.98"; "10.03"; "9.99" ])
  in
  Alcotest.(check string) "kind" "chemistry_sample_spread"
    (json |> member "kind" |> to_string);
  Alcotest.(check string) "source" "measured"
    (json |> member "source_class" |> to_string);
  Alcotest.(check string) "arithmetic" "exact_over_reported_values"
    (json |> member "arithmetic_class" |> to_string);
  Alcotest.(check int) "n" 5 (json |> member "n" |> to_int);
  let first_observation = json |> member "observations" |> to_list |> List.hd in
  Alcotest.(check string) "observation source" "measured"
    (first_observation |> member "source_class" |> to_string);
  Alcotest.(check string) "observation representation"
    "exact_rational_of_reported_value"
    (first_observation |> member "representation_class" |> to_string);
  Alcotest.(check string) "mean" "1001/100"
    (json |> member "mean" |> member "value" |> to_string);
  Alcotest.(check string) "mean input source" "measured"
    (json |> member "mean" |> member "input_source_class" |> to_string);
  Alcotest.(check string) "mean arithmetic" "exact_over_reported_values"
    (json |> member "mean" |> member "arithmetic_class" |> to_string);
  Alcotest.(check string) "sample variance" "13/20000"
    (json |> member "sample_variance" |> member "value" |> to_string);
  Alcotest.(check string) "sample sd kind" "exact_radical"
    (json |> member "sample_standard_deviation" |> member "kind" |> to_string);
  Alcotest.(check string) "sample sd radicand" "13/20000"
    (json |> member "sample_standard_deviation" |> member "radicand" |> to_string);
  Alcotest.(check string) "rsd representation" "fraction_not_percent"
    (json |> member "relative_standard_deviation" |> member "representation"
   |> to_string);
  Alcotest.(check string) "confidence interval" "not_computed"
    (json |> member "confidence_interval" |> member "status" |> to_string);
  Alcotest.(check string) "measurement uncertainty" "not_provided"
    (json |> member "measurement_uncertainty" |> member "status" |> to_string)

let test_declared_exact_protocol () =
  let json =
    unwrap
      (spread_request ~observation_class:Centl_chemistry_sample.Declared_exact
         ~unit_symbol:"mol" [ "1/3"; "2/3" ])
  in
  Alcotest.(check string) "source" "declared_exact"
    (json |> member "source_class" |> to_string);
  Alcotest.(check string) "mean" "1/2"
    (json |> member "mean" |> member "value" |> to_string);
  Alcotest.(check string) "derived input source" "declared_exact"
    (json |> member "mean" |> member "input_source_class" |> to_string)

let test_protocol_error () =
  match spread_request ~unit_symbol:"g" [ "1/0" ] with
  | Ok json ->
      Alcotest.failf "unexpected success: %s" (Yojson.Safe.to_string json)
  | Error json ->
      Alcotest.(check string) "kind" "chemistry_sample_error"
        (json |> member "kind" |> to_string);
      Alcotest.(check string) "code" "invalid_observation"
        (json |> member "code" |> to_string)

let () =
  Alcotest.run "CENTL Chemistry sample protocol"
    [
      ( "protocol",
        [
          Alcotest.test_case "measured spread" `Quick test_protocol_spread;
          Alcotest.test_case "declared exact spread" `Quick
            test_declared_exact_protocol;
          Alcotest.test_case "error" `Quick test_protocol_error;
        ] );
    ]

