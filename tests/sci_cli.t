  $ ../src/sci_main.exe 'What is 0.1 plus 0.2?'
  3/10

  $ ../src/sci_main.exe 'Solve x squared minus 5x plus 6 equals zero.'
  x = 2 or x = 3

  $ ../src/sci_main.exe 'Convert 2.5 kilometers to meters.'
  2500 m

  $ ../src/sci_main.exe 'What is 2 × 3?'
  6

  $ ../src/sci_main.exe --mode math 'Solve x² minus 5x plus 6 equals zero.'
  x = 2 or x = 3

  $ ../src/sci_main.exe --details 'Solve x squared minus 5x plus 6 equals zero.'
  x = 2 or x = 3
  
  Details:
    Exact result
    Variable: x
    Method: polynomial equation solving
    Verified by CENTL

  $ ../src/sci_main.exe --explain 'What is 0.1 plus 0.2?'
  3/10
  
  Details:
    Exact result
    Method: exact arithmetic
    Verified by CENTL

  $ ../src/sci_main.exe --json 'What is 0.1 plus 0.2?' | grep -F '"interpreter_path": "fast"' >/dev/null

  $ printf '%s\n' 'What is 0.1 plus 0.2?' 'Convert 2.5 kilometers to meters.' ':exit' | ../src/sci_main.exe --repl --no-history | sed 's/> $/>/'
  CENTL-SCi v0.0.2-dev
  Free for science.
  
  HYBRID> 3/10
  HYBRID> 2500 m
  HYBRID>

  $ printf '%s\n' ':mode math' 'What is 0.1 plus 0.2?' ':mode physics' 'Convert 2.5 kilometers to meters.' ':mode build' ':mode' ':exit' | ../src/sci_main.exe --repl --no-history | sed 's/> $/>/'
  CENTL-SCi v0.0.2-dev
  Free for science.
  
  HYBRID> Mode: math
  MATH> 3/10
  MATH> Mode: physics
  PHYS> 2500 m
  PHYS> Mode: build
  BUILD> Mode: build
  BUILD>

  $ printf '%s\n' ':details on' 'What is 0.1 plus 0.2?' ':details off' ':exit' | ../src/sci_main.exe --repl --no-history | sed 's/> $/>/'
  CENTL-SCi v0.0.2-dev
  Free for science.
  
  HYBRID> Explanation details on.
  HYBRID> 3/10
  
  Details:
    Exact result
    Method: exact arithmetic
    Verified by CENTL
  HYBRID> Explanation details off.
  HYBRID>

  $ printf '%s\n' 'solve x squared plus 4' ':quit' | ../src/sci_main.exe --repl --no-history | sed 's/> $/>/'
  CENTL-SCi v0.0.2-dev
  Free for science.
  
  HYBRID> I understand this as an equation-solving request, but the equation relation or right-hand side is missing. Try, for example: solve x squared plus 4 equals 0.
  HYBRID>

  $ printf '%s\n' 'What is 0.1 plus 0.2?' | ../src/sci_main.exe --repl --no-history | sed 's/> $/>/'
  CENTL-SCi v0.0.2-dev
  Free for science.
  
  HYBRID> 3/10
  HYBRID>
