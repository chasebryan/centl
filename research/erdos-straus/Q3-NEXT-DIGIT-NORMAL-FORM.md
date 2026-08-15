# q=3 Next-Digit Normal Form

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Depends on:** `REDUCED-PARAMETER-DOMAIN.md`, `Q3-FIBER-INJECTIVITY.md`  
**Claim boundary:** normalizes every q=3 pullback on a fixed candidate into one common next 3-adic digit coordinate. It does not prove that three primitive base rows cannot occupy all three digits, universal DSC-P, López-all-primes, or Erdős-Straus.

---

## 1. Setup

Fix a candidate progression

\[
x(s)=r+Ls.
\]

Let `j` be an earlier layer with

\[
m_j=4j-1
\]

and

\[
q_j=\frac{m_j}{\gcd(L,m_j)}=3.
\]

Write

\[
\boxed{n_j=m_j/3=\gcd(L,m_j).}
\]

Let

\[
b=v_3(n_j).
\]

Because `n_j|L` but `3n_j` does not divide `L`,

\[
\boxed{v_3(L)=b.}
\]

Thus every q=3 layer active on the same candidate has the **same** value of `b`.

Write

\[
n_j=3^b\nu_j,
\qquad
L=3^b\Lambda,
\]

with

\[
3\nmid\nu_j\Lambda.
\]

Since `n_j|L`, we also have `\nu_j|\Lambda`.

---

## 2. Theorem — layer modulus cancels

Suppose a trap `u in T_j` produces a nonempty pullback class

\[
a\in R_j\subseteq\mathbb Z/3\mathbb Z.
\]

Then

\[
\boxed{
a\equiv
\frac{u-r}{3^b}\,\Lambda^{-1}
\pmod3.
}
\]

Equivalently,

\[
\boxed{
a\equiv
\left(\frac{u-r}{3^b}\right)
\left(\frac{L}{3^b}\right)^{-1}
\pmod3.
}
\]

### Proof

Since `q_j=3`, the hit relation is

\[
r+La\equiv u\pmod{3n_j}.
\]

Reducing modulo `n_j` gives

\[
u\equiv r\pmod{n_j},
\]

so

\[
D:=\frac{u-r}{n_j}
\]

is an integer, understood modulo `3`.

Divide the hit relation by `n_j`:

\[
\frac{L}{n_j}a\equiv D\pmod3.
\]

Because `q_j=3`, `L/n_j` is a unit modulo `3`, hence

\[
a\equiv D\left(\frac{L}{n_j}\right)^{-1}\pmod3.
\]

Now

\[
D
=\frac{u-r}{3^b\nu_j}
\equiv
\frac{u-r}{3^b}\,\nu_j^{-1}
\pmod3,
\]

while

\[
\left(\frac{L}{n_j}\right)^{-1}
=
\left(\frac{\Lambda}{\nu_j}\right)^{-1}
\equiv
\nu_j\Lambda^{-1}
\pmod3.
\]

The layer-specific factor `\nu_j` cancels:

\[
a\equiv
\frac{u-r}{3^b}\,\Lambda^{-1}
\pmod3.
\]

QED.

---

## 3. Interpretation — every row paints one next 3-adic digit

The condition

\[
u\equiv r\pmod{n_j}
\]

already implies

\[
u\equiv r\pmod{3^b}.
\]

So a q=3 trap witness lies above the fixed `3^b`-adic prefix of the candidate and chooses one of the three lifts modulo `3^{b+1}`.

The theorem says that the parameter class `a mod 3` is exactly that next digit, followed by one fixed multiplication by the common unit

\[
\Lambda^{-1}=(L/3^b)^{-1}\pmod3.
\]

Therefore **all q=3 layers on the candidate use the same coordinate system**. No layer-specific rescaling remains.

---

## 4. Cover criterion in digit form

For a q=3 trap witness `u`, define its normalized next digit

\[
\boxed{
\delta(u):=
\frac{u-r}{3^b}\pmod3.
}
\]

Multiplication by `\Lambda^{-1}` is a permutation of `F_3`, so

\[
\bigcup_jR_j=\mathbb Z/3\mathbb Z
\]

if and only if the realized trap witnesses occupy all three normalized next digits:

\[
\boxed{
\{\delta(u):u\text{ is a realized q=3 trap witness}\}
=\mathbb F_3.
}
\]

Combined with `Q3-FIBER-INJECTIVITY.md`, each individual q=3 layer contributes at most one such digit.

---

## 5. Directly novel form

Combine the q=3 hierarchy:

- strong descendants are absent when nonempty on a directly novel candidate;
- weak descendants are redundant;
- every used trap must be pointwise primitive;
- every surviving layer contributes at most one class;
- every surviving class is one common next 3-adic digit.

Thus a genuine directly novel q=3 obstruction is precisely:

\[
\boxed{
\text{at least three pointwise-primitive base trap witnesses}
\text{ occupying all three lifts above one }3^b\text{-prefix}.
}
\]

This is the exact residual local theorem target.

---

## 6. Special case b=1

When `v_3(L)=1`, every hard candidate satisfies `r=1 mod 3`, and the three possible trap residues modulo `9` are

\[
1,4,7.
\]

A corrected q=3 cover is therefore equivalent to primitive realized traps occupying all three residues

\[
\boxed{1,4,7\pmod9}
\]

(up to the common affine permutation determined by `r` and `L/3`).

This gives a concrete small-modulus target for the base-triple analysis.
