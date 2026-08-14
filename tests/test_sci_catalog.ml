let test_discovery_requests () =
  Alcotest.(check bool)
    "what can you do" true
    (Centl_sci_catalog.is_discovery_request "What can you do?");
  Alcotest.(check bool)
    "catalog" true
    (Centl_sci_catalog.is_discovery_request "catalog");
  Alcotest.(check bool)
    "ordinary math is not discovery" false
    (Centl_sci_catalog.is_discovery_request "What is 0.1 plus 0.2?")

let test_catalog_contains_gcd () =
  let rendered = Centl_sci_catalog.render () in
  Alcotest.(check bool)
    "gcd is listed" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"gcd" rendered));
  Alcotest.(check bool)
    "no model invention" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"cannot add one by talking"
          rendered))

let test_products_do_not_declare_oasis_on_main () =
  let rendered = Centl_sci_products.render () in
  Alcotest.(check bool)
    "names CENTL" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"CENTL" rendered));
  Alcotest.(check bool)
    "Wellspring is not a product release" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"not a release" rendered))

let test_next_steps_do_not_invent_math () =
  let rendered = Centl_sci_next.render ~problem:"orbital transfer" () in
  Alcotest.(check bool)
    "no invented answer" true
    (Option.is_some
       (Centl_sci_interaction.find_substring ~needle:"did not invent" rendered)
    || Option.is_some
         (Centl_sci_interaction.find_substring ~needle:"extend" rendered))

let () =
  Alcotest.run "CENTL-SCi catalog"
    [
      ( "discovery",
        [
          Alcotest.test_case "request classification" `Quick
            test_discovery_requests;
          Alcotest.test_case "catalog" `Quick test_catalog_contains_gcd;
          Alcotest.test_case "products" `Quick
            test_products_do_not_declare_oasis_on_main;
          Alcotest.test_case "next steps" `Quick
            test_next_steps_do_not_invent_math;
        ] );
    ]
