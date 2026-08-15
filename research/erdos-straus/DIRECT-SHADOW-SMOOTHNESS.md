# Direct-shadow smoothness theorem

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Claim boundary:** this theorem restricts which earlier moduli can directly shadow a fixed candidate progression. It does not imply that collective/union shadows collapse to direct shadows, and it does not prove Erdős-Straus.

## Setup

Fix a candidate progression

\[
x(s)=r+Ls.
\]

For an earlier Type A/B layer `i`, write

\[
m=4i-1,
\qquad
g=\gcd(L,m),
\qquad
q=m/g.
\]

The attained fibre modulo `m` is

\[
\{r+Ls\pmod m:s\in\mathbb Z/q\mathbb Z\}.
\]

Every Type A/B trap residue is a unit modulo `m`, because each trap is `-e` or `-4e` with `e|i` and

\[
\gcd(i,4i-1)=1.
\]

## Theorem

If layer `i` directly shadows the candidate, then every prime divisor of `m` already divides `L`:

\[
\boxed{\operatorname{rad}(m)\mid\operatorname{rad}(L).}
\]

Equivalently, every direct-shadow modulus is smooth over the prime support of `L`.

### Proof

Suppose a prime `p|m` does not divide `L`.

Then `p` divides the quotient

\[
q=m/\gcd(L,m),
\]

and `L` is invertible modulo `p`.

As `s` runs over a complete parameter period modulo `q`, it runs over every class modulo `p`. Therefore there is an `s` satisfying

\[
r+Ls\equiv0\pmod p.
\]

That attained fibre point is not a unit modulo `m`, while every Type A/B trap is a unit modulo `m`. Hence that fibre point is not in `T_i`, so the layer cannot directly shadow the whole candidate.

Contradiction. QED.

## Consequence for exact direct-shadow falsification

For a concrete target candidate with target modulus `M=4k-1`, every earlier direct-shadow modulus satisfies

\[
m<M,
\qquad
m\equiv3\pmod4,
\qquad
\operatorname{rad}(m)\mid\operatorname{rad}(L).
\]

Thus an exact direct-shadow check need not scan all `i<k`. It is enough to enumerate the finitely many `L`-smooth odd moduli below `M` that are `3 mod 4`, and test their complete attained fibres.

This reduction is used by `verify_dsc_counterexample.py`.
