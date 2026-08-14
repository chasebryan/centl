type family =
  | Mathematics
  | Physics
  | Programming
  | Inspection
  | Contribution
  | Host_growth
  | Clarification

type verdict = Allowed of family | Rejected of string

let lower text = String.lowercase_ascii (String.trim text)

let contains needle text =
  Option.is_some (Centl_sci_interaction.find_substring ~needle (lower text))

let rejected_needles =
  [
    "child sexual";
    "child porn";
    "csam";
    "ransomware";
    "keylogger";
    "steal password";
    "dump credit card";
    "credit card numbers";
    "make a bomb";
    "build a bomb";
    "sql injection payload";
    "remote code exploit";
    "hack into";
    "hack their";
    "rm -rf /";
    "curl | sh";
    "curl|sh";
    "wget | bash";
    "wget|bash";
    "ignore previous instructions";
  ]

let classify text =
  let text = String.trim text in
  if text = "" then Allowed Clarification
  else if List.exists (fun needle -> contains needle text) rejected_needles then
    Rejected
      "That request is outside CENTL's scientific scope. I will not help with \
       illegal, abusive, or attack activity."
  else if
    contains "exploit this system" text
    || contains "write malware" text
    || contains "create malware" text
    || contains "write a virus" text
  then
    Rejected
      "I will not generate malware or attack tools. CENTL stays inside \
       mathematics, physics, local programming, and reviewed scientific \
       contribution."
  else if
    contains "store my token" text
    || contains "save my github token" text
    || contains "save my password" text
  then
    Rejected
      "CENTL will not store credentials, tokens, or passwords. Use `gh auth \
       login` yourself if you need GitHub."
  else Allowed Programming

let render = function Allowed _ -> None | Rejected message -> Some message

let in_scope text =
  match classify text with Allowed _ -> true | Rejected _ -> false
