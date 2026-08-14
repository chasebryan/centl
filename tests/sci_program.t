  $ export CENTL_WORKSPACE="$PWD/ws"
  $ mkdir -p "$CENTL_WORKSPACE"
  $ ../src/sci_main.exe 'let square(x) = x^2' | sed 's#/.*/ws/#WS/#'
  I created local program `square`.
  
  Source:
    square(x) = x^2
  
  Created local CENTL function square.
  Generated/validated source: square(x) = x^2
  Source file: WS/modules/square.centl
  Workspace revision: 1
  Assurance: locally tested extension (not verified core).
  The extension is enabled and will be loaded into the active downstream CENTL session.
  
  Try it now:
    square(1)  →  1
  
  Spoken English now:
    square of 2
  
  No restart needed. It is loaded into this live session now.
  
  This is yours to edit, disable, or undo.
  It is a local extension, not verified CENTL core.
  $ ../src/sci_main.exe 'square(6)'
  36
  $ ../src/sci_main.exe 'what is the square of 6'
  36
  $ ../src/sci_main.exe 'What is 0.1 plus 0.2?'
  3/10
  $ ../src/sci_main.exe 'foo(6)'
  foo(6)
  
  `foo` is not a live program in this session. Create it with:
    make a function called foo that takes ... and computes ...
  Or teach the session: teach yourself foo
