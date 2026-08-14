let test_additive_identity_is_cheaper () =
  match Centl_sci_mirage_rewrite.extract_source "x + 0" with
  | None -> Alcotest.fail "expected rewrite extraction"
  | Some extraction ->
      Alcotest.(check bool) "improved" true extraction.improved;
      Alcotest.(check string) "equivalent" "x" extraction.equivalent

let test_zero_product_collapses () =
  match Centl_sci_mirage_rewrite.extract_source "0 * (x + 1)" with
  | None -> Alcotest.fail "expected rewrite extraction"
  | Some extraction ->
      Alcotest.(check bool) "improved" true extraction.improved;
      Alcotest.(check string) "equivalent" "0" extraction.equivalent

let test_does_not_invent_nonzero_power_zero () =
  match Centl_sci_mirage_rewrite.extract_source "0^0" with
  | None -> Alcotest.fail "expected rewrite extraction"
  | Some extraction ->
      Alcotest.(check bool)
        "0^0 is not rewritten to 1" false extraction.improved

let () =
  Alcotest.run "CENTL-MIRAGE rewrite"
    [
      ( "saturation",
        [
          Alcotest.test_case "additive identity" `Quick
            test_additive_identity_is_cheaper;
          Alcotest.test_case "zero product" `Quick test_zero_product_collapses;
          Alcotest.test_case "0^0 remains" `Quick
            test_does_not_invent_nonzero_power_zero;
        ] );
    ]
