# Unique-active valuation excess is a first prime-power lift

**Status:** proved universal theorem  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Coordinator:** Operator-01 / primary research lead  
**Partner input:** Operator-02 active fixed-negative core and valuation criterion  
**Claim boundary:** this theorem classifies the shape of the excess quotient of a unique active fixed-negative row. It does not prove the observed hard-class restriction `q in {3,5,9}`, universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- [CLASS-C-CENSUS-K1500.md](CLASS-C-CENSUS-K1500.md)
- [SINGLE-ACTIVE-LOCAL-ESCAPE.md](SINGLE-ACTIVE-LOCAL-ESCAPE.md)
- [operator-02/DIAMOND-VALUATION-CRITERION.md](operator-02/DIAMOND-VALUATION-CRITERION.md)
- [SQUARE-LIFT-CORE.md](SQUARE-LIFT-CORE.md)

## 1. Setup

Fix a target progression modulus `L` and a fixed-negative earlier layer `j` with

\[
m_j=4j-1.
\]

Because the layer is fixed at squareclass level, write

\[
\boxed{m_j=d s^2}
\]

with `d` squarefree and every prime dividing `d` already dividing `L`.

The Jacobi sign of the target residue on this entire square-lift tower depends only on `d`:

\[
\left(\frac r{d s^2}\right)=\left(\frac r d\right).
\]

Thus replacing `s` by a divisor of `s` preserves the fixed-negative character sign whenever the resulting layer is earlier and active.

Define the active excess quotient

\[
q_j=\frac{m_j}{\gcd(L,m_j)}.
\]

Assume `j` is the **unique** member of the active fixed-negative core:

\[
\boxed{|\mathcal N^{\rm act}_{k,r}|=1.}
\]

## 2. The theorem

### Theorem

For the unique active fixed-negative layer,

\[
\boxed{q_j=p^a}
\]

for one prime `p`, with

\[
\boxed{a\in\{1,2\}.}
\]

Equivalently,

\[
\boxed{q_j=p\quad\text{or}\quad p^2.}
\]

### Proof

For a prime `p`, write

\[
v_p(m_j)=v_p(d)+2v_p(s).
\]

Let

\[
b_p=v_p(L).
\]

Then

\[
v_p(q_j)=\max(v_p(m_j)-b_p,0).
\]

Because `j` is active, at least one exponent is positive.

### Step 1: only one prime can divide q_j

Suppose two distinct primes `p` and `ell` divide `q_j`.

Then both satisfy

\[
v_p(m_j)>b_p,
\qquad
v_\ell(m_j)>b_\ell.
\]

Since the squarefree part `d` is already supported on primes dividing `L`, every valuation excess comes from the square factor `s^2` beyond the amount absorbed by `L`.

Choose one excess prime, say `p`, and replace

\[
s\mapsto s/p.
\]

The resulting modulus

\[
m'=d(s/p)^2
\]

is smaller than `m_j`, hence its corresponding depth is earlier than `j` and therefore earlier than the target depth.

Its squarefree part is still `d`, so it has the same fixed-negative Jacobi sign.

Removing one factor of `p` from `s` reduces the `p`-valuation of the modulus by exactly two but leaves the `ell`-valuation unchanged. Since `ell` was already in valuation excess,

\[
v_\ell(m')=v_\ell(m_j)>b_\ell.
\]

Therefore the earlier layer `m'` remains active.

This produces a second active fixed-negative layer, contradicting uniqueness.

Hence `q_j` has support on only one prime:

\[
q_j=p^a.
\]

### Step 2: the excess exponent is at most two

Suppose

\[
a=v_p(q_j)\ge3.
\]

Again replace `s` by `s/p`. The new layer has the same squarefree part `d` and therefore the same fixed-negative sign.

Its `p`-valuation is lower by exactly two, so its remaining excess above `L` is

\[
a-2\ge1.
\]

Thus the earlier layer is still active, again contradicting uniqueness.

Therefore

\[
a\le2.
\]

Since the layer is active, `a>=1`, giving

\[
\boxed{a\in\{1,2\}.}
\]

QED.

## 3. Class-B corollary

Recall Operator-02 Class B means the excess prime is absent from `L` and appears to even exponent in the fixed-squareclass layer.

### Corollary

If the unique active fixed-negative layer is Class B, then necessarily

\[
\boxed{q_j=p^2}
\]

for a prime `p` not dividing `L`.

### Proof

If `p` does not divide `L`, then

\[
v_p(q_j)=v_p(m_j).
\]

Fixed-squareclass support requires a prime absent from `L` to occur to even exponent. The theorem restricts the positive exponent to `1` or `2`, so it must equal `2`. QED.

Thus the unique-active universe splits cleanly into:

\[
\boxed{
\begin{array}{ll}
\text{Class A:}&q=p\text{ or }p^2,\quad p\mid L,\\
\text{Class B:}&q=p^2,\quad p\nmid L.
\end{array}}
\]

## 4. First-excess interpretation

The theorem says a unique active fixed-negative row is literally the **first active prime-power lift** of its negative squarefree ancestor along one prime direction.

If more than one prime direction were already excessive, a smaller active row would exist by removing one direction.

If one direction had more than two units of valuation excess, a smaller active row would exist by removing one square factor.

So uniqueness forces the active layer onto the first shell of the valuation lattice.

## 5. Relation to the k <= 1500 census

The independently verified census found

```text
2,770 single-active candidates
q=3: 1,322
q=5:    34
q=9: 1,414
Class A only: 2,770
Class B/mixed: 0
```

The theorem explains why only prime or prime-square quotients can occur.

It does **not** yet explain why the only observed prime directions are `3` and `5`, why `7` is absent, why no prime `>=11` occurs, or why `25` is absent.

Those are now isolated as a sharper theorem candidate rather than being mixed together with the already solved prime-power question.

## 6. Hard-class small-prime collapse conjecture

The finite data suggests:

> For Mordell-hard target classes modulo 840, if a fixed-negative active core has exactly one layer, then its first-excess quotient belongs to
>
> \[
> \boxed{\{3,5,9\}}.
> \]
>
> In particular the unique active row is Class A, never Class B.

This statement is **not proved** here.

The next attack should exploit the additional hard-class facts at primes `3,5,7`, the square-lift ancestor structure, and target-modulus divisibility. A counterexample would be a hard-compatible target with `|N^act|=1` and quotient `7`, `25`, `p>=11`, or `p^2` for a free prime.

## 7. Why this matters

The Class-C problem began with arbitrary active valuation excess.

The theorem reduces the single-active branch to one prime and at most one square-lift step:

\[
\boxed{
|\mathcal N^{act}|=1
\Longrightarrow
\text{one prime direction}
\Longrightarrow
q=p\text{ or }p^2.
}
\]

That is a genuine universal compression of C1 and gives the `3,5,9` observation a precise remaining burden of proof.
