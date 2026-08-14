# Mersenne-prime backbone inside the Type A/B depth spectrum

**Status:** proved corollary combining two established project theorems  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this does not prove infinitely many Mersenne primes, universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

This note connects:

- [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md), and
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md).

The intersection produces an exact infinite-prime realization theorem at every dyadic depth whose Mersenne-type modulus happens to be prime.

## 1. Setup

Let

\[
q\ge5
\]

be a prime exponent such that

\[
\boxed{M_q=2^q-1}
\]

is prime.

Set

\[
\boxed{k=2^{q-2}.}
\]

Then

\[
4k-1
=2^q-1
=M_q.
\]

Thus the target Type A/B modulus is a Mersenne prime.

## 2. Exact trap set

The dyadic trap theorem gives

\[
\boxed{
T_k=-\langle2\rangle\pmod{M_q}.
}
\]

Because

\[
\operatorname{ord}_{M_q}(2)=q,
\]

we have

\[
\boxed{|T_k|=q.}
\]

Equivalently,

\[
\boxed{
T_k=\{-1,-2,-2^2,\ldots,-2^{q-1}\}\pmod{M_q}.
}
\]

So an apparently large divisor-generated Type A/B layer becomes one cyclic orbit of length `q`.

## 3. Independence from the previous depth history

Because `M_q=4k-1` is prime and every earlier modulus `4j-1` is strictly smaller than `M_q`, the target prime modulus is coprime to the complete previous lcm.

Therefore it introduces a genuinely new CRT coordinate at depth `k`.

The exact conditional Type A/B first-hit hazard is consequently

\[
\boxed{
h_k=\frac{|T_k|}{M_q-1}.}
\]

Substituting the dyadic trap size gives

\[
\boxed{
h_{2^{q-2}}
=\frac{q}{2^q-2}.}
\]

This is an exact arithmetic probability over prime residue classes conditioned on survival through every earlier Type A/B layer. It is not a heuristic independence approximation.

## 4. Infinite exact-depth primes

The prime-modulus backbone theorem also gives:

### Theorem

For every Mersenne prime exponent `q>=5`, infinitely many primes `p` satisfy

\[
\boxed{C_{AB}(p)=2^{q-2}.}
\]

Moreover these primes can be chosen in a Mordell-hard residue class such as

\[
p\equiv1\pmod{840}.
\]

### Reason

Choose a residue class that avoids every previous Type A/B trap, for example the universal residue `1` modulo the lcm of the earlier moduli, and independently choose any target trap residue

\[
t\in T_k
\]

modulo the new prime `M_q`.

CRT combines the conditions because the target modulus is coprime to the previous lcm. The resulting progression is reduced, and Dirichlet supplies infinitely many primes in it.

Every such prime survives all earlier layers and hits at depth `k`.

## 5. q distinct target trap families

Because the target trap set has exactly `q` residues and the target modulus is a new independent coordinate, each

\[
-2^r\pmod{M_q},
\qquad0\le r<q,
\]

can be paired with a fixed earlier-survivor progression.

Thus each Mersenne-prime dyadic depth carries `q` explicit target trap classes, each giving an infinite Dirichlet family after the earlier survivor conditions are imposed.

This does not assert that the resulting arithmetic progressions have the same prime density in finite intervals. It is an exact existence and residue-structure statement.

## 6. Examples

### q = 5

\[
M_5=31,
\qquad
k=2^3=8.
\]

Then

\[
|T_8|=5
\]

and

\[
\boxed{h_8=\frac5{30}=\frac16.}
\]

This is the same `k=8` layer that appeared prominently in the early hard-prime hazard experiments, now explained as a Mersenne-prime dyadic backbone layer.

### q = 7

\[
M_7=127,
\qquad
k=2^5=32,
\]

so

\[
\boxed{h_{32}=\frac7{126}=\frac1{18}.}
\]

### q = 13

\[
M_{13}=8191,
\qquad
k=2^{11}=2048.
\]

Therefore, without extending the finite candidate search to that depth, the theory already proves

\[
\boxed{
\text{infinitely many primes have }C_{AB}(p)=2048.
}
\]

The exact conditional hazard is

\[
\boxed{h_{2048}=\frac{13}{8190}.}
\]

This is an example of the structural theory outrunning the current brute-force depth frontier.

## 7. Relation to dyadic irredundancy

When `M_q` is prime, its exponent `q` is prime. Hence the dyadic node

\[
k=2^{q-2}
\]

has no earlier cyclic dyadic shadow ancestor.

So a Mersenne-prime backbone node is simultaneously:

1. an exact saturated dyadic trap coset;
2. irredundant inside the earlier cyclic dyadic shadow lattice;
3. a new prime CRT coordinate relative to **all** earlier Type A/B moduli;
4. an infinite exact-depth prime source.

This is an unusually clean meeting point of the shadow, quotient, spectrum, and hazard theories.

## 8. No claim about infinitely many such layers

The statement

\[
\text{infinitely many Mersenne primes exist}
\]

is itself open.

Therefore this note does **not** use the Mersenne-prime family to prove unboundedness of `C_AB`. Finite-value unboundedness was already proved by the general prime-modulus backbone using all primes `4k-1`, not only Mersenne primes.

The Mersenne family is valuable because its trap set has a complete closed multiplicative description.

## 9. Theorem-program significance

The Mersenne-prime nodes provide exact laboratory points where several layers of the theory collapse simultaneously:

\[
\boxed{
\begin{array}{c}
\text{Type A/B exact traps}\\
=\\
\text{one cyclic multiplicative coset}\\
\downarrow\\
\text{new prime CRT coordinate}\\
\downarrow\\
\text{closed exact hazard }q/(2^q-2)\\
\downarrow\\
\text{infinitely many exact-depth primes}
\end{array}
}
\]

They should be used as regression fixtures and model cases when attempting a more general multiplicative-quotient proof of DSC-P.

## 10. Novelty boundary

Mersenne numbers, their divisibility properties, and orders of `2` modulo `2^q-1` are classical. López Type A/B congruences are prior art. The candidate contribution is the way these facts combine inside the `C_AB` minimal-depth, exact-hazard, and shadow framework.

A targeted arXiv search on 2026-08-14 did not locate this exact Mersenne-prime Type-A/B depth-spectrum formulation. That negative search does not establish publication priority.
