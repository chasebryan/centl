# Exact survivor density and hazard for the Type A/B sieve

**Status:** theorem note
**Date:** 2026-08-14
**Claim boundary:** this note applies the prime number theorem for arithmetic progressions, the divergence of reciprocal primes in the class `3 mod 4`, and the Type A/B congruence characterization. It proves a density-one statement for Type A/B coverage of primes. It does not prove pointwise coverage of every prime and therefore does not solve the Erdős-Straus conjecture. No literature-priority claim is made without a separate prior-art review.

## 1. Finite-depth survivor states

Let

\[
m_k=4k-1,
\qquad
T_k=\{-e,-4e\pmod{m_k}:e\mid k\}.
\]

For an odd prime `p`, let

\[
C_{AB}(p)=\min\{k\ge1:p\bmod m_k\in T_k\},
\]

with `C_AB(p)=infinity` if no such layer exists.

For a fixed depth `K`, define

\[
M_K=\operatorname{lcm}(m_1,m_2,\ldots,m_K).
\]

Define the reduced survivor set

\[
S_K=
\left\{
a\in(\mathbb Z/M_K\mathbb Z)^\times:
 a\bmod m_j\notin T_j\text{ for every }1\le j\le K
\right\}.
\]

Except for the finitely many primes dividing `M_K`, a prime survives the first `K` Type A/B layers if and only if its residue modulo `M_K` belongs to `S_K`.

## 2. Exact finite-depth prime density theorem

By the prime number theorem for arithmetic progressions, each reduced residue class modulo fixed `M_K` contains asymptotically the same proportion of primes.

Therefore the relative density among primes of surviving through layer `K` exists and is exactly

\[
\boxed{
\delta_K=\frac{|S_K|}{\varphi(M_K)}.
}
\]

Likewise, define the exact-depth residue set

\[
E_k=
\left\{
a\in(\mathbb Z/M_k\mathbb Z)^\times:
 a\bmod m_k\in T_k,
\quad
 a\bmod m_j\notin T_j\text{ for }j<k
\right\}.
\]

Then the relative prime density of exact minimal depth `k` is

\[
\boxed{
\mu_k=\frac{|E_k|}{\varphi(M_k)}.
}
\]

Since exact depth `k` is precisely survival through `k-1` followed by failure at `k`,

\[
\boxed{
\mu_k=\delta_{k-1}-\delta_k.
}
\]

Thus the minimal-depth spectrum is literally the support of the density drop:

\[
\boxed{
k\text{ is infinitely prime-realizable}\iff\mu_k>0.}
\]

The implication from a nonempty reduced residue class to infinitely many prime realizations is Dirichlet's theorem.

## 3. The exact survival-history hazard

Whenever `delta_(k-1)>0`, define

\[
\boxed{
h_k=\frac{\mu_k}{\delta_{k-1}}
=1-\frac{\delta_k}{\delta_{k-1}}.}
\]

This is the exact asymptotic conditional probability that a prime hits Type A/B layer `k`, conditioned on having survived every earlier layer.

It is not a heuristic independence model. All arithmetic dependence, all direct shadows, and all joint shadow closure are already encoded in the finite residue set `S_(k-1)`.

This is the correct arithmetic replacement for the earlier raw and prime-conditioned empirical hazard models.

A structural gap is exactly a zero-hazard layer:

\[
\boxed{h_k=0\iff\mu_k=0.}
\]

## 4. Exact hazard on the prime-modulus backbone

Suppose

\[
q=m_k=4k-1
\]

is prime.

Because `q` is larger than every earlier modulus `m_j`, it divides none of them. Hence

\[
\gcd(q,M_{k-1})=1
\]

and

\[
M_k=qM_{k-1}.
\]

Every survivor residue modulo `M_(k-1)` therefore has exactly `q-1` reduced CRT extensions modulo `M_k`, one for each nonzero residue modulo `q`.

Exactly `|T_k|` of those extensions hit the target layer. Consequently

\[
|S_k|=|S_{k-1}|\bigl(q-1-|T_k|\bigr)
\]

and

\[
\boxed{
h_k=\frac{|T_k|}{q-1}=\frac{|T_k|}{4k-2}.}
\]

Using the exact trap-cardinality identity

\[
|T_k|
=
2\tau(k)-1-\mathbf 1_{4\mid k}\tau(k/4),
\]

we obtain the closed formula

\[
\boxed{
h_k
=
\frac{2\tau(k)-1-\mathbf 1_{4\mid k}\tau(k/4)}{4k-2}
\qquad(4k-1\text{ prime}).}
\]

Thus every prime-modulus backbone layer is not merely realizable. Its conditional asymptotic hazard is known exactly and is independent of the entire preceding shadow history.

## 5. Density-one Type A/B coverage of primes

For every backbone depth with `q=4k-1>7` prime, `k>=3` and

\[
|T_k|\ge3.
\]

Non-backbone layers can only remove additional survivors. Therefore

\[
\delta_K
\le
\prod_{\substack{q\le4K-1\\q\equiv3\pmod4\\q>7}}
\left(1-\frac{3}{q-1}\right).
\]

The reciprocal sum over primes `q congruent 3 mod 4` diverges. Hence this product tends to zero and

\[
\boxed{\lim_{K\to\infty}\delta_K=0.}
\]

Let

\[
\mathcal E=\{p\text{ prime}:C_{AB}(p)=\infty\}.
\]

For every fixed `K`, the set `E` is contained in the primes surviving through `K`, whose relative density is `delta_K`. Therefore

\[
\overline d_{\mathbb P}(\mathcal E)\le\delta_K
\]

for every `K`. Sending `K` to infinity gives

\[
\boxed{
overline d_{\mathbb P}(\mathcal E)=0.
}
\]

Equivalently:

\[
\boxed{\text{A relative density-one set of primes has a Type A or Type B solution.}}
\]

This is a pointwise weaker statement than López's conjecture that every prime has Type A or B, but it is unconditional.

## 6. A quantitative decay in depth

The Mertens theorem for primes in arithmetic progressions gives

\[
\sum_{\substack{q\le x\\q\equiv3\pmod4}}\frac1q
=
\frac12\log\log x+O(1).
\]

Using `log(1-u)<=-u`, the prime-modulus backbone alone yields

\[
\log\delta_K
\le
-3
\sum_{\substack{q\le4K-1\\q\equiv3\pmod4\\q>7}}
\frac1{q-1}
=
-\frac32\log\log K+O(1).
\]

Hence

\[
\boxed{
\delta_K\ll(\log K)^{-3/2}.
}
\]

This is a conservative bound because it uses only three trap residues at each prime-modulus layer and ignores every composite-modulus layer as well as the extra divisor structure in `T_k`.

## 7. Hard-class version

The same argument remains valid after conditioning on any fixed reduced residue class modulo a modulus coprime to the backbone prime `q`.

In particular, for the six Mordell hard classes modulo `840`, every backbone prime `q>7` is coprime to `840`. Therefore the exact backbone hazard formula survives unchanged inside each hard class.

Consequently the set of hard-class primes not covered by Type A/B also has relative density zero within the hard-prime population.

This dovetails with the hard-class depth spectrum and arrival-function framework: structural gaps are zero-density drops, realizable depths are positive drops, and the prime-modulus backbone supplies infinitely many explicit positive drops.

## 8. Why this changes the research picture

The Type A/B system can now be viewed as an exact arithmetic survival process:

\[
1=\delta_0\ge\delta_1\ge\delta_2\ge\cdots\to0,
\]

with exact mass function

\[
\mu_k=\delta_{k-1}-\delta_k
\]

and exact conditional hazard

\[
h_k=\mu_k/\delta_{k-1}.
\]

The shadow graph describes dependencies between layers. The shadow closure describes finite covering of survivor states. The depth spectrum is the support of `mu_k`. The arrival function records the first prime occupying each positive-mass depth. The prime-modulus backbone gives an infinite set of layers where the hazard is closed-form and independent of the past.

This unifies what previously looked like separate empirical phenomena.

## 9. The next theorem targets

The strongest immediate targets are:

1. compute or bound `h_k` at composite moduli using the shadow-closure quotient rather than raw residue density;
2. determine whether direct-shadow completeness is true, which would characterize every zero-hazard layer by a one-edge shadow obstruction;
3. exploit the exact backbone recurrence together with average divisor information for `k=(q+1)/4` to improve the conservative `(log K)^(-3/2)` survivor bound;
4. study whether the exact hazard sequence has a tractable Euler-product or multiplicative approximation after quotienting shadow dependencies;
5. relate the depth-tail `delta_K` to the arrival function `lambda(k)` and the observed record frontier.

The remaining universal question is still pointwise: density zero does not rule out an infinite sparse exceptional set, and proving that the exceptional set is empty remains equivalent to establishing Type A/B coverage for every prime.
