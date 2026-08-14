type family = Linux | Macos | Windows | Other of string

let windows = Sys.win32

let darwin_marker = "/System/Library/CoreServices/SystemVersion.plist"

let family () =
  if windows then Windows
  else if Sys.file_exists darwin_marker then Macos
  else
    match String.lowercase_ascii Sys.os_type with
    | "unix" -> Linux
    | value -> Other value

let id = function
  | Linux -> "linux"
  | Macos -> "macos"
  | Windows -> "windows"
  | Other value -> value

let label = function
  | Linux -> "GNU/Linux"
  | Macos -> "macOS"
  | Windows -> "Windows"
  | Other value -> value

let current_id () = id (family ())

let current_label () = label (family ())

let exe_name name = if windows then name ^ ".exe" else name

let prebuilt_archive_id = function
  | Linux -> Some "linux"
  | Macos -> Some "macos"
  | Windows -> Some "windows"
  | Other _ -> None

let harbor = "CENTL Marsa"

let oasis_native_supported = function Linux -> true | _ -> false
