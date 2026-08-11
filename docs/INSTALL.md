# Install CENTL

The native release is the recommended way to use CENTL. It contains the CENTL,
CENTL Physics, and CENTL-SCi executables together with their required native math
libraries. F*, OPAM, OCaml, Dune, a C compiler, GMP, MPFR, FLINT, and development
headers are not required on the user's machine.

CENTL currently supports **GNU/Linux only**. Linux is the reference development,
validation, packaging, installer, and release platform for CENTL-SCi and the
Caramels series. macOS and Windows are unsupported and are not release-blocking
targets.

The public release line is `CENTL OASIS`. `CENTL MIRAGE` is the experimental
development line. Feature names such as `CENTL-SCi`, `Caramels+`, and
`CENTL-CARAVAN` remain subsystem names under the CENTL umbrella.

## Linux

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install
sh install
```

The installer:

1. requires GNU/Linux and the supported Linux architecture;
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

A Caramels CENTL-SCi package should begin:

```text
CENTL-SCi v0.0.2-Caramels+
Free for science.

>
```

Additional installer options:

```sh
sh install --version 0.13.0
sh install --prefix "$HOME/software"
sh install --no-path
```

`--no-path` leaves shell startup files untouched. The installer will print the
exact command directory that must be added manually.

## FCF or other static release hosts

GitHub Releases remains the default network source for compatibility, but the
Linux installer does not require GitHub's URL layout.

A host-neutral release root may expose the same immutable version directories
that FCF preservation uses:

```text
RELEASE_ROOT/
  v0.13.0/
    centl-linux-x86_64.tar.gz
    centl-linux-x86_64.tar.gz.sha256
```

The URL contract is:

```text
<release-base-url>/v<VERSION>/<asset>
<release-base-url>/v<VERSION>/<asset>.sha256
```

Example:

```sh
sh install \
  --version 0.13.0 \
  --release-base-url https://downloads.example.org/centl/releases
```

The equivalent environment form is:

```sh
CENTL_RELEASE_BASE_URL=https://downloads.example.org/centl/releases \
  sh install --version 0.13.0
```

A custom release root requires an **explicit version**. CENTL does not require a
host to implement GitHub's `latest/download` redirect semantics. This keeps an
FCF/static host simple and makes the selected immutable version visible to the
operator.

Custom network roots must use HTTPS. `file://` roots are also accepted for local
static mirrors and hermetic/offline use. Plain HTTP is deliberately rejected
because an attacker able to replace both an archive and its adjacent checksum
would defeat checksum-only transport verification.

`--archive` and a custom release root are mutually exclusive; choose one source
explicitly.

No FCF hostname is hard-coded in CENTL. The eventual public artifact host may
move without changing the installer or the cryptographic identity of preserved
release bytes. FCF can publish its verified `releases/` preservation subtree as a
static HTTPS hierarchy matching this contract.

The native installer currently verifies the adjacent release SHA-256 before
execution. Authenticated FCF release manifests (`SHA256SUMS` + `SHA256SUMS.sig`)
are a separate publisher-authentication layer documented in
[RELEASE-SIGNING.md](RELEASE-SIGNING.md); SHA-256 and signature authentication
remain distinct properties.

## Unsupported operating systems

macOS and Windows are currently unsupported. Existing portable code, historical
packaging scripts, or installers may remain in the repository where removing
them would add churn without improving the Linux implementation, but they carry
no compatibility or release promise and are not part of the Caramels acceptance
gate. The Unix installer rejects macOS explicitly. See
[SCI_PLATFORM_SUPPORT.md](SCI_PLATFORM_SUPPORT.md) for the policy.

## Offline archives

Keep a Linux archive and its adjacent `.sha256` file together.

```sh
sh install --archive ./centl-linux-x86_64.tar.gz
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

The current release vocabulary is:

- `CENTL` for the product umbrella;
- `OASIS` for the stable release line;
- `MIRAGE` for the experimental line.

Native packages built from the current release path contain:

- `centl`;
- `centl-physics`;
- `centl-sci`;
- private compatible runtime copies of FLINT, GMP, and MPFR where required;
- license texts, component source references, version metadata, and build
  identity metadata.

The supported release matrix is currently:

- **GNU/Linux x86_64**, built against the project's declared Linux runtime
  baseline.

FLINT, GMP, and MPFR are private to CENTL and never replace system libraries.
F* verifies and extracts the shared core once. Native release jobs then build
that exact output, run the test suite, package it, install the package into a
clean temporary prefix, and execute installed-binary smoke tests.

Archives contain complete license texts for bundled runtime components and an
exact source-reference file.

## Build from source

Source builds are for development and require the pinned toolchain on Linux. See
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

Maintainers package an already-tested native Linux build with:

```sh
make release VERSION=0.13.0
```
