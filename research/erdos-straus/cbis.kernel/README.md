# cbis.kernel

**CB Inverse Sieve.** The ES+ letter engine. The live W/I/N/L cover is C; the
model-escape observer uses exact Python integers so arbitrary witness
denominators are not truncated to a machine word. **1.2.0** is the current
released cover engine ([release](https://github.com/chasebryan/centl/releases/tag/cbis-1.2.0)); the model-escape work is unreleased on this branch.

One process, two walks, one cover.

1. **Sweep** — from 0 (or the saved cursor). Spectra A/B/C by lanes W, I, N, L.
2. **Home** — only the residual R, where a window-layer letter can sit.

W is not weakened. Letters keep the same `ES-LETTER-v1` numbers.

[![cbis.kernel live color panel](../../../site/assets/cbis-kernel-esp-demo.jpg)](https://freecomputation.org/assets/cbis-kernel-esp-demo.mp4)

[Watch the live panel (2:35)](https://freecomputation.org/assets/cbis-kernel-esp-demo.mp4)

## R

    R = { hard p : p+4 and 4p+1 have only prime factors ≡ 1 (mod 4) }

About 27% of hard primes through 10^8. Every W-survivor must lie here.
Homing walks S = p+4 through Sigma_1, sets p = S-4, and never spends
time on linear 4p+1 / p+4 hits.

Equation: [`../ES-plus/HOMING.md`](../ES-plus/HOMING.md).

## Matrix (sweep)

| lane | source | marks |
| --- | --- | --- |
| W | bb / CC window | 4p+1, p+4, then fab on R |
| I | ES+ signed box | survivors of W |
| N | CC / cbap NR | aligned nonresidue shifts |
| L | Type A/B | López prime-modulus traps |

Dashboard splits W into `linear / R / fab`.

## Type A/B is a model, not a kernel axiom

`cbis.kernel` does **not** assume that Type A/B is complete. Lane L is a
useful Type A/B sub-cover: it tests the prime-modulus López traps. The
separate `cbis-audit` executable is deliberately outside the cover and
checks the stronger bounded question:

> Has this prime got any Type A/B witness through K, allowing every
> modulus `4k-1`, prime or composite?

```sh
./cbis-audit 9658489 --k-max 400
./cbis-audit 9658489 --k-max 3000
```

The first command must report `ab_unseen_through_K=true`. The second must
recover the known minimal Type B witness at `k=2622`, `d=69`, `n=38`.
That pair is the canonical guard against the finite-depth fallacy.

The audit is observational only:

- it never marks the W/I/N/L cover;
- it never changes an `ES-LETTER-v1` identity;
- it never writes a letter or advances either cursor;
- `A/B unseen through K` must never be promoted to `no A/B witness`.

## General model-escape observer

`cbis_escape.py` attacks the full Erdős–Straus equation without assuming a
Type A/B parametrization.

For ordered denominators `x <= y <= z`, every solution has

    floor(p/4)+1 <= x <= floor(3p/4).

For each `x`, write the exact remainder as

    a/b = 4/p - 1/x.

Then

    1/y + 1/z = a/b

is equivalent to

    (a y - b)(a z - b) = b^2.

The observer factors `b^2`, enumerates the admissible divisor pairs, and
verifies every emitted decomposition again by exact integer cross
multiplication. This search is complete for each visited `x`; `--complete`
requests the entire canonical x-domain.

```sh
python3 cbis_escape.py 9658489 --ab-k 400 --x-count 8
python3 cbis_escape.py 9658489 --ab-k 3000 --x-count 8
python3 cbis_escape.py 9658489 --ab-k 400 --x-count 8 --record
python3 cbis_escape.py letters --ab-k 400 --x-count 10000 --limit 20 --record
```

At `K=400`, the regression prime has no A/B witness through the audit bound,
but the general observer finds and exactly verifies:

    4/9658489
      = 1/2414624
      + 1/3331659906339
      + 1/62813018687490942976992

That is a **bounded model-escape candidate**, not a refutation of Type A/B.
At `K=3000`, the same prime is correctly reclassified as
`AB_EXPLAINED_THROUGH_K` because its Type B witness at `k=2622` is now in
range.

### Evidence

`--record` writes only verified general witnesses for which A/B is still
unseen through the recorded finite K. Records are content-addressed under
[`evidence/`](evidence/) using schema `ES-MODEL-ESCAPE-v1`.

If the compiled C audit is present, the Python observer independently
recomputes Type A/B and compares the two implementations. It refuses to
record evidence if they disagree.

A complete no-witness search is deliberately **not** auto-recorded as an
Erdős–Straus counterexample. Such a result requires an independent verifier
and certificate review before any claim.

Design contract: [`MODEL-ESCAPE.md`](MODEL-ESCAPE.md).

## Commands

```sh
make
make check
./cbis                     # sweep + home, start 0, then resume
./cbis go --random
./cbis go --home-only      # missile only
./cbis go --sweep-only     # 0-to-infinity only
./cbis go --k-max 400 --step 50000
./cbis go --scroll         # line log instead of the panel
./cbis status
./cbis letters
./cbis solve 2521
./cbis-audit 2521 --k-max 400
python3 cbis_escape.py 2521 --ab-k 400 --x-count 10000
```

From the CENTL root, the released cover driver remains:

```sh
./centl es cbis
./centl es cbis go --home-only
./centl es cbis letters
```

The audit and model-escape observer are kept as sidecars on this integration
branch so concurrent development of the live `cbis` cover can continue
without changing its command semantics or letter identity.

On a terminal the hunt is a fixed color panel. Cursors, rates, the
spectrum×lane window, and the last five events update in place. It
does not scroll. `NO_COLOR` or `TERM=dumb` turns the color off.
`--scroll` is the old line log (also what you get when stdout is not
a TTY).

Ctrl+C saves both cursors (`scanned_through` and `home_S`).
Letters: `cbis.kernel/letters/`.
