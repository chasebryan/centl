# WS-CAND-003: Erdős-Straus Type A/B witness depth and congruence shadow structure

**Status:** Wellspring Candidate
**Date identified:** 2026-08-14
**Investigators:** Chase Bryan / Free Computation Foundation
**Origin:** `secret-oasis-2026-08-14` and CENTL exact-computation demonstration work
**Scope:** Erdős-Straus Type A/B congruence structure, minimal witness depth, redundancy, and exact verification
**Oasis effect:** none
**Novelty status:** candidate, pending comprehensive prior-art review and independent mathematical review

> This record documents a potentially new structural lens on the Type A/B congruence system used in work on the Erdős-Straus conjecture. It does **not** claim a proof of the Erdős-Straus conjecture, a new global computational verification bound for that conjecture, or priority over prior literature.

## 1. Executive summary

The Erdős-Straus conjecture asks whether, for every integer `n >= 2`, there exist positive integers `x,y,z` such that

\[
\frac{4}{n}=\frac1x+\frac1y+\frac1z.
\]

Miguel Angel López introduced two structural solution classes, Type A and Type B, and characterized them by congruences of the form

\[
p\equiv -4d \pmod{4dn-1}
\]

and

\[
p\equiv -n \pmod{4dn-1}.
\]

López conjectures that every prime has a Type A or Type B solution. That conjecture would imply the Erdős-Straus conjecture for primes and hence the usual reduction to all positive integers. The Type A/B framework itself is therefore prior art and is **not** claimed here as an FCF discovery.

The FCF experiment introduced a minimal-depth statistic for this Type A/B congruence system, denoted

\[
C_{AB}(p),
\]

then studied the congruence layers that define it. That process produced five connected candidate contributions:

1. **Minimal Type A/B witness depth.** A compact invariant `C_AB(p)` records the first Type A/B layer at which a prime is captured.
2. **A certified record frontier.** For the six classical Mordell-hard residue classes modulo 840, every prime through `10,000,000` was captured, and thirteen successive record holders for `C_AB` were independently rechecked. The current record in that range is `C_AB(9,658,489)=2622`.
3. **Exact trap-set cardinality.** The number of distinct Type A/B residues at layer `k` has a closed formula in the divisor-counting function.
4. **Congruence shadowing.** Some later Type A/B layers are provably redundant because all of their admissible congruence classes are already captured by earlier layers. This explains exact zero first-hit layers that a naive probabilistic model incorrectly treated as extreme statistical anomalies.
5. **An irredundant-layer research program.** The direct shadow relation induces a redundancy graph on Type A/B congruence layers and suggests studying the irredundant core rather than every integer `k`.

A separate elementary argument also shows that `C_AB`, if finite on all primes as López conjectures, cannot be bounded by any universal constant. In fact, for every `K` there are infinitely many primes in the hard class `1 mod 840` whose Type A/B depth exceeds `K`.

The exact invariant, certified frontier, trap-cardinality formula, and shadow hierarchy were not found in the targeted primary-literature search performed on 2026-08-14. This is encouraging but **not sufficient to establish novelty or priority**. The record remains a Wellspring Candidate until the prior-art search and independent review are stronger.

## 2. Prior work and what is not new

### 2.1 Erdős-Straus remains open

The research in this record does not solve the Erdős-Straus conjecture. Large-scale computational verification of the original conjecture also predates this work by many orders of magnitude. Salez reported computational verification through `10^17`.

Therefore the statement

> all selected hard primes below `10^7` were resolved

must never be presented as a new verification bound for the original Erdős-Straus conjecture. The new object being measured is Type A/B **minimal witness depth**, not the existence of arbitrary unit-fraction decompositions.

### 2.2 López Type A and Type B

The primary structural source for this experiment is:

- Miguel Angel López, *A Complete Congruence System for the Erdos-Straus Conjecture*, arXiv:2404.01508, 2024: <https://arxiv.org/abs/2404.01508>

López defines Type A and Type B solutions and gives congruence characterizations. In the notation used here, for positive integers `d,n` and

\[
m=4dn-1,
\]

a prime `p` has the relevant Type A form when

\[
p\equiv-4d\pmod m,
\]

and Type B form when

\[
p\equiv-n\pmod m.
\]

López conjectures that every prime has at least one solution of Type A or B. His paper reports experimental verification of the Type A/B conjecture for the first 10,000 primes, through `p=104729`.

The paper also works in the classical context in which the familiar modular identities reduce attention to six difficult residue classes modulo 840:

\[
H=\{1,121,169,289,361,529\}.
\]

These Type A/B definitions, their congruence characterizations, and the hard residue classes are prior work.

### 2.3 Recent related work checked

The 2026 prior-art pass also included recent primary literature on divisor and congruence parametrizations, including:

- M. Bello-Hernández, M. Benito, E. Fernández, *A Divisor Parametrization for the Erdős--Straus Conjecture*, arXiv:2606.10922, 2026: <https://arxiv.org/abs/2606.10922>
- additional current arXiv work on parametric and congruence approaches to Erdős-Straus.

The targeted search did not surface the exact `C_AB` minimal-depth invariant or the direct congruence-layer shadow relation defined below. This is a **negative search result**, not a proof that no equivalent construction exists under another notation.

## 3. Type A/B constructions used in the experiment

Let

\[
k=dn,\qquad m=4k-1=4dn-1.
\]

### 3.1 Type B

Suppose

\[
p+n=qm.
\]

Equivalently,

\[
p\equiv-n\pmod m.
\]

Then with

\[
X=dnq=kq,
\]

\[
Y=dqp,
\]

\[
Z=dnp=kp,
\]

one obtains

\[
\frac4p=\frac1X+\frac1Y+\frac1Z.
\]

The identity follows directly from `p+n=q(4dn-1)`.

### 3.2 Type A

Suppose

\[
p+4d=qm.
\]

Equivalently,

\[
p\equiv-4d\pmod m.
\]

Put

\[
u=nq-1.
\]

Then a corresponding Type A decomposition is

\[
X=du=d(nq-1),
\]

\[
Y=dnp,
\]

\[
Z=dnp(nq-1),
\]

and again

\[
\frac4p=\frac1X+\frac1Y+\frac1Z.
\]

CENTL is useful here because these algebraic identities can be checked exactly, including as polynomial identities for entire parameterized families rather than as floating-point samples.

## 4. Definition of the Type A/B depth invariant

For `k >= 1`, define

\[
m_k=4k-1.
\]

Let

\[
T_k=\{-e,-4e\pmod{m_k}:e\mid k\}.
\]

The **Type A/B witness depth** is

\[
\boxed{
C_{AB}(p)=\min\{k\ge1:p\bmod(4k-1)\in T_k\}.
}
\]

Equivalently,

\[
\boxed{
C_{AB}(p)=
\min\left\{
 k\ge1:\exists e\mid k,
 p\equiv-e\text{ or }p\equiv-4e\pmod{4k-1}
\right\}.
}
\]

If no Type A/B witness exists, define `C_AB(p)=infinity`.

This is the same as the minimum product `dn` among López Type A/B witnesses. It is intentionally named `C_AB`, rather than simply `C`, to avoid implying global minimality among all possible Erdős-Straus decompositions.

### 4.1 Interpretation

`C_AB(p)` is a first-hit statistic on a deterministic congruence sieve. At each integer layer `k`, the modulus is `4k-1`, and the divisors of `k` generate the trap residues.

A prime with a large `C_AB` has escaped every Type A/B trap at all smaller layers.

## 5. The hard-prime computation through 10,000,000

The main sieve used:

- search limit: `10,000,000`;
- prime population: primes `p` with `p mod 840` in `H`;
- number of selected hard primes: `20,513`;
- layer search: increasing `k`;
- final bound used: `K_MAX=3000`.

The search resolved all `20,513` selected primes. The final survivor was captured at `k=2622`.

This establishes the finite computational statement:

> Every prime `p <= 10,000,000` in the six selected Mordell-hard classes has a Type A/B witness with `C_AB(p) <= 2622`.

It does **not** establish a universal bound, and Section 9 proves that no universal constant bound can exist.

## 6. Certified record frontier

Scanning the selected hard primes in increasing prime order gives the following successive records for minimal Type A/B witness depth:

| prime `p` | `p mod 840` | `C_AB(p)` | type | `d` | `n` | `m=4C_AB-1` | `q` |
|---:|---:|---:|:---:|---:|---:|---:|---:|
| 1009 | 169 | 3 | B | 1 | 3 | 11 | 92 |
| 1201 | 361 | 8 | A | 2 | 4 | 31 | 39 |
| 2521 | 1 | 22 | B | 11 | 2 | 87 | 29 |
| 3361 | 1 | 25 | B | 5 | 5 | 99 | 34 |
| 9601 | 361 | 28 | A | 14 | 2 | 111 | 87 |
| 33289 | 529 | 45 | B | 9 | 5 | 179 | 186 |
| 76441 | 1 | 70 | B | 14 | 5 | 279 | 274 |
| 83449 | 289 | 170 | A | 17 | 10 | 679 | 123 |
| 1095481 | 121 | 245 | A | 5 | 49 | 979 | 1119 |
| 1423321 | 361 | 1050 | A | 35 | 30 | 4199 | 339 |
| 2031121 | 1 | 1403 | B | 23 | 61 | 5611 | 362 |
| 4728649 | 289 | 1435 | B | 5 | 287 | 5739 | 824 |
| 9658489 | 169 | 2622 | B | 69 | 38 | 10487 | 921 |

The depth sequence is therefore

```text
3, 8, 22, 25, 28, 45, 70, 170, 245, 1050, 1403, 1435, 2622
```

within this finite search population.

## 7. Independent minimality verification

The discovery sieve was not trusted as its own final verifier. A second program independently rechecked every frontier claim using a different control flow:

1. verify that the listed `p` is prime by trial division;
2. for every `1 <= k < claimed C_AB(p)`, enumerate the divisors of `k` and check the Type A and Type B divisibility conditions directly;
3. reject the claim immediately if any smaller witness exists;
4. verify at least one witness at the claimed depth;
5. emit a deterministic JSON certificate and SHA-256 digest.

All thirteen frontier claims passed.

For the record prime `p=9,658,489`, the verifier exhaustively rejected layers `1` through `2621` and found the unique recorded witness at layer `2622`:

```text
Type B
d = 69
n = 38
k = 2622
m = 10487
q = 921
p + n = 9658527 = 10487 * 921
```

The certificate's internal digest, computed before adding the digest field, was:

```text
55bf4226937122b1021f7be1d25e8ab8cd411e64fb4200a2392a23b9de37cf10
```

The final file SHA-256 values produced in the experiment were:

| artifact | SHA-256 |
|---|---|
| `frontier-summary.json` | `ffa7bcdcf0dab0dec867e60b59fe55e71b0aad1cc28f5b4e67a26c37169cc2bd` |
| `p-1009-C-3.json` | `0856c3750ea6b407b229e2ccc59ae9e261c86894e63272a333c529359312c5ce` |
| `p-1095481-C-245.json` | `8347027971ddec81b4d2d2b2781be56f12fd4c0321bb4ad5d610fb0f1bb4ea12` |
| `p-1201-C-8.json` | `54004c7f3c330e0cdaef6ef461ccbe0685773651b6bf95c41a45de67d282a328` |
| `p-1423321-C-1050.json` | `1b6a8bb8e2e76b60c9a35b2bbf6a6e9b2434d062719531624eb3f05d9bea4875` |
| `p-2031121-C-1403.json` | `2272a0c7e2b36491c22ed15591b03a3b7fa4760e0c47b141387cec59310aef78` |
| `p-2521-C-22.json` | `631534348e9807f224073200182de8c33849652efc383a4bcbae65fb403dc1c8` |
| `p-33289-C-45.json` | `b1b154ec22e5ec6e3ac5340a9d9dee66bd7546ad86dd8df44680006506498730` |
| `p-3361-C-25.json` | `98cdae19969ed66331fa502ae7e53859370f686ff55653a2dcea98d190f7f315` |
| `p-4728649-C-1435.json` | `637436d1d212fff18a92a078d83d4b9e205c7a651b3679725fdec4b3aad2813d` |
| `p-76441-C-70.json` | `5a69c5e6e4de8e73cb8cdd17ff6acb0d4a790e243a1a93ac1d5d92c6a816e8f1` |
| `p-83449-C-170.json` | `ce3553cb05828f50500d4169e95cfca130dd39a6db922beef78d5fc5a3343f4c` |
| `p-9601-C-28.json` | `23d187ea18503b3a597c7f5923c1e8a26e71a39d79cd3a3c78e6301b1e1fd5fc` |
| `p-9658489-C-2622.json` | `5d06e079925c0563043a4879c235c62b4f15ceb83b4711429709b55d9f129c5a` |

These hashes identify the local artifacts created during the experiment. The original paths contained the investigator's workstation home directory and are intentionally not treated as portable identifiers.

## 8. CENTL exact verification of the record holder

For `p=9,658,489`, the Type B witness gives the exact decomposition

\[
\boxed{
\frac4{9658489}
=
\frac1{2414862}
+
\frac1{613787317461}
+
\frac1{25324558158}.
}
\]

CENTL was asked to verify the closed rational equality exactly:

```sh
centl 'assert(4/9658489 = 1/2414862 + 1/613787317461 + 1/25324558158)'
```

CENTL returned:

```text
verdict: verified (closed_exact_rational via closed_rational_comparison); comparison=equal
```

The same witness was then lifted to the entire parameterized Type B family

\[
P(t)=10487t-38,
\]

\[
X(t)=2622t,
\]

\[
Y(t)=69t(10487t-38),
\]

\[
Z(t)=2622(10487t-38).
\]

CENTL verified the cross-multiplied polynomial identity

\[
4XYZ=PYZ+PXZ+PXY
\]

with a rational variable `t` and returned:

```text
verdict: verified (univariate_rational_polynomial via polynomial_zero_difference); comparison=equal
```

At `t=921`, `P(t)=9,658,489`.

CENTL's role here is exact algebraic verification. It does not, by itself, certify the external number-theoretic claims about primality, Dirichlet's theorem, prior art, or global congruence coverage.

## 9. Theorem: `C_AB` is unbounded over primes

A finite search initially makes it tempting to ask whether there is a universal constant `B` such that every prime has `C_AB(p) <= B`. That is impossible.

### Theorem

For every positive integer `K`, there are infinitely many primes `p` in the hard class `p == 1 mod 840` with

\[
C_{AB}(p)>K.
\]

Consequently `C_AB` is unbounded over the primes, whether or not López's Type A/B conjecture is true.

### Proof

Let

\[
L_K=\operatorname{lcm}\left(840,\;4k-1:1\le k\le K\right).
\]

Dirichlet's theorem on primes in arithmetic progressions gives infinitely many primes

\[
p\equiv1\pmod{L_K},
\]

because `gcd(1,L_K)=1`.

Such a prime satisfies `p == 1 mod 840`, so it lies in a classical hard class, and for every `k <= K` it also satisfies

\[
p\equiv1\pmod{4k-1}.
\]

At level `k`, a Type A/B hit would require a divisor `e | k` for which

\[
1\equiv-e\pmod{4k-1}
\]

or

\[
1\equiv-4e\pmod{4k-1}.
\]

The first is impossible because it would require `4k-1` to divide `e+1`, while

\[
0<e+1\le k+1<4k-1.
\]

For the second, `4k-1` would divide `4e+1`. Since

\[
0<4e+1\le4k+1=(4k-1)+2,
\]

the only possible positive multiple is `4k-1` itself, which would imply

\[
4e+1=4k-1,
\]

hence `e=k-1/2`, impossible for integral `e`.

Thus no level `k <= K` can capture `p`, and therefore

\[
C_{AB}(p)>K.
\]

Since `K` was arbitrary, `C_AB` is unbounded. QED.

### Consequence

This does **not** refute López's Type A/B conjecture. It says that if every prime eventually has a Type A/B witness, the depth required must nevertheless grow without any fixed universal ceiling.

The research target is therefore not a constant upper bound. The deeper questions concern finiteness, growth, distribution, record behavior, and structure of the surviving congruence classes.

## 10. Exact trap-set cardinality

Recall

\[
T_k=\{-d,-4d\pmod{4k-1}:d\mid k\}.
\]

Let `tau(k)` be the number of positive divisors of `k`.

### Theorem

\[
\boxed{
|T_k|=2\tau(k)-1-\mathbf1_{4\mid k}\tau(k/4).
}
\]

### Proof

The residues `-d` are distinct as `d` ranges over divisors of `k`, because all representatives lie in an interval shorter than the modulus `4k-1`. The same is true for the residues `-4d`. Before cross-collisions there are therefore `2 tau(k)` entries.

A cross-collision occurs when

\[
a\equiv4b\pmod{4k-1}
\]

for divisors `a,b | k`. Since `1 <= a <= k` and `1 <= b <= k`, the quantity `4b-a` lies strictly above `-(4k-1)` and at most `4k-1`. Thus a congruence collision can occur only when

\[
4b-a=0
\]

or

\[
4b-a=4k-1.
\]

The second has the unique solution `(a,b)=(1,k)`, giving the universal collision

\[
-1\equiv-4k\pmod{4k-1}.
\]

The first condition is `a=4b`. Such collisions exist exactly when `4 | k`; then they are in one-to-one correspondence with divisors `b | k/4`. Hence there are `tau(k/4)` additional cross-collisions when `4 | k`.

Subtracting these from `2 tau(k)` proves the formula. QED.

### Checks from the experiment

For

\[
2622=2\cdot3\cdot19\cdot23,
\]

`tau(2622)=16` and `4` does not divide `2622`, so

\[
|T_{2622}|=2(16)-1=31.
\]

The independently generated fingerprint also counted exactly 31 distinct trap residues.

For `k=1050`, `tau(1050)=24`, giving `|T_1050|=47`, again matching the computation.

For `k=8`, the correction term matters:

\[
|T_8|=2(4)-1-\tau(2)=8-1-2=5.
\]

## 11. Hazard analysis and why the naive model failed

The finite sieve records a conditional kill fraction at each layer:

\[
h_k=\frac{\text{newly captured at }k}{\text{survivors immediately before }k}.
\]

A first naive comparison used

\[
\rho(k)=\frac{|T_k|}{4k-1}.
\]

This was wrong as a probabilistic baseline because the population consists of primes already restricted to the six hard classes modulo 840. Such primes do not occupy arbitrary residue classes modulo `m_k`.

### 11.1 Prime- and hard-class-conditioned null

For a hard class `h in H`, put

\[
g_k=\gcd(840,m_k)
\]

and define the compatible unit residues

\[
U_{k,h}=\{r\pmod{m_k}:\gcd(r,m_k)=1,\ r\equiv h\pmod{g_k}\}.
\]

Then

\[
|U_{k,h}|=\frac{\varphi(m_k)}{\varphi(g_k)}
\]

and the class-specific Type A/B trap density is

\[
\rho_h(k)=\frac{|T_k\cap U_{k,h}|}{|U_{k,h}|}.
\]

Weighting these probabilities by the current number of survivors in each hard class gives a more appropriate local null model.

This correction explained several large apparent enrichments. For example, at `k=10`, the raw density was about `17.95%`, while the prime-compatible conditioned density is `33.333%`, close to the observed `34.2445%`.

### 11.2 Residual anomalies after conditioning

Even after prime/hard-class conditioning, some layers remained highly anomalous. Examples in the high-population regime included:

| `k` | survivors before | observed | conditioned expected | enrichment | standardized residual |
|---:|---:|---:|---:|---:|---:|
| 25 | 1437 | 152 | 95.800 | 1.5866 | +5.943 |
| 12 | 4044 | 870 | 791.217 | 1.0996 | +3.123 |
| 51 | 373 | 27 | 17.286 | 1.5620 | +2.425 |
| 14 | 3174 | 0 | 478.300 | 0 | -23.966 |
| 24 | 1531 | 94 | 211.556 | 0.4443 | -8.734 |
| 29 | 973 | 0 | 67.500 | 0 | -8.551 |
| 39 | 609 | 0 | 31.200 | 0 | -5.751 |
| 52 | 346 | 0 | 20.970 | 0 | -4.725 |

The extreme negative layers suggested that conditioning on primality and the hard residue classes was still insufficient. The missing information was **survival history**: a prime present at layer `k` has already escaped every earlier layer.

That observation led to the shadow relation.

Late-stage giant enrichment or `z` values with only one, two, three, or four survivors are not treated as meaningful statistical evidence. They are dominated by tiny sample size and selection effects.

## 12. Direct congruence shadowing

### 12.1 Admissible candidate classes

For layer `k`, modulus `m_k=4k-1`, hard class `h in H`, and trap `t in T_k`, call `(h,t)` **admissible** when

\[
\gcd(t,m_k)=1
\]

and

\[
t\equiv h\pmod{\gcd(840,m_k)}.
\]

The pair determines a simultaneous congruence class

\[
x\equiv h\pmod{840},
\]

\[
x\equiv t\pmod{m_k}.
\]

By CRT this is a class

\[
x\equiv r\pmod L,
\]

where

\[
L=\operatorname{lcm}(840,m_k).
\]

### 12.2 Shadow criterion

Fix an earlier layer `j<k`, with modulus `m_j=4j-1`, and put

\[
g=\gcd(L,m_j).
\]

As `x` runs through the candidate progression `r mod L`, the possible residues modulo `m_j` are exactly the fibre

\[
F_{j}(r,L)=\{u\pmod{m_j}:u\equiv r\pmod g\}.
\]

Therefore the candidate class `(h,t)` at level `k` is **directly shadowed by level `j`** if and only if

\[
\boxed{
F_j(r,L)\subseteq T_j.
}
\]

This is an exact finite criterion, not a statistical one.

### 12.3 Proof of the fibre statement

The simultaneous system

\[
x\equiv r\pmod L,
\qquad
x\equiv u\pmod{m_j}
\]

is solvable exactly when

\[
u\equiv r\pmod{\gcd(L,m_j)}.
\]

Thus the listed fibre is precisely the set of residues modulo `m_j` attained by members of the candidate progression. If every such residue belongs to `T_j`, then every integer in the candidate class is already a Type A/B hit at `j`. Conversely, if some residue in the fibre is not in `T_j`, the CRT supplies integers in the candidate class that evade `j`.

### 12.4 Layer-level notions

For a layer `k`, let `A_k` be the set of admissible `(h,t)` pairs.

A pair is **directly shadowed** when some single earlier level `j` shadows it by the criterion above.

Define the direct novelty fraction

\[
\nu(k)=
1-\frac{\#\{\text{directly shadowed pairs in }A_k\}}{|A_k|}.
\]

Interpretation:

- `nu(k)=0`: every admissible pair is directly shadowed by at least one earlier layer;
- `0<nu(k)<1`: the layer is partially directly redundant;
- `nu(k)=1`: no admissible pair is wholly shadowed by any single earlier layer.

**Important limitation:** `nu(k)=1` does not yet prove that earlier layers cannot collectively cover a candidate class by a union of partial fibres. This experiment has established a **single-earlier-layer shadow relation**, not complete union irredundancy. The specific class containing an actual prime with verified `C_AB(p)=k` is stronger evidence of noncoverage, because that prime is itself a witness that the union of all earlier traps did not cover that point.

## 13. Exact example: layer 14 is redundant

For `k=14`,

\[
m_{14}=55.
\]

After hard-class and prime compatibility are imposed, the relevant trap residues reduce to the residues `41`, `51`, and `54` modulo 55 across the admissible pairs. Modulo 11,

\[
41\equiv8,
\qquad
51\equiv7,
\qquad
54\equiv10.
\]

At `k=3`,

\[
m_3=11,
\qquad
T_3=\{7,8,10\}.
\]

Thus every admissible hard-prime hit at layer 14 is already a hit at layer 3.

The shadow-map computation reported:

```text
k=14  m=55  classes=9  shadowed=9  novel=0  sources=[3]
```

Hence, for the selected hard-prime population,

\[
\boxed{C_{AB}(p)\ne14.}
\]

This is an infinite congruence statement, not merely the observation that no example appeared below `10^7`.

The huge negative hazard residual at `k=14` was therefore not a random statistical anomaly. The correct conditional expectation after incorporating survival history is exactly zero.

## 14. Shadow map through `k=3000`

The optimized shadow computation analyzed every layer through `3000`. It found many completely directly shadowed layers. Early examples include:

```text
14 <- 3
29 <- 6
39 <- 8
47 <- 3,14
52 <- 6
59 <- 12
62 <- 5,10,24
69 <- 3,14
74 <- 15
75 <- 6,10,29
89 <- 18
100 <- 5,24
101 <- 8,39
106 <- 12
113 <- 3,14
119 <- 5,24,100
129 <- 26
134 <- 27
146 <- 3,14,40
159 <- 32
166 <- 10
167 <- 6,29
178 <- 20
179 <- 3,14,36
194 <- 8,39
201 <- 3,14
205 <- 10
213 <- 6,29
218 <- 10,17,84
239 <- 48
249 <- 50
251 <- 15,74
256 <- 8,39
257 <- 20,99
267 <- 3,14
269 <- 11,54
278 <- 3,14,76
282 <- 6,29
299 <- 60
```

The complete program output continues with hundreds of directly redundant layers through `k=3000`. The important mathematical fact is not the finite count by itself, but that each entry carries a finite CRT shadow certificate that can in principle be independently checked.

### 14.1 Selected novelty measurements

| `k` | `m` | admissible classes | directly shadowed | directly novel | `nu(k)` |
|---:|---:|---:|---:|---:|---:|
| 14 | 55 | 9 | 9 | 0 | 0.0000 |
| 24 | 95 | 15 | 9 | 6 | 0.4000 |
| 25 | 99 | 12 | 0 | 12 | 1.0000 |
| 29 | 115 | 9 | 9 | 0 | 0.0000 |
| 36 | 143 | 84 | 60 | 24 | 0.2857 |
| 39 | 155 | 9 | 9 | 0 | 0.0000 |
| 40 | 159 | 36 | 0 | 36 | 1.0000 |
| 51 | 203 | 8 | 0 | 8 | 1.0000 |
| 54 | 215 | 21 | 9 | 12 | 0.5714 |
| 62 | 247 | 42 | 42 | 0 | 0.0000 |
| 65 | 259 | 8 | 0 | 8 | 1.0000 |
| 70 | 279 | 48 | 24 | 24 | 0.5000 |
| 75 | 299 | 66 | 66 | 0 | 0.0000 |
| 83 | 331 | 18 | 0 | 18 | 1.0000 |
| 90 | 359 | 138 | 0 | 138 | 1.0000 |
| 104 | 415 | 15 | 9 | 6 | 0.4000 |
| 114 | 455 | 4 | 0 | 4 | 1.0000 |
| 170 | 679 | 16 | 0 | 16 | 1.0000 |
| 245 | 979 | 66 | 18 | 48 | 0.7273 |
| 1050 | 4199 | 282 | 216 | 66 | 0.2340 |
| 1403 | 5611 | 42 | 18 | 24 | 0.5714 |
| 1435 | 5739 | 48 | 0 | 48 | 1.0000 |
| 2622 | 10487 | 186 | 0 | 186 | 1.0000 |

### 14.2 Layer 25

Layer 25 was particularly informative because the conditioned hazard analysis had identified it as a strong positive residual:

```text
N=1437
observed first hits=152
conditioned expected=95.800
E*=1.5866
z=5.943
```

The shadow map then found all 12 admissible `(h,t)` pairs directly fresh under the single-layer criterion. The trap residues are `79` and `94` modulo 99 for every hard class. Their residues modulo 11 are `2` and `6`, neither of which lies in `T_3={7,8,10}`.

This does not establish a new probabilistic law, especially because layers are dependent and multiple layers were inspected. It does show that the strong positive residual at `k=25` is not explained by the same direct-shadow mechanism that forces the zero at `k=14`.

### 14.3 Layers 1435 and 2622

The shadow map found:

```text
k=1435  m=5739   classes=48   shadowed=0  novel=48   nu=1.0000
k=2622  m=10487  classes=186  shadowed=0  novel=186  nu=1.0000
```

Again, `nu=1` means no **single earlier level** completely shadows an admissible class. It does not yet prove absence of union shadowing.

For the particular Type B class containing `p=9,658,489`, however, the independent minimality certificate proves that this actual prime evades every level `1..2621`. Thus the union of all prior Type A/B traps does not cover that point.

## 15. The emerging redundancy graph

The direct shadow relation naturally defines a directed graph on congruence layers or, more finely, on admissible `(k,h,t)` classes.

An edge

```text
j -> (k,h,t)
```

means the earlier layer `j` covers the entire CRT progression represented by `(k,h,t)`.

At layer level, one can record the set of earlier sources responsible for shadowing every admissible class. This produces a hierarchy of inherited congruence work.

Examples:

```text
3 -> 14
6 -> 29
8 -> 39
12 -> 59
5,10,24 -> 62
6,10,29 -> 75
```

This suggests replacing the nominal sequence of all integer layers with an **irredundant Type A/B sieve** whose active objects are only congruence classes that add information not already forced by earlier layers.

That irredundant object has not yet been completely constructed because direct shadowing is only the first notion of redundancy. Union shadowing remains to be computed and formalized.

## 16. Candidate novelty, stated precisely

The novelty claim under investigation is **not**:

- the Erdős-Straus conjecture;
- the Type A or Type B solution forms;
- the congruences `p == -4d` or `p == -n mod (4dn-1)`;
- the six difficult classes modulo 840;
- or a new record for brute-force verification of Erdős-Straus.

The candidate novelty is the following structural package built on López's Type A/B framework:

### Candidate contribution A: minimal witness-depth invariant

The explicit use of

\[
C_{AB}(p)=\min\{k:p\bmod(4k-1)\in T_k\}
\]

as a Type A/B complexity/depth invariant, together with certified record behavior.

### Candidate contribution B: exact trap cardinality

The formula

\[
|T_k|=2\tau(k)-1-\mathbf1_{4\mid k}\tau(k/4)
\]

and its elementary collision proof.

### Candidate contribution C: unboundedness of Type A/B depth

The Dirichlet construction proving that for every fixed `K`, infinitely many primes in `1 mod 840` have `C_AB(p)>K`.

### Candidate contribution D: direct congruence-layer shadowing

The CRT fibre criterion that determines when an admissible later Type A/B congruence class is completely implied by a single earlier layer.

### Candidate contribution E: irredundant Type A/B sieve

The resulting distinction between fully shadowed, partially shadowed, and directly fresh layers, and the associated redundancy graph/poset as an object of study.

### Candidate contribution F: certified computational frontier

A reproducible minimal-depth frontier on the six hard residue classes through `10^7`, capped by

\[
C_{AB}(9658489)=2622,
\]

with an independent exhaustive minimality verifier and exact CENTL verification of the final decomposition and its parameterized polynomial family.

These items are strongly connected: the depth invariant motivates the layer sieve, the trap cardinality measures each layer, the unboundedness theorem rules out a finite constant-depth strategy, and shadowing explains why many nominal layers add no new first-hit information.

**Current status:** targeted searches have not found this exact package in the primary literature checked, but FCF does not claim priority until a broader literature review and independent expert scrutiny are completed.

## 17. What would falsify, narrow, or demote the candidate

This candidate should be narrowed or retired if any of the following occurs:

1. prior literature is found that already defines an equivalent minimal Type A/B depth invariant and substantially the same shadow hierarchy;
2. the claimed trap-cardinality formula is shown false for some `k`;
3. the CRT shadow criterion is shown to misclassify an admissible class;
4. an independent implementation finds a smaller Type A/B witness for one of the certified frontier primes;
5. the computation is shown to have omitted valid López Type A/B witnesses under the stated definition;
6. the distinction between direct shadowing and union shadowing proves too weak to support the proposed irredundant-sieve program.

Discovery of prior art would not invalidate the computations, but it could remove or substantially narrow the novelty claim.

## 18. Reproducibility architecture

The work intentionally separated discovery from checking:

```text
Type A/B discovery miner
        |
        v
minimal-depth k-sieve
        |
        v
independent frontier verifier
        |
        +--> JSON minimality certificates + SHA-256
        |
        v
CENTL exact rational / polynomial verification
        |
        v
arithmetic fingerprint
        |
        v
prime-conditioned hazard analysis
        |
        v
CRT shadow-map computation
```

The major experimental scripts created during the session were:

```text
esc-miner.py
esc-k-sieve.py
esc-frontier-verify.py
esc-frontier-fingerprint.py
esc-hazard-profile.py
esc-conditioned-hazard.py
esc-shadow-map.py
esc-shadow-map-fast.py
```

The first shadow-map implementation was intentionally replaced after it was observed consuming a full CPU core for a long period. The optimized implementation precomputed trap sets and replaced repeated explicit fibre construction with residue-bucket counts. The optimized program implements the same single-layer shadow criterion and completed through `k=3000`.

Future archival work should commit normalized versions of the scripts and machine-readable certificates, with relative paths and deterministic manifests, rather than relying on workstation-local paths.

## 19. Open problems created by the finding

This candidate opens several distinct research streams.

### 19.1 Union shadowing

Determine whether a candidate class not shadowed by any single earlier level may nevertheless be completely covered by the **union** of multiple earlier levels. Define and compute a stronger irredundancy invariant.

### 19.2 Classification of fully redundant depths

Characterize the integers `k` for which every admissible hard-prime Type A/B class is already covered earlier. A closed arithmetic criterion would convert a large empirical shadow list into a theorem family.

### 19.3 Irredundant core and graph structure

Construct the transitive reduction or another canonical representation of the shadow graph. Determine whether recurring source patterns such as `3 -> 14`, `6 -> 29`, and `8 -> 39` extend to infinite families.

### 19.4 Growth of `C_AB`

Study

\[
C_{AB}^{\max}(X)=\max_{p\le X,\ p\text{ in hard classes}} C_{AB}(p)
\]

and the least prime whose depth exceeds a given threshold. The unboundedness theorem guarantees arbitrarily deep survivors exist, but does not control their least size.

### 19.5 Relation to quadratic characters and other hardness measures

Several frontier primes overlap with record primes arising in other, different Erdős-Straus parametrization searches. This may be coincidence or may reflect shared arithmetic obstructions. Quadratic characters, factorizations of `p-1`, `p+1`, `k`, `m`, and multiplicative-order data are candidates for further study, but no theorem is claimed from the current small frontier sample.

### 19.6 Formal verification

CENTL already verifies the supported algebraic identities exactly. The external modular lemmas, trap-cardinality theorem, and shadow theorem could be formalized in a proof assistant or added to a future verified arithmetic layer. Until then, CENTL receipts and the number-theoretic arguments have separate assurance boundaries.

### 19.7 López Type A/B coverage

The deepest open target remains proving that

\[
C_{AB}(p)<\infty
\]

for every prime. This is essentially the Type A/B coverage conjecture studied by López and would imply Erdős-Straus. Nothing in the present work establishes that global finiteness claim.

## 20. Publication discipline

Any public summary of this work should include the following sentence or equivalent:

> FCF has identified a **candidate** structural contribution concerning minimal Type A/B witness depth and congruence-layer redundancy in the Erdős-Straus problem. The computations and elementary lemmas are reproducible, but novelty and priority remain under review, and the Erdős-Straus conjecture remains open.

Avoid phrases such as:

```text
FCF solved Erdős-Straus.
CENTL proved Erdős-Straus.
FCF verified Erdős-Straus farther than previous work.
C_AB <= 2622 for all primes.
Layer 2622 is globally irredundant in every admissible class.
```

None of those statements is established by the current evidence.

## 21. References

1. Miguel Angel López, *A Complete Congruence System for the Erdos-Straus Conjecture*, arXiv:2404.01508, 2024. <https://arxiv.org/abs/2404.01508>
2. S. Salez, computational work on the Erdős-Straus conjecture through `10^17`, arXiv:1406.6307. <https://arxiv.org/abs/1406.6307>
3. M. Bello-Hernández, M. Benito, E. Fernández, *A Divisor Parametrization for the Erdős--Straus Conjecture*, arXiv:2606.10922, 2026. <https://arxiv.org/abs/2606.10922>
4. Current FCF Wellspring policy: [`../FCF-WELLSPRING.md`](../FCF-WELLSPRING.md).

## 22. Current assessment

The evidence is strong enough to preserve this work as a **Wellspring Candidate** because it has generated multiple independent research directions and includes exact arguments, independent computation, and CENTL verification.

It is not yet designated an FCF Wellspring. The remaining barriers are principally prior-art review, independent mathematical review, union-shadow analysis, and archival reproduction from repository-controlled scripts and certificates.

The central research question created by the experiment is now:

\[
\boxed{
\text{What is the irredundant congruence structure of the Type A/B sieve, and how does it govern } C_{AB}(p)?
}
\]

That question is narrower than solving Erdős-Straus directly, but it is precise, testable, and structurally richer than the brute-force experiment from which it emerged.
