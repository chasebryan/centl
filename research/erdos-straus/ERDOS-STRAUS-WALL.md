# Erdős-Straus — Wall

**Status: OPEN**

## Major route correction

Universal Direct-Shadow Completeness is no longer part of the wall because it is **false**.

`DSC-COUNTEREXAMPLE.md` gives a hosted-verified admissible hard candidate that is not directly shadowed but is collectively covered by three earlier q=3 rows. Thus DSC-0 and DSC-P are false as universal statements.

This does **not** move Erdős-Straus backward. A collectively shadowed target is already solved by an earlier Type A/B layer. Exact-depth realizability was stronger than pointwise ES coverage requires.

## Closed / retained on this route

- Density-one Type A/B coverage of primes via the prime-modulus backbone
- Finite candidatewise DSC through `k<=1500` as a finite theorem-certificate
- Exact reduced-parameter domain `gcd(r+Ls,LQ)=1`
- Strong q=3 absorption
- Weak q=3 redundancy
- Pointwise q=3 absorption
- q=3 singleton-pullback theorem
- Direct-shadow smoothness
- Explicit counterexample showing universal DSC-0 / DSC-P are false
- Ancestry rigidity and the existing Type A/B local structure

## Still required for the ES route

### 1. All-prime Type A/B coverage

Prove that **every** prime has some Type A/B decomposition. The density-one theorem is not enough.

After the prime-modulus backbone, the pointwise burden is concentrated in the zero-density survivor core:

\[
\boxed{
\text{every prime escaping all prime-modulus layers has a composite rescue}.
}
\]

This is the principal current wall.

### 2. Composite n

Once every prime is solved, extend to arbitrary composite `n`. The standard divisor/scaling reduction means a solution for a divisor can be scaled to a solution for `n`; the repo should carry a clean self-contained proof when this stage is promoted into the final chain.

## What is no longer required

The following are useful depth-spectrum questions but are **not prerequisites for Erdős-Straus**:

- universal DSC-0;
- universal DSC-P;
- proving every directly novel candidate has an exact-depth prime;
- eliminating every collective shadow.

These belong to the separate covering-core / exact-depth program.

## Honest floor

A density-one set of primes is structurally captured. The remaining all-prime problem is a zero-density composite-rescue core. The repo now also contains an explicit proof that direct-shadow graphs alone cannot encode all redundancy, so future ES work should attack **existence of some Type A/B hit**, not universal exact-depth realizability.
