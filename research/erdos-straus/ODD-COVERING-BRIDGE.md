# Type A/B shadow pullbacks as a structured odd-covering problem

**Status:** theory bridge / prior-art orientation  
**Date:** 2026-08-14  
**Claim boundary:** this note does not claim a solution of the Erdos-Selfridge odd covering problem, Direct-Shadow Completeness, Lopez Type A/B coverage, or the Erdos-Straus conjecture.

This note connects the FCF/CENTL shadow program to classical covering-system theory.

Read with:

- [DIAMOND.md](DIAMOND.md)
- [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md)
- [DIRECT-SHADOW-K1000.md](DIRECT-SHADOW-K1000.md)
- [SHADOW-COVER-GEOMETRY.md](SHADOW-COVER-GEOMETRY.md)
- [PRIOR-ART.md](PRIOR-ART.md)

## 1. Pullback formulation

For a fixed admissible Type A/B candidate `(k,h,t)`, write

\[
x=r+Ls,
\qquad L=\operatorname{lcm}(840,4k-1).
\]

Every earlier layer `j<k` induces a forbidden parameter system

\[
s\bmod q_j\in R_j,
\qquad
q_j=\frac{4j-1}{\gcd(L,4j-1)}.
\]

Because every `4j-1` is odd, every nontrivial pullback modulus `q_j` is odd.

Thus union-shadowing of the candidate is exactly the statement that the structured family

\[
\mathscr R_{k,h,t}
=
\{s\equiv a\pmod{q_j}:a\in R_j,\ j<k\}
\]

covers all integers.

A direct shadow is the degenerate local case where one earlier layer alone supplies all residue classes modulo its `q_j`.

Direct-Shadow Completeness asks whether, for this special Type A/B-generated family, collective covering can ever occur without such a local complete layer.

## 2. Relation to the Erdos-Selfridge odd covering problem

Classical covering-system theory studies finite unions of congruence classes that cover all integers. A famous open problem of Erdos and Selfridge asks whether a covering system can exist with all moduli odd, distinct, and greater than one.

Relevant sources include:

- Song Guo and Zhi-Wei Sun, *On odd covering systems with distinct moduli*, arXiv:math/0412217.
- Jackson Hopper, *On covering systems of integers*, arXiv:1705.04372.
- Joshua Harrington, Yewen Sun, Wing Hong Tony Wong, *Covering systems with odd moduli*, arXiv:2104.00602.
- Chris Bispels et al., *A further investigation on covering systems with odd moduli*, arXiv:2507.16135.

A 2026 formalization by Ibrahim Mian and Shayaan Siddique, arXiv:2607.25628, gives kernel-checked finite exclusions for the distinct-odd-modulus problem while explicitly treating the general problem as open.

The Type A/B pullback problem is **not identical** to the Erdos-Selfridge problem:

1. pullback moduli `q_j` can repeat;
2. one earlier layer can contribute multiple residue classes `R_j` at the same modulus;
3. the residues are not arbitrary: they are affine pullbacks of divisor-generated trap sets
   \[
   T_j=\{-e,-4e\pmod{4j-1}:e\mid j\};
   \]
4. the moduli themselves arise as quotients of `4j-1` by gcds with a fixed candidate modulus `L`;
5. prime-realization requires a reduced uncovered class, not merely an uncovered integer.

Therefore a proof of DSC-P would establish a no-cover theorem for a special arithmetic subclass of odd covering systems, not resolve the general odd covering problem.

## 3. Why this bridge matters

The covering-system viewpoint gives precise language for the obstruction we are trying to understand.

General proper congruence classes can collectively cover the integers. Consequently,

\[
R_j\neq\mathbb Z/q_j\mathbb Z\ \forall j
\]

is nowhere near enough in an arbitrary covering problem.

But in the exact Type A/B computations through `k=1000`, every directly novel candidate admits a reduced uncovered progression.

Thus the research question is now:

> What arithmetic property of the divisor-generated Type A/B pullback family prevents it from behaving like an arbitrary odd covering system?

That question should be attacked using both the special algebra of `T_j` and known covering-system obstructions.

## 4. A prime-power coordinate model

Let

\[
Q=\operatorname{lcm}\{q_j:R_j\neq\varnothing\}
=
\prod_{\ell}\ell^{a_\ell}.
\]

Then the parameter line modulo `Q` decomposes by CRT into prime-power coordinates

\[
\mathbb Z/Q\mathbb Z
\cong
\prod_{\ell}\mathbb Z/\ell^{a_\ell}\mathbb Z.
\]

Each forbidden system `(q_j,R_j)` depends only on the coordinates corresponding to prime powers dividing `q_j`.

This turns Direct-Shadow Completeness into a finite constraint-satisfaction problem on an odd prime-power product.

A useful taxonomy is:

- **unary constraints:** `q_j` is a prime power, so the event depends on one coordinate;
- **binary constraints:** `q_j` has two distinct prime factors;
- **higher-support constraints:** `q_j` has three or more distinct prime factors.

Preliminary diagnostics on difficult certified candidates show a strong concentration in unary and binary support. This suggests that the pullback family may have a low-complexity local core even while the raw number of earlier constraints is large.

## 5. Canonical coordinate experiment

For each prime-power coordinate `ell^a` of `Q`:

1. combine all unary Type A/B constraints acting only on that coordinate;
2. choose an allowed local residue, preferring `1` whenever it survives;
3. combine the local choices by CRT;
4. count the remaining violated multi-prime constraints;
5. attempt to repair them by changing the smallest possible number of prime-power coordinates while preserving all unary constraints.

This is not merely a faster witness search. It asks whether the global survivor can be **constructed locally**.

If every directly novel candidate admits a survivor after a bounded number of local repairs, that would suggest a much sharper theorem than raw DSC-P.

## 6. Candidate theorem hierarchy

### Coordinate-Core Conjecture

Every directly novel Type A/B pullback family has a prime-power coordinate assignment satisfying all unary constraints and all but finitely controlled multi-prime obstructions.

### Bounded-Repair Conjecture

There exists an absolute or structurally bounded repair number `B` such that every directly novel candidate can be made globally avoiding by changing at most `B` prime-power coordinates from a canonical unary-safe assignment.

### DSC-P

Every directly novel candidate has a reduced avoiding parameter class and therefore infinitely many exact-depth prime realizations.

A proof of a strong bounded-repair theorem could imply DSC-P by an explicit construction.

## 7. Proof mechanisms to investigate

1. **Unary saturation:** classify when the combined prime-power-only constraints can cover a coordinate. Determine whether such local saturation is equivalent to a direct shadow or forces one elsewhere.
2. **Binary graph structure:** build the graph whose vertices are prime-power coordinates and whose edges are binary pullback constraints. Study degeneracy, cores, cycles, and whether the forbidden edge relations have a common algebraic orientation.
3. **Residue 1 bias:** the trap fact `1 notin T_j` may survive affine pullback in a weakened coordinate form, making the all-ones assignment a natural base point except on a small exceptional set of coordinates.
4. **Minimal-cover contradiction:** assume a minimal Type A/B union cover and apply classical covering-system necessities to its odd moduli, then use the special divisor-generated residues to contradict minimality.
5. **Character signatures:** test quadratic and higher multiplicative characters of the allowed and forbidden local residues.
6. **Prime-power valuation signatures:** test whether forbidden pullbacks force incompatible valuation patterns around `r+Ls+e` or `r+Ls+4e`.

## 8. Research significance

This bridge sharpens the novelty target.

The generic concept of a congruence covering is classical and must not be claimed as new. The candidate novelty is that the Lopez Type A/B system appears to generate a special family of odd covering problems with an unexpectedly strong local-to-global noncoverage phenomenon.

If universal DSC-P is proved, one defensible interpretation would be:

> Type A/B first-hit realizability admits a complete local obstruction theory because the associated divisor-generated odd pullback systems cannot collectively cover unless a direct shadow is already present.

That would be a theorem about a structured subclass of odd covering systems and, simultaneously, a theorem about the exact-depth geometry of the Erdos-Straus Type A/B system.

## 9. Immediate work

The project should now run two attacks in parallel:

- continue exact candidatewise falsification beyond `k=1000`;
- mine the certified `k<=1000` bundle for the prime-power coordinate invariant that explains the absence of covers.

The second attack is now higher value than merely extending the numerical range.