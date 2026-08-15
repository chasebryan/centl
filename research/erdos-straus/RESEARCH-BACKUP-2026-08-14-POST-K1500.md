# Erdős-Straus research backup — post-k<=1500 checkpoint

**Project:** Free Computation Foundation / CENTL  
**Checkpoint date:** 2026-08-14 local / 2026-08-15 UTC  
**Purpose:** crash-resistant recovery point for the active Type A/B theorem program  
**Claim boundary:** this checkpoint does not claim a proof of the Erdős-Straus conjecture, universal López Type A/B coverage, universal Direct-Shadow Completeness, or publication priority.

This file exists because live chat context is not considered durable research storage. The repository, named backup branch, workflow artifact, and hashes below are the recovery sources.

## 1. Frozen repository restore point

The complete repository state immediately before this checkpoint file was written is frozen at:

```text
commit:
5fe657887b0fca5b447bda867ffa1e294c132aa2

backup branch:
backup/erdos-straus-2026-08-14-k1500
```

The backup branch was created directly from that exact commit. Restoring or comparing against that branch recovers the entire theorem/code state independently of later changes to `main`.

The pre-checkpoint HEAD already includes the latest multiplicative defect/zero-product analyzer work.

## 2. Fully green k<=1500 candidatewise assault

GitHub Actions run:

```text
run id:       31849103304
checkout SHA: c508994fb48e6f701f15577352f275df5646cd78
k_limit:      1500
search_limit: 3,000,000
status:       SUCCESS
```

Every workflow stage completed successfully, including:

```text
candidate enumeration/search         SUCCESS
independent verifier                 SUCCESS
prime-power coordinate core          SUCCESS
coarse shadow-kernel peeling         SUCCESS
exact fiber-kernel peeling           SUCCESS
bounded selector replay              SUCCESS
quadratic character shield           SUCCESS
CENTL exact certification            SUCCESS
SHA256 freeze                         SUCCESS
artifact upload                       SUCCESS
```

### Candidatewise exact counts

```text
admissible candidates:             73,814
directly shadowed candidates:      20,574
directly novel candidates:         53,240
integer avoiding witnesses:        53,240
reduced avoiding witnesses:        53,240
unresolved integer candidates:          0
unresolved reduced candidates:          0
independent verifier:              VERIFIED
```

Every directly novel hard-compatible candidate through `k<=1500` therefore has an explicit reduced avoiding progression in this finite range. By Dirichlet, each reduced progression contains infinitely many primes. This is a finite theorem-certificate result, not a universal DSC-P proof.

### Independent verifier

```text
direct_novel_candidates_checked: 53240
integer_witnesses_verified:      53240
reduced_witnesses_verified:      53240
unresolved_integer_candidates:       0
unresolved_reduced_candidates:       0
verdict:                         VERIFIED
```

## 3. Frozen Actions artifact

```text
artifact id:
9238241616

artifact name:
direct-shadow-completeness-c508994fb48e6f701f15577352f275df5646cd78

artifact size:
3,226,135 bytes

artifact SHA256:
e181a66bec9a8e0d68b4b6b46892b6c71c50ebe8ab64c45944c8c17408c983dd

expires:
2026-11-12T23:05:32Z
```

The artifact contains the generated candidate bundle, independent verification, kernel reports, selector report, quadratic-character report, CENTL receipts/build metadata, and `SHA256SUMS`.

The artifact is temporary, so the repository documents/theorem code and backup branch are the permanent recovery layer.

## 4. k<=1500 structural replay results

### Prime-power coordinate core

```text
canonical unary-safe assignment solves: 17,776 / 53,240
maximum guided repair coordinates:       10
```

The guided repair count is an upper bound, not a proven minimum.

### Coarse exact shadow kernel

```text
fully resolved by augmented peeling: 754
largest residual kernel:              28 prime coordinates
largest residual prime observed:     109
universal first-bound last bad prime:139
first prime above with B_p(k)<1:      149
```

A residual kernel is not a counterexample.

### Exact fiber shadow kernel

```text
fiber kernel empty:                  26,532 / 53,240 = 49.835%
fiber-empty or canonical satisfied: 45,063 / 53,240 = 84.641%
largest residual kernel:             9 prime coordinates
largest residual prime:             31
```

Residual kernel-size distribution:

```text
0: 26,532
2:     28
3:  3,996
4:      6
5:    384
6:  1,582
7: 20,274
9:    438
```

### Bounded selector replay

Using the fixed menu

\[
0,\pm1,\ldots,\pm64,
\]

we obtained:

```text
fiber-empty candidates:                  26,532
nonempty kernels solved by selector:     26,708 / 26,708
combined independently resolved:         53,240 / 53,240
unresolved:                                   0
largest selector radius actually used:       54
```

Thus the same radius `54` that sufficed through `k<=1200` still suffices through `k<=1500` in this finite replay.

### Scalar quadratic-character shield

```text
explicit Jacobi trap checks: 22,428, all passed
all-square shield:            38,658 / 53,240 = 72.611%
general F2 character shield:  38,658 / 53,240 = 72.611%
character residual:           14,582 / 53,240 = 27.389%
```

Character-shield success gives an independent infinite reduced exact-depth prime progression; the residual requires finer geometry.

### CENTL certification

The generated hardest-candidate contract was checked by the repository CENTL binary. All listed exact contract lines in the workflow completed with `verified` verdicts, and the receipt/build/version files were included in the frozen artifact.

## 5. Theorem chain added after the earlier backup

The following records are part of the current durable theorem architecture.

### Squarefree lift localization

[SQUAREFREE-LIFT-CORE.md](SQUAREFREE-LIFT-CORE.md)

For `m_j=4j-1`, let `d_j` be its squarefree kernel. Since `m_j=d_js_j^2` and `d_j=3 mod 4`,

\[
d_j=4a_j-1
\]

for an earlier squarefree ancestor depth `a_j`. Character-fixed layers are therefore square-lifts of earlier squarefree Type A/B moduli. The exact projection excess

\[
E_j=(T_j\bmod d_j)\setminus T_{a_j}
\]

isolates the only part of such a layer that can remain active after ancestor direct novelty is imposed.

Finite `k<=1200` proof-mining signal recorded in the theorem note:

```text
non-squarefree moduli:                    224
nonempty projection-excess layers:        115
empty projection-excess layers:         1085
character residual candidates:          11056
character residual with no active excess:7608
candidates with active excess:           3448
```

### Square-lift reciprocity

[SQUARE-LIFT-RECIPROCITY.md](SQUARE-LIFT-RECIPROCITY.md)

For a square lift

\[
4j-1=d s^2,
\qquad d=4a-1\text{ squarefree},
\]

every divisor `e|j` satisfies

\[
\left(\frac e d\right)=+1,
\]

hence every projected Type A/B trap lies on the ancestor Jacobi-negative side.

### Jacobi saturation classification

[JACOBI-SATURATION.md](JACOBI-SATURATION.md)

The exact Type A/B trap layer fills the complete Jacobi-negative half if and only if

\[
\boxed{k\in\{1,2,4\}}.
\]

So moduli `3,7,15` are the complete Jacobi-saturated ancestor class.

### Square-lift full-signature theorem

[SQUARE-LIFT-SIGNATURE.md](SQUARE-LIFT-SIGNATURE.md)

The projected local Legendre-signature image of a lift is

\[
\eta_d+W_{j\to a},
\]

while the ancestor trap signatures are

\[
\eta_d+V_a.
\]

Thus signature shadowing is exactly

\[
W_{j\to a}\subseteq V_a.
\]

If the ancestor quadratic quotient dimension satisfies

\[
\kappa(a)=1,
\]

then every square lift is automatically ancestor-shadowed at full local quadratic-signature resolution.

### Reciprocity defect quotient and conservation

[RECIPROCITY-DEFECT-QUOTIENT.md](RECIPROCITY-DEFECT-QUOTIENT.md)

Define

\[
\mathcal R_a=\ker J_d/V_a,
\qquad
\dim\mathcal R_a=\kappa(a)-1.
\]

For every square-lift factorization

\[
j=\prod q^{e_q},
\]

the defect classes obey

\[
\boxed{
\sum_q(e_q\bmod2)\delta_a(q)=0
\quad\text{in }\mathcal R_a.
}
\]

### Reciprocity matrix

[RECIPROCITY-MATRIX.md](RECIPROCITY-MATRIX.md)

The binary matrix

\[
A_k=\left(\left(\frac{\ell_j}{p_i}\right)\right)
\]

with rows `p_i|4k-1` and columns `ell_j|k` has two canonical conservation laws:

\[
c_k^TA_k=0,
\qquad
A_kb_k=0.
\]

The first is the Jacobi/squarefree-kernel left-null vector; the second is the prime-exponent parity right-null vector.

### Universal square-lift signature classification

[SQUARE-LIFT-SIGNATURE-CLASSIFICATION.md](SQUARE-LIFT-SIGNATURE-CLASSIFICATION.md)

For squarefree ancestor `a`:

\[
\boxed{
\kappa(a)=1
\iff
\text{every square lift is ancestor-shadowed at full quadratic-signature resolution}.
}
\]

If

\[
\kappa(a)>1,
\]

then CRT + Dirichlet realization produces infinitely many square lifts carrying genuinely new signature defect classes.

### Quadratic-field / genus bridge

[QUADRATIC-FIELD-BRIDGE.md](QUADRATIC-FIELD-BRIDGE.md) and [GENUS-DEFECT-IDENTIFICATION.md](GENUS-DEFECT-IDENTIFICATION.md)

For squarefree `d=4a-1`, put

\[
K=\mathbb Q(\sqrt{-d}),
\qquad
\alpha_s=\frac{1+s\sqrt{-d}}2.
\]

Then

\[
N(\alpha_s)=\frac{1+ds^2}{4}=j_s.
\]

Every rational prime dividing a square-lift depth splits in `K`, and the selected prime ideals satisfy the principal-class conservation relation

\[
\sum_q e_q[\mathfrak p_{q,s}]=0
\quad\text{in }\operatorname{Cl}(K).
\]

Using classical genus theory,

\[
\operatorname{Cl}(K)/\operatorname{Cl}(K)^2\cong\ker J_d,
\]

and the Type A/B defect quotient is identified as the genus-class quotient left after modding out by the classes generated by the distinguished norm factors of

\[
\alpha_1=(1+\sqrt{-d})/2.
\]

This explicitly narrows the novelty claim: genus theory, class groups and Rédei-type quadratic residue machinery are classical; the Type-A/B-specific minimal-depth/shadow organization remains the candidate contribution.

### Exact signed-box residual and counterexample

[MIXED-BOX-OBSTRUCTION.md](MIXED-BOX-OBSTRUCTION.md)

Normalize

\[
U_k=-T_k.
\]

Then exactly

\[
\boxed{U_k=D_k\cup D_k^{-1}},
\]

where `D_k` is the divisor-residue set. Exact square-lift projection shadowing is therefore signed exponent-box containment modulo the ancestor relation lattice.

A tempting generator-wise simplification is false. The first recorded mixed-only failure is

\[
\boxed{j=696},
\]

with

\[
4j-1=2783=23\cdot11^2,
\qquad a=6,
\qquad d=23.
\]

Every individual prime-power direction of `696=2^3*3*29` lies in the ancestor signed box, but the mixed divisor

\[
87=3\cdot29\equiv18\pmod{23}
\]

lies outside it.

Finite square-lift replay through `j<=20000` recorded:

```text
non-squarefree moduli:                      3,788
exact ancestor projection contained:       1,198
single-axis failure visible:               2,575
all axes safe but mixed interaction fails:    15
```

This proves that the final exact residue core contains genuine interaction geometry.

## 6. Multiplicative defect quotient and zero-product atoms

The pre-checkpoint HEAD also contains:

- [MULTIPLICATIVE-DEFECT-QUOTIENT.md](MULTIPLICATIVE-DEFECT-QUOTIENT.md)
- [DEFECT-ZERO-SUM-ATOMS.md](DEFECT-ZERO-SUM-ATOMS.md)
- `multiplicative_defect_atom_analyzer.py`

For a squarefree ancestor, define the Jacobi-positive subgroup `K_a`, the subgroup `D_a` generated by prime divisors of `a`, and

\[
\boxed{\mathcal M_a=K_a/D_a.}
\]

Its order is

\[
\boxed{|\mathcal M_a|=\iota(a)/2=2^{\kappa(a)-1}\Theta(a)}.
\]

Every square lift obeys the full finite-abelian conservation law

\[
\boxed{
\prod_{q\mid j}
\left(\delta_a^{\rm mult}(q)\right)^{e_q}=1
\quad\text{in }\mathcal M_a.
}
\]

Universal square-lift multiplicative shadowing occurs exactly when

\[
\boxed{\iota(a)=2}.
\]

The defect sequence of every lift is a zero-product sequence in `M_a`, hence decomposes into minimal zero-product atoms. Classical Davenport-constant bounds reduce arbitrary factorization complexity to bounded-size neutral defect packets at each fixed ancestor.

This is the active bridge from quadratic/genus information to the finer multiplicative/two-box exact residue core.

## 7. Recovery hierarchy

If research/chat state is lost, recover in this order:

1. check out `backup/erdos-straus-2026-08-14-k1500`;
2. read this checkpoint and the older [RESEARCH-BACKUP-2026-08-14.md](RESEARCH-BACKUP-2026-08-14.md);
3. read [README.md](README.md), [DIAMOND.md](DIAMOND.md), and [CURRENT-FRONTIER.md](CURRENT-FRONTIER.md);
4. inspect workflow run `31849103304` and artifact `9238241616` while the artifact remains available;
5. verify the artifact digest against
   `e181a66bec9a8e0d68b4b6b46892b6c71c50ebe8ab64c45944c8c17408c983dd`;
6. continue from the multiplicative defect / zero-product atom / signed-box interaction core.

## 8. Current proof frontier

The current architecture is:

\[
\boxed{
\begin{array}{c}
C_{AB}\text{ / exact-depth spectrum}\\
\downarrow\\
\text{direct shadow graph and certified reduced escape progressions}\\
\downarrow\\
\text{fiber kernel and bounded selector}\\
\downarrow\\
\text{Jacobi and full local quadratic signatures}\\
\downarrow\\
\text{squarefree ancestor / genus defect quotient}\\
\downarrow\\
\text{multiplicative defect quotient }\mathcal M_a\\
\downarrow\\
\text{zero-product atom decomposition}\\
\downarrow\\
\text{signed exponent-box interaction geometry}\\
\downarrow\\
\text{exact direct-shadow completeness target}
\end{array}}
\]

The next high-value theorem target is to classify the bounded zero-product defect atoms and determine whether every atom that escapes the ancestor exact two-box trap is shadowed by another earlier layer, or whether mixed-box failures admit a bounded-support universal classification.

## 9. Backup rule

Material research work must be committed before moving far beyond it. Every major green workflow should get:

- a durable repository checkpoint;
- exact run/commit/artifact provenance;
- a named backup branch for major milestones;
- hashes for temporary workflow artifacts;
- claim-boundary language separating exact theorems, finite certificates, conjectures, and classical prior art.

**Chat is exploratory. The repository and frozen refs are canonical.**
