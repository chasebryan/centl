# Current research frontier: from shadow completeness to the fiber kernel

**Date:** 2026-08-14  
**Status:** active theorem program  
**Claim boundary:** Erdős-Straus remains open; universal López Type A/B coverage and universal Direct-Shadow Completeness remain unproved.

This is the short moving-frontier record. The full synthesis remains [DIAMOND.md](DIAMOND.md).

## What is now exact

The candidatewise Direct-Shadow attack has reached `k<=1200`:

- `57,367` admissible hard-compatible Type A/B candidates;
- `15,897` directly shadowed candidates;
- `41,470` directly novel candidates;
- `41,470/41,470` explicit integer avoiding witnesses;
- `41,470/41,470` reduced avoiding progressions;
- `0` unresolved integer candidates;
- `0` unresolved reduced candidates;
- independent verifier verdict: `VERIFIED`;
- CENTL exact certification of selected hardest progression identities;
- hashes and artifact publication completed successfully.

See [DIRECT-SHADOW-K1200.md](DIRECT-SHADOW-K1200.md).

The universal conjecture remains open, but no candidatewise union-shadow counterexample has appeared through twelve hundred layers.

## Exact coordinate locality through k=1200

The first complete prime-power coordinate-core diagnostic is also frozen for all `41,470` directly novel candidates.

A canonical unary-safe local assignment already solves

\[
15,715/41,470=37.895\%
\]

of the candidates.

Using each already-certified reduced witness only as a guide for which local coordinate values to substitute, every candidate can be reached from that basepoint by at most

\[
\boxed{9}
\]

prime-power coordinate changes.

The cumulative guided upper bounds are:

```text
0 changes: 37.895%
<=1:       71.264%
<=2:       88.847%
<=3:       96.122%
<=4:       98.727%
<=5:       99.612%
<=6:       99.908%
<=7:       99.990%
<=8:       99.998%
<=9:      100.000%
```

These repair counts are not proven minimal and do not independently establish witness existence. They are proof-mining evidence that the globally large congruence systems have surprisingly low local repair complexity.

## The covering-system bridge

For a candidate `x=r+Ls`, every earlier Type A/B layer induces a forbidden system

\[
s\bmod q_j\in R_j,
\qquad q_j=(4j-1)/\gcd(L,4j-1).
\]

Every nontrivial `q_j` is odd. Union shadowing is therefore a special structured odd covering problem.

The general Erdős-Selfridge odd covering problem is classical and open; our system is a much more restricted divisor-generated subclass with repeated moduli and multi-residue layers. See [ODD-COVERING-BRIDGE.md](ODD-COVERING-BRIDGE.md).

## Prime-power peeling theorem

Write

\[
Q=\prod_p p^{A_p}
\]

for the total parameter period. For coordinate `p`, define

\[
\lambda_p
=
\sum_{p\mid q_j}\frac{|R_j|}{p^{v_p(q_j)}}.
\]

If

\[
\lambda_p<1,
\]

then `p` can be removed from the satisfiability problem: any solution of the constraints not involving `p` can be extended to a value of the `p^{A_p}` coordinate satisfying every incident constraint.

Adding the one local residue forbidden by the reducedness condition gives the augmented version used for prime realization.

See [SHADOW-KERNEL.md](SHADOW-KERNEL.md).

## Universal finite large-prime elimination

Using only the trap sizes and the implication `p|q_j => p|4j-1`, define the conservative candidate-independent bound

\[
B_p(k)
=
\frac{1+\sum_{j<k,\ p\mid4j-1}|T_j|}{p}.
\]

At `k=1000`, exact evaluation gives `B_p(1000)<1` for every prime `p>=113`, so every admissible candidate in that range can universally shed all parameter-prime coordinates at least `113` before the true obstruction is considered.

At `k=1200`, the analogous first bound pushes the possible universal kernel only through the small-prime region: primes `p>=127` are automatically peelable under the same conservative criterion.

Candidate-specific elimination is much stronger.

## New theorem: fiber peeling

The coarse local load still charges every prime coordinate for all of `|R_j|`, even though after the other coordinates are fixed only one fiber of `R_j` can matter.

For

\[
q_j=p^{a_{j,p}}c,
\qquad(p,c)=1,
\]

let `f_{j,p}` be the maximum number of forbidden `p^{a_{j,p}}` residues lying above any one fixed value modulo `c`.

Define

\[
\Lambda_p
=
\sum_{p\mid q_j}\frac{f_{j,p}}{p^{a_{j,p}}}.
\]

Then

\[
\boxed{\Lambda_p<1}
\]

is an exact stronger peeling criterion. Adding the local reducedness cost produces `Lambda_p^*` for prime realization.

See [FIBER-SHADOW-KERNEL.md](FIBER-SHADOW-KERNEL.md).

This is a genuine theoretical advance over the raw candidate search: it explains how a coordinate can be eliminated by the internal fiber geometry of the Type A/B forbidden sets.

## Fiber-kernel proof mining

An exact analyzer, [`shadow_fiber_kernel_analyzer.py`](shadow_fiber_kernel_analyzer.py), now implements this theorem candidate by candidate without using the stored avoiding witness to decide peelability.

Exploratory diagnostics from the already verified `k<=1000` bundle are striking:

- an evenly distributed `5,000`-candidate diagnostic sample had an empty fiber kernel in `3,686` cases, about `73.7%`;
- every nonempty residual kernel in that sample used primes at most `23`;
- the two dominant nonempty signatures were `{3,11,13}` and `{3,5,11,13,17,19,23}`;
- the difficult `(k,h,t)=(987,169,3935)` case collapsed to `{3,11,13}`;
- the `(648,529,2585)` case peeled completely.

These sample statistics remain proof-mining diagnostics until a complete automated bundle freezes the fiber analysis across the entire candidate range. The fiber peeling theorem itself is exact regardless of those sample numbers.

## Next automated attack

The workflow has now been expanded to run four distinct stages after discovery:

1. independent candidate verifier;
2. coordinate-core locality diagnostic;
3. exact coarse shadow-kernel peeling;
4. exact fiber shadow-kernel peeling;
5. CENTL symbolic certification, hashing, and artifact publication.

The next configured falsification target is

\[
\boxed{k\le1500}
\]

with witness search through

\[
\boxed{s\le3,000,000}.
\]

This deliberately crosses the earlier record-depth region around `k=1403` and `k=1435` while simultaneously testing whether the new kernel machinery continues to compress the obstruction.

No result from that next run should be treated as established until all verification and certification stages finish green.

## The problem we are actually trying to solve now

The immediate theorem target has become much more precise:

> Prove that every directly novel Type A/B pullback system peels to a small-prime fiber kernel, and prove that every such kernel has a reduced satisfying assignment.

A successful proof would give universal DSC-P:

\[
\text{not directly shadowed}
\Longrightarrow
\text{reduced avoiding class}
\Longrightarrow
\text{infinitely many exact-depth primes}.
\]

If that succeeds, the shadow graph becomes a complete obstruction theory for Type A/B first-hit realizability.

That is the present edge of the diamond.