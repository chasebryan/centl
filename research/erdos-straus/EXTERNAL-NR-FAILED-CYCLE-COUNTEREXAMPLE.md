# Counterexample to universal external-NR failed-cycle obstruction

**Status:** exact counterexample to a proposed proof bridge  
**Date:** 2026-08-16  
**Depends on:** `EXTERNAL-NR-FACTOR-CYCLE.md`, `BINARY-EXTERNAL-CYCLE-DEFECT.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Claim boundary:** this does **not** disprove Erdős–Straus. It disproves the proposed intermediate statement that no directed external-nonresidue factor cycle can carry binary/two-target failure at every vertex. The prime below is solved at another shift.

---

## 1. The hard prime

Take

\[
\boxed{p=118801.}
\]

It is prime and

\[
\boxed{p\equiv361\pmod{840},}
\]

so it lies in the Mordell-hard wheel.

The external nonresidue primes

\[
\boxed{113,\ 37,\ 929}
\]

all satisfy

\[
\boxed{
\left(\frac{113}{p}\right)
=
\left(\frac{37}{p}\right)
=
\left(\frac{929}{p}\right)
=-1.
}
\]

---

## 2. Exact directed cycle

For an external prime `q`, recall

\[
R_q=
\begin{cases}
q,&q\equiv3\pmod4,\\
3q,&q\equiv1\pmod4,
\end{cases}
\qquad
A_q=\frac{p+R_q}{4}.
\]

All three vertices here are `1 mod 4`, so their admissible shifts are `3q`.

### Vertex `113`

\[
R_{113}=339,
\]

\[
A_{113}
=\frac{118801+339}{4}
=29785
=5\cdot7\cdot23\cdot37.
\]

The unique external-nonresidue prime factor is `37`, hence

\[
\boxed{113\to37.}
\]

### Vertex `37`

\[
R_{37}=111,
\]

\[
A_{37}
=\frac{118801+111}{4}
=29728
=2^5\cdot929.
\]

The unique external-nonresidue prime factor is `929`, hence

\[
\boxed{37\to929.}
\]

### Vertex `929`

\[
R_{929}=2787,
\]

\[
A_{929}
=\frac{118801+2787}{4}
=30397
=113\cdot269.
\]

The unique external-nonresidue prime factor is `113`, hence

\[
\boxed{929\to113.}
\]

Therefore

\[
\boxed{113\to37\to929\to113}
\]

is an exact directed external-NR factor cycle.

---

## 3. Every vertex fails the exact two-target test

For a fixed admissible shift `R`, put

\[
C=\frac{p+R}{4}.
\]

The divisor-square form of the exact two-target theorem uses

\[
D(C^2)=\{d\bmod R:d\mid C^2\},
\]

with targets

\[
\tau_I=-4^{-1}\pmod R,
\qquad
\tau_{II}=-C\pmod R.
\]

The three cycle vertices give:

| source `q` | shift `R_q` | `C=A_q` | `|D(C^2)|` | `tau_I` | `tau_II` | result |
|---:|---:|---:|---:|---:|---:|---|
| 113 | 339 | 29,785 | 75 | 254 | 47 | both miss |
| 37 | 111 | 29,728 | 26 | 83 | 20 | both miss |
| 929 | 2,787 | 30,397 | 9 | 2,090 | 260 | both miss |

Thus

\[
\boxed{
D(A_q^2)\cap\{\tau_I,\tau_{II}\}=\varnothing
}
\]

for every vertex in the cycle.

---

## 4. Independent binary-collision check

The binary formulation uses

\[
N_q=pA_q
\]

and its signed divisor box modulo `R_q`. By `ES-BINARY-LANE-I-EQUIVALENCE.md`, binary rescue is equivalent to the two-target Lane-I hit above.

Direct signed-box reconstruction gives:

| source `q` | shift `R_q` | signed-box size | `-1` present? |
|---:|---:|---:|---|
| 113 | 339 | 178 | no |
| 37 | 111 | 62 | no |
| 929 | 2,787 | 27 | no |

So the counterexample does not depend on choosing one coordinate system:

\[
\boxed{
\text{every vertex fails both the exact Lane-I test and the equivalent binary collision.}
}
\]

---

## 5. The edge cofactor is factorwise QR

This cycle is especially sharp because every shifted factor has **exactly one** external-nonresidue valuation unit.

Writing

\[
A_q=c_q q_{\rm next},
\]

the cofactors are

\[
\boxed{c_{113}=5\cdot7\cdot23,}
\]

\[
\boxed{c_{37}=2^5,}
\]

\[
\boxed{c_{929}=269.}
\]

Every prime factor of each cofactor is a quadratic residue modulo `p`; by the reciprocity-transfer theorem it is also Jacobi-positive at the corresponding source shift.

Thus even the strongest first-odd-packet shape

\[
\boxed{\text{one simple external-NR edge factor}\times\text{factorwise QR cofactor}}
\]

can persist around a complete failed cycle.

This is the critical falsification.

---

## 6. Why this is not an Erdős–Straus counterexample

The same prime is solved at the ordinary corridor shift

\[
\boxed{k=59.}
\]

There

\[
C_{59}
=\frac{118801+59}{4}
=29715
=3\cdot5\cdot7\cdot283.
\]

The exact Type-II divisor target is

\[
-C_{59}\equiv21\pmod{59},
\]

and the literal divisor

\[
\boxed{21\mid C_{59}^2}
\]

hits it. The Type-I target is also attained, for example by

\[
\boxed{21225\mid C_{59}^2.}
\]

Hence `p=118801` is an ordinary solved prime. It only disproves the proposed universal failed-cycle obstruction.

---

## 7. Research consequence

The following proposed bridge is false:

> no directed external-nonresidue factor cycle can carry binary failure at every vertex.

Even strengthening the edge alphabet to

- odd external-NR packet;
- exactly one external-NR valuation unit;
- factorwise QR cofactor;
- exact binary/two-target failure at every vertex;

does not rescue that statement.

Therefore the cycle program cannot close Erdős–Straus by a **pure local-consistency contradiction around the cycle**.

Any surviving use of the cycle must import information from outside the cycle, for example:

1. another admissible shift attached to the same prime;
2. interaction between the cycle and the consecutive corridor;
3. a global size/order invariant not encoded by the local edge characters;
4. a theorem forcing a non-cycle target such as the observed `k=59` rescue.

The failed cycle is still useful structure, but it is not itself the contradiction.

---

Erdős–Straus remains open. The counterexample closes only this proposed intermediate proof route.
