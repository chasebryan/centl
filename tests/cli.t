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

  $ ../src/main.exe 'integrate(1/x, x)'
  integrate(1 / x, x)

  $ ../src/main.exe 'integrate(x^2, x = 0, a)'
  integrate(x^2, x = 0, a)

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
  unresolved: solve(x^2 = 2, x)

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
  integrate(x, _centl_bound_x)

  $ ../src/main.exe 'approx(sqrt(2), 12)'
  ≈ [1.41421356237, 1.41421356238]

  $ ../src/main.exe --version
  centl 0.8.0

  $ ../src/main.exe --syntax | sed -n '1,4p'
  CENTL syntax
  values: integer decimal fraction variable () pi e tau
  arithmetic: + - * / ^
  symbolic math: f(...) name= f(...)= solve diff integrate substitute simplify expand factor assuming = != < <= > >=

  $ ../src/main.exe --help | sed -n '1p;3p;5,11p'
  CENTL — exact mathematics, directly.
  Usage: centl [--json|--serve|--mcp] [--syntax] [--color=auto|always|never] [--file PATH] [EXPRESSION]
    centl EXPRESSION   calculate
    centl              open the calculator
    --file PATH        run a script
    --syntax           list mathematical identifiers
    --json [EXPR]      use the JSON interface
    --serve            persistent stateful JSON Lines
    --mcp              MCP server over standard I/O

  $ ../src/main.exe --color=always 'x + 1' | sed "s/$(printf '\033')/<ESC>/g"
  <ESC>[95mx<ESC>[0m<ESC>[93m + <ESC>[0m<ESC>[96m1<ESC>[0m

  $ ../src/main.exe --json '1 / 8'
  {"version":1,"ok":true,"value":{"kind":"rational","exact":true,"numerator":"1","denominator":"8","text":"1/8"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"}}

  $ ../src/main.exe --json 'integrate(x^2, x = 0, 1)'
  {"version":1,"ok":true,"value":{"kind":"rational","exact":true,"numerator":"1","denominator":"3","text":"1/3"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"}}

  $ ../src/main.exe --json 'sum(k, k = 1, 10)'
  {"version":1,"ok":true,"value":{"kind":"integer","exact":true,"value":"55","text":"55"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"}}

  $ ../src/main.exe --json 'diff(sin(x), x)'
  {"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"cos(x)","text":"cos(x)"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"}}

  $ ../src/main.exe --json 'assuming(x / x, x != 0)'
  {"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"1 where x != 0","text":"1 where x != 0","conditions":[{"left":"x","relation":"not_equal","right":"0","text":"x != 0"}]},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"}}

  $ ../src/main.exe --json 'solve(x^2 - 1 = 0, x)'
  {"version":1,"ok":true,"value":{"kind":"solution_set","exact":true,"resolved":true,"status":"finite","variable":"x","solutions":[{"numerator":"-1","denominator":"1","text":"-1"},{"numerator":"1","denominator":"1","text":"1"}],"equation":{"left":"x^2 - 1","right":"0"},"text":"x in {-1, 1}"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact_solution_set","method":"equation_solving","backend":"centl-exact"}}

  $ printf '{"version":1,"expression":"2 * (3 + 4)"}\n' | ../src/main.exe --json
  {"version":1,"ok":true,"value":{"kind":"integer","exact":true,"value":"14","text":"14"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"}}

  $ printf '%s\n' '{"version":1,"id":"a","expression":"r = 3"}' '{"version":1,"id":"b","expression":"circle_area(r)"}' '{"version":1,"id":"c","op":"reset"}' | ../src/main.exe --serve
  {"version":1,"id":"a","ok":true,"value":{"kind":"definition","exact":true,"definition_kind":"value","name":"r","value":{"kind":"integer","exact":true,"value":"3","text":"3"},"text":"r = 3"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact_definition","method":"session_binding","backend":"centl-session"},"session":{"definitions":1,"requests":1}}
  {"version":1,"id":"b","ok":true,"value":{"kind":"symbolic","exact":true,"expression":"9 * pi","text":"9 * pi"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact_symbolic","method":"symbolic_evaluation","backend":"centl-core"},"session":{"definitions":1,"requests":2}}
  {"version":1,"id":"c","ok":true,"reset":true,"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"control","method":"reset","backend":"centl-protocol"},"session":{"definitions":0,"requests":3}}

  $ seq 1 300 | sed 's/.*/{"version":1,"op":"ping"}/' | ../src/main.exe --serve | wc -l | tr -d ' '
  300

  $ printf '{"version":1,"id":"limit","expression":"approx(pi, 20)","limits":{"max_precision_digits":10}}\n' | ../src/main.exe --serve
  {"version":1,"id":"limit","ok":false,"error":{"code":"precision_limit","message":"approximation digits must be between 1 and 10"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"},"session":{"definitions":0,"requests":1}}

  $ printf '%s\n' '{"version":1,"id":"n","expression":"n = 6"}' '{"version":1,"id":"factorial","expression":"product(k, k = 1, n)"}' | ../src/main.exe --serve | tail -n 1
  {"version":1,"id":"factorial","ok":true,"value":{"kind":"integer","exact":true,"value":"720","text":"720"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"},"session":{"definitions":1,"requests":2}}

  $ printf '{"version":1,"id":"limit-sum","expression":"sum(k, k = 1, 4)","limits":{"max_integer_iterations":3}}\n' | ../src/main.exe --serve
  {"version":1,"id":"limit-sum","ok":false,"error":{"code":"resource_limit","message":"the finite iteration exceeds the integer-iteration limit"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"},"session":{"definitions":0,"requests":1}}

  $ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":"0.1 + 0.2"}}}' | ../src/main.exe --mcp
  {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-11-25","capabilities":{"tools":{"listChanged":false}},"serverInfo":{"name":"centl","title":"CENTL exact mathematics","version":"0.8.0"},"instructions":"Use centl_calculate for exact, symbolic, or rigorously enclosed mathematics. Definitions persist until centl_reset or process exit."}}
  {"jsonrpc":"2.0","id":2,"result":{"content":[{"type":"text","text":"3/10"}],"structuredContent":{"version":1,"ok":true,"value":{"kind":"rational","exact":true,"numerator":"3","denominator":"10","text":"3/10"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"},"session":{"definitions":0,"requests":3}},"isError":false}}

  $ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":"finite","method":"tools/call","params":{"name":"centl_calculate","arguments":{"expression":"product(k, k = 1, 6)"}}}' | ../src/main.exe --mcp | tail -n 1
  {"jsonrpc":"2.0","id":"finite","result":{"content":[{"type":"text","text":"720"}],"structuredContent":{"version":1,"ok":true,"value":{"kind":"integer","exact":true,"value":"720","text":"720"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"exact","method":"rational_evaluation","backend":"centl-core"},"session":{"definitions":0,"requests":3}},"isError":false}}

  $ printf '# exact sums\n0.1 + 0.2\n1/3 + 1/6\n' | ../src/main.exe
  3/10
  1/2

  $ printf 'r = 3\ncircle_area(r)\nf(x) = x^2 + 1\nf(3)\ndiff(f(x), x)\n' | ../src/main.exe
  r = 3
  9 * pi
  f(x) = x^2 + 1
  10
  2 * x

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
  error: pi is built in and cannot be redefined
  [2]

  $ ../src/main.exe '1 / 0'
  error: division by zero
  [2]

  $ ../src/main.exe '1 +'
  error: expected a number or '(', found the end of the expression at column 4
  [2]

  $ ../src/main.exe 'sum(k, k, 1, 3)'
  error: expected '=', found ',' at column 9
  [2]

  $ ../src/main.exe 'integrate(x^2, 3)'
  error: expected an integration variable, found a number at column 16
  [2]

  $ ../src/main.exe 'integrate(x^2, x, 0, 1)'
  error: expected ')' or '=', found ',' at column 17
  [2]

  $ ../src/main.exe 'integrate(x^2, x = 0)'
  error: expected ',', found ')' at column 21
  [2]

  $ ../src/main.exe 'sum = 3'
  error: sum is built in and cannot be redefined
  [2]

  $ printf '{"version":2,"expression":"1 + 1"}\n' | ../src/main.exe --json
  {"version":1,"ok":false,"error":{"code":"invalid_request","message":"unsupported protocol version"},"provenance":{"schema":1,"producer":{"name":"centl","version":"0.8.0"},"classification":"failure","method":"evaluation","backend":"centl-runtime"}}
  [2]
