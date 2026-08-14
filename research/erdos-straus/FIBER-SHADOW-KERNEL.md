# Fiber shadow kernel: a sharper local elimination theorem

**Status:** theorem note and active proof direction  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

This strengthens the prime-power peeling lemma in [SHADOW-KERNEL.md](SHADOW-KERNEL.md). The earlier load used the full size `|R_j|` of a forbidden pullback set against every prime coordinate dividing its modulus. That is deliberately coarse. Once the other coordinates are fixed, only one **fiber** of `R_j` can matter.

The resulting fiber load is strictly sharper and appears to compress the candidatewise obstruction dramatically.

Read with:

- [DIAMOND.md](DIAMOND.md)
- [DIRECT-SHADOW-K1000.md](DIRECT-SHADOW-K1000.md)
- [ODD-COVERING-BRIDGE.md](ODD-COVERING-BRIDGE.md)
- [SHADOW-COVER-GEOMETRY.md](SHADOW-COVER-GEOMETRY.md)
- [SHADOW-KERNEL.md](SHADOW-KERNEL.md)

## 1. Setup

For a fixed admissible Type A/B candidate write

\[
x=r+Ls.
\]

Every earlier active layer gives

\[
s\bmod q_j\in R_j,
\qquad
q_j=\frac{4j-1}{\gcd(L,4j-1)}.
\]

Let

\[
Q=\operatorname{lcm}\{q_j:R_j\neq\varnothing\}
=\prod_p p^{A_p}.
\]

Fix a prime `p|Q`. For one active constraint write

\[
q_j=p^{a_{j,p}}c_{j,p},
\qquad
\gcd(p,c_{j,p})=1.
\]

CRT identifies

\[
\mathbb Z/q_j\mathbb Z
\cong
\mathbb Z/p^{a_{j,p}}\mathbb Z
\times
\mathbb Z/c_{j,p}\mathbb Z.
\]

## 2. Fiber width

For `b mod c_{j,p}`, define the `p`-fiber of the forbidden set

\[
F_{j,p}(b)
=
\left\{
a\bmod p^{a_{j,p}}:
(a,b)\text{ corresponds by CRT to an element of }R_j
\right\}.
\]

Define its maximum width

\[
\boxed{
f_{j,p}=\max_{b\bmod c_{j,p}}|F_{j,p}(b)|.
}
\]

Necessarily

\[
1\le f_{j,p}\le \min(|R_j|,p^{a_{j,p}})
\]

for an active incident constraint.

The coarse peeling lemma replaced `f_{j,p}` by `|R_j|`. The difference can be substantial because the forbidden residues may be distributed over many settings of the other prime coordinates.

## 3. Fiber peeling lemma

### Theorem

Define the fiber load

\[
\boxed{
\Lambda_p
=
\sum_{\substack{j<k\\p\mid q_j}}
\frac{f_{j,p}}{p^{a_{j,p}}}.
}
\]

If

\[
\boxed{\Lambda_p<1,}
\]

then the prime-power coordinate `p^{A_p}` is peelable: every assignment of all other prime-power coordinates satisfying all constraints not involving `p` extends to at least one value of the `p^{A_p}` coordinate satisfying every constraint involving `p`.

### Proof

Fix all coordinates other than `p`.

For an incident constraint `j`, the fixed non-`p` coordinates determine one residue

\[
b\bmod c_{j,p}.
\]

The constraint can therefore forbid only the fiber

\[
F_{j,p}(b),
\]

whose size is at most `f_{j,p}` modulo `p^{a_{j,p}}`.

Each forbidden value modulo `p^{a_{j,p}}` has exactly

\[
p^{A_p-a_{j,p}}
\]

lifts modulo `p^{A_p}`. Thus constraint `j` excludes at most

\[
f_{j,p}p^{A_p-a_{j,p}}
\]

full-coordinate values.

All incident constraints together exclude at most

\[
p^{A_p}
\sum_{p\mid q_j}
\frac{f_{j,p}}{p^{a_{j,p}}}
=
p^{A_p}\Lambda_p.
\]

If `Lambda_p<1`, fewer than all `p^{A_p}` values are excluded. At least one extension survives. QED.

## 4. Reduced fiber peeling

For prime realization we additionally require

\[
\gcd(r+Ls,LQ)=1.
\]

When `p` does not divide `L`, reducedness forbids one residue modulo `p` and therefore contributes exactly `1/p` to the local load. When `p|L`, admissibility already gives `p` not dividing `r`, so no additional local restriction is needed.

Define

\[
\boxed{
\Lambda_p^{\!*}
=
\Lambda_p
+
\begin{cases}
1/p,&p\nmid L,\\
0,&p\mid L.
\end{cases}
}
\]

Then

\[
\boxed{\Lambda_p^{\!*}<1}
\]

is an exact sufficient condition for peeling `p` while preserving the possibility of a reduced final progression.

## 5. Iterated fiber kernel

When a coordinate is peeled, every constraint incident to it can be removed from the residual problem. This can only decrease the fiber loads of the remaining coordinates.

Therefore fiber peeling can be iterated until no remaining coordinate satisfies the strict load inequality.

The residual system is the **fiber shadow kernel**.

If the fiber shadow kernel is empty, then a reduced avoiding assignment exists by constructive reverse extension, independently of the large sequential witness scan. Dirichlet then gives infinitely many exact-depth primes in the candidate.

This gives a new sufficient theorem for DSC-P on any candidate whose fiber kernel vanishes.

## 6. Why this is materially stronger

The original global cover mass

\[
W=\sum_j|R_j|/q_j
\]

is often far above one. The coarse coordinate load can also remain above one on small primes.

Fiber load asks a different question:

> after the other coordinates have been fixed, how many values can this constraint actually remove from this one coordinate?

That is the correct quantity for variable elimination.

It captures overlap **inside each forbidden set**, before overlap among different layers is even considered.

## 7. Exploratory proof-mining signal from the certified k <= 1000 bundle

The exact theorem above is unconditional. The following finite numbers are exploratory diagnostics from the already verified `k<=1000` candidate bundle and are being moved into automated certificate generation before they should be treated as frozen project results.

An evenly distributed diagnostic sample of `5,000` of the `33,644` certified directly novel candidates gave:

```text
fiber kernel empty:              3,686 / 5,000
residual kernel size 2:              3
residual kernel size 3:            523
residual kernel size 5:              1
residual kernel size 6:             18
residual kernel size 7:            769
```

Thus roughly `73.7%` of this diagnostic sample were already proved reduced-realizable by fiber peeling alone, without using their stored avoiding witness.

More strikingly, every residual kernel in this sample was supported on primes at most

\[
\boxed{23}.
\]

The two overwhelmingly dominant nonempty prime signatures were

\[
\boxed{\{3,11,13\}}
\]

and

\[
\boxed{\{3,5,11,13,17,19,23\}}.
\]

These sample statistics are not a universal theorem and are not yet a complete `33,644`-candidate enumeration. Their significance is that the stronger exact elimination rule appears to collapse hundreds of active congruence layers to a tiny recurring small-prime interior.

## 8. Two difficult examples

Exploratory exact reconstruction gives two useful examples.

For the high-search-parameter candidate

\[
(k,h,t)=(987,169,3935),
\]

whose independently certified reduced witness first appeared at `s=730101`, fiber peeling reduces the entire earlier-layer system to only

\[
\boxed{\{3,11,13\}}.
\]

The residual system contains fourteen constraints. The local assignment `s=1` on all three remaining prime-power coordinates satisfies those residual constraints and the local reducedness requirements. Thus this apparently difficult global witness hides a very small local core.

For the earlier proof-mining outlier

\[
(k,h,t)=(648,529,2585),
\]

fiber peeling removes the entire residual coordinate system: its fiber shadow kernel is empty.

These examples must be independently frozen by the automated analyzer before being promoted from proof-mining evidence to regression fixtures.

## 9. The emerging theorem architecture

The union-shadow problem now has three scales:

\[
\boxed{
\begin{array}{c}
\text{hundreds of raw earlier constraints}\\
\downarrow\\
\text{prime-power decomposition}\\
\downarrow\\
\text{coarse local-load peeling}\\
\downarrow\\
\text{fiber-load peeling}\\
\downarrow\\
\text{tiny recurring small-prime kernel}
\end{array}
}
\]

The research problem has therefore sharpened again.

Instead of proving directly that hundreds of odd congruence systems cannot cover, it may be enough to:

1. prove that fiber peeling always removes every prime outside a bounded small set;
2. classify the finitely structured residual kernel types;
3. prove each kernel type has a reduced satisfying assignment whenever no direct shadow exists.

## 10. Immediate next work

1. run the fiber-kernel analyzer over **all** `33,644` certified candidates through `k=1000`;
2. run it automatically on the in-progress `k<=1200` certificate bundle;
3. hash and independently verify the fiber-width calculations;
4. classify residual kernel signatures up to prime-coordinate relabeling and residue translation;
5. test whether every residual kernel is solved by a canonical all-ones basepoint plus at most one or two local coordinate repairs;
6. derive trap-specific bounds on `f_{j,p}`, rather than using them only computationally;
7. search for an absolute small-prime bound for the fiber kernel.

## 11. Current interpretation

The first peeling lemma proved that the obstruction has a small-prime interior.

The fiber refinement now suggests that the interior may be **dramatically smaller and highly repetitive**.

That is exactly the kind of compression one would hope to see before a finite computational phenomenon turns into a structural proof.