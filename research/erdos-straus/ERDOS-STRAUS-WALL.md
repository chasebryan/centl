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
- Exact two-target corridor companions at `q=3,7,11` and `k=15,19`, plus the linear form `2p+1`
- `{2,3,5,7}`-smooth aligned Type-II covering is impossible (external prime `ℓ≥11` is necessary)
- A public infinite hard-prime hunt with content-addressed letter numbers (`ES-HUNT.md`). Finite coverage, not a proof

## Still required for the ES route

### 1. All-prime two-target coverage

Prove that **every** prime has some Type A/B decomposition, or more generally some two-target signed-box hit. The density-one theorem is not enough. López A/B would suffice but is stronger than original ES requires.

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

A density-one set of primes is structurally captured. The remaining all-prime problem is a zero-density core: some later two-target shift must hit. Direct-shadow graphs alone cannot encode all redundancy, so future ES work should attack **existence of some Type I or Type II hit**, not universal exact-depth realizability. The next exact corridor target is the Type-I companion at `q=23`.
