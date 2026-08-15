# Zero-product atom decomposition of square-lift multiplicative defects

**Status:** proved reduction using classical zero-sum theory  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** Davenport constants and zero-sum sequence theory in finite abelian groups are classical. This note applies them to the Type A/B square-lift multiplicative defect quotient. It does not prove exact Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- [MULTIPLICATIVE-DEFECT-QUOTIENT.md](MULTIPLICATIVE-DEFECT-QUOTIENT.md)
- [RECIPROCITY-DEFECT-QUOTIENT.md](RECIPROCITY-DEFECT-QUOTIENT.md)
- [MULTIPLICATIVE-TRAP-QUOTIENT.md](MULTIPLICATIVE-TRAP-QUOTIENT.md)

## 1. Defect sequence

Let

\[
d=4a-1
\]

be a squarefree ancestor modulus and let

\[
\mathcal M_a=K_a/D_a
\]

be the multiplicative reciprocity defect quotient.

For a positive odd square lift

\[
j=\frac{1+d s^2}{4},
\]

factor

\[
j=\prod_q q^{e_q}.
\]

Each prime divisor has a defect class

\[
\delta_a(q)\in\mathcal M_a.
\]

Form the finite sequence `S(j/a)` containing `e_q` copies of `delta_a(q)` for every prime `q|j`.

Its length is

\[
|S(j/a)|=\Omega(j),
\]

where `Omega` counts prime factors with multiplicity.

The multiplicative conservation theorem gives

\[
\boxed{
\prod_{g\in S(j/a)}g=1.
}
\]

Thus every square lift produces a zero-product sequence in the finite abelian group `M_a`.

## 2. Minimal zero-product atoms

A nonempty sequence in a finite abelian group is a **minimal zero-product sequence** when its total product is `1` but no nonempty proper subsequence has product `1`.

Every finite zero-product sequence admits a factorization into minimal zero-product subsequences: repeatedly choose a minimal nonempty zero-product subsequence and remove it. The remainder remains zero-product.

Therefore:

### Atom decomposition theorem

Every square-lift defect sequence admits a disjoint decomposition

\[
\boxed{
S(j/a)=A_1\sqcup\cdots\sqcup A_r
}
\]

such that each `A_i` is a minimal zero-product sequence in `M_a`.

The decomposition need not be unique. Existence is enough for the structural reduction.

## 3. Davenport bound

Let

\[
D(\mathcal M_a)
\]

be the Davenport constant of the finite abelian group `M_a`: the maximum length of a minimal zero-sum / zero-product sequence, equivalently the least `D` such that every sequence of length `D` contains a nonempty zero-product subsequence under the standard convention adjusted by one as appropriate.

Using the convention that `D(G)` is the maximum atom length, every atom in the decomposition satisfies

\[
\boxed{|A_i|\le D(\mathcal M_a).}
\]

Hence the globally large prime-factor configuration of an arbitrary square lift decomposes into defect packets whose size is bounded solely by the ancestor quotient.

This bound is independent of the square multiplier `s` and the height of the lift.

## 4. Divisor interpretation

Each atom `A_i` corresponds to a divisor

\[
e_i\mid j
\]

obtained by multiplying the prime powers selected by that subsequence.

Because the atom has product defect `1`,

\[
\boxed{
e_i\bmod d\in D_a.}
\]

Thus

\[
-e_i,-4e_i\in-D_a.
\]

So every atom determines a divisor whose projected Type A/B residues lie inside the ancestor's **multiplicative trap coset**.

If the whole defect sequence splits into more than one atom, the square lift contains multiple proper divisors with this property.

This is not yet exact ancestor trap membership because

\[
T_a\subseteq-D_a
\]

may be strict. The remaining difference is precisely the ancestor two-box / divisor-sparsity problem.

## 5. Proper neutral divisors above the Davenport threshold

Suppose

\[
\Omega(j)>D(\mathcal M_a).
\]

Take any `D(M_a)` terms of the defect sequence. By the defining zero-product property of the Davenport constant, they contain a nonempty zero-product subsequence.

Because at least one term of the full sequence lies outside those chosen terms, this zero-product subsequence is proper in the full factorization of `j`.

Hence:

### Corollary

If

\[
\boxed{
\Omega(j)>D(\mathcal M_a),
}
\]

then there exists a proper divisor

\[
\boxed{1<e<j}
\]

such that

\[
\boxed{e\bmod d\in D_a.}
\]

Since the total defect is also trivial, the complementary divisor

\[
f=j/e
\]

also satisfies

\[
\boxed{f\bmod d\in D_a.}
\]

Thus sufficiently long square-lift factorizations always split into two nontrivial multiplicatively ancestor-neutral pieces.

## 6. Atomic lifts are bounded-complexity objects

Call a square-lift defect configuration **multiplicatively atomic** when its nontrivial defect sequence is itself minimal zero-product.

Then necessarily

\[
\boxed{
\Omega_{\rm defect}(j)
\le D(\mathcal M_a),
}
\]

where `Omega_defect` counts only prime factors carrying nontrivial defect, with multiplicity.

Therefore any prospective genuinely primitive multiplicative exception at a fixed ancestor is forced into a bounded prime-factor complexity class.

Large lifts can still exist, but their defect content decomposes into bounded atoms.

## 7. Standard invariant-factor bounds

If

\[
\mathcal M_a
\cong
C_{n_1}\oplus\cdots\oplus C_{n_r},
\qquad
n_1\mid\cdots\mid n_r,
\]

then the classical lower bound is

\[
1+\sum_{i=1}^r(n_i-1)
\le D(\mathcal M_a).
\]

Equality is known for important classes including finite `p`-groups and groups of rank at most two. General upper bounds from zero-sum theory may be used when exact `D(M_a)` is unavailable.

For a cyclic defect quotient

\[
\mathcal M_a\cong C_n,
\]

we have simply

\[
\boxed{D(\mathcal M_a)=n.}
\]

For an elementary binary quotient

\[
\mathcal M_a\cong C_2^r,
\]

\[
\boxed{D(\mathcal M_a)=r+1.}
\]

## 8. Relation to the earlier binary conservation law

The reciprocity defect quotient

\[
\mathcal R_a
\]

records only the quadratic image of `M_a`.

Its conservation law sees prime exponents only modulo `2`.

The present atom decomposition occurs in the full finite abelian group `M_a`, so it retains:

- odd-order defect information;
- higher prime-power orders;
- full exponent multiplicities modulo the relevant group orders.

Thus the binary parity pairings observed in the `k<=1200` data are the first visible special case of a general finite-abelian zero-product structure.

## 9. Why this is useful for exact shadowing

The unresolved exact problem inside an ancestor coset is the two-box set

\[
-T_a
=
\phi_a(\mathcal B_{\mathbf b})
\cup
\phi_a(\mathcal B_{\mathbf b}-\mathbf b)
\subseteq D_a.
\]

The atom theorem says that arbitrary square-lift factorizations need not be studied as one huge collection of primes. Their multiplicative defect content can be reduced to bounded-size neutral divisor packets.

This suggests a two-level proof strategy:

1. classify all possible zero-product atoms in `M_a` up to the Davenport bound;
2. for the corresponding neutral divisor residues in `D_a`, prove exact inclusion in the ancestor two-box trap or identify the finite exceptional residue types.

For ancestors with small `M_a`, this converts an unbounded factorization problem into a finite local classification.

## 10. Next computational and theorem targets

1. compute invariant factors of `M_a` for squarefree ancestors appearing through the current research range;
2. compute exact Davenport constants whenever the group class permits it;
3. classify observed square-lift defect sequences into zero-product atom types;
4. compare each atom's neutral divisor residue with `T_a` rather than merely `D_a`;
5. test whether every atom failing exact ancestor-trap membership is already shadowed by another earlier layer;
6. search for a uniform bound on the atom types needed in the directly novel candidate core.

The fifth target is a concrete route from classical zero-sum structure back to the exact Direct-Shadow Completeness theorem.
