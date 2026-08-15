# Prime Reduction for Erdős-Straus

**Status:** elementary proved reduction  
**Date:** 2026-08-15  
**Claim boundary:** this does not prove the conjecture for primes. It removes any separate composite endgame once all primes are solved.

---

## Theorem — divisor scaling

Let `d|n`. If

\[
\frac4d=\frac1x+\frac1y+\frac1z
\]

for positive integers `x,y,z`, then

\[
\frac4n
=
\frac1{x(n/d)}
+
\frac1{y(n/d)}
+
\frac1{z(n/d)}.
\]

### Proof

Put `c=n/d`. Dividing the identity for `d` by `c` gives

\[
\frac4{dc}
=
\frac1{cx}+
\frac1{cy}+
\frac1{cz}.
\]

Since `dc=n`, this is the desired decomposition. QED.

---

## Corollary — primes suffice

Every integer `n>=2` has a prime divisor `p`.

Therefore, if the Erdős-Straus equation is solvable for every prime `p`, then it is solvable for every integer `n>=2` by applying the theorem with `d=p`.

Hence

\[
\boxed{
\text{Erdős-Straus for all primes}
\Longrightarrow
\text{Erdős-Straus for all integers }n\ge2.
}
\]

The converse is trivial, so the full conjecture is equivalent to its restriction to primes.

---

## Consequence for the current Type A/B program

If the López Type A/B coverage statement is proved for **every prime**, then each prime has a valid Type A or Type B unit-fraction decomposition and therefore satisfies Erdős-Straus. Prime reduction then immediately extends the result to all composite integers.

So the endgame is not

\[
\text{López-all-primes} + \text{a second composite theorem}.
\]

It is

\[
\boxed{
\text{López-all-primes}
\Longrightarrow
\text{Erdős-Straus outright}.
}
\]

`COMPOSITE-CORE.md` remains meaningful as a Type-A/B **modulus/depth** structure document; it should not be interpreted as a separate requirement to solve composite values of `n` after all primes are covered.
