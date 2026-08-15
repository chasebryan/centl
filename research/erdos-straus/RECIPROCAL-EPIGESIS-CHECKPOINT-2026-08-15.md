# Reciprocal epigesis checkpoint — 2026-08-15

**Branch:** `research/es-reciprocal-fab-duality`  
**Status:** active proof hunt  
**Claim boundary:** Erdős–Straus remains open. This checkpoint distinguishes proved exact reductions, finite evidence, falsified conjectures, and the next universal wall.

## 1. Why this branch exists

The universal DSC route is false and no longer the main ES bridge. The post-DSC program moved to the complete `fab` divisor parametrization and then derived a reciprocal formulation that separates the input prime from the integer being factored.

The branch is intentionally isolated from `main` until the universal existence step is actually closed.

## 2. Proved exact results on this branch

### Reciprocal factor duality

`FAB-RECIPROCAL-DUALITY.md`

For `M=4bc`, a factorization

\[
1+4b^2c=kd
\]

with

\[
k\equiv-p\pmod M
\]

forces

\[
d\equiv-p^{-1}\pmod M
\]

and reconstructs

\[
\boxed{
\begin{aligned}
p+k&=4abc,\\
pd+1&=4bcq,\\
kd&=1+4b^2c,\\
q&=ad-b,\\
kq&=a+bp.
\end{aligned}}
\]

Hence

\[
\boxed{
\frac4p
=
\frac1{abc}
+
\frac1{acq}
+
\frac1{bcpq}.
}
\]

### Two-residue collapse

At fixed `(b,c)`, the factor search for `1+4b^2c` collapses to two least residues, `-p` and `-p^{-1}` modulo `4bc`; no arbitrary divisor enumeration is required.

### Reciprocal fixed-d square criterion

For `d=3 mod4`, put

\[
Y_d=\frac{pd+1}{4}.
\]

A sufficient exact certificate condition is

\[
\boxed{
\exists D\mid Y_d^2:
\quad4D\equiv-1\pmod d.
}
\]

The full fab certificate is reconstructed explicitly from `D`.

### Signed-target collapse

`FAB-RECIPROCAL-SIGNED-TARGET.md`

For

\[
n=\prod r^{e_r},
\]

define

\[
\Sigma_m(n)
=
\left\{
\prod r^{z_r}\pmod m:
-e_r\le z_r\le e_r
\right\}.
\]

Then

\[
\boxed{
\text{reciprocal at }d
\iff
-1\in\Sigma_d(Y_d).
}
\]

The target group element is the constant `-1`, independent of `p`.

### Character transport

`FAB-RECIPROCAL-CHARACTER-TRANSPORT.md`

For Mordell-hard `p`, odd squarefree `d=3 mod4`, and every prime factor `r` of either

\[
X_d=\frac{p+d}{4}
\quad\text{or}\quad
Y_d=\frac{pd+1}{4},
\]

quadratic reciprocity gives

\[
\boxed{
\left(\frac r p\right)=\left(\frac r d\right).
}
\]

Thus the moving factors carry exactly the same quadratic character relative to the target prime and the chosen fab modulus.

### Six exact nonresidue detectors

`FAB-SIX-FORM-NONRESIDUE-DETECTOR.md`

For every hard prime and each

\[
d\in\{3,7,15\},
\]

**both** forward and reciprocal lanes succeed exactly when their base contains a prime factor `r` with

\[
\boxed{(r/p)=-1.}
\]

So a hypothetical hard-prime counterexample must make every prime factor of

\[
\boxed{
\frac{p+3}{4},
\frac{3p+1}{4},
\frac{p+7}{4},
\frac{7p+1}{4},
\frac{p+15}{4},
\frac{15p+1}{4}
}
\]

a quadratic residue modulo `p`.

The six forms have only fixed small pairwise common support.

## 3. Exact finite instruments

### Reciprocal double-sieve probe

`fab_reciprocal_probe.py`

- exact integer search;
- reconstructs complete fab certificate;
- exact cross-multiplication check of the resulting Egyptian fraction;
- emits machine-readable results and hashes.

Independent verifier:

`verify_fab_reciprocal_probe.py`.

Finite result through `p<=50,000,000`:

- Mordell-hard primes: `93,457`;
- captured: `93,457`;
- unresolved: `0`;
- first-success parameter never exceeds `m=59`.

This is finite evidence only.

### Signed-state analyzer

`fab_signed_state_analyzer.py`

Exact finite automaton for bounded signed divisor products modulo `m`. It was used to prove the `m=7` and `m=15` local failure classifications rather than infer them statistically.

## 4. Falsified routes

### Universal DSC

Already false on `main`; not revisited here.

### Naive Euclidean descent

`FAB-EUCLIDEAN-REMAINDER-CRITERION.md`

The exact Euclidean criterion is valid, but the naive map that replaces `M` by four times the least negative remainder has explicit cycles, including one at `p=2521`. Therefore it is not a monotone descent.

### Finite static rotated progression cover

`FAB-NO-FINITE-ROTATED-COVER.md`

No finite list of fixed rotated factor pairs can cover all primes `1 mod4`; Dirichlet supplies infinitely many primes in a residue class missed by every member of such a finite static family.

### Divisor lattice of (p-1)/2

`FAB-DYADIC-DIVISOR-LIFT-CONJECTURE.md` is now marked **falsified**.

Counterexample:

`FAB-DYADIC-DIVISOR-LIFT-COUNTEREXAMPLE.md`.

The hard prime

\[
\boxed{p=9,078,191,439,529}
\]

has

\[
\frac{p-1}{2}
=12\cdot378,257,976,647
\]

with the large factor prime. All twelve nodes `t|(p-1)/2` fail in both lanes. The prime is nevertheless solved immediately at forward `d=31`, corresponding to the missing dyadic node `t=8`.

This cleanly demonstrates that a rigid divisor lattice can be one dyadic level too shallow.

## 5. Dyadic connection to existing CENTL theory

The rescuing node

\[
t=8,
\qquad d=31
\]

is a dyadic/Mersenne-prime node already identified by the repository's older dyadic trap theory as an unusually irredundant source of new residue information.

This suggests that the old dyadic/Mersenne program and the new reciprocal-fab program are not separate stories. The dyadic tower may supply precisely the escape coordinates missed by an input-dependent divisor lattice.

Pure dyadic nodes alone are **not** sufficient in the finite data, so the next target must combine them with moving odd-divisor information rather than replace one rigid family with another.

## 6. Current strongest universal wall

The proof target is no longer a fixed search cap.

It is to construct an **adaptive factor-selection mechanism** with both of these properties:

1. residue-side structure can be supplied from factors already forced by `p-1` or hard-class congruences;
2. some moving cofactor must import an external prime quadratic nonresidue of `p` and place it into the signed target `-1`.

The six-form detector theorem proves exactly what success looks like locally. The remaining step is to force that local event globally.

## 7. Immediate next attacks

1. derive a controlled dyadic-closure theorem rather than conjecturing a fixed closure depth;
2. coordinate the least external quadratic nonresidue of `p` with the reciprocal bases `Y_d`;
3. classify when forced residue-side factors span the full Jacobi-positive kernel at a moving modulus;
4. exploit pairwise-resultant bounds between forward and reciprocal forms so that failure at one node restricts the available factor support at the next;
5. continue adversarial counterexample generation before promoting any new universal statement.

## 8. Research discipline

The branch deliberately records negative results alongside positive ones. A route is promoted only after its universal existence step is proved; finite coverage, density-one behavior, and random high-range success remain evidence rather than conclusions.
