# CRASH CHECKPOINT — Erdős-Straus Type A/B program

**Updated:** 2026-08-15  
**Purpose:** immediate recovery after chat/model/runtime failure  
**Canonical repository:** `chasebryan/centl`  
**Rule:** the repository is authoritative. Do not reconstruct theorem status from chat memory when this file and the cited artifacts are available.

## 0. Recovery protocol

If research execution is interrupted:

1. fetch this file from `main`;
2. fetch `CURRENT-FRONTIER.md` and `RESEARCH-BACKUP-2026-08-14.md`;
3. fetch the current `main` HEAD and compare it with the HEAD recorded below;
4. inspect any commits after the recorded HEAD before continuing;
5. verify workflow conclusions and artifact digests before promoting finite results;
6. treat any script whose companion theorem document or green workflow is absent as **work in progress**, not a proved result;
7. commit every material theorem, proof, analyzer, workflow, artifact digest, and claim-boundary change before moving to the next attack.

## 1. Repository state at this checkpoint

Observed `main` HEAD immediately before this checkpoint was created:

```text
5fe657887b0fca5b447bda867ffa1e294c132aa2
research: add multiplicative defect quotient and zero-product atom analyzer
```

Its parent is:

```text
f85ddcfe0feec8ff7acf627f3076f80cf345c911
ci: automate quotient-9 rigidity theorem regression
```

Important: commit `5fe6578...` adds

```text
research/erdos-straus/multiplicative_defect_atom_analyzer.py
```

The analyzer references proposed companion notes named approximately

```text
MULTIPLICATIVE-DEFECT-QUOTIENT.md
DEFECT-ZERO-SUM-ATOMS.md
```

but those companion theorem records were not found in the repository at checkpoint time. Therefore the multiplicative-defect / zero-product-atom line is **unfinished research state**. Do not promote theorem claims from that analyzer until the proof documents exist and an independent/automated regression is green.

## 2. Latest fully green candidatewise frontier: k <= 1500

GitHub Actions run:

```text
workflow:    CENTL direct-shadow completeness attack
run id:      31849103304
head commit: c508994fb48e6f701f15577352f275df5646cd78
status:      completed
conclusion:  success
```

The complete workflow finished green, including candidate attack, independent verification, coordinate-core mining, coarse/fiber peeling, bounded selectors, quadratic shield, CENTL exact certification, hash freezing, summary publication, and artifact upload.

Frozen artifact:

```text
artifact id: 9238241616
name: direct-shadow-completeness-c508994fb48e6f701f15577352f275df5646cd78
sha256: e181a66bec9a8e0d68b4b6b46892b6c71c50ebe8ab64c45944c8c17408c983dd
size: 3,226,135 bytes
```

This supersedes the earlier checkpoint text that still described the `k<=1500` run as in progress.

The finite result is evidence/certification through `k<=1500`, not universal Direct-Shadow Completeness.

## 3. Quotient-9 rigidity is proved and green

Canonical theorem:

```text
research/erdos-straus/QUOTIENT-9-RIGIDITY.md
```

Statement for unrestricted ancestry child

\[
K=9j-2:
\]

\[
T_K\bmod(4j-1)\subseteq T_j
\]

if and only if one of:

```text
K is prime;
K = 2p with p prime;
(j,K) = (2,16).
```

Automated regression:

```text
workflow:    CENTL Erdős-Straus quotient-9 rigidity
run id:      31853547363
head commit: f85ddcfe0feec8ff7acf627f3076f80cf345c911
status:      completed
conclusion:  success
artifact id: 9238285901
artifact sha256: 4a2ec4bf5c819d887b1bceba20e51f45bbe1f07df3aa22413d11dedbb95237b6
```

The configured regression checked the exact theorem by explicit trap enumeration.

## 4. Prime-child ancestry theorem is proved and green

Canonical theorem:

```text
research/erdos-straus/PRIME-CHILD-SHADOWS.md
```

For any ancestry quotient

\[
4K-1=q(4j-1),\qquad q\equiv1\pmod4,
\]

if the child depth `K` is prime, then

\[
T_K\bmod(4j-1)\subseteq T_j.
\]

For quotient `q=5`, the unrestricted converse is exact:

\[
T_{5j-1}\bmod(4j-1)\subseteq T_j
\iff
5j-1\text{ is prime}.
\]

Green regression:

```text
run id:      31852969007
head commit: 76ad8a9df8890a3dd0f6048b0985076a6d1852f9
artifact id: 9238092721
artifact sha256: 21a22ccdb80e505d9cacbf9a8932e088f3721bfc62b55c249e984066bbbdb6e5
```

Finite regression facts:

```text
q = 5,9,...,101; j <= 2000
prime-child checks: 6,247 / 6,247 passed
q=5 rigidity checked through j <= 50,000
prime q=5 children: 5,510
full unrestricted q=5 shadows: 5,510
mismatches: 0
```

## 5. Universal square-lift shadow classification is proved and green

Canonical theorem:

```text
research/erdos-straus/UNIVERSAL-SQUARE-LIFT-SHADOW-CLASSIFICATION.md
```

A base layer shadows **every** odd square lift if and only if

\[
\boxed{j\in\{1,2,4\}.}
\]

Constructive converse regression:

```text
run id:      31852781397
head commit: 45adfb05f8f454b2564fe52338dc7255e425c05a
artifact id: 9238029825
artifact sha256: 9f221d7cf82f8a27ccd02beb35da98513852120837047fadf8ef11cff7666d87
```

Finite certificate facts:

```text
bases checked: 1..5000
universal bases: 1,2,4
nonuniversal bases with explicit escaping square lift: 4,997
unresolved: 0
maximum progression prime used: 1,270,909
maximum search steps: 68
maximum constructed lift depth: 19,833,438,467,899,419
```

Every nonuniversal finite base received a positive counter-lift certificate, not merely a failed search.

## 6. Reciprocity tower theorem is proved and green

Canonical theorem:

```text
research/erdos-straus/RECIPROCITY-TOWER-SHADOWS.md
```

The only Jacobi-saturated bases are

\[
\boxed{1,2,4}.
\]

They generate three universal odd-square-lift shadow families:

\[
3n^2+3n+1,
\]

\[
7n^2+7n+2,
\]

\[
15n^2+15n+4.
\]

Green regression:

```text
run id:      31852607474
head commit: 93ce84c8fb1fa795da2b4ed8f4f2add497f7d89f
artifact id: 9237972571
artifact sha256: 11344d55fdfcd5d77c46ff9f7bf18d1ce2d556e3b077ccbeedfe75ef058a1288
```

Finite checks:

```text
Jacobi saturation checked through k <= 50,000
observed saturated layers: 1,2,4
odd lifts through c <= 1001 for each base
1,503 / 1,503 lifts shadowed
12,715 divisor reciprocity checks passed
```

## 7. Dyadic trap lattice is proved and green

Canonical theorem:

```text
research/erdos-straus/DYADIC-TRAP-LATTICE.md
```

For `a>=1`,

\[
T_{2^a}=-\langle2\rangle\pmod{2^{a+2}-1}.
\]

Globally,

\[
\boxed{T_k=-D_k\iff k\text{ is a power of }2.}
\]

For `1<=a<b`,

\[
a+2\mid b+2
\Longrightarrow
T_{2^b}\bmod(2^{a+2}-1)=T_{2^a}.
\]

Green regression:

```text
run id:      31852068758
artifact id: 9237819599
artifact sha256: 5c1b2f4e70eaa724f39e7f449b2e0cf964b157c0bb40c89f4b658657828e226d
```

The first regression correctly caught the special `k=1` endpoint; the theorem and analyzer were corrected before the green freeze.

## 8. Prime-depth spectrum slice is completely classified

Canonical theorem already present:

```text
research/erdos-straus/PRIME-DEPTH-DICHOTOMY.md
```

For prime depth `k`:

\[
\boxed{
k\text{ is infinitely realized}
\iff
4k-1\text{ is prime},
}
\]

while composite `4k-1` makes `k` a global structural gap.

This fully classifies the prime-valued depth subsequence. The unresolved exact-depth classification problem therefore begins on composite target depths.

## 9. Structural-gap spectrum results currently committed

Canonical notes include:

```text
EXACT-DEPTH-GAP-THEOREMS.md
SPECTRUM-INFINITE-COINFINITE.md
SPECTRUM-COUNTING.md
SATURATED-BASE-SHADOW-SEMIGROUPS.md
SATURATED-BASE-COUNTING.md
MERSENNE-BACKBONE.md
```

Key theorem package:

- infinitely many depths are infinitely prime-realizable;
- infinitely many depths are structurally impossible;
- prime-depth indices are completely classified;
- source `j=1` deletes the multiplicative semigroup whose prime factors are all `1 mod 3`;
- the source-1 semigroup yields a classical Selberg-Delange lower bound
  \[
  G(X)\gg X/\sqrt{\log X}.
  \]

These are statements about the López Type A/B minimal-depth spectrum, not a proof of universal Type A/B coverage or Erdős-Straus.

## 10. Active theorem architecture

The proof program has compressed the obstruction through the following layers:

\[
\boxed{
\begin{array}{c}
\text{exact Type A/B traps}\\
\downarrow\\
\text{direct shadow graph / ancestry}\\
\downarrow\\
\text{fiber peeling / bounded selectors}\\
\downarrow\\
\text{Jacobi and local quadratic signatures}\\
\downarrow\\
\text{multiplicative quotient}\\
\downarrow\\
\text{square-lift towers}\\
\downarrow\\
\text{factorization rigidity of ancestry children}\\
\downarrow\\
\text{higher p-adic / exact divisor geometry}.
\end{array}
}
\]

Quotients `q=5` and `q=9` are now completely classified in the unrestricted ancestry system. The natural next exact ancestry target is `q=13`, unless the multiplicative-defect/zero-product-atom line yields a stronger general theorem first.

## 11. Current unfinished edge

The latest HEAD added `multiplicative_defect_atom_analyzer.py`. Its stated purpose is to analyze:

- squarefree ancestry;
- the Jacobi-positive unit subgroup;
- the divisor-generated subgroup;
- the quotient of those groups;
- invariant factors;
- multiplicative defect classes of prime factors;
- a conservation law;
- minimal zero-product atom decompositions.

This line may be important, but at this checkpoint it is **not frozen as theorem-level output** because the named companion proof documents and a green dedicated workflow were not yet located.

### Resume here after a crash

1. inspect commit `5fe657887b0fca5b447bda867ffa1e294c132aa2` and the analyzer;
2. recover/complete the intended theorem statements before running farther;
3. write the companion proof documents;
4. add an independent regression workflow;
5. freeze artifact hash and results file;
6. only then decide whether it supersedes the planned `q=13` attack.

## 12. Claim boundary that must survive every restart

We have **not** proved:

- the Erdős-Straus conjecture;
- that every prime has finite `C_AB`;
- universal López Type A/B coverage;
- universal Direct-Shadow Completeness;
- publication priority for the new minimal-depth/shadow framework.

We **have** built a growing package of exact structural theorems, finite machine-checked frontiers, explicit infinite shadow families, exact spectrum gaps, and reproducible artifacts.

## 13. Mandatory backup discipline from now on

Before beginning a new theorem branch:

- commit the current proof note;
- commit the analyzer/falsifier;
- add or update the dedicated workflow;
- wait for green when practical;
- record run ID, head SHA, artifact ID, and SHA-256 here or in a dedicated `*-RESULTS.md` file;
- update this checkpoint whenever the active research edge changes materially.

**Chat is scratch space. GitHub is the flight recorder.**
