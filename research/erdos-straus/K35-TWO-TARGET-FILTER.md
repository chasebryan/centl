# Exact two-target filter at the composite shift `k=35`

**Status:** exact computer-assisted finite-group classification  
**Date:** 2026-08-16  
**Depends on:** `K35-TWO-TARGET-STRUCTURE.md`, `FIXED-SHIFT-JACOBI-PARITY.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Machine certificate:** `classify_k35_states.py`  
**Independent finite regression:** `verify_k35_structure.py` plus the preserved CBX 10M standalone hit relation  
**Claim boundary:** this closes the fixed Lane-I shift `k=35` by an exact finite-group state exhaustion. It does not prove that every hard prime reaches a successful shift by 35, does not give a universal finite shift bound, and does not prove Erdős–Straus.

---

## 1. Setup

Let `p` be Mordell-hard and put

\[
\boxed{C=\frac{p+35}{4}}.
\]

The structural theorem `K35-TWO-TARGET-STRUCTURE.md` gives

\[
G=(\mathbb Z/35\mathbb Z)^\times
\cong C_{12}\times C_2.
\]

Use the coordinates

\[
\boxed{x=6^\varepsilon3^a\pmod{35},
\qquad
(\varepsilon,a)\in C_2\times C_{12}.}
\]

The index-two subgroup

\[
\boxed{H=\langle3\rangle}
\]

is exactly the Jacobi-`+1` kernel.

For every Mordell-hard prime,

\[
\boxed{C\in H.}
\]

Equivalently, the final center coordinate of `C` has

\[
\boxed{\varepsilon(C)=0.}
\]

This is also the `k=35` specialization of `FIXED-SHIFT-JACOBI-PARITY.md`.

---

## 2. Exact divisor-state coordinate

Factor

\[
C=\prod_iq_i^{e_i}.
\]

Let

\[
g_i=(\varepsilon_i,a_i)\in G
\]

be the coordinate of `q_i mod 35`.

Define

\[
\boxed{
D(C)=
\left\{
\sum_i f_i g_i:
0\le f_i\le2e_i
\right\}
\subseteq G
}
\]

and let

\[
\boxed{c(C)=\sum_i e_i g_i}
\]

be the group coordinate of `C` itself.

Thus the complete fixed-shift state is

\[
\boxed{S(C)=(D(C),c(C)).}
\]

This state contains all information needed for both exact Lane-I targets.

---

## 3. The two targets

From `K35-TWO-TARGET-STRUCTURE.md`, the Type-I divisor-square target is

\[
\boxed{\tau_I=(1,8),}
\]

while

\[
-1=(1,6).
\]

Because `c(C)=(0,c)` lies in `H`, the Type-II divisor-square target is

\[
\boxed{\tau_{II}(c)=(1,c+6).}
\]

Therefore

\[
\boxed{
k=35\text{ misses}
\iff
(1,8)\notin D(C)
\text{ and }
(1,c+6)\notin D(C).}
\]

This is an exact membership criterion in a 24-element group.

---

## 4. One valuation occurrence gives one exact transition

A single prime-valuation occurrence with group coordinate

\[
g\in G
\]

allows divisor exponents `0,1,2`. Hence it contributes the local set

\[
\boxed{\{0,g,2g\}.}
\]

If the current state is `(D,c)`, adjoining one valuation occurrence gives

\[
\boxed{
T_g(D,c)
=
\left(D+\{0,g,2g\},\ c+g\right).
}
\]

This transition is exact.

Repeated application also handles a prime power `q^e`: the Minkowski sum of `e` copies of `{0,g,2g}` contains every multiple

\[
0,g,2g,\ldots,2eg,
\]

because every integer from `0` through `2e` is a sum of `e` digits from `{0,1,2}`.

Therefore arbitrary factorizations of `C` are exactly represented by finite sequences of the 24 transitions `T_g`.

---

## 5. Finite closure theorem

Start from the empty factorization state

\[
\boxed{S_0=(\{0\},0).}
\]

`classify_k35_states.py` closes this state under all 24 transitions `T_g` until no new state appears.

The least closed state space has exactly

\[
\boxed{1298}
\]

states.

Because each state is checked under every one of the 24 transitions, the closed system contains all states reachable by arbitrarily long factorization sequences. No upper bound on `p`, on the number of prime factors, or on the valuations is used.

Among the 1298 states, exactly

\[
\boxed{650}
\]

have final center in `H`, i.e. `epsilon(c)=0`, and are therefore compatible with the Mordell-hard `k=35` center law.

### Theorem — exact state exhaustion

Every possible `k=35` divisor state of a Mordell-hard prime belongs to these 650 admissible states.

This is a finite-group exhaustion, not a finite-prime search.

---

## 6. Complete miss table

Apply the two exact target tests to all 650 admissible states.

The result is

\[
\boxed{418\text{ hit states}}
\]

and

\[
\boxed{232\text{ combined-miss states}.}
\]

The classifier can emit all 232 miss rows with

```sh
python3 research/erdos-straus/classify_k35_states.py --json --table
```

Define that emitted exact table to be

\[
\boxed{\mathcal M_{35}.}
\]

### Theorem — exact fixed-`k=35` classification

For a Mordell-hard prime `p`, let

\[
C=\frac{p+35}{4}
\]

and form its exact state `S(C)=(D(C),c(C))`.

Then

\[
\boxed{
k=35\text{ misses both Lane-I targets}
\iff
S(C)\in\mathcal M_{35}.}
\]

No other miss state exists.

By `ES-BINARY-LANE-I-EQUIVALENCE.md`, this is simultaneously the complete fixed-35 binary-selector classification.

---

## 7. The pure-`H` theorem is recovered exactly

Close the state system using only valuation directions in

\[
H.
\]

There are exactly

\[
\boxed{92}
\]

such states.

Every one is a combined miss:

\[
\boxed{92/92\text{ pure-}H\text{ states miss}.}
\]

Thus the universal pure-subgroup trap from `K35-TWO-TARGET-STRUCTURE.md` appears as an exact subspace of the full state classifier.

The remaining

\[
\boxed{140}
\]

miss states are genuinely non-pure.

---

## 8. Every non-pure miss state has a tiny outside core

Count a valuation occurrence as **outside** when its coordinate has

\[
\varepsilon=1,
\]

i.e. its residue lies outside `H`.

For each of the 232 miss states, minimize lexicographically

\[
(\text{number of outside valuation units},\ \text{total valuation units})
\]

over all transition paths producing the same exact state.

The minimum-outside distribution is

\[
\boxed{
\begin{array}{c|c}
\text{minimum outside units}&\text{miss states}\\
\hline
0&92\\
2&138\\
4&2
\end{array}}
\]

Hence:

\[
\boxed{
\text{every }k=35\text{ miss state has a state-equivalent core using at most four outside units}.}
\]

This is a statement about **state representatives**, not a claim that the original integer `C` itself contains at most four outside prime-factor occurrences. A factorization with many outside factors can collapse to the same residue/divisor state as a smaller core.

This sharpens the earlier four-companion theorem: the two-packet geometry generates 138 of the 140 non-pure miss states, while only two genuinely new states require a four-outside-unit representative.

---

## 9. The two four-unit core states

Both exceptional minimum-four states have center

\[
\boxed{c=(0,2),}
\]

so

\[
\tau_{II}=(1,2+6)=(1,8)=\tau_I.
\]

Thus the two exact targets coincide.

Each exceptional divisor set has size

\[
\boxed{21/24,}
\]

and misses the common target `(1,8)` plus only two additional group elements.

One shortest outside-only representative uses coordinates

\[
\boxed{(1,1),(1,1),(1,2),(1,10),}
\]

corresponding to residues

\[
\boxed{18,18,19,24\pmod{35}.}
\]

Its three missing residues are

\[
\boxed{17,13,26.}
\]

The second uses

\[
\boxed{(1,2),(1,2),(1,5),(1,5),}
\]

corresponding to residues

\[
\boxed{19,19,23,23\pmod{35},}
\]

and its three missing residues are

\[
\boxed{3,27,26.}
\]

In both cases `26` is the common Type-I/Type-II target.

These two states are the entire minimum-four exception to the two-outside-unit core picture.

---

## 10. Target-preserving symmetry

The automorphism

\[
\boxed{(\varepsilon,a)\mapsto(\varepsilon,7a)}
\]

of `C_2 x C_12` fixes

\[
(1,8),
\qquad
(1,6),
\]

and therefore preserves both the Type-I target and the Type-II translation law.

It preserves the complete miss set.

Under this involution, the 232 miss states collapse to

\[
\boxed{149\text{ orbits},}
\]

consisting of

\[
\boxed{66\text{ fixed states}}
\]

and

\[
\boxed{83\text{ two-state orbits}.}
\]

This symmetry is useful for theorem mining and for compact independent reimplementations of the table.

---

## 11. Independent finite regression through 10 million

The exact state theorem above is range-free. Separately, the preserved CBX standalone artifact supplies an independent finite hit relation through

\[
p\le10^7.
\]

On all

\[
\boxed{20,513}
\]

Mordell-hard primes in that domain, an independent factorization/state reconstruction gives:

```text
direct CBX k=35 hits      5,978
state-classifier hits     5,978
mismatches                    0
```

The comparison reconstructs the state from the factorization of `(p+35)/4`; it does not use the CBX Lane-I decision to choose the predicted state outcome.

The older `verify_k35_structure.py` independently checks the subgroup, parity, pure-`H`, full-`H`, and exact two-packet companion identities by constructing divisor residue boxes directly modulo `35`.

These finite checks support the implementation. The theorem itself is the exhaustive 24-element-group state closure.

---

## 12. Corridor consequence

On the same preserved 10M corpus, the completely classified shifts

\[
3,7,11,15,19,23,27,31
\]

leave

\[
\boxed{65}
\]

hard primes entering `k=35`.

The `k=35` classifier gives

\[
\boxed{17\text{ hits},\qquad48\text{ misses}.}
\]

Their later first-hit distribution is

```text
k=39   22
k=43    5
k=47   15
k=51    1
k=55    2
k=59    2
k=107   1
```

This is finite evidence only. It does not make `107` a universal bound.

The next local corridor target is therefore

\[
\boxed{k=39.}
\]

By `FIXED-SHIFT-JACOBI-PARITY.md`, its outside-packet parity is already controlled by

\[
\left(\frac{39}{p}\right)=\left(\frac{13}{p}\right).
\]

So the next theorem search should exploit the split between the `(13/p)=+1` even-packet branch and `(13/p)=-1` odd-packet branch rather than treating `k=39` as an unstructured modulus.

---

## 13. Reproduction

The complete exact state classifier is

```sh
python3 research/erdos-straus/classify_k35_states.py --json
```

and the complete 232-row table is

```sh
python3 research/erdos-straus/classify_k35_states.py --json --table
```

Hard regression constants are:

```text
total states                 1298
admissible H-center states    650
hit states                    418
miss states                   232
pure-H states                  92
pure-H miss states             92
non-pure miss states          140
miss symmetry orbits          149
symmetry fixed states          66
symmetry pairs                 83
minimum-outside histogram   {0:92, 2:138, 4:2}
```

Any change to these constants causes the classifier to fail.

---

Erdős–Straus remains open. Fixed `k=35` is now completely classified; the missing global step is still to prove that the Legendre-prescribed sequence of fixed-shift miss states cannot persist indefinitely.
