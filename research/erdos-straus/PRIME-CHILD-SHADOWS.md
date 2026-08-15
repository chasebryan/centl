# Prime-child ancestry shadows

**Status:** proved theorem family inside the Type A/B minimal-depth program  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. It proves an infinite family of exact direct-shadow edges along every modulus-ancestry quotient and completely classifies the unrestricted quotient-5 case.

Read with:

- [THEORY.md](THEORY.md)
- [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md)
- [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md)
- [RECIPROCITY-TOWER-SHADOWS.md](RECIPROCITY-TOWER-SHADOWS.md)

## 1. Modulus ancestry

Let `j<K` and suppose

\[
4j-1\mid4K-1.
\]

Write

\[
\boxed{
4K-1=q(4j-1),
}
\]

where necessarily

\[
q\equiv1\pmod4.
\]

Write

\[
q=4s+1.
\]

Then

\[
\boxed{
K=qj-s.
}
\]

A small but crucial identity is

\[
\boxed{
K-j=s(4j-1),
}
\]

so

\[
\boxed{
K\equiv j\pmod{4j-1}.
}
\]

## 2. Prime-child shadow theorem

### Theorem

Suppose

\[
4j-1\mid4K-1
\]

and the later depth `K` is prime.

Then the entire later Type A/B trap set is directly shadowed by the earlier layer `j`:

\[
\boxed{
T_K\bmod(4j-1)
\subseteq
T_j.
}
\]

### Proof

Because `K` is prime, its positive divisors are only

\[
1,\ K.
\]

Therefore

\[
T_K
=
\{-1,-4,-K,-4K\}
\pmod{4K-1}.
\]

Reduce these residues modulo

\[
m=4j-1.
\]

The ancestry identity gives

\[
K\equiv j\pmod m.
\]

Hence

\[
-K\equiv-j\pmod m,
\]

and

\[
-4K\equiv-4j\equiv-1\pmod m.
\]

Thus the projected target trap set is contained in

\[
\{-1,-4,-j\}.
\]

But `1|j` and `j|j`, so all three residues belong to `T_j`.

Therefore

\[
T_K\bmod m\subseteq T_j.
\]

QED.

## 3. Infinite prime-child shadows for every ancestry quotient

Fix any

\[
q=4s+1>1.
\]

The ancestry children of quotient `q` have depths

\[
K=qj-s.
\]

Equivalently,

\[
K\equiv-s\pmod q.
\]

Since

\[
\gcd(s,q)=1,
\]

Dirichlet's theorem gives infinitely many primes in the residue class

\[
-s\pmod q.
\]

For every such prime `K`,

\[
j=\frac{K+s}{q}
\]

is a positive integer and

\[
4K-1=q(4j-1).
\]

The prime-child theorem therefore gives an exact direct-shadow edge

\[
\boxed{j\longrightarrow K.}
\]

Thus:

### Corollary

For **every** ancestry quotient

\[
q\equiv1\pmod4,
\qquad q>1,
\]

there are infinitely many exact Type A/B direct-shadow edges of that quotient.

## 4. Counting prime-child edges for fixed q

Let

\[
P_q(X)
=
\#\{K\le X:K\text{ prime and }K\equiv-s\pmod q\},
\qquad q=4s+1.
\]

Every such prime gives one prime-child shadow edge.

By the prime number theorem in arithmetic progressions,

\[
\boxed{
P_q(X)
\sim
\frac{\operatorname{Li}(X)}{\varphi(q)}.
}
\]

So the prime-child mechanism alone contributes on the order of

\[
\frac{X}{\varphi(q)\log X}
\]

shadow edges of fixed ancestry quotient `q` up to child depth `X`.

This immediately explains why the smallest quotient `q=5` is expected to be especially prominent in finite shadow maps.

## 5. The quotient-5 family

For

\[
q=5,
\]

we have `s=1` and

\[
\boxed{K=5j-1.}
\]

The prime-child theorem gives

\[
K\text{ prime}
\Longrightarrow
T_K\bmod(4j-1)\subseteq T_j.
\]

In this special quotient, the converse also holds.

## 6. Quotient-5 rigidity theorem

### Theorem

For every positive integer `j`, put

\[
K=5j-1.
\]

Then

\[
\boxed{
T_K\bmod(4j-1)\subseteq T_j
\iff
K\text{ is prime}.
}
\]

This concerns the **unrestricted exact trap sets**. Hard-class-conditioned shadowing can be stronger because inadmissible target residues have been removed.

### Proof of the converse

Assume `K=5j-1` is composite. Put

\[
m=4j-1.
\]

We show some divisor of `K` produces a target trap residue outside `T_j`.

### Case 1: j is odd

Then `K` is even. Since `K>2`,

\[
2\mid K.
\]

Thus

\[
-2\in T_K.
\]

We claim

\[
-2\notin T_j.
\]

Equivalently, `2` does not belong to the normalized base set

\[
S_j=-T_j
=
\{d,4d\pmod m:d\mid j\}.
\]

Because `j` is odd, `2` is not a divisor of `j`.

For `d<j`,

\[
4d\le4j-4=m-3,
\]

so `4d mod m` is an even integer at least `4`, never `2`.

For `d=j`,

\[
4j\equiv1\pmod m.
\]

Hence `2 notin S_j`, so `-2 notin T_j`.

Therefore full shadowing fails.

### Case 2: j is even

Then `K` is odd and composite. Let `ell` be a prime factor of `K` with

\[
1<\ell<K.
\]

We may choose the smallest prime factor, so

\[
\ell\le\sqrt K<4j-1=m.
\]

Also

\[
\gcd(j,K)=\gcd(j,5j-1)=1,
\]

so

\[
\ell\nmid j.
\]

If `ell` belonged to the normalized base trap set `S_j`, then because `ell<m` there are only three possibilities:

1. `ell=d` for some divisor `d|j`, impossible because `ell` does not divide `j`;
2. `ell=4d` with `d<j`, impossible because `ell` is odd;
3. the wrapped value from `d=j`, namely `4j mod m=1`, impossible because `ell>1`.

Thus

\[
\ell\notin S_j,
\]

so

\[
-\ell\notin T_j.
\]

But `ell|K`, hence `-ell in T_K`. Full shadowing fails.

Therefore a composite child can never give unrestricted quotient-5 full shadowing.

Combined with the prime-child theorem,

\[
\boxed{
T_{5j-1}\bmod(4j-1)\subseteq T_j
\iff
5j-1\text{ is prime}.
}
\]

QED.

## 7. Infinite quotient-5 family

Primes

\[
K\equiv4\pmod5
\]

are infinite by Dirichlet.

For every such prime,

\[
j=\frac{K+1}{5}
\]

and the quotient-5 rigidity theorem gives a full exact direct shadow.

The first bases are

```text
j = 4,  6,  12, 16, 18, 22, 28, 30, 36, 40, ...
```

corresponding to prime children

```text
K = 19, 29, 59, 79, 89, 109, 139, 149, 179, 199, ...
```

This matches the unrestricted trap-set computation.

## 8. Why the hard-class shadow map had additional q=5 edges

Earlier finite work on the Mordell-hard residue classes found q=5 shadows such as

```text
j=3 -> K=14
j=8 -> K=39
```

whose child depths are composite.

There is no contradiction.

Those computations imposed prime compatibility and the six hard classes modulo `840` before asking whether the surviving target candidate classes were shadowed.

The quotient-5 rigidity theorem concerns the complete unrestricted target trap set.

Thus:

\[
\boxed{
\text{unrestricted shadow}
\subseteq
\text{hard-compatible shadow}
}
\]

and conditioning can create additional complete shadows after incompatible target classes disappear.

This distinction is now important enough to keep explicit in future theorem statements.

## 9. New interpretation of the ancestry graph

The observed ancestry quotient groups are not arbitrary.

Every quotient

\[
q=5,9,13,17,\ldots
\]

carries an infinite prime-child shadow family.

The direct-shadow graph therefore contains a universal arithmetic backbone indexed by:

\[
\boxed{
(q,K):
q\equiv1\pmod4,
\quad
K\equiv-(q-1)/4\pmod q,
\quad
K\text{ prime}.
}
\]

The remaining composite-child shadows are the genuinely richer part of the ancestry problem.

## 10. Next theorem targets

1. for each fixed quotient `q`, classify the **composite** children that are also fully shadowed;
2. compare composite-child shadows with square-lift quotients `q=c^2`;
3. determine when full local quadratic-signature shadowing explains a composite child;
4. determine when multiplicative quotient containment explains it;
5. isolate the residual composite-child shadows requiring exact two-box divisor geometry.

For `q=5`, this program is already complete in the unrestricted system: there are no composite-child full shadows.

## 11. Novelty boundary

Dirichlet's theorem and the prime number theorem in arithmetic progressions are classical. The modulus-divisibility identity is elementary, and López Type A/B congruences are prior art.

The candidate contribution is the **prime-child direct-shadow theorem across all Type A/B ancestry quotients and the exact quotient-5 rigidity classification inside the minimal-depth/shadow framework**.

Targeted literature searches have not yet located this formulation. That is not proof of publication priority.
