![Free Computation Foundation — FCF and camel banner](assets/branding/fcf-centl-banner.png)

# CENTL

Exact-first mathematics, physics, and scientific computation.

> Good maths should be free. Never manufacture mathematical certainty.

## CENTL Marsa: install only what you need 🍎 🪟

This branch is the macOS and Windows harbor for the current Camp software. It supports component-selective installation:

```sh
# exact mathematics only
sh scripts/marsa-install --component centl

# typed physics only
sh scripts/marsa-install --component physics

# scientific interpreter only
sh scripts/marsa-install --component sci

# all three public commands
sh scripts/marsa-install --component all
```

A mathematician does not need to install Physics. A physicist does not need to install the mathematics CLI or SCi unless those surfaces are useful to their work.

Start with the field guides on `main` for the scientist-facing path:

- [🧮 📐 Mathematician onboarding](https://github.com/chasebryan/centl/blob/main/docs/MATHEMATICIANS.md)
- [⚛️ 🔬 Physicist onboarding](https://github.com/chasebryan/centl/blob/main/docs/PHYSICISTS.md)

Marsa builds from the shared source graph, so the checkout still contains shared build dependencies. The installed command surface is component-selective. GNU/Linux Oasis additionally publishes physically separate component archives so the download itself can be command-specific.

## Current release status

**CENTL v0.15.0 Al-Nur is the qualified Oasis release.** It lives on the `oasis` branch and is currently qualified for GNU/Linux x86_64.

**FCF Camp #1** (`fcf-camp-001`) is the current stay on `main` and `mirage`. `CENTL-Marsa` ports that Camp-stable software to macOS and Windows. Marsa is not an Oasis declaration and has no SemVer effect.

| Line | What it is |
| --- | --- |
| [`oasis`](https://github.com/chasebryan/centl/tree/oasis) | Qualified stable product. |
| [`main`](https://github.com/chasebryan/centl/tree/main) | Developer distribution and current Camp stay. |
| [`mirage`](https://github.com/chasebryan/centl/tree/mirage) | Laboratory. Installable. Never a full release. |
| [`CENTL-Marsa`](https://github.com/chasebryan/centl/tree/CENTL-Marsa) | macOS and Windows harbor of the Camp stay. |

See [CENTL Marsa documentation](https://github.com/chasebryan/centl/blob/main/docs/CENTL-MARSA.md) and [FCF Camps](https://github.com/chasebryan/centl/blob/main/docs/FCF-CAMPS.md).

## macOS

Homebrew is required. From this branch:

```sh
sh scripts/marsa-install --component centl      # mathematics only
sh scripts/marsa-install --component physics    # physics only
sh scripts/marsa-install --component sci        # SCi only
```

The macOS Camp product is built and smoke-tested in the Marsa workflow. It is not Oasis-qualified.

## Windows

Use an **MSYS2 MinGW64 shell**, not ordinary Command Prompt. Git and `opam` must be available in that environment.

```sh
sh scripts/marsa-install --component centl
sh scripts/marsa-install --component physics
sh scripts/marsa-install --component sci
```

The Windows dependency and FLINT harbor is CI-checked. The full Windows product CI job remains disabled until the OCaml/MinGW runtime and numeric-library toolchains are unified, so a successful Windows Marsa build is not an Oasis claim.

## Commands

| Command | Use |
| --- | --- |
| `centl` | Exact calculator, language, verification, JSON, and MCP |
| `centl-physics` | Typed exact-first physics |
| `centl-sci` | Local scientific interpreter. Not a chatbot |

Exact values stay exact. Approximations carry justified bounds. Unsupported work stays visible. The numerical contract is [docs/NUMERICS.md](docs/NUMERICS.md).

## License

Software is Apache-2.0. Documentation is CC BY 4.0 where identified. Branding is separate: [LICENSING.md](LICENSING.md).

Developed under the **Free Computation Foundation**.

> **Free for science.**
