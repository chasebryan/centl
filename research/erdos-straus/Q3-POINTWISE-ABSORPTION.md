# q=3 Pointwise Absorption

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Depends on:** `Q3-ABSORPTION.md`, `Q3-WEAK-REDUNDANCY.md`  
**Claim boundary:** sharpens q=3 direct-shadow detection from whole-layer ancestry to the actual trap point used by a candidate. Does not by itself prove that pointwise-primitive base traps cannot cover the corrected parameter domain, universal DSC-P, López-all-primes, or Erdős-Straus.

---

## Setup

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

Put

\[
\boxed{n_j=m_j/3.}
\]

Then

\[
\boxed{n_j\mid L.}
\]

A class `a mod 3` belongs to `R_j` precisely when there is a trap residue `u in T_j` such that

\[
r+La\equiv u\pmod{m_j}.
\]

In particular

\[
\boxed{u\equiv r\pmod{n_j}.}
\]

---

## Theorem (pointwise q=3 absorption)

Assume `a in R_j`, witnessed by `u in T_j`.

If there is any earlier layer `i<j` satisfying

\[
\boxed{m_i\mid n_j}
\]

and

\[
\boxed{u\bmod m_i\in T_i,}
\]

then the entire candidate progression is directly shadowed by layer `i`.

### Proof

Since

\[
m_i\mid n_j\mid L,
\]

the progression is frozen modulo `m_i`:

\[
x(s)\equiv r\pmod{m_i}
\qquad\text{for all }s.
\]

The witness relation gives

\[
u\equiv r\pmod{n_j},
\]

hence also

\[
u\equiv r\pmod{m_i}.
\]

By hypothesis `u mod m_i in T_i`. Therefore

\[
r\bmod m_i\in T_i.
\]

Since every point of the progression has that same residue modulo `m_i`, every point lies in the earlier Type A/B layer `i`. Thus the candidate is directly shadowed. QED.

---

## Definition — pointwise-primitive q=3 trap

For a q=3 layer `j`, call a trap residue `u in T_j` **pointwise primitive** if

\[
\boxed{
\forall i<j\text{ with }m_i\mid m_j/3,
\quad
u\bmod m_i\notin T_i.
}
\]

This is a property of the actual trap point, not of the whole layer.

### Corollary

On a directly novel candidate, every trap witness responsible for every nonempty q=3 pullback must be pointwise primitive.

Equivalently:

\[
\boxed{
\text{non-primitive q=3 trap witness}
\Longrightarrow
\text{direct shadow}.
}
\]

---

## Relation to strong absorption

Strong absorption assumes one ancestor `i` satisfies

\[
T_j\bmod m_i\subseteq T_i.
\]

That makes **every** trap of `j` non-primitive and therefore kills the entire layer whenever `R_j` is nonempty.

Pointwise absorption is strictly finer: even a base layer with no whole-set reducing ancestor can be dead for a particular candidate if the specific trap point selected by that candidate reduces into an earlier frozen trap.

Thus the true residual q=3 threat is smaller than the base-layer population:

\[
\boxed{
\text{base layers}
\supseteq
\text{base layers with primitive traps}
\supseteq
\text{primitive traps actually alignable on one candidate}.
}
\]

---

## Corrected q=3 cover target

Because `3|840|L`, the exact Dirichlet parameter domain at q=3 is all of

\[
\mathbb Z/3\mathbb Z.
\]

After strong absorption, weak redundancy, and pointwise absorption, a directly novel q=3 obstruction would require pointwise-primitive trap witnesses whose pullbacks jointly cover

\[
\boxed{\{0,1,2\}.}
\]

This is the next exact search/theorem target.
