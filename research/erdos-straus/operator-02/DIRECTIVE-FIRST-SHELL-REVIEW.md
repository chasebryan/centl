# Operator-02 directive: adversarial review of the single-active first-shell theorem

**Coordinator:** Operator-01 / primary research lead  
**Date:** 2026-08-15  
**Priority:** immediate  
**Parent theorem under review:** [`../SINGLE-ACTIVE-FIRST-SHELL-THEOREM.md`](../SINGLE-ACTIVE-FIRST-SHELL-THEOREM.md)

The primary lane has promoted the former `q in {3,5,9}` finite pattern to a proved theorem note.

Operator-02 is asked to attack the proof independently before publication-grade promotion.

## Claimed theorem

For a fixed-negative squareclass tower under a target modulus `M=4k-1`, if the tower contains exactly one active layer below `M`, then the unique active square parameter is

\[
\boxed{s\in\{3,5\}.}
\]

Therefore the unique active excess quotient is

\[
\boxed{q\in\{3,5,9,25\}.}
\]

For the six Mordell-hard classes modulo `840`, the hard local square condition at `5` eliminates `q=25`, giving

\[
\boxed{|N^{act}|=1\Longrightarrow q\in\{3,5,9\}}
\]

and Class-A-only activity.

## Review targets

### R1. Tower normalization

Check carefully that for a fixed-negative row

\[
m=d s^2
\]

with squarefree kernel `d`, every odd `u` satisfying `d u^2<M` defines another valid earlier fixed-negative layer with the same squarefree kernel and Jacobi sign.

Verify the equivalence

\[
du^2\mid L\iff u^2\mid A=L/d.
\]

### R2. Interval and 2-adic invariant

Check

\[
N^2<M/d\le(N+2)^2
\]

for the largest odd `N` below the target, and hence

\[
cN^2<A\le c(N+2)^2,
\qquad c=L/M=840/\gcd(840,M).
\]

Verify

\[
v_2(A)=3.
\]

### R3. Elimination of s>=9

The proof uses inactivity of `u=3,5,7` to infer

\[
105\mid M,
\qquad c=8,
\]

then obtains an lcm/product contradiction from the two largest inactive odd square positions, with separate cases `s=N`, `s=N-2`, and neither.

Check all inequalities at the boundary `N=9` and monotonicity beyond it.

### R4. Elimination of s=7

The proof gets

\[
c\in\{8,56\}
\]

from the inactive `3` and `5` lifts.

Check:

- the `N>=11` product inequality;
- the exact `N=9` lcm case;
- the exact `N=7` interval and `v_2(A)=3` exclusion.

Try to construct any missed integer `A` in those small intervals.

### R5. Hard-class elimination of q=25

Check that `q=25` forces

\[
s=5,
\quad5\mid d,
\quad v_5(L)=1.
\]

Then verify that `d'=d/5` is again squarefree and `3 mod 4`, and that the Mordell-hard residues satisfy

\[
(r/5)=+1,
\]

so

\[
(r/d')=-1.
\]

Finally verify that

\[
m'=d'5^2=m/5
\]

is an earlier active fixed-negative layer with quotient `5`, contradicting uniqueness.

### R6. Scope

Try to find any hidden dependence on:

- direct novelty;
- primality of the target integer;
- a particular hard class rather than all six;
- exact Type A/B trap membership rather than only target compatibility;
- an unspoken assumption that `d|M`.

The proof is intended **not** to require any of those except hard compatibility for the final `q=25` elimination.

## Deliverable

Create a new Operator-02 note with one of:

1. `VERIFIED` with a section-by-section proof reconstruction;
2. `REVISE` with the exact line/lemma requiring repair;
3. `COUNTEREXAMPLE` with complete arithmetic data.

Do not modify the parent theorem file.

The independently verified `k<=100000` regression is in
[`../SINGLE-ACTIVE-HARD-COLLAPSE-K100000.md`](../SINGLE-ACTIVE-HARD-COLLAPSE-K100000.md), but the review must stand on the proof, not the computation.
