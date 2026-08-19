# Exact `k=31` two-target quotient classification when `v_2(C)>=2`

**Status:** proved exact classification on the `v_2(C)>=2` branch  
**Date:** 2026-08-16  
**Depends on:** `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`, `K27-TWO-TARGET-STRUCTURE.md`  
**Claim boundary:** this completely classifies the fixed shift `k=31` when the shifted integer `C=(p+31)/4` has 2-adic valuation at least two. The `v_2(C)=1` branch remains separate. This does not prove Erdős-Straus.

---

## 1. Setup and the forced factor 2

Let `p` be Mordell-hard and put

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

The exact theorem below treats the branch

\[
\boxed{v_2(C)\ge2.}
\]

---

## 2. Logarithmic coordinates modulo 31

The unit group

\[
G=(\mathbb Z/31\mathbb Z)^\times
\]

is cyclic of order `30`. Use primitive root `3` and write

\[
\lambda(x)=\log_3 x\pmod{30}.
\]

The residues needed below are

\[
\boxed{\lambda(2)=24,}
\]

\[
\boxed{\lambda(-1)=15.}
\]

The fixed Type-I divisor-square target is

\[
-4^{-1}\equiv-8\equiv23\pmod{31},
\]

and

\[
\boxed{\lambda(23)=27.}
\]

Thus, in divisor-log coordinates,

\[
\boxed{\text{Type I target}=27.}
\]

If

\[
c=\lambda(C),
\]

then Type II is the translated divisor-log target

\[
\boxed{c+15.}
\]

---

## 3. The factor 2 fills an order-five kernel

The residue `2` has order five modulo `31`. Define

\[
\boxed{H=\langle2\rangle=\{1,2,4,8,16\}.}
\]

In log coordinates,

\[
\lambda(H)=6\mathbb Z/30\mathbb Z
=\{0,6,12,18,24\}.
\]

If

\[
v_2(C)=e\ge2,
\]

then divisors of the `2`-part of `C^2` contribute

\[
\{0,24,48,72,96\}\pmod{30}
=\{0,24,18,12,6\}.
\]

Hence

\[
\boxed{\text{the `2`-part alone fills all of }\lambda(H).}
\]

Let

\[
\pi:C_{30}\to C_{30}/6\mathbb Z\cong C_6
\]

be reduction modulo `6` in logarithmic coordinates. Because the full kernel is already present in the divisor box, exact target membership is equivalent to target membership after applying `pi`.

So the `v_2(C)>=2` branch is not merely approximated by a quotient: it is **exactly reduced to `C_6`**.

---

## 4. The two quotient targets

Write

\[
C=2^eM,
\qquad M\text{ odd}.
\]

Since

\[
\lambda(2)=24\equiv0\pmod6,
\]

the quotient log of `C` is just

\[
\bar c=\lambda(M)\pmod6.
\]

The two targets become

\[
\boxed{\tau_I=27\equiv3\pmod6,}
\]

and

\[
\boxed{\tau_{II}=\bar c+15\equiv\bar c+3\pmod6.}
\]

For each prime-power occurrence in `M`, write

\[
d=\lambda(q)\pmod6.
\]

A valuation unit contributes the divisor-log packet

\[
\boxed{\{0,d,2d\}\subseteq C_6.}
\]

Repeated valuation units in the same quotient direction add by Minkowski sum.

---

## 5. Pure quadratic support is an exact combined miss

A unit modulo `31` is a quadratic residue exactly when its `3`-log is even. Therefore the quadratic residues occupy the three even quotient classes

\[
\boxed{d\in\{0,2,4\}\pmod6.}
\]

If every prime factor of `C` is a quadratic residue modulo `31`, the quotient divisor box is contained in

\[
\{0,2,4\}.
\]

Also `bar c` is even. Hence both targets

\[
3,
\qquad
\bar c+3
\]

are odd and lie outside the quotient box.

### Theorem A — pure-QR branch

If every prime factor of `C=(p+31)/4` is a quadratic residue modulo `31`, then

\[
\boxed{\text{Type I and Type II both miss at }k=31.}
\]

This holds for every `v_2(C)`, but it is one branch of the exact `v_2(C)>=2` classification below.

---

## 6. Any `d=3` factor is an immediate Type-I hit

If some prime-factor occurrence of `M` satisfies

\[
\lambda(q)\equiv3\pmod6,
\]

then its local divisor packet is

\[
\{0,3,0\},
\]

which contains the Type-I quotient target `3`.

Therefore every combined miss must avoid quotient class `3`.

---

## 7. Mixing a nonzero even class with an odd `±1` class fills `C_6`

A factor in quotient class `2` or `4` contributes

\[
\{0,2,4\}.
\]

A factor in quotient class `1` contributes

\[
\{0,1,2\},
\]

while class `5=-1` contributes

\[
\{0,5,4\}.
\]

Direct addition gives

\[
\boxed{\{0,2,4\}+\{0,1,2\}=C_6,}
\]

and

\[
\boxed{\{0,2,4\}+\{0,5,4\}=C_6.}
\]

Hence a non-pure combined miss cannot contain any quotient-`2/4` factor together with a quotient-`1/5` factor.

Since the case with no odd factor is exactly the pure-QR branch, every **non-pure** miss must therefore use only quotient classes

\[
\boxed{0,1,5.}
\]

---

## 8. Exact thin-packet classification in `C_6`

Assume now that the factorization is not pure quadratic support and that all quotient directions lie in

\[
\{0,1,5\}.
\]

Let

\[
e_+=\sum_{q^a\parallel M,\ \lambda(q)\equiv1\ (6)}a,
\]

\[
e_-=\sum_{q^a\parallel M,\ \lambda(q)\equiv5\ (6)}a.
\]

The quotient-`0` factors are inert. The remaining divisor-log box is the cyclic interval

\[
\boxed{
U(e_+,e_-)
=\{-2e_-,-2e_-+1,\ldots,2e_+\}
\pmod6.
}
\]

The total quotient log is

\[
\boxed{\bar c=e_+-e_-\pmod6.}
\]

We now test the two exact targets.

### One positive packet

If

\[
(e_+,e_-)=(1,0),
\]

then

\[
U=\{0,1,2\},
\qquad
\bar c=1.
\]

The targets are `3` and `4`, so both miss.

### One negative packet

If

\[
(e_+,e_-)=(0,1),
\]

then

\[
U=\{0,4,5\},
\qquad
\bar c=5.
\]

The targets are `3` and `2`, so both miss.

### One packet in each direction

If

\[
(e_+,e_-)=(1,1),
\]

then

\[
U=\{0,1,2,4,5\}=C_6\setminus\{3\},
\qquad
\bar c=0.
\]

Both targets coincide at `3`, and both miss.

### Every larger packet hits

If either

\[
e_+\ge2
\]

or

\[
e_-\ge2,
\]

then the interval `U(e_+,e_-)` contains `3 mod6`. Therefore Type I hits.

Thus the three packets above are the only non-pure misses.

---

## 9. Residue-coset form

The kernel subgroup is

\[
\boxed{H=\{1,2,4,8,16\}.}
\]

The two thin nonresidue cosets are

\[
\boxed{A=3H=\{3,6,12,17,24\},}
\]

and

\[
\boxed{B=3^{-1}H=\{11,13,21,22,26\}.}
\]

The remaining quotient cosets are forbidden in a non-pure miss.

Define the total valuations

\[
E_A=\sum_{q^e\parallel C,\ q\bmod31\in A}e,
\]

\[
E_B=\sum_{q^e\parallel C,\ q\bmod31\in B}e.
\]

### Theorem B — exact `v_2(C)>=2` classification

Let `p` be Mordell-hard and

\[
C=\frac{p+31}{4},
\qquad
v_2(C)\ge2.
\]

Then both exact Lane-I targets miss at `k=31` **if and only if** exactly one of the following holds.

1. **Pure quadratic branch.** Every prime factor of `C` is a quadratic residue modulo `31`.

2. **Thin quotient branch.** Every prime factor of `C` outside `H` lies in `A union B`, every remaining factor lies in `H`, and
   \[
   \boxed{(E_A,E_B)\in\{(1,0),(0,1),(1,1)\}.}
   \]

In every other `v_2(C)>=2` case, at least one exact target hits and `p` satisfies Erdős-Straus at shift `31`.

### Proof

The full `2`-part fills the kernel `H`, so exact target membership is equivalent to target membership in the quotient `C_6`. Sections 5 through 8 exhaust the quotient directions and prove that the only miss states are the pure even branch and the three displayed `±1` packets. Translating quotient classes back to residue cosets gives the statement. QED.

---

## 10. Independent finite regression signal

The preserved standalone Lane-I corpus through

\[
p\le10^7
\]

contains

\[
\boxed{20,513}
\]

Mordell-hard primes.

Among those with

\[
v_2((p+31)/4)\ge2,
\]

there are

\[
\boxed{10,270}
\]

targets.

Independent factorization and the theorem above agree with the exact CBX `k=31` hit relation on all of them:

\[
\boxed{0\text{ mismatches}.}
\]

The theorem-side classification counts on that finite corpus are:

```text
hit by theorem complement : 6510
pure QR miss              : 2952
thin (0,1) miss           : 347
thin (1,0) miss           : 313
thin (1,1) miss           : 148
```

These counts are supporting finite evidence only; the classification itself is the quotient proof above.

---

## 11. Position after the first seven shifts

On the preserved `p<=10^7` corridor, the first six classified shifts

\[
3,7,11,15,19,23
\]

leave `308` targets. Shift `27` removes `91`, leaving

\[
\boxed{217}.
\]

Shift `31` removes `152`, leaving

\[
\boxed{65}.
\]

Inside those 217 targets, the theorem above exactly classifies every case with `v_2(C)>=2`:

```text
68 hits
26 pure-QR misses
7 thin (0,1) misses
3 thin (1,1) misses
```

The remaining unresolved part of the fixed `k=31` classification is therefore the genuinely thin branch

\[
\boxed{v_2(C)=1.}
\]

That is the next local theorem target.

---

Erdős-Straus remains open. This theorem closes one exact branch of one fixed shift; it is not a universal finite-shift bound.
