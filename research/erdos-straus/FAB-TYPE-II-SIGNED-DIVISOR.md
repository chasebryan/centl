# Normalized Type-II signed-divisor target

**Status:** proved exact sufficient criterion; complete for prime Type-II solutions after canonical normalization  
**Date:** 2026-08-15  
**External framework:** Bello-Hernández, Benito, Fernández, *A Divisor Parametrization for the Erdős--Straus Conjecture*, arXiv:2606.10922v1  
**Depends on:** `FAB-COPRIME-DIVISOR-CRITERION.md`, `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`  
**Claim boundary:** this note does not prove Erdős--Straus. It identifies a second exact target in the same fixed-`k` signed divisor box used by the strong Type-I/FAB lane.

---

## 1. Fixed-k signed divisor box

Let `p` be a prime with

\[
p\equiv1\pmod4,
\]

and let

\[
k\equiv3\pmod4,
\qquad
\gcd(p,k)=1.
\]

Put

\[
C=\frac{p+k}{4}
=\prod_i r_i^{e_i}.
\]

Because `gcd(C,k)=1`, define

\[
\boxed{
\mathcal R_k(C)
=
\left\{
\prod_i r_i^{z_i}\pmod k:
-e_i\le z_i\le e_i
\right\}
\subseteq(\mathbb Z/k\mathbb Z)^\times.
}
\]

The existing strong fixed-`k` FAB theorem asks whether

\[
-p^{-1}\in\mathcal R_k(C).
\]

There is a second natural target.

---

## 2. Type-II target theorem

### Theorem

If

\[
\boxed{-1\in\mathcal R_k(C),}
\]

then `p` satisfies the Erdős--Straus equation.

### Proof

Choose exponents `z_i` with

\[
-e_i\le z_i\le e_i
\]

such that

\[
\prod_i r_i^{z_i}\equiv-1\pmod k.
\]

Split the prime powers of `C` into three positive integers `A,B,T` prime by prime:

- if `z_i<0`, put `r_i^{-z_i}` into `A`;
- if `z_i>0`, put `r_i^{z_i}` into `B`;
- put the remaining `r_i^{e_i-|z_i|}` into `T`.

Then

\[
\boxed{ABT=C,\qquad \gcd(A,B)=1,}
\]

and

\[
BA^{-1}\equiv-1\pmod k.
\]

Since `A` is a unit modulo `k`, this is equivalent to

\[
\boxed{k\mid A+B.}
\]

Put

\[
Q=\frac{A+B}{k}.
\]

Also

\[
p+k=4C=4ABT.
\]

Therefore

\[
\begin{aligned}
\frac1{ABT}
+\frac1{pAQT}
+\frac1{pBQT}
&=
\frac{pQ+B+A}{pABQT}\\
&=
\frac{Q(p+k)}{pABQT}\\
&=
\frac4p.
\end{aligned}
\]

Hence

\[
\boxed{
\frac4p
=
\frac1{ABT}
+
\frac1{pAQT}
+
\frac1{pBQT}.
}
\]

This has the standard Type-II shape: two displayed denominators carry a factor `p`. QED.

---

## 3. Exact normalized Type-II lane

The theorem can be stated without the box notation.

For `p≡1 mod4`, a normalized Type-II certificate consists of positive integers

\[
A,B,T,Q,k
\]

satisfying

\[
\boxed{
A+B=kQ,
\qquad
p+k=4ABT,
\qquad
k\equiv3\pmod4.
}
\]

The associated identity is

\[
\boxed{
\frac4p
=
\frac1{ABT}
+
\frac1{pAQT}
+
\frac1{pBQT}.
}
\]

At fixed `k`, the first two equations say exactly

\[
AB\mid C=\frac{p+k}{4}
\]

and

\[
B/A\equiv-1\pmod k.
\]

Every signed exponent vector in `[-e_i,e_i]` is exactly a coprime choice of the ratio `B/A` with the unused prime-power mass assigned to `T`. Hence the Type-II target is precisely

\[
\boxed{\tau_{II}=-1.}
\]

---

## 4. Completeness for prime Type-II solutions

The recent divisor-parametrization theorem is complete for Erdős--Straus decompositions after scaling by `4`. Its canonical construction can be normalized so that every prime Type-II solution lands in the target above.

Start from a Type-II solution and scale it to

\[
\frac1p=\frac1X+\frac1Y+\frac1Z,
\qquad 4\mid X,Y,Z,
\]

choosing `X` to be the unique denominator not divisible by `p`, and `Y,Z` the two denominators divisible by `p`.

Set

\[
k=X-p,
\qquad
g=\gcd(X,Y),
\qquad b=\frac Xg,
\qquad q=\frac Yg,
\qquad a=\frac{kY-pX}{g}=kq-pb.
\]

The completeness proof of Bello-Hernández--Benito--Fernández gives these as admissible FAB data.

Because `p\nmid X`, one has `p\nmid k` and `p\nmid g`. Also `gcd(b,q)=1`. Further,

\[
\gcd(a,b)
=
\gcd(kq-pb,b)
=
\gcd(kq,b)
=
\gcd(k,b).
\]

Any common divisor of `k` and `b` divides both `k` and `X=gb`, hence divides `X-k=p`. Since `p\nmid k`,

\[
\boxed{\gcd(a,b)=1.}
\]

Because `p\mid Y` and `p\nmid g`, write

\[
q=pQ.
\]

Then `kq=a+bp` forces `p\mid a`; write

\[
a=pA.
\]

The divisor equation becomes

\[
\boxed{kQ=A+b.}
\]

The third scaled denominator is

\[
Z=\frac{pq(p+k)}{a}.
\]

Since `p\mid Z`, while `p\nmid k`, the normalized factor `A` cannot contain `p`: if `p\mid A`, then `gcd(A,Q)=1` and `p\nmid(p+k)`, so cancelling `a=pA` would remove the only remaining required `p`-factor from `Z` (and higher `p`-valuation in `A` would violate integrality). Hence

\[
\boxed{p\nmid A.}
\]

Write

\[
c=\frac{p+k}{4}.
\]

The two FAB divisibility conditions reduce, using the displayed coprimalities, to

\[
b\mid c,
\qquad
A\mid c.
\]

Since `gcd(A,b)=1`,

\[
\boxed{Ab\mid c.}
\]

Put

\[
T=\frac c{Ab}.
\]

Then

\[
A+b=kQ,
\qquad
p+k=4AbT,
\]

which is exactly the normalized Type-II lane above. Therefore every prime Type-II solution supplies a fixed-`k` signed-divisor hit at

\[
\boxed{-1\in\mathcal R_k(C).}
\]

---

## 5. Classical parameter match

The normalized equations are the standard Type-II surface in divisor coordinates. Eliminating `k` from

\[
A+B=kQ,
\qquad
p+k=4ABT
\]

gives

\[
\boxed{(4BQT-1)A=pQ+B.}
\]

Thus, with the standard Type-II parameters

\[
(A_{\rm std},B_{\rm std},C_{\rm std},D_{\rm std})
=(Q,B,T,A),
\]

this is

\[
(4A_{\rm std}B_{\rm std}C_{\rm std}-1)D_{\rm std}
=A_{\rm std}p+B_{\rm std}.
\]

So the new point is not a new Type-II parametrization. The useful observation is that **Type II and the strong fixed-k FAB/Type-I lane live in the same signed divisor box**.

---

## 6. Two targets in one box

At fixed `k` and `C=(p+k)/4`, we now have

\[
\boxed{
\begin{array}{rcl}
\tau_I&=&-p^{-1}\pmod k,\\[2mm]
\tau_{II}&=&-1\pmod k.
\end{array}}
\]

Thus the same multiplicative expansion machinery can attack both classical solution types simultaneously.

This observation is the input for `FAB-TWO-TARGET-KNESER.md`.
