# Canonical q^2 Type-II square lifts lie on the López boundary

**Status:** proved exact structural theorem  
**Date:** 2026-08-16  
**Depends on:** `ES-TYPEII-ROOT-GEOMETRY.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `Q23-SQUARE-LIFT-PHASE-SIEVE.md`  
**Claim boundary:** this classifies the geometry of the canonical divisor `d=q^2` at a genuine q-adic square lift. It does not say that every square lift hits, that every Type-II hit is comparable-root, or that blocked canonical phases miss the full signed box.

---

## 1. Setup

Let `q` be prime and let an admissible fixed shift `k` have

\[
C=\frac{p+k}{4}.
\]

Suppose the q-adic valuation has reached a genuine square lift

\[
\boxed{q^2\mid C}.
\]

The canonical square-lift divisor is

\[
\boxed{d=q^2}.
\]

If this divisor reaches the exact Type-II target,

\[
\boxed{d\equiv-C\pmod k},
\]

then it is an exact Type-II certificate at that shift.

The question here is not whether the congruence holds. It is: **where does this certificate sit inside the full Type-II root geometry?**

---

## 2. Root decomposition

The canonical Type-II root coordinates are defined by

\[
d=sb^2,
\qquad
\frac{C^2}{d}=sc^2,
\qquad
C=sbc,
\]

with `s` squarefree.

For

\[
d=q^2,
\]

the decomposition is immediate:

\[
\boxed{s=1,\qquad b=q,\qquad c=\frac Cq}.
\]

Because the lift is genuinely square,

\[
q^2\mid C,
\]

one has

\[
q\mid\frac Cq.
\]

Therefore

\[
\boxed{b\mid c}.
\]

By the exact root-comparability theorem,

\[
\boxed{b\mid c\iff\text{López Type A at the same Type-II layer}.}
\]

---

## 3. Theorem

### Canonical square-lift boundary theorem

If `q` is prime, `q^2|C`, and the canonical divisor

\[
d=q^2
\]

satisfies the exact Type-II target

\[
d\equiv-C\pmod k,
\]

then the resulting Type-II certificate is necessarily a **López Type-A boundary certificate**.

Its canonical root data are

\[
\boxed{(s,b,c)=\left(1,q,\frac Cq\right)},
\]

with

\[
\boxed{b=q\mid c=C/q}.
\]

Thus a canonical q-square-lift hit can never be an incomparable-root Type-II certificate.

---

## 4. What this changes in the q23 phase sieve

The q23 square-lift phase sieve studies

\[
q=23,
\qquad
q^2=529,
\]

and deliberately tests the canonical divisor

\[
d=529.
\]

Consequently every **successful canonical** Type-II event in that sieve lies on the López Type-A boundary.

This includes both pinned earliest realized anchors.

### Route A anchor

For

\[
p=3,051,374,929,
\qquad
k=755,
\]

one has

\[
C=762,843,921=23^2\cdot1,442,049.
\]

The canonical root data are

\[
\boxed{(s,b,c)=(1,23,33,167,127)},
\]

and

\[
23\mid33,167,127.
\]

The shift is Type-II-only, but its canonical Type-II certificate is still López-boundary.

### Route B anchor

For

\[
p=13,874,535,529,
\qquad
k=295,
\]

one has

\[
C=3,468,633,956=23^2\cdot6,556,964.
\]

The canonical root data are

\[
\boxed{(s,b,c)=(1,23,150,810,172)},
\]

again with

\[
23\mid150,810,172.
\]

This shift contains both Type I and Type II; the canonical Type-II component remains López-boundary.

---

## 5. Why this sharpens the active search

The q23 phase sieve has thirteen phases where the canonical `d=23^2` boundary certificate is arithmetically allowed and ten where that specific certificate is blocked.

The new interpretation is sharper:

```text
allowed canonical phase
    -> may realize a specific López-A boundary Type-II certificate

blocked canonical phase
    -> only that specific boundary certificate is unavailable
    -> Type I remains possible
    -> noncanonical comparable-root Type II remains possible
    -> incomparable-root Type II remains possible
```

So the ten blocked phases are especially valuable laboratories for the full geometry. They are places where the canonical boundary mechanism has been removed **without** removing Type II itself.

A full signed-box hit in a blocked phase should therefore be classified by its actual divisor/root geometry rather than described merely as a failure of the q23 lift.

---

## 6. Integration with the candidate decomposition framework

`TYPEII-CANDIDATE-DECOMPOSITION-FRAMEWORK.md` treats q-adic valuation phase as one coordinate and the full signed box as the terminal geometry.

This theorem separates those coordinates cleanly:

> the canonical q^2 valuation certificate is not a new interior Type-II mechanism; it is a deterministic route into the López-A boundary sector.

The larger decomposition framework remains essential because a blocked canonical boundary transition may still terminate through another boundary divisor, an incomparable-root divisor, or Type I.

Accordingly, the next high-value refinement is not merely to count allowed versus blocked q23 phases. It is to classify the **noncanonical terminal geometry** of the blocked phases that nevertheless hit.

---

## 7. Research consequence

The full Type-II program now has a useful controlled experiment:

1. force a q^2 square lift;
2. use the phase sieve to remove the canonical `d=q^2` boundary certificate on blocked phases;
3. evaluate the complete signed box;
4. classify every surviving Type-II hit as comparable or incomparable;
5. study whether the exact survivor state predicts which replacement mechanism appears.

That is a direct way to expose genuinely non-López geometry without pretending that López itself has been disproved or rendered irrelevant.

Erdős–Straus remains open.
