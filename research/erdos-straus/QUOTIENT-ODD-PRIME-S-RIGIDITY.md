# General odd-prime-shift ancestry rigidity — corrected scope

**Status:** `REVISE / PREVIOUS ALL-j CLAIM RETRACTED`  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** the former statement in this file claimed an exact classification for every `j>=1`. That statement is false. The correct universal theorem holds in the asymptotic range `j>=s+1`; small `j` can contain additional full-shadow children. See [`ODD-PRIME-SHIFT-ASYMPTOTIC-RIGIDITY.md`](ODD-PRIME-SHIFT-ASYMPTOTIC-RIGIDITY.md).

## 1. Retraction of the former all-j statement

The previous version claimed that for an odd prime `s`, with

\[
Q=4s+1,
\qquad
K=Qj-s,
\qquad
m=4j-1,
\]

full unrestricted shadowing always satisfied

\[
T_K\bmod m\subseteq T_j
\iff
K\text{ prime or }K=s p\text{ with }p\text{ prime}.
\]

This is false for small `j`.

A concrete counterexample is

\[
\boxed{s=17,\quad j=2,\quad K=121=11^2,\quad m=7.}
\]

Here

\[
S_2=-T_2=\{1,2,4\}\pmod7.
\]

The divisors of `121` are

\[
1,11,121,
\]

which reduce modulo `7` to

\[
1,4,2,
\]

respectively. All lie in `S_2`, so

\[
T_{121}\bmod7\subseteq T_2.
\]

But `121` is neither prime nor `17p`.

Therefore the all-`j` theorem is disproved.

## 2. Why the former proof failed

The previous write-up itself exposed the problem: it attempted to use

\[
K<m^2
\]

for all small `j`, but this inequality fails when `s` is large relative to `j`.

For example, at `s=17`, `j=2`,

\[
K=121>49=m^2.
\]

The least-prime-factor escape argument therefore does not apply.

A proof cannot replace this missing range with an unspecified “finite check per `s`” while still claiming a uniform all-`s`, all-`j` theorem.

## 3. What remains valid

The following results remain valid:

1. the prime-child theorem;
2. the divisor-child theorem:
   \[
   a\mid\gcd(j,s),\ K=ap,\ p\text{ prime}
   \Longrightarrow
   T_K\bmod m\subseteq T_j;
   \]
3. the asymptotic ancestry skeleton for `j>=s+1`;
4. the exact quotient-specific classifications already proved independently for `Q=13`, `17`, `21`, and `29`;
5. the corrected odd-prime-shift theorem in [`ODD-PRIME-SHIFT-ASYMPTOTIC-RIGIDITY.md`](ODD-PRIME-SHIFT-ASYMPTOTIC-RIGIDITY.md).

## 4. Small-j exception family is a real object

The counterexample above is not isolated.

Finite scouting finds additional small-`j` full-shadow children for prime shifts, for example:

```text
s=19, j=4:   K=289=17^2
s=53, j=4:   K=799=17*47
s=71, j=8:   K=2209=47^2
s=71, j=16:  K=4489=67^2
s=83, j=2:   K=583=11*53
s=89, j=10:  K=3481=59^2
```

These are not counterexamples to the asymptotic skeleton because every one lies in the small range

\[
j<s+1.
\]

They define a separate **small-ancestor exception problem** governed by the exact multiplicative geometry of `S_j`.

In particular, dyadic ancestors `j=2^a` are already understood through the Mersenne trap lattice:

\[
S_{2^a}=\langle2\rangle
\pmod{2^{a+2}-1}.
\]

That multiplicative closure naturally permits composite child divisors to remain inside the ancestor trap image.

## 5. Correct research program

The odd-prime-shift program now splits cleanly:

### Large-j theorem

For

\[
j\ge s+1,
\]

the exact nonsmooth classification is prime or `sp`, and smooth children are eliminated in the corrected theorem note.

### Small-j exception census

For

\[
1\le j\le s,
\]

classify full shadows by the finite group / trap geometry of `S_j`.

This small range is not noise. It intersects the dyadic trap lattice and other multiplicative-saturation phenomena and may possess infinite families as `s` varies.

## 6. Scientific record

The invalid all-`j` proof remains available in Git history for provenance but must not be cited as a theorem.

The canonical status is now:

```text
all-j odd-prime-shift rigidity:      FALSE
asymptotic j>=s+1 rigidity:          PROVED
small-j exception classification:    OPEN
```
