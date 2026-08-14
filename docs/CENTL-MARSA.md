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
| `scripts/marsa-bootstrap` | probe only | Homebrew flint/opam | MSYS2 MinGW flint |
| Native FLINT stubs | yes | in progress | in progress |
| Prebuilt installer | Oasis `linux-x86_64` | none | none |
| Oasis declaration | v0.14.0 only | no | no |

## How to inhabit the harbor

```sh
git clone https://github.com/chasebryan/centl.git
cd centl
git checkout CENTL-Marsa
sh scripts/marsa-bootstrap
make build
```

On Windows use MSYS2 MinGW64, not a generic Command Prompt, until a native
Windows installer exists.

## Branch rule

`CENTL-Marsa` is undeletable. It is not a fourth release product. Do not open
ordinary feature work here; land Camp work on `mirage` / `main` and replay
the harbor after the stay moves.
