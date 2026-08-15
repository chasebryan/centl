# cbap.kernel

**CB-Advanced-Processing.** A C letter-targeting engine for Erdős–Straus.

It does **not** prove the conjecture. GREAT is not stored. Only LETTER
files are written.

Learned from [`../bb.kernel`](../bb.kernel) (the full menu) and
[`../CC.kernel`](../CC.kernel) (the hard-prime attack). Those kernels
still exist. This one hunts letters.

## Channels

| channel | name | job |
|---|---|---|
| **A** | ACQUIRE | Walk three CRT spectra of Mordell-hard primes, `n ≡ 1,121` / `169,289` / `361,529 (mod 840)`. |
| **B** | LOCK | Theorem layer plus `fab(a,b)` with `a,b ≤ 11`. A hit would have been GREAT — **drop it**. |
| **C** | TRACK | Two-target corridor and aligned NR shifts. A hit is dropped. |
| **D** | VERDICT | `LETTER = TRUE` only if A–C all miss. Then the letter is saved at once. |

A miss at B prints `TARGET IDENTIFIED`. A true letter prints
`TARGET COLLECTED` and writes `letters/L-<id>.md`. The journal
`letters/JOURNAL.md` is the growing list.

Letter numbers are the same `ES-LETTER-v1` SHA-256 names as bb.kernel.

## Commands

First session starts at **0**. Later sessions **resume**. `--random`
sets a random start only when there is no seed yet.

```sh
make
./cbap                 # go
./cbap go              # start at 0, or resume
./cbap go --random     # first session at a random n; later resumes
./cbap status
./cbap letters
./cbap solve 2521
./cbap self-test
```

From the CENTL root:

```sh
./centl es cbap
./centl es cbap go
./centl es cbap go --random
./centl es cbap letters
```

Ctrl+C stops after the current prime and writes the seed.

Letters live only in `cbap.kernel/letters/`. A finished hunt is not a
proof.
