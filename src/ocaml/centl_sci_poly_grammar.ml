(*
   Class-routed polynomial inference does not need arbitrary JSON strings.
   Keep the generated surface deliberately smaller than the general SCi
   grammar so known-invalid equation separators cannot be emitted inside
   left/right fields. The independent IR validator remains authoritative.
*)
let polynomial_equation_grammar =
  {|root ::= polynomial-equation
polynomial-equation ::= "{\"schema_version\":1,\"domain\":\"mathematics\",\"problem_class\":\"polynomial_equation\",\"operation\":\"solve\",\"assumptions\":[],\"left\":" equation-string ",\"relation\":\"equal\",\"right\":" equation-string ",\"variable\":" identifier-string "}"
equation-string ::= "\"" equation-char+ "\""
equation-char ::= [-+*/^()A-Za-z0-9_ .]
identifier-string ::= "\"" identifier "\""
identifier ::= [A-Za-z_] [A-Za-z0-9_]*
|}
