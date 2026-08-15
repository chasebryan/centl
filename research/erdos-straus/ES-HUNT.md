# Public Erdős–Straus hunt

**Status:** operational public hunt; not a proof  
**Date:** 2026-08-15  
**Depends on:** `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `FAB-COPRIME-DIVISOR-CRITERION.md`, `HARD-SMOOTH-TYPEII-OBSTRUCTION.md`  
**Claim boundary:** a cleared window is a finite certificate for those primes only. Letter numbers identify findings. Neither a finished hunt nor a pile of letters proves or disproves Erdős–Straus.

---

## 1. What this is

The conjecture asks whether every integer \(n \ge 2\) has a solution of

\[
\frac{4}{n} = \frac{1}{x} + \frac{1}{y} + \frac{1}{z}
\]

in positive integers. The remaining computational burden, after the classical identities, lives on Mordell-hard primes: those congruent to

\[
1,\ 121,\ 169,\ 289,\ 361,\ 529 \pmod{840}.
\]

This note records the public hunt that attacks those primes, files readable findings, and can be resumed on any machine. It is the operator-facing surface of the same two-target mathematics used in the theorem notes. It is not a new existence theorem.

From the CENTL root:

```text
./centl es
./centl es go
./centl es go --random
./centl es letters
./centl es seed
```

`./centl es` opens a menu. `go` is the infinite hunt. Ctrl+C stops it and saves the seed.

GREAT and GOOD records are a compact ledger, not hundreds of thousands of files. They are **not** in a git clone. Fetch them, compact an old pile, or hunt letters only:

```text
./centl es fetch
./centl es compact
./centl es go --all
./centl es go --letters-only
```

---

## 2. Two kernels

The work is split so a mathematician can read one stack and a long hunt can run the other.

| name | job |
|---|---|
| [`bb.kernel`](bb.kernel) (also `B-BervigES.kernel`) | Python reference. Full construction menu, exact integer check \(4xyz = n(yz+xz+xy)\), findings librarian, seed, live menu. |
| [`CC.kernel`](CC.kernel) | C attack engine. Theorem layer, \(a,b\le 11\) window, then the two-target corridor. Emits an explicit witness or reports a miss. |

CC.kernel is the theorem/attack provider. bb.kernel is the coupled reference. Either can be invoked from `centl es`. Neither uses CENTL-SCi. `strike` in the CC ledger stays false until a universal certificate is deposited in [`CC.kernel/PROOF.md`](CC.kernel/PROOF.md).

---

## 3. The infinite equation

Let \(s\) be the integer `scanned_through` in [`findings/seeds/current.json`](findings/seeds/README.md), and let \(\Delta\) be the window width (default \(50\,000\)). The hunt is

\[
W_i = (s + i\Delta,\ s + (i+1)\Delta],
\qquad i = 0,1,2,\ldots
\]

with no last interval. \(s\) begins at the **start factor**: \(0\), a bound the operator types, or a random integer in \([10^6, 10^{10})\). After each window, \(s\) advances. Ctrl+C writes \(s\). The next `go` starts at \(s\), never at \(0\).

`cleared_through` is the last bound for which every Mordell-hard prime has a checked witness. It lags \(s\) if an unsolved letter was continued past.

The engine walks the six hard residue classes and tests primality directly. There is no prefix-sieve cap at \(50\) million.

Letters are collected. The hunt does not stop on the first letter.

---

## 4. Start factor

A start factor chooses *where* a hunt begins. It is stored with the seed and does not change for that hunt.

```text
./centl es go              # resume the default hunt
./centl es go --from 0     # another hunt beginning at the origin
./centl es go --origin     # same as --from 0
./centl es go 0            # same as --from 0
./centl es go --from N     # another hunt beginning at any chosen N
./centl es go N            # same as --from N (0, 1000, 2e9, 20_000_000_000)
./centl es go --random     # another hunt, random stretch; does not replace the first
./centl es go --hunt NAME  # resume a named hunt
./centl es hunts           # list every hunt cursor in this tree
```

`--from` and `--random` used to overwrite the only seed file. They no longer do. Each hunt keeps its own cursor under `findings/seeds/`. Two `go` processes on the same hunt become siblings and claim distinct windows on that line.

**Two hunts on one machine:** each named hunt has its own lane. `main` and `h-0` must not share a cursor. A bug briefly put `main` on `lane-0`, so starting `h-0` jumped to five billion and looked frozen. That is fixed: `h-0` continues from its own `scanned_through`. Two `go` processes on the *same* named hunt still split windows. You can also run only `./centl es go` and ignore siblings. Not a proof of the conjecture.

Two people who begin at different start factors explore different stretches of the line. That is the only role of the factor. It is not part of a letter's identity.

---

## 5. Letter numbers

A worldwide serial (`Letter #1`, `Letter #2` in discovery order) cannot be the same on two machines without a shared counter.

A content-addressed number can. The letter number is the first \(128\) bits of SHA-256 of this exact UTF-8 text:

```text
ES-LETTER-v1
rule=<unsolved_after_search | window_broken | universal_strike>
n=<the prime, or 0>
extra=<empty, or a hash of a claimed certificate>
```

Anyone who finds the same rule at the same prime computes the same integer and the same file name `letters/L-<32 hex chars>.md`. The start factor, the clock, and the hostname are not in the key.

Different primes, or a different rule on the same prime, receive different numbers.

The three letter rules are mechanical. They are written in [`findings/HOW-GRADES-WORK.md`](findings/HOW-GRADES-WORK.md).

| stamp | meaning |
|---|---|
| GOOD | A checked hard identity that is not a routine small-shift hit. |
| GREAT | Escaped the small theorems, Type I only, or a deep first hit. Stored as one line in `findings/great.jsonl`. A cleared bound is the running `max_cleared_bound`, not a new row. |
| LETTER | Unsolved after the full menu, \(a,b\le 11\) failed, or a claimed universal proof. |

A finding is refused if it claims three denominators that fail \(4xyz = n(yz+xz+xy)\).

---

## 6. What the hunt does not claim

- A cleared bound is coverage of a finite interval.
- A letter is an alarm or a structural event, not a counterexample by itself.
- `./centl es hunt --until-proof` expands the attack. It does not declare the conjecture proved.
- Universal DSC-0 and DSC-P are false; they are not the bridge used here.

The remaining theorem work is still the all-prime two-target coverage recorded in [`ERDOS-STRAUS-WALL.md`](ERDOS-STRAUS-WALL.md) and [`CURRENT-FRONTIER.md`](CURRENT-FRONTIER.md).

---

## 7. How to check a finding

Open the file. If it shows

```text
4/n = 1/x + 1/y + 1/z
```

compute \(4xyz\) and \(n(yz+xz+xy)\) with any exact calculator, or run

```text
./centl es solve n
```

They must be equal. Do not trust a floating-point check.

If two people both hold a letter, compare the **letter number** printed at the top of each file. The numbers match if and only if the findings are the same.
