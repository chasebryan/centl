# How grades are decided

A finding is refused if it claims three denominators that fail

```text
4 · x · y · z  =  n · (y z + x z + x y)
```

Otherwise the engine attaches every rule that applies, then keeps the strongest stamp.

## LETTER

1. `unsolved_after_search` — a Mordell-hard prime missed every construction.
2. `window_broken` — `a,b ≤ 11` failed and a later search still (or did not) resolve it.
3. `universal_strike` — the proof ledger claims a complete proof. Read the certificate. Finite hunts never set this by themselves.

Each letter also carries a **letter number**: the first 128 bits of SHA-256 of the exact text

```text
ES-LETTER-v1
rule=<one of the three rules>
n=<the prime, or 0>
extra=<empty, or a hash of a claimed certificate>
```

The same letter is the same number on every machine. The hunt's start factor, the clock, and the hostname are not in that text.

## GREAT

1. `escaped_small_theorems` — missed `k = 3,7,11,15` and the `p+4` / `4p+1` filters.
2. `type_I_only` — Type II missed, Type I hit.
3. `deep_shift` — first two-target hit has `k ≥ 19`.
4. `record_shift` — that `k` is larger than any previously filed `k`.
5. `cleared_bound` — every hard prime below a stated bound has a checked witness.
   This updates `max_cleared_bound` only. It is not stored as another GREAT row.

## GOOD

1. `certified_hard_witness` — a checked identity for a hard prime that is not merely a routine small-shift hit.
2. `new_method` — a construction name the catalog has not seen.

Erdős–Straus stays open unless a LETTER named `universal_strike` points at a complete deposited proof.
