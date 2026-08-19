# Exact two-target filter at the prime shift `k=43`

**Status:** exact computer-assisted finite-group classification  
**Date:** 2026-08-16  
**Depends on:** `FIXED-SHIFT-JACOBI-PARITY.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Machine certificate:** `classify_k43_states.py`  
**Independent finite regression:** `verify_k43_structure.py` and the preserved CBX 10M standalone relation  
**Claim boundary:** this closes the fixed Lane-I shift `k=43`. It does not prove a universal finite shift ceiling and does not prove Erdős–Straus.

---

## 1. Setup

Let `p` be Mordell-hard and put

\[
\boxed{C=\frac{p+43}{4}.}
\]

For Mordell-hard `p`, one has `p != 43`, so `gcd(C,43)=1`.

The unit group is cyclic:

\[
\boxed{(\mathbb Z/43\mathbb Z)^\times\cong C_{42}.}
\]

Use primitive root

\[
\boxed{3\pmod{43}}
\]

and write

\[
\lambda(x)=\log_3x\pmod{42}.
\]

---

## 2. Exact state of a factorization

Factor

\[
C=\prod_iq_i^{e_i}.
\]

Define the divisor-log set

\[
\boxed{
D(C)=
\left\{
\sum_i f_i\lambda(q_i):
0\le f_i\le2e_i
\right\}
\subseteq C_{42}
}
\]

and the center

\[
\boxed{c(C)=\lambda(C)=\sum_ie_i\lambda(q_i).}
\]

The complete fixed-shift state is

\[
\boxed{S(C)=(D(C),c(C)).}
\]

This is exactly the divisor-square coordinate from `ES-TWO-TARGET-DIVISOR-SQUARE.md`.

---

## 3. The two exact targets

The Type-I divisor-square target is

\[
-4^{-1}\equiv32\pmod{43}.
\]

Since

\[
\boxed{\lambda(32)=9,}
\]

Type I is exactly

\[
\boxed{9\in D(C).}
\]

Also

\[
\lambda(-1)=21.
\]

Therefore the Type-II divisor target `-C` has log

\[
\boxed{c(C)+21\pmod{42}.}
\]

Hence

\[
\boxed{
k=43\text{ misses}
\iff
9\notin D(C)
\text{ and }
c(C)+21\notin D(C).}
\]

---

## 4. One valuation occurrence gives one exact transition

A single prime-valuation occurrence with log

\[
a\in C_{42}
\]

permits divisor exponents `0,1,2`. Thus its exact contribution is

\[
\{0,a,2a\}.
\]

The exact state transition is

\[
\boxed{
T_a(D,c)
=
\left(D+\{0,a,2a\},\ c+a\right).
}
\]

Repeated application handles arbitrary prime powers because `e` copies of `{0,a,2a}` attain every multiple

\[
0,a,2a,\ldots,2ea.
\]

Therefore arbitrary factorizations of `C` are represented exactly by finite sequences of the 42 transitions `T_a`.

---

## 5. Finite closure theorem

Start from the empty-factorization state

\[
\boxed{S_0=(\{0\},0).}
\]

`classify_k43_states.py` closes this state under all 42 transition directions until no new state appears.

The least closed state space has exactly

\[
\boxed{31,572}
\]

states.

Every outgoing transition from every discovered state remains inside the set. Hence arbitrarily long factorizations create no additional residue state.

### Theorem — exact state exhaustion

Every possible divisor-log state at fixed shift `k=43` belongs to this 31,572-state closure.

This statement is range-free. It uses only the finite group `C_42`, not a bound on `p` or a finite list of primes.

---

## 6. Complete miss table

Apply the two exact target tests to all 31,572 states.

The result is

\[
\boxed{23,832\text{ hit states}}
\]

and

\[
\boxed{7,740\text{ combined-miss states}.}
\]

Define the exact emitted miss table to be

\[
\boxed{\mathcal M_{43}.}
\]

### Theorem — exact fixed-`k=43` classification

For a Mordell-hard prime `p`, form `C=(p+43)/4` and its exact state `S(C)`.

Then

\[
\boxed{
k=43\text{ misses both Lane-I targets}
\iff
S(C)\in\mathcal M_{43}.}
\]

No other fixed-43 miss state exists.

By `ES-BINARY-LANE-I-EQUIVALENCE.md`, the same table is the exact fixed-43 consecutive binary-selector classification.

---

## 7. Pure quadratic support is an exact miss branch

In the primitive-root coordinate, quadratic residues are exactly the even logs.

If every prime factor of `C` is a quadratic residue modulo 43, then every element of `D(C)` has even log and `c(C)` is even.

But

\[
9\text{ is odd},
\qquad
c(C)+21\text{ is odd}.
\]

Therefore both targets miss.

Closing the transition system using only even log directions gives exactly

\[
\boxed{852}
\]

pure-QR states, and every one is a miss:

\[
\boxed{852/852.}
\]

This is a universal branch of the fixed-shift theorem, not a finite observation.

---

## 8. Jacobi parity is exactly center parity

Because `4` is a square modulo 43,

\[
\left(\frac C{43}\right)
=
\left(\frac p{43}\right).
\]

Since every Mordell-hard prime satisfies `p=1 mod4`, quadratic reciprocity gives

\[
\left(\frac p{43}\right)
=
\left(\frac{43}{p}\right).
\]

In primitive-root coordinates,

\[
\left(\frac C{43}\right)=(-1)^{c(C)}.
\]

Thus

\[
\boxed{(-1)^{c(C)}=\left(\frac{43}{p}\right).}
\]

This is the `k=43` instance of `FIXED-SHIFT-JACOBI-PARITY.md`.

The exact 7,740 miss states split as

\[
\boxed{4,268\text{ with }(43/p)=+1,}
\]

\[
\boxed{3,472\text{ with }(43/p)=-1.}
\]

Both character branches therefore contain genuine fixed-shift failure geometry.

---

## 9. Every miss state has a small nonresidue core

Call a valuation occurrence a **nonresidue unit** when its log is odd.

For each state, minimize lexicographically

\[
(\text{number of odd-log valuation units},\ \text{total valuation units})
\]

over all transition paths that produce the same exact state.

Among the 7,740 miss states, the minimum-nonresidue distribution is

\[
\boxed{
\begin{array}{c|r}
\text{minimum NR units}&\text{miss states}\\
\hline
0&852\\
1&2474\\
2&3177\\
3&998\\
4&239
\end{array}}
\]

No miss state requires a minimum representative with five or more nonresidue valuation units.

Hence

\[
\boxed{
\text{every fixed-43 miss state has a state-equivalent core with at most four NR units}.}
\]

As at shifts 35 and 39, this is a statement about an equivalent finite-group **state representative**, not a bound on the number of nonresidue prime-factor occurrences in the original integer `C`.

The parity law is visible exactly in the table:

- center even, `(43/p)=+1`: only minimum NR counts `0,2,4` occur;
- center odd, `(43/p)=-1`: only counts `1,3` occur.

So the Legendre symbol determines the parity of the smallest packet geometry exactly as predicted by the global fixed-shift parity theorem.

---

## 10. Target-preserving symmetry

Multiplication of logs by

\[
\boxed{29\pmod{42}}
\]

is a nontrivial involutive automorphism of `C_42`.

It fixes the Type-I target because

\[
29\cdot9\equiv9\pmod{42},
\]

and fixes the `-1` translation because

\[
29\cdot21\equiv21\pmod{42}.
\]

Therefore it preserves the complete miss set.

The 7,740 miss states collapse under this symmetry to

\[
\boxed{4,045\text{ orbits},}
\]

consisting of

\[
\boxed{350\text{ fixed states}}
\]

and

\[
\boxed{3,695\text{ two-state orbits}.}
\]

This gives a smaller canonical object for later cross-shift theorem mining.

---

## 11. Independent finite regression

`verify_k43_structure.py` independently generates Mordell-hard primes, factors `C`, constructs the divisor residue box of `C^2` directly modulo 43, and compares direct target membership with the exact state classification.

On the small Fedora regression domain through `100,000`, there are 273 hard primes and zero mismatches.

Separately, replay against the preserved CBX standalone relation through

\[
p\le10^7
\]

gives

```text
Mordell-hard primes       20,513
CBX k=43 hits               3,687
state-classifier hits       3,687
mismatches                      0
```

The finite population splits as

```text
(43/p)=+1 : 1,014 hits, 9,204 misses
(43/p)=-1 : 2,673 hits, 7,622 misses
```

These population counts are finite evidence. The theorem itself is the closed finite-group state system.

---

## 12. Corridor consequence

After the completely classified shifts through

\[
3,7,11,15,19,23,27,31,35,39,
\]

the preserved 10M corpus leaves exactly

\[
\boxed{26}
\]

hard primes entering shift 43.

At `k=43`:

```text
(43/p)=+1 :  1 hit, 11 misses
(43/p)=-1 :  4 hits, 10 misses
```

so 43 removes five targets and leaves

\[
\boxed{21}
\]

finite corridor survivors.

Their later first-hit distribution is

```text
k=47   15
k=51    1
k=55    2
k=59    2
k=107   1
```

This is theorem-hunting evidence only. It does not make 107 a universal bound.

The next local corridor target is

\[
\boxed{k=47.}
\]

---

## 13. Reproduction

Run

```sh
python3 research/erdos-straus/classify_k43_states.py --json
python3 research/erdos-straus/verify_k43_structure.py --limit 100000 --json
```

The complete 7,740-row miss table is emitted by

```sh
python3 research/erdos-straus/classify_k43_states.py --json --table
```

Hard classifier constants are:

```text
total states                    31,572
hit states                      23,832
miss states                      7,740
pure-QR states                     852
pure-QR misses                     852
miss symmetry orbits             4,045
symmetry fixed states              350
symmetry pairs                   3,695
Legendre miss split       {+1:4268, -1:3472}
minimum NR histogram      {0:852, 1:2474, 2:3177, 3:998, 4:239}
```

Any change to these constants causes the machine certificate to fail.

---

Erdős–Straus remains open. Fixed `k=43` is now completely classified; the global problem is to prevent the character-prescribed miss-state sequence from persisting across all admissible shifts.
