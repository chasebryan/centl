# Install CENTL

Prebuilt releases contain CENTL and its native math libraries. F*, OPAM,
OCaml, Dune, a C compiler, and development headers are not required.

## Linux and macOS

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install
less install
sh install
```

The installer detects Linux x86_64, macOS x86_64, or macOS arm64; verifies the
archive's SHA-256 checksum; and installs below `~/.local` without `sudo`.
The x86_64 packages target the baseline x86-64 ISA and select optimized GMP
routines at runtime when the processor supports them.

```sh
sh install --version 0.11.0
sh install --prefix "$HOME/software"
```

## Windows

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/chasebryan/centl/main/install.ps1 -OutFile install.ps1
Get-Content .\install.ps1
Unblock-File .\install.ps1
.\install.ps1
centl '0.1 + 0.2'
```

The PowerShell installer supports Windows x86_64, verifies the ZIP checksum,
installs below `%LOCALAPPDATA%\Programs\CENTL`, and adds its command directory
to the user's PATH. Open a new terminal after the first installation.

```powershell
.\install.ps1 -Version 0.11.0
.\install.ps1 -Prefix "$HOME\Software\CENTL" -NoPath
```

## Offline archives

Keep an archive and its adjacent `.sha256` file together.

```sh
sh install --archive ./centl-linux-x86_64.tar.gz
sh install --archive ./centl-macos-arm64.tar.gz
```

```powershell
.\install.ps1 -Archive .\centl-windows-x86_64.zip
```

## Release contract

Each release contains four native packages:

- Linux x86_64, built against glibc 2.35
- macOS x86_64 and arm64, targeting macOS 13 or newer
- Windows x86_64

FLINT, GMP, and MPFR are private to CENTL and never replace system libraries.
F* verifies and extracts the shared core once. Every native runner then builds
that exact output, runs the complete test suite, packages it, installs the
package into a clean temporary prefix, and runs an installed-binary smoke test.
The release workflow also reruns the deterministic fuzzing, metamorphic,
sanitizer, performance, and Julia/Nemo differential gates on Linux, then
re-verifies every collected asset against its adjacent checksum. A tag is
published only after those gates and all four native jobs pass.

Archives contain complete license texts for the bundled runtime components and
an exact source-reference file. The Windows executable statically links FLINT,
GMP, and MPFR, so that file also identifies the matching CENTL source and build
scripts needed to rebuild and relink it with compatible modified libraries.

## Build from source

Development builds use the pinned toolchain in [TOOLCHAIN.md](TOOLCHAIN.md).

```sh
make test
```

Maintainers package an already-tested native build with:

```sh
make release VERSION=0.11.0
```

```powershell
.\scripts\package-release.ps1 0.11.0
```
