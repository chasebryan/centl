# Future Operator Instructions

**Date updated:** 2026-08-15  
**Scope:** Erdős-Straus / López Type A/B / DSC-P program  
**Authority:** Coordinator ledger; repository is canonical

## Mission

Advance the Type A/B shadow program toward universal Direct-Shadow Completeness while preserving exact claim boundaries.

Do not claim Erdős-Straus, universal López Type A/B coverage, or universal DSC-P unless a complete proof is deposited and independently checked.

## Hard rules

1. **Repository first.** No material result exists only in chat.
2. **Proof status must be explicit.** Distinguish theorem, finite certificate, formulation, conjecture, and retraction.
3. **Retractions stay visible.** Do not resurrect superseded theorem claims from Git history.
4. **Finite is not universal.** Numerical cleanliness is a falsification result, not a proof.
5. **Exact trap membership is finer than signature/coset membership.** Never collapse the hierarchy.
6. **Reducedness belongs to `x=r+Ls`, not to the parameter `s` by itself.**
7. **Operator-02 remains a parallel analysis lane.** Parent promotion is a Coordinator action after review.

## Corrections that every future operator must know

### Retracted first-shell proof

The former claim that arbitrary members `d u^2` of a squarefree tower inherit the same negative Jacobi sign was used without checking `gcd(r,u)=1`. That proof is invalid.

The sharp hard-class observation

\[
|N^{act}|=1\Longrightarrow q\in\{3,5,9\}
\]

is **finite-certified through `k<=100000` only**, not a theorem.

### Retracted all-j odd-prime-shift theorem

The all-`j` claim is false. Counterexample:

\[
r=17,\ j=2,\ K=121,
\]

which is fully shadowed but neither prime nor `17p`.

The correct uniform theorem is:

\[
\boxed{
r\text{ odd prime},\ j\ge r+1
\Longrightarrow
\text{full shadow}\iff K\text{ prime or }K=rp.
}
\]

Small `j<=r` is a real exception strip.

## Current P0: prove C1 coordination

The local unique-active-row obstruction is **solved**.

Read:

- `SINGLE-ACTIVE-EXCESS-PRIME-POWER.md`
- `SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md`
- `C1-PULLBACK-CARDINALITY.md`
- `CLASS-C-CENSUS-K1500.md`

For `|N^{act}|=1`, the active quotient is `p` or `p^2`, and the unique active fixed-negative row always has a reduced exact local escape.

The remaining C1 problem is:

\[
\boxed{
\text{coordinate that guaranteed local escape with every surviving nonfixed exact row.}
}
\]

Finite `k<=1500` data:

```text
single-active candidates:                    2,770
nonempty final fiber kernels:                1,480
active row survives final kernel:               18
nonfixed residual edge incidences:          69,672
all nonempty C1 kernels globally solved: 1,480/1,480
maximum bounded-selector radius:                48
```

A naive union bound cannot solve these systems: the nonempty C1 residual systems already have nominal forbidden mass greater than one. A naive asymmetric Lovász Local Lemma probe also did not certify them. Do not repeat those approaches without a new invariant.

## P0-A: solve the two `{11,13}` residual systems structurally

There are exactly two smallest nonempty C1 kernels with residual prime signature

\[
\boxed{\{11,13\}}.
\]

Both occur at target depth `k=574`, hard class `h=169`, with active `j0=319`, `q=5`, and empty active-row pullback.

The exact residual period is

\[
11^3 13^2=224,939.
\]

Each system has exactly

\[
54,990
\]

reduced safe residues in the full period.

After the pure 11-adic constraints and reducedness, 725 values remain modulo `11^3`. Conditional on those values, the safe 13-adic fiber size is always `65` or `78`.

Observed split:

```text
605 eleven-adic values -> 78 safe thirteen-adic values
120 eleven-adic values -> 65 safe thirteen-adic values
605*78 + 120*65 = 54,990
```

This is the cleanest laboratory for a **conditioned fiber theorem**.

Goal: derive those two fiber sizes algebraically from the Type A/B trap rows and prove they are positive without enumerating the full period.

## P0-B: lift to the recurring `{3,11,13}` kernel

The signature

\[
\boxed{\{3,11,13\}}
\]

occurs 336 times in the single-active `k<=1500` census.

Once `{11,13}` is understood, add the 3-adic coordinate and determine whether the conditioned-fiber positivity theorem tensorizes, nests, or requires a new overlap invariant.

## P0-C: classify residual row support

In the finite C1 bundle, final residual edges have prime-support size only `1`, `2`, or `3`.

Current exact incidence counts:

```text
support size 1: 16,092
support size 2: 47,250
support size 3:  6,348
```

The problem is therefore locally low-arity even though the global residual graph is dense.

Goal: prove that low-arity Type A/B rows have a positive conditioned fiber after a suitable elimination order.

## P1: conditioned fiber / variable-elimination theorem

Develop a theorem of the following shape.

Let the residual modulus factor into prime-power coordinates. Eliminate coordinates one at a time. At each step, condition on an assignment to the already-eliminated coordinates and bound the number of forbidden values in the next coordinate using exact trap-fiber collision profiles.

Desired invariant:

\[
\boxed{
\text{every surviving partial assignment has at least one safe extension}
}
\]

or a weaker invariant that guarantees at least one full branch survives.

This would explain why enormous nominal cover mass can coexist with a large exact complement.

## P2: bounded active-core size

Only after C1 is proved globally, extend to

\[
|N^{act}|=2,3,\ldots
\]

Do not skip the C1 coordination proof merely because finite selectors work.

## P3: ancestry exception strip

The general ancestry results now include:

- divisor-child theorem;
- asymptotic ancestry skeleton;
- odd-prime-shift exact rigidity for `j>=r+1`;
- exact classifications at quotients 5, 9, 13, 17, 21, 29;
- dyadic/Mersenne trap lattice.

The new ancestry target is the small strip

\[
\boxed{1\le j\le r}
\]

for odd-prime shift `r`.

For fixed `j`, classify primes `r` for which every divisor of

\[
K=r(4j-1)+j
\]

lands in the fixed finite set `S_j` modulo `4j-1`.

Dyadic `j=2^a` should be studied through the exact Mersenne subgroup theorem rather than rediscovered experimentally.

## P4: mixed-box support two

Operator-02 has finite evidence through `j<=50000` that every mixed-only exact projection failure has a support-2 witness and no support-3 minimum.

Either prove the support-2 theorem or freeze the first support-3 counterexample.

## P5: atom-to-shadow bridge

Continue the multiplicative defect atom program:

1. build neutral divisor from each minimal zero-product atom;
2. test exact ancestor trap membership;
3. if it misses, search earlier direct shadows;
4. classify whether exact misses are systematically killed elsewhere.

This remains a promising bridge from finite-abelian conservation to exact DSC-P.

## Current success criterion

The next major promotion should be one of:

1. a theorem proving the `{11,13}` conditioned fiber is always positive in its exact C1 family;
2. a general conditioned-fiber elimination lemma subsuming `{11,13}`;
3. a counterexample showing why that route fails, with exact residual certificate;
4. a proof of full C1 coordination.

## Forbidden outcomes

- claiming the hard `3/5/9` collapse as universal;
- claiming all odd-prime shifts have no small-`j` exceptions;
- calling `gcd(s,q)=1` the relevant reducedness condition;
- promoting finite selector success to universal DSC-P;
- claiming Erdős-Straus solved.

## Standing order

**The active row is locally beaten. Now prove why the nonfixed residual rows cannot jointly close the door.**
