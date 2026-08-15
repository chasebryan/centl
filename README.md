<p>
  <img src="assets/branding/fcf-centl-banner.png" alt="Free Computation Foundation — CENTL">
</p>

# CENTL

**Exact-first mathematics, physics, and scientific computation.**

*Good maths should be free.*  
*Never manufacture mathematical certainty.*

**Oasis v0.15.0 · Al-Nur** · [freecomputation.org](https://freecomputation.org/) · Apache-2.0

---

## What CENTL is

CENTL is a scientific computation system that refuses to pretend.

- Exact values stay exact. `0.1 + 0.2` is exactly `3/10`.
- Approximations always carry justified bounds.
- Unsupported work stays visible as residual expressions instead of being silently approximated or guessed.
- You can install only the surface you actually need.

```sh
centl '0.1 + 0.2'                 # → 3/10
centl 'approx(pi, 50)'            # justified digits only
centl-physics convert 100 cm m    # exact unit conversion
centl-sci                         # local scientific interpreter
```

---

## Install only what you need

You do **not** need the whole product.

| You want | Install |
| --- | --- |
| Pure formal mathematics | `centl` |
| Typed exact-first physics | `centl-physics` |
| Natural-language scientific interaction | `centl-sci` |
| Everything | full installer |

### GNU/Linux x86_64 (recommended)

```sh
# Single component
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install-component
sh install-component --component centl        # or physics / sci

# Full product
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/oasis/install
sh install
```

### macOS & Windows

Use the **CENTL-Marsa** harbor (current Camp software, not Oasis).  
See [docs/CENTL-MARSA.md](docs/CENTL-MARSA.md) or the field guides below.

---

## Field guides

| Field | Start here |
| --- | --- |
| Mathematics | **[Mathematician onboarding](docs/MATHEMATICIANS.md)** |
| Physics | **[Physicist onboarding](docs/PHYSICISTS.md)** |

Both guides cover all three platforms and begin with the smallest useful install.

---

## Current lines

| Line | What it is |
| --- | --- |
| [`oasis`](https://github.com/chasebryan/centl/tree/oasis) | Qualified stable product (v0.15.0 Al-Nur) |
| [`main`](https://github.com/chasebryan/centl/tree/main) | Current Camp stay + developer distribution |
| [`mirage`](https://github.com/chasebryan/centl/tree/mirage) | Laboratory |
| [`CENTL-Marsa`](https://github.com/chasebryan/centl/tree/CENTL-Marsa) | macOS / Windows harbor of the Camp stay |

A Camp is a stay. It is not an Oasis.  
Details: [Oasis](docs/OASIS.md) · [CENTL Marsa](docs/CENTL-MARSA.md) · [FCF Camps](docs/FCF-CAMPS.md)

---

## Research

The public research program is currently focused on **Erdős–Straus Type A/B witness depth and congruence shadow structure**.

### CBAP.kernel — letter targeting

**[cbap.kernel](research/erdos-straus/cbap.kernel/README.md)** (CB-Advanced-Processing) is the letter-only C engine. Three CRT spectra feed channels A/B/C; channel D sets `LETTER = TRUE` or drops the prime. GREAT is not stored.

```sh
make -C research/erdos-straus/cbap.kernel
./centl es cbap              # start at 0, later resume
./centl es cbap go --random  # first session at a random n; later resume
./centl es cbap letters      # journal of TARGET COLLECTED
```

Letters are written at once to `research/erdos-straus/cbap.kernel/letters/`.

The older hunt still exists if you want GOOD/GREAT as well:

```sh
./centl es go --letters-only --random   # start a random letters-only hunt
./centl es go                           # resume the default hunt
./centl es go --from 0                  # start another hunt at the origin
./centl es go --all                     # file GOOD, GREAT, and LETTER
./centl es hunts                        # list hunts on this machine
```

A finished hunt is not a proof of the conjecture.  
Public library (static HTML, no JavaScript): [freecomputation.org/research.html](https://freecomputation.org/research.html)

| Resource | What it is |
| --- | --- |
| [CBAP.kernel](research/erdos-straus/cbap.kernel/README.md) | Letter targeting, C |
| [Research library](https://freecomputation.org/research.html) | Hosted papers, certificates, and Wellspring candidates |
| [Erdős–Straus program](https://freecomputation.org/research-erdos-straus.html) | Program overview |
| [Hunt record](research/erdos-straus/ES-HUNT.md) | Operator-facing hunt (bb + CC) |

---

## Documentation

| Document | When |
| --- | --- |
| [Mathematician onboarding](docs/MATHEMATICIANS.md) | Mathematics |
| [Physicist onboarding](docs/PHYSICISTS.md) | Physics |
| [Installation](docs/INSTALL.md) | Full install details |
| [Numerical contract](docs/NUMERICS.md) | Exactness rules |
| [Documentation index](docs/README.md) | Everything else |
| [Contributing](CONTRIBUTING.md) | How to send work |
| [Security](SECURITY.md) | How to report problems |

---

## License

Software is **Apache-2.0**.  
Documentation is **CC BY 4.0** where identified.  
Branding is separate: [LICENSING.md](LICENSING.md).

Developed under the **Free Computation Foundation**.

**Free for science.**
