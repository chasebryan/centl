# Cryptology research track for WS-CAND-003

**Status:** exploratory research only
**Date opened:** 2026-08-14
**Scope:** possible cryptologic relevance of Type A/B witness depth, trap geometry, and congruence shadowing

This note records a cryptology-facing research program arising from WS-CAND-003. It does **not** claim a break of RSA, discrete logarithm systems, elliptic-curve cryptography, post-quantum cryptography, or any deployed cryptosystem.

The motivating observation is that the current work has produced a deterministic arithmetic fingerprint of primes and an exact redundancy structure among modular constraints:

\[
C_{AB}(p)=\min\{k\ge 1:p\bmod(4k-1)\in T_k\},
\]

with

\[
T_k=\{-d,-4d\pmod{4k-1}:d\mid k\},
\]

plus a direct-shadow relation describing when one modular trap layer is implied by an earlier layer.

Cryptology routinely depends on prime generation, modular arithmetic, structured-prime selection, sieving, and the absence of unintended arithmetic bias. This makes the new objects worth testing as **cryptographic diagnostics and sieve structure**, even though no cryptographic impact has yet been demonstrated.

## 1. The strongest plausible connection: prime-source fingerprinting

`C_AB(p)` and the fuller hit/shadow profile of a prime can be treated as arithmetic features.

Define a finite fingerprint through depth `K` by

\[
F_K(p)=\left(C_{AB}(p),\;\mathbf 1[p\bmod m_k\in T_k]_{1\le k\le K},\;\text{shadow/novelty labels}\right).
\]

The first cryptologic question is whether the distribution of these features differs detectably between prime populations generated under different structural constraints.

Candidate populations include:

- unconstrained random probable primes of a fixed bit size;
- Blum primes `p == 3 mod 4`;
- safe primes `p=2r+1` with `r` prime;
- primes restricted to selected residue classes;
- primes produced by standards-oriented generation procedures, when reproducible test implementations are available;
- deliberately structured toy prime families used as controls.

A measurable distinction would not itself imply weakness. It would establish that the Type A/B depth/shadow system is sensitive to prime-generation structure and could therefore serve as a **prime-distribution audit statistic**.

## 2. Prime-generation auditing and backdoor detection

Modern public-key systems depend on suitable prime or prime-field parameters. Standards such as NIST FIPS 186-5 specify RSA and signature-related parameter generation requirements, and NIST validation material explicitly treats properties of generated RSA primes as testable key-generation outputs.

The research hypothesis is:

> If a prime generator introduces hidden modular structure, a Type A/B depth or shadow fingerprint may detect distributional deviations even when ordinary low-modulus checks do not.

This is a detection hypothesis, not an assertion that any standardized generator is biased or vulnerable.

A useful negative control is equally important: if `C_AB` fingerprints are statistically indistinguishable after conditioning on the generator's explicit congruence requirements, that limits the cryptologic relevance of the invariant in this direction.

## 3. Structured-prime diagnostics

Cryptanalytic history contains many examples in which special arithmetic structure in parameters matters. Number-field-sieve variants exploit special-form finite-field primes, and lattice/Coppersmith techniques can exploit particular modular polynomial structure in vulnerable constructions.

The current Type A/B framework should therefore be tested as a **structure detector**, not assumed to be an attack.

Questions:

1. Do primes with unusually large or small `C_AB` exhibit correlations with known structured-prime families?
2. Does the ancestry/shadow profile detect arithmetic regularity not captured by a handful of small congruence tests?
3. Are record-depth primes unusually generic, unusually structured, or neither under standard prime statistics?
4. Can a shadow-compressed fingerprint identify deliberately planted toy prime-generation biases?

No positive answer should be promoted to a cryptographic weakness without a concrete reduction, distinguisher, key-recovery improvement, or parameter-generation failure.

## 4. Modular-sieve compression

The direct-shadow relation has an immediate algorithmic interpretation:

> if one modular condition is implied by earlier modular conditions, it can be removed from a sieve without changing the accepted set.

The Type A/B system is not the number field sieve, quadratic sieve, or a cryptographic lattice attack. However, the mathematical pattern is close enough to motivate a generic question:

\[
\text{Can shadow analysis compress other modular sieves or modular constraint systems?}
\]

The research should separate two levels:

- **domain-specific result:** exact compression of the Type A/B congruence sieve;
- **transfer result:** a generalized shadow criterion that improves a cryptologically relevant sieve or modular search problem.

Only the second would establish a direct cryptologic algorithmic impact.

## 5. RSA: what can and cannot currently be said

For an RSA modulus

\[
N=pq,
\]

the factors `p` and `q` are secret, while `N` is public. A factor-specific value such as `C_AB(p)` is therefore not directly observable from the public key.

The current research does **not** provide a factorization algorithm.

There is nevertheless a concrete research question. For every `k`, public knowledge of

\[
N\bmod m_k=(p\bmod m_k)(q\bmod m_k)\bmod m_k
\]

couples the two unknown factor residues. The trap sets `T_k`, together with cross-layer ancestry and shadow constraints, define finite residue systems for the possible factors.

The experimental question is whether combining these public product constraints across many **irredundant** layers reduces the candidate factor-residue space faster than an appropriate random baseline.

This must first be tested on toy RSA moduli where the true factors are retained only for scoring. A useful outcome may be either positive or negative:

- positive: a measurable residue-space reduction beyond trivial congruence information, motivating deeper cryptanalysis;
- negative: evidence that the factor-specific invariant does not leak usefully through the product modulus.

Until such an experiment succeeds, describing the work as an RSA attack would be incorrect.

## 6. Public-modulus fingerprint

For a modulus `N` and layer `k`, define the public product residue

\[
r_k=N\bmod m_k.
\]

One simple diagnostic is the product-trap set

\[
P_k=\{ab\bmod m_k:a,b\in T_k,\gcd(ab,m_k)=1\}.
\]

Then

\[
G_K(N)=\left(\mathbf 1[r_k\in P_k]\right)_{1\le k\le K}
\]

is computable without factoring `N`.

This does **not** prove that the actual secret factors are both in `T_k`; it only tests compatibility with that possibility. The purpose of `G_K` is empirical: determine whether different prime-generation families induce distinguishable public-modulus distributions after controlling for obvious residue constraints.

## 7. Immediate experiments

The cryptology track begins with deliberately modest, falsifiable experiments:

1. Generate equal-size samples of random primes, Blum primes, safe primes, hard-class primes, and deliberately biased toy primes.
2. Measure `C_AB`, hit-vector, direct-shadow, and ancestry statistics for every prime.
3. Compare empirical distributions using total-variation distance and simple held-out classification, with explicit controls for known congruence restrictions.
4. Form toy RSA moduli from each population and compute public product-trap fingerprints `G_K(N)`.
5. Measure whether the public fingerprints identify the source population beyond the information already implied by low-modulus constraints.
6. Test whether removing directly shadowed layers preserves all measured information while reducing work.
7. If a nontrivial signal survives, escalate to larger bit sizes and stronger statistical tests.

The initial experiments are diagnostic. They must not be described as key recovery or cryptographic breaks.

## 8. CENTL's role

CENTL should remain the exact-verification layer rather than the statistical oracle.

For each cryptology experiment it should certify, where expressible in the current language:

- exact algebraic identities used to derive structured prime families;
- modulus-ancestry polynomial identities;
- exact rational summaries and derived formulas;
- generated proof contracts for any claimed algebraic reduction.

Python or another dedicated finite-search engine may enumerate primes and residue classes, but the resulting algebraic claims should be replayed through CENTL and accompanied by deterministic artifacts and hashes, following the existing WS-CAND-003 methodology.

## 9. Claim discipline

Permitted current wording:

> The Type A/B witness-depth and shadow framework has plausible cryptologic relevance as a new arithmetic fingerprint of primes and as a method for identifying redundant modular constraints. FCF is testing whether that structure yields useful prime-generation distinguishers, parameter-audit diagnostics, or modular-sieve compression.

Not currently justified:

- "FCF broke RSA."
- "The Erdős-Straus work weakens modern encryption."
- "C_AB leaks RSA factors."
- "The shadow graph improves the number field sieve."
- "Cryptographic standards generate weak primes."

Those require separate evidence.

## 10. Primary references for the cryptology bridge

- NIST, *FIPS 186-5: Digital Signature Standard*, 2023, https://doi.org/10.6028/NIST.FIPS.186-5
- NIST ACVP RSA key-generation specification, including generated-prime properties and test modes, https://pages.nist.gov/ACVP/draft-celi-acvp-rsa.html
- R. Barbulescu, P. Gaudry, T. Kleinjung, *The Tower Number Field Sieve*, IACR ePrint 2015/505. This is cited only as established evidence that special arithmetic form of cryptographic parameters can affect sieve complexity, not as evidence that `C_AB` has such an effect.
- H. Davis, M. Green, N. Heninger, K. Ryan, A. Suhl, *On the Possibility of a Backdoor in the Micali-Schnorr Generator*, IACR ePrint 2023/440. This is cited as an example of cryptanalysis exploiting structured parameters with lattice techniques, not as an analogue already established for the present framework.

## 11. Research target

The strongest near-term cryptology result would be one of the following:

1. a reproducible distinguisher showing that `F_K` detects a nontrivial prime-generation bias after conditioning on all obvious congruence information;
2. a public-modulus statistic derived from the shadow-compressed system that distinguishes structured toy RSA populations without access to the factors;
3. a general shadow-compression theorem that transfers to a recognized cryptologic modular sieve.

Until one of these is obtained, the cryptology connection remains a motivated research program rather than a cryptographic impact claim.
