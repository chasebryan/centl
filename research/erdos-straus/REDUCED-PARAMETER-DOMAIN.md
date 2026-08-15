# Exact reduced-parameter domain

**Status:** proved elementary theorem  
**Date:** 2026-08-15  
**Claim boundary:** this corrects the local parameter domain used in some C1/C2/CN proof-mining notes. It does not prove universal Type A/B coverage or Erdős-Straus.

## Setup

For an admissible target candidate write

\[
x(s)=r+Ls,
\qquad
L=\operatorname{lcm}(840,4k-1).
\]

Let

\[
Q=\operatorname{lcm}\{q_j:R_j\ne\varnothing\}.
\]

The exact Dirichlet condition needed for a prime progression is

\[
\boxed{\gcd(r+Ls,LQ)=1.}
\]

The parameter itself need not be a unit modulo `Q`.

Every admissible CRT base satisfies

\[
\boxed{\gcd(r,L)=1.}
\]

because the hard residue is coprime to `840` and every Type A/B target trap is a unit modulo its target modulus.

## Theorem

Assume `gcd(r,L)=1`. For every prime `p|Q`:

- if `p|L`, then
  \[
  r+Ls\equiv r\not\equiv0\pmod p
  \]
  for every `s`;
- if `p\nmid L`, then `L` is invertible modulo `p`, and
  \[
  p\mid r+Ls
  \iff
  s\equiv-rL^{-1}\pmod p.
  \]

Therefore

\[
\boxed{
\gcd(r+Ls,LQ)=1
\iff
s\not\equiv-rL^{-1}\pmod p
\text{ for every }p\mid Q,\ p\nmid L.
}
\]

Higher powers of `p` in `Q` do not change the gcd condition.

Define

\[
\mathcal D_{r,L}(Q)
=\{s\bmod Q:\gcd(r+Ls,LQ)=1\}.
\]

Then

\[
\boxed{
|\mathcal D_{r,L}(Q)|
=Q\prod_{\substack{p\mid Q\\p\nmid L}}
\left(1-\frac1p\right).
}
\]

## Important correction

The auxiliary set

\[
(\mathbb Z/Q\mathbb Z)^*
\]

is generally not the exact reduced parameter domain.

In particular, for the hard-class program

\[
3\cdot5\cdot7\mid840\mid L.
\]

Hence any local coordinate supported only on `3,5,7` carries the **full residue-ring parameter domain** as far as Dirichlet reducedness is concerned.

For `q=3` specifically,

\[
\boxed{\mathcal D_{r,L}(3)=\mathbb Z/3\mathbb Z.}
\]

Thus two singleton rows forbidding `{1}` and `{2}` do not form a reduced obstruction: `s=0 mod3` remains prime-compatible.

Combined with `Q3-SINGLETON-PULLBACK.md`, a genuine q=3 local cover requires three distinct singleton rows covering

\[
\boxed{\{0,1,2\}.}
\]

The constructive core in `DSC-COUNTEREXAMPLE.md` shows that such a three-row cover can in fact occur.

## Research rule

Future local escape and covering arguments must distinguish:

1. primes already dividing `L`, where parameter residues are unrestricted by reducedness;
2. primes outside `L`, where exactly one affine class modulo `p` is excluded.

Do not replace this exact affine condition by `gcd(s,Q)=1` unless an equivalence has been proved for the stated special case.
