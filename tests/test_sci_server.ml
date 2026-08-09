let assoc name = function
  | `Assoc fields ->
      begin match List.assoc_opt name fields with
      | Some value -> value
      | None -> Alcotest.fail ("missing JSON field " ^ name)
      end
  | _ -> Alcotest.fail "expected JSON object"

let string name json =
  match assoc name json with
  | `String value -> value
  | _ -> Alcotest.fail ("expected string field " ^ name)

let bool name json =
  match assoc name json with
  | `Bool value -> value
  | _ -> Alcotest.fail ("expected bool field " ^ name)

let int name json =
  match assoc name json with
  | `Int value -> value
  | _ -> Alcotest.fail ("expected int field " ^ name)

let fake_curl () =
  match Sys.getenv_opt "CENTL_SCI_FAKE_CURL" with
  | Some value when value <> "" -> value
  | _ -> Alcotest.fail "CENTL_SCI_FAKE_CURL is not configured"

let test_loopback_only () =
  let good = Centl_sci_server.default ~base_url:"http://127.0.0.1:8080" () in
  let bad = Centl_sci_server.default ~base_url:"https://example.com:8080" () in
  begin match Centl_sci_server.validate_config good with
  | Ok () -> ()
  | Error error -> Alcotest.fail (Centl_sci_server.string_of_error error)
  end;
  match Centl_sci_server.validate_config bad with
  | Error _ -> ()
  | Ok () -> Alcotest.fail "resident adapter must reject non-loopback URLs"

let test_request_contract () =
  let problem = "Solve x squared minus 5 x plus 6 equals zero for x." in
  let config = Centl_sci_server.default ~base_url:"http://localhost:8080/" () in
  let request = Centl_sci_server.request_json config problem in
  Alcotest.(check bool) "cache prompt" true (bool "cache_prompt" request);
  Alcotest.(check int) "bounded generation" 192 (int "n_predict" request);
  Alcotest.(check string)
    "class grammar" Centl_sci_schema.polynomial_equation_grammar
    (string "grammar" request);
  let prompt = string "prompt" request in
  Alcotest.(check bool)
    "compact resident prompt" true
    (String.length prompt < 1_024);
  Alcotest.(check bool)
    "class is fixed" true
    (String.starts_with ~prefix:"CENTL-SCi v0.0.1" prompt
    && String.contains prompt 'p');
  Alcotest.(check bool)
    "problem encoded as data" true
    (String.ends_with ~suffix:(Yojson.Safe.to_string (`String problem)) prompt);
  let arguments = Centl_sci_server.argv config problem |> Array.to_list in
  Alcotest.(check bool) "proxy bypass" true (List.mem "--noproxy" arguments);
  Alcotest.(check string)
    "endpoint" "http://localhost:8080/completion"
    (Centl_sci_server.endpoint config)

let test_end_to_end_fake_server () =
  let config =
    Centl_sci_server.default ~curl_executable:(fake_curl ())
      ~base_url:"http://127.0.0.1:8080" ()
  in
  let ir =
    match Centl_sci_server.interpret config "What is 0.1 plus 0.2?" with
    | Ok value -> value
    | Error error -> Alcotest.fail (Centl_sci_server.string_of_error error)
  in
  let outcome = Centl_sci_runtime.execute ir in
  Alcotest.(check string)
    "status" "established"
    (Centl_sci_runtime.status_text outcome.status);
  match outcome.Centl_sci_runtime.response with
  | Some response ->
      let value = assoc "value" response in
      Alcotest.(check string) "exact result" "3/10" (string "text" value)
  | None -> Alcotest.fail "expected CENTL response"

let () =
  Alcotest.run "centl-sci-server"
    [
      ( "server",
        [
          Alcotest.test_case "loopback only" `Quick test_loopback_only;
          Alcotest.test_case "request contract" `Quick test_request_contract;
          Alcotest.test_case "fake resident inference" `Quick
            test_end_to_end_fake_server;
        ] );
    ]
