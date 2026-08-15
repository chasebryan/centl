# Complete classification of the depth-1 Type A/B shadow component

**Status:** proved exact classification  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem classifies global direct shadowing by the first Type A/B layer. It does not classify all structural gaps and does not prove universal López Type A/B coverage or the Erdős-Straus conjecture.

Read with [COSET-SOURCE-SEMIGROUP-SHADOW.md](COSET-SOURCE-SEMIGROUP-SHADOW.md) and [STRUCTURAL-GAP-ASYMPTOTIC.md](STRUCTURAL-GAP-ASYMPTOTIC.md).

## 1. First layer

At depth

\[
j=1,
\]

we have

\[
m_1=3
\]

and

\[
T_1
=
\{-1,-4\}\pmod3
=
\{2\}.
\]

Call a later layer `k>1` **globally shadowed by depth 1** when every integer satisfying a Type A/B trap congruence at depth `k` is automatically in the depth-1 trap modulo `3`.

## 2. Classification theorem

### Theorem

For every `k>1`, the following are equivalent:

1. the complete Type A/B layer at depth `k` is globally directly shadowed by depth `1`;
2. every prime divisor `p|k` satisfies
   \[
   p\equiv1\pmod3;
   \]
3. every positive divisor `e|k` satisfies
   \[
   e\equiv1\pmod3.
   \]

Thus the depth-1 shadow component is exactly the multiplicative semigroup

\[
\boxed{
\mathcal S_3
=
\{k>1:p\mid k\Rightarrow p\equiv1\pmod3\}.
}
\]

### Proof

`(2) iff (3)` is immediate from unique factorization.

### (2) implies (1)

If every prime divisor of `k` is `1 mod 3`, then every divisor `e|k` is `1 mod 3`, and in particular

\[
k\equiv1\pmod3.
\]

Hence

\[
3\mid4k-1=m_k.
\]

For every target trap residue,

\[
-e\equiv-1\equiv2\pmod3
\]

and, because `4=1 mod 3`,

\[
-4e\equiv-e\equiv2\pmod3.
\]

Therefore every target trap is contained in

\[
T_1=\{2\}\pmod3.
\]

So depth `1` globally shadows depth `k`.

### (1) implies (2)

Assume depth `1` globally shadows depth `k`.

First, `3` must divide `m_k=4k-1`. If not, then

\[
\gcd(m_k,3)=1.
\]

Take the target trap residue

\[
x\equiv-1\pmod{m_k}.
\]

By CRT this progression contains integers in every residue class modulo `3`, including residues not equal to `2`. Such integers hit layer `k` but avoid `T_1`, contradicting global shadowing.

Therefore

\[
3\mid4k-1,
\]

so

\[
k\equiv1\pmod3.
\]

Now let `p|k` be any prime divisor. Since `p` itself is a divisor of `k`, the target trap includes

\[
x\equiv-p\pmod{m_k}.
\]

Because `3|m_k`, every integer in this progression has residue

\[
x\equiv-p\pmod3.
\]

Global shadowing by depth `1` requires this residue to equal the unique trap residue `2 mod 3`. Thus

\[
-p\equiv2\pmod3,
\]

and hence

\[
p\equiv1\pmod3.
\]

This holds for every prime divisor `p|k`. QED.

## 3. Spectrum consequence

For every

\[
k\in\mathcal S_3,
\]

we have

\[
\boxed{C_{AB}(n)\ne k}
\]

for every integer `n` for which `C_AB(n)` is defined.

So `S_3` is not merely an explicit subset of the gap set. It is exactly the portion of the global structural-gap set explained by the first Type A/B layer alone.

## 4. Counting consequence

The Selberg-Delange analysis in [STRUCTURAL-GAP-ASYMPTOTIC.md](STRUCTURAL-GAP-ASYMPTOTIC.md) gives

\[
|\mathcal S_3\cap[1,X]|
\sim
C_3\frac{X}{\sqrt{\log X}}
\]

with explicit `C_3>0`.

Therefore the **single first layer** already explains

\[
\boxed{
(C_3+o(1))\frac{X}{\sqrt{\log X}}
}
\]

global impossible depths up to `X`.

This gives the current strongest proved lower bound for the full structural-gap counting function.

## 5. Why this matters

The first trap layer is extremely small:

\[
T_1=\{2\}\pmod3.
\]

Yet its exact shadow basin in depth space has size of order

\[
X/\sqrt{\log X}.
\]

This illustrates the central geometry of the project: tiny early congruence layers can cast very large multiplicative shadows over the later minimal-depth spectrum.

## 6. Next classification targets

The natural analogues are:

1. classify global direct shadowing by depth `2`, where
   \[
   m_2=7,
   \qquad
   T_2=-\langle2\rangle=\{3,5,6\};
   \]
2. classify shadowing by depth `4`, where
   \[
   m_4=15
   \]
   and the source is again coset-saturated;
3. determine whether the union of the exact depth-1, depth-2, and depth-4 shadow components has a sharper asymptotic than any one component;
4. extend exact source-basin classifications to every coset-saturated power-of-two source.
