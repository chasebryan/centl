# Infinite exact-depth structural gap families

**Status:** proved corollary family inside the Type A/B minimal-depth program  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this does not prove the Erdős-Straus conjecture, universal López Type A/B coverage, or universal Direct-Shadow Completeness. It proves that the minimal Type A/B depth spectrum has explicit infinite structural gaps.

Read with:

- [DEPTH-SPECTRUM.md](DEPTH-SPECTRUM.md)
- [RECIPROCITY-TOWER-SHADOWS.md](RECIPROCITY-TOWER-SHADOWS.md)
- [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md)
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md)

## 1. Exact-depth spectra

Define

\[
\mathcal D_{\exists}
=
\{k\ge1:\exists\text{ prime }p\text{ with }C_{AB}(p)=k\}
\]

and the stronger infinite-realization spectrum

\[
\mathcal D_{\infty}
=
\{k\ge1:\text{infinitely many primes }p\text{ satisfy }C_{AB}(p)=k\}.
\]

Clearly

\[
\mathcal D_{\infty}\subseteq\mathcal D_{\exists}.
\]

A **structural gap** is a depth `k` at which every Type A/B hit is already forced to have occurred at an earlier layer. Such a depth lies outside `D_exists`, not merely outside a finite computation.

## 2. Reciprocity-gap theorem

### Theorem

For every integer `n>=1`, none of the three depths

\[
\boxed{3n^2+3n+1,}
\]

\[
\boxed{7n^2+7n+2,}
\]

or

\[
\boxed{15n^2+15n+4}
\]

can be the first Type A/B hit of any prime.

Equivalently,

\[
\boxed{
\{3n^2+3n+1:n\ge1\}
\cup
\{7n^2+7n+2:n\ge1\}
\cup
\{15n^2+15n+4:n\ge1\}
\subseteq
\mathbb N\setminus\mathcal D_{\exists}.
}
\]

### Proof

[RECIPROCITY-TOWER-SHADOWS.md](RECIPROCITY-TOWER-SHADOWS.md) proves that these three target families are respectively fully shadowed by the earlier layers `1`, `2`, and `4`.

If an integer, and in particular a prime, lands in the target trap set at one of those later depths, reduction to the corresponding earlier modulus lands in the earlier trap set. Therefore the later depth cannot be its first hit. QED.

## 3. Dyadic-gap theorem

### Theorem

Let

\[
b\ge4
\]

and suppose

\[
b+2
\]

is composite. Then

\[
\boxed{2^b\notin\mathcal D_{\exists}.}
\]

### Proof

Put

\[
r=b+2.
\]

Because `r>=6` is composite, it has a proper divisor

\[
d
\]

with

\[
3\le d<r.
\]

Set

\[
a=d-2.
\]

Then

\[
1\le a<b
\]

and

\[
a+2=d\mid r=b+2.
\]

The dyadic shadow theorem gives

\[
T_{2^b}\bmod(2^{a+2}-1)=T_{2^a}.
\]

Thus every hit at depth `2^b` is already a hit at the earlier depth `2^a`, so `2^b` cannot be a first hit. QED.

### Simple infinite subfamily

Every even `b>=4` satisfies that `b+2` is even and at least `6`, hence composite. Therefore

\[
\boxed{
2^{2s}\notin\mathcal D_{\exists}
\qquad(s\ge2).
}
\]

So the exact-depth spectrum has an explicit infinite exponentially sparse family of permanent gaps in addition to the three quadratic families.

## 4. The complement is infinite and unbounded

The reciprocity-gap theorem alone gives three unbounded quadratic sequences outside `D_exists`. Therefore

\[
\boxed{
\mathbb N\setminus\mathcal D_{\exists}
\text{ is infinite and unbounded}.
}
\]

This rules out any hypothesis that every sufficiently large depth eventually occurs as a minimal Type A/B witness depth.

The missing depths are structural, not finite-search latency.

## 5. The realized spectrum is also infinite and unbounded

The prime-modulus backbone gives the opposite result.

If

\[
q=4k-1
\]

is prime and `q>7`, then

\[
\boxed{k\in\mathcal D_{\infty}.}
\]

Indeed infinitely many primes have exact depth `k`.

There are infinitely many primes

\[
q\equiv3\pmod4,
\]

so there are infinitely many corresponding depths

\[
k=\frac{q+1}{4}.
\]

Therefore

\[
\boxed{
\mathcal D_{\infty}
\text{ is infinite and unbounded}.
}
\]

## 6. Two-sided spectrum theorem

Combining the previous sections gives:

### Theorem

The López Type A/B minimal witness-depth spectrum is permanently nontrivial in both directions:

\[
\boxed{
\mathcal D_{\infty}
\text{ is infinite and unbounded},
}
\]

while

\[
\boxed{
\mathbb N\setminus\mathcal D_{\exists}
\text{ is also infinite and unbounded}.
}
\]

Thus the spectrum contains infinitely many depths supporting infinitely many prime first hits and infinitely many depths supporting **no** prime first hit at all.

This is an exact theorem, not an empirical observation.

## 7. Structural gaps versus latency gaps

This theorem sharpens the distinction introduced in [DEPTH-SPECTRUM.md](DEPTH-SPECTRUM.md).

A **latency gap** is an apparently empty finite-search depth that eventually appears at a larger prime, as happened at `k=104`.

A **structural gap** is impossible by theorem because the whole target layer is shadowed.

The new infinite families provide explicit structural-gap certificates:

```text
reciprocity gap: target layer is shadowed by j=1,2,or4

dyadic gap: target layer is shadowed by an earlier dyadic ancestor
```

No increase in the prime-search bound can ever populate these depths.

## 8. Interleaving with the backbone

The depth line therefore contains at least three kinds of locations:

1. **proved infinite-realization nodes**, including every prime-modulus backbone depth;
2. **proved structural gaps**, including the reciprocity and dyadic shadow families above;
3. **unclassified nodes**, whose realization depends on the deeper shadow/tower/exact-residue theory.

The emerging problem is not to show that the spectrum is eventually full. It is to classify this interleaving.

## 9. Relation to Direct-Shadow Completeness

Universal DSC-P would turn direct shadowing into a complete exact-depth classification:

\[
\boxed{
\text{directly shadowed}
\iff
\text{structural gap},
}
\]

and

\[
\boxed{
\text{directly novel}
\iff
\text{infinitely prime-realizable}.
}
\]

The theorem families in this note prove substantial infinite portions of the first direction without assuming DSC-P.

The prime-modulus backbone proves an infinite portion of the second.

This makes the universal DSC-P conjecture a proposed bridge between two already nontrivial infinite theorem families.

## 10. Research significance

The exact-depth spectrum is therefore not just a numerical record sequence attached to `C_AB`.

It has proved arithmetic geometry:

\[
\boxed{
\text{infinite arrival families}
+
\text{infinite forbidden families}
+
\text{shadow ancestry between them}.
}
\]

A complete classification of that geometry would be a substantial structural theorem about the López Type A/B congruence system even independently of universal Erdős-Straus coverage.

## 11. Novelty boundary

Dirichlet's theorem, quadratic reciprocity, Mersenne divisibility, and López Type A/B congruences are prior mathematics. The candidate contribution is the resulting **minimal-depth spectrum with explicit infinite exact-depth arrival and structural-gap families generated by the shadow framework**.

Targeted searches through 2026-08-15 have not located this exact minimal-depth spectrum formulation in the existing Erdős-Straus literature. That negative search does not establish publication priority.
