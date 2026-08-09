let json_schema =
  {|{"oneOf":[{"type":"object","properties":{"schema_version":{"type":"integer","const":1},"domain":{"type":"string","enum":["mathematics"]},"problem_class":{"type":"string","enum":["exact_expression"]},"operation":{"type":"string","enum":["compute"]},"assumptions":{"type":"array","maxItems":16,"items":{"type":"string","maxLength":512}},"expression":{"type":"string","maxLength":4096}},"required":["schema_version","domain","problem_class","operation","assumptions","expression"],"additionalProperties":false},{"type":"object","properties":{"schema_version":{"type":"integer","const":1},"domain":{"type":"string","enum":["mathematics"]},"problem_class":{"type":"string","enum":["polynomial_equation"]},"operation":{"type":"string","enum":["solve"]},"assumptions":{"type":"array","maxItems":16,"items":{"type":"string","maxLength":512}},"left":{"type":"string","maxLength":4096},"relation":{"type":"string","enum":["equal"]},"right":{"type":"string","maxLength":4096},"variable":{"type":"string","maxLength":64}},"required":["schema_version","domain","problem_class","operation","assumptions","left","relation","right","variable"],"additionalProperties":false},{"type":"object","properties":{"schema_version":{"type":"integer","const":1},"domain":{"type":"string","enum":["physics"]},"problem_class":{"type":"string","enum":["unit_conversion"]},"operation":{"type":"string","enum":["convert"]},"assumptions":{"type":"array","maxItems":16,"items":{"type":"string","maxLength":512}},"value":{"type":"string","maxLength":256},"from_unit":{"type":"string","maxLength":64},"to_unit":{"type":"string","maxLength":64}},"required":["schema_version","domain","problem_class","operation","assumptions","value","from_unit","to_unit"],"additionalProperties":false},{"type":"object","properties":{"schema_version":{"type":"integer","const":1},"domain":{"type":"string","enum":["unsupported"]},"problem_class":{"type":"string","enum":["unsupported"]},"operation":{"type":"string","enum":["unsupported"]},"assumptions":{"type":"array","maxItems":16,"items":{"type":"string","maxLength":512}},"reason":{"type":"string","maxLength":1024}},"required":["schema_version","domain","problem_class","operation","assumptions","reason"],"additionalProperties":false}]}|}

(*
   llama.cpp's JSON-Schema-to-GBNF converter is intentionally not part of the
   CENTL-SCi trust boundary. The runtime uses these small native GBNF grammars
   directly, then reparses and independently validates the resulting JSON
   against the stricter OCaml IR contract above.

   Generation is deliberately canonical and whitespace-free. Earlier grammar
   revisions admitted unbounded whitespace before/after the root object. The
   /completion server could therefore keep producing legal whitespace until
   n_predict was exhausted even after a complete IR had been generated.
*)
let grammar_rules =
  {|exact-expression ::= "{\"schema_version\":1,\"domain\":\"mathematics\",\"problem_class\":\"exact_expression\",\"operation\":\"compute\",\"assumptions\":" assumptions ",\"expression\":" string "}"
polynomial-equation ::= "{\"schema_version\":1,\"domain\":\"mathematics\",\"problem_class\":\"polynomial_equation\",\"operation\":\"solve\",\"assumptions\":" assumptions ",\"left\":" string ",\"relation\":\"equal\",\"right\":" string ",\"variable\":" string "}"
unit-conversion ::= "{\"schema_version\":1,\"domain\":\"physics\",\"problem_class\":\"unit_conversion\",\"operation\":\"convert\",\"assumptions\":" assumptions ",\"value\":" string ",\"from_unit\":" string ",\"to_unit\":" string "}"
unsupported ::= "{\"schema_version\":1,\"domain\":\"unsupported\",\"problem_class\":\"unsupported\",\"operation\":\"unsupported\",\"assumptions\":" assumptions ",\"reason\":" string "}"
assumptions ::= "[" (string ("," string)*)? "]"
string ::= "\"" char* "\""
char ::= [^"\\\x7F\x00-\x1F] | "\\" (["\\/bfnrt] | "u" hex hex hex hex)
hex ::= [0-9a-fA-F]
|}

let grammar root = "root ::= " ^ root ^ "\n" ^ grammar_rules
let llama_grammar = grammar "exact-expression | polynomial-equation | unit-conversion | unsupported"
let exact_expression_grammar = grammar "exact-expression"
let polynomial_equation_grammar = grammar "polynomial-equation"
let unit_conversion_grammar = grammar "unit-conversion"
let unsupported_grammar = grammar "unsupported"
