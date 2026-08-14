# CENTL Marsa

**Status:** harbor for the Camp-stable software on macOS and Windows
**SemVer effect:** none
**Oasis assurance effect:** none

> Marsa is an anchorage. It is not an Oasis.

## What this line is

`CENTL-Marsa` is the long-lived harbor that ports the **current FCF Camp stay**
to macOS and Windows. The software being ported is the inhabited Camp tree,
not a new Oasis product.

- CENTL v0.14.0 on `oasis` remains the qualified GNU/Linux product.
- FCF Camp #1 on `main` / `mirage` remains where newest designs are used on
  Linux.
- `CENTL-Marsa` takes that camp-stable source and makes it build and run on
  macOS and Windows.

A successful Marsa build does not become Oasis. Three Horizons still requires
an independently qualified Oasis identity for a later three-platform release.

## What is supported today

| Surface | Linux Camp | Marsa macOS | Marsa Windows |
| --- | --- | --- | --- |
| Source checkout | yes | yes | yes |
| Harbor bootstrap | probe | Homebrew flint + flags | MSYS2 MinGW flint + flags |
| `make marsa-build` | yes, no F* required | yes | yes |
| `scripts/marsa-install` | not the Linux path | source install | source install in a Unix shell |
| Public commands | `centl`, `centl-physics`, `centl-sci` | same after harbor install | same after harbor install |
| Prebuilt Oasis archive | `linux-x86_64` | none | none |
| Oasis declaration | v0.14.0 only | no | no |

F* re-extraction is not required. Marsa builds the committed generated core.

## How to inhabit the harbor

```sh
git clone https://github.com/chasebryan/centl.git
cd centl
git checkout CENTL-Marsa
sh scripts/marsa-install
```

That installs `centl`, `centl-physics`, and `centl-sci` under `~/.local/bin`
by default. `./install` in this tree does the same on macOS and Windows.

On Windows use MSYS2 MinGW64 or another Unix shell with opam. A generic
Command Prompt is not the harbor path yet.

Then:

```sh
centl '0.1 + 0.2'
centl-physics convert 100 cm m
centl-sci
```

## Branch rule

`CENTL-Marsa` is undeletable. It is not a fourth release product. Do not open
ordinary feature work here; land Camp work on `mirage` / `main` and replay
the harbor after the stay moves.
