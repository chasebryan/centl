let json_schema =
  {|{"oneOf":[{"type":"object","properties":{"schema_version":{"type":"integer","const":1},"domain":{"type":"string","enum":["mathematics"]},"problem_class":{"type":"string","enum":["exact_expression"]},"operation":{"type":"string","enum":["compute"]},"assumptions":{"type":"array","maxItems":16,"items":{"type":"string","maxLength":512}},"expression":{"type":"string","maxLength":4096}},"required":["schema_version","domain","problem_class","operation","assumptions","expression"],"additionalProperties":false},{"type":"object","properties":{"schema_version":{"type":"integer","const":1},"domain":{"type":"string","enum":["mathematics"]},"problem_class":{"type":"string","enum":["polynomial_equation"]},"operation":{"type":"string","enum":["solve"]},"assumptions":{"type":"array","maxItems":16,"items":{"type":"string","maxLength":512}},"left":{"type":"string","maxLength":4096},"relation":{"type":"string","enum":["equal"]},"right":{"type":"string","maxLength":4096},"variable":{"type":"string","maxLength":64}},"required":["schema_version","domain","problem_class","operation","assumptions","left","relation","right","variable"],"additionalProperties":false},{"type":"object","properties":{"schema_version":{"type":"integer","const":1},"domain":{"type":"string","enum":["physics"]},"problem_class":{"type":"string","enum":["unit_conversion"]},"operation":{"type":"string","enum":["convert"]},"assumptions":{"type":"array","maxItems":16,"items":{"type":"string","maxLength":512}},"value":{"type":"string","maxLength":256},"from_unit":{"type":"string","maxLength":64},"to_unit":{"type":"string","maxLength":64}},"required":["schema_version","domain","problem_class","operation","assumptions","value","from_unit","to_unit"],"additionalProperties":false},{"type":"object","properties":{"schema_version":{"type":"integer","const":1},"domain":{"type":"string","enum":["unsupported"]},"problem_class":{"type":"string","enum":["unsupported"]},"operation":{"type":"string","enum":["unsupported"]},"assumptions":{"type":"array","maxItems":16,"items":{"type":"string","maxLength":512}},"reason":{"type":"string","maxLength":1024}},"required":["schema_version","domain","problem_class","operation","assumptions","reason"],"additionalProperties":false}]}|}

(*
   llama.cpp's JSON-Schema-to-GBNF converter is intentionally not part of the
   CENTL-SCi trust boundary.  The runtime uses this small native GBNF grammar
   directly, then reparses and independently validates the resulting JSON
   against the stricter OCaml IR contract above.  Fixed property order keeps
   the generation grammar small and deterministic without changing what the
   IR validator accepts.
*)
let llama_grammar =
  {|root ::= ws (exact-expression | polynomial-equation | unit-conversion | unsupported) ws
exact-expression ::= "{" ws "\"schema_version\"" ws ":" ws "1" ws "," ws "\"domain\"" ws ":" ws "\"mathematics\"" ws "," ws "\"problem_class\"" ws ":" ws "\"exact_expression\"" ws "," ws "\"operation\"" ws ":" ws "\"compute\"" ws "," ws "\"assumptions\"" ws ":" ws assumptions ws "," ws "\"expression\"" ws ":" ws string ws "}"
polynomial-equation ::= "{" ws "\"schema_version\"" ws ":" ws "1" ws "," ws "\"domain\"" ws ":" ws "\"mathematics\"" ws "," ws "\"problem_class\"" ws ":" ws "\"polynomial_equation\"" ws "," ws "\"operation\"" ws ":" ws "\"solve\"" ws "," ws "\"assumptions\"" ws ":" ws assumptions ws "," ws "\"left\"" ws ":" ws string ws "," ws "\"relation\"" ws ":" ws "\"equal\"" ws "," ws "\"right\"" ws ":" ws string ws "," ws "\"variable\"" ws ":" ws string ws "}"
unit-conversion ::= "{" ws "\"schema_version\"" ws ":" ws "1" ws "," ws "\"domain\"" ws ":" ws "\"physics\"" ws "," ws "\"problem_class\"" ws ":" ws "\"unit_conversion\"" ws "," ws "\"operation\"" ws ":" ws "\"convert\"" ws "," ws "\"assumptions\"" ws ":" ws assumptions ws "," ws "\"value\"" ws ":" ws string ws "," ws "\"from_unit\"" ws ":" ws string ws "," ws "\"to_unit\"" ws ":" ws string ws "}"
unsupported ::= "{" ws "\"schema_version\"" ws ":" ws "1" ws "," ws "\"domain\"" ws ":" ws "\"unsupported\"" ws "," ws "\"problem_class\"" ws ":" ws "\"unsupported\"" ws "," ws "\"operation\"" ws ":" ws "\"unsupported\"" ws "," ws "\"assumptions\"" ws ":" ws assumptions ws "," ws "\"reason\"" ws ":" ws string ws "}"
assumptions ::= "[" ws (string (ws "," ws string)*)? ws "]"
string ::= "\"" char* "\""
char ::= [^"\\\x7F\x00-\x1F] | "\\" (["\\/bfnrt] | "u" hex hex hex hex)
hex ::= [0-9a-fA-F]
ws ::= [ \t\n]*
|}
