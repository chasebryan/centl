# Prime-power Type A/B trap dichotomy

**Status:** proved structural theorem  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem concerns the internal structure of Type A/B trap layers. It does not prove universal Type A/B coverage or the Erdős-Straus conjecture. Literature priority remains under review.

Read with [MERSENNE-SHADOW-LATTICE.md](MERSENNE-SHADOW-LATTICE.md) and [MULTIPLICATIVE-TRAP-COSET.md](MULTIPLICATIVE-TRAP-COSET.md).

## 1. General prime-power layer

Let

\[
k=p^a
\]

with `p` prime and `a>=1`, and put

\[
m=4p^a-1.
\]

The divisor-generated subgroup is

\[
H=\langle p\rangle\le(\mathbb Z/m\mathbb Z)^\times.
\]

Since

\[
4p^a\equiv1\pmod m,
\]

we have

\[
4\equiv p^{-a}\pmod m.
\]

The divisors of `p^a` are `p^i`, `0<=i<=a`. Therefore the two trap families become

\[
-p^i
\]

and

\[
-4p^i\equiv-p^{i-a}.
\]

Hence

\[
\boxed{
T_{p^a}
=\{-p^j:-a\le j\le a\}
\subseteq-\langle p\rangle.
}
\]

This is an exact exponent-window description.

## 2. Odd prime case

Assume `p` is odd.

Because `4` does not divide `p^a`, the exact trap-cardinality theorem gives

\[
\boxed{|T_{p^a}|=2a+1.}
\]

Let

\[
r=\operatorname{ord}_{m}(p).
\]

The exponent-window description shows

\[
2a+1\le r.
\]

### Theorem

For every odd prime `p` and `a>=1`,

\[
\boxed{
\operatorname{ord}_{4p^a-1}(p)>2a+1.
}
\]

Consequently

\[
\boxed{
T_{p^a}\subsetneq-\langle p\rangle.
}
\]

### Proof

Suppose for contradiction that

\[
r=2a+1.
\]

Then

\[
p^{2a+1}\equiv1\pmod m.
\]

Write `n=p^a`. Since

\[
4n\equiv1\pmod m,
\]

we have

\[
16n^2\equiv1\pmod m.
\]

But

\[
p^{2a+1}=pn^2\equiv1\pmod m.
\]

Multiplying the latter congruence by `16` gives

\[
p\equiv16\pmod m.
\]

For all odd prime-power cases except `(p,a)=(3,1)`,

\[
m=4p^a-1>|p-16|,
\]

so this congruence would force `p=16`, impossible for a prime. The exceptional numerical case has `m=11` and `3` is not congruent to `16 mod 11` either.

Thus equality cannot occur. Since `r>=2a+1`, we obtain

\[
r>2a+1.
\]

Therefore the `2a+1` trap residues cannot exhaust the cyclic subgroup. QED.

## 3. Binary case

For `p=2`, the situation changes because

\[
4=2^2
\]

is itself a power of the subgroup generator.

The Mersenne theorem gives

\[
\boxed{
\operatorname{ord}_{2^{a+2}-1}(2)=a+2
}
\]

and

\[
\boxed{
T_{2^a}=-\langle2\rangle.
}
\]

Thus binary prime powers saturate the divisor-generated multiplicative coset exactly, whereas odd prime powers never do.

## 4. Dichotomy

We therefore have the clean prime-power split

\[
\boxed{
\begin{array}{ll}
p=2 &: T_{2^a}=-H_{2^a};\\[1mm]
p\text{ odd} &: T_{p^a}\subsetneq-H_{p^a}.
\end{array}
}
\]

The infinite Mersenne shadow lattice is therefore a genuinely binary phenomenon inside the prime-power family, not a generic consequence of prime-power divisor structure.

## 5. Consequences for the theorem program

1. exact multiplicative-coset saturation has a distinguished infinite binary family;
2. odd prime-power layers retain an intrinsic **divisor-sparsity gap** even after the full multiplicative quotient has been used;
3. attempts to generalize the Mersenne shadow lattice to odd prime powers must exploit something other than full coset equality;
4. the exact density factor `|T_k|/|H_k|` from [TRAP-QUOTIENT-FACTORIZATION.md](TRAP-QUOTIENT-FACTORIZATION.md) is therefore essential, not merely a technical remainder.
