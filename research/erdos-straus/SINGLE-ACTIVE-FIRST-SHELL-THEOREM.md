# Single-active first-shell collapse — retracted proof attempt

**Status:** `REVISE / RETRACTED PROOF`  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Coordinator:** Operator-01 / primary research lead  
**Claim boundary:** the former proof in this file is invalid. The `q in {3,5,9}` hard-class collapse remains an independently verified finite theorem-certificate through `k<=100000`, not a universal theorem. The earlier universal theorem `|N^act|=1 => q=p or p^2` remains unaffected.

Read with:

- [SINGLE-ACTIVE-EXCESS-PRIME-POWER.md](SINGLE-ACTIVE-EXCESS-PRIME-POWER.md) — still proved;
- [SINGLE-ACTIVE-HARD-COLLAPSE-K100000.md](SINGLE-ACTIVE-HARD-COLLAPSE-K100000.md) — verified finite result;
- [CLASS-C-CENSUS-K1500.md](CLASS-C-CENSUS-K1500.md);
- [operator-02/DIRECTIVE-FIRST-SHELL-REVIEW.md](operator-02/DIRECTIVE-FIRST-SHELL-REVIEW.md).

## 1. Retraction

An earlier version of this file claimed the universal implication

\[
|\mathcal N^{\rm act}_{k,r}|=1
\Longrightarrow
s\in\{3,5\}
\Longrightarrow
q\in\{3,5,9,25\},
\]

followed by a hard-class elimination of `q=25`.

That proof used a false intermediate assertion.

The assertion was:

> if `m=d s^2` is a fixed-negative squareclass layer, then every earlier layer `d u^2` in the same squarefree tower has the same negative Jacobi sign.

The correct statement is

\[
\left(\frac r{d u^2}\right)
=
\left(\frac r d\right)
\]

**only when**

\[
\gcd(r,u)=1.
\]

If a prime dividing `u` also divides `r`, then the Jacobi symbol is `0`, not `-1`.

The invalid proof compared the active shell with unrelated odd values such as `N`, `N-2`, `3`, `5`, and `7` without first proving those values are coprime to `r`. Therefore uniqueness of the active **fixed-negative** core does not imply that all those comparison shells are inactive. Some may simply fail to be fixed-negative because their Jacobi symbol is zero.

The product/lcm interval contradictions built from those unrelated shells are therefore unsupported.

## 2. What remains proved

The theorem in [SINGLE-ACTIVE-EXCESS-PRIME-POWER.md](SINGLE-ACTIVE-EXCESS-PRIME-POWER.md) survives this correction.

Its argument only replaces the actual active square parameter `s` by a divisor such as `s/p`.

Because the original layer has Jacobi sign `-1`,

\[
\gcd(r,s)=1.
\]

Hence every divisor of `s` is also coprime to `r`, and removing an actual factor preserves the negative squareclass sign.

Thus the universal statement remains:

\[
\boxed{
|\mathcal N^{\rm act}_{k,r}|=1
\Longrightarrow
q=p\text{ or }p^2
}
\]

for one prime `p`.

The Class-B corollary also remains:

\[
\boxed{
\text{Class B single-active}
\Longrightarrow
q=p^2,\quad p\nmid L.
}
\]

## 3. What remains independently verified finite evidence

The two-construction GitHub workflow through

\[
k\le100000
\]

examined

\[
8,021,288
\]

hard-compatible Type A/B target candidates and found

\[
419,123
\]

single-active candidates, with exact quotient distribution

```text
q=3: 252,832
q=5:   4,173
q=9: 162,118
other:      0
Class B:    0
```

The independent verifier had zero mismatched fields.

Workflow provenance:

```text
run:      31854964168
artifact: 9238743256
artifact sha256:
f390c20afe0c8fc97d9046c34117f4e0b2c8e56f255d6a31c732b337d16d2159
```

Therefore the sharp statement

\[
\boxed{
\text{hard-compatible }|N^{act}|=1
\Longrightarrow
q\in\{3,5,9\}\text{ and Class A}
}
\]

is a **strong theorem candidate with exact finite verification through `k<=100000`**, not a proved theorem.

## 4. Correct proof target

The missing ingredient must use information that distinguishes a hard-compatible Type A/B target residue from an arbitrary reduced residue.

For a target layer

\[
M=4k-1,
\]

the candidate residue is not arbitrary. It satisfies

\[
r\equiv -e\quad\text{or}\quad -4e\pmod M
\]

for some

\[
e\mid k.
\]

At the same time, an active fixed-negative layer

\[
m=d s^2
\]

satisfies

\[
\left(\frac r d\right)=-1,
\qquad
\gcd(r,s)=1,
\qquad
q=m/\gcd(L,m)=p\text{ or }p^2.
\]

The new theorem search must exploit the **target trap residue** together with quadratic reciprocity / divisor arithmetic, rather than assuming arbitrary shells in the same squarefree tower are negative.

## 5. Revised attack directions

### A. Target-trap reciprocity

Substitute

\[
r\equiv-e\text{ or }-4e\pmod M
\]

into the fixed-negative condition modulo the squarefree kernel `d`.

Because

\[
e\mid k,
\qquad
4k\equiv1\pmod d
\]

whenever `d|M`, divisor residues may force local quadratic constraints on the excess prime `p`.

The key question is whether the condition

\[
(r/d)=-1
\]

can coexist with a first active shell at a prime `p>=7` or a Class-B square once the target residue is a Type A/B trap.

### B. Actual-divisor shell reductions only

All universally valid square-tower reductions should use divisors of the actual active shell `s`, because those preserve coprimality with `r` automatically.

No comparison with an unrelated `u` may be called fixed-negative without proving `gcd(r,u)=1`.

### C. Explain the observed absence of Class B

For Class B,

\[
q=p^2,
\qquad p\nmid L.
\]

Since `p` is absent from both `840` and the target modulus `M`, it is a genuinely new square coordinate in the earlier fixed-negative layer.

The finite data suggest Type A/B target compatibility forbids such a coordinate in a unique active core. That is now a clean separate theorem target.

### D. Preserve the finite falsifier

The `k<=100000` double-construction test remains valuable and should be extended only as a regression/falsifier, not used as a substitute for proof.

## 6. Scientific correction protocol

This correction was made immediately upon finding the gap, before publication-grade promotion.

The invalid proof remains recoverable in Git history at commit

```text
a7a0ccb17d59c8797e6c6f0b315ccc08db66ba87
```

but must not be cited as a theorem.

The repository is the canonical record of both the proposed proof and its retraction.

## 7. Current status table

```text
|N^act|=1 => q=p or p^2:                    PROVED
Class-B single-active => q=p^2, p not in L: PROVED
hard single-active q in {3,5,9}:            FINITE-CERTIFIED through k<=100000
hard single-active Class-A only:             FINITE-CERTIFIED through k<=100000
former first-shell proof:                    RETRACTED / INVALID
universal hard-collapse theorem:             OPEN
```

This is the active proof frontier.
