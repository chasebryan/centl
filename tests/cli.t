  $ ../src/main.exe '0.1 + 0.2'
  3/10

  $ ../src/main.exe '1/3 + 1/6'
  1/2

  $ ../src/main.exe --json '1 / 8'
  {"version":1,"ok":true,"value":{"kind":"rational","exact":true,"numerator":"1","denominator":"8","text":"1/8"}}

  $ printf '{"version":1,"expression":"2 * (3 + 4)"}\n' | ../src/main.exe --json
  {"version":1,"ok":true,"value":{"kind":"integer","exact":true,"value":"14","text":"14"}}

  $ printf '# exact sums\n0.1 + 0.2\n1/3 + 1/6\n' | ../src/main.exe
  3/10
  1/2

  $ ../src/main.exe --file fixtures/exact.centl
  3/10
  1/2

  $ ../src/main.exe '1 / 0'
  error: division by zero
  [2]

  $ ../src/main.exe '1 +'
  error: expected a number or '(', found the end of the expression at column 4
  [2]

  $ printf '{"version":2,"expression":"1 + 1"}\n' | ../src/main.exe --json
  {"version":1,"ok":false,"error":{"code":"invalid_request","message":"unsupported protocol version"}}
  [2]
