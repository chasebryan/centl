# cbis.kernel

**CB Inverse Sieve.** The ES+ engine. Entirely C.

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

## Commands

```sh
make
./cbis                     # sweep + home, start 0, then resume
./cbis go --random
./cbis go --home-only      # missile only
./cbis go --sweep-only     # 0-to-infinity only
./cbis go --k-max 400 --step 50000
./cbis go --scroll            # line log instead of the panel
./cbis status
./cbis letters
./cbis solve 2521
```

From the CENTL root:

```sh
./centl es cbis
./centl es cbis go --home-only
./centl es cbis letters
```

On a terminal the hunt is a fixed color panel. Cursors, rates, the
spectrum×lane window, and the last five events update in place. It
does not scroll. `NO_COLOR` or `TERM=dumb` turns the color off.
`--scroll` is the old line log (also what you get when stdout is not
a TTY).

Ctrl+C saves both cursors (`scanned_through` and `home_S`).
Letters: `cbis.kernel/letters/`.
