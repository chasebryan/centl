  $ ../src/sci_main.exe 'What is 0.1 plus 0.2?'
  3/10

  $ ../src/sci_main.exe 'Solve x squared minus 5x plus 6 equals zero.'
  x = 2 or x = 3

  $ ../src/sci_main.exe 'Convert 2.5 kilometers to meters.'
  2500 m

  $ ../src/sci_main.exe --details 'Solve x squared minus 5x plus 6 equals zero.'
  x = 2 or x = 3
  
  Details:
    Exact result
    Variable: x
    Method: polynomial equation solving
    Verified by CENTL

  $ ../src/sci_main.exe --json 'What is 0.1 plus 0.2?' | grep -F '"interpreter_path": "fast"' >/dev/null

  $ printf '%s\n' 'What is 0.1 plus 0.2?' 'Convert 2.5 kilometers to meters.' ':exit' | ../src/sci_main.exe --repl | sed 's/> $/>/'
  CENTL-SCi v0.0.1-Camelus
  Free for science.
  
  > 3/10
  > 2500 m
  >

  $ printf '%s\n' 'This is not a supported scientific problem.' 'What is 0.1 plus 0.2?' ':quit' | ../src/sci_main.exe --repl | sed 's/> $/>/'
  CENTL-SCi v0.0.1-Camelus
  Free for science.
  
  > CENTL-SCi cannot solve this problem yet.
  > 3/10
  >

  $ printf '%s\n' ':details on' 'What is 0.1 plus 0.2?' ':details off' ':exit' | ../src/sci_main.exe --repl | sed 's/> $/>/'
  CENTL-SCi v0.0.1-Camelus
  Free for science.
  
  > Details on.
  > 3/10
  
  Details:
    Exact result
    Method: exact arithmetic
    Verified by CENTL
  > Details off.
  >

  $ printf '%s\n' 'What is 0.1 plus 0.2?' | ../src/sci_main.exe --repl | sed 's/> $/>/'
  CENTL-SCi v0.0.1-Camelus
  Free for science.
  
  > 3/10
  >
