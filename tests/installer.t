  $ cp -RL fixtures/release release-fixture
  $ chmod 755 release-fixture/centl/bin/centl release-fixture/centl/libexec/centl release-fixture/centl/bin/centl-physics release-fixture/centl/libexec/centl-physics release-fixture/centl/bin/centl-sci release-fixture/centl/libexec/centl-sci
  $ tar -czf centl-linux-x86_64.tar.gz -C release-fixture centl
  $ sha256sum centl-linux-x86_64.tar.gz > centl-linux-x86_64.tar.gz.sha256
  $ mkdir -p home

  $ HOME="$PWD/home" SHELL=/bin/bash ../install --archive "$PWD/centl-linux-x86_64.tar.gz" --prefix "$PWD/prefix"
  Installed CENTL 0.0.0-test at $TESTCASE_ROOT/prefix/share/centl/versions/0.0.0-test
  Command: $TESTCASE_ROOT/prefix/bin/centl
  Physics command: $TESTCASE_ROOT/prefix/bin/centl-physics
  Scientific command: $TESTCASE_ROOT/prefix/bin/centl-sci
  
  CENTL-SCi is ready.
  PATH configured in $TESTCASE_ROOT/home/.bashrc for new shells.
  Open a new terminal and run: centl-sci
  Or start now with:
    export PATH='$TESTCASE_ROOT/prefix/bin':"$PATH"
    centl-sci

  $ "$PWD/prefix/bin/centl" numbers are exact
  centl fixture numbers are exact

  $ "$PWD/prefix/bin/centl-physics" convert 100 cm m
  1

  $ "$PWD/prefix/bin/centl-sci" 'What is 0.1 plus 0.2?'
  3/10

  $ printf ':exit\n' | "$PWD/prefix/bin/centl-sci" --repl
  CENTL-SCi v0.0.1-Camelus
  Free for science.
  
  > 

  $ HOME="$PWD/home" SHELL=/bin/bash ../install --archive "$PWD/centl-linux-x86_64.tar.gz" --prefix "$PWD/prefix" 2>&1
  centl install: CENTL 0.0.0-test is already installed at $TESTCASE_ROOT/prefix/share/centl/versions/0.0.0-test
  [1]

  $ HOME="$PWD/home" SHELL=/bin/bash ../install --archive "$PWD/centl-linux-x86_64.tar.gz" --version 9.9.9 --prefix "$PWD/other" 2>&1
  centl install: requested 9.9.9 but the archive contains 0.0.0-test
  [1]

  $ cp centl-linux-x86_64.tar.gz corrupt.tar.gz
  $ cp centl-linux-x86_64.tar.gz.sha256 corrupt.tar.gz.sha256
  $ printf 'corrupt' >> corrupt.tar.gz
  $ HOME="$PWD/home" SHELL=/bin/bash ../install --archive "$PWD/corrupt.tar.gz" --prefix "$PWD/corrupt" 2>&1
  centl install: release checksum verification failed
  [1]

  $ mkdir -p occupied/bin
  $ touch occupied/bin/centl
  $ HOME="$PWD/home" SHELL=/bin/bash ../install --archive "$PWD/centl-linux-x86_64.tar.gz" --prefix "$PWD/occupied" 2>&1
  centl install: $TESTCASE_ROOT/occupied/bin/centl already exists and is not a symbolic link
  [1]

  $ mkdir -p occupied-physics/bin
  $ touch occupied-physics/bin/centl-physics
  $ HOME="$PWD/home" SHELL=/bin/bash ../install --archive "$PWD/centl-linux-x86_64.tar.gz" --prefix "$PWD/occupied-physics" 2>&1
  centl install: $TESTCASE_ROOT/occupied-physics/bin/centl-physics already exists and is not a symbolic link
  [1]

  $ mkdir -p occupied-sci/bin
  $ touch occupied-sci/bin/centl-sci
  $ HOME="$PWD/home" SHELL=/bin/bash ../install --archive "$PWD/centl-linux-x86_64.tar.gz" --prefix "$PWD/occupied-sci" 2>&1
  centl install: $TESTCASE_ROOT/occupied-sci/bin/centl-sci already exists and is not a symbolic link
  [1]
