let json_schema =
  {|{
  "oneOf": [
    {
      "type": "object",
      "properties": {
        "schema_version": {"type": "integer", "const": 1},
        "domain": {"type": "string", "enum": ["mathematics"]},
        "problem_class": {"type": "string", "enum": ["exact_expression"]},
        "operation": {"type": "string", "enum": ["compute"]},
        "assumptions": {"type": "array", "maxItems": 16, "items": {"type": "string", "maxLength": 512}},
        "expression": {"type": "string", "maxLength": 4096}
      },
      "required": ["schema_version", "domain", "problem_class", "operation", "assumptions", "expression"],
      "additionalProperties": false
    },
    {
      "type": "object",
      "properties": {
        "schema_version": {"type": "integer", "const": 1},
        "domain": {"type": "string", "enum": ["mathematics"]},
        "problem_class": {"type": "string", "enum": ["polynomial_equation"]},
        "operation": {"type": "string", "enum": ["solve"]},
        "assumptions": {"type": "array", "maxItems": 16, "items": {"type": "string", "maxLength": 512}},
        "left": {"type": "string", "maxLength": 4096},
        "relation": {"type": "string", "enum": ["equal"]},
        "right": {"type": "string", "maxLength": 4096},
        "variable": {"type": "string", "maxLength": 64}
      },
      "required": ["schema_version", "domain", "problem_class", "operation", "assumptions", "left", "relation", "right", "variable"],
      "additionalProperties": false
    },
    {
      "type": "object",
      "properties": {
        "schema_version": {"type": "integer", "const": 1},
        "domain": {"type": "string", "enum": ["mathematics"]},
        "problem_class": {"type": "string", "enum": ["verification_claim"]},
        "operation": {"type": "string", "enum": ["verify"]},
        "assumptions": {"type": "array", "maxItems": 0},
        "left": {"type": "string", "maxLength": 4096},
        "relation": {"type": "string", "enum": ["equal", "not_equal", "less_than", "less_or_equal", "greater_than", "greater_or_equal"]},
        "right": {"type": "string", "maxLength": 4096}
      },
      "required": ["schema_version", "domain", "problem_class", "operation", "assumptions", "left", "relation", "right"],
      "additionalProperties": false
    },
    {
      "type": "object",
      "properties": {
        "schema_version": {"type": "integer", "const": 1},
        "domain": {"type": "string", "enum": ["physics"]},
        "problem_class": {"type": "string", "enum": ["unit_conversion"]},
        "operation": {"type": "string", "enum": ["convert"]},
        "assumptions": {"type": "array", "maxItems": 16, "items": {"type": "string", "maxLength": 512}},
        "value": {"type": "string", "maxLength": 256},
        "from_unit": {"type": "string", "maxLength": 64},
        "to_unit": {"type": "string", "maxLength": 64}
      },
      "required": ["schema_version", "domain", "problem_class", "operation", "assumptions", "value", "from_unit", "to_unit"],
      "additionalProperties": false
    },
    {
      "type": "object",
      "properties": {
        "schema_version": {"type": "integer", "const": 1},
        "domain": {"type": "string", "enum": ["physics"]},
        "problem_class": {"type": "string", "enum": ["physical_constant"]},
        "operation": {"type": "string", "enum": ["constant"]},
        "assumptions": {"type": "array", "maxItems": 16, "items": {"type": "string", "maxLength": 512}},
        "symbol": {"type": "string", "enum": ["c", "h", "e", "k_B", "N_A", "g0"]}
      },
      "required": ["schema_version", "domain", "problem_class", "operation", "assumptions", "symbol"],
      "additionalProperties": false
    },
    {
      "type": "object",
      "properties": {
        "schema_version": {"type": "integer", "const": 1},
        "domain": {"type": "string", "enum": ["physics"]},
        "problem_class": {"type": "string", "enum": ["uniform_gravity_particle"]},
        "operation": {"type": "string", "enum": ["simulate"]},
        "assumptions": {"type": "array", "maxItems": 16, "items": {"type": "string", "maxLength": 512}},
        "mass_value": {"type": "string", "maxLength": 256},
        "mass_unit": {"type": "string", "maxLength": 64},
        "position_x": {"type": "string", "maxLength": 256},
        "position_y": {"type": "string", "maxLength": 256},
        "position_z": {"type": "string", "maxLength": 256},
        "position_unit": {"type": "string", "maxLength": 64},
        "velocity_x": {"type": "string", "maxLength": 256},
        "velocity_y": {"type": "string", "maxLength": 256},
        "velocity_z": {"type": "string", "maxLength": 256},
        "velocity_unit": {"type": "string", "maxLength": 64},
        "gravity_x": {"type": "string", "maxLength": 256},
        "gravity_y": {"type": "string", "maxLength": 256},
        "gravity_z": {"type": "string", "maxLength": 256},
        "gravity_unit": {"type": "string", "maxLength": 64},
        "dt_value": {"type": "string", "maxLength": 256},
        "dt_unit": {"type": "string", "maxLength": 64},
        "steps": {"type": "integer", "minimum": 1, "maximum": 100000}
      },
      "required": ["schema_version", "domain", "problem_class", "operation", "assumptions", "mass_value", "mass_unit", "position_x", "position_y", "position_z", "position_unit", "velocity_x", "velocity_y", "velocity_z", "velocity_unit", "gravity_x", "gravity_y", "gravity_z", "gravity_unit", "dt_value", "dt_unit", "steps"],
      "additionalProperties": false
    },
    {
      "type": "object",
      "properties": {
        "schema_version": {"type": "integer", "const": 1},
        "domain": {"type": "string", "enum": ["unsupported"]},
        "problem_class": {"type": "string", "enum": ["unsupported"]},
        "operation": {"type": "string", "enum": ["unsupported"]},
        "assumptions": {"type": "array", "maxItems": 16, "items": {"type": "string", "maxLength": 512}},
        "reason": {"type": "string", "maxLength": 1024}
      },
      "required": ["schema_version", "domain", "problem_class", "operation", "assumptions", "reason"],
      "additionalProperties": false
    }
  ]
}|}

(*
   llama.cpp's JSON-Schema-to-GBNF converter is intentionally not part of the
   CENTL-SCi trust boundary. The runtime uses these small native GBNF grammars
   directly, then reparses and independently validates the resulting JSON
   against the stricter OCaml IR contract above.

   Verification claims are intentionally absent from the model grammar for the
   current Caramels slice. Supported closed verification phrasing is handled by
   Tier-0 deterministic interpretation and lowered directly to the read-only
   CENTL verification protocol. The canonical JSON schema still includes the
   typed class so structured IR remains self-consistent.
*)
let grammar_rules =
  {|exact-expression ::= "{\"schema_version\":1,\"domain\":\"mathematics\",\"problem_class\":\"exact_expression\",\"operation\":\"compute\",\"assumptions\":" assumptions ",\"expression\":" string "}"
polynomial-equation ::= "{\"schema_version\":1,\"domain\":\"mathematics\",\"problem_class\":\"polynomial_equation\",\"operation\":\"solve\",\"assumptions\":" assumptions ",\"left\":" string ",\"relation\":\"equal\",\"right\":" string ",\"variable\":" string "}"
unit-conversion ::= "{\"schema_version\":1,\"domain\":\"physics\",\"problem_class\":\"unit_conversion\",\"operation\":\"convert\",\"assumptions\":" assumptions ",\"value\":" string ",\"from_unit\":" string ",\"to_unit\":" string "}"
physical-constant ::= "{\"schema_version\":1,\"domain\":\"physics\",\"problem_class\":\"physical_constant\",\"operation\":\"constant\",\"assumptions\":" assumptions ",\"symbol\":" constant-symbol "}"
uniform-gravity-particle ::= "{\"schema_version\":1,\"domain\":\"physics\",\"problem_class\":\"uniform_gravity_particle\",\"operation\":\"simulate\",\"assumptions\":" assumptions ",\"mass_value\":" string ",\"mass_unit\":" string ",\"position_x\":" string ",\"position_y\":" string ",\"position_z\":" string ",\"position_unit\":" string ",\"velocity_x\":" string ",\"velocity_y\":" string ",\"velocity_z\":" string ",\"velocity_unit\":" string ",\"gravity_x\":" string ",\"gravity_y\":" string ",\"gravity_z\":" string ",\"gravity_unit\":" string ",\"dt_value\":" string ",\"dt_unit\":" string ",\"steps\":" positive-integer "}"
unsupported ::= "{\"schema_version\":1,\"domain\":\"unsupported\",\"problem_class\":\"unsupported\",\"operation\":\"unsupported\",\"assumptions\":" assumptions ",\"reason\":" string "}"
constant-symbol ::= "\"c\"" | "\"h\"" | "\"e\"" | "\"k_B\"" | "\"N_A\"" | "\"g0\""
positive-integer ::= [1-9] [0-9]*
assumptions ::= "[" (string ("," string)*)? "]"
string ::= "\"" char* "\""
char ::= [^"\\\x7F\x00-\x1F] | "\\" (["\\/bfnrt] | "u" hex hex hex hex)
hex ::= [0-9a-fA-F]
|}

let grammar root = "root ::= " ^ root ^ "\n" ^ grammar_rules

let llama_grammar =
  grammar
    "exact-expression | polynomial-equation | unit-conversion | physical-constant | uniform-gravity-particle | unsupported"

let exact_expression_grammar = grammar "exact-expression"
let polynomial_equation_grammar = grammar "polynomial-equation"
let unit_conversion_grammar = grammar "unit-conversion"
let physical_constant_grammar = grammar "physical-constant"
let uniform_gravity_particle_grammar = grammar "uniform-gravity-particle"
let unsupported_grammar = grammar "unsupported"
