# q=3 Factor-Pair Types and Target Alignment

**Status:** proved universal algebraic reduction; the former three-species impossibility target is **refuted**  
**Date:** 2026-08-15  
**Depends on:** `Q3-NEXT-DIGIT-THEOREM.md`, `Q3-POINTWISE-DIVISOR-REDUCTION.md`  
**Read with:** `DSC-COUNTEREXAMPLE.md`  
**Claim boundary:** the factor-pair identities below are proved. They do **not** prohibit all three species from aligning; `DSC-COUNTEREXAMPLE.md` explicitly realizes all three on one directly novel target.

---

## 1. Trap factor pair

For layer `j`, put

\[
m=4j-1.
\]

Every Type A/B trap can be represented as

\[
u\equiv-w\pmod m
\]

where either

\[
w=e
\qquad\text{or}\qquad
w=4e
\]

for a divisor `e|j`.

In either case `w` divides `4j=m+1`. Define

\[
\boxed{a=\frac{m+1}{w}.}
\]

Then

\[
\boxed{wa=m+1.}
\]

Thus each trap carries an ordered positive factor pair `(w,a)` of `m+1`.

---

## 2. Hard-compatible q=3 factor pairs

Assume the trap can occur on a Mordell-hard progression at a q=3 layer. Every hard class is

\[
1\pmod3.
\]

Therefore

\[
u\equiv1\pmod3.
\]

Since `u=-w mod m` and `3|m`,

\[
\boxed{w\equiv2\pmod3.}
\]

Also

\[
wa=m+1\equiv1\pmod3,
\]

so

\[
\boxed{a\equiv2\pmod3.}
\]

When `v3(m)=2`,

\[
wa\equiv1\pmod9.
\]

The units modulo 9 that are `2 mod 3` are exactly

\[
\{2,5,8\}.
\]

Their inverses are

\[
2^{-1}=5,
\qquad
5^{-1}=2,
\qquad
8^{-1}=8
\pmod9.
\]

Hence exactly three ordered species occur:

\[
\boxed{
(w,a)\pmod9
\in
\{(2,5),(5,2),(8,8)\}.
}
\]

---

## 3. Three species = three next 3-adic digits

The trap residue is

\[
u\equiv-w\pmod9.
\]

Therefore

\[
\begin{array}{c|c}
(w,a)\pmod9 & u\pmod9\\
\hline
(2,5) & 7\\
(5,2) & 4\\
(8,8) & 1
\end{array}
\]

By `Q3-NEXT-DIGIT-THEOREM.md`, `{1,4,7}` are the three possible lifts of the common frozen `1 mod 3` prefix and are carried bijectively to the three parameter classes by one common affine relabeling.

Thus a full corrected-domain q=3 cover is equivalent to realizing all three factor-pair species among aligned surviving trap witnesses.

This equivalence is now not merely conceptual: `DSC-COUNTEREXAMPLE.md` realizes all three species simultaneously.

---

## 4. Target factor pair

Let the target depth be `k`, with

\[
M=4k-1.
\]

If the target trap is

\[
t\equiv-W\pmod M,
\]

write

\[
\boxed{A=\frac{M+1}{W}}
\]

so that

\[
\boxed{WA=M+1=4k.}
\]

Let `(w,a)` be a local q=3 trap factor pair at layer `j`.

Suppose a positive integer `b` divides both local and target moduli:

\[
\boxed{b\mid m,\qquad b\mid M.}
\]

If target and local trap residues are compatible on this coordinate,

\[
t\equiv u\pmod b,
\]

then

\[
-W\equiv-w\pmod b,
\]

hence

\[
\boxed{W\equiv w\pmod b.}
\]

Because

\[
WA\equiv1\pmod b
\]

and

\[
wa\equiv1\pmod b,
\]

we also obtain

\[
\boxed{A\equiv a\pmod b.}
\]

Therefore

\[
\boxed{(W,A)\equiv(w,a)\pmod b.}
\]

---

## 5. Determinant divisibility

The coordinatewise congruence gives

\[
\boxed{b\mid(Wa-wA).}
\]

Each aligned q=3 row therefore supplies a divisor of the cross-determinant between target and local factor-pair vectors.

This remains a useful invariant even though it does not force impossibility.

---

## 6. Explicit realization of all three species

`DSC-COUNTEREXAMPLE.md` uses

\[
\begin{array}{c|c|c}
 j & (w,a) & \text{species mod }9\\
\hline
25  & (20,5)  & (2,5)\\
70  & (14,20) & (5,2)\\
187 & (44,17) & (8,8)
\end{array}
\]

on shared target coordinates `11,31,83`.

CRT gives target factor pair

\[
\boxed{(W,A)=(23450,764)}
\]

and hence

\[
WA-1=17,915,799=4(4,478,950)-1.
\]

The resulting admissible candidate is directly novel and the three rows occupy all three q=3 classes.

Therefore the former conjectural statement

\[
\text{“one target factor pair cannot support all three species”}
\]

is false.

---

## 7. New use of the factor-pair formalism

The factor-pair framework is now a **construction theory**, not an impossibility theory.

It can be used to:

1. synthesize collective cores by CRT-gluing local factor pairs;
2. classify which local species can coexist on a target;
3. derive exact target arithmetic from a proposed core;
4. search for smaller or infinite families of collective-shadow examples;
5. connect collective cores to divisor parametrizations for the all-prime problem.

The active question is therefore no longer whether all three species can align. They can. The question is how the resulting collective cores are organized and whether that organization helps prove eventual Type A/B coverage of every prime.
