# Negative-Legendre `k=47` misses versus the earlier corridor — 10M

**Status:** exact fixed-`k` state analysis plus finite theorem-mining census  
**Date:** 2026-08-16  
**Domain:** Mordell-hard primes represented in the preserved CBX standalone relation through `10,000,000`  
**Analyzer:** `analyze_k47_negative_corridor.py`  
**Claim boundary:** the 80-state and 11-class statements below are exact fixed-`k=47` consequences of the forced-6 state model. Cross-shift capture counts and covers are finite observations on the preserved 10M relation. Nothing here asserts universal cross-shift containment or proves Erdős–Straus.

---

## 1. Target population

The exact fixed-47 theorem permits misses in both Legendre branches. On the preserved 10M corpus there are

\[
\boxed{822}
\]

Mordell-hard primes satisfying

\[
\left(\frac{47}{p}\right)=-1
\qquad\text{and}\qquad
k=47\text{ misses}.
\]

Thus the negative-character branch is genuinely populated in isolation.

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

Hence the finite 10M target population is already covered by shifts through 39. The exact finite minimum cover over the configured prior shifts has size seven, with the unique minimum example

\[
\boxed{\{3,7,15,23,27,31,39\}.}
\]

This is a finite set-cover fact only.

---

## 3. Exact forced-6 compression at `k=47`

For every Mordell-hard prime, `p ≡ 1 (mod 24)`, so

\[
C_{47}=\frac{p+47}{4}
\]

has the universal factor `6=2·3`. The forced-6 state theorem reduces the generic `k=47` state space to 1,079 hard-prime states. Exactly 196 are misses, split as

\[
116\text{ positive-character misses}
\quad+\quad
80\text{ negative-character misses}.
\]

The 80 negative-character miss states are exactly the one-additional-nonresidue-packet branch.

---

## 4. Exact eleven-class one-packet partition

Using base-5 logarithms modulo 47, the allowed one-packet representative directions are

\[
\boxed{\{1,7,9,11,17,19,27,29,35,37,45\}}.
\]

Their corresponding residue representatives are

\[
\{5,11,40,13,38,10,26,19,20,33,29\}\pmod{47}.
\]

Starting from the forced-6 seed, add one packet in direction `r` and then allow arbitrary quadratic-residue directions. Intersecting with the miss condition produces the following exact classes:

| log direction `r` | residue | exact miss states |
|---:|---:|---:|
| 1 | 5 | 7 |
| 7 | 11 | 2 |
| 9 | 40 | 13 |
| 11 | 13 | 13 |
| 17 | 38 | 9 |
| 19 | 10 | 9 |
| 27 | 26 | 9 |
| 29 | 19 | 9 |
| 35 | 20 | 4 |
| 37 | 33 | 4 |
| 45 | 29 | 1 |

These classes are disjoint and their union is exactly the 80-state negative-character forced-6 miss family.

This is an exact fixed-`k=47` classification, not a finite observation.

A representative direction is a state-equivalence label. It must not be read as a claim that an actual factorization of `C47` contains one uniquely distinguished prime in that residue class.

---

## 5. Finite 822-prime population also partitions uniquely

The analyzer reconstructs the full actual `k=47` state of each of the 822 finite targets from the factorization of `C47`, then asks which of the eleven exact classes contains that state.

Although the implementation deliberately permits a set-valued answer, every finite target has compatibility cardinality one:

\[
\boxed{822\text{ targets}\to822\text{ singleton class assignments}.}
\]

Finite counts by representative direction are:

| `r` | residue | finite targets |
|---:|---:|---:|
| 1 | 5 | 58 |
| 7 | 11 | 8 |
| 9 | 40 | 156 |
| 11 | 13 | 145 |
| 17 | 38 | 95 |
| 19 | 10 | 79 |
| 27 | 26 | 100 |
| 29 | 19 | 90 |
| 35 | 20 | 32 |
| 37 | 33 | 50 |
| 45 | 29 | 9 |

Total: 822.

Again, uniqueness here means uniqueness of the exact state-equivalence class, not uniqueness of an actual prime factor.

---

## 6. Direction-only cross-shift attack is too coarse

For each of the eleven finite direction classes, the analyzer exhaustively searches covers from

\[
\{3,7,11,15,19,23,27,31,35,39\}.
\]

No direction class is completely eliminated by one shift, any pair of shifts, or any triple of shifts.

The exact finite minimum cover sizes by direction are:

| `r` | targets | finite minimum cover size | one minimum cover |
|---:|---:|---:|---|
| 1 | 58 | 4 | `{3,11,15,31}` |
| 7 | 8 | 4 | `{3,7,11,19}` |
| 9 | 156 | 4 | `{7,11,23,35}` |
| 11 | 145 | 5 | `{3,7,11,15,23}` |
| 17 | 95 | 4 | `{3,7,11,35}` |
| 19 | 79 | 4 | `{3,7,11,15}` |
| 27 | 100 | 5 | `{3,7,11,15,19}` |
| 29 | 90 | 4 | `{3,11,19,23}` |
| 35 | 32 | 4 | `{3,7,11,23}` |
| 37 | 50 | 4 | `{3,7,11,35}` |
| 45 | 9 | 4 | `{3,7,11,23}` |

So the hoped-for theorem form

> one representative direction at `k=47` forces one earlier layer

is not visible in this finite corpus. Nor is a universal-looking pair or triple suggested merely by direction.

That negative result is useful: the eleven-direction quotient has done its job, but it has reached its resolution limit.

---

## 7. Full exact-state refinement

Refine again by the complete fixed-47 state `(mask, center_log)` rather than only its representative direction.

Of the exact 80 negative-character forced-6 miss states,

\[
\boxed{62}
\]

are realized by the 822 finite targets, while 18 are not realized through 10M.

Now the finite cover picture changes sharply:

| finite minimum earlier-shift cover size | realized exact states |
|---:|---:|
| 1 | 35 |
| 2 | 9 |
| 3 | 11 |
| 4 | 7 |

Thus

\[
\boxed{55/62}
\]

realized exact `k=47` states are eliminated by at most three earlier shifts on the finite domain, and more than half, 35/62, are eliminated by a single earlier shift.

This is the strongest current theorem-mining compression.

### The seven four-shift holdouts

Only seven realized exact states still need four earlier shifts in the 10M relation:

| mask | center | direction | targets | one finite minimum cover |
|---|---:|---:|---:|---|
| `0x39754f1e55d3` | 45 | 7 | 39 | `{3,11,23,39}` |
| `0x170f8741e0f` | 29 | 37 | 37 | `{3,11,19,23}` |
| `0x755e0f55c6b` | 3 | 11 | 37 | `{7,11,23,39}` |
| `0x355c6b1d5783` | 27 | 35 | 35 | `{3,7,11,39}` |
| `0x31fc701f1f01` | 37 | 45 | 34 | `{3,11,15,31}` |
| `0x3d7d7f1fd7d7` | 45 | 35 | 27 | `{7,11,27,39}` |
| `0x21f1fc7c3f1f` | 29 | 19 | 22 | `{3,7,23,27}` |

These seven state signatures, rather than all 822 primes or all eleven direction classes, are now the natural difficult symbolic targets.

---

## 8. What the next proof search should attack

The finite data now suggests a two-tier program.

First, for the 35 singleton-eliminated exact states, test whether their observed single-shift exclusion can be upgraded to an exact incompatibility theorem between the `k=47` state condition and the corresponding earlier fixed-shift failure condition.

Second, treat the seven four-shift holdouts as the hard kernel. Their masks retain enough divisor-set geometry that a cross-shift argument can use more information than the one-packet quotient. The likely useful object is a companion-state signature across

\[
C_k=P+\frac{k+1}{4},\qquad p=4P+1,
\]

with `P ≡ 0 (mod 6)` for Mordell-hard primes.

The immediate symbolic question is therefore no longer “which direction wins?” It is:

> Which exact `k=47` divisor-set masks are incompatible with simultaneous failure of a specified earlier companion shift or small shift set?

That target is finite-state enough to enumerate, but strong enough to carry real factorization information.

---

## 9. Candidate cross-shift statement remains open

The strongest broad candidate is still:

> If a Mordell-hard prime misses the exact two-target shifts `3,7,11,15,19,23,27,31,35,39`, then `(47/p)=-1` forces a hit at `k=47`.

The 10M relation has zero finite exceptions.

It is **not proved**. A proof must connect the factorization-state restrictions of the earlier companions to exclusion of all 80 exact forced-6 negative-character miss states at 47. Re-running the finite relation is not a proof.

---

## 10. Reproduction

Given the preserved standalone hit relation:

```sh
python3 research/erdos-straus/analyze_k47_negative_corridor.py \
  standalone-hit-relations.tsv \
  --hi 10000000 \
  --json
```

The analyzer independently computes:

- the 822-target population,
- the ordered earlier-corridor residual,
- the global finite minimum cover,
- the exact eleven-class state partition,
- finite direction-class cover data,
- the 62 realized full exact states,
- and the exact-state finite cover histogram.

Erdős–Straus remains open. The frontier has nevertheless moved from an 822-prime empirical phenomenon to a 62-state finite classification with a seven-state hard kernel.
