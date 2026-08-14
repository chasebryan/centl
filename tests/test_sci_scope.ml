let test_allows_science () =
  Alcotest.(check bool)
    "math" true
    (Centl_sci_scope.in_scope "What is 0.1 plus 0.2?");
  Alcotest.(check bool)
    "program" true
    (Centl_sci_scope.in_scope
       "make a function called square that takes x and computes x^2")

let test_rejects_attack () =
  Alcotest.(check bool)
    "malware" false
    (Centl_sci_scope.in_scope "write malware to steal password");
  Alcotest.(check bool)
    "tokens" false
    (Centl_sci_scope.in_scope "save my github token in the workspace")

let () =
  Alcotest.run "CENTL-SCi scope"
    [
      ( "scope",
        [
          Alcotest.test_case "science allowed" `Quick test_allows_science;
          Alcotest.test_case "attacks refused" `Quick test_rejects_attack;
        ] );
    ]
