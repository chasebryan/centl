# Binary-r rescue after one exact greedy denominator

**Status:** proved exact criterion; finite theorem-mining evidence deposited separately  
**Date:** 2026-08-15  
**Claim boundary:** this gives an exact sufficient-and-necessary binary criterion after fixing the first denominator. It does not prove that a suitable `r` always exists and therefore does not prove Erdős–Straus.

## 1. One denominator leaves a binary problem

Let

\[
p\equiv1\pmod4
\]

be prime, and let

\[
\boxed{r\equiv3\pmod4}
\]

be a prime. Put

\[
\boxed{A_r=\frac{p+r}{4}}.
\]

Then

\[
4A_r=p+r,
\]

so

\[
\frac4p-\frac1{A_r}
=
\frac{4A_r-p}{pA_r}
=
\boxed{\frac r{pA_r}}.
\]

Define

\[
\boxed{N_r=pA_r.}
\]

Hence

\[
\boxed{
\frac4p
=
\frac1{A_r}
+
\frac r{N_r}.
}
\]

The Erdős–Straus problem for this chosen first denominator is therefore exactly a two-unit-fraction problem.

---

## 2. Exact binary divisor criterion

Because `p≡1 mod4` and `r≡3 mod4`, `r!=p`. Also

\[
A_r\equiv p\,4^{-1}\pmod r,
\]

so

\[
\gcd(N_r,r)=1.
\]

Let `d` be a positive divisor of `N_r^2`, and put

\[
d_1=\frac{N_r^2}{d}.
\]

If

\[
\boxed{d\equiv-N_r\pmod r,}
\]

then, since `N_r` is invertible modulo `r`,

\[
d^{-1}\equiv-N_r^{-1}\pmod r
\]

and therefore

\[
d_1=N_r^2d^{-1}\equiv-N_r\pmod r.
\]

Thus both

\[
\boxed{Y=\frac{N_r+d}{r}},
\qquad
\boxed{Z=\frac{N_r+d_1}{r}}
\]

are positive integers.

Now

\[
\frac1Y+\frac1Z
=
\frac{r}{N_r+d}+
\frac{r}{N_r+d_1}.
\]

Since `dd_1=N_r^2`,

\[
(N_r+d)(N_r+d_1)
=N_r(2N_r+d+d_1),
\]

while the numerator is

\[
r(2N_r+d+d_1).
\]

Hence

\[
\boxed{
\frac1Y+\frac1Z=\frac r{N_r}.
}
\]

Combining with the first denominator gives

\[
\boxed{
\frac4p
=
\frac1{A_r}
+
\frac1Y
+
\frac1Z.
}
\]

Conversely, the standard factorization of a two-unit-fraction equation shows that every split

\[
\frac r{N_r}=\frac1Y+\frac1Z
\]

produces

\[
d=rY-N_r,
\qquad
 d_1=rZ-N_r,
\]

with

\[
dd_1=N_r^2,
\qquad
 d\equiv d_1\equiv-N_r\pmod r.
\]

Therefore the divisor condition is exact for the fixed `r`.

---

## 3. The target is always a quadratic nonresidue

Modulo `r`,

\[
N_r
=p\frac{p+r}{4}
\equiv\frac{p^2}{4}.
\]

Thus the target class is

\[
\boxed{
-N_r\equiv-\frac{p^2}{4}\pmod r.
}
\]

The factor `p^2/4` is a square modulo `r`, while

\[
\left(\frac{-1}{r}\right)=-1
\]

because `r≡3 mod4`. Hence

\[
\boxed{
\left(\frac{-N_r}{r}\right)=-1.
}
\]

So every binary-r rescue must select a **quadratic-nonresidue divisor of `N_r^2` in one exact residue class**.

This is the cleanest direct bridge found so far between:

- the external-nonresidue phenomenon in `FAB-HARD-NONRESIDUE-BRIDGE.md`;
- the factorization of a nearby shifted integer `(p+r)/4`;
- an actual three-term Erdős–Straus decomposition.

Unlike the coprime-fab route, this criterion does not require the three denominators of the associated `1/p` decomposition to all be divisible by `4`.

---

## 4. Relation to the r=3 filter

For

\[
r=3,
\qquad
A_3=\frac{p+3}{4},
\]

the unit group modulo `3` has only two classes. The target nonresidue is the unique class `2 mod3`.

Thus the failure of the `r=3` binary rescue forces the prime-factor support of `A_3` into the `1 mod3` side, recovering the exact first filter already deposited in `FAB-HARD-FIRST-FILTERS.md`.

The significance of larger `r` is that they preserve the same exact binary mechanism while introducing a richer but still finite multiplicative residue group.

---

## 5. Finite theorem-mining signal

`one_shot_es_probe.py` independently replays this criterion.

Through `p<=500,000`:

- Mordell-hard primes: `1,246`;
- survivors of the first four exact shifted-factor theorems: `202`;
- every one of those `202` has a binary-r rescue for a prime
  \[
  r\equiv3\pmod4,
  \qquad r\le71;
  \]
- the first successful `r` histogram is

```text
r=7   : 77
r=11  : 73
r=19  : 27
r=23  : 10
r=31  : 13
r=59  : 1
r=71  : 1
```

There are zero unresolved candidates in that finite census when the probe is allowed primes `r<=200`.

This is finite evidence only. It is **not** a proof that `r<=71`, `r<=200`, or any fixed finite bound works universally.

---

## 6. New theorem target

The pointwise all-prime wall can now be attacked in the following form:

> For every Mordell-hard prime `p`, prove that there exists a prime `r≡3 mod4` such that the divisor box of
> \[
> N_r^2
> =p^2\left(\frac{p+r}{4}\right)^2
> \]
> contains the exact nonresidue class
> \[
> -N_r\pmod r.
> \]

Equivalently, classify failure of the exact target class for each small `r` as a multiplicative residue-support restriction on `(p+r)/4`, then prove that the simultaneous failure restrictions cannot persist for all `r`.

This route attacks Erdős–Straus directly and does not require resurrecting the false universal DSC conjecture.
