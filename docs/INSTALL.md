# Install CENTL

CENTL has two GNU/Linux installation channels:

- **Oasis** is the qualified stable product and the recommended default.
- **Mirage** is the rolling development product. It begins from the current Oasis baseline and may contain newer experimental work that has not earned Oasis qualification.

The channels install independently and can coexist on the same machine.

CENTL currently supports **GNU/Linux x86_64** as its native release target. macOS and Windows are outside the active release promise.

## Quick install

Download the installer from the authoritative Oasis branch:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/oasis/install
sh install
```

When run interactively, the installer asks which channel to install:

```text
Choose a CENTL channel:
  1) Oasis  - qualified stable product (recommended)
  2) Mirage - development and experimental product
Selection [1]:
```

Press Enter for Oasis.

For scripts, CI, containers, or anyone who wants to be explicit:

```sh
sh install --channel oasis
sh install --channel mirage
```

A non-interactive invocation with no `--channel` defaults to Oasis.

## Installing both channels

The channels occupy separate version trees below the installation prefix.
Installing Mirage never replaces the stable Oasis commands.

Oasis installs these conventional commands:

```text
centl
centl-physics
centl-sci
```

It also provides explicit channel aliases:

```text
oasis-centl
oasis-centl-physics
oasis-centl-sci
```

Mirage uses separate commands:

```text
mirage-centl
mirage-centl-physics
mirage-centl-sci
```

Therefore installing both is simply:

```sh
sh install --channel oasis
sh install --channel mirage
```

The stable `centl`, `centl-physics`, and `centl-sci` aliases continue to point only to Oasis.

The project deliberately does **not** use `centl-mirage` as the Mirage-channel launcher. That name remains available for the CENTL-MIRAGE self-development system itself.

## Distribution model

The canonical GitHub release history begins at the first Oasis foundation release, `v0.14.0`.

Prebuilt channel bytes are served from the repository's machine-oriented `distribution` branch:

```text
channels/
  oasis/
    LATEST
    v0.14.0/
      centl-linux-x86_64.tar.gz
      centl-linux-x86_64.tar.gz.sha256
      SOURCE-COMMIT
  mirage/
    LATEST
    latest/
      centl-linux-x86_64.tar.gz
      centl-linux-x86_64.tar.gz.sha256
      SOURCE-COMMIT
      VERSION
    builds/
      <commit-sha>/
        centl-linux-x86_64.tar.gz
        centl-linux-x86_64.tar.gz.sha256
        SOURCE-COMMIT
        VERSION
```

Oasis directories contain immutable qualified release bytes. Mirage `latest` is a rolling development pointer while each published Mirage commit remains addressable under `builds/<commit-sha>/`.

This separates **release identity** from **artifact transport**. The immutable `v0.14.0` release remains the canonical Oasis foundation even though GitHub release immutability prevented adding assets after it was published.

## What the installer verifies

For both channels the installer:

1. requires GNU/Linux x86_64;
2. downloads the selected native package and adjacent SHA-256 file, or accepts an offline archive;
3. verifies the archive SHA-256 before extraction;
4. rejects unsafe archive paths and unsupported link/device/FIFO members;
5. stages the package away from the active installation;
6. requires the packaged `centl --version` identity to match its metadata;
7. smoke-tests exact physics conversion when CENTL Physics is present;
8. smoke-tests `centl-sci 'What is 0.1 plus 0.2?'` and requires `3/10`;
9. starts and exits the CENTL-SCi REPL and checks its identity;
10. atomically activates the selected channel; and
11. adds the command directory to the current user's shell profile when necessary unless `--no-path` is requested.

The default prefix is `~/.local`.

## Oasis

Install the latest qualified Oasis release:

```sh
sh install --channel oasis
```

Install a specific qualified Oasis version:

```sh
sh install --channel oasis --version 0.14.0
```

Start the scientific interface:

```sh
centl-sci
```

Or use the explicit channel name:

```sh
oasis-centl-sci
```

Basic checks:

```sh
centl '0.1 + 0.2'
centl 'solve(x^2 - 5*x + 6 = 0, x)'
centl verify --left '0.1 + 0.2' --relation equal --right '3/10'
centl-physics convert 100 cm m
```

Expected exact-first results include:

```text
3/10
x in {2, 3}
verdict: verified (closed_exact_rational via closed_rational_comparison); comparison=equal
1
```

## Mirage

Install the latest rolling Mirage build:

```sh
sh install --channel mirage
```

Start it with:

```sh
mirage-centl-sci
```

Mirage is intentionally not an Oasis claim. A successful Mirage package build establishes only that the development snapshot met the lighter installability baseline used to publish that snapshot. It does not promote the snapshot to the `oasis` branch or make it a stable release.

A specific published Mirage build may be selected by its commit SHA:

```sh
sh install --channel mirage --version <commit-sha>
```

## Offline archives

Keep a Linux archive and its adjacent `.sha256` file together:

```sh
sh install --channel oasis --archive ./centl-linux-x86_64.tar.gz
```

A Mirage archive can be installed independently:

```sh
sh install --channel mirage --archive ./centl-linux-x86_64.tar.gz
```

Offline installation performs the same checksum, archive-structure, staging, runtime, and command smoke checks.

## Alternate static release hosts

A custom Oasis-compatible release root may expose immutable version directories:

```text
RELEASE_ROOT/
  v0.14.0/
    centl-linux-x86_64.tar.gz
    centl-linux-x86_64.tar.gz.sha256
```

Install from it with an explicit version:

```sh
sh install \
  --channel oasis \
  --version 0.14.0 \
  --release-base-url https://downloads.example.org/centl/releases
```

The equivalent environment form is:

```sh
CENTL_RELEASE_BASE_URL=https://downloads.example.org/centl/releases \
  sh install --channel oasis --version 0.14.0
```

Custom network roots must use HTTPS. `file://` roots are accepted for local static mirrors and hermetic testing. Plain HTTP is rejected because replacing both an archive and its adjacent checksum would defeat checksum-only transport verification.

## Custom installation prefix

```sh
sh install --channel oasis --prefix "$HOME/software"
```

To prevent shell startup-file changes:

```sh
sh install --channel oasis --no-path
```

The installer prints the command directory that must then be added to `PATH` manually.

## Optional semantic model

A semantic model is **not required** for deterministic CENTL-SCi paths. Exact arithmetic, admitted polynomial equations, spoken polynomial forms, and admitted unit conversion can run without model inference.

Model weights remain separate from the native package and are never silently downloaded. A configured model may interpret intent, but its output is untrusted until it passes CENTL's typed and deterministic boundaries. See [SCI.md](SCI.md).

## Build from source

Source builds are for development and require the pinned Linux toolchain. See [ONBOARDING.md](ONBOARDING.md) and [CONTRIBUTING.md](../CONTRIBUTING.md).

```sh
scripts/bootstrap-opam
eval "$(opam env --switch=centl)"
make test
```

Run the live scientific interface directly with:

```sh
dune exec centl-sci
```

Maintainers package a tested Linux build with:

```sh
make release VERSION=0.14.0
```

Oasis publication must use the already-qualified bytes from the exact release SHA. Mirage publication is a separate rolling development channel and never substitutes for Oasis qualification.
