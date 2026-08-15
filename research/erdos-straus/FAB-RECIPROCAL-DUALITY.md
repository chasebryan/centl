# Reciprocal fab duality and the two-residue collapse

**Status:** exact sufficient theorems proved below; universal existence remains open  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Depends on:** `FAB-COPRIME-DIVISOR-CRITERION.md`, `FAB-FIXED-K-SQUARE-DIVISOR.md`, `FAB-SHIFTED-FACTOR-DESCENT.md`  
**Claim boundary:** nothing below is a proof of Erdős–Straus. The finite `p<=50,000,000` result is an exact computational observation, not a universal theorem.

## 1. Rotate the coprime fab equations

Let

\[
p\equiv1\pmod4
\]

be prime. Choose positive integers `b,c` and put

\[
M=4bc,
\qquad
N=1+bM=1+4b^2c.
\]

Suppose a positive divisor `k|N` satisfies

\[
\boxed{k\equiv-p\pmod M.}
\]

Then `gcd(p,M)=1`: if a prime factor of `p` divided `M`, the displayed congruence would force it to divide `k`, while `k|1+bM` would force the same prime to divide `1`.

Write

\[
\boxed{d=N/k.}
\]

Since

\[
kd=N\equiv1\pmod M,
\]

the complementary factor is forced into the reciprocal ray class

\[
\boxed{d\equiv-p^{-1}\pmod M.}
\]

Therefore

\[
M\mid p+k,
\qquad
M\mid pd+1.
\]

Define

\[
\boxed{a=\frac{p+k}{M},
\qquad
q=\frac{pd+1}{M}.}
\]

Both are positive integers. Moreover

\[
ad
=\frac{(p+k)d}{M}
=\frac{pd+kd}{M}
=\frac{pd+1+bM}{M}
=q+b,
\]

so

\[
\boxed{q=ad-b.}
\]

Also

\[
kq
=\frac{k(pd+1)}{M}
=\frac{p(kd)+k}{M}
=\frac{p(1+bM)+k}{M}
=a+bp.
\]

Finally

\[
p+k=M a=4abc.
\]

Thus `k` is an admissible `fab` divisor and

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

This proves:

### Theorem 1 — rotated factor criterion

For prime `p=1 mod 4`, it is sufficient to find positive `b,c` such that

\[
\boxed{
\exists k\mid1+4b^2c:
\qquad
k\equiv-p\pmod{4bc}.
}
\]

The target prime has disappeared from the integer being factored. It survives only in the ray-class selection condition.

## 2. Complementary-factor duality

The same certificate has the exact six-variable skeleton

\[
\boxed{
\begin{aligned}
p+k&=4abc,\\
pd+1&=4bcq,\\
kd&=1+4b^2c,\\
q&=ad-b.
\end{aligned}}
\]

The two factors of `1+4b^2c` occupy reciprocal classes modulo `4bc`:

\[
\boxed{
k\equiv-p,
\qquad
d\equiv-p^{-1}
\pmod{4bc}.}
\]

This is the reciprocal symmetry that is invisible when the search is written only as `k|a+bp`.

## 3. The factor search collapses to two least residues

For fixed `b,c`, no general factorization of `N=1+4b^2c` is needed.

Indeed

\[
M=4bc\ge4b,
\]

so

\[
N=1+bM
\le1+\frac{M^2}{4}
<M^2.
\]

Hence for every factorization `N=kd`, at least one of `k,d` is strictly smaller than `M`.

Let

\[
r=\langle-p\rangle_M,
\qquad
s=\langle-p^{-1}\rangle_M
\]

be the least positive residues, so `1<=r,s<M`.

If `k<M`, its ray class forces `k=r`. If `d<M`, its reciprocal ray class forces `d=s`.

Conversely, if `r|N`, take `k=r`; because `N=1 mod M`, its complement automatically lies in the class `s`. Likewise if `s|N`, take `d=s` and the complementary factor automatically lies in the class `r`.

Therefore:

### Theorem 2 — two-residue collapse

For fixed positive `b,c`, with `M=4bc` and `N=1+bM`, the rotated criterion succeeds if and only if

\[
\boxed{
r\mid N\quad\text{or}\quad s\mid N,}
\]

where

\[
\boxed{
r=\langle-p\rangle_M,
\qquad
s=\langle-p^{-1}\rangle_M.}
\]

So the fixed-`(b,c)` bridge is exactly **two divisibility tests**. No divisor enumeration is necessary.

This is useful for proof search because a hypothetical counterexample must make both the direct residue defect and its modular-inverse defect miss `1+4b^2c` for every selected `(b,c)`.

## 4. A reciprocal fixed-d square-divisor theorem

There is a second formulation parallel to `FAB-FIXED-K-SQUARE-DIVISOR.md`.

Fix

\[
d\equiv3\pmod4
\]

and put

\[
\boxed{Q_d=\frac{pd+1}{4}.}
\]

Suppose there is a divisor

\[
D\mid Q_d^2
\]

such that

\[
\boxed{4D\equiv-1\pmod d.}
\]

Factor `Q_d` prime by prime. For every `r^E || Q_d`, put `U=v_r(D)` and define exponent contributions

\[
\begin{aligned}
v_r(q)&=\max(E-U,0),\\
v_r(b)&=\max(U-E,0),\\
v_r(c)&=E-|E-U|.
\end{aligned}
\]

Then

\[
\boxed{Q_d=bcq,
\qquad
D=b^2c,
\qquad
\gcd(b,q)=1.}
\]

Set

\[
\boxed{k=\frac{4D+1}{d}.}
\]

The congruence makes `k` integral. Because `4D+1=kd` and `d=3 mod4`, also `k=3 mod4`.

Now

\[
pd+1=4bcq,
\qquad
kd=1+4b^2c.
\]

Modulo `d`, these imply

\[
4bcq\equiv1,
\qquad
4b^2c\equiv-1.
\]

Since `gcd(4bc,d)=1`,

\[
q+b\equiv0\pmod d.
\]

Define

\[
\boxed{a=\frac{q+b}{d}.}
\]

Then

\[
\boxed{p+k=4abc,
\qquad
a+bp=kq,}
\]

and the same exact Egyptian-fraction decomposition follows.

Hence:

### Theorem 3 — reciprocal fixed-d square criterion

For prime `p=1 mod4` and any positive `d=3 mod4`,

\[
\boxed{
\exists D\mid\left(\frac{pd+1}{4}\right)^2:
\quad4D\equiv-1\pmod d
}
\]

is sufficient for Erdős–Straus at `p`.

This theorem has no `a,b<p` size hypothesis because the reconstructed parameters are checked directly against the original `fab` admissibility equations.

## 5. Reciprocal double sieve

The forward fixed-factor criterion and Theorem 3 now form two parallel lanes for every `m=3 mod4`.

### Forward lane

\[
X_m=\frac{p+m}{4},
\qquad
\exists D\mid X_m^2:
4D\equiv-1\pmod m.
\]

### Reciprocal lane

\[
Y_m=\frac{pm+1}{4},
\qquad
\exists D\mid Y_m^2:
4D\equiv-1\pmod m.
\]

The target residue

\[
\boxed{D\equiv-4^{-1}\pmod m}
\]

is identical in both lanes and is independent of `p`.

Thus a hard-prime counterexample to this program must avoid the same fixed target class simultaneously in the divisor squares of two reciprocal linear forms for every tested `m=3 mod4`.

That is a much tighter obstruction than either lane by itself.

## 6. Exact finite signal through fifty million

A standalone exact replay of the reciprocal double sieve over the six Mordell-hard residue classes modulo `840` gives:

- prime bound: `50,000,000`;
- Mordell-hard primes: `93,457`;
- tested parameters: every `m=3 mod4` with `3<=m<=59`;
- captured by at least one lane: `93,457`;
- unresolved: `0`;
- largest first-success parameter: `59`.

The first-success distribution from the replay is:

| lane | m | captures |
|---|---:|---:|
| forward | 3 | 41,703 |
| reciprocal | 3 | 24,830 |
| forward | 7 | 11,695 |
| reciprocal | 7 | 7,351 |
| forward | 11 | 4,633 |
| reciprocal | 11 | 1,332 |
| forward | 15 | 587 |
| reciprocal | 15 | 489 |
| forward | 19 | 383 |
| reciprocal | 19 | 128 |
| forward | 23 | 200 |
| reciprocal | 23 | 34 |
| forward | 27 | 28 |
| reciprocal | 27 | 11 |
| forward | 31 | 38 |
| reciprocal | 31 | 6 |
| forward | 35 | 3 |
| reciprocal | 35 | 1 |
| forward | 39 | 2 |
| reciprocal | 39 | 1 |
| forward | 47 | 1 |
| forward | 59 | 1 |

The unique first-success at `m=59` in this scan is

\[
\boxed{p=118801.}
\]

One reconstructed certificate is

\[
(a,b,c,k,d,q)=(7,5,849,59,1439,10068),
\]

which yields

\[
\boxed{
\frac4{118801}
=
\frac1{29715}
+
\frac1{59834124}
+
\frac1{5077395546660}.
}
\]

The reciprocity lane is not redundant in the finite data. For example

\[
p=8803369
\]

survives the forward lane for every `m=3 mod4` below `100`, but the reciprocal lane succeeds already at

\[
\boxed{d=15.}
\]

A reconstructed reciprocal certificate is

\[
(a,b,c,k,d,q)=(17,1,129971,34659,15,254).
\]

Again, these are finite facts only.

## 7. The new universal wall

A proof through this route can now target a much smaller statement than universal Type A/B depth behavior:

> For every Mordell-hard prime `p`, there exists some `m=3 mod4` such that the fixed target `-4^{-1} mod m` occurs among the divisors of either
>
> \[
> \left(\frac{p+m}{4}\right)^2
> \]
>
> or
>
> \[
> \left(\frac{pm+1}{4}\right)^2.
> \]

The finite data raises the stronger experimental question of whether a bounded menu through `m=59` is sufficient on all hard primes. **No bounded universal claim is made.**

The proof search should now attack the simultaneous-failure condition for the forward and reciprocal linear forms, especially at `m=3,7,11,15,19,23,...`, rather than expanding another Type A/B depth census.
