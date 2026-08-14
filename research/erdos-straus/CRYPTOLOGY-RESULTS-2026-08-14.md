# WS-CAND-003 cryptology results — 2026-08-14

**Status:** controlled exploratory result
**Cryptographic impact:** none demonstrated
**Primary conclusion:** the first strong pilot separation is explained by the deliberately planted congruence constraints; after masking those constraints, both the prime-level and public toy-RSA classifiers collapse to chance.

## 1. Experimental progression

The first pilot compared two 31-bit prime sources:

- control: `p == 1 mod 840`;
- structured: `p == 1 mod lcm(840,11,19,23)`.

It produced a large separation in `C_AB` depth and in public product-trap fingerprints. That experiment established sensitivity to planted modular structure, but it did not determine whether the Type A/B fingerprint carried information beyond the congruences explicitly planted by construction.

A second probe was therefore built with stronger controls:

- 39-bit primes;
- unique primes within each population;
- cross-label duplicate primes excluded;
- 12 independently seeded trials;
- 160 primes per population per trial;
- 80 toy RSA moduli per population per trial;
- 5-fold held-out Bernoulli naive-Bayes classification;
- shuffled-label baselines;
- feature masks removing every Type A/B modulus sharing a factor with `11*19*23`;
- a stronger deep mask also removing `k <= 6`;
- direct-shadow-compressed versions of the fingerprints.

The workflow completed successfully and CENTL verified all exact planted-control algebra contracts.

## 2. Why the pilot was expected to separate

For every `k >= 1`, the residue `1` is not in the Type A/B trap set

\[
T_k=\{-d,-4d\pmod{4k-1}:d\mid k\}.
\]

The structured source imposed

\[
p\equiv1\pmod{11},\quad
p\equiv1\pmod{19},\quad
p\equiv1\pmod{23}.
\]

Since

\[
11=4(3)-1,\qquad19=4(5)-1,\qquad23=4(6)-1,
\]

the source was forced to avoid Type A/B hits at `k=3,5,6`. The first pilot's depth shift therefore contained a deterministic built-in signal.

This is formalized separately in `CRYPTOLOGY-THEORY.md`.

## 3. v1 result at the larger 39-bit setting

At the new 39-bit workflow setting:

- control mean resolved `C_AB`: `8.20625`;
- structured mean resolved `C_AB`: `18.025`;
- control maximum resolved `C_AB`: `125`;
- structured maximum resolved `C_AB`: `112`;
- empirical `C_AB` histogram total-variation distance: `0.643750`.

This confirms that the deliberately structured source remains easily distinguishable before controlling for the planted congruences.

## 4. Repeated held-out v2 result

### 4.1 Prime-source fingerprints

| feature set | observed mean accuracy | approximate 95% interval for mean | shuffled-label mean |
|---|---:|---:|---:|
| full | 0.8367 | 0.8219 .. 0.8515 | 0.5073 |
| coprime to planted modulus | 0.4922 | 0.4730 .. 0.5114 | 0.4945 |
| deep coprime | 0.4969 | 0.4748 .. 0.5190 | 0.4964 |
| shadow compressed | 0.8177 | 0.8038 .. 0.8316 | 0.5049 |
| shadow compressed + deep coprime | 0.5039 | 0.4847 .. 0.5231 | 0.5073 |

The unmasked fingerprints strongly identify the deliberately structured prime source. Once every feature modulus sharing arithmetic information with the planted `11,19,23` conditions is removed, classification falls to chance.

### 4.2 Public toy-RSA fingerprints

Each public sample is `N=pq`. The classifier sees only the Type A/B product-trap fingerprint computed from `N`, not `p` or `q`.

| feature set | observed mean accuracy | approximate 95% interval for mean | shuffled-label mean |
|---|---:|---:|---:|
| full | 0.9771 | 0.9712 .. 0.9830 | 0.4948 |
| coprime to planted modulus | 0.5068 | 0.4865 .. 0.5271 | 0.5021 |
| deep coprime | 0.5120 | 0.4810 .. 0.5429 | 0.4833 |
| shadow compressed | 0.9526 | 0.9433 .. 0.9620 | 0.4943 |
| shadow compressed + deep coprime | 0.4969 | 0.4742 .. 0.5196 | 0.5083 |

The public modulus exposes the intentionally planted congruence structure extremely well in the full fingerprint. But after the relevant congruence information is masked, the public classifier also collapses to chance.

## 5. Scientific interpretation

This is a useful **negative result**.

The present experiment does not support a claim that Type A/B fingerprints reveal a deeper hidden property of these toy RSA factors beyond the modular structure deliberately inserted into their generator.

It also validates the experimental discipline: the full fingerprint produced an exciting-looking signal, but the correct arithmetic controls explained it.

The result narrows the cryptology program. The next experiment should plant structure that is *not* equivalent to a short list of explicit low-modulus congruences and then test whether any factor-source signature survives multiplication into `N=pq`.

## 6. Next experiment: Type A/B-selected prime source

A stronger source-selection experiment will use two populations sharing `p == 1 mod 840`:

1. an ordinary control population;
2. a population selected for unusually deep `C_AB` survival, for example `C_AB(p) >= D`.

The public-modulus test will then use two feature regimes:

- the full Type A/B product fingerprint;
- a **post-selection** fingerprint discarding all `k < D`, so the classifier cannot simply read the constraints used to select the high-depth primes.

If the public post-selection fingerprint remains at chance, that is another clean negative result. If it exhibits a reproducible held-out signal, the first task will be to eliminate finite-range, sampling, and cross-layer arithmetic explanations before calling it a cryptologic distinguisher.

## 7. Claim boundary

Current justified statement:

> The Type A/B fingerprint detects deliberately planted modular structure at both the prime and public toy-RSA-modulus level, but the observed signal disappears when the planted congruence information is properly masked. No nontrivial cryptographic distinguisher or key-recovery result has yet been demonstrated.

No result here weakens RSA or any deployed cryptosystem.
