# Twelve-consecutive exact two-target corridor through `k=47`

**Status:** exact fixed-shift theorem synthesis plus preserved finite 10M corridor census  
**Date:** 2026-08-16  
**Finite analyzer:** `analyze_twelve_shift_corridor.py`  
**Claim boundary:** every fixed-shift classification cited below is a separate range-free theorem. The statement that only six hard primes survive all twelve positions through `10^7` is finite evidence only. This file does not prove a universal twelve-shift cover and does not prove Erdős–Straus.

---

## 1. The consecutive coordinate

For a Mordell-hard prime `p`, put

\[
\boxed{P=\frac{p-1}{4}.}
\]

Every admissible Lane-I shift can be written

\[
k=4t-1.
\]

Then

\[
\boxed{
\frac{p+k}{4}=P+t.}
\]

Therefore the first twelve shifts

\[
\boxed{3,7,11,15,19,23,27,31,35,39,43,47}
\]

are not a scattered collection of moduli. They are exactly the twelve consecutive integers

\[
\boxed{P+1,P+2,\ldots,P+12.}
\]

---

## 2. Every one of the twelve fixed positions is now classified

The two-target program now has an exact fixed-shift criterion at each of those twelve positions.

The early positions are handled by explicit subgroup/factorization theorems:

- `k=3` — exact binary / Type-II criterion;
- `k=7` — Type I cannot rescue a hard Type-II miss;
- `k=11` — exact combined classification with the Type-I companion;
- `k=15` — exact subgroup trap plus thin packet;
- `k=19` — exact QR / nonresidue-packet filter;
- `k=23` — exact combined safe-prime filter.

The later positions are closed by exact finite-group state systems:

- `k=27` — exact `C18` packet classification;
- `k=31` — exact `C30` quotient/lift classification;
- `k=35` — exact `C12 x C2` state closure;
- `k=39` — exact conjugate `C12 x C2` state closure;
- `k=43` — exact `C42` state closure;
- `k=47` — exact `C46` state closure, plus the sharper hard-prime forced-6 reduction.

Thus for every fixed `t=1,...,12`, combined Lane-I failure at `P+t` has an exact theorem-level description.

What remains open is **joint incompatibility** across the twelve consecutive factorizations.

---

## 3. Finite 10M progression

The canonical CBX standalone relation through

\[
p\le10^7
\]

contains

\[
\boxed{20,513}
\]

Mordell-hard primes.

Applying the twelve exact hit sets in ascending order gives:

| shift `k` | translate | new hits | residual |
|---:|---:|---:|---:|
| 3  | `P+1`  | 8,590 | 11,923 |
| 7  | `P+2`  | 4,779 | 7,144 |
| 11 | `P+3`  | 4,463 | 2,681 |
| 15 | `P+4`  | 949 | 1,732 |
| 19 | `P+5`  | 883 | 849 |
| 23 | `P+6`  | 541 | 308 |
| 27 | `P+7`  | 91 | 217 |
| 31 | `P+8`  | 152 | 65 |
| 35 | `P+9`  | 17 | 48 |
| 39 | `P+10` | 22 | 26 |
| 43 | `P+11` | 5 | 21 |
| 47 | `P+12` | 15 | 6 |

Thus the finite residual after all twelve consecutive exact positions is

\[
\boxed{6/20,513.}
\]

The six primes are

\[
\boxed{
118801,
496609,
532249,
806521,
2458369,
8803369.
}
\]

This is an exact finite census, not a theorem that twelve positions suffice universally.

---

## 4. The six survivors are not letters

All six finite twelve-position survivors are hit later in the same K=400 standalone relation:

```text
k=51    1
k=55    2
k=59    2
k=107   1
```

Therefore none is an ES-LETTER-v1 candidate at the full current Lane-I grade.

The last one is the already-known first-hit record at

\[
\boxed{p=8,803,369,\qquad k=107.}
\]

Again, `107` is an observed finite record, not a universal bound.

---

## 5. Why the twelve-position synthesis matters

The proof problem is no longer “find a useful small shift.”

Every one of the first twelve consecutive translated integers already has an exact miss language.

A hypothetical counterexample must place

\[
P+1,P+2,\ldots,P+12
\]

simultaneously into twelve compatible exceptional state families.

This is a much stronger object than twelve independent density statements. Consecutive integers satisfy rigid gcd relations:

\[
\gcd(P+i,P+j)\mid|i-j|.
\]

So prime-factor support that creates a defect at one position cannot be reassigned arbitrarily at neighboring positions.

The current global frontier is therefore a **consecutive-state incompatibility theorem**.

---

## 6. First concrete cross-shift exclusion candidate

The `k=47` analysis gives the first especially sharp candidate.

Fixed 47 admits negative-character misses, but after the forced factor

\[
6\mid P+12
\]

the entire negative-character miss geometry reduces to 80 one-packet states in only eleven nonresidue directions.

The 10M earlier corridor through `P+10` realizes none of them.

Equivalently, the finite data support:

> If `P+1,...,P+10` all lie in their exact miss families and `(47/p)=-1`, then `P+12` cannot lie in a `k=47` miss state.

This statement remains unproved, but it is the first corridor-wide Legendre exclusion target with an explicit finite state alphabet on the terminal layer.

See:

- `K47-FORCED6-HARD-REDUCTION.md`;
- `K47-ONE-PACKET-COMPANION-FILTER.md`;
- `K47-NEGATIVE-LEGENDRE-CORRIDOR-10M.md`.

---

## 7. Reproduction

Given the canonical standalone relation:

```sh
python3 research/erdos-straus/analyze_twelve_shift_corridor.py \
  standalone-hit-relations.tsv \
  --hi 10000000 \
  --json
```

The script recomputes the ordered twelve-layer residual and the later first-hit histogram from the exact relation set.

---

## 8. Research target

The preferred theorem-search direction is now:

\[
\boxed{
\text{prove that the twelve consecutive exact miss families have empty intersection.}
}
\]

A weaker but still valuable intermediate theorem would eliminate one Legendre branch at one late position, beginning with the negative `k=47` packet family.

The state classifiers make the terminal exceptional sets finite. The missing mathematics must now exploit the **shared consecutive integer structure** rather than deepen any one isolated modulus indefinitely.

---

Erdős–Straus remains open. The twelve-position corridor is a theorem-synthesis framework and a sharply reduced proof target, not a solution.
