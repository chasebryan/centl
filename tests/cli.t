  $ ../src/main.exe '0.1 + 0.2'
  3/10

  $ ../src/main.exe '1/3 + 1/6'
  1/2

  $ ../src/main.exe 'diff(x^3 + 2*x + 1, x)'
  3 * x^2 + 2

  $ ../src/main.exe 'integrate(3*x^2 + 2*x + 1, x)'
  x^3 + x^2 + x

  $ ../src/main.exe 'integrate(x^2, x = 0, 3)'
  9

  $ ../src/main.exe 'integrate(x^2, x = 0, 1/2)'
  1/24

  $ ../src/main.exe 'integrate(x^2, x = 3, 0)'
  -9

  $ ../src/main.exe 'diff(integrate(3*x^2 + 2*x + 1, x), x)'
  3 * x^2 + 2 * x + 1

  $ ../src/main.exe 'integrate(sin(x), x)'
  integrate(sin(x), x)
  resolution: unsupported (operation=integrate; reason=non_polynomial_integrand; supported_domain=rational-coefficient univariate polynomials with exact rational bounds)

  $ ../src/main.exe 'integrate(1/x, x)'
  integrate(1 / x, x)
  resolution: unsupported (operation=integrate; reason=non_polynomial_integrand; supported_domain=rational-coefficient univariate polynomials with exact rational bounds)

  $ ../src/main.exe 'integrate(x^2, x = 0, a)'
  integrate(x^2, x = 0, a)
  resolution: unsupported (operation=integrate; reason=non_rational_bounds; supported_domain=rational-coefficient univariate polynomials with exact rational bounds)

  $ ../src/main.exe 'substitute(x^2 + 1, x = 3)'
  10

  $ ../src/main.exe 'simplify(2*x + 3*x)'
  5 * x

  $ ../src/main.exe 'expand((x + 1)^3)'
  x^3 + 3 * x^2 + 3 * x + 1

  $ ../src/main.exe 'factor(x^2 - 1)'
  (x - 1) * (x + 1)

  $ ../src/main.exe 'solve(2*x + 3 = 11, x)'
  x = 4

  $ ../src/main.exe 'solve(x^2 - 5*x + 6 = 0, x)'
  x in {2, 3}

  $ ../src/main.exe 'solve(x^2 + 1 = 0, x)'
  no solutions

  $ ../src/main.exe 'solve(x^2 = 2, x)'
  x in {-sqrt(2), sqrt(2)}

  $ ../src/main.exe 'assuming(x / x, x != 0)'
  1 where x != 0

  $ ../src/main.exe 'distance(0, 0, 3, 4)'
  5

  $ ../src/main.exe 'circle_area(3)'
  9 * pi

  $ ../src/main.exe 'choose(52, 5)'
  2598960

  $ ../src/main.exe 'sum(k^2, k = 1, 100)'
  338350

  $ ../src/main.exe 'product((k + 1)/k, k = 1, 10)'
  11

  $ ../src/main.exe 'sum(sum(i*j, j = 1, i), i = 1, 4)'
  65

  $ ../src/main.exe 'substitute(sum(k*x, k = 1, 4), x = 3)'
  30

  $ ../src/main.exe 'substitute(sum(x, k = 1, 3), x = k)'
  k + k + k

  $ ../src/main.exe 'substitute(sum(x + k, k = 1, 2), x = k)'
  k + 1 + k + 2

  $ ../src/main.exe 'substitute(substitute(sum(x, k = 1, 3), x = k), k = 4)'
  12

  $ ../src/main.exe 'sum(k^100, k = 1, 0)'
  0

  $ ../src/main.exe 'product(1/0, k = 1, 0)'
  1

  $ printf '%s\n' 'k = 10' 'sum(k, k = k - 1, k + 1)' 'k' | ../src/main.exe | tail -n 2
  30
  10

  $ printf '%s\n' 'triangular(n) = sum(k, k = 1, n)' 'triangular(10)' | ../src/main.exe | tail -n 1
  55

  $ printf '%s\n' 'repeat(x) = sum(x, k = 1, 3)' 'repeat(k)' | ../src/main.exe | tail -n 1
  k + k + k

  $ printf '%s\n' 'x = 4' 'integrate(x, x = 0, x)' | ../src/main.exe | tail -n 1
  8

  $ printf '%s\n' 'integrated_scale(scale) = integrate(scale*x, x = 0, 1)' 'integrated_scale(6)' | ../src/main.exe | tail -n 1
  3

  $ printf '%s\n' 'held(value) = integrate(value, x)' 'held(x)' | ../src/main.exe | tail -n 1
  resolution: unsupported (operation=integrate; reason=non_polynomial_integrand; supported_domain=rational-coefficient univariate polynomials with exact rational bounds)

  $ ../src/main.exe 'approx(sqrt(2), 12)'
  ≈ [1.41421356237, 1.41421356238]

  $ ../src/main.exe --version
  centl 0.11.0

  $ ../src/main.exe --syntax | sed -n '1,4p'
  CENTL syntax
  values: integer decimal fraction variable () pi e tau
  arithmetic: + - * / ^
  symbolic math: f(...) name= f(...)= solve diff integrate substitute simplify expand factor assuming = != < <= > >=

  $ ../src/main.exe --help | sed -n '1p;3p;5,12p'
  CENTL - exact mathematics, directly.
  Usage: centl [options] [EXPRESSION] | centl verify ... | centl check FILE
    centl EXPRESSION   calculate
    centl              open the calculator
    --file PATH        run a script
    --syntax           list mathematical identifiers
    --json [EXPR]      use the JSON interface
    --serve            persistent stateful JSON Lines
    --mcp              MCP server over standard I/O
    --no-history       do not load or save durable history

  $ ../src/main.exe --color=always 'x + 1' | sed "s/$(printf '\033')/<ESC>/g"
  <ESC>[95mx<ESC>[0m<ESC>[93m + <ESC>[0m<ESC>[96m1<ESC>[0m

  $ ../src/main.exe --json '1 / 8'
  {"version":1,"ok":true,"value":{"kind":"rational","exact":true,"numerator":"1","denominator":"8","text":"1/8"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"}}

  $ ../src/main.exe --json 'integrate(x^2, x = 0, 1)'
  {"version":1,"ok":true,"value":{"kind":"rational","exact":true,"numerator":"1","denominator":"3","text":"1/3"},"resolution":{"status":"transformed","operation":"integrate","supported_domain":"rational-coefficient univariate polynomials with exact rational bounds"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"}}

  $ ../src/main.exe --json 'sum(k, k = 1, 10)'
  {"version":1,"ok":true,"value":{"kind":"integer","exact":true,"value":"55","text":"55"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"}}

  $ ../src/main.exe --json 'diff(sin(x), x)'
  {"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"cos(x)","text":"cos(x)"},"resolution":{"status":"transformed","operation":"diff","supported_domain":"the documented exact symbolic differentiation rules"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"}}

  $ ../src/main.exe --json 'assuming(x / x, x != 0)'
  {"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"1 where x != 0","text":"1 where x != 0","conditions":[{"left":"x","relation":"not_equal","right":"0","text":"x != 0"}]},"resolution":{"status":"transformed","operation":"assuming","supported_domain":"exact expressions with retained conditions"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"}}

  $ ../src/main.exe --json 'solve(x^2 - 1 = 0, x)'
  {"version":1,"ok":true,"value":{"kind":"solution_set","exact":true,"resolved":true,"status":"finite","variable":"x","solutions":[{"numerator":"-1","denominator":"1","text":"-1"},{"numerator":"1","denominator":"1","text":"1"}],"equation":{"left":"x^2 - 1","right":"0"},"text":"x in {-1, 1}"},"resolution":{"status":"transformed","operation":"solve","supported_domain":"linear and real quadratic equations with rational coefficients"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact_solution_set","method":"equation_solving","backend":"centl-exact"}}

  $ ../src/main.exe --json 'solve(x^2 = 2, x)'
  {"version":1,"ok":true,"value":{"kind":"solution_set","exact":true,"resolved":true,"status":"finite","variable":"x","solutions":[{"kind":"real_quadratic","exact":true,"branch":"lower","center":{"numerator":"0","denominator":"1"},"radicand":{"numerator":"2","denominator":"1"},"text":"-sqrt(2)"},{"kind":"real_quadratic","exact":true,"branch":"upper","center":{"numerator":"0","denominator":"1"},"radicand":{"numerator":"2","denominator":"1"},"text":"sqrt(2)"}],"equation":{"left":"x^2","right":"2"},"text":"x in {-sqrt(2), sqrt(2)}"},"resolution":{"status":"transformed","operation":"solve","supported_domain":"linear and real quadratic equations with rational coefficients"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact_solution_set","method":"verified_quadratic_solving","backend":"centl-core"}}

  $ printf '{"version":1,"expression":"2 * (3 + 4)"}\n' | ../src/main.exe --json
  {"version":1,"ok":true,"value":{"kind":"integer","exact":true,"value":"14","text":"14"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"}}

  $ printf '{"version":1,"id":"one-shot","op":"evaluate","expression":"1 + 1"}\n' | ../src/main.exe --json
  {"version":1,"id":"one-shot","ok":true,"value":{"kind":"integer","exact":true,"value":"2","text":"2"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"}}

  $ { awk 'BEGIN { for (i = 0; i < 65537; i++) printf "x"; print "" }'; printf '{"version":1,"expression":"1 + 1"}\n'; } | ../src/main.exe --json
  {"version":1,"ok":false,"error":{"details":{"category":"limit","limit":"max_request_bytes"},"suggestion":"Reduce the request or retry with a larger permitted request limit.","code":"resource_limit","message":"the request exceeds the byte limit","retryable":true},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"}}
  {"version":1,"ok":true,"value":{"kind":"integer","exact":true,"value":"2","text":"2"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"}}
  [2]

  $ printf '{"version":1,"expression":"sequence(k, k = 1, 4)","limits":{"max_integer_iterations":3}}\n' | ../src/main.exe --json
  {"version":1,"ok":false,"error":{"details":{"category":"limit","limit":"max_integer_iterations"},"suggestion":"Reduce the request or retry with a larger permitted request limit.","position":0,"range":{"start":0,"end":0},"code":"resource_limit","message":"the finite sequence exceeds the integer-iteration limit","retryable":true},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"}}
  [2]

  $ printf '%s\n' '{"version":1,"id":"a","expression":"r = 3"}' '{"version":1,"id":"b","expression":"circle_area(r)"}' '{"version":1,"id":"c","op":"reset"}' | ../src/main.exe --serve
  {"version":1,"id":"a","ok":true,"value":{"kind":"definition","exact":true,"definition_kind":"value","name":"r","value":{"kind":"integer","exact":true,"value":"3","text":"3"},"text":"r = 3"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact_definition","method":"session_binding","backend":"centl-session"},"session":{"definitions":1,"requests":1}}
  {"version":1,"id":"b","ok":true,"value":{"kind":"symbolic","exact":true,"expression":"9 * pi","text":"9 * pi"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"},"session":{"definitions":1,"requests":2}}
  {"version":1,"id":"c","ok":true,"reset":true,"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"control","method":"reset","backend":"centl-protocol"},"session":{"definitions":0,"requests":3}}

  $ printf '%s\n' '{"version":1,"id":"name","expression":"pi = 3"}' '{"version":1,"id":"parameter","expression":"f(x, x) = x"}' '{"version":1,"id":"empty","expression":"g() = 1"}' | ../src/main.exe --serve
  {"version":1,"id":"name","ok":false,"error":{"position":0,"range":{"start":0,"end":0},"code":"reserved_name","message":"pi is built in and cannot be redefined","retryable":false},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"},"session":{"definitions":0,"requests":1}}
  {"version":1,"id":"parameter","ok":false,"error":{"position":5,"range":{"start":5,"end":5},"code":"invalid_definition","message":"function parameters must be unique","retryable":false},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"},"session":{"definitions":0,"requests":2}}
  {"version":1,"id":"empty","ok":false,"error":{"position":2,"range":{"start":2,"end":2},"code":"invalid_definition","message":"a function definition needs at least one parameter","retryable":false},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"},"session":{"definitions":0,"requests":3}}

  $ seq 1 300 | sed 's/.*/{"version":1,"op":"ping"}/' | ../src/main.exe --serve | wc -l | tr -d ' '
  300

  $ printf '{"version":1,"id":"limit","expression":"approx(pi, 20)","limits":{"max_precision_digits":10}}\n' | ../src/main.exe --serve
  {"version":1,"id":"limit","ok":false,"error":{"details":{"category":"limit","limit":"max_precision_digits"},"suggestion":"Request fewer digits or retry with a larger permitted precision limit.","position":0,"range":{"start":0,"end":0},"code":"precision_limit","message":"approximation digits must be between 1 and 10","retryable":true},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"},"session":{"definitions":0,"requests":1}}

  $ printf '%s\n' '{"version":1,"id":"n","expression":"n = 6"}' '{"version":1,"id":"factorial","expression":"product(k, k = 1, n)"}' | ../src/main.exe --serve | tail -n 1
  {"version":1,"id":"factorial","ok":true,"value":{"kind":"integer","exact":true,"value":"720","text":"720"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"},"session":{"definitions":1,"requests":2}}

  $ printf '{"version":1,"id":"limit-sum","expression":"sum(k, k = 1, 4)","limits":{"max_integer_iterations":3}}\n' | ../src/main.exe --serve
  {"version":1,"id":"limit-sum","ok":false,"error":{"details":{"category":"limit","limit":"max_integer_iterations"},"suggestion":"Reduce the request or retry with a larger permitted request limit.","position":0,"range":{"start":0,"end":0},"code":"resource_limit","message":"the finite iteration exceeds the integer-iteration limit","retryable":true},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"},"session":{"definitions":0,"requests":1}}

  $ printf '%s\n' '{"version":1,"id":"d","expression":"d = 2^40"}' '{"version":1,"id":"bits","expression":"1/(d*d) + 1/3","limits":{"max_exact_bits":100}}' | ../src/main.exe --serve | tail -n 1
  {"version":1,"id":"bits","ok":false,"error":{"details":{"category":"limit","limit":"max_exact_bits"},"suggestion":"Reduce the request or retry with a larger permitted request limit.","position":0,"range":{"start":0,"end":0},"code":"resource_limit","message":"the exact result exceeds the bit limit","retryable":true},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"},"session":{"definitions":1,"requests":2}}

  $ printf '%s\n' '{"version":1,"id":"def","op":"define","expression":"r = 3"}' '{"version":1,"id":"comp","op":"compute","expression":"r^2"}' '{"version":1,"id":"bad","op":"compute","expression":"x = 1"}' '{"version":1,"id":"sess","op":"session"}' '{"version":1,"id":"help","op":"help","query":"factor"}' | ../src/main.exe --serve
  {"version":1,"id":"def","ok":true,"value":{"kind":"definition","exact":true,"definition_kind":"value","name":"r","value":{"kind":"integer","exact":true,"value":"3","text":"3"},"text":"r = 3"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact_definition","method":"session_binding","backend":"centl-session"},"session":{"definitions":1,"requests":1}}
  {"version":1,"id":"comp","ok":true,"value":{"kind":"integer","exact":true,"value":"9","text":"9"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"},"session":{"definitions":1,"requests":2}}
  {"version":1,"id":"bad","ok":false,"error":{"suggestion":"Use the explicit define operation for session definitions.","position":0,"range":{"start":0,"end":0},"code":"definition_not_allowed","message":"compute accepts expressions only and cannot define session state","retryable":false},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"},"session":{"definitions":1,"requests":3}}
  {"version":1,"id":"sess","ok":true,"definitions":[{"kind":"value","name":"r","expression":"3","dependencies":[]}],"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"control","method":"session_inspection","backend":"centl-protocol"},"session":{"definitions":1,"requests":4}}
  {"version":1,"id":"help","ok":true,"help":{"entries":[{"section":"Symbolic math","form":"factor(expression)","meaning":"factor a polynomial"},{"section":"Concrete math","form":"factorial(n)","meaning":"n factorial"}],"examples":[],"query":"factor"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"control","method":"syntax_help","backend":"centl-protocol"},"session":{"definitions":1,"requests":5}}

  $ ../src/main.exe 'factor(x^2 + 1)'
  x^2 + 1
  resolution: unsupported (operation=factor; reason=no_supported_factorization; supported_domain=symbolic even-power differences of squares, unit (x +/- 1)^2 quadratics, and common variable-power factors in univariate rational polynomials)

  $ ../src/main.exe 'simplify(x)'
  x
  resolution: unchanged_proved (operation=simplify; reason=polynomial_normal_form; supported_domain=bounded univariate rational polynomials with constant rational division)

  $ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"centl_compute","arguments":{"expression":"factor(x^2 + 1)"}}}' | ../src/main.exe --mcp | tail -n 1
  {"jsonrpc":"2.0","id":2,"result":{"content":[{"type":"text","text":"x^2 + 1\nresolution: unsupported (operation=factor; reason=no_supported_factorization; supported_domain=symbolic even-power differences of squares, unit (x +/- 1)^2 quadratics, and common variable-power factors in univariate rational polynomials)"}],"structuredContent":{"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"x^2 + 1","text":"x^2 + 1"},"resolution":{"status":"unsupported","operation":"factor","reason":"no_supported_factorization","supported_domain":"symbolic even-power differences of squares, unit (x +/- 1)^2 quadratics, and common variable-power factors in univariate rational polynomials"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"},"session":{"definitions":0,"requests":3}},"isError":false}}

  $ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":"0.1 + 0.2"}}}' | ../src/main.exe --mcp
  {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-11-25","capabilities":{"tools":{"listChanged":false}},"serverInfo":{"name":"centl","title":"CENTL exact mathematics","version":"0.11.0"},"instructions":"Use read-only centl_compute for mathematics, centl_verify for structured claims, and centl_define for immutable session definitions. centl_calculate remains available for compatibility. Definitions persist until centl_reset or process exit."}}
  {"jsonrpc":"2.0","id":2,"result":{"content":[{"type":"text","text":"3/10"}],"structuredContent":{"version":1,"ok":true,"value":{"kind":"rational","exact":true,"numerator":"3","denominator":"10","text":"3/10"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"},"session":{"definitions":0,"requests":3}},"isError":false}}

  $ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":"finite","method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":"product(k, k = 1, 6)"}}}' | ../src/main.exe --mcp | tail -n 1
  {"jsonrpc":"2.0","id":"finite","result":{"content":[{"type":"text","text":"720"}],"structuredContent":{"version":1,"ok":true,"value":{"kind":"integer","exact":true,"value":"720","text":"720"},"resolution":{"status":"computed"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"},"session":{"definitions":0,"requests":3}},"isError":false}}

  $ printf '# exact sums\n0.1 + 0.2\n1/3 + 1/6\n' | ../src/main.exe
  3/10
  1/2

  $ printf 'r = 3\ncircle_area(r)\nf(x) = x^2 + 1\nf(3)\ndiff(f(x), x)\n' | ../src/main.exe
  r = 3
  9 * pi
  f(x) = x^2 + 1
  10
  2 * x

  $ printf '%s\n' 'sum(' '  k^2,' '  k = 1,' '  4)' | ../src/main.exe
  30

  $ printf '%s\n' 'f(x) =' '  x^2 + 1' 'f(4)' | ../src/main.exe
  f(x) = x^2 + 1
  17

  $ printf '%s\n' '# multiline script' 'product(' '  k,' '  k = 1,' '  5)' > multiline.centl
  $ ../src/main.exe --file multiline.centl
  120

  $ printf '%s\n' '# heading' '' 'sum(' '  k,' '  k,' > bad-multiline.centl
  $ ../src/main.exe --file bad-multiline.centl
  bad-multiline.centl:5:4: error: expected '=', found ','
  5 |   k,
    |    ^
  [2]

  $ printf '%s\n' 'sum(' '  k,' '  k,' '  3)' | ../src/main.exe
  standard input:3:4: error: expected '=', found ','
  3 |   k,
    |    ^
  [2]

  $ printf '1 +\n' | ../src/main.exe
  standard input:1:4: error: expected a number or '(', found the end of the expression
  1 | 1 +
    |    ^
  [2]

  $ if command -v timeout >/dev/null 2>&1 && command -v script >/dev/null 2>&1 && script -V 2>/dev/null | grep -qi util-linux; then sh raw-repl ../src/main.exe edit; else echo 2; fi
  2

  $ if command -v timeout >/dev/null 2>&1 && command -v script >/dev/null 2>&1 && script -V 2>/dev/null | grep -qi util-linux; then sh raw-repl ../src/main.exe limit; else echo 'error: the expression exceeds the source-byte limit'; fi
  error: the expression exceeds the source-byte limit

  $ if command -v timeout >/dev/null 2>&1 && command -v script >/dev/null 2>&1 && script -V 2>/dev/null | grep -qi util-linux; then sh raw-repl ../src/main.exe partial-escape; else echo raw-escape-ok; fi
  raw-escape-ok

  $ ../src/main.exe --file fixtures/exact.centl
  3/10
  1/2

  $ ../src/main.exe --file fixtures/definitions.centl
  r = 3
  9 * pi
  f(x) = x^2 + 1
  10
  2 * x

  $ ../src/main.exe 'pi = 3'
  error: pi is built in and cannot be redefined at column 1
  1 | pi = 3
    | ^
  [2]

  $ ../src/main.exe '1 / 0'
  error: division by zero at column 1
  1 | 1 / 0
    | ^
  [2]

  $ ../src/main.exe '1 +'
  error: expected a number or '(', found the end of the expression at column 4
  1 | 1 +
    |    ^
  [2]

  $ ../src/main.exe 'sum(k, k, 1, 3)'
  error: expected '=', found ',' at column 9
  1 | sum(k, k, 1, 3)
    |         ^
  [2]

  $ ../src/main.exe 'integrate(x^2, 3)'
  error: expected an integration variable, found a number at column 16
  1 | integrate(x^2, 3)
    |                ^
  [2]

  $ ../src/main.exe 'integrate(x^2, x, 0, 1)'
  error: expected ')' or '=', found ',' at column 17
  1 | integrate(x^2, x, 0, 1)
    |                 ^
  [2]

  $ ../src/main.exe 'integrate(x^2, x = 0)'
  error: expected ',', found ')' at column 21
  1 | integrate(x^2, x = 0)
    |                     ^
  [2]

  $ ../src/main.exe 'sum = 3'
  error: sum is built in and cannot be redefined at column 1
  1 | sum = 3
    | ^
  [2]

  $ printf '%s\n' '{"version":1,"id":"v1","op":"verify","left":"0.1 + 0.2","relation":"equal","right":"3/10"}' '{"version":1,"id":"v2","op":"verify","left":"1+1","relation":"equal","right":"3"}' | ../src/main.exe --serve
  {"version":1,"id":"v1","ok":true,"verification":{"schema":1,"verdict":"verified","scope":"closed_exact_rational","method":"closed_rational_comparison","claim":{"left":"0.1 + 0.2","relation":"equal","right":"3/10","variables":[],"assumptions":[]},"evidence":{"left":{"kind":"rational","text":"3/10","numerator":"3","denominator":"10"},"right":{"kind":"rational","text":"3/10","numerator":"3","denominator":"10"},"comparison":"equal","left_resolution":{"status":"computed"},"right_resolution":{"status":"computed"}},"assurance":{"class":"exact_algorithm"},"producer":{"name":"centl","version":"0.11.0"}},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"verification","method":"claim_verification","backend":"centl-verify"},"session":{"definitions":0,"requests":1}}
  {"version":1,"id":"v2","ok":true,"verification":{"schema":1,"verdict":"refuted","scope":"closed_exact_rational","method":"closed_rational_comparison","claim":{"left":"1+1","relation":"equal","right":"3","variables":[],"assumptions":[]},"evidence":{"left":{"kind":"integer","text":"2","numerator":"2","denominator":"1"},"right":{"kind":"integer","text":"3","numerator":"3","denominator":"1"},"comparison":"less","left_resolution":{"status":"computed"},"right_resolution":{"status":"computed"}},"assurance":{"class":"exact_algorithm"},"producer":{"name":"centl","version":"0.11.0"}},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"verification","method":"claim_verification","backend":"centl-verify"},"session":{"definitions":0,"requests":2}}

  $ ../src/main.exe verify --left '0.1 + 0.2' --relation equal --right '3/10'
  verdict: verified (closed_exact_rational via closed_rational_comparison); comparison=equal

  $ ../src/main.exe verify --left '1+1' --relation equal --right '3'; echo $?
  verdict: refuted (closed_exact_rational via closed_rational_comparison); comparison=less
  1

  $ ../src/main.exe verify --left 'sqrt(2)' --relation less_than --right '2'
  verdict: verified (closed_real_enclosure via certified_enclosure_sign); comparison=less

  $ ../src/main.exe verify --left '0.1 + 0.2' --relation equal --right '3/10' --json | python3 -c 'import sys,json; o=json.load(sys.stdin); v=o["verification"]; print(v["verdict"], v["scope"], v["assurance"]["class"], o["provenance"]["classification"], o["session"]["requests"])'
  verified closed_exact_rational exact_algorithm verification 1

  $ ../src/main.exe verify --left '(x+1)^2' --relation equal --right 'x^2+2*x+1' --variable x:rational; echo $?
  verdict: unknown (univariate_rational_polynomial via polynomial_zero_difference); comparison=equal; reason=polynomial_soundness_theorem_pending
  1

  $ ../src/main.exe verify --left '(x+1)^2' --relation equal --right 'x^2+2*x' --variable x:rational; echo $?
  verdict: refuted (univariate_rational_polynomial via exact_rational_counterexample); counterexample={x=0}
  1

  $ ../src/main.exe 'assert(0.1 + 0.2 = 3/10)'
  verdict: verified (closed_exact_rational via closed_rational_comparison); comparison=equal

  $ ../src/main.exe --json 'assert(0.1 + 0.2 = 3/10)' | python3 -c 'import sys,json; o=json.load(sys.stdin); print(o["verification"]["verdict"], o["provenance"]["classification"], o["session"]["requests"])'
  verified verification 1

  $ ../src/main.exe 'assertion(1)'
  assertion(1)

  $ ../src/main.exe 'assert(1 + 1 = 3)'; echo $?
  verdict: refuted (closed_exact_rational via closed_rational_comparison); comparison=less
  1

  $ ../src/main.exe 'assert((x+1)^2 = x^2+2*x+1, for_all = x, domain = rational)'; echo $?
  verdict: unknown (univariate_rational_polynomial via polynomial_zero_difference); comparison=equal; reason=polynomial_soundness_theorem_pending
  1

  $ ../src/main.exe check fixtures/contracts.centl; echo $?
  line 2: verified
  line 3: verified
  line 4: defined
  line 5: verified
  line 6: verified
  line 7: unknown
  line 8: unknown
  1

  $ ../src/main.exe check fixtures/contracts.centl --json | python3 -c 'import sys,json; o=json.load(sys.stdin); print(o["ok"], o["failures"], o["results"][0]["verification"]["verdict"], o["results"][2]["kind"], o["results"][-1]["verification"]["verdict"])'
  False 2 verified define unknown

  $ printf '%s\n' 'define | broken =' > malformed-contract.centl
  $ ../src/main.exe check malformed-contract.centl; echo $?
  line 1: ERROR expected a number or '(', found the end of the expression at column 9
  2

  $ printf '%s\n' 'equal | factorial(100001) | 1' > resource-contract.centl
  $ ../src/main.exe check resource-contract.centl; echo $?
  line 1: ERROR the exact result exceeds the bit limit at column 1
  2

  $ awk 'BEGIN { for (i = 0; i < 32769; i++) printf "x"; print "" }' > oversized-contract.centl
  $ ../src/main.exe check oversized-contract.centl; echo $?
  centl: contract exceeds the 32768-byte source limit
  2

  $ printf '{"version":2,"expression":"1 + 1"}\n' | ../src/main.exe --json
  {"version":1,"ok":false,"error":{"code":"invalid_request","message":"unsupported protocol version","retryable":false},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.11.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"}}
  [2]
