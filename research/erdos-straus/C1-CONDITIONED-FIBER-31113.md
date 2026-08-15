# C1 conditioned-fiber collapse on the `{3,11,13}` residual family

**Status:** finite theorem-certificate target; exact structure identified through the frozen `k<=1500` C1 bundle  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note records an exact finite structural pattern on the 336 C1 residual systems with prime signature `{3,11,13}`. It is not yet a universal-in-`k` theorem and does not prove full C1, universal DSC-P, López universal coverage, or Erdős-Straus.

Read with:

- [CLASS-C-CENSUS-K1500.md](CLASS-C-CENSUS-K1500.md)
- [SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md](SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md)
- [TRAP-FIBER-BOUND.md](TRAP-FIBER-BOUND.md)
- [FUTURE-OPERATOR-INSTRUCTIONS.md](FUTURE-OPERATOR-INSTRUCTIONS.md)

## 1. Why this family matters

The independently verified C1 census through `k<=1500` contains

\[
\boxed{336}
\]

single-active candidates whose final nonempty fiber kernel has exactly the prime support

\[
\boxed{\{3,11,13\}}.
\]

This is the most frequent small residual kernel after the larger seven-prime family and the cleanest recurring system in which genuine three-coordinate coupling remains.

The question is not merely whether each finite system has one solution. That was already known from the bounded selector certificate.

The question is whether there is a **uniform elimination invariant** explaining why these systems cannot close.

The answer in the frozen range is yes.

## 2. Exact elimination order

For every one of the 336 systems, use the coordinate order

\[
\boxed{11\longrightarrow13\longrightarrow3.}
\]

The residual moduli involve powers no larger than

\[
3^4,\qquad11^3,\qquad13^2.
\]

Start by applying:

1. all unary exact Type A/B constraints on each coordinate;
2. the correct reducedness condition on `x=r+Ls`;
3. then the mixed rows in the order described below.

The resulting finite CSP has an unexpectedly strong extension property.

## 3. Unary 11-adic room

After unary 11-adic rows and reducedness:

- the number of surviving base residue classes modulo `11` is always `6` or `7`;
- the full 11-adic domain is never empty;
- the smallest full 11-adic domain over all 336 systems has size
  \[
  \boxed{6}.
  \]

Thus the first variable always has room before any mixed row is considered.

## 4. Unary 13-adic room

After unary 13-adic rows and reducedness, the number of surviving base classes modulo `13` is always between

\[
\boxed{5\text{ and }8}.
\]

The full 13-coordinate may be modulo `13` or `13^2`, depending on the candidate.

## 5. The 11-to-13 conditioned fiber

Now fix **any** surviving full 11-adic value.

Apply every residual row whose support is contained in `{11,13}`.

### Finite structural result

For every candidate and every surviving full 11-adic value:

\[
\boxed{\text{at least 4 base classes modulo }13\text{ remain safe}.}
\]

Equivalently, the mixed 11/13 rows remove at most two of the unary-safe base 13 classes.

The observed minimum number of surviving **full** 13-adic values per surviving 11-adic value is

\[
\boxed{5}.
\]

When the 13-coordinate has exponent two, the surviving fibers occur in complete mod-13 classes after the finer row is accounted for.

### Fine `13^2` row is conditionally redundant

The residual row with quotient

\[
1859=11\cdot13^2
\]

appears in many of these systems.

Across the entire 336-system family, every forbidden value from a mixed row with 13-exponent greater than one is already removed by unary constraints or by a coarser mixed 11/13 row.

Thus the fine 13-adic row introduces

\[
\boxed{0}
\]

new forbidden points after the coarse 11/13 stage.

This is a finite exact masking statement, not an assumption.

## 6. The conditioned 3-adic fiber

Fix any surviving `(11,13)` assignment after the preceding stage.

Now inspect all residual rows containing the prime `3`.

The common coarse rows live at moduli including

\[
33=3\cdot11,
\quad
117=3^2\cdot13,
\quad
39=3\cdot13,
\quad
429=3\cdot11\cdot13,
\]

with optional higher rows such as

\[
99=3^2\cdot11,
\qquad
1053=3^4\cdot13.
\]

### Mod-3 collapse

Across every unary-safe base `(11,13)` pair in every one of the 336 systems, the rows whose 3-part is exactly `3` collectively forbid at most

\[
\boxed{1}
\]

of the three residues modulo `3`.

So at least two mod-3 classes survive before the mod-9 refinements are considered.

### Mod-9 collapse

After lifting that forbidden mod-3 class to modulo `9` and adding every row with 3-part `9`, the total forbidden set modulo `9` has cardinality at most

\[
\boxed{4}.
\]

Therefore at least

\[
\boxed{5\text{ of the }9}
\]

3-adic residue classes remain safe.

### Fine `3^4` row is conditionally redundant

Whenever the row with 3-part `81` occurs, every one of its forbidden values already lies over a mod-9 class forbidden by the coarser rows.

It contributes

\[
\boxed{0}
\]

new forbidden 3-adic values after the mod-9 stage.

Hence the exact number of safe full 3-adic values conditioned on a surviving `(11,13)` pair belongs to

\[
\boxed{
\{5,6,8,9,45,54,72,81\}.
}
\]

The second half is exactly nine times the first half because safe mod-9 classes lift freely through the `3^4` coordinate.

The global minimum is

\[
\boxed{5}.
\]

## 7. Nested extension theorem for the frozen family

Combining the stages gives the following exact finite statement.

### Finite theorem-certificate

For every one of the 336 C1 residual systems with signature `{3,11,13}` through `k<=1500`:

1. at least one unary-safe 11-adic value exists;
2. **every** unary-safe 11-adic value extends to at least five full 13-adic values after all 11/13 rows;
3. **every** surviving `(11,13)` pair extends to at least five full 3-adic values after every remaining row.

Therefore every initial 11-adic branch has at least

\[
\boxed{25}
\]

full `(13,3)` extensions.

This is much stronger than the existence of one bounded selector.

It proves a branch-survival property for the entire finite family.

## 8. Relation to the two `{11,13}` systems

The two smallest C1 residual systems, both at target depth `k=574`, exhibit the same phenomenon without the 3-coordinate.

In each case:

- `725` full 11-adic values survive unary constraints;
- the unary 13-adic domain contains `78` values, six complete residue classes modulo 13;
- all mixed rows except the `j=36` row are masked by the unary safe sets;
- the `j=36` row removes exactly one 13-class for one special residue modulo 11.

Thus the conditioned 13-fiber has size

\[
65\quad\text{or}\quad78,
\]

and the exact full safe count is

\[
605\cdot78+120\cdot65
=
\boxed{54,990}.
\]

The `{3,11,13}` family is therefore a genuine lift of the same conditioned-fiber geometry.

## 9. What this suggests universally

The original residual systems have nominal cover mass greater than one, so global density bounds fail.

The conditioned-fiber result shows why that statistic is misleading.

The constraints overlap in a way that is exposed only after conditioning coordinate by coordinate:

\[
\boxed{
\text{large global cover mass}
\quad\text{but}\quad
\text{uniformly positive local extension fibers}.
}
\]

The theorem target is now:

### Conditioned Fiber Positivity Conjecture

For every directly novel C1 residual system, there exists an elimination order on the residual prime-power coordinates such that every surviving partial assignment has a positive exact extension fiber at the next coordinate.

A weaker version allowing some partial branches to die while preserving at least one branch would also suffice for C1.

This is not proved universally.

## 10. Immediate proof questions

1. Why do the `3`-linear rows forbid at most one mod-3 class after unary-safe 11/13 conditioning?
2. Why can the mod-9 rows add at most one additional residue outside that lifted class?
3. Why are the `13^2` and `3^4` rows always masked by coarser rows in this family?
4. Which parts follow from ancestry/shadow relations among the fixed row depths `25,36,88,179,205,322,465,520,790`?
5. Can the exact masking be turned into a universal row-domination lemma rather than a finite observation?

Those questions are now considerably sharper than the former “why does a selector exist?” question.
