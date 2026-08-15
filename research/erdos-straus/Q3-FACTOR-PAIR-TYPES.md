# q=3 Factor-Pair Types and Target Alignment

**Status:** proved universal algebraic reduction  
**Date:** 2026-08-15  
**Depends on:** `Q3-NEXT-DIGIT-THEOREM.md`, `Q3-POINTWISE-DIVISOR-REDUCTION.md`  
**Claim boundary:** converts the q=3 digit problem into an exact factor-pair alignment problem. It does not yet prove that all three species cannot align on one admissible target.

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

In either case `w` divides `4j=m+1`. Define the complementary positive integer

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

Therefore the trap residue must satisfy

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

When `v3(m)=2` (the common `v3(L)=1` q=3 regime),

\[
wa\equiv1\pmod9.
\]

The units modulo 9 that are `2 mod 3` are exactly

\[
\{2,5,8\}.
\]

Their inverses modulo 9 are

\[
2^{-1}=5,
\qquad
5^{-1}=2,
\qquad
8^{-1}=8.
\]

Hence there are exactly three possible ordered q=3 factor-pair types:

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

Therefore the three factor-pair species produce

\[
\begin{array}{c|c}
(w,a)\pmod9 & u\pmod9\\
\hline
(2,5) & 7\\
(5,2) & 4\\
(8,8) & 1
\end{array}
\]

By `Q3-NEXT-DIGIT-THEOREM.md`, `{1,4,7}` are precisely the three possible lifts of the common frozen `1 mod 3` prefix and are carried bijectively to the three parameter classes `0,1,2` by one common affine relabeling.

Thus a full corrected-domain q=3 cover is equivalent to realizing **all three factor-pair species** among the aligned surviving trap witnesses.

On a directly novel candidate we may sharpen `surviving` to **ancestry-minimal** by `Q3-POINTWISE-DIVISOR-REDUCTION.md`.

Hence the universal local target becomes

\[
\boxed{
\text{Can one admissible target align ancestry-minimal q=3 pairs of all three types }(2,5),(5,2),(8,8)?
}
\]

---

## 4. Target factor pair

Now let the target depth be `k`, with

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

If the target and local trap residues are compatible on this shared coordinate,

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

and `W,w` are units modulo `b`, their inverses agree. Therefore

\[
\boxed{A\equiv a\pmod b.}
\]

So the complete ordered factor pair aligns coordinatewise:

\[
\boxed{(W,A)\equiv(w,a)\pmod b.}
\]

---

## 5. Determinant divisibility

The coordinatewise congruence immediately gives

\[
\boxed{b\mid(Wa-wA).}
\]

Thus every aligned q=3 row supplies an exact divisor of the cross-determinant between the target and local factor-pair vectors.

This is a useful rigidity invariant because the local row also satisfies

\[
wa=m+1,
\]

while the target satisfies

\[
WA=M+1.
\]

The remaining proof search can therefore be phrased in terms of simultaneous divisor constraints on

\[
Wa-wA
\]

for ancestry-minimal local pairs of the three distinct modulo-9 species.

---

## 6. Why this is sharper than residue bookkeeping

The previous q=3 formulation stored only a forbidden digit.

The factor-pair formulation retains:

1. the digit species modulo 9;
2. the exact divisor identity `wa=m+1`;
3. the exact target identity `WA=M+1`;
4. coordinatewise congruence on every shared target factor;
5. determinant divisibility.

A universal q=3 closure theorem can now target a concrete Diophantine impossibility:

\[
\boxed{
\text{one target factor pair cannot support ancestry-minimal aligned local pairs of all three mod-9 species.}
}

This is the active analytic target.
