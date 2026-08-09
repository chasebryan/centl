let canonical text =
  match String.lowercase_ascii (String.trim text) with
  | "m" | "meter" | "meters" | "metre" | "metres" -> Some "m"
  | "cm" | "centimeter" | "centimeters" | "centimetre" | "centimetres" ->
      Some "cm"
  | "mm" | "millimeter" | "millimeters" | "millimetre" | "millimetres" ->
      Some "mm"
  | "km" | "kilometer" | "kilometers" | "kilometre" | "kilometres" -> Some "km"
  | "s" | "second" | "seconds" -> Some "s"
  | "ms" | "millisecond" | "milliseconds" -> Some "ms"
  | "min" | "minute" | "minutes" -> Some "min"
  | "h" | "hour" | "hours" -> Some "h"
  | "kg" | "kilogram" | "kilograms" -> Some "kg"
  | "g" | "gram" | "grams" -> Some "g"
  | "a" | "ampere" | "amperes" -> Some "A"
  | "k" | "kelvin" | "kelvins" -> Some "K"
  | "mol" | "mole" | "moles" -> Some "mol"
  | "cd" | "candela" | "candelas" -> Some "cd"
  | "m/s" | "meter per second" | "meters per second" | "metre per second"
  | "metres per second" ->
      Some "m/s"
  | "m/s^2" | "meter per second squared" | "meters per second squared"
  | "metre per second squared" | "metres per second squared" ->
      Some "m/s^2"
  | "n" | "newton" | "newtons" -> Some "N"
  | "j" | "joule" | "joules" -> Some "J"
  | "pa" | "pascal" | "pascals" -> Some "Pa"
  | "hz" | "hertz" -> Some "Hz"
  | "c" | "coulomb" | "coulombs" -> Some "C"
  | "w" | "watt" | "watts" -> Some "W"
  | "v" | "volt" | "volts" -> Some "V"
  | _ -> None

let canonical_or_original text =
  match canonical text with Some value -> value | None -> String.trim text

let mentions_known_unit text =
  let lowered = String.lowercase_ascii text in
  let separators = [ ' '; '\t'; '\n'; ','; '.'; '?'; '!'; ':'; ';'; '('; ')' ] in
  let is_separator character = List.mem character separators in
  let buffer = Buffer.create (String.length lowered) in
  String.iter
    (fun character -> Buffer.add_char buffer (if is_separator character then ' ' else character))
    lowered;
  Buffer.contents buffer |> String.split_on_char ' '
  |> List.exists (fun token -> token <> "" && Option.is_some (canonical token))
