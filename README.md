![Free Computation Foundation — FCF and camel banner](assets/branding/fcf-centl-banner.png)

# CENTL

Exact-first mathematics, physics, and scientific computation.

> Good maths should be free. Never manufacture mathematical certainty.

## Choose your field — and take only what you need

You do **not** need to learn, download, or install the whole CENTL product family before using CENTL for your science. Start with your field, then install only the scientific surface you actually want:

| Field | Start here | Smallest useful install |
| --- | --- | --- |
| 🧮 📐 **Mathematics** | **[Mathematician onboarding](docs/MATHEMATICIANS.md)** | `centl` only for formal pure mathematics; add `centl-sci` only if you want ordinary-language mathematics. |
| ⚛️ 🔬 **Physics** | **[Physicist onboarding](docs/PHYSICISTS.md)** | `centl-physics` only for direct typed physics; add `centl` and/or `centl-sci` only when you actually need them. |

**Both field guides cover 🐧 GNU/Linux, 🍎 macOS, and 🪟 Windows, and both begin with component-selective setup.**

On GNU/Linux x86_64, CENTL publishes separate component archives so the installer can download the requested command **without first downloading the full three-command bundle**:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install-component

# pure mathematics only
sh install-component --component centl

# typed physics only
sh install-component --component physics

# scientific interpreter only
sh install-component --component sci
```

The traditional complete bundle remains available for people who intentionally want everything. macOS and Windows use component-selective `CENTL-Marsa` source builds; the field guides give the exact commands and explain the current assurance boundary.

If you are here only to do mathematics or physics, those onboarding pages are your front door. Networking, release infrastructure, CARAVAN, and contributor systems can wait until you actually need them.

## Current release status

**CENTL v0.15.0 is an Oasis release.**

This Oasis is named **Al-Nur**. The canonical tag is `v0.15.0`. It
lives on the `oasis` branch. A camp does not replace it, inherit it,
or become it.

**FCF Camp #1** (`fcf-camp-001`) is the current stay. That is where the
newest software and designs are used. It lives on `main` and `mirage`.
It is not an Oasis declaration and not a SemVer product.

**CENTL Marsa** is the harbor that ports that Camp stay to macOS and
Windows. It is not Oasis.

| Line | What it is |
| --- | --- |
| [`oasis`](https://github.com/chasebryan/centl/tree/oasis) | Qualified stable product. Install this for the published calculator. |
| [`main`](https://github.com/chasebryan/centl/tree/main) | Developer distribution and current Camp stay. |
| [`mirage`](https://github.com/chasebryan/centl/tree/mirage) | Laboratory. Installable. Never a full release. |
| [`CENTL-Marsa`](https://github.com/chasebryan/centl/tree/CENTL-Marsa) | Windows and macOS harbor of the Camp stay. |

See [docs/OASIS.md](docs/OASIS.md), [CENTL Marsa](docs/CENTL-MARSA.md), and
[FCF Camps](https://github.com/chasebryan/centl/blob/main/docs/FCF-CAMPS.md).

## Install the complete Oasis product

Use this only when you actually want all three public commands:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/oasis/install
sh install
centl-sci
```

GNU/Linux x86_64. The installer checks the archive, then activates.
Details: [docs/INSTALL.md](docs/INSTALL.md).

```sh
centl '0.1 + 0.2'
centl-physics convert 100 cm m
```

For a smaller install, use the component installer above. For macOS and Windows installation, use the field-specific onboarding or [CENTL Marsa](docs/CENTL-MARSA.md).

## Use the current Camp stay

On GNU/Linux, clone `main` (or `mirage` if you want the laboratory). On macOS or Windows, use the `CENTL-Marsa` harbor for the current Camp software. The camp notes are
[docs/releases/camp-001.md](https://github.com/chasebryan/centl/blob/main/docs/releases/camp-001.md).

## Commands

| Command | Use |
| --- | --- |
| `centl` | Exact calculator, language, verification, JSON, and MCP |
| `centl-physics` | Typed exact-first physics |
| `centl-sci` | Local scientific interpreter. Not a chatbot |

Each public command can now be selected independently on the scientist-facing install paths. Exact values stay exact. Approximations carry justified bounds. Unsupported work stays visible. The contract is [docs/NUMERICS.md](docs/NUMERICS.md).

## Read next

- [🧮 📐 Mathematician onboarding](docs/MATHEMATICIANS.md)
- [⚛️ 🔬 Physicist onboarding](docs/PHYSICISTS.md)
- [Installation](docs/INSTALL.md)
- [CENTL Marsa](docs/CENTL-MARSA.md)
- [Documentation index](docs/README.md)
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- Site: [freecomputation.org](https://freecomputation.org/)

## License

Software is Apache-2.0. Documentation is CC BY 4.0 where identified.
Branding is separate: [LICENSING.md](LICENSING.md).

Developed under the **Free Computation Foundation**.

> **Free for science.**
