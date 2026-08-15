# `fab` Character Bridge

**Status:** proved elementary character theorem inside the coprime opposite-parity `fab` plane  
**Date:** 2026-08-15  
**Depends on:** `FAB-COPRIME-PARITY-PLANE.md`  
**Prior-art boundary:** the `fab` parametrization is from Bello-Hernández, Benito, Fernández (2026). The character deductions below are elementary consequences used to connect that parametrization to the FCF/CENTL character framework.  
**Claim boundary:** this does not prove every prime has a `fab` certificate.

---

## 1. Certificate equations

Let

\[
p\equiv1\pmod4
\]

be prime.

Suppose positive integers `a,b` satisfy

\[
\gcd(a,b)=1,
\qquad
\gcd(a,p)=1,
\]

and have opposite parity.

By `FAB-COPRIME-PARITY-PLANE.md`, an exact certificate is a divisor

\[
k\mid a+bp
\]

satisfying

\[
\boxed{p+k=4abc}
\]

for some positive integer `c`.

Equivalently,

\[
k\equiv-p\pmod{4ab}.
\]

---

## 2. Hidden local congruence

From

\[
p=4abc-k
\]

we obtain

\[
a+bp
=a+4ab^2c-bk
=a(1+4b^2c)-bk.
\]

Because

\[
k\mid a+bp
\]

and trivially

\[
k\mid bk,
\]

we have

\[
k\mid a(1+4b^2c).
\]

Moreover

\[
\gcd(a,k)=1
\]

because `k|a+bp` and `gcd(a,bp)=1`.

Therefore

\[
\boxed{k\mid1+4b^2c.}
\]

This is the local congruence hidden inside the simplified divisor criterion.

---

## 3. `c` is a Jacobi nonresidue modulo `k`

The congruence gives

\[
4b^2c\equiv-1\pmod k.
\]

In particular

\[
\gcd(2bc,k)=1.
\]

For every odd prime `ell|k`,

\[
(2b)^2c\equiv-1\pmod\ell.
\]

Hence

\[
\left(\frac c\ell\right)
=
\left(\frac{-1}\ell\right).
\]

Multiplying with prime-power multiplicity gives

\[
\boxed{
\left(\frac ck\right)
=
\left(\frac{-1}k\right).
}
\]

The certificate congruence implies

\[
k\equiv3\pmod4,
\]

so

\[
\left(\frac{-1}k\right)=-1.
\]

Therefore

\[
\boxed{
\left(\frac ck\right)=-1.
}
\]

Thus the cofactor

\[
c=\frac{p+k}{4ab}
\]

is forced into the negative quadratic-character class modulo the certificate divisor.

---

## 4. Reciprocity relation with the target prime

Modulo `k`,

\[
p\equiv4abc.
\]

The factors `4` and `b^2` are squares modulo `k`, so

\[
\left(\frac pk\right)
=
\left(\frac ak\right)
\left(\frac ck\right).
\]

Using the previous theorem,

\[
\boxed{
\left(\frac pk\right)
=-
\left(\frac ak\right).
}
\]

Because

\[
p\equiv1\pmod4,
\]

quadratic reciprocity for the Jacobi symbol has no sign change:

\[
\left(\frac pk\right)
=
\left(\frac kp\right).
\]

Hence the exact target relation is

\[
\boxed{
\left(\frac kp\right)
=-
\left(\frac ak\right).
}
\]

---

## 5. A-axis corollary

On the exact one-parameter axis

\[
a=1,
\]

one has

\[
\left(\frac ak\right)=1.
\]

Therefore every A-axis certificate satisfies

\[
\boxed{
\left(\frac kp\right)=-1.
}
\]

So the divisor `k` is necessarily a quadratic nonresidue modulo the target prime `p`.

This is a structural explanation for the scarcity of small A-axis certificate divisors on the Mordell-hard prime classes.

---

## 6. Interaction with the Mordell-hard classes

The six classical hard classes modulo 840 are quadratic-residue classes at the small primes that generate the first congruence shields.

For example, a hard prime satisfies

\[
p\equiv1\pmod{12},
\]

so

\[
\left(\frac3p\right)=1.
\]

Likewise the hard modulo-7 restriction places `p` in a quadratic-residue class modulo 7, and because `p≡1 mod4`, reciprocity gives

\[
\left(\frac7p\right)=1.
\]

Therefore neither

\[
k=3
\]

nor

\[
k=7
\]

can serve as an A-axis certificate divisor for a Mordell-hard prime.

The first useful certificate divisors must leave this inherited positive-character shield.

---

## 7. Character signature for general plane points

The relation

\[
\left(\frac kp\right)
=-
\left(\frac ak\right)
\]

splits the simplified plane into two character modes:

### Mode N

If

\[
\left(\frac ak\right)=1,
\]

then

\[
\left(\frac kp\right)=-1.
\]

### Mode R

If

\[
\left(\frac ak\right)=-1,
\]

then

\[
\left(\frac kp\right)=1.
\]

Thus the extra parameter `a` permits the full `fab` plane to cross a target-prime character shield that the `a=1` axis cannot cross.

This gives a conceptual explanation for primes that survive both one-parameter axes but are caught at interior points such as

\[
(a,b)=(3,2).
\]

---

## 8. Example p = 351289

The interior certificate is

\[
(a,b,k)=(3,2,23).
\]

Here

\[
c
=
\frac{351289+23}{4\cdot3\cdot2}
=14638.
\]

The hidden congruence is

\[
1+4b^2c
=1+16(14638)
\equiv0\pmod{23}.
\]

Since

\[
23\equiv3\pmod4,
\]

we have

\[
\left(\frac{14638}{23}\right)=-1.
\]

The target reciprocity relation is

\[
\left(\frac{23}{351289}\right)
=-
\left(\frac3{23}\right).
\]

This is the exact character switch supplied by the interior parameter `a=3`.

---

## 9. Relation to the FCF character program

The Type A/B research already developed:

- scalar Jacobi shields;
- full local quadratic signatures;
- character-level redundancy and ancestry;
- higher-order multiplicative quotient structure.

The `fab` identity now has an explicit compatible character layer:

\[
\boxed{
\text{divisor certificate}
\Longrightarrow
\text{negative local cofactor character}
\Longrightarrow
\text{target reciprocity relation}.
}
\]

This makes it possible to compare Type A/B survivors and `fab` survivors inside one common character-signature language rather than treating them as unrelated parametrizations.

---

## 10. Active proof question

A hypothetical all-prime survivor would have to evade not only every divisor congruence but also the character modes induced by the available `(a,b,k)` triples.

The next structural target is:

\[
\boxed{
\text{show that the hard positive-character shield forces some interior parameter }a
\text{ to flip the local sign and create a certificate.}
}
\]

This is now the cleanest bridge between the old Type A/B obstruction theory and the complete divisor parametrization.
