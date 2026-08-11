let test_known_vectors () =
  Alcotest.(check string)
    "empty" "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    (Centl_sha256.hex_string "");
  Alcotest.(check string)
    "abc" "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    (Centl_sha256.hex_string "abc");
  Alcotest.(check string)
    "multi-block"
    "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"
    (Centl_sha256.hex_string
       "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")

let () =
  Alcotest.run "CENTL SHA-256"
    [
      ( "vectors",
        [ Alcotest.test_case "known SHA-256 vectors" `Quick test_known_vectors ]
      );
    ]
