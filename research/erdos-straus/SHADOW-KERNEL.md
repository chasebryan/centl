# Prime-power shadow kernel

**Status:** theorem note plus finite exact bound  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note does not prove universal Direct-Shadow Completeness, Lopez Type A/B coverage, or the Erdos-Straus conjecture.

This note develops the prime-power kernel hinted at by [ODD-COVERING-BRIDGE.md](ODD-COVERING-BRIDGE.md) and the candidatewise results in [DIRECT-SHADOW-K1000.md](DIRECT-SHADOW-K1000.md).

The main point is exact: a large class of prime-power coordinates can be removed from the union-shadow satisfiability problem by a local load inequality. Any genuine counterexample to Direct-Shadow Completeness must therefore survive inside a much smaller prime-coordinate kernel.

## 1. Pullback system

Fix an admissible hard-class Type A/B candidate `(k,h,t)` and write

\[
x=r+Ls,
\qquad
L=\operatorname{lcm}(840,4k-1).
\]

For every earlier layer `j<k`, let

\[
q_j=\frac{4j-1}{\gcd(L,4j-1)}
\]

and let

\[
R_j\subseteq\mathbb Z/q_j\mathbb Z
\]

be the forbidden parameter residues satisfying

\[
r+Ls\bmod(4j-1)\in T_j
\iff
s\bmod q_j\in R_j.
\]

Let

\[
Q=\operatorname{lcm}\{q_j:R_j\neq\varnothing\}
=
\prod_p p^{A_p}.
\]

The parameter space decomposes as the product of the prime-power coordinates `p^{A_p}`.

## 2. Coordinate load

Fix a prime `p|Q`. For every active constraint with `p|q_j`, put

\[
a_{j,p}=v_p(q_j)\ge1.
\]

Define the exact local load

\[
\boxed{
\lambda_p
=
\sum_{\substack{j<k\\p\mid q_j}}
\frac{|R_j|}{p^{a_{j,p}}}.
}
\]

This quantity is not the global cover mass. It measures only how much of the `p^{A_p}` coordinate can be excluded after every other prime-power coordinate has been fixed.

## 3. Prime-power peeling lemma

### Lemma

If

\[
\boxed{\lambda_p<1,}
\]

then the `p` coordinate is **peelable**: every assignment of all other prime-power coordinates that satisfies the constraints not involving `p` can be extended to a value modulo `p^{A_p}` satisfying every constraint involving `p`.

### Proof

Fix arbitrary values of every coordinate except `p^{A_p}`.

Consider one constraint `(q_j,R_j)` involving `p`, with

\[
p^{a_{j,p}}\Vert q_j.
\]

Once the other coordinates are fixed, each residue in `R_j` can forbid at most one residue modulo `p^{a_{j,p}}`. Each such residue has exactly

\[
p^{A_p-a_{j,p}}
\]

lifts modulo `p^{A_p}`.

Therefore constraint `j` excludes at most

\[
|R_j|p^{A_p-a_{j,p}}
\]

values of the full `p` coordinate.

By the union bound, all constraints involving `p` exclude at most

\[
\sum_{p\mid q_j}|R_j|p^{A_p-a_{j,p}}
=
p^{A_p}\lambda_p.
\]

If `lambda_p<1`, this number is strictly smaller than `p^{A_p}`. Hence at least one value of the `p` coordinate survives. QED.

## 4. Satisfiability-preserving elimination

The lemma gives an exact elimination rule.

When `lambda_p<1`:

1. remove the `p` coordinate;
2. remove every constraint involving `p`;
3. solve the residual constraint system;
4. extend the solution back to `p` using the peeling lemma.

Loads can only decrease after constraints are removed. Therefore this process may be iterated.

The coordinates that remain when no further `lambda_p<1` move is possible form the **prime-power shadow kernel** of the candidate under this peeling rule.

If the kernel is empty, the candidate is proved not union-shadowed without searching over the complete period `Q`.

## 5. Reduced prime-realization load

For DSC-P we need more than an avoiding integer. We need a reduced progression.

For every prime `p|Q` with `p` not dividing `L`, the condition

\[
p\nmid r+Ls
\]

forbids exactly one residue class modulo `p`, namely

\[
s\not\equiv-rL^{-1}\pmod p.
\]

This removes a fraction `1/p` of the `p^{A_p}` coordinate.

Define the augmented load

\[
\boxed{
\lambda_p^{\!*}
=
\lambda_p
+
\begin{cases}
1/p,&p\nmid L,\\
0,&p\mid L.
\end{cases}
}
\]

If

\[
\lambda_p^{\!*}<1,
\]

the same proof peels `p` while preserving the possibility of a reduced final progression.

For an admissible candidate, `r` is already coprime to `L`, because its residues modulo `840` and `4k-1` are prime-compatible units. Thus if every coordinate can be removed by augmented peeling, the resulting avoiding class is reduced modulo `LQ` and Dirichlet supplies infinitely many exact-depth primes.

## 6. Candidate-independent upper load

The local load can be bounded without knowing the candidate.

Since `R_j` is an affine pullback of the trap set,

\[
|R_j|\le|T_j|.
\]

Also, if `p|q_j`, then necessarily

\[
p\mid4j-1.
\]

Because `a_{j,p}>=1`, we obtain

\[
\lambda_p
\le
\frac1p
\sum_{\substack{1\le j<k\\p\mid4j-1}}|T_j|.
\]

For reducedness, a uniform sufficient bound is therefore

\[
\boxed{
B_p(k)
=
\frac{1+\displaystyle\sum_{\substack{1\le j<k\\p\mid4j-1}}|T_j|}{p}.
}
\]

Whenever

\[
\boxed{B_p(k)<1,}
\]

the prime coordinate `p` is guaranteed peelable for **every** admissible candidate at target depth at most `k`, regardless of `h`, `t`, or the detailed gcd reductions.

This is deliberately conservative: candidate-specific `q_j` omit many of the terms counted by `B_p(k)`, higher `p`-adic exponents reduce load further, and multiple trap residues can project to the same local residue.

## 7. A crude analytic kernel bound

Let

\[
D_k=\max_{1\le j<k}\tau(j).
\]

Since

\[
|T_j|\le2\tau(j)\le2D_k
\]

and `4j=1 mod p` selects at most one residue class of `j mod p`, the number of indices `j<k` contributing to `B_p(k)` is at most approximately `ceil((k-1)/p)`.

Thus the simple sufficient estimate

\[
B_p(k)
\le
\frac{1+2D_k\lceil(k-1)/p\rceil}{p}
\]

shows that all sufficiently large prime coordinates are automatically peelable.

Using `ceil(x)<=x+1`, a convenient sufficient inequality is

\[
p^2-(2D_k+1)p-2D_k(k-1)>0.
\]

So any hypothetical union-shadow counterexample is forced into primes below a scale on the order of

\[
\sqrt{kD_k}+D_k,
\]

before any candidate-specific information is used.

This is not yet the sharp kernel. It is a universal elementary bound.

## 8. Exact universal bound through k = 1000

For `k<=1000`, exact trap enumeration gives

\[
\max_{j<1000}\tau(j)=32.
\]

More importantly, evaluating the sharper finite quantity `B_p(1000)` for every odd prime shows that

\[
B_p(1000)<1
\]

for every prime

\[
\boxed{p\ge113.}
\]

Therefore, for every admissible Type A/B candidate through depth `1000`, every parameter prime coordinate `p>=113` is universally peelable even after the reducedness condition is included.

Only the following `28` primes can survive this **candidate-independent** first kernel bound:

```text
3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47,
53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109
```

The actual candidate-specific kernels are usually smaller because the universal bound intentionally overcounts.

Exploratory exact peeling of difficult certified candidates has already produced residual kernels supported only on substantially smaller primes, for example at most `67` or `89` in selected high-depth cases. These observations are proof-mining data, not a universal `p<=89` theorem.

## 9. Why this matters

This changes the shape of the proof search.

A union-shadow counterexample no longer needs to be imagined as a gigantic arbitrary covering system over all prime factors of `Q`.

Large prime coordinates are provably disposable.

The obstruction, if it exists, must condense into a **small-prime kernel**.

This is strongly consonant with classical covering-system theory, where small prime divisors play an essential role in possible covers, but the present lemma is specialized directly to the Type A/B pullback system and handles multi-residue constraints.

The universal DSC-P problem can now be attacked as:

\[
\boxed{
\text{peel the large coordinates}
\longrightarrow
\text{classify the surviving small-prime kernel}
\longrightarrow
\text{prove the kernel always has a reduced survivor.}
}
\]

## 10. Next theorem targets

1. sharpen `B_p(k)` using the exact trap-cardinality formula and the arithmetic progression `4j=1 mod p`;
2. include exact candidate-specific gcd reductions and `p`-adic exponents in automated kernel certificates;
3. classify the small-prime kernels appearing through `k<=1200` and beyond;
4. determine whether the kernel belongs to finitely many isomorphism types after quotienting by residue relabeling;
5. prove a local satisfiability theorem for those kernel types;
6. combine the kernel theorem with Direct-Shadow Completeness to obtain a constructive proof of exact-depth realization.

## 11. Current interpretation

The shadow-cover problem appears to have two scales:

- a large-prime exterior that can be removed by an elementary local-load argument;
- a small-prime interior where the genuine overlap geometry lives.

That interior is now the highest-value object in the proof search.
