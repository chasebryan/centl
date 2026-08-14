open Alcotest

let family_is_known () =
  match Centl_platform.family () with
  | Centl_platform.Linux | Centl_platform.Macos | Centl_platform.Windows
  | Centl_platform.Other _ ->
      ()

let linux_is_the_oasis_native () =
  check bool "linux oasis" true
    (Centl_platform.oasis_native_supported Centl_platform.Linux);
  check bool "macos oasis" false
    (Centl_platform.oasis_native_supported Centl_platform.Macos);
  check bool "windows oasis" false
    (Centl_platform.oasis_native_supported Centl_platform.Windows)

let ids_are_stable () =
  check string "linux" "linux" (Centl_platform.id Centl_platform.Linux);
  check string "macos" "macos" (Centl_platform.id Centl_platform.Macos);
  check string "windows" "windows" (Centl_platform.id Centl_platform.Windows)

let home_prefers_home_then_profile () =
  match Centl_platform.home_directory () with
  | Some path -> check bool "home path" true (String.trim path <> "")
  | None -> ()

let () =
  run "CENTL platform"
    [
      ( "family",
        [
          test_case "known" `Quick family_is_known;
          test_case "oasis native" `Quick linux_is_the_oasis_native;
          test_case "ids" `Quick ids_are_stable;
          test_case "home" `Quick home_prefers_home_then_profile;
        ] );
    ]
