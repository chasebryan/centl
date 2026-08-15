# Prior-art audit — recent claimed Erdős–Straus proofs

**Date:** 2026-08-15  
**Status:** source audit / proof triage  
**Claim boundary:** this note identifies specific proof obligations or counterexamples to intermediate statements in public preprints. It is not a priority claim, and it does not establish Erdős–Straus.

Primary sources checked:

- Kyle Bradford, *A solution to the Straus-Erdős conjecture*, arXiv:2602.11774v1.
- E. Dyachenko, *Constructive Proofs of the Erdős–Straus Conjecture for Prime Numbers of the Form P ≡ 1 (mod 4)*, arXiv:2511.07465v1.
- A. Bello-Hernández, M. Benito, F. Fernández, *A Divisor Parametrization for the Erdős–Straus Conjecture*, arXiv:2606.10922v1.

---

## 1. Bradford 2602.11774v1 — covering step not supplied

Bradford derives explicit congruence families from Type I/II forms and then states that combining them will produce a covering system.

The paper ends its mathematical development with the sentence:

> “The last thing that we must show is that this is a covering system.”

No subsequent proof that the displayed residue families cover every prime `p ≡ 1 (mod 4)` appears in v1.

Therefore the preprint supplies useful explicit solution families, but its universal conclusion still requires the global covering statement it itself identifies.

**FCF use:** harvest the valid congruence families; do not treat the universal cover as proved.

---

## 2. Dyachenko 2511.07465v1 — the unconditional box-hitting lemma is false

The paper claims an unconditional ED2 existence theorem. The geometric step is Proposition 9.25.

In the paper's notation,

\[
L=\{(u,v)\in\mathbb Z^2:u b'+v c'\equiv0\pmod g\},
\]

with

\[
\alpha=\gcd(g,b'+c'),
\qquad
d'=g/\alpha.
\]

Proposition 9.25 asserts that every axis-parallel rectangle of width and height at least `d'` meets `L`.

### Exact counterexample

Take

\[
g=2,
\qquad b'=c'=1.
\]

Then

\[
\alpha=\gcd(2,2)=2,
\qquad d'=1,
\]

and

\[
L=\{(u,v)\in\mathbb Z^2:u+v\equiv0\pmod2\}.
\]

Consider

\[
R=[0,1)\times[1,2).
\]

Its width and height are both exactly

\[
1=d'.
\]

Its only integer point is

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

Thus

\[
\boxed{L\cap R=\varnothing}
\]

and Proposition 9.25 is false as stated.

### Where the proof slips

The proof chooses a representative `u*` in the first interval congruent to `u0 mod d'` and independently chooses a representative `v*` in the second interval congruent to `v0 mod d'`.

It then defines a single shift

\[
m=(u^*-u_0)/d'
\]

and moves along the diagonal lattice vector

\[
(d',d').
\]

This guarantees the first coordinate becomes `u*`, but it does **not** imply that the second coordinate becomes the independently chosen `v*`. The two required shifts need not be equal.

The subsequent unconditional existence statement in Theorem 9.21 explicitly invokes Proposition 9.25, so the claimed universal conclusion is not established by that argument.

### The appendix itself preserves a conditional covering burden

Appendix D calls §D.7 a **“Conditional residue covering scheme.”** The direct-algorithm discussion later states that a global guarantee from a fixed finite list corresponds to that conditional covering scheme.

So there is a clean separation between:

- valid ED2 identities and constructors;
- a false box-hitting shortcut;
- a remaining global covering/existence obligation.

**FCF use:** ED2 algebra may be mined, but do not import the unconditional existence claim.

---

## 3. Bello-Hernández–Benito–Fernández 2606.10922v1 — useful complete parametrization, no universal bounded theorem claimed

This paper defines the divisor function `fab(n,a,b)` and proves that its admissible divisors give Erdős–Straus decompositions. It also proves a completeness statement for decompositions of `1/n` with all three denominators divisible by `4`.

For primes `p ≡ 1 (mod 4)`, the paper reports a striking computation:

\[
5\le p<10^{14}
\]

was covered with some

\[
1\le a,b\le11.
\]

The paper explicitly cautions that the bounded window is computational evidence rather than a universal theorem, and gives composite examples requiring larger parameters.

FCF has extracted two exact consequences:

- `FAB-COPRIME-DIVISOR-CRITERION.md`;
- `FAB-HARD-NONRESIDUE-BRIDGE.md`.

These reduce a large part of the search to a divisor-in-residue-class problem and connect hard-class certificates to external quadratic nonresidues.

---

## 4. Net consequence for the CENTL/FCF route

None of the audited recent preprints currently supplies a proof that can simply be imported to close the conjecture.

The useful surviving ingredients are:

1. Bradford: explicit Type I/II congruence families;
2. Dyachenko: algebraic ED2 identities and finite constructors, **not** the unconditional box-hitting claim;
3. Bello et al.: a flexible divisor parametrization and exceptionally strong bounded-parameter computational evidence.

The actual all-prime wall remains a pointwise divisor/covering theorem. This matches the post-DSC `CURRENT-FRONTIER.md`: solve the zero-density prime survivor/composite-rescue core rather than relying on an unproved global cover.
