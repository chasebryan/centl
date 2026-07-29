  $ cp -RL fixtures/release release-fixture
  $ chmod 755 release-fixture/centl/bin/centl release-fixture/centl/libexec/centl
  $ tar -czf centl-linux-x86_64.tar.gz -C release-fixture centl
  $ sha256sum centl-linux-x86_64.tar.gz > centl-linux-x86_64.tar.gz.sha256

  $ HOME="$PWD/home" ../install --archive "$PWD/centl-linux-x86_64.tar.gz" --prefix "$PWD/prefix"
  Installed CENTL 0.0.0-test at $TESTCASE_ROOT/prefix/share/centl/versions/0.0.0-test
  Command: $TESTCASE_ROOT/prefix/bin/centl
  Add $TESTCASE_ROOT/prefix/bin to PATH to run centl anywhere.

  $ "$PWD/prefix/bin/centl" numbers are exact
  centl fixture numbers are exact

  $ HOME="$PWD/home" ../install --archive "$PWD/centl-linux-x86_64.tar.gz" --prefix "$PWD/prefix" 2>&1
  centl install: CENTL 0.0.0-test is already installed at $TESTCASE_ROOT/prefix/share/centl/versions/0.0.0-test
  [1]

  $ HOME="$PWD/home" ../install --archive "$PWD/centl-linux-x86_64.tar.gz" --version 9.9.9 --prefix "$PWD/other" 2>&1
  centl install: requested 9.9.9 but the archive contains 0.0.0-test
  [1]

  $ cp centl-linux-x86_64.tar.gz corrupt.tar.gz
  $ cp centl-linux-x86_64.tar.gz.sha256 corrupt.tar.gz.sha256
  $ printf 'corrupt' >> corrupt.tar.gz
  $ HOME="$PWD/home" ../install --archive "$PWD/corrupt.tar.gz" --prefix "$PWD/corrupt" 2>&1
  centl install: release checksum verification failed
  [1]

  $ mkdir -p occupied/bin
  $ touch occupied/bin/centl
  $ HOME="$PWD/home" ../install --archive "$PWD/centl-linux-x86_64.tar.gz" --prefix "$PWD/occupied" 2>&1
  centl install: $TESTCASE_ROOT/occupied/bin/centl already exists and is not a symbolic link
  [1]
