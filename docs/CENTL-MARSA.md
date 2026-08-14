# CENTL Marsa

**Status:** harbor for the current Camp-stable software on macOS and Windows  
**SemVer effect:** none  
**Oasis assurance effect:** none

> Marsa is an anchorage. It is not an Oasis.

## What this line is

`CENTL-Marsa` is the long-lived harbor that ports the **current FCF Camp stay** to macOS and Windows. The software being ported is the inhabited Camp tree, not a new Oasis product.

- CENTL v0.15.0 **Al-Nur** on `oasis` is the qualified GNU/Linux x86_64 product.
- FCF Camp #1 on `main` / `mirage` is where the newest software and designs are inhabited on Linux.
- `CENTL-Marsa` takes the Camp-stable source and makes the same public CENTL surfaces available through the macOS and Windows harbor paths.

A successful Marsa build does not become Oasis. Three Horizons still requires independently qualified platform identities before a later three-platform Oasis declaration can exist.

## What is supported today

| Surface | GNU/Linux | Marsa macOS | Marsa Windows |
| --- | --- | --- | --- |
| Source checkout | yes | yes | yes |
| Qualified Oasis installer | yes, `linux-x86_64` | no | no |
| Component-only install | prebuilt component archives | source-build component selection | source-build component selection |
| `scripts/marsa-bootstrap` | probe/reference only | Homebrew GMP/MPFR/FLINT/opam path | MSYS2 MinGW64 GMP/MPFR/FLINT path |
| `centl` / `centl-physics` / `centl-sci` public command intent | yes | yes | yes |
| Full product CI smoke | Oasis/release workflows | yes | not yet enabled |
| Oasis declaration | v0.15.0 Al-Nur | no | no |

The assurance distinction matters. macOS is built and smoke-tested as a Camp product in the Marsa workflow. Windows currently has the MSYS2/MinGW dependency and FLINT harbor gate, while the full Windows CENTL product job remains disabled until the OCaml/MinGW runtime and numeric-library toolchains are unified.

That does **not** create different mathematics or physics. Marsa exists so the same CENTL interfaces can be brought to those operating systems without falsely labeling the port as an Oasis-qualified release.

## Install only what you need

Marsa accepts an explicit component selection:

```text
--component centl
--component physics
--component sci
--component all
```

The default remains `all` for compatibility. Scientists should normally select the smallest surface that matches their work.

| Component | Installs |
| --- | --- |
| `centl` | exact mathematics command only |
| `physics` | `centl-physics` only |
| `sci` | `centl-sci` only |
| `all` | all three public commands |

Marsa currently builds from CENTL's shared source graph. A component install therefore minimizes the **installed command surface**, while the source checkout still contains shared code required by the current build architecture. This is different from GNU/Linux Oasis, where command-only prebuilt archives let the download itself be component-specific.

## macOS harbor installation 🍎

Homebrew is required. Clone only the Marsa branch and avoid repository history you do not need:

```sh
git clone --filter=blob:none --single-branch --branch CENTL-Marsa https://github.com/chasebryan/centl.git
cd centl
```

Then choose exactly one surface, for example:

```sh
# mathematics only
sh scripts/marsa-install --component centl

# physics only
sh scripts/marsa-install --component physics

# interpreter only
sh scripts/marsa-install --component sci
```

Only use the complete install when you deliberately want everything:

```sh
sh scripts/marsa-install --component all
```

The bootstrap prepares GMP, MPFR, FLINT, `pkg-config`, and `opam` as needed. The default prefix is `~/.local`.

## Windows harbor installation 🪟

Use an **MSYS2 MinGW64 shell**, not ordinary Command Prompt. Git and `opam` must be available in that environment.

```sh
git clone --filter=blob:none --single-branch --branch CENTL-Marsa https://github.com/chasebryan/centl.git
cd centl
```

Choose only the command you need:

```sh
# mathematics only -> centl.exe
sh scripts/marsa-install --component centl

# physics only -> centl-physics.exe
sh scripts/marsa-install --component physics

# interpreter only -> centl-sci.exe
sh scripts/marsa-install --component sci
```

The Windows bootstrap uses `pacman` to prepare the MinGW GMP, MPFR, FLINT, GCC, make, `pkg-config`, and supporting build tools.

The full Windows product CI gate is deliberately still disabled. A local Marsa build is therefore a harbor build, not evidence of Oasis qualification.

## Scientist onboarding

Scientists do not need to learn the branch or port architecture before using CENTL. Start from the field-specific guides instead:

- [🧮 📐 Mathematician onboarding](MATHEMATICIANS.md)
- [⚛️ 🔬 Physicist onboarding](PHYSICISTS.md)

Each guide begins with **take only what you need**, then covers GNU/Linux, macOS, and Windows before converging on the same scientific command surfaces.

## Branch rule

`CENTL-Marsa` is the long-lived Windows/macOS harbor. It is not a fourth release product. Ordinary feature work belongs on `mirage` / `main`; the harbor is replayed as the Camp stay moves.
