# Audit of Dyachenko 2025 Claimed Constructive Proof

**Status:** internal mathematical audit / prior-art calibration  
**Date:** 2026-08-15  
**Source:** E. Dyachenko, *Constructive Proofs of the Erdős–Straus Conjecture for Prime Numbers with P congruent to 1 modulo 4*, arXiv:2511.07465v1 (2025).  
**Claim boundary:** this note identifies explicit failures in the presented proof route. It does not assert that every algebraic identity or algorithm in the paper is wrong, nor does it prove that no corrected version of the method can work.

---

## 1. Why this paper matters

The paper claims a constructive proof for every prime

\[
P\equiv1\pmod4
\]

using an ED2 parametrization centered on

\[
(4b-1)(4c-1)=4P\delta+1.
\]

That identity and its factor-pair viewpoint are directly relevant to the FCF/CENTL Type A/B and collective-core program.

However, the claimed global existence theorem depends on a geometric lattice-hitting step that fails as stated.

---

## 2. The paper itself distinguishes linear lattice density from the nonlinear identity

In Section 9, the paper explicitly notes that affine-lattice point-counting theorems do **not** by themselves guarantee the nonlinear identity

\[
(4b-1)(4c-1)=4P\delta+1.
\]

An additional existence mechanism is therefore required.

The claimed unconditional bridge is supplied in Section 9.10, especially Lemmas 9.22–9.24 and Proposition 9.25, which are then invoked to support Theorem 9.21.

This is the portion audited below.

---

## 3. Lemma 9.23 is false as written

The paper states, in substance:

> For any modulus `m`, residue `r`, and half-interval `[x0,x0+H)` with `H>=m`, there is exactly one integer in the interval congruent to `r mod m`.

This is false whenever the interval is longer than one modulus.

### Counterexample

Take

\[
m=2,
\qquad r=0,
\qquad [x_0,x_0+H)=[0,5).
\]

Then

\[
H=5\ge2=m,
\]

but the interval contains three integers in the same residue class:

\[
\boxed{0,2,4\equiv0\pmod2.}
\]

So the claimed uniqueness fails.

The correct elementary statement is that an interval of length **exactly** `m` in an appropriate half-open convention contains exactly one representative of each class; an interval of length at least `m` guarantees **at least** one representative, not exactly one.

---

## 4. Proposition 9.25 is independently false

Proposition 9.25 considers the lattice

\[
L=\{(u,v)\in\mathbb Z^2:u b'+v c'\equiv0\pmod g\}
\]

with

\[
\alpha=\gcd(g,b'+c'),
\qquad
d'=g/\alpha,
\]

and claims that every axis-parallel rectangle of width and height at least `d'` intersects `L`.

This statement is false even in the smallest nontrivial case.

### Counterexample

Take

\[
g=2,
\qquad b'=c'=1.
\]

Then

\[
L=\{(u,v):u+v\equiv0\pmod2\},
\]

and

\[
\alpha=\gcd(2,2)=2,
\qquad d'=1.
\]

Consider

\[
R=[0,1)\times[1,2).
\]

Its width and height both equal

\[
1=d'.
\]

The only integer point in `R` is

\[
(0,1),
\]

but

\[
0+1\equiv1\pmod2,
\]

so

\[
(0,1)\notin L.
\]

Therefore

\[
\boxed{L\cap R=\varnothing}
\]

under exactly the stated width/height hypothesis.

Thus Proposition 9.25 is false as a general lattice-hitting theorem.

---

## 5. The proof of Proposition 9.25 also contains a synchronization error

The proof chooses a desired representative `u*` for the first coordinate and a desired representative `v*` for the second coordinate independently.

It then chooses one integer shift `m` from the first coordinate and moves along the diagonal vector

\[
(d',d').
\]

That single shift fixes both coordinates simultaneously.

The argument then concludes that the shifted second coordinate must equal the independently selected `v*` merely because they lie in the same residue class modulo `d'`.

That conclusion is invalid:

1. if the interval length exceeds `d'`, there may be multiple representatives of the class, contradicting the invoked uniqueness claim;
2. even when an interval contains a unique representative, selecting the shift to place the first coordinate does not automatically place the second coordinate in its desired interval unless the two interval positions are synchronized along the diagonal direction.

A one-dimensional diagonal orbit cannot in general hit an arbitrary two-dimensional rectangle solely from separate width bounds.

---

## 6. The nonlinear square/difference condition is not supplied by lattice membership

The paper's own inverse test requires, for suitable parameters,

\[
u=md',
\qquad
u\equiv v\pmod2,
\qquad
u^2-v^2=4A/\alpha.
\]

The final equality is a nonlinear Diophantine condition.

Proposition 9.25, even if repaired to give a lattice point in a rectangle, establishes only membership in a congruence lattice. It does not by itself prove the existence of a point satisfying

\[
u^2-v^2=4A/\alpha.
\]

In Section 9.10 the paper moves from the lattice-hitting proposition to language of “find `v`” satisfying this difference-of-squares equation, but the missing existence argument is precisely the hard step.

So there are two distinct burdens:

1. hit an appropriate lattice/box;
2. hit the nonlinear solution locus inside that lattice/box.

The first does not imply the second.

---

## 7. The appendix itself describes global coverage as conditional

Appendix D labels its residue-covering construction **conditional** and states that a global guarantee that every `P` is hit by a fixed finite list of parameter pairs corresponds to that conditional covering scheme.

Its final summary again distinguishes:

- unconditional algebraic identities and correctness of direct/back tests;
- a **conditional** finite covering scheme.

This is consistent with the gap identified above and inconsistent with treating the global all-prime existence theorem as established solely by the presented geometry.

---

## 8. Responsible conclusion

The paper contains useful algebraic parametrizations and exact identities, especially

\[
(4b-1)(4c-1)=4P\delta+1.
\]

But the presented proof of universal existence for every prime `P=1 mod4` is not established because a load-bearing geometric lemma/proposition is false as stated and the nonlinear difference-of-squares existence step remains unsupported by the lattice-density argument.

Therefore FCF/CENTL should classify the paper as:

```text
algebraic parametrization: useful / to be independently checked
algorithms for verifying a proposed solution: useful
universal all-prime proof claim: NOT ACCEPTED on current argument
```

---

## 9. What to salvage

The following parts are potentially valuable for our program:

1. factor-pair identity
   \[
   (4b-1)(4c-1)=4P\delta+1;
   \]
2. complete checking of a proposed ED2 tuple;
3. the direct divisibility parametrization by `(r,s)`;
4. the separation between affine congruence structure and nonlinear solution structure;
5. the idea of finite covering systems, provided coverage is actually proved rather than inferred from density.

These are naturally compatible with `COLLECTIVE-CORE.md`: a covering theorem must carry an exact finite cover certificate or a valid universal structural proof.

---

## 10. New cross-program question

The useful question is not whether the paper already solved ES. It did not establish that conclusion by the argument audited here.

The useful question is:

\[
\boxed{
\text{Can the ED2 factor-pair parametrization be combined with exact collective-core certificates to supply the missing coverage step?}
}
\]

That is a legitimate secondary route toward the all-prime wall and should be investigated independently of the paper's headline claim.
