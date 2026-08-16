# Negative-Legendre `k=47` misses versus the earlier corridor — 10M

**Status:** exact finite theorem-mining census plus proved fixed-47 state reductions  
**Date:** 2026-08-16  
**Domain:** complete Mordell-hard prime universe through `10,000,000`  
**Analyzers:** `analyze_k47_negative_corridor.py`, `analyze_k47_negative_states.py`, `analyze_k47_negative_hard_cells.py`  
**Claim boundary:** finite cover statements in this note are not universal cross-shift theorems. Exact fixed-47 state statements are identified separately. Erdős–Straus remains open.

---

## 1. Sound finite universe

The finite universe is reconstructed independently from the six Mordell-hard residue classes

\[
\boxed{1,121,169,289,361,529\pmod{840}}
\]

using deterministic 64-bit primality testing.

Through `10,000,000` this gives exactly

\[
\boxed{20,513}
\]

hard primes.

This correction matters: the standalone relation TSV contains only hit rows. Its union contains `20,507` primes, so

\[
\boxed{6}
\]

hard primes miss every recorded standalone shift through `k=47` and are invisible if the hit union is incorrectly used as the universe.

The earlier v1 analyzer used that unsafe convention. The corrected complete-universe computation changes the methodology but **does not change the negative-character target count below**.

---

## 2. Target population survives the universe correction

On the complete 10M hard-prime universe there are exactly

\[
\boxed{822}
\]

primes satisfying both

\[
\left(\frac{47}{p}\right)=-1
\]

and

\[
\boxed{k=47\text{ misses}.}
\]

Thus the negative-character branch is genuinely populated at fixed `k=47`; the fixed-shift theorem alone does not exclude it.

---

## 3. Earlier corridor removes all 822

Apply the earlier shifts

\[
3,7,11,15,19,23,27,31,35,39.
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
```

Hence on this finite domain,

\[
\boxed{
\{p:\ (47/p)=-1,\ k=47\text{ misses}\}
\subseteq
\bigcup_{k\in\{3,7,11,15,19,23,27,31,35,39\}}H_k.
}
\]

This is finite evidence only.

---

## 4. Exact finite global covers

No subset of six or fewer of the ten earlier shifts covers all 822 finite targets.

There are exactly two minimum seven-shift covers:

\[
\boxed{\{3,7,15,23,27,31,39\}}
\]

and

\[
\boxed{\{7,15,23,27,31,35,39\}}.
\]

Therefore the exact finite minimum cover size is

\[
\boxed{7}.
\]

The previous note recorded the first cover but did not state that a second minimum cover exists.

---

## 5. Exact eleven-direction partition

The generic fixed-47 closure has `6,848` negative-character miss states. Imposing the universal hard-prime factor

\[
6\mid C_{47}=\frac{p+47}{4}
\]

reduces this to exactly

\[
\boxed{80}
\]

negative-character forced-6 miss states.

The one-packet theorem gives eleven possible log directions

\[
\mathcal R_{47}^{(1)}=\{1,7,9,11,17,19,27,29,35,37,45\}.
\]

The exact state regression now proves that these eleven classes are **disjoint and complete** on the 80 states: every one of the 80 belongs to exactly one direction class.

Their abstract state counts are

| log direction | states |
|---:|---:|
| 1 | 7 |
| 7 | 2 |
| 9 | 13 |
| 11 | 3 |
| 17 | 6 |
| 19 | 10 |
| 27 | 11 |
| 29 | 3 |
| 35 | 3 |
| 37 | 13 |
| 45 | 9 |

On the 10M target set the corresponding prime counts are

\[
\boxed{91,57,77,69,61,78,73,72,63,101,80},
\]

summing to 822.

At direction resolution there is no singleton or pair earlier-shift eliminator. Every finite direction class needs a minimum cover of size four or five.

---

## 6. Exact-state refinement

Refining by the full fixed-47 abstract state rather than direction alone gives a much sharper finite target.

Of the 80 abstract negative-character states,

\[
\boxed{62}
\]

are realized by the 822 finite targets and 18 are not realized through 10M.

For the 62 realized states, the exact finite minimum earlier-shift cover histogram is

| minimum cover size | realized states |
|---:|---:|
| 1 | 35 |
| 2 | 9 |
| 3 | 11 |
| 4 | 7 |

Thus

\[
\boxed{55/62}
\]

realized states already reduce to a singleton, pair, or triple finite theorem target.

Only seven realized states require four shifts, containing

\[
\boxed{231}
\]

of the 822 finite primes.

Those seven state IDs are

```text
r7-s02
r11-s02
r19-s06
r35-s02
r35-s03
r37-s09
r45-s08
```

---

## 7. Hard-residue refinement collapses the core again

Now split each exact state by the universal hard residue `p mod 840`.

There are `184` realized `(state, hard-residue)` cells. Their exact finite minimum-cover histogram is

| minimum cover size | cells | target primes |
|---:|---:|---:|
| 1 | 123 | 359 |
| 2 | 57 | 431 |
| 3 | 3 | 22 |
| 4 | 1 | 10 |

So

\[
\boxed{812/822}
\]

finite targets lie in cells needing at most three earlier shifts.

Only one cell still needs four:

\[
\boxed{(\texttt{r7-s02},\ p\equiv1\pmod{840})},
\]

containing exactly ten targets through 10M.

The only three-shift cells are

```text
r19-s06 @ p mod 840 = 529   : 4 targets
r37-s09 @ p mod 840 =   1   : 7 targets
r37-s09 @ p mod 840 = 361   : 11 targets
```

A further finite curiosity is that all 822 targets lie in hard classes

\[
\boxed{1,169,361,529\pmod{840}},
\]

with counts `202,208,196,216` respectively. The classes `121` and `289` contribute zero finite negative-character k47 misses through 10M. No universal exclusion of those two classes is claimed.

---

## 8. The unique four-shift cell has an exact fixed-47 shape

The state `r7-s02` is the immediate log-7 extension of the forced `2·3` state.

A separate exact transition-graph verifier proves that, after the forced factors 2 and 3, the only productive nonzero valuation-unit transition into this state is log `7`; log `0` units are neutral.

Therefore any integer realizing this exact fixed-47 state has

\[
\boxed{C_{47}=6qS}
\]

where

- `q` is prime with `q ≡ 11 (mod 47)` and occurs to total valuation one;
- every prime divisor of `S` is `1 (mod 47)`;
- `v_2(C47)=v_3(C47)=1`.

The state center gives

\[
C_{47}\equiv19\pmod{47},
\qquad
\boxed{p\equiv29\pmod{47}}.
\]

Inside the unique hard cell `p ≡ 1 (mod 840)`, CRT gives the universal conditional congruence

\[
\boxed{p\equiv9241\pmod{39480}}.
\]

Equivalently,

\[
\boxed{qS\equiv387\pmod{1645}}.
\]

The ten 10M examples happen to have `S=1`, but that is **not universal**. An explicit larger prime realization is

\[
p=537,647,881,
\quad q=79,159,
\quad S=283,
\]

with

\[
C_{47}=6\cdot79,159\cdot283,
\qquad 283\equiv1\pmod{47}.
\]

It is an exact `r7-s02` fixed-47 miss. This example is retained as a regression against the false stronger guess `S=1`.

---

## 9. Current symbolic target

The broad candidate remains:

> If a Mordell-hard prime misses the exact earlier corridor through `k=39`, then `(47/p)=-1` forces a hit at `k=47`.

The complete 10M corpus has zero finite exceptions.

The practical theorem-mining target is now much narrower. The hardest observed cell can be stated as:

> Analyze primes `p ≡ 9241 (mod 39480)` whose fixed-47 factor state is `C47=6qS` with one `q ≡ 11 (mod47)` valuation unit and all factors of `S ≡1 (mod47)`, and prove that one of the earlier signed-box shifts must hit.

Even this narrowed statement is **not proved**. The finite ten-prime cover size four does not imply a universal four-shift theorem.

---

## 10. Reproduction

```sh
python3 research/erdos-straus/analyze_k47_negative_corridor.py \
  standalone-hit-relations.tsv --hi 10000000 --json

python3 research/erdos-straus/analyze_k47_negative_states.py \
  standalone-hit-relations.tsv --hi 10000000 --json

python3 research/erdos-straus/analyze_k47_negative_hard_cells.py \
  standalone-hit-relations.tsv --hi 10000000 --json

python3 research/erdos-straus/verify_k47_r7_s02_shape.py --json
```

The Fedora workflow `.github/workflows/erdos-straus-k47-direction-matrix.yml` regenerates the complete standalone relation and preserves the JSON evidence as an Actions artifact.

---

Erdős–Straus remains open. The result here is a sequence of exact fixed-shift reductions plus finite cross-shift compression from an 822-prime phenomenon to one explicit ten-prime hard cell, with its exact k47 factor-residue shape isolated for symbolic attack.
