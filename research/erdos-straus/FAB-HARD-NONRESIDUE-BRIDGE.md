# Coprime fab certificates force an external hard-class nonresidue

**Status:** proved structural theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-COPRIME-DIVISOR-CRITERION.md`  
**Claim boundary:** this gives a necessary condition for coprime fab certificates on the Mordell-hard prime classes. It does not prove existence of such a certificate for every prime and therefore does not prove Erdős-Straus.

## 1. Setup

Let `p` be a Mordell-hard prime:

\[
p\bmod840\in\{1,121,169,289,361,529\}.
\]

In particular

\[
\boxed{p\equiv1\pmod8}
\]

and `p` is a quadratic residue modulo `3`, `5`, and `7`.

Suppose `a,b` are coprime positive integers below `p`, and `k` is a coprime fab certificate as in `FAB-COPRIME-DIVISOR-CRITERION.md`:

\[
k\mid a+bp,
\qquad
k\equiv-p\pmod{4ab}.
\]

Write

\[
\boxed{p+k=4abc}
\]

with `c>0`, and put

\[
q=\frac{a+bp}{k}.
\]

## 2. Auxiliary factorization

From

\[
kq=a+bp
\]

and

\[
p=4abc-k,
\]

we get

\[
kq
=a+b(4abc-k)
=a+4ab^{2}c-bk.
\]

Hence

\[
k(q+b)=a(1+4b^{2}c).
\]

The coprime criterion gives `gcd(a,k)=1`, so

\[
\boxed{k\mid1+4b^{2}c.}
\]

Write

\[
\boxed{kd=1+4b^{2}c.}
\]

Since the right side is `1 mod4` and `k=3 mod4`, necessarily

\[
\boxed{d\equiv3\pmod4.}
\]

Also

\[
\boxed{\gcd(k,c)=1,}
\]

because a common divisor would divide `1`.

## 3. Nonresidue theorem

### Theorem

For a Mordell-hard prime `p`, the leftover factor `c` satisfies

\[
\boxed{\left(\frac{c}{p}\right)=-1,}
\]

where the symbol is the Legendre/Jacobi symbol after removing square factors in the numerator.

### Proof for odd c

Modulo `k`,

\[
4b^{2}c\equiv-1.
\]

Since `4b^2` is a square modulo `k`,

\[
\left(\frac{c}{k}\right)
=
\left(\frac{-1}{k}\right)
=-1
\]

because `k≡3 mod4`.

On the other hand

\[
p\equiv-k\pmod c.
\]

For odd `c`, Jacobi reciprocity and `k≡3 mod4` give

\[
\left(\frac{-k}{c}\right)
=
\left(\frac{c}{k}\right).
\]

Therefore

\[
\left(\frac{p}{c}\right)=-1.
\]

Because `p≡1 mod4`, reciprocity introduces no sign when reversing `p` and the odd part of `c`, hence

\[
\left(\frac{c}{p}\right)=-1.
\]

### Even c

Write `c=2^e c_0` with `c_0` odd.

Since the hard classes satisfy `p≡1 mod8`,

\[
\left(\frac2p\right)=1.
\]

If `e>0`, the identity `p+k=4abc` forces `p+k≡0 mod8`, so

\[
k\equiv7\pmod8
\]

and therefore

\[
\left(\frac2k\right)=1.
\]

Removing the factor `2^e` from the reciprocity calculation leaves the same sign as in the odd case. Thus again

\[
\boxed{\left(\frac{c}{p}\right)=-1.}
\]

QED.

## 4. External-prime corollary

For every hard class,

\[
\left(\frac2p\right)
=
\left(\frac3p\right)
=
\left(\frac5p\right)
=
\left(\frac7p\right)
=1.
\]

The first equality follows from `p=1 mod8`; the others follow by quadratic reciprocity from the fact that the six hard residues are quadratic residues modulo `3`, `5`, and `7`.

If every prime factor of `c` belonged to `{2,3,5,7}` or occurred only through square contributions, then `(c/p)=1`, contradicting the theorem.

Therefore:

### Corollary

Every coprime fab certificate for a Mordell-hard prime contains an odd prime factor

\[
\boxed{\ell\mid c,\qquad \ell\ge11}
\]

with odd valuation contribution and

\[
\boxed{\left(\frac{\ell}{p}\right)=-1.}
\]

Since `p≡1 mod4`, equivalently

\[
\boxed{\left(\frac{p}{\ell}\right)=-1.}
\]

## 5. Why this matters

The Type A/B / shadow program reached residual small-prime coordinates beginning at `11` and `13` after the `3,5,7` hard shield was imposed.

The divisor-parametrization framework reaches the same boundary from the opposite direction: a coprime certificate cannot live entirely inside the `2,3,5,7` squareclass support. It must import a genuine external nonresidue prime.

Thus a promising all-prime strategy is to coordinate:

1. the first external quadratic nonresidue of the hard prime;
2. the factorization of the linear forms `a+bp`;
3. the divisor class `k=-p mod 4ab` from the coprime criterion.

This is a structural bridge between the two research languages, not a claim that the remaining existence theorem is closed.
