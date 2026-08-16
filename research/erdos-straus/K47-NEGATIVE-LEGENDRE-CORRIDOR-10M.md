# Negative-Legendre `k=47` misses versus the earlier corridor — 10M

**Status:** exact finite theorem-mining census  
**Date:** 2026-08-16  
**Domain:** Mordell-hard primes represented in the preserved CBX standalone relation through `10,000,000`  
**Analyzer:** `analyze_k47_negative_corridor.py`  
**Claim boundary:** every statement in this note is finite unless explicitly identified as an already-proved fixed-shift theorem. This note does not assert a universal cross-shift containment and does not prove Erdős–Straus.

---

## 1. Target population

The exact fixed-47 state theorem permits misses in both Legendre branches.

On the preserved 10M corpus there are

\[
\boxed{822}
\]

Mordell-hard primes satisfying both

\[
\left(\frac{47}{p}\right)=-1
\]

and

\[
\boxed{k=47\text{ misses}.}
\]

Thus the negative-Legendre branch is genuinely populated in isolation. It is not forbidden by the fixed-47 theorem.

---

## 2. Earlier corridor removes all 822

Apply the earlier classified shifts in ascending order:

\[
3,7,11,15,19,23,27,31,35,39,43.
\]

The residual sequence is

```text
start  822
k=3    558
k=7    302
k=11   118
k=15    81
k=19    48
k=23    13
k=27     7
k=31     2
k=35     1
k=39     0
k=43     0
```

Therefore, on this finite domain,

\[
\boxed{
\{p:\ (47/p)=-1,\ k=47\text{ misses}\}
\subseteq
\bigcup_{k\in\{3,7,11,15,19,23,27,31,35,39\}}H_k.
}
\]

The shift 43 is not needed for this finite containment.

This explains why the post-43 corridor entering shift 47 contains no negative-Legendre miss.

---

## 3. First earlier hit distribution

The first earlier hit among the 822 targets is

```text
k=3    264
k=7    256
k=11   184
k=15    37
k=19    33
k=23    35
k=27     6
k=31     5
k=35     1
k=39     1
```

The distribution is broad. No single early theorem explains the phenomenon.

In particular, this is not a trivial shadow by one dominant layer.

---

## 4. Exact finite minimum cover size

The analyzer exhaustively tests subsets of the eleven prior configured layers

\[
\{3,7,11,15,19,23,27,31,35,39,43\}
\]

against the finite target set.

No subset of size six or smaller covers all 822 targets.

A seven-layer cover exists, for example

\[
\boxed{\{3,7,15,23,27,31,39\}.}
\]

Hence, relative to this finite set of candidate earlier layers, the exact minimum cover size is

\[
\boxed{7.}
\]

This is a finite set-cover fact only. It is not a seven-layer universal theorem.

---

## 5. Why this is a better theorem target than raw `k=47`

The fixed-47 classifier contains

\[
\boxed{6,848}
\]

abstract miss states with negative center parity, equivalently `(47/p)=-1`.

After the universally forced factor `6 | (p+47)/4` is imposed, the actual hard-prime state closure leaves only

\[
\boxed{80}
\]

negative-character miss states.

The finite earlier corridor then realizes none of those states after shift 39.

So the proof target has been compressed in three stages:

\[
6848\text{ generic states}
\longrightarrow
80\text{ forced-6 hard states}
\longrightarrow
0\text{ observed post-corridor states through }10^7.
\]

A useful universal theorem would explain the last arrow without relying on a finite bound.

---

## 6. Candidate cross-shift statement

The strongest current target is:

> **Candidate.** If a Mordell-hard prime misses the exact two-target shifts
> `3,7,11,15,19,23,27,31,35,39`, then `(47/p)=-1` forces a hit at `k=47`.

The 10M relation supports this candidate with zero finite exceptions.

It is **not proved**.

A proof must connect the earlier factorization-state restrictions to the 80 forced-6 negative-character miss states at 47. Merely re-running the finite relation or listing the 80 states is not sufficient.

---

## 7. Reproduction

Given the preserved standalone hit relation:

```sh
python3 research/erdos-straus/analyze_k47_negative_corridor.py \
  standalone-hit-relations.tsv \
  --hi 10000000 \
  --json
```

The analyzer independently computes the target population, ordered residual, and exhaustive finite minimum set cover over the earlier configured layers.

---

Erdős–Straus remains open. The significance of this census is that the first strong cross-shift Legendre exclusion candidate has now been isolated precisely enough to attack symbolically.
