let require_adapter () =
  match Sys.getenv_opt "CENTL_SCI_FAKE_EXTERNAL_ADAPTER" with
  | Some path -> path
  | None -> Alcotest.fail "CENTL_SCI_FAKE_EXTERNAL_ADAPTER is not configured"

let test_round_trip () =
  let program = require_adapter () in
  let request = `Assoc [ ("operation", `String "probe"); ("value", `Int 7) ] in
  match Centl_sci_external.invoke ~program ~argv:[] request with
  | Error error -> Alcotest.fail (Centl_sci_external.error_text error)
  | Ok invocation ->
      Alcotest.(check string) "runtime assurance" "external_backend"
        invocation.assurance;
      Alcotest.(check string) "program identity" program invocation.program;
      (match invocation.response with
      | `Assoc fields ->
          Alcotest.(check (option string)) "status" (Some "ok")
            (match List.assoc_opt "status" fields with
            | Some (`String value) -> Some value
            | _ -> None);
          Alcotest.(check bool) "request echoed" true
            (List.assoc_opt "echo" fields = Some request)
      | _ -> Alcotest.fail "external adapter response was not an object")

let test_request_limit () =
  let program = require_adapter () in
  let request = `Assoc [ ("payload", `String (String.make 32 'x')) ] in
  match
    Centl_sci_external.invoke ~max_request_bytes:8 ~program ~argv:[] request
  with
  | Error (Centl_sci_external.Request_too_large _) -> ()
  | Error error -> Alcotest.fail (Centl_sci_external.error_text error)
  | Ok _ ->
      Alcotest.fail "oversized request unexpectedly reached external adapter"

let () =
  Alcotest.run "CENTL-SCi external boundary"
    [
      ( "jsonl",
        [
          Alcotest.test_case "round trip preserves external assurance" `Quick
            test_round_trip;
          Alcotest.test_case "request size is bounded before spawn" `Quick
            test_request_limit;
        ] );
    ]
