let contains ~needle text =
  let needle_length = String.length needle in
  let rec loop index =
    if needle_length = 0 then true
    else if index + needle_length > String.length text then false
    else if String.sub text index needle_length = needle then true
    else loop (index + 1)
  in
  loop 0

let read_file path =
  let channel = open_in_bin path in
  let length = in_channel_length channel in
  let text = really_input_string channel length in
  close_in channel;
  text

let make_temp_dir () =
  let path = Filename.temp_file "centl-sci-contrib" "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  path

let require_ok = function
  | Ok () -> ()
  | Error error -> Alcotest.fail (Centl_sci_contrib.string_of_error error)

let exact_outcome () =
  let ir =
    match
      Centl_sci_ir.of_json
        (`Assoc
          [
            ("schema_version", `Int 1);
            ("domain", `String "mathematics");
            ("problem_class", `String "exact_expression");
            ("operation", `String "compute");
            ("assumptions", `List []);
            ("expression", `String "0.1 + 0.2");
          ])
    with
    | Ok value -> value
    | Error error -> Alcotest.fail (Centl_sci_ir.string_of_error error)
  in
  (ir, Centl_sci_runtime.execute ir)

let setup () =
  let root = make_temp_dir () in
  Unix.putenv "XDG_CONFIG_HOME" (Filename.concat root "config");
  Unix.putenv "XDG_STATE_HOME" (Filename.concat root "state");
  root

let test_default_off () =
  ignore (setup ());
  Alcotest.(check string)
    "default mode" "off"
    (Centl_sci_contrib.mode_text (Centl_sci_contrib.load_mode ()))

let test_diagnostics_excludes_problem () =
  ignore (setup ());
  require_ok (Centl_sci_contrib.set_mode Centl_sci_contrib.Diagnostics);
  let ir, outcome = exact_outcome () in
  let problem = "PRIVATE-MARKER-829104: What is 0.1 plus 0.2?" in
  require_ok
    (Centl_sci_contrib.record ~source:"fast" ~problem ~ir ~outcome ());
  let path = Option.get (Centl_sci_contrib.pending_path ()) in
  let text = read_file path in
  Alcotest.(check bool)
    "diagnostics omit raw problem" false
    (contains ~needle:"PRIVATE-MARKER-829104" text);
  Alcotest.(check bool)
    "diagnostics identify mode" true
    (contains ~needle:"\"capture_mode\":\"diagnostics\"" text)

let test_examples_include_problem_locally () =
  ignore (setup ());
  require_ok (Centl_sci_contrib.set_mode Centl_sci_contrib.Examples);
  let ir, outcome = exact_outcome () in
  let problem = "EXAMPLE-MARKER-173205: What is 0.1 plus 0.2?" in
  require_ok
    (Centl_sci_contrib.record ~source:"fast" ~problem ~ir ~outcome ());
  let path = Option.get (Centl_sci_contrib.pending_path ()) in
  let text = read_file path in
  Alcotest.(check bool)
    "examples include explicitly opted-in problem" true
    (contains ~needle:"EXAMPLE-MARKER-173205" text);
  Alcotest.(check bool)
    "capture is local only" true
    (contains ~needle:"\"network_upload\":false" text)

let test_export_and_clear () =
  let root = setup () in
  require_ok (Centl_sci_contrib.set_mode Centl_sci_contrib.Diagnostics);
  let ir, outcome = exact_outcome () in
  require_ok
    (Centl_sci_contrib.record ~source:"fast" ~problem:"1 + 1" ~ir ~outcome ());
  let destination = Filename.concat root "review/export.jsonl" in
  require_ok (Centl_sci_contrib.export_pending destination);
  Alcotest.(check bool) "export exists" true (Sys.file_exists destination);
  require_ok (Centl_sci_contrib.clear_pending ());
  let pending = Option.get (Centl_sci_contrib.pending_path ()) in
  Alcotest.(check bool) "pending data cleared" false (Sys.file_exists pending)

let () =
  Alcotest.run "centl-sci-contrib"
    [
      ( "privacy",
        [
          Alcotest.test_case "default off" `Quick test_default_off;
          Alcotest.test_case "diagnostics excludes problem" `Quick
            test_diagnostics_excludes_problem;
          Alcotest.test_case "examples include problem locally" `Quick
            test_examples_include_problem_locally;
          Alcotest.test_case "export and clear" `Quick test_export_and_clear;
        ] );
    ]
