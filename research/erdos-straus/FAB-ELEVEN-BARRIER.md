# The `a = 11` Character Barrier

**Status:** proved theorem inside the coprime opposite-parity `fab` plane  
**Date:** 2026-08-15  
**Depends on:** `FAB-COPRIME-PARITY-PLANE.md`, `FAB-CHARACTER-BRIDGE.md`  
**Claim boundary:** explains the first possible character-flipping numerator parameter on Mordell-hard primes. It does not prove that `a<=11` gives universal coverage.

---

## 1. Mordell-hard character data

The six classical hard prime classes modulo

\[
840=2^3\cdot3\cdot5\cdot7
\]

satisfy

\[
\boxed{p\equiv1\pmod8}
\]

and are quadratic residues modulo each of

\[
3,5,7.
\]

Equivalently, for a Mordell-hard prime `p`,

\[
\boxed{
\left(\frac3p\right)
=
\left(\frac5p\right)
=
\left(\frac7p\right)
=1.
}
\]

Because `p≡1 mod4`, reciprocity also gives

\[
\left(\frac p3\right)
=
\left(\frac p5\right)
=
\left(\frac p7\right)
=1.
\]

---

## 2. Certificate congruence

Take a coprime opposite-parity `fab` certificate `(a,b,k)` for such a prime.

`FAB-COPRIME-PARITY-PLANE.md` gives

\[
\boxed{k\equiv-p\pmod{4ab}.}
\]

In particular

\[
\boxed{k\equiv-p\pmod{4a}.}
\]

Also

\[
k\equiv3\pmod4.
\]

---

## 3. Odd small-prime factors of a contribute positive character

Let

\[
\ell\in\{3,5,7\}
\]

be a prime divisor of `a`.

From the certificate congruence,

\[
k\equiv-p\pmod\ell.
\]

Quadratic reciprocity gives

\[
\left(\frac\ell k\right)
=
(-1)^{\frac{\ell-1}{2}\frac{k-1}{2}}
\left(\frac k\ell\right).
\]

Since

\[
k\equiv3\pmod4,
\]

`(k-1)/2` is odd, so the sign is

\[
\left(\frac{-1}\ell\right).
\]

Using `k≡-p mod ell`,

\[
\left(\frac k\ell\right)
=
\left(\frac{-p}\ell\right)
=
\left(\frac{-1}\ell\right)
\left(\frac p\ell\right).
\]

The two minus-one factors cancel:

\[
\boxed{
\left(\frac\ell k\right)
=
\left(\frac p\ell\right)
=1.
}
\]

Therefore every factor `3`, `5`, or `7` occurring in `a`, with any exponent, contributes positive Jacobi character modulo `k`.

---

## 4. The factor 2 also contributes positive character

If `2|a`, then

\[
8\mid4a.
\]

Hence

\[
k\equiv-p\pmod8.
\]

Because

\[
p\equiv1\pmod8,
\]

we get

\[
\boxed{k\equiv7\pmod8.}
\]

The supplementary law gives

\[
\boxed{
\left(\frac2k\right)=1.
}
\]

Thus every power of 2 in `a` also contributes positive character.

---

## 5. Theorem — 7-smooth a cannot flip the target character

Suppose every prime divisor of `a` belongs to

\[
\{2,3,5,7\}.
\]

Then the preceding sections imply

\[
\boxed{
\left(\frac ak\right)=1.
}
\]

By `FAB-CHARACTER-BRIDGE.md`, every coprime opposite-parity certificate satisfies

\[
\left(\frac kp\right)
=-
\left(\frac ak\right).
\]

Therefore

\[
\boxed{
\left(\frac kp\right)=-1.
}
\]

So every certificate whose parameter `a` is 7-smooth lies in the **negative-target-character mode**.

---

## 6. Corollary — first possible Mode R parameter is 11

Mode R is the character-flipping regime

\[
\left(\frac kp\right)=+1,
\]

which requires

\[
\left(\frac ak\right)=-1.
\]

The theorem shows this is impossible when `a` is supported only on

\[
2,3,5,7.
\]

The smallest positive integer containing a prime outside that support is

\[
\boxed{11}.
\]

Hence:

\[
\boxed{
\text{For a Mordell-hard prime, }a=11\text{ is the first possible numerator parameter capable of Mode R.}
}
\]

This is a structural barrier, not a finite-search artifact.

---

## 7. Finite diagnostic that motivated the theorem

In an exploratory exact scan of Mordell-hard primes below `500000`, using coprime opposite-parity parameters `1<=a,b<=11`, every observed certificate with

\[
\left(\frac ak\right)=-1
\]

had

\[
\boxed{a=11.}
\]

The theorem explains that observation completely: no `a<11` can contain a prime outside the classical hard support.

This finite diagnostic is motivation only; the theorem does not depend on it.

---

## 8. Example: p = 2521

The prime

\[
p=2521
\]

has a Mode R certificate

\[
\boxed{(a,b,k)=(11,2,31).}
\]

Indeed

\[
11+2p=5053=31\cdot163,
\]

and

\[
31\equiv-2521\pmod{88}.
\]

Moreover

\[
\left(\frac{11}{31}\right)=-1,
\]

so

\[
\boxed{
\left(\frac{31}{2521}\right)=+1.
}
\]

This certificate crosses the inherited hard-prime positive-character shield precisely through the new prime `11` carried by `a`.

---

## 9. Interpretation of the empirical bound 11

The 2026 divisor-parametrization paper reports that all tested primes

\[
p\equiv1\pmod4,
\qquad p<10^{14},
\]

are detected somewhere in the full window

\[
1\le a,b\le11.
\]

That finite computation is not a universal proof.

However, the theorem here gives a concrete structural reason that the endpoint `11` is mathematically distinguished:

\[
\boxed{
11\text{ is the first prime parameter outside the }2,3,5,7\text{ Mordell character shield.}
}
\]

So the success of the window through 11 has a plausible character-theoretic mechanism rather than being merely a convenient cutoff.

---

## 10. New proof target

A hypothetical hard prime can be attacked in two stages:

1. **Mode N:** certificates with 7-smooth `a`, forcing `k` to be a quadratic nonresidue modulo `p`;
2. **Mode R:** certificates whose `a` contains a prime outside the hard support, beginning with `11`, allowing `k` to be a quadratic residue modulo `p`.

The immediate question is whether the two modes together force a certificate for every hard prime, with `11` as the first necessary character-extension coordinate.
