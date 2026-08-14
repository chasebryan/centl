# Square-lift towers in the character residual core

**Status:** proved structural reduction and active theorem direction  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note does not prove universal Direct-Shadow Completeness, universal López Type A/B coverage, or the Erdős-Straus conjecture. It refines the square-lift reduction in [SQUARE-LIFT-CORE.md](SQUARE-LIFT-CORE.md).

Read with:

- [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md)
- [SQUARE-LIFT-CORE.md](SQUARE-LIFT-CORE.md)
- [QUADRATIC-SIGNATURE-QUOTIENT.md](QUADRATIC-SIGNATURE-QUOTIENT.md)
- [MULTIPLICATIVE-TRAP-QUOTIENT.md](MULTIPLICATIVE-TRAP-QUOTIENT.md)
- [FIBER-SELECTOR-K1200.md](FIBER-SELECTOR-K1200.md)

## 1. Squarefree kernel

For an odd positive integer `n`, define its squarefree kernel

\[
\operatorname{sf}(n)
=\prod_{v_p(n)\text{ odd}}p.
\]

Thus uniquely

\[
\boxed{n=\operatorname{sf}(n)b^2}
\]

for some positive integer `b`.

Fix a target Type A/B candidate at depth `k`, with

\[
M=4k-1,
\qquad
L=\operatorname{lcm}(840,M),
\qquad
x\equiv r\pmod L.
\]

For an earlier layer `j<k`, write

\[
m_j=4j-1.
\]

## 2. Tower classification theorem

### Theorem

An earlier layer `j` is character-fixed with respect to the target progression if and only if

\[
\boxed{
\operatorname{sf}(m_j)\mid\operatorname{rad}(L).
}
\]

Equivalently, every character-fixed earlier modulus has the form

\[
\boxed{
m_j=a b^2}
\]

where

\[
a\mid\operatorname{rad}(L),
\qquad
a\text{ squarefree}.
\]

Because `m_j=3 mod 4`, necessarily

\[
\boxed{a\equiv3\pmod4}
\]

and `b` is odd.

### Proof

The character-fixed condition says precisely that every prime occurring to odd exponent in `m_j` already divides `L`. Those odd-exponent primes are exactly the prime factors of `sf(m_j)`. Hence

\[
\operatorname{sf}(m_j)\mid\operatorname{rad}(L).
\]

The unique squarefree-square decomposition gives `m_j=a b^2`. Since `b^2=1 mod 4` for odd `b` and `m_j=3 mod 4`, we obtain `a=3 mod 4`. QED.

## 3. Square-lift towers

For a fixed squarefree integer

\[
a\equiv3\pmod4,
\]

define its **square-lift tower** by

\[
\boxed{
m(a,b)=a b^2,}
\qquad b\text{ odd},
\]

with corresponding Type A/B layer index

\[
\boxed{
j(a,b)=\frac{a b^2+1}{4}.}
\]

Every character-fixed earlier layer belongs to one such tower whose base `a` divides `rad(L)`.

The tower is intrinsic to the modulus sequence `4j-1`; it does not depend on the target candidate. The target candidate decides only which tower bases are available through `a|rad(L)` and which of them are character-negative.

## 4. Character coherence theorem

### Theorem

For a fixed target progression `x=r mod L`, every character-fixed layer in the same square-lift tower has the same Jacobi sign:

\[
\boxed{
\left(\frac r{a b^2}\right)
=
\left(\frac r a\right).
}
\]

Therefore the sign is independent of the lift parameter `b`.

### Proof

Prime exponents contributed by `b^2` are even and disappear from the Jacobi symbol. Hence only the squarefree kernel `a` contributes. QED.

### Consequence

A tower is either entirely character-positive or entirely character-negative for a fixed target progression.

Thus the character residual is not naturally indexed by hundreds of earlier layers. It is indexed first by a much smaller set of squarefree tower bases

\[
\boxed{
\mathcal A_{k,r}
=
\left\{
a:\
a\mid\operatorname{rad}(L),
\ a\equiv3\pmod4,
\ \left(\frac r a\right)=-1
\right\}.
}
\]

Only actual tower members `a b^2 < M` contribute earlier rows.

## 5. Odd-square ancestry inside a tower

Suppose `b_1|b_2` and write

\[
b_2=c b_1.
\]

Then `c` is odd and

\[
m(a,b_2)=c^2m(a,b_1).
\]

Hence the corresponding layer indices satisfy

\[
\boxed{
j(a,b_2)
=c^2j(a,b_1)-\frac{c^2-1}{4}.}
\]

Because an odd square satisfies

\[
c^2\equiv1\pmod8,
\]

this is a special square-quotient subfamily of the general modulus-ancestry relation

\[
4j_1-1\mid4j_2-1.
\]

Thus every square-lift tower carries a canonical divisibility ancestry graph controlled simply by divisibility among the odd lift parameters `b`.

## 6. Pullback consequence

For a character-fixed row

\[
m_j=a b^2,
\]

the candidate pullback modulus is

\[
q_j=\frac{m_j}{\gcd(L,m_j)}.
\]

Every prime `p` not dividing `L` that occurs in `q_j` comes from `b^2`, and therefore

\[
\boxed{v_p(q_j)\text{ is even}.}
\]

This recovers the square-lift theorem and now places those even powers inside an explicit tower indexed by `a`.

Moreover, if such an outside prime `p` occurs at all, then

\[
p^2\mid m_j<M,
\]

so

\[
\boxed{p<\sqrt{M}=\sqrt{4k-1}.}
\]

This gives a universal depth-dependent bound on genuinely new prime coordinates after character saturation.

## 7. Finite replay through k <= 1200

The frozen candidate bundle from GitHub Actions run `31846146909` contains `41,470` directly novel candidates.

Among the `11,056` candidates in the Jacobi character residual:

```text
median number of variable negative towers: 1
mean number of variable negative towers:   about 1.110
maximum variable negative towers:          10

median variable fixed-negative rows:       1
mean variable fixed-negative rows:         about 2.284
maximum variable fixed-negative rows:      24
```

Only `3,756` candidates in the complete `41,470`-candidate bundle had more than one variable negative square-lift tower.

One finite maximum-tower example occurs at the already important depth

\[
\boxed{k=1050,}
\]

where one candidate has ten variable negative tower bases:

```text
19, 39, 51, 91, 95, 119, 195, 255, 399, 455
```

These counts are proof-mining observations, not universal bounds. The theorem is the tower decomposition and character coherence, not the finite numbers.

## 8. Why this matters

The residual problem after the character shield has now compressed in two independent directions.

First, [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md) removes genuinely collective squareclass inconsistency.

Second, this note shows the remaining character-negative rows occur in coherent towers

\[
\boxed{a b^2}
\]

and the Jacobi sign is determined entirely by the tower base `a`.

So the unresolved exact arithmetic is more accurately viewed as

\[
\boxed{
\text{a small family of negative squarefree bases}
+\text{ higher p-adic square lifts}
+\text{ exact divisor traps}.
}
\]

That is substantially more rigid than a generic odd covering system.

## 9. New theorem target: tower escape

For one negative tower base `a`, the exact earlier constraints come from the finite lifts

\[
a b^2<M.
\]

The next question is:

> Can all exact Type A/B traps belonging to one negative square-lift tower be avoided by one coherent choice of the higher `p`-adic digits, unless one layer is already an exact direct shadow?

If this can be proved tower by tower, the remaining interaction problem is only to combine the small number of towerwise escape choices.

The hoped-for architecture becomes

\[
\boxed{
\text{direct novelty}
\to
\text{character saturation}
\to
\text{negative square-lift towers}
\to
\text{towerwise p-adic escape}
\to
\text{reduced avoiding progression}.
}
\]

This is now a primary route toward universal DSC-P.

## 10. Novelty boundary

Squarefree kernels, Jacobi symbols, and decompositions `n=a b^2` are classical. The candidate contribution is their use as a **tower decomposition of the López Type A/B minimal-depth character residual**, integrated with shadowing, fiber peeling, and exact-depth realization.

Targeted arXiv searching on 2026-08-14 did not locate this exact tower organization in the López Type A/B minimal-depth setting. That negative search does not establish publication priority.
