# Current research frontier

**Date:** 2026-08-15  
**Claim boundary:** Erdős--Straus remains open. Universal López Type A/B coverage remains open. Universal DSC-0 and DSC-P are false. The square-divisor mechanism itself is prior art going back at least to Thépault; the active FCF contribution is the structural synthesis described below, with literature priority still under review.

---

## 1. Main route correction

The universal direct-shadow bridge is closed as a route to Erdős--Straus:

\[
\boxed{\mathrm{DSC\!\!-0}\text{ false},
\qquad
\mathrm{DSC\!\!-P}\text{ false}.}
\]

The explicit hosted counterexample remains in `DSC-COUNTEREXAMPLE.md`.

Strong/weak/pointwise `q=3` absorption, finite exact-depth certificates, character quotients, ancestry, and the shadow hypergraph remain valid mathematics. They are now supporting structure rather than the universal proof bridge.

---

## 2. Exact prime Erdős--Straus coordinate

For prime

\[
p\equiv1\pmod4
\]

and an admissible shift

\[
k\equiv3\pmod4,
\qquad
\gcd(k,p)=1,
\]

put

\[
C_k=\frac{p+k}{4}
=\prod_i r_i^{e_i}
\]

and define the symmetric signed divisor box

\[
\boxed{
\mathcal R_k(C_k)
=
\left\{
\prod_i r_i^{z_i}\pmod k:
-e_i\le z_i\le e_i
\right\}.}
\]

`ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md` proves the exact equivalence

\[
\boxed{
 p\text{ satisfies Erdős--Straus}
\iff
\exists k:
\{-p^{-1},-1\}\cap\mathcal R_k(C_k)\ne\varnothing.}
\]

The targets are the standard prime solution types:

\[
\boxed{\tau_I=-p^{-1}}
\]

for Type I and

\[
\boxed{\tau_{II}=-1}
\]

for Type II.

Inversion symmetry gives the second Type-I orientation

\[
\boxed{-p.}
\]

Thus an unsolved fixed shift must avoid

\[
\boxed{-p^{-1},\ -p,\ -1.}
\]

---

## 3. Historical square-divisor coordinate and provenance

The divisor-of-a-square Type-II mechanism is **not** new.

At least as far back as Thépault's 1979 work, one finds a sufficient condition of the form

\[
\boxed{
b\mid a^2,
\qquad
4a-1\mid bp+a.}
\]

Later public work and Bradford's 2024 preprint also use complete divisor-of-a-square coordinates.

The present equivalent coordinate is

\[
\boxed{
d\mid a^2,
\qquad
4a-1\mid p+4d,}
\]

which is carried to Thépault's form by divisor complement

\[
d\longleftrightarrow a^2/d.
\]

See `SQUARE-COMPLETION-PRIOR-ART.md`.

Do not claim FCF novelty for `d|a^2`, square-divisor Type II, or a generic divisor-square parametrization.

---

## 4. The active synthesis: López A/B are boundary orthants of the full Type-II square box

Fix a layer

\[
a\ge1,
\qquad
m_a=4a-1.
\]

Define the square-completed Type-II layer

\[
\boxed{
S_a
=
\{-4D\pmod{m_a}:D\mid a^2\}.}
\]

The ordinary López Type-A/B layer is

\[
T_a
=
\{-e,-4e:e\mid a\}.
\]

`ES-SQUARE-COMPLETION-TRAP-GEOMETRY.md` proves

\[
\boxed{T_a\subseteq S_a}
\]

at the **same modulus**.

Write

\[
a=\prod_i\ell_i^{E_i},
\qquad
D=\prod_i\ell_i^{U_i},
\qquad
0\le U_i\le2E_i.
\]

Then:

- López Type A is the lower orthant
  \[
  U_i\le E_i\quad\forall i;
  \]
- López Type B is the upper orthant
  \[
  U_i\ge E_i\quad\forall i;
  \]
- genuinely additional Type-II certificates are the **mixed** points, with some coordinates below and some above the midpoint.

The exact number of mixed divisor parameters is

\[
\boxed{
M(a)=\tau(a^2)-2\tau(a)+1.}
\]

It vanishes exactly when `a` is a prime power.

Therefore

\[
\boxed{
\omega(a)=1
\Longrightarrow
S_a=T_a.}
\]

All new completed geometry is localized to multi-prime layer indices.

---

## 5. Exact identity merging the shadow and Kneser languages

Center the square-divisor exponents:

\[
z_i=U_i-E_i,
\qquad
-E_i\le z_i\le E_i.
\]

Because

\[
4a\equiv1\pmod{4a-1},
\]

one obtains

\[
-4D
\equiv
-\prod_i\ell_i^{z_i}
\pmod{4a-1}.
\]

Hence `ES-SQUARE-TRAP-SIGNED-BOX-IDENTITY.md` proves

\[
\boxed{
S_a
=-\mathcal R_{4a-1}(a).}
\]

This is the central synthesis.

The pre-DSC research studied **cross-layer shadow/ancestry** of congruence traps.

The post-DSC research developed **internal Kneser/stabilizer expansion** for symmetric signed product boxes.

They now act on the same completed Type-II object.

López Type A and B are just the all-negative and all-positive exponent orthants. Mixed Type II fills the cross-sign region.

Divisor complement

\[
D\mapsto a^2/D
\]

is simply

\[
z\mapsto-z
\]

and becomes residue inversion. The familiar López A/B inverse relationship is the boundary restriction of this global symmetry.

---

## 6. Root geometry

Write the complementary square divisors as

\[
d=sb^2,
\qquad
\frac{a^2}{d}=sc^2,
\qquad
 a=sbc,
\]

with `s` squarefree.

Then the square-completed Type-II relation has exact positive parameters

\[
\boxed{
p+q=4sbt,
\qquad
b+t=cq.}
\]

The decomposition is

\[
\boxed{
\frac4p
=
\frac1{sctp}
+
\frac1{sbt}
+
\frac1{sbcp}.}
\]

And the López boundary has an elementary interpretation:

\[
\boxed{
\begin{array}{ccl}
\text{Type A} &\iff& b\mid c,\\
\text{Type B} &\iff& c\mid b,\\
\text{mixed completed Type II} &\iff& b\nmid c\text{ and }c\nmid b.
\end{array}}
\]

So the missing region is exactly the incomparable-root region of the divisibility poset.

---

## 7. First completed shadow theorem: exact prime-index spectrum

If the layer index `a` is prime, then

\[
\boxed{S_a=\{-4,-1,-a\}.}
\]

If an earlier modulus satisfies

\[
4j-1\mid4a-1,
\]

then

\[
a\equiv j\pmod{4j-1}
\]

and therefore

\[
S_a\bmod(4j-1)
=
\{-4,-1,-j\}
\subseteq S_j.
\]

Thus every ancestry edge into a prime-index completed layer is a complete direct shadow.

Every composite integer `4a-1≡3 mod4` has a proper prime divisor `3 mod4`, so if `a` is prime and `4a-1` is composite, the entire layer is redundant.

Conversely, if `4a-1` is prime greater than `7`, the completed prime-modulus backbone produces infinitely many Mordell-hard primes whose first completed hit is exactly `a`.

Therefore `ES-SQUARE-PRIME-INDEX-SPECTRUM.md` proves

\[
\boxed{
 a\text{ prime is an exact completed first-hit depth}
\iff
4a-1\text{ is prime}.}
\]

This is the first exact spectrum theorem obtained from the merged completed-shadow framework.

---

## 8. Prime-power structural gaps survive completion unchanged

Since

\[
S_a=T_a
\]

for every prime-power layer index, all trap identities proved solely on those layers transfer unchanged.

In particular the power-of-two Mersenne lattice remains exact:

\[
S_{2^b}=T_{2^b}
=-\langle2\rangle
\pmod{2^{b+2}-1}.
\]

Whenever

\[
a+2\mid b+2,
\]

the later binary layer is directly shadowed by the earlier one.

Hence the infinite family of structural gaps and the density-one deletion within the exponent-indexed power-of-two subsequence survive the square completion.

Completion repairs only genuinely multidimensional layer geometry.

---

## 9. Completed depth is unbounded

The neutral residue is never trapped:

\[
\boxed{1\notin S_a\quad\forall a.}
\]

The central residue is always trapped:

\[
\boxed{-1\in S_a\quad\forall a.}
\]

These facts allow the prime-modulus CRT/Dirichlet construction to go through unchanged.

Whenever

\[
4a-1>7
\]

is prime, infinitely many Mordell-hard primes have exact completed first depth `a`.

Therefore

\[
\boxed{\text{completed first-hit depth is unbounded}.}
\]

The proof cannot be a universal bounded-depth theorem.

---

## 10. Finite completed census through 50,000,000

A standalone reproducer is checked in as

`square_completion_probe.py`.

For all Mordell-hard primes

\[
p\le50,000,000,
\]

there are

\[
\boxed{93,457}
\]

primes in the six hard classes.

All are captured by completed layers with

\[
\boxed{a\le624.}
\]

The unique deepest observed prime is

\[
\boxed{p=2,031,121}
\]

with mixed witness

\[
\boxed{
a=624,
\quad D=576,
\quad m=2495,
\quad q=815.}
\]

The first López Type-A/B depth for the same prime is

\[
\boxed{1403.}
\]

This is finite evidence of strong compression, not a ceiling theorem. The unboundedness theorem proves that the observed plateau must eventually break.

See `SQUARE-COMPLETION-FINITE-CENSUS.md`.

---

## 11. External-shift Kneser route remains complementary

The exact two-target fixed-shift formulation remains valuable independently of the layer completion.

For external prime shifts

\[
q\equiv3\pmod4,
\qquad
(q/p)=-1,
\]

a combined failure has even stabilizer index

\[
\boxed{n\ge6}
\]

and, because `-p^{-1}`, `-p`, and `-1` occupy three distinct missing stabilizer cosets,

\[
\boxed{
\sum_i
\left(
\min(2e_i+1,\operatorname{ord}(r_iH))-1
\right)
\le n-4.}
\]

At index six the entire failure reduces to one simple primitive sextic factor and a forced external-nonresidue edge.

Consecutive primitive defects can occur. The exact transition law is

\[
\boxed{
q_{i-1}
\equiv
q_{i+1}^{\pm2}u_i^6
\pmod{q_i}.}
\]

The finite witness

\[
p=808369:
\quad
43\xrightarrow{6}19\xrightarrow{6}28871\xrightarrow{28870}\cdots
\]

shows why a one-edge contradiction is too strong.

For a forced successor `r≡1 mod4`, the natural shift `3r` reduces to a prime-`r` placement problem with one mod-3 parity bit. Index four is impossible, and index six is classified into a primitive branch and a parity-cubic double-defect branch.

These remain useful local obstruction theorems, especially now that the completed layer itself is recognized as a signed product box.

---

## 12. Defect complexity of a hypothetical counterexample is unbounded

CRT plus Dirichlet can force arbitrary prescribed external-nonresidue prime-power load into

\[
\frac{p+q}{4}
\]

at infinitely many external prime shifts.

Therefore a hypothetical counterexample would require arbitrarily large full-stabilizer defect indices.

A stronger starvation construction forces the least odd prime divisor of the defect index to be arbitrarily large.

Thus no proof can close the problem by classifying a fixed finite menu of low-order Kneser defects.

A successful argument must be uniform in quotient complexity.

---

## 13. Current theorem stack

### Exact complete coordinates

- `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`
- `ES-TWO-TARGET-DIVISOR-SQUARE.md`
- `ES-TYPEII-SQUARE-COMPLETION-LOPEZ-A.md`
- `ES-TYPEII-ROOT-GEOMETRY.md`

### Square-completed López / Thépault synthesis

- `SQUARE-COMPLETION-PRIOR-ART.md`
- `ES-SQUARE-COMPLETION-TRAP-GEOMETRY.md`
- `ES-SQUARE-TRAP-COMPLEMENT.md`
- `ES-SQUARE-TRAP-SIGNED-BOX-IDENTITY.md`
- `ES-SQUARE-COMPLETION-BACKBONE.md`
- `ES-SQUARE-PRIME-INDEX-SPECTRUM.md`
- `SQUARE-COMPLETION-FINITE-CENSUS.md`
- `square_completion_probe.py`

### Kneser / external-shift obstruction theory

- `FAB-TWO-TARGET-KNESER.md`
- `FAB-INDEX6-COMBINED-DEFECT.md`
- `ES-PRIMITIVE-SEXTIC-CHAIN.md`
- `ES-COMPOSITE-SUCCESSOR-3R.md`
- `ES-COMPOSITE-SUCCESSOR-INDEX4.md`
- `ES-COMPOSITE-SUCCESSOR-INDEX6.md`
- `ES-COMPOSITE-BRANCHB-FILTERS.md`
- `ES-UNBOUNDED-DEFECT-FORCING.md`
- `ES-LARGE-PRIME-DEFECT-FORCING.md`

### Retained shadow/depth structure

- `PRIME-MODULUS-BACKBONE.md`
- `COMPOSITE-CORE.md`
- `MERSENNE-SHADOW-LATTICE.md`
- the strong/weak/pointwise `q=3` notes
- the covering-core / hypergraph depth program

---

## 14. Highest-priority proof targets

### A. Completed cross-layer ancestry

The primary target is now the composite-index spectrum of

\[
\boxed{S_a=-\mathcal R_{4a-1}(a).}
\]

Classify when a completed layer is swallowed by earlier completed layers.

Start with low-dimensional multi-prime indices:

1. squarefree semiprimes `a=uv`;
2. general semiprimes / two-prime-support layers;
3. layers where `4a-1` has a small `3 mod4` ancestry divisor.

Use:

- signed exponent geometry internally;
- Kneser stabilizer compression internally;
- CRT/modulus ancestry across layers;
- complement/inversion to halve mixed cases.

### B. Mixed-first arrival

Classify primes whose first completed hit uses a genuinely mixed exponent vector.

The finite record `p=2,031,121` gives one deep example.

Determine whether the old López composite-rescue core is systematically absorbed by mixed completed traps.

### C. Root incomparability

In root variables, mixed Type II means

\[
b\nmid c,
\qquad
c\nmid b.
\]

Search for an exact transformation or descent on incomparable roots, but do not assume a Euclidean descent exists without a proved parameter-preserving operation.

### D. Uniform Kneser closure

Because hypothetical-counterexample defect complexity is provably unbounded, seek a quotient-uniform expansion or reciprocity theorem rather than further finite index classification.

---

## 15. One-line status

The current direct-ES object is no longer the López boundary trap and no longer DSC. It is the **Thépault square-completed Type-II layer viewed simultaneously as a López congruence layer and a symmetric Kneser product box**:

\[
\boxed{
S_a=-\mathcal R_{4a-1}(a).}
\]

López A/B are its two monotone boundary orthants, mixed Type II fills the cross-region, prime-power layers remain unchanged, prime-index depths are now exactly classified, and the remaining proof burden has concentrated on **composite multi-prime layers and uniform cross-layer ancestry**.
