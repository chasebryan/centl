  $ ../src/main.exe '0.1 + 0.2'
  3/10

  $ ../src/main.exe '1/3 + 1/6'
  1/2

  $ ../src/main.exe 'diff(x^3 + 2*x + 1, x)'
  3 * x^2 + 2

  $ ../src/main.exe 'substitute(x^2 + 1, x = 3)'
  10

  $ ../src/main.exe 'simplify(2*x + 3*x)'
  5 * x

  $ ../src/main.exe 'expand((x + 1)^3)'
  x^3 + 3 * x^2 + 3 * x + 1

  $ ../src/main.exe 'factor(x^2 - 1)'
  (x - 1) * (x + 1)

  $ ../src/main.exe 'assuming(x / x, x != 0)'
  1 where x != 0

  $ ../src/main.exe 'distance(0, 0, 3, 4)'
  5

  $ ../src/main.exe 'circle_area(3)'
  9 * pi

  $ ../src/main.exe 'choose(52, 5)'
  2598960

  $ ../src/main.exe 'approx(sqrt(2), 12)'
  ≈ [1.41421356237, 1.41421356238]

  $ ../src/main.exe --version
  centl 0.5.0-dev

  $ ../src/main.exe --syntax | sed -n '1,4p'
  CENTL syntax
  values: integer decimal fraction variable () pi e tau
  arithmetic: + - * / ^
  symbolic math: f(...) name= f(...)= diff substitute simplify expand factor assuming = != < <= > >=

  $ ../src/main.exe --help | sed -n '1p;3p;5,8p'
  CENTL — exact mathematics, directly.
  Usage: centl [--json] [--syntax] [--color=auto|always|never] [--file PATH] [EXPRESSION]
    centl EXPRESSION   calculate
    centl              open the calculator
    --file PATH        run a script
    --syntax           list mathematical identifiers

  $ ../src/main.exe --color=always 'x + 1' | sed "s/$(printf '\033')/<ESC>/g"
  <ESC>[95mx<ESC>[0m<ESC>[93m + <ESC>[0m<ESC>[96m1<ESC>[0m

  $ ../src/main.exe --json '1 / 8'
  {"version":1,"ok":true,"value":{"kind":"rational","exact":true,"numerator":"1","denominator":"8","text":"1/8"}}

  $ ../src/main.exe --json 'diff(sin(x), x)'
  {"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"cos(x)","text":"cos(x)"}}

  $ ../src/main.exe --json 'assuming(x / x, x != 0)'
  {"version":1,"ok":true,"value":{"kind":"symbolic","exact":true,"expression":"1 where x != 0","text":"1 where x != 0","conditions":[{"left":"x","relation":"not_equal","right":"0","text":"x != 0"}]}}

  $ printf '{"version":1,"expression":"2 * (3 + 4)"}\n' | ../src/main.exe --json
  {"version":1,"ok":true,"value":{"kind":"integer","exact":true,"value":"14","text":"14"}}

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

  $ printf '{"version":2,"expression":"1 + 1"}\n' | ../src/main.exe --json
  {"version":1,"ok":false,"error":{"code":"invalid_request","message":"unsupported protocol version"}}
  [2]
