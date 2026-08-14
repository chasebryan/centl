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
| `scripts/marsa-bootstrap` | probe/reference only | Homebrew GMP/MPFR/FLINT/opam path | MSYS2 MinGW64 GMP/MPFR/FLINT path |
| `scripts/marsa-install` source-build path | reference platform does not need Marsa | yes | yes, from MSYS2 MinGW64 |
| `centl` / `centl-physics` / `centl-sci` public command intent | yes | yes | yes |
| Full product CI smoke | Oasis/release workflows | yes | not yet enabled |
| Oasis declaration | v0.15.0 Al-Nur | no | no |

The assurance distinction matters. macOS is built and smoke-tested as a Camp product in the Marsa workflow. Windows currently has the MSYS2/MinGW dependency and FLINT harbor gate, while the full Windows CENTL product job remains disabled until the OCaml/MinGW runtime and numeric-library toolchains are unified.

That does **not** create different mathematics or physics. Marsa exists so the same CENTL interfaces can be brought to those operating systems without falsely labeling the port as an Oasis-qualified release.

## macOS harbor installation 🍎

Homebrew is required.

```sh
git clone https://github.com/chasebryan/centl.git
cd centl
git checkout CENTL-Marsa
sh scripts/marsa-install
```

The bootstrap prepares GMP, MPFR, FLINT, `pkg-config`, and `opam` as needed, then the installer builds the Camp stay and installs:

```text
centl
centl-physics
centl-sci
```

The default prefix is `~/.local`.

## Windows harbor installation 🪟

Use an **MSYS2 MinGW64 shell**, not ordinary Command Prompt. Git and `opam` must be available in that environment.

```sh
git clone https://github.com/chasebryan/centl.git
cd centl
git checkout CENTL-Marsa
sh scripts/marsa-install
```

The Windows bootstrap uses `pacman` to prepare the MinGW GMP, MPFR, FLINT, GCC, make, `pkg-config`, and supporting build tools. The public commands are installed as Windows executables:

```text
centl.exe
centl-physics.exe
centl-sci.exe
```

The full Windows product CI gate is deliberately still disabled. A local Marsa build is therefore a harbor build, not evidence of Oasis qualification.

## Scientist onboarding

Scientists do not need to learn the branch or port architecture before using CENTL. Start from the field-specific guides instead:

- [🧮 📐 Mathematician onboarding](MATHEMATICIANS.md)
- [⚛️ 🔬 Physicist onboarding](PHYSICISTS.md)

Each guide begins with GNU/Linux, macOS, and Windows setup, then converges on the same scientific command surfaces.

## Branch rule

`CENTL-Marsa` is the long-lived Windows/macOS harbor. It is not a fourth release product. Ordinary feature work belongs on `mirage` / `main`; the harbor is replayed as the Camp stay moves.
