let () =
  match input_line stdin with
  | line ->
      let request = Yojson.Safe.from_string line in
      let response =
        `Assoc
          [
            ("status", `String "ok");
            ("echo", request);
            ("backend_claim", `String "this field is untrusted");
          ]
      in
      Yojson.Safe.to_channel stdout response;
      output_char stdout '\n';
      flush stdout
  | exception End_of_file -> exit 2
