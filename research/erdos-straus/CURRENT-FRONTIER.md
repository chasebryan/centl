# Current research frontier

**Date:** 2026-08-15  
**Claim boundary:** Erdős-Straus remains open. Universal López Type A/B coverage remains open. Universal DSC-0 and DSC-P are false. Universal prime strong/Type-II coverage is also unproved. The Mizony/Thépault divisor-square mechanism is classical prior art. The active FCF work is the structural synthesis, shadow theory, Kneser theory, and exact fixed-shift analysis described below.

---

## 1. The proof search now has two distinct lanes

Do not conflate these.

### Lane A: exact prime Erdős-Straus

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
\]

and define

\[
\boxed{
\mathcal R_k(C_k)
=
\left\{
\prod_i r_i^{z_i}\pmod k:
-e_i\le z_i\le e_i,
\quad
C_k=\prod_i r_i^{e_i}
\right\}.}
\]

`ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md` proves

\[
\boxed{
 p\text{ satisfies Erdős-Straus}
\iff
\exists k:
\{-p^{-1},-1\}
\cap
\mathcal R_k(C_k)
\ne\varnothing.}
\]

The targets are standard Type I and Type II respectively. Inversion symmetry adds the equivalent Type-I orientation `-p`.

This is an exact reformulation of prime ES.

### Lane B: classical strong/Type-II route

For a layer index `a`, define

\[
\boxed{
S_a
=
\{-4D\pmod{4a-1}:D\mid a^2\}.}
\]

Universal prime coverage by the layers `S_a` would prove the classical strong/Type-II form and therefore Erdős-Straus, but it is logically stronger than original ES.

The condition

\[
D\mid a^2,
\qquad
4a-1\mid p+4D
\]

belongs to the historical Mizony/Thépault/Rosati-Yamamoto lineage. See:

- `STRONG-ES-MIZONY-THEPAULT-PROVENANCE.md`
- `SQUARE-COMPLETION-PRIOR-ART.md`

No novelty claim should be made for the square-divisor criterion itself.

---

## 2. DSC is closed as the universal bridge

The explicit hosted counterexample proves

\[
\boxed{\mathrm{DSC\!\!-0}\text{ is false},
\qquad
\mathrm{DSC\!\!-P}\text{ is false}.}
\]

The following remain valid supporting mathematics:

- strong/weak/pointwise `q=3` absorption;
- exact reduced-parameter domain;
- finite exact-depth certificates;
- direct-shadow smoothness;
- character and multiplicative quotient structure;
- covering-core / hypergraph depth theory.

Do not spend the main ES effort trying to restore universal DSC.

---

## 3. López A/B are the two boundary orthants of the classical square layer

The ordinary López trap at layer `a` is

\[
T_a
=
\{-e,-4e:e\mid a\}
\pmod{4a-1}.
\]

Write

\[
a=\prod_i\ell_i^{E_i},
\qquad
D=\prod_i\ell_i^{U_i},
\qquad
0\le U_i\le2E_i.
\]

Then `ES-SQUARE-COMPLETION-TRAP-GEOMETRY.md` proves:

- López Type A is the lower orthant `U_i<=E_i` for every `i`;
- López Type B is the upper orthant `U_i>=E_i` for every `i`;
- the additional standard Type-II parameters are the mixed cross-orthant points.

The exact mixed parameter count is

\[
\boxed{
M(a)=\tau(a^2)-2\tau(a)+1.}
\]

Thus

\[
\boxed{M(a)=0\iff a\text{ is a prime power}.}
\]

Prime-power layers are unchanged by completion:

\[
\boxed{S_a=T_a\quad\text{if }\omega(a)=1.}
\]

---

## 4. Central synthesis: the completed layer is a symmetric Kneser box

Center the square-divisor exponents:

\[
z_i=U_i-E_i.
\]

Since

\[
4a\equiv1\pmod{4a-1},
\]

one gets

\[
-4D
\equiv
-\prod_i\ell_i^{z_i}
\pmod{4a-1}.
\]

Therefore

\[
\boxed{
S_a
=-\mathcal R_{4a-1}(a).}
\]

This is the main structural merger.

The old program studied cross-layer congruence shadowing. The newer program studied Kneser expansion and stabilizers of symmetric product boxes. They now act on the same classical strong/Type-II object.

Divisor complement

\[
D\mapsto a^2/D
\]

is exactly

\[
z\mapsto-z
\]

and therefore residue inversion.

The López A/B mutual-inverse relation is the boundary restriction of this global symmetry.

See:

- `ES-SQUARE-TRAP-SIGNED-BOX-IDENTITY.md`
- `ES-SQUARE-TRAP-COMPLEMENT.md`

---

## 5. The old character shields survive completion

Let

\[
H_a
=
\langle \ell\bmod(4a-1):\ell\mid a\rangle.
\]

The complete strong layer satisfies

\[
\boxed{
T_a
\subseteq
S_a
\subseteq
-H_a
\subseteq
\{x:(x/(4a-1))=-1\}.}
\]

Thus square completion changes exact occupancy inside the old multiplicative coset, but does not weaken the coarse multiplicative or Jacobi shields.

See `ES-SQUARE-COMPLETION-COSET-SHIELD.md`.

---

## 6. Root geometry

Every square-divisor parameter may be written

\[
D=sb^2,
\qquad
\frac{a^2}{D}=sc^2,
\qquad
 a=sbc,
\]

with `s` squarefree.

The Type-II equations become

\[
\boxed{
p+q=4sbt,
\qquad
b+t=cq.}
\]

López comparability is exact:

\[
\boxed{
\begin{array}{ccl}
\text{Type A}&\iff&b\mid c,\\
\text{Type B}&\iff&c\mid b,\\
\text{mixed strong Type II}&\iff&b\nmid c\text{ and }c\nmid b.
\end{array}}
\]

See `ES-TYPEII-ROOT-GEOMETRY.md`.

---

## 7. Completed depth is unbounded, but finite compression is strong

Two elementary facts hold for every layer:

\[
\boxed{1\notin S_a,}
\qquad
\boxed{-1\in S_a.}
\]

The prime-modulus CRT/Dirichlet backbone therefore survives completion.

Whenever

\[
4a-1>7
\]

is prime, infinitely many Mordell-hard primes have exact strong/Type-II first depth `a`.

Hence completed first-hit depth is unbounded.

A reproducible finite census through

\[
p\le50,000,000
\]

contains `93,457` Mordell-hard primes, all captured by completed layers with

\[
\boxed{a\le624.}
\]

The unique deepest observed prime is

\[
\boxed{p=2,031,121}
\]

with mixed witness

\[
\boxed{a=624,
\quad D=576,
\quad 4a-1=2495,
\quad q=815.}
\]

Its López A/B first depth is `1403`.

This is finite compression only, not a universal ceiling.

See:

- `ES-SQUARE-COMPLETION-BACKBONE.md`
- `SQUARE-COMPLETION-FINITE-CENSUS.md`
- `square_completion_probe.py`

---

## 8. Exact prime-index spectrum

If the layer index `a` is prime, then

\[
S_a=\{-4,-1,-a\}.
\]

Every ancestry edge into such a layer is a complete shadow. Consequently:

\[
\boxed{
 a\text{ prime is an exact completed depth}
\iff
4a-1\text{ is prime}.}
\]

The positive case is realized infinitely often by Mordell-hard primes.

See `ES-SQUARE-PRIME-INDEX-SPECTRUM.md`.

---

## 9. Prime-power and squarefree-semiprime dichotomy

### Prime powers

If `a` is a prime power,

\[
S_a=T_a.
\]

In particular the power-of-two Mersenne shadow lattice carries over unchanged, including its infinite structural-gap families.

### Squarefree semiprimes

If

\[
a=uv
\]

with distinct primes `u<v`, the only mixed square divisors are

\[
u^2,\qquad v^2.
\]

Their signed ratios

\[
u/v,\qquad v/u
\]

lie outside every López boundary residue.

Therefore

\[
\boxed{T_{uv}\subsetneq S_{uv}}
\]

for every squarefree semiprime layer.

See `ES-SQUAREFREE-SEMIPRIME-MIXED-RESIDUES.md`.

---

## 10. Multiplicative ancestry is completely classified

Fix an ancestor `j` and let

\[
R_j=\mathcal R_{4j-1}(j),
\qquad
H_j=\operatorname{Stab}(R_j).
\]

Take a multiplicative descendant

\[
k=jB
\]

on an ancestry edge. The ancestry condition is

\[
B\equiv1\pmod{4j-1}.
\]

Then

\[
\boxed{
S_{jB}\bmod(4j-1)\subseteq S_j
\iff
r\bmod(4j-1)\in H_j
\text{ for every prime }r\mid B.}
\]

Any containment is automatically equality.

This is an exact iff classification of direct shadows on multiplicative ancestry edges.

See `ES-SQUARE-MULTIPLICATIVE-SHADOW-IFF.md`.

---

## 11. Internal stabilizers manufacture infinite cross-layer gaps

If every prime factor of an extension `B` lies in `H_j` and

\[
B\equiv1\pmod{4j-1},
\]

then

\[
S_{jB}\bmod(4j-1)=S_j.
\]

For any `h in H_j`, Dirichlet gives primes

\[
r\equiv h,
\qquad
s\equiv h^{-1}
\pmod{4j-1}.
\]

Then `B=rs` gives an infinite structural-gap cone above `j`.

This is the first exact theorem where an internal Kneser stabilizer generates cross-layer shadow edges.

See `ES-SQUARE-STABILIZER-EXTENSION-SHADOW.md`.

---

## 12. Nonmultiplicative ancestry also has infinite exact structure

### Squarefree factor-lift theorem

If the later index is squarefree

\[
k=r_1\cdots r_t
\]

and the ancestor factors as

\[
j=A_1\cdots A_t
\]

with

\[
r_i\equiv A_i\pmod{4j-1},
\]

then

\[
\boxed{S_k\bmod(4j-1)\subseteq S_j.}
\]

### Every ancestry quotient has infinite factor-lift families

For any

\[
Q=4s+1,
\]

choose a squarefree divisor `A|s`, put `t=s/A`, choose a prime

\[
r\equiv-t\pmod Q,
\]

and define

\[
B=\frac{r+t}{Q},
\qquad
j=AB,
\qquad
k=Ar.
\]

Then

\[
\boxed{4k-1=Q(4j-1)}
\]

and the later layer is completely shadowed by `j`.

Dirichlet supplies infinitely many such `r`.

Therefore:

\[
\boxed{
\text{every allowed ancestry quotient supports infinitely many exact completed structural gaps}.}
\]

See:

- `ES-SQUARE-SQUAREFREE-FACTOR-LIFT.md`
- `ES-SQUARE-ALL-QUOTIENT-FACTOR-LIFT.md`

---

## 13. Exponent-lattice normal form for arbitrary ancestry

For

\[
j=\prod_i p_i^{E_i},
\]

define

\[
\phi_j:\mathbb Z^d\to(\mathbb Z/(4j-1)\mathbb Z)^\times,
\qquad
z\mapsto\prod_i p_i^{z_i},
\]

and

\[
L_j=\ker\phi_j.
\]

The ancestor completed box is the image of

\[
B_j=\prod_i[-E_i,E_i]_{\mathbb Z}.
\]

For a later ancestry layer

\[
k=\prod_\nu r_\nu^{F_\nu},
\]

choose exponent lifts `v_nu` with

\[
\phi_j(v_\nu)=r_\nu.
\]

Define the later discrete zonotope

\[
Z(k\to j)
=
\left\{
\sum_\nu z_\nu v_\nu:
-F_\nu\le z_\nu\le F_\nu
\right\}.
\]

Then direct shadow is exactly

\[
\boxed{
Z(k\to j)
\subseteq
B_j+L_j.}
\]

A strong sufficient coordinate-budget test is

\[
\boxed{
\sum_\nu F_\nu |(v_\nu)_i|\le E_i
\quad\forall i.}
\]

This turns residual nonmultiplicative shadowing into a finite zonotope-in-lattice-cover problem.

See `ES-SQUARE-EXPONENT-LATTICE-SHADOW.md`.

---

## 14. Effective dimension can be much smaller than prime support

For

\[
j=2^e p
\]

with `p` odd prime,

\[
4j-1=2^{e+2}p-1
\]

gives

\[
p\equiv2^{-(e+2)}.
\]

Therefore the raw two-dimensional completed box collapses exactly to

\[
\boxed{
\mathcal R_{4j-1}(j)
=
\{2^z:-2e-2\le z\le2e+2\}.}
\]

For `j=2p`, this is the nine-step interval `[-4,4]` in powers of `2`.

This explains non-factor-lift shadows such as the finite edge `j=10 -> k=8083=59*137`.

See `ES-SQUARE-BINARY-PRIME-INTERVAL.md`.

The next internal invariant should be **effective signed-box dimension modulo `4j-1`**, not merely `omega(j)`.

---

## 15. Completed depth spectrum is quantitatively infinite and coinfinite

The prime-modulus backbone gives

\[
\boxed{
|\mathcal D_{\rm sq}\cap[1,K]|
\ge
(1+o(1))\frac{2K}{\log(4K)}.}
\]

The quotient-nine factor-lift family

\[
k=2r,
\qquad
r\equiv8\pmod9
\]

gives structural gaps with

\[
\boxed{
|\mathcal G_{\rm sq}\cap[1,K]|
\ge
(1+o(1))\frac{K}{12\log K}.}
\]

Thus the completed strong/Type-II depth spectrum is provably infinite and coinfinite, with explicit backbone and anti-backbone subfamilies both of prime-counting order.

See `ES-SQUARE-SPECTRUM-INFINITE-COINFINITE.md`.

---

## 16. Fixed-shift strong/Type-II search lives in a finite corridor

A successful Type-II shift `q` satisfies

\[
\boxed{3q\le p+4.}
\]

Writing

\[
A=\frac{p+3}{4},
\]

the shifts

\[
q_h=4h+3
\]

correspond to consecutive integers

\[
C_h=A+h.
\]

Only

\[
0\le h\le\left\lfloor\frac{p-5}{12}\right\rfloor
\]

can support a Type-II solution.

Thus a hypothetical strong counterexample requires simultaneous signed-box defects across a long finite corridor of consecutive integers.

See `STRONG-ES-FINITE-SHIFT-CORRIDOR.md`.

---

## 17. Exact small-shift factor filters

For Mordell-hard primes:

### q = 3

\[
\boxed{
q=3\text{ misses}
\iff
\text{every prime factor of }\frac{p+3}{4}
\text{ is }1\pmod3.}
\]

### q = 7

\[
\boxed{
q=7\text{ misses}
\iff
\text{every prime factor of }\frac{p+7}{4}
\text{ is a quadratic residue mod }7.}
\]

### q = 11

A miss is either:

1. pure quadratic splitting modulo `11`, or
2. a thin defect with `v_3=1`, all other QR factors `1 mod11`, only primitive NR classes `2,6`, and total such valuation at most `2`.

### q = 23

Because `6|(p+23)/4`, the forced factors `2,3` generate almost the entire QR subgroup. A miss is either:

1. pure quadratic splitting modulo `23`, or
2. a thin defect with `v_2=v_3=1`, all other QR factors `1 mod23`, only NR classes `5,14`, and total such valuation at most `2`.

See:

- `FAB-HARD-FIRST-FILTERS.md`
- `STRONG-ES-Q7-EXACT-FILTER.md`
- `STRONG-ES-Q11-EXACT-FILTER.md`
- `STRONG-ES-Q23-EXACT-FILTER.md`

---

## 18. The first four prime shifts already give a dimension-three sieve

Classical upper-bound sieve theory applied to the exact corridor filters gives:

\[
\boxed{
\#\{p\le X:\ q=3,7\text{ both miss}\}
\ll
\frac{X}{(\log X)^2}.}
\]

Adding `q=11` gives

\[
\boxed{
\#\{p\le X:\ q=3,7,11\text{ all miss}\}
\ll
\frac{X}{(\log X)^{5/2}}.}
\]

Adding `q=23` gives

\[
\boxed{
\#\{p\le X:\ q=3,7,11,23\text{ all miss}\}
\ll
\frac{X}{(\log X)^3}.}
\]

The last estimate is a relative-prime exceptional proportion

\[
\boxed{O((\log X)^{-2}).}
\]

These are specific applications of classical Selberg/Brun sieve ideas. Classical full-ES exceptional-set theorems are much stronger.

See:

- `STRONG-ES-Q3-Q7-SIEVE.md`
- `STRONG-ES-Q3-Q7-Q11-SIEVE.md`
- `STRONG-ES-Q3-Q7-Q11-Q23-SIEVE.md`

---

## 19. Exact-ES external-shift Kneser obstruction theory remains active

For external prime shifts

\[
q\equiv3\pmod4,
\qquad
(q/p)=-1,
\]

a combined Type-I/Type-II failure has even stabilizer index

\[
\boxed{n\ge6}
\]

and symmetric defect budget

\[
\boxed{
\sum_i
\left(
\min(2e_i+1,\operatorname{ord}(r_iH))-1
\right)
\le n-4.}
\]

At index six the failure reduces to one simple primitive sextic factor and a forced external-nonresidue edge.

Consecutive primitive defects can occur, with exact recurrence

\[
\boxed{
q_{i-1}
\equiv
q_{i+1}^{\pm2}u_i^6
\pmod{q_i}.}
\]

A hypothetical ES counterexample would require unbounded full-stabilizer quotient complexity as the auxiliary shift varies, and the least odd prime divisor of that defect index can be forced arbitrarily large.

Thus no finite classification of low Kneser defect indices can finish exact ES.

---

## 20. Current highest-priority proof targets

### A. Strong/Type-II cross-layer ancestry

Use the exact object

\[
S_a=-\mathcal R_{4a-1}(a)
\]

and classify the residual nonmultiplicative ancestry edges after removing:

1. multiplicative stabilizer extensions, already solved exactly;
2. factor-lift families, already infinite at every quotient;
3. low effective-dimension folds such as `2^e p`.

The exponent-lattice criterion is now the primary language.

### B. Strong/Type-II finite corridor

Continue exact fixed-shift classifications at useful small primes `q` and track the added sieve dimension.

The immediate questions are:

1. identify more shifts where hard congruences force a large QR product subset;
2. quantify all exceptional low-entropy branches;
3. determine whether a useful uniform family of corridor shifts exists.

### C. Exact ES two-target lane

Seek quotient-uniform principles rather than more low-index casework.

The proven unbounded-defect forcing theorem means any final Kneser argument must survive arbitrarily large quotient complexity.

### D. Prior-art review

Continue tracing Thépault, Mizony, Rosati-Yamamoto, Mordell, Bradford, López, Chamberland, and BHB-F so all structural novelty claims remain conservative and publication-safe.

---

## 21. One-line status

The main new research object is now clear:

\[
\boxed{
\text{classical Mizony/Thépault strong layer}
=
\text{square-completed López layer}
=
-\text{symmetric signed divisor box}.}
\]

Its internal Kneser geometry and cross-layer shadow geometry are now partially unified, multiplicative ancestry is completely classified, every ancestry quotient has infinite exact gap families, the residual shadow problem has an exact exponent-lattice form, and four tiny fixed Type-II shifts already leave only an `O(X/(log X)^3)` prime survivor set. Original Erdős-Straus remains open.