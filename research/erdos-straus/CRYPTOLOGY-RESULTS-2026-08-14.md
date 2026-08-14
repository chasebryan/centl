# WS-CAND-003 cryptology results — 2026-08-14

**Status:** controlled exploratory result
**Cryptographic impact:** none demonstrated
**Primary conclusion:** Type A/B fingerprints strongly detect deliberately planted or selection-induced structure at the factor level, but the public toy-RSA signal collapses to chance after the defining information is controlled. A second mathematical effect is now visible: much of the apparent late-layer signal induced by selecting for large `C_AB` disappears when directly shadowed layers are removed.

## 1. Experimental progression

The cryptology track now contains three progressively stricter probes.

### v1: deliberately planted congruence source

The first pilot compared:

- control: `p == 1 mod 840`;
- structured: `p == 1 mod lcm(840,11,19,23)`.

It produced a large separation in `C_AB` depth and in public product-trap fingerprints. That experiment established sensitivity to planted modular structure, but it did not determine whether the Type A/B fingerprint carried information beyond the congruences explicitly planted by construction.

### v2: repeated held-out negative control

The second probe used:

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

### v3: high-depth source transmission

The third probe removed the explicit planted congruence source entirely. Both prime populations satisfy

\[
p\equiv1\pmod{840}.
\]

The labels are defined only by Type A/B witness depth:

- low-depth source: `C_AB(p) < 25`;
- high-depth source: `C_AB(p) >= 25`.

Each of 12 trials again uses 160 primes per source, 80 same-source toy RSA moduli per source, and 5-fold held-out classification. The critical feature sets use only layers `k >= 25`, so the classifier cannot simply read the no-hit conditions at `k < 25` that define the high-depth source.

All three probes ran in GitHub Actions. CENTL built from the checked-out repository commit and verified the exact planted-control algebra contracts. The generated JSON, reports, receipts, and hashes were uploaded as workflow artifacts.

## 2. Why the v1 pilot was expected to separate

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

At the 39-bit workflow setting:

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

This is a useful negative result: the first exciting public signal is explained by the planted congruences.

## 5. Repeated held-out v3 result

The v3 source selection is itself defined by `C_AB`, rather than by a short list of explicit congruences. The important question is whether later Type A/B layers retain information about the early survival history, and whether any such information remains visible through `N=pq`.

### 5.1 Prime-level classification

| feature set | observed mean accuracy | approximate 95% interval for mean | shuffled-label mean |
|---|---:|---:|---:|
| full | 0.9547 | 0.9484 .. 0.9609 | 0.4945 |
| post-selection, `k >= 25` | 0.6672 | 0.6550 .. 0.6794 | 0.4904 |
| post-selection + 5, `k >= 30` | 0.6294 | 0.6104 .. 0.6485 | 0.4948 |
| shadow-compressed post-selection | 0.5167 | 0.4971 .. 0.5362 | 0.4997 |
| shadow-compressed post-selection + 5 | 0.5086 | 0.4936 .. 0.5236 | 0.5000 |

The full classifier is expected to be strong because it sees the early layers that define the labels. More interestingly, later layers alone retain substantial predictive signal: `0.6672` for `k >= 25` and `0.6294` for `k >= 30`.

However, this residual signal almost disappears when layers that are completely directly shadowed by earlier Type A/B layers are removed. The shadow-compressed post-selection classifiers are near chance.

This is not a cryptographic leak. It is evidence that congruence shadowing carries a large portion of the measurable survival-history dependence between early and later Type A/B layers.

### 5.2 Public toy-RSA classification

| feature set | observed mean accuracy | approximate 95% interval for mean | shuffled-label mean |
|---|---:|---:|---:|
| full | 0.5448 | 0.5176 .. 0.5720 | 0.4781 |
| post-selection, `k >= 25` | 0.5167 | 0.4915 .. 0.5418 | 0.5193 |
| post-selection + 5, `k >= 30` | 0.5203 | 0.4899 .. 0.5507 | 0.5036 |
| shadow-compressed post-selection | 0.5141 | 0.4984 .. 0.5297 | 0.5068 |
| shadow-compressed post-selection + 5 | 0.5141 | 0.4889 .. 0.5393 | 0.4760 |

The public post-selection classifiers are effectively at chance and track the shuffled-label baselines. The experiment therefore provides no evidence that selecting secret factors by high versus low `C_AB` leaves a useful public product-trap fingerprint in `N=pq` once the defining early-layer information is excluded.

No factorization or key-recovery result is present.

## 6. New mathematical interpretation: threshold shadowing

The v3 factor-level result suggests a sharper object than the binary label "fully shadowed layer."

Fix a survival threshold `D`. For a later layer `k >= D`, let `A_k` be the admissible hard-class candidate set and define

\[
S_{D,k}=\{a\in A_k:\text{the candidate }a\text{ is directly shadowed by at least one }j<D\}.
\]

Define the **pre-shadow load**

\[
\boxed{\sigma_D(k)=\frac{|S_{D,k}|}{|A_k|}.}
\]

If a prime satisfies `C_AB(p) >= D`, then it has escaped every layer `j<D`. Therefore it cannot occupy any candidate in `S_{D,k}` at a later layer `k`.

Thus conditioning on deep Type A/B survival deterministically removes a calculable subset of later trap classes. This gives a direct mechanism for the post-selection signal observed in v3.

The next mathematical experiment should measure the per-layer depletion in the high-depth population and compare it with `sigma_D(k)`. A strong relation would convert the classifier observation into a quantitative theorem target about conditional survivor geometry.

## 7. Current scientific interpretation

The cryptology track has now produced two successive controlled negative results for public toy-RSA leakage:

1. an explicit congruence source is easily visible until the planted congruence information is masked, after which the signal vanishes;
2. a high-`C_AB` factor source has strong factor-level survival-history structure, but its post-selection public product fingerprint is at chance.

At the same time, v3 produced a positive mathematical clue: direct-shadow compression reduces factor-level post-selection classification from `0.6672` to `0.5167` at `k >= 25`.

That observation supports the hypothesis that the shadow graph is not merely a catalogue of redundant congruences. It appears to organize a substantial part of the statistical dependence created by conditioning on survival through earlier layers.

## 8. Next work

The immediate priority is no longer to make an RSA claim. It is to explain the v3 ablation mathematically.

The research program should now:

1. compute `sigma_D(k)` for each later layer and hard residue class;
2. compare pre-shadow load against empirical later-layer depletion after conditioning on `C_AB >= D`;
3. replace the coarse product-trap public feature with correctly trained multiplicative residue likelihoods only after the factor-level dependence is understood;
4. repeat at multiple depth thresholds and bit sizes;
5. treat any public signal as a source-distribution distinguisher first, never as factor recovery without a separate algorithmic result.

## 9. Claim boundary

Current justified statement:

> The Type A/B witness-depth and shadow framework detects deliberately planted prime-source structure, and shadowing explains a substantial portion of the late-layer dependence induced by selecting primes for deep Type A/B survival. In the controlled toy-RSA experiments completed so far, the corresponding public-modulus signal collapses to chance after the defining information is excluded. No cryptographic break or key-recovery result has been demonstrated.

No result here weakens RSA or any deployed cryptosystem.
