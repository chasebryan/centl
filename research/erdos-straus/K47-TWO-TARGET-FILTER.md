# Exact two-target filter at the prime shift `k=47`

**Status:** exact computer-assisted finite-group classification  
**Date:** 2026-08-16  
**Depends on:** `FIXED-SHIFT-JACOBI-PARITY.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Machine certificate:** `classify_k47_states.py`  
**Independent finite regression:** `verify_k47_structure.py` and the preserved CBX 10M standalone relation  
**Claim boundary:** this closes the fixed Lane-I shift `k=47`. It does not prove a universal finite shift ceiling and does not prove Erdős–Straus.

---

## 1. Cyclic coordinate

Let `p` be Mordell-hard and put

\[
\boxed{C=\frac{p+47}{4}.}
\]

Since `p != 47`, `C` is a unit modulo 47. The group

\[
(\mathbb Z/47\mathbb Z)^\times
\]

is cyclic of order 46. Use primitive root

\[
\boxed{5\pmod{47}}
\]

and write

\[
\lambda(x)=\log_5x\pmod{46}.
\]

For a factorization `C=prod q_i^{e_i}`, define

\[
D(C)=\left\{\sum_i f_i\lambda(q_i):0\le f_i\le2e_i\right\}\subseteq C_{46},
\qquad
c(C)=\lambda(C).
\]

The exact factorization state is `S(C)=(D(C),c(C))`.

---

## 2. Exact targets

The Type-I divisor-square target is

\[
-4^{-1}\equiv35\pmod{47}.
\]

Its discrete log is

\[
\boxed{\lambda(35)=33.}
\]

Also

\[
\lambda(-1)=23.
\]

Therefore

\[
\boxed{
k=47\text{ misses}
\iff
33\notin D(C)
\text{ and }
c(C)+23\notin D(C).}
\]

---

## 3. Exact finite transition system

One prime-valuation occurrence with log `a` contributes divisor exponents `0,1,2`, so the exact state transition is

\[
\boxed{
T_a(D,c)=\left(D+\{0,a,2a\},\ c+a\right).
}
\]

Repeated occurrences represent arbitrary valuations exactly. Starting from `( {0},0 )`, close under all 46 transition directions.

The least closed system has exactly

\[
\boxed{61,134}
\]

states.

Because every outgoing transition from every state remains inside this finite set, it exhausts arbitrary factorization lengths and valuations. No bound on `p` is used.

---

## 4. Complete fixed-47 classification

Testing the two exact targets on the complete closure gives

\[
\boxed{46,660\text{ hit states}}
\]

and

\[
\boxed{14,474\text{ combined-miss states}.}
\]

Let the exact machine-emitted miss table be `M_47`.

### Theorem

For every Mordell-hard prime `p`, with `C=(p+47)/4`,

\[
\boxed{k=47\text{ misses both Lane-I targets}\iff S(C)\in\mathcal M_{47}.}
\]

No other fixed-47 miss state exists.

By `ES-BINARY-LANE-I-EQUIVALENCE.md`, this is also the complete fixed-47 binary-selector classification.

---

## 5. Pure quadratic support

Quadratic residues are exactly the even discrete logs. If every prime factor of `C` is a quadratic residue modulo 47, then `D(C)` and `c(C)` are even-log objects, while

\[
33\quad\text{and}\quad c(C)+23
\]

are odd.

Hence pure QR support misses both targets universally.

The exact even-direction closure contains

\[
\boxed{1,498}
\]

states, and all 1,498 are misses.

---

## 6. Legendre parity

Because `4` is a square and every hard prime is `1 mod4`,

\[
\left(\frac C{47}\right)
=
\left(\frac p{47}\right)
=
\left(\frac{47}{p}\right).
\]

In the primitive-root coordinate,

\[
\left(\frac C{47}\right)=(-1)^{c(C)}.
\]

Thus

\[
\boxed{(-1)^{c(C)}=\left(\frac{47}{p}\right).}
\]

The 14,474 exact miss states split as

\[
\boxed{7,626\text{ with }(47/p)=+1,}
\]

\[
\boxed{6,848\text{ with }(47/p)=-1.}
\]

So both Legendre branches genuinely contain fixed-shift misses.

---

## 7. Every miss state has a four-nonresidue core

Minimize, over all exact transition paths producing a state,

\[
(\text{number of odd-log valuation units},\ \text{total valuation units}).
\]

The minimum nonresidue counts among the 14,474 miss states are

\[
\boxed{
\begin{array}{c|r}
0&1498\\
1&5187\\
2&5740\\
3&1661\\
4&388
\end{array}}
\]

No miss state requires five or more nonresidue units in a minimum state representative.

Hence

\[
\boxed{\text{every fixed-47 miss state has a state-equivalent core with at most four NR units}.}
\]

As before, this is a statement about finite-group state representatives, not a factor-count bound on the original integer `C`.

Parity is exact:

- `(47/p)=+1` states use minimum counts `0,2,4`;
- `(47/p)=-1` states use minimum counts `1,3`.

Unlike shifts 35, 39, and 43, there is no nontrivial power automorphism of `C_46` that simultaneously fixes the Type-I log 33 and the `-1` log 23. The complete miss table therefore does not collapse through the same simple target-preserving symmetry.

---

## 8. Independent finite regression

`verify_k47_structure.py` independently factors `C`, constructs the divisor set of `C^2` directly modulo 47, and compares direct target membership with the closed state classifier.

The Fedora smoke domain through 100,000 has zero mismatches.

Separately, the preserved CBX 10M standalone relation gives

```text
Mordell-hard primes       20,513
CBX k=47 hits              13,553
state-classifier hits      13,553
mismatches                      0
```

The finite population split is

```text
(47/p)=+1 : 4,071 hits, 6,138 misses
(47/p)=-1 : 9,482 hits,   822 misses
```

These counts are finite evidence only. The fixed-shift theorem is the range-free finite-state closure above.

---

## 9. Corridor-conditioned signal

After the completely classified shifts through `k=43`, the 10M corpus leaves only

\[
\boxed{21}
\]

hard primes entering shift 47.

At `k=47`:

```text
(47/p)=+1 :  2 hits, 6 misses
(47/p)=-1 : 13 hits, 0 misses
```

Therefore

\[
\boxed{15\text{ hit and }6\text{ miss}.}
\]

The absence of a `(47/p)=-1` miss after the earlier corridor is a strong finite theorem-mining signal, but it is **not** asserted universally.

The six finite survivors are

```text
118801
496609
532249
806521
2458369
8803369
```

and their next first-hit distribution is

```text
k=51   1
k=55   2
k=59   2
k=107  1
```

The next symbolic question is sharper than simply classifying `k=51`:

> Can the exact failure laws at `3,7,11,15,19,23,27,31,35,39,43` be combined to prove that a surviving hard prime with `(47/p)=-1` must hit at 47?

A positive answer would be the first genuinely cross-shift Legendre exclusion in this corridor.

---

## 10. Reproduction

```sh
python3 research/erdos-straus/classify_k47_states.py --json
python3 research/erdos-straus/verify_k47_structure.py --limit 100000 --json
```

The exact 14,474-row miss table is emitted by

```sh
python3 research/erdos-straus/classify_k47_states.py --json --table
```

Hard state constants are

```text
total states                    61,134
hit states                      46,660
miss states                     14,474
pure-QR states                   1,498
pure-QR misses                   1,498
Legendre miss split       {+1:7626, -1:6848}
minimum NR histogram      {0:1498, 1:5187, 2:5740, 3:1661, 4:388}
```

---

Erdős–Straus remains open. Fixed `k=47` is completely classified; the most promising new target is the observed disappearance of the `(47/p)=-1` miss branch after the earlier exact corridor constraints.
