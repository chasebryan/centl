![Free Computation Foundation — FCF and camel banner](assets/branding/fcf-centl-banner.png)

# CENTL

Exact-first mathematics, physics, and scientific computation.

> Good maths should be free. Never manufacture mathematical certainty.

## Current release status

**CENTL v0.14.0 is an Oasis release.**

Oasis is the qualified stable product. It lives on the `oasis` branch.
A camp does not replace it, inherit it, or become it.

**FCF Camp #1** (`fcf-camp-001`) is the current stay. That is where the
newest software and designs are used. It lives on `main` and `mirage`.
It is not an Oasis declaration and not a SemVer product.

| Line | What it is |
| --- | --- |
| [`oasis`](https://github.com/chasebryan/centl/tree/oasis) | Qualified stable product. Install this for the published calculator. |
| [`main`](https://github.com/chasebryan/centl/tree/main) | Developer distribution and current Camp stay. |
| [`mirage`](https://github.com/chasebryan/centl/tree/mirage) | Laboratory. Installable. Never a full release. |

See [docs/OASIS.md](docs/OASIS.md) and
[FCF Camps](https://github.com/chasebryan/centl/blob/main/docs/FCF-CAMPS.md).

## Install the Oasis product

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

## Use the current Camp stay

Clone `main` (or `mirage` if you want the laboratory). That tree is
where current work is inhabited. Build and run from the checkout.
The camp notes are
[docs/releases/camp-001.md](https://github.com/chasebryan/centl/blob/main/docs/releases/camp-001.md).

## Commands

| Command | Use |
| --- | --- |
| `centl` | Exact calculator, language, verification, JSON, and MCP |
| `centl-physics` | Typed exact-first physics |
| `centl-sci` | Local scientific interpreter. Not a chatbot |

Exact values stay exact. Approximations carry justified bounds.
Unsupported work stays visible. The contract is
[docs/NUMERICS.md](docs/NUMERICS.md).

## Read next

- [Installation](docs/INSTALL.md)
- [Documentation index](docs/README.md)
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- Site: [freecomputation.org](https://freecomputation.org/)

## License

Software is Apache-2.0. Documentation is CC BY 4.0 where identified.
Branding is separate: [LICENSING.md](LICENSING.md).

Developed under the **Free Computation Foundation**.

> **Free for science.**
