# Install CENTL

The native release is the recommended way to use CENTL. It contains the CENTL,
CENTL Physics, and CENTL-SCi executables together with their required native math
libraries. F*, OPAM, OCaml, Dune, a C compiler, GMP, MPFR, FLINT, and development
headers are not required on the user's machine.

Linux is the CENTL-SCi reference platform. macOS remains a supported native
target. Windows x86_64 is experimental and best-effort during the early CENTL-SCi
development series.

## Linux and macOS

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install
sh install
```

The installer:

1. detects the supported platform and architecture;
2. downloads the requested native release, or accepts an offline archive;
3. verifies the archive SHA-256 checksum before extraction;
4. rejects unsafe archive paths;
5. stages the package under the user installation prefix;
6. runs `centl --version` as a runtime check;
7. smoke-tests exact physics unit conversion when CENTL Physics is present;
8. smoke-tests `centl-sci 'What is 0.1 plus 0.2?'` and requires `3/10` when
   CENTL-SCi is present;
9. starts `centl-sci --repl`, exits it cleanly, and requires both the CENTL-SCi
   identity line and `Free for science.` before activation;
10. atomically activates the installed version and command launchers;
11. configures the current user's Bash, Zsh, or POSIX profile when the command
    directory is not already on `PATH`, unless `--no-path` is requested.

The default prefix is `~/.local`. If PATH configuration was required, open a new
terminal once. The normal starting command is then:

```sh
centl-sci
```

A current CENTL-SCi package should begin:

```text
CENTL-SCi v0.0.1-Camelus
Free for science.

>
```

Additional installer options:

```sh
sh install --version 0.12.0-rc.1
sh install --prefix "$HOME/software"
sh install --no-path
```

`--no-path` leaves shell startup files untouched. The installer will print the
exact command directory that must be added manually.

## FCF or other static release hosts

GitHub Releases remains the default network source for compatibility, but the
installer does not require GitHub's URL layout.

A host-neutral release root may expose the same immutable version directories
that FCF preservation uses:

```text
RELEASE_ROOT/
  v0.12.0/
    centl-linux-x86_64.tar.gz
    centl-linux-x86_64.tar.gz.sha256
    centl-macos-x86_64.tar.gz
    centl-macos-x86_64.tar.gz.sha256
    centl-macos-arm64.tar.gz
    centl-macos-arm64.tar.gz.sha256
    centl-windows-x86_64.zip
    centl-windows-x86_64.zip.sha256
```

The exact files present depend on the release/platform matrix. The important URL
contract is simply:

```text
<release-base-url>/v<VERSION>/<asset>
<release-base-url>/v<VERSION>/<asset>.sha256
```

On Linux/macOS:

```sh
sh install \
  --version 0.12.0 \
  --release-base-url https://downloads.example.org/centl/releases
```

The equivalent environment form is:

```sh
CENTL_RELEASE_BASE_URL=https://downloads.example.org/centl/releases \
  sh install --version 0.12.0
```

On Windows:

```powershell
.\install.ps1 `
  -Version 0.12.0 `
  -ReleaseBaseUrl https://downloads.example.org/centl/releases
```

or:

```powershell
$env:CENTL_RELEASE_BASE_URL = 'https://downloads.example.org/centl/releases'
.\install.ps1 -Version 0.12.0
```

A custom release root requires an **explicit version**. CENTL does not require a
host to implement GitHub's `latest/download` redirect semantics. This keeps an
FCF/static host simple and makes the selected immutable version visible to the
operator.

Custom network roots must use HTTPS. `file://` roots are also accepted for local
static mirrors and hermetic/offline use. Plain HTTP is deliberately rejected
because an attacker able to replace both an archive and its adjacent checksum
would defeat checksum-only transport verification.

`--archive`/`-Archive` and a custom release root are mutually exclusive; choose
one source explicitly.

No FCF hostname is hard-coded in CENTL. The eventual public artifact host may
move without changing the installer or the cryptographic identity of preserved
release bytes. FCF can publish its verified `releases/` preservation subtree as a
static HTTPS hierarchy matching this contract.

The native installer currently verifies the adjacent release SHA-256 before
execution. Authenticated FCF release manifests (`SHA256SUMS` + `SHA256SUMS.sig`)
are a separate publisher-authentication layer documented in
[RELEASE-SIGNING.md](RELEASE-SIGNING.md); SHA-256 and signature authentication
remain distinct properties.

## Windows

Windows support is currently experimental and best-effort for CENTL-SCi. The
PowerShell installer still installs available native commands, validates them,
and adds its command directory to the user's PATH by default.

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/chasebryan/centl/main/install.ps1 -OutFile install.ps1
Get-Content .\install.ps1
Unblock-File .\install.ps1
.\install.ps1
```

When the package contains CENTL-SCi, the installer creates `centl-sci.cmd` and
runs the same exact-arithmetic `3/10` smoke test before activation. Open a new
terminal after PATH is changed, then run:

```powershell
centl-sci
```

Other options:

```powershell
.\install.ps1 -Version 0.12.0-rc.1
.\install.ps1 -Prefix "$HOME\Software\CENTL" -NoPath
```

The default Windows prefix is `%LOCALAPPDATA%\Programs\CENTL`.

## Offline archives

Keep an archive and its adjacent `.sha256` file together.

```sh
sh install --archive ./centl-linux-x86_64.tar.gz
sh install --archive ./centl-macos-arm64.tar.gz
```

```powershell
.\install.ps1 -Archive .\centl-windows-x86_64.zip
```

Offline installation performs the same checksum, staging, runtime, and command
smoke checks as a downloaded release.

For a directory containing multiple preserved versions, `file://` plus an
explicit version can also use the static release-root contract instead of naming
one archive manually.

## Optional semantic model

A semantic model is **not required** for the deterministic CENTL-SCi paths. Exact
arithmetic, admitted polynomial equations, spoken polynomial forms, and admitted
unit conversion can run immediately without model inference.

Model weights are intentionally separate from the native CENTL package and are
never silently downloaded by the installer. A configured local model may extend
language interpretation, but its output remains untrusted and must pass the
CENTL-SCi Problem IR boundary before CENTL or CENTL Physics performs any admitted
computation. See [SCI.md](SCI.md) for model configuration and the trust boundary.

## Release contract

Native packages built from the current release path contain:

- `centl`;
- `centl-physics`;
- `centl-sci`;
- private compatible runtime copies of FLINT, GMP, and MPFR where required;
- license texts, component source references, version metadata, and build
  identity metadata.

The current release matrix is:

- Linux x86_64, built against glibc 2.35;
- macOS x86_64 and arm64, targeting macOS 13 or newer;
- Windows x86_64, experimental/best-effort for CENTL-SCi.

FLINT, GMP, and MPFR are private to CENTL and never replace system libraries.
F* verifies and extracts the shared core once. Native release jobs then build
that exact output, run the test suite, package it, install the package into a
clean temporary prefix, and execute installed-binary smoke tests.

Archives contain complete license texts for bundled runtime components and an
exact source-reference file. The Windows executable statically links the native
math libraries, so the source-reference file also identifies the matching CENTL
source and build scripts needed for compatible rebuilding and relinking.

## Build from source

Source builds are for development and require the pinned toolchain. See
[ONBOARDING.md](ONBOARDING.md) and [CONTRIBUTING.md](../CONTRIBUTING.md).

```sh
scripts/bootstrap-opam
eval "$(opam env --switch=centl)"
make test
```

After a source build, the live interpreter can be run directly with:

```sh
dune exec centl-sci
```

Maintainers package an already-tested native build with:

```sh
make release VERSION=0.12.0-rc.1
```

```powershell
.\scripts\package-release.ps1 0.12.0-rc.1
```
