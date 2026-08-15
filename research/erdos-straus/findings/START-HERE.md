# Findings library

This folder is written by the hunt. You do not need to know Python.

## The only commands you need

From the CENTL folder:

```text
./centl es
```

That opens the menu. Choose what to file before you go:

```text
[a] all three   GOOD, GREAT, and LETTER
[t] letters     LETTER only — does not grow the GREAT/GOOD ledger
[g] go
```

The choice is remembered on that hunt. Or, without the menu:

```text
./centl es go
```

That is the long hunt. It remembers a **seed** (where it stopped) so it never starts from scratch. It runs until you press Ctrl+C. Letters are collected as they appear; the hunt does not stop on the first one.

```text
./centl es go --from 0
./centl es go --origin
./centl es go 0
./centl es go --from 20000000000
./centl es go 20000000000
./centl es go --from 2e9
./centl es go --random
```

starts **another** hunt at 0 or at any number you choose. The hunt you already had keeps its cursor. Findings still go in this shared library. Resume a named hunt with `./centl es go --hunt NAME`. List them with `./centl es hunts`.

If you type `go` in a second terminal while the first hunt is still running, that second process joins as a sibling and takes the next free windows. It does not reset the first.

```text
./centl es look
./centl es letters
./centl es seed
```

`look` shows the latest findings. `letters` shows only the rarest files, each with its letter number. `seed` shows the cursor.

## The infinite hunt

Let `s` be the number `scanned_through` in `findings/seeds/current.json`, and let `Δ` be the window (default 50 000). The hunt is the sequence of intervals

```text
(s, s+Δ],   (s+Δ, s+2Δ],   (s+2Δ, s+3Δ],   …
```

with no last interval. `s` begins at the **start factor** (0, a number you typed, or a random integer). After each interval, `s` moves forward. Ctrl+C stops the engine and writes `s`. The next `go` starts at `s`.

A finished interval is not a proof of the conjecture.

## Letter numbers

Every letter has a number printed at the top of its file.

That number is not assigned by a machine, a clock, or a person. It is the first 128 bits of SHA-256 of a fixed description of *what was found* (the rule, and the prime). Anyone who finds the same letter, on any computer, at any time, computes the same number.

If you and someone else both find the same unsolved prime, you will both hold the same letter file name and the same letter number. Compare them.

A worldwide serial number (#1, #2 in the order of discovery) cannot work without a shared counter. This can.

The start factor is **not** part of the letter. Two hunts that begin in different places and later meet the same prime write the same letter.

## What the three stamps mean

| stamp | where it lives | meaning |
|---|---|---|
| GOOD | `good.jsonl` | A solid, checked identity or a new construction. Worth keeping. |
| GREAT | `great.jsonl` | A hard prime escaped the small theorems, a Type I rescue, or a new depth record. One JSON line each — not a pair of files. |
| LETTER | `letters/` | An unsolved hard prime, a broken `a,b ≤ 11` window, or a claimed universal proof. These stay individual files. |

A cleared bound is the number `max_cleared_bound` in `counts.json`. It is not a new GREAT row on every window.

The GREAT/GOOD ledgers are **not** in a `git clone`. Download them on purpose:

```text
./centl es fetch
./centl es fetch great
./centl es show G-<id>
```

To hunt without growing the GREAT ledger:

```text
./centl es go --letters-only
./centl es go --all
```

If an old tree still has a `great/` pile of files:

```text
./centl es compact
```

That folds witnesses into `great.jsonl` and deletes the pair-files. Do not delete the witnesses themselves unless you only want letters.

The rules are written in `HOW-GRADES-WORK.md`. They are mechanical. The computer is not guessing.

## How to check a finding yourself

Open the file. If it shows

```text
4/n = 1/x + 1/y + 1/z
```

ask CENTL:

```text
./centl es solve n
```

or compute `4xyz` and `n(yz + xz + xy)` with any exact calculator. They must be equal.

## What is not in here

Ordinary easy identities (`n` even, `n ≡ 3 mod 4`, `k = 3` or `7`) are not copied into these folders. They are logged in `log.jsonl` only when they meet a filing rule. The library is meant to stay readable.
