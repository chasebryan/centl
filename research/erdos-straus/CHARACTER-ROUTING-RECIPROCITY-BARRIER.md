# Quadratic-reciprocity barrier for character-to-companion routing

**Status:** proved arithmetic theorem  
**Date:** 2026-08-16  
**Depends on:** `K11-CHARACTER-COMPANION-ROUTING.md`, fixed-shift companion identity `C_k=(p+k)/4`  
**Verifier:** `verify_character_routing_reciprocity_barrier.py`  
**Claim boundary:** this theorem explains a limitation of quadratic/Jacobi character routing. It is not a coverage theorem and does not prove Erdős-Straus.

## 1. Setup

Let

- p and q be distinct odd primes;
- p be congruent to 1 modulo 4;
- k be a positive odd integer congruent to 3 modulo 4;
- q divide the companion `C_k=(p+k)/4`;
- `(q/p)=+1`.

Because q divides C_k,

`p = -k mod q`.

Because p is 1 modulo 4, quadratic reciprocity gives

`(q/p) = (p/q)`.

Hence

`+1 = (p/q) = (-k/q)`.

Now apply Jacobi reciprocity to k and q. Since k is 3 modulo 4,

`(k/q) = (q/k) * (-1)^((q-1)/2)`.

Also

`(-1/q) = (-1)^((q-1)/2)`.

Therefore

`(-k/q) = (-1/q)(k/q) = (q/k)`.

Combining the identities yields the central result.

## 2. Reciprocity-protected routing theorem

> If a positive quadratic character `(q/p)=+1` routes the prime q into an admissible companion `C_k` with k congruent to 3 modulo 4, then
>
> `(q/k)=+1`.

Here `(q/k)` is the Jacobi symbol when k is composite and the Legendre symbol when k is prime.

The result is range-free and elementary.

## 3. Why this matters for the current support theorems

Several exact fixed-shift miss theorems in CBX have the form

> fixed k misses if and only if every prime factor of C_k lies in the positive quadratic or Jacobi character subgroup modulo k.

Examples now include:

- k=7 - quadratic-residue support modulo 7;
- k=11 on the rigid hard classes - quadratic-residue support modulo 11;
- k=15 on routed branches - Jacobi-plus support modulo 15;
- k=19 on the rigid h=121 branch and strengthened routed branches - quadratic-residue support modulo 19;
- k=23 on ten rigid residue branches - quadratic-residue support modulo 23;
- k=35 on the routed p mod11=9 branch - Jacobi-plus support modulo 35;
- k=31 and k=47 on their rigid class-conditioned branches - quadratic-residue support modulo the prime shift.

Suppose a positive-character source at q routes q into one of these receiving companions. The theorem says the routed factor q automatically has positive Jacobi character modulo the receiving k.

Therefore the newly routed factor cannot, by itself, violate a receiving miss condition whose only requirement is positive quadratic/Jacobi support.

This explains several previously observed compatible routes:

- q=19 routed into k=15 gives 19 mod15=4, in the Jacobi-plus subgroup modulo15;
- q=23 routed into k=15 gives 23 mod15=8, Jacobi-plus modulo15;
- q=31 routed into k=15 gives 31 mod15=1, Jacobi-plus modulo15;
- q=47 routed into k=15 gives 47 mod15=2, Jacobi-plus modulo15;
- q=11 routed into k=35 gives 11 a positive Jacobi character modulo35;
- q=47 routed into k=35 gives 47 mod35=12, again positive Jacobi character modulo35;
- q=23 routed into prime k=19 is automatically a quadratic residue modulo19 on the compatible route;
- q=23 routed into prime k=7 is automatically a quadratic residue modulo7 on the compatible route.

These are not accidental finite coincidences. They are forced by reciprocity.

## 4. Method-boundary corollary

Consider a route graph whose nodes are exact fixed-shift miss conditions of the form

`every prime factor of C_k has positive Jacobi character modulo k`,

and whose directed edges are generated only by

`(q/p)=+1 -> q divides C_k`.

Then every routed source factor q is automatically admitted by the quadratic/Jacobi support condition at the destination.

Consequently:

> A contradiction cannot be obtained merely by arguing that a positive-character routed factor lands outside the destination's positive quadratic/Jacobi support subgroup.

Any successful cross-shift contradiction must use information not erased by this reciprocity compatibility. Candidate sources include:

- an exact miss mask strictly smaller than the full positive-character subgroup;
- a higher-order multiplicative character rather than a quadratic/Jacobi sign;
- simultaneous routing of multiple factors into companions whose residual supports are pairwise coprime or nearly coprime;
- valuation constraints, not merely support signs;
- exact center restrictions coupled across shifts;
- non-character divisor geometry from the complete square-divisor state.

## 5. Relation to the current route graph

The theorem changes how the route graph should be mined.

A route into a quadratic-support node is not useful merely because it forces an additional prime factor. If that factor was produced from a positive quadratic character, reciprocity has already certified that the factor belongs to the destination's allowed character kernel.

The useful edges are instead those where routing does at least one of the following:

- shrinks the destination to a unique exact miss state;
- forces an additional center residue;
- creates an exact affine relation between seed-stripped residuals;
- places two or more routed primes in distinct residuals of the six-companion wheel;
- enters a destination whose exact miss mask is a proper subset of the positive-character subgroup.

This prunes a large family of seductive but structurally incapable proof attempts.

## 6. Strategic consequence

The repeated survival of quadratic character routes is now explained by theorem rather than by census.

The next theorem search should therefore move one level above Legendre/Jacobi signs. In particular, the highest-value objects are the exceptional exact miss masks already visible at k=23 residues 1,5,14 and the non-character masks at composite shifts, together with multi-route support allocation across coprime residual companions.

Erdős-Straus remains open.
