# Install CENTL

CENTL has two GNU/Linux installation channels:

- **Oasis** is the qualified stable product and the recommended default.
- **Mirage** is the rolling development product. It begins from the current Oasis baseline and may contain newer experimental work that has not earned Oasis qualification.

The channels install independently and can coexist on the same machine.

CENTL's qualified native release target is currently **GNU/Linux x86_64**. macOS and Windows use the current Camp software through [CENTL Marsa](CENTL-MARSA.md); those ports are not Oasis declarations.

## Install only what you need

The full CENTL bundle is convenient, but it is not mandatory.

If you want exactly one public scientific command on GNU/Linux x86_64, use the component installer:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install-component
```

Then choose one component:

```sh
# exact mathematics only
sh install-component --component centl

# typed exact-first physics only
sh install-component --component physics

# CENTL-SCi interpreter only
sh install-component --component sci
```

The Oasis component installer downloads a **component-specific archive**. It does not first download the full three-command product and discard the commands you did not ask for.

Each component archive contains only the selected public launcher/executable plus the shared runtime libraries, license material, and provenance metadata required to run and redistribute it correctly. It does not contain the other two public command executables.

Typical scientist choices are:

| Need | Install |
| --- | --- |
| Pure formal mathematics | `--component centl` |
| Typed physics only | `--component physics` |
| Natural-language scientific interaction only | `--component sci` |
| Mathematics + SCi, no Physics command | install `centl`, then `sci` |
| Physics + direct mathematics, no SCi | install `physics`, then `centl` |
| Everything | use the full installer below |

For field-specific guidance, start with [🧮 📐 Mathematician onboarding](MATHEMATICIANS.md) or [⚛️ 🔬 Physicist onboarding](PHYSICISTS.md).

On macOS and Windows, `CENTL-Marsa` provides the same installed-command selection through:

```sh
sh scripts/marsa-install --component centl
sh scripts/marsa-install --component physics
sh scripts/marsa-install --component sci
```

Marsa currently builds from the shared source graph, so its source checkout still contains shared build code. Its **installed command surface** is selective. See [CENTL Marsa](CENTL-MARSA.md).

## Quick full install

Use the ordinary installer when you intentionally want the complete GNU/Linux product bundle:

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

The channels occupy separate version trees below the installation prefix. Installing Mirage never replaces the stable Oasis commands.

The complete Oasis bundle installs these conventional commands:

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

Mirage uses separate commands when a rolling Mirage package is available:

```text
mirage-centl
mirage-centl-physics
mirage-centl-sci
```

The project deliberately does **not** use `centl-mirage` as the Mirage-channel launcher. That name remains available for the CENTL-MIRAGE self-development system itself.

## Distribution model

The canonical GitHub release history begins at the first Oasis foundation release, `v0.14.0`.

Prebuilt channel bytes are served from the repository's machine-oriented `distribution` branch. An Oasis version directory contains the complete bundle and command-selective derivatives:

```text
channels/
  oasis/
    LATEST
    v0.15.0/
      centl-linux-x86_64.tar.gz
      centl-linux-x86_64.tar.gz.sha256

      centl-only-linux-x86_64.tar.gz
      centl-only-linux-x86_64.tar.gz.sha256

      centl-physics-only-linux-x86_64.tar.gz
      centl-physics-only-linux-x86_64.tar.gz.sha256

      centl-sci-only-linux-x86_64.tar.gz
      centl-sci-only-linux-x86_64.tar.gz.sha256

      SOURCE-COMMIT
```

The command-selective archives are mechanically derived from the already-published aggregate package without rebuilding or modifying the selected executable bytes. Each records the source aggregate and its SHA-256 identity. CI verifies that each archive contains its requested public executable and none of the other two public executables, then smoke-installs each component independently.

When a Mirage aggregate package is published, the component-distribution workflow is designed to derive the same command-selective shapes for that rolling build. Mirage remains a development channel and never inherits Oasis assurance merely from packaging.

This separates **release identity**, **artifact transport**, and **component choice**. `LATEST` currently names **v0.15.0 Al-Nur**. The immutable `v0.14.0` Al-Khayma bytes remain on the channel as the previous Oasis.

## What the full installer verifies

For the complete package, the installer:

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

## What the component installer verifies

For a command-selective archive, `install-component`:

1. requires GNU/Linux x86_64;
2. downloads only the archive named for the requested component and its adjacent SHA-256 file, or accepts an offline component archive;
3. verifies the checksum before extraction;
4. rejects unsafe or unexpected archive paths;
5. requires an explicit component identity;
6. requires the selected launcher and executable to exist;
7. rejects an archive containing either of the other public command executables;
8. smoke-tests the requested command using a domain-appropriate exact operation; and
9. installs the component independently under the chosen prefix.

Installing a second component later does not require reinstalling the first.

## Oasis

Install the latest qualified complete Oasis release:

```sh
sh install --channel oasis
```

Install a specific qualified complete Oasis version:

```sh
sh install --channel oasis --version 0.15.0
```

Or install only one Oasis command:

```sh
sh install-component --component centl
sh install-component --component physics
sh install-component --component sci
```

Basic checks:

```sh
centl '0.1 + 0.2'
centl 'solve(x^2 - 5*x + 6 = 0, x)'
centl verify --left '0.1 + 0.2' --relation equal --right '3/10'
centl-physics convert 100 cm m
```

Run only the checks for commands you actually installed.

Expected exact-first results include:

```text
3/10
x in {2, 3}
verdict: verified (closed_exact_rational via closed_rational_comparison); comparison=equal
1
```

## Mirage

Install the latest rolling Mirage aggregate build when one is published:

```sh
sh install --channel mirage
```

Mirage is intentionally not an Oasis claim. A successful Mirage package build establishes only that the development snapshot met the lighter installability baseline used to publish that snapshot. It does not promote the snapshot to the `oasis` branch or make it a stable release.

A specific published Mirage build may be selected by its commit SHA:

```sh
sh install --channel mirage --version <commit-sha>
```

## Offline archives

Keep an archive and its adjacent `.sha256` file together.

Complete Oasis bundle:

```sh
sh install --channel oasis --archive ./centl-linux-x86_64.tar.gz
```

A component can also be installed offline without the other command archives:

```sh
sh install-component --component centl \
  --archive ./centl-only-linux-x86_64.tar.gz

sh install-component --component physics \
  --archive ./centl-physics-only-linux-x86_64.tar.gz

sh install-component --component sci \
  --archive ./centl-sci-only-linux-x86_64.tar.gz
```

## Alternate static release hosts

A custom full-bundle Oasis-compatible release root may expose immutable version directories:

```text
RELEASE_ROOT/
  v0.15.0/
    centl-linux-x86_64.tar.gz
    centl-linux-x86_64.tar.gz.sha256
```

Install from it with an explicit version:

```sh
sh install \
  --channel oasis \
  --version 0.15.0 \
  --release-base-url https://downloads.example.org/centl/releases
```

The equivalent environment form is:

```sh
CENTL_RELEASE_BASE_URL=https://downloads.example.org/centl/releases \
  sh install --channel oasis --version 0.15.0
```

Custom network roots must use HTTPS. `file://` roots are accepted for local static mirrors and hermetic testing. Plain HTTP is rejected because replacing both an archive and its adjacent checksum would defeat checksum-only transport verification.

## Custom installation prefix

For the full installer:

```sh
sh install --channel oasis --prefix "$HOME/software"
```

For a component:

```sh
sh install-component --component centl --prefix "$HOME/software"
```

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
make release VERSION=0.15.0
```

Oasis publication must use the already-qualified bytes from the exact release SHA. Component archives are transport derivatives of those published bytes, not new release identities. Mirage publication is a separate rolling development channel and never substitutes for Oasis qualification.
