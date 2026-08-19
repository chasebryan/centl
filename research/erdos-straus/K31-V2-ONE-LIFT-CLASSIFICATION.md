# Exact `k=31` lift classification when `v_2(C)=1`

**Status:** exact computer-assisted finite-group classification  
**Date:** 2026-08-16  
**Depends on:** `K31-TWO-TARGET-QUOTIENT.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `classify_k31_v2_one.py`  
**Claim boundary:** this closes the residue-group state classification for the fixed shift `k=31` on the branch `v_2((p+31)/4)=1`. The finite-state closure is an exact computation in `C_30`, not a finite prime-range extrapolation. It does not prove that every prime reaches `k=31`, and does not prove Erdős–Straus.

---

## 1. Setup

Let `p` be Mordell-hard and put

\[
\boxed{C=\frac{p+31}{4}}.
\]

This note treats

\[
\boxed{v_2(C)=1}.
\]

Use primitive root `3 mod 31` and write

\[
\lambda(x)=\log_3 x\pmod{30}.
\]

For

\[
C=\prod_iq_i^{e_i},
\]

define the divisor-log box

\[
\boxed{
D(C)=\left\{\sum_i f_i\lambda(q_i):0\le f_i\le2e_i\right\}\subseteq C_{30}
}
\]

and put

\[
\boxed{c=\lambda(C)}.
\]

At `k=31`, the exact Type-I divisor-square target is log `27`, while Type II is log `c+15`. Thus

\[
\boxed{k=31\text{ misses}\iff27\notin D(C)\text{ and }c+15\notin D(C).}
\]

---

## 2. Forced single factor `2`

Because

\[
\lambda(2)=24,
\]

the branch `v_2(C)=1` begins at

\[
\boxed{D_0=\{0,18,24\},\qquad c_0=24.}
\]

Unlike the `v_2(C)\ge2` branch, this three-element packet does not fill the order-five kernel

\[
6\mathbb Z/30\mathbb Z.
\]

The incomplete kernel is exactly what permits a target visible in the `C_6` quotient to fail to lift to the required log in `C_30`.

---

## 3. Exact transition law

One additional prime-valuation occurrence with log

\[
a\in C_{30}
\]

contributes divisor exponents `0,1,2`. Hence the exact state transition is

\[
\boxed{
T_a(D,c)=\bigl(D+\{0,a,2a\},\ c+a\bigr).
}
\]

Repeated valuation of one prime and separate primes in the same residue class obey the same Minkowski-addition law. Therefore every factorization state is obtained by a finite sequence of these transitions.

---

## 4. Finite closure theorem

Starting from `(D_0,c_0)`, `classify_k31_v2_one.py` closes the state system under all thirty maps `T_a` and then checks every outgoing transition from every discovered state.

The cumulative state counts are

\[
\boxed{1,\ 30,\ 325,\ 760},
\]

and the next closure round adds no states.

Thus the least closed state set contains exactly

\[
\boxed{760}
\]

states.

The program explicitly verifies

\[
\boxed{760\cdot30=22,800}
\]

outgoing transitions, with no transition leaving the set.

### Theorem — exact closure

Every possible `v_2(C)=1` divisor-log state modulo `31` lies in this 760-state set. Arbitrarily long factorization sequences cannot create any additional state.

This is a finite-state proof. It is independent of any upper bound on `p`.

---

## 5. Exact miss states

Applying the two exact target tests to all 760 states leaves

\[
\boxed{118}
\]

combined-miss states.

Project logs modulo six. Of those 118 states,

\[
\boxed{101}
\]

already miss in the quotient `C_6`.

The remaining

\[
\boxed{17}
\]

are genuine **lift defects**: at least one target class is visible modulo six, but the incomplete order-five kernel packet fails to lift it to the exact required class modulo thirty.

---

## 6. Human-readable quotient misses

Let

\[
H=\langle2\rangle=\{1,2,4,8,16\},
\]

\[
A=3H=\{3,6,12,17,24\},
\]

\[
B=3^{-1}H=\{11,13,21,22,26\}.
\]

The quotient misses are exactly the same two branches isolated in `K31-TWO-TARGET-QUOTIENT.md`.

### Q1. Pure quadratic support

Every prime factor of `C` is a quadratic residue modulo `31`.

### Q2. Thin `A/B` packet

Every prime factor outside `H` lies in `A\cup B`, every other prime factor lies in `H`, and

\[
\boxed{(E_A,E_B)\in\{(1,0),(0,1),(1,1)\}.}
\]

These 101 quotient-miss states are automatically exact misses. The only extra `v_2=1` phenomenon is the 17 lift-defect states.

---

## 7. Lift-defect symmetry

Multiplication of logs by

\[
\boxed{11\pmod{30}}
\]

is an automorphism of `C_30`. It fixes the forced state because

\[
11\cdot24\equiv24,
\qquad
11\cdot18\equiv18
\pmod{30},
\]

fixes the Type-I target because

\[
11\cdot27\equiv27,
\]

and preserves the Type-II relation because

\[
11\cdot15\equiv15.
\]

Therefore

\[
\boxed{(D,c)\text{ is a lift defect}\iff(11D,11c)\text{ is a lift defect}.}
\]

The 17 lift-defect states collapse to exactly

\[
\boxed{9}
\]

orbits: eight two-state orbits and one fixed state.

---

## 8. Nine canonical lift-defect orbits

For compactness write

\[
M=C_{30}\setminus D.
\]

Each row represents the displayed state and its image under `(D,c)\mapsto(11D,11c)`. The final row is fixed. The witness logs are one shortest sequence of additional valuation-log occurrences reaching the representative from the forced state; they are reachability witnesses, not unique factorization patterns.

| orbit | `|D|` | `c` | missing logs `M` | shortest witness logs |
|---:|---:|---:|---|---|
| 1 | 15 | 4 | `{1,2,6,7,11,12,13,16,17,19,21,22,25,26,27}` | `(5,5)` |
| 2 | 15 | 8 | `{3,4,5,6,10,11,12,13,17,19,20,23,26,27,29}` | `(7,7)` |
| 3 | 19 | 26 | `{5,6,10,11,12,16,17,23,25,27,29}` | `(13,19)` |
| 4 | 21 | 29 | `{1,3,6,11,14,17,22,25,27}` | `(19,16)` |
| 5 | 23 | 5 | `{13,17,19,20,21,23,27}` | `(4,7)` |
| 6 | 23 | 7 | `{3,11,17,19,22,25,27}` | `(8,5)` |
| 7 | 23 | 23 | `{5,8,11,19,21,25,27}` | `(13,16)` |
| 8 | 27 | 5 | `{13,20,27}` | `(17,7,17)` |
| 9 | 29 | 12 | `{27}` | `(25,28,25)` |

Every row omits log `27`, as required. Its Type-II target `c+15` also lies in the displayed missing set.

---

## 9. Exact `v_2=1` classification

### Theorem

Let `p` be Mordell-hard and

\[
C=\frac{p+31}{4},
\qquad
v_2(C)=1.
\]

Compute the exact state `(D(C),c)` in base-3 logarithms modulo `31`.

Then both exact Lane-I targets miss at `k=31` **if and only if** either:

1. the factorization lies in quotient branch Q1 or Q2; or
2. the quotient contains a target, but `(D(C),c)` belongs to one of the nine automorphism orbits in Section 8.

No other `v_2=1` miss state exists.

### Proof

The closure theorem exhausts every possible factorization state. Exact target testing leaves 118 misses. Quotient testing identifies 101 of them as Q1/Q2 states. The remaining 17 are exactly partitioned by the nine automorphism orbits. QED.

---

## 10. Fixed `k=31` is now completely classified

`K31-TWO-TARGET-QUOTIENT.md` gives the elementary exact classification for

\[
v_2(C)\ge2.
\]

This note gives the exact finite-group classification for

\[
v_2(C)=1.
\]

Every Mordell-hard prime has `2\mid C`, so the two branches exhaust all cases. Therefore the fixed shift

\[
\boxed{k=31}
\]

now has a complete exact two-target classification.

This does **not** prove that every hard prime hits by `31`; it classifies success and failure at this one shift.

---

## 11. Independent finite 10M cross-check

On the preserved hard-prime corpus through

\[
p\le10^7,
\]

there are `20,513` Mordell-hard primes. Exactly

\[
\boxed{10,243}
\]

have `v_2((p+31)/4)=1`.

Their exact `k=31` outcomes are

```text
exact hits                  6,642
quotient-miss exact misses  3,528
lift-only exact misses         73
```

so the total `v_2=1` miss count is `3,601`.

After the earlier corridor shifts through `k=27`, only `113` of the 217 remaining targets lie in `v_2=1`. Of those,

```text
84 hit at k=31
28 miss already in the quotient
 1 is a genuine lift-only miss
```

The lone finite lift-only survivor is

\[
\boxed{p=2,315,161,}
\]

with

\[
C=578,798=2\cdot11\cdot26,309.
\]

These prime-range counts are supporting evidence only. The 760-state classification itself is range-free finite-group exhaustion.

---

Erdős–Straus remains open. Fixed `k=31` is classified; the global existence of a successful shift remains the proof problem.
