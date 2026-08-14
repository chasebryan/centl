# Candidate-independent trap-fiber bounds

**Status:** theorem note with exact finite evaluations  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

This note sharpens [FIBER-SHADOW-KERNEL.md](FIBER-SHADOW-KERNEL.md) by removing the candidate dependence from the fiber-width estimate. The key observation is that the affine pullback from a Type A/B trap set to the parameter line preserves CRT fiber multiplicities up to relabeling.

The result gives a much smaller **universal finite prime kernel** than the coarse `|R_j|` load bound.

## 1. Setup

For an earlier layer `j`, put

\[
m_j=4j-1,
\qquad
T_j=\{-e,-4e\pmod{m_j}:e\mid j\}.
\]

For a target candidate `x=r+Ls`, define

\[
g_j=\gcd(L,m_j),
\qquad
q_j=m_j/g_j.
\]

The compatible traps are

\[
U_j=\{u\in T_j:u\equiv r\pmod{g_j}\}.
\]

The pullback forbidden set is

\[
R_j=
\left\{
\frac{u-r}{g_j}\left(\frac{L}{g_j}\right)^{-1}\pmod{q_j}
:u\in U_j
\right\}.
\]

Fix a prime `p|q_j` and write

\[
a=v_p(q_j),
\qquad
q_j=p^a c,
\qquad(p,c)=1.
\]

## 2. Affine fiber invariance

Multiplication by the unit

\[
(L/g_j)^{-1}\pmod{q_j}
\]

is an automorphism of both CRT coordinates

\[
\mathbb Z/q_j\mathbb Z
\cong
\mathbb Z/p^a\mathbb Z\times\mathbb Z/c\mathbb Z.
\]

Therefore it changes only the labels of the fibers, not their cardinalities.

Before that unit scaling, fixing the non-`p` coordinate means fixing

\[
\frac{u-r}{g_j}\pmod c.
\]

Equivalently, it fixes `u` modulo

\[
g_jc
=
\frac{m_j}{p^a}.
\]

Hence the candidate-specific fiber width `f_{j,p}` from the fiber peeling theorem satisfies

\[
\boxed{
f_{j,p}
\le
\kappa_{j,p^a},
}
\]

where

\[
\boxed{
\kappa_{j,p^a}
=
\max_{b\bmod(m_j/p^a)}
\#\{u\in T_j:u\equiv b\pmod{m_j/p^a}\}.
}
\]

The quantity `kappa` depends only on the trap set `T_j` and the prime power dividing `m_j`. It does **not** depend on the target candidate `(k,h,t)`.

## 3. Candidate-independent local contribution

The exponent `a=v_p(q_j)` depends on the target candidate because the gcd with `L` may remove some `p`-power from `m_j`.

To dominate every possible candidate, define

\[
\boxed{
\beta_{j,p}
=
\max_{1\le a\le v_p(m_j)}
\frac{\kappa_{j,p^a}}{p^a}
}
\]

when `p|m_j`, and `beta_{j,p}=0` otherwise.

For every target candidate and every active occurrence of `p` at earlier layer `j`,

\[
\frac{f_{j,p}}{p^{v_p(q_j)}}
\le
\beta_{j,p}.
\]

## 4. Universal reduced fiber load

For a depth bound `K`, define

\[
\boxed{
\mathcal F_p(K)
=
\frac1p
+
\sum_{1\le j<K}\beta_{j,p}.
}
\]

The initial `1/p` is a worst-case allowance for the local reducedness condition. If `p|L`, that cost is actually zero, so this remains an upper bound.

### Theorem

If

\[
\boxed{\mathcal F_p(K)<1,}
\]

then the prime coordinate `p` is reduced-fiber-peelable for **every** admissible Type A/B target candidate at every depth

\[
k\le K.
\]

### Proof

For a fixed candidate, sum the exact reduced fiber load

\[
\Lambda_p^{\!*}
=
\epsilon_p
+
\sum_{j<k,p\mid q_j}
\frac{f_{j,p}}{p^{v_p(q_j)}}.
\]

Here `epsilon_p` is either `0` or `1/p`.

Each active summand is at most `beta_{j,p}`, and the target range `k<=K` only removes terms from the sum defining `F_p(K)`. Therefore

\[
\Lambda_p^{\!*}
\le
\mathcal F_p(K)<1.
\]

The reduced fiber-peeling theorem applies. QED.

## 5. Exact finite evaluations

The quantities below are obtained by exact enumeration of the finite trap sets and exact rational arithmetic. They are finite theorem bounds, not heuristic estimates.

### Through K = 1000

The only primes for which the candidate-independent bound does **not** already prove peelability are

\[
\boxed{
3,5,7,11,13,17,19,23,29,31,37.
}
\]

The last non-automatically-peelable prime is `37`. Therefore

\[
\boxed{
 p\ge41
 \Longrightarrow
 p\text{ is reduced-fiber-peelable for every admissible candidate with }k\le1000.
}
\]

This improves the earlier coarse universal threshold `p>=113` dramatically.

### Through K = 1200

The only primes not eliminated by the universal trap-fiber bound are

\[
\boxed{
3,5,7,11,13,17,19,23,29,31,37,41.
}
\]

Thus

\[
\boxed{
p\ge43
\Longrightarrow
p\text{ is universally reduced-fiber-peelable through }k=1200.
}
\]

### Through K = 1500

The universal finite kernel is contained in

\[
\boxed{
\{3,5,7,11,13,17,19,23,29,31,37,41,43,47\}.
}
\]

Therefore every prime coordinate

\[
\boxed{p\ge53}
\]

is automatically peelable for every admissible candidate through `k=1500`.

### Through K = 3000

Even at the full depth used in the original hard-prime shadow map, the candidate-independent trap-fiber bound leaves only

\[
\boxed{
3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61.
}
\]

as possible first-stage kernel primes.

Hence

\[
\boxed{
p\ge67}
\]

is universally reduced-fiber-peelable through `k=3000`.

This is before using target-specific gcd cancellation, iterative removal of incident constraints, or the exact candidate-specific fibers. All three make the actual kernel smaller.

## 6. Why this is important

The union-shadow problem originally involved parameter periods containing many prime factors and hundreds of active congruence constraints.

The coarse local-load theorem proved that sufficiently large coordinates can be peeled.

The fiber theorem improved the candidate-specific load.

The present bound adds the missing bridge:

\[
\boxed{
\text{trap-set arithmetic itself}
\Longrightarrow
\text{candidate-independent fiber bounds}
\Longrightarrow
\text{small universal finite prime kernel}.
}
\]

Through `k=3000`, before looking at a particular target residue, every potential obstruction has already been forced onto only seventeen small primes.

This is not a universal-in-`k` bounded-prime theorem. The finite universal kernel can grow with `K`. But it is a major compression of the exact finite problem and a concrete route toward a structural proof.

## 7. New object: trap-fiber collision profile

For each earlier layer, the values

\[
\kappa_{j,p^a}
\]

measure how strongly the divisor-generated Type A/B trap set collides when projected away from a prime-power coordinate.

This **trap-fiber collision profile** is a new natural object in the current framework.

The next analytic question is to bound or classify `kappa_{j,p^a}` directly from the divisor structure of `j` and the two trap maps

\[
e\mapsto-e,
\qquad
e\mapsto-4e.
\]

A sufficiently sharp uniform bound on these collision profiles could turn the finite small-kernel phenomenon into an asymptotic theorem.

## 8. Immediate theorem targets

1. derive closed bounds for `kappa_{j,p^a}` using the location of divisors `e|j` inside residue classes modulo `m_j/p^a`;
2. classify cross-collisions between the `-e` and `-4e` trap families inside one fiber;
3. determine whether iterative fiber peeling has an absolute residual-prime bound even though the first candidate-independent bound grows slowly with `K`;
4. classify the residual kernels on the small prime sets above;
5. prove those kernels always possess a reduced satisfying assignment when direct shadowing is absent.

The obstruction has now been compressed twice: first from congruence layers to prime-power coordinates, and then from arbitrary coordinate loads to exact trap-fiber collisions.