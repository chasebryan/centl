# cbx2.kernel

**CB Formulation 2.** A separate ES+ kernel. Entirely C. Version **0.1.0**.

This directory is new. It does not replace:

- `cbis.kernel 1.2.0` — production letter hunt on `main`
- `cbx.kernel` — X-ray / multi-orientation research suite on PR #230

Formulation: [`FORMULATION.md`](FORMULATION.md).

## What it does

One process, four steps, one letter identity.

1. **Construct I** — `k → C → p = 4C−k` with `C ≡ (h+k)/4 (mod 210)`.
2. **X-ray** — measure W, N, L independently on every hard prime (a W-hit does not hide I/N/L).
3. **Verdict** — stacked `W → I → N → L`. LETTER only if all miss. Same `ES-LETTER-v1`.
4. **Home** — only residual R, as in cbis.

Finite grade `Γ = (F, K_I, E_N, A_L)`, default `(11, 400, 300, 400)`.

Factorization is Pollard–rho (the cbx 0.1.0 arithmetic, not the cbis trial-factor fallback).

## Commands

```sh
make
./cbx2                     # construct + xray + home, start 0, then resume
./cbx2 go --random
./cbx2 go --home-only
./cbx2 go --sweep-only
./cbx2 probe 2521
./cbx2 verify --hi 100000 --i-max 80
./cbx2 status
./cbx2 letters
```

From the CENTL root (after this branch is present):

```sh
./centl es cbx2
./centl es cbx2 verify --hi 3000 --i-max 80
```

On a TTY the hunt is a fixed color panel. `--scroll` or a pipe is a line log.
Ctrl+C saves both cursors. Letters: `cbx2.kernel/letters/`.

State lives only under this directory. It never reads or writes `cbis.kernel/` or `cbx.kernel/`.

## Claim boundary

Erdős–Straus remains open. A letter is not a counterexample. Inverse/recognition
agreement on a finite interval is a software check, not a new theorem.
