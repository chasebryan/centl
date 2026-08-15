# Prime-depth backbone projection

**Status:** proved corollary of the prime-depth dichotomy  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this classifies the direct-shadow source available for a prime depth with composite target modulus. It does not prove universal López Type A/B coverage or the Erdős-Straus conjecture.

Read with [PRIME-DEPTH-DICHOTOMY.md](PRIME-DEPTH-DICHOTOMY.md) and [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md).

## Theorem

Let `k` be a prime depth and put

\[
m_k=4k-1.
\]

If `m_k` is composite, then there exists a prime

\[
q\mid m_k,
\qquad
q\equiv3\pmod4,
\qquad
q<m_k.
\]

Set

\[
j=(q+1)/4.
\]

Then

\[
m_j=q
\]

is itself prime, so `j` is a prime-modulus backbone depth, and

\[
\boxed{T_k\bmod q\subseteq T_j.}
\]

Thus every structurally impossible prime depth is directly shadowed by a prime-modulus backbone layer.

### Proof

Because

\[
m_k\equiv3\pmod4,
\]

its prime factorization contains at least one prime factor `q=3 mod 4`. Since `m_k` is composite, choose such a factor with `q<m_k`.

Write

\[
m_k=Aq.
\]

Because both `m_k` and `q` are `3 mod 4`,

\[
A\equiv1\pmod4.
\]

Write

\[
A=4s+1,
\qquad
q=4j-1.
\]

Then

\[
4k-1=(4s+1)(4j-1),
\]

so

\[
k=s(4j-1)+j
\]

and

\[
4k=(4s+1)(4j-1)+1.
\]

Therefore

\[
k\equiv j\pmod q,
\qquad
4k\equiv1\pmod q.
\]

Since `k` is prime,

\[
T_k=\{-1,-4,-k,-4k\}.
\]

Reducing modulo `q=m_j` gives

\[
\{-1,-4,-j,-1\}\subseteq T_j,
\]

because `1|j` and `j|j`.

QED.

## Graph interpretation

On the subsequence of prime depth values, every node has one of two forms:

\[
\boxed{
\text{prime depth }k
\to
\begin{cases}
\text{backbone node}, & 4k-1\text{ prime},\\
\text{direct edge to a backbone node}, & 4k-1\text{ composite}.
\end{cases}}
\]

So the prime-depth part of the shadow graph has depth at most one above the prime-modulus backbone.

This is substantially stronger than merely knowing that composite `4k-1` produces some earlier shadow source.

## Multiple backbone parents

Every distinct prime divisor

\[
q\equiv3\pmod4
\]

of `4k-1` supplies a backbone shadow parent

\[
j=(q+1)/4.
\]

Thus the set of prime-modulus parents of an impossible prime depth is read directly from the `3 mod 4` prime factors of its target modulus.

Examples:

```text
k=19:  4k-1=75=3*5^2
       q=3  -> j=1

k=29:  4k-1=115=5*23
       q=23 -> j=6

k=79:  4k-1=315=3^2*5*7
       q=3  -> j=1
       q=7  -> j=2
```

## Consequence

The genuinely difficult part of the depth spectrum is therefore even more concentrated on **composite depth values**.

Prime depth values do not create long new shadow ancestry chains. They are either independent backbone layers themselves or are removed immediately by a backbone parent.
