# Exact two-target filter at the prime shift `k=31`

**Status:** proved exact combined Type-I/Type-II classification  
**Date:** 2026-08-16  
**Depends on:** `K31-TWO-TARGET-QUOTIENT.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Machine certificate for `v_2(C)=1`:** `classify_k31_v2_one.py`  
**Independent finite regression for `v_2(C)>=2`:** `verify_k31_v2_quotient.py`  
**Claim boundary:** this closes the fixed Lane-I shift `k=31` for Mordell-hard primes. It does not prove that every smaller-shift survivor must hit at `31`, does not establish a universal finite Lane-I bound, and does not prove Erdős–Straus.

---

## 1. Setup

Let `p` be Mordell-hard and write

\[
P=\frac{p-1}{4}.
\]

Since every hard prime satisfies

\[
p\equiv1\pmod{24},
\]

we have

\[
P\equiv0\pmod6.
\]

At shift

\[
\boxed{k=31}
\]

put

\[
\boxed{C=\frac{p+31}{4}=P+8.}
\]

Therefore

\[
\boxed{2\mid C.}
\]

Hence exactly one of the two branches occurs:

\[
\boxed{v_2(C)=1}
\]

or

\[
\boxed{v_2(C)\ge2.}
\]

The first branch is classified by an exact finite-state closure in `C_30`; the second is classified by an exact quotient theorem in `C_6`.

---

## 2. Logarithmic coordinates and exact targets

The unit group

\[
G=(\mathbb Z/31\mathbb Z)^\times
\]

is cyclic of order `30`. Use primitive root `3` and write

\[
\lambda(x)=\log_3 x\pmod{30}.
\]

The constants are

\[
\boxed{\lambda(2)=24,}
\qquad
\boxed{\lambda(-1)=15.}
\]

The Type-I divisor-square target is

\[
-4^{-1}\equiv23\pmod{31},
\]

with

\[
\boxed{\lambda(23)=27.}
\]

Let

\[
c=\lambda(C)\pmod{30}
\]

and let

\[
\mathcal D(C)
\]

be the divisor-log set of `C^2`.

By the exact divisor-square formulation,

\[
\boxed{\text{Type I hits}\iff27\in\mathcal D(C),}
\]

and

\[
\boxed{\text{Type II hits}\iff c+15\in\mathcal D(C).}
\]

Therefore

\[
\boxed{
\text{combined miss}
\iff
27\notin\mathcal D(C)
\text{ and }
c+15\notin\mathcal D(C).}
\]

---

## 3. The branch `v_2(C)>=2`

The residue `2` has order five modulo `31`. Let

\[
\boxed{H=\langle2\rangle=\{1,2,4,8,16\}.}
\]

In logarithmic coordinates,

\[
\lambda(H)=\{0,6,12,18,24\}.
\]

When

\[
v_2(C)\ge2,
\]

the divisors of the `2`-part of `C^2` already fill this entire kernel. Exact target membership therefore descends without loss to

\[
C_{30}/\lambda(H)\cong C_6.
\]

`K31-TWO-TARGET-QUOTIENT.md` proves the resulting quotient classification completely.

Define

\[
\boxed{A=3H=\{3,6,12,17,24\}}
\]

and

\[
\boxed{B=3^{-1}H=\{11,13,21,22,26\}.}
\]

Let

\[
E_A=\sum_{q^e\parallel C,\ q\bmod31\in A}e,
\]

\[
E_B=\sum_{q^e\parallel C,\ q\bmod31\in B}e.
\]

### Theorem A — exact `v_2(C)>=2` branch

Assume

\[
v_2(C)\ge2.
\]

Then both exact targets miss at `k=31` if and only if exactly one of the following holds.

1. **Pure quadratic branch.** Every prime factor of `C` is a quadratic residue modulo `31`.

2. **Thin quotient branch.** Every prime factor of `C` outside `H` lies in `A union B`, every remaining factor lies in `H`, and
   \[
   \boxed{(E_A,E_B)\in\{(1,0),(0,1),(1,1)\}.}
   \]

Every other `v_2(C)>=2` factorization hits at least one exact target.

This theorem is proved directly in the quotient note; no finite-state certificate is needed for this branch.

---

## 4. The branch `v_2(C)=1`

Now assume

\[
\boxed{v_2(C)=1.}
\]

The forced factor `2` contributes divisor exponents `0,1,2`. Since

\[
\lambda(2)=24,
\]

the initial divisor-log state is

\[
\boxed{
D_0=\{0,24,18\},
\qquad
c_0=24.}
\]

The single factor `2` does **not** fill the order-five kernel `H`, so reduction modulo `6` can lose information. The exact lift must therefore be classified in `C_30`.

---

## 5. Exact finite-state transition law

Split every additional prime power

\[
q^e\parallel C/2
\]

into `e` identical valuation units. If

\[
a=\lambda(q)\pmod{30},
\]

then one valuation unit contributes divisor exponents `0,1,2`, hence the local log packet

\[
\boxed{\{0,a,2a\}.}
\]

Therefore one exact transition is

\[
\boxed{
(D,c)
\longmapsto
\left(D+\{0,a,2a\},\ c+a\right)
}
\]

for

\[
a\in C_{30}.
\]

Here `+` on divisor sets is Minkowski sum modulo `30`.

This transition is exact for arbitrary prime-power exponents because splitting exponent `e` into `e` valuation units loses no divisor exponent: sums of `e` choices from `{0,1,2}` realize every integer from `0` through `2e`.

---

## 6. Why the state closure is universal

Starting from

\[
(D_0,c_0),
\]

close under every one of the 30 possible transitions `a=0,...,29`.

The closure stabilizes at exactly

\[
\boxed{760\text{ states}.}
\]

The classifier then checks all

\[
\boxed{760\times30=22,800}
\]

outgoing transitions and verifies that every one lands back inside the closed state set.

This is an exhaustive finite-group closure, not a prime-range search.

Every actual factorization with `v_2(C)=1` maps to a path in this state graph: each prime-valuation unit has some log `a`, and applying its transition appends precisely its divisor-log contribution and center contribution. Therefore every arithmetically realizable `v_2=1` state is contained in the 760-state closure.

The abstract closure may contain states not realized by any prime `p`; that only makes the classifier conservative. It does not omit any actual factorization state.

---

## 7. Exact miss table for `v_2(C)=1`

For every reachable state `(D,c)`, the exact miss predicate is simply

\[
27\notin D
\]

and

\[
c+15\notin D.
\]

The exhaustive closure contains exactly

\[
\boxed{118\text{ combined-miss states}.}
\]

`classify_k31_v2_one.py` emits **all 118 rows**, including

- the exact divisor-log set `D`;
- its size;
- the center `c`;
- both exact targets;
- its modulo-6 quotient image;
- the missing log classes;
- a shortest abstract transition witness from the forced-2 state.

Thus:

### Theorem B — exact `v_2(C)=1` branch

Assume

\[
v_2(C)=1.
\]

Then both exact targets miss at `k=31` if and only if the exact divisor-log state

\[
(\mathcal D(C),\lambda(C))
\]

is one of the 118 rows emitted by

```sh
python3 research/erdos-straus/classify_k31_v2_one.py --json
```

This is a complete fixed-group classification of the branch.

---

## 8. Quotient-visible misses versus genuine lift defects

Reduce a `v_2=1` state modulo the kernel `H`, equivalently reduce its logs modulo `6`.

Among the 118 exact combined-miss states:

\[
\boxed{101}
\]

already miss in the `C_6` quotient.

The remaining

\[
\boxed{17}
\]

are genuine lift defects:

\[
\boxed{
\text{both quotient targets appear, but the exact C_30 targets still miss}.}
\]

So the quotient is nearly exact on this branch but not quite. Those 17 states are precisely the obstruction to extending the `v_2>=2` quotient theorem unchanged to `v_2=1`.

---

## 9. Exact symmetry of the lift defects

Multiplication by

\[
\boxed{11}
\]

is an automorphism of `C_30` because `gcd(11,30)=1`.

It preserves the forced state:

\[
11D_0=D_0,
\qquad
11c_0=c_0.
\]

It also preserves the two-target form:

\[
11\cdot27\equiv27\pmod{30},
\]

and

\[
11(c+15)
\equiv11c+15\pmod{30}
\]

because

\[
11\cdot15\equiv15\pmod{30}.
\]

Therefore

\[
(D,c)
\mapsto
(11D,11c)
\]

is an exact symmetry of the miss predicate.

The 17 lift-only miss states form exactly

\[
\boxed{9\text{ orbits}}
\]

under this involution: eight two-element orbits and one fixed state.

---

## 10. The nine lift-defect orbit representatives

The following table records one representative from each exact orbit. `Missing logs` means the complement of `D` in `C_30`.

| orbit | `|D|` | `c` | missing logs | orbit size |
|---:|---:|---:|---|---:|
| 1 | 15 | 4 | `1,2,6,7,11,12,13,16,17,19,21,22,25,26,27` | 2 |
| 2 | 15 | 8 | `3,4,5,6,10,11,12,13,17,19,20,23,26,27,29` | 2 |
| 3 | 19 | 26 | `5,6,10,11,12,16,17,23,25,27,29` | 2 |
| 4 | 21 | 29 | `1,3,6,11,14,17,22,25,27` | 2 |
| 5 | 23 | 5 | `13,17,19,20,21,23,27` | 2 |
| 6 | 23 | 7 | `3,11,17,19,22,25,27` | 2 |
| 7 | 23 | 23 | `5,8,11,19,21,25,27` | 2 |
| 8 | 27 | 5 | `13,20,27` | 2 |
| 9 | 29 | 12 | `27` | 1 |

For every row, both

\[
27
\]

and

\[
c+15
\]

are absent from `D`.

The ninth orbit is fixed by the symmetry and is especially sharp:

\[
\boxed{
c=12,
\qquad
D=C_{30}\setminus\{27\}.}
\]

Here the two targets coincide:

\[
c+15=27,
\]

and the divisor box misses exactly that one class.

The classifier also stores shortest abstract transition witnesses for these representatives. Those witnesses certify reachability in the finite state machine; they are not assertions that the corresponding abstract log sequences occur as prime factorizations.

---

## 11. Complete fixed-shift theorem at k=31

### Theorem

Let `p` be Mordell-hard and put

\[
C=\frac{p+31}{4}.
\]

Then both exact Lane-I targets miss at `k=31` if and only if exactly one of the following branch conditions holds.

### Branch I: `v_2(C)>=2`

Either

1. every prime factor of `C` is a quadratic residue modulo `31`; or
2. every factor outside
   \[
   H=\{1,2,4,8,16\}
   \]
   lies in
   \[
   A=\{3,6,12,17,24\}
   \]
   or
   \[
   B=\{11,13,21,22,26\},
   \]
   every remaining factor lies in `H`, and
   \[
   (E_A,E_B)\in\{(1,0),(0,1),(1,1)\}.
   \]

### Branch II: `v_2(C)=1`

The exact state

\[
(\mathcal D(C),\lambda(C))
\]

is one of the 118 explicitly emitted miss states of `classify_k31_v2_one.py`.

Equivalently, on the `v_2=1` branch the miss is either one of the 101 quotient-visible miss states or one of the 17 lift-only states in the nine symmetry orbits above.

In every other case at least one exact target hits, so `p` has an Erdős–Straus decomposition at shift `31`.

---

## 12. Machine-checkable closure constants

The `v_2=1` classifier hard-checks the following exact constants:

```text
reachable states                  760
transition closure checks      22,800
combined miss states              118
quotient-visible miss states       101
lift-only miss states               17
emitted exact miss rows            118
lift-defect symmetry orbits           9
```

The Fedora theorem workflow independently requires all of those values and verifies that the 118 emitted rows split exactly as `101 + 17`.

The `v_2>=2` theorem is separately replayed by `verify_k31_v2_quotient.py` against finite hard-prime corpora. That replay is regression evidence only; the branch theorem itself is the quotient proof in `K31-TWO-TARGET-QUOTIENT.md`.

---

## 13. Corridor status

The exact consecutive Lane-I corridor is now classified through

\[
\boxed{k=3,7,11,15,19,23,27,31.}
\]

By `ES-BINARY-LANE-I-EQUIVALENCE.md`, these are simultaneously exact consecutive binary-selector classifications.

The finite `p<=10^7` first-hit census leaves only

\[
\boxed{65}
\]

Mordell-hard primes after the first eight shifts through `31`, but that is finite evidence only.

The next fixed shift is

\[
\boxed{k=35.}
\]

A separate `k=35` structural reduction is already present in the repository. The highest-value next step is to combine the eight exact failure laws and the `k=35` structure rather than reopening any of the now-closed shifts.

---

Erdős–Straus remains open. This theorem closes one fixed shift exactly; it does not provide the missing universal existence argument across shifts.
