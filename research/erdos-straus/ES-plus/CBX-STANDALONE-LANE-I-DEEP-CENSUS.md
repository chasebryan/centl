# CBX standalone Lane-I deep census - 10,000,000 at K_I=400

**Status:** preserved exact finite intrinsic-layer census  
**Date:** 2026-08-16  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora 44 GNU/Linux  
**Finite domain:** Mordell-hard primes `p <= 10,000,000`  
**Lane-I shifts:** every admissible `k = 3,7,...,399` tested independently  
**Source commit:** `aa259cebe28beba519197daf550cacab96cad16d`  
**Checkout merge commit:** `23915a6974a683b234dfb9fe35301c1206d9513e`  
**GitHub Actions run:** `31928579778`  
**Artifact id:** `9258600538`  
**Artifact name:** `cbx-standalone-fedora-X10000000-K400-aa259cebe28beba519197daf550cacab96cad16d`  
**Artifact ZIP digest:** `sha256:04266d1816d340f551f7f07e0198419ccb922f67d4cff87658081a2c0d37406e`  
**Claim boundary:** this note measures finite intrinsic layer strength with overlaps allowed. It does not give first-hit depths, does not prove layer redundancy or absorption, does not prove an adaptive K law, and does not prove Erdős-Straus.

---

## 1. Why standalone layers are a different object

The ordinary survivor profile asks a marginal question:

> after every smaller admissible shift has already had its chance, how many previously unresolved targets does this k solve first?

That quantity defines the first-hit depth distribution.

The standalone profile asks a different question:

> if this k were tested independently against the complete finite hard-prime universe, how many targets would it hit?

For a shift `k`, write its finite intrinsic hit set as

\[
H_k(X)=\{p\le X: p\text{ is Mordell-hard prime and }\delta_k((p+k)/4)=0\}.
\]

The standalone census measures

\[
|H_k(10^7)|
\]

for every admissible `k <= 400`, without removing targets hit by earlier shifts.

This distinction is essential:

\[
\boxed{\text{marginal first-hit contribution} \ne \text{intrinsic layer strength}.}
\]

A shift can contribute zero new first hits only because its entire finite hit set is already covered by earlier layers.

---

## 2. The main finite result

The finite target universe contains

\[
\boxed{20,513}
\]

Mordell-hard primes through `10,000,000`.

There are 100 admissible shifts

\[
3,7,11,\ldots,399.
\]

Every one of them is intrinsically productive:

\[
\boxed{100/100\text{ standalone layers have at least one hit}.}
\]

Therefore

\[
\boxed{\text{zero standalone-hit layers}=0.}
\]

The result above the observed marginal frontier is even more striking. There are 73 admissible shifts with

\[
k>107,
\]

and all 73 are intrinsically productive:

\[
\boxed{73/73\text{ shifts above }107\text{ hit hard primes independently}.}
\]

So the fact that no first-hit layer above 107 appears in the K=400 survivor census is not evidence that those layers are weak or empty. It is evidence that their finite hit sets overlap the cover already accumulated by smaller shifts.

---

## 3. Strong layers exist well beyond the first-hit frontier

The strongest standalone layers above 107 include:

| k | standalone hits | hit rate of all 20,513 hard primes |
|---:|---:|---:|
| 119 | 12,345 | 0.6018134841 |
| 111 | 10,439 | 0.5088967972 |
| 191 | 10,142 | 0.4944181738 |
| 167 | 9,818 | 0.4786233120 |
| 311 | 9,811 | 0.4782820650 |
| 215 | 9,685 | 0.4721396188 |
| 143 | 9,483 | 0.4622922049 |
| 159 | 9,234 | 0.4501535612 |
| 239 | 8,785 | 0.4282650027 |
| 335 | 7,968 | 0.3884366012 |

Thus a shift can lie far beyond the observed first-hit record and still solve a large fraction of the entire finite hard-prime universe when examined independently.

For example,

\[
\boxed{|H_{119}(10^7)|=12,345,}
\]

which is more than 60% of all hard primes in the census.

---

## 4. The strongest layers overall

The largest intrinsic standalone hit counts in the complete `k <= 400` census are:

| k | standalone hits | hit rate |
|---:|---:|---:|
| 23 | 13,860 | 0.6756690879 |
| 47 | 13,553 | 0.6607029688 |
| 11 | 13,417 | 0.6540730269 |
| 31 | 13,152 | 0.6411543899 |
| 71 | 12,960 | 0.6317944718 |
| 39 | 12,769 | 0.6224833033 |
| 119 | 12,345 | 0.6018134841 |
| 95 | 11,300 | 0.5508701799 |
| 59 | 10,680 | 0.5206454444 |
| 55 | 10,521 | 0.5128942622 |
| 111 | 10,439 | 0.5088967972 |
| 19 | 10,186 | 0.4965631551 |

The strongest single finite standalone layer is

\[
\boxed{k=23,\qquad |H_{23}(10^7)|=13,860.}
\]

That is about 67.57% of the hard-prime universe.

This ranking is intrinsic, not marginal. It should not be confused with the first-hit order, where early layers have already removed many targets before later layers are evaluated.

---

## 5. The first-hit record layer is not intrinsically exceptional

The marginal K=400 census found one finite record prime first hit at

\[
k=107.
\]

But standalone `k=107` is not a one-prime phenomenon. It independently hits

\[
\boxed{4,461}
\]

of the 20,513 hard primes, a rate of

\[
\boxed{0.2174718471.}
\]

Its spectrum breakdown is

\[
A=1,499,\qquad B=1,494,\qquad C=1,468.
\]

The special role of 107 in the first-hit census therefore comes from **cover order and overlap**, not from 107 being intrinsically the only useful late shift.

---

## 6. Even the weakest measured layers are nonempty

The smallest standalone layers in this finite census include:

| k | hits | hit rate |
|---:|---:|---:|
| 387 | 519 | 0.0253010286 |
| 363 | 679 | 0.0331009604 |
| 315 | 807 | 0.0393409058 |
| 267 | 869 | 0.0423633793 |
| 307 | 981 | 0.0478233315 |
| 379 | 981 | 0.0478233315 |
| 283 | 1,005 | 0.0489933213 |
| 331 | 1,207 | 0.0588407351 |
| 243 | 1,282 | 0.0624969532 |
| 355 | 1,346 | 0.0656169259 |

Even the weakest measured layer, `k=387`, hits 519 hard primes independently.

Again, finite nonemptiness is not a theorem of asymptotic density. It simply demonstrates that every configured layer has genuine finite arithmetic content.

---

## 7. Aggregate overlap is enormous

Because standalone layers overlap, one hard prime may contribute a hit event to many shifts.

Across all 100 layers, the census records

\[
\boxed{534,037\text{ standalone hit events}.}
\]

Every layer visits all 20,513 hard-prime targets, so the standalone workload contains

\[
\boxed{2,051,300\text{ target visits}}
\]

and the same number of signed-box factorizations.

The average standalone layer therefore hits

\[
\frac{534,037}{100}=5,340.37
\]

hard primes.

Equivalently, counting multiplicity across layers, the average hard prime participates in about

\[
\frac{534,037}{20,513}\approx26.03
\]

standalone hit events among the 100 shifts.

This is direct finite evidence that the signed-box cover has substantial overlap.

---

## 8. Spectrum hit events

Across all standalone layers, spectrum hit events total

\[
\boxed{
A=173,607,
\qquad
B=181,895,
\qquad
C=178,535.
}
\]

These counts include overlap across shifts. They are not counts of unique primes.

Individual layers can have noticeable spectrum preferences. For example:

- `k=111`: A=3,022, B=4,161, C=3,256;
- `k=191`: A=2,679, B=4,118, C=3,345;
- `k=311`: A=2,076, B=3,808, C=3,927;
- `k=199`: A=2,146, B=1,297, C=2,899;
- `k=231`: A=1,027, B=3,004, C=2,193.

This makes spectrum-conditioned overlap a natural next research variable.

---

## 9. What the two deep censuses say together

The marginal first-hit census at the same finite domain and grade says:

- all 20,513 hard primes are covered;
- only 16 shifts contribute first hits;
- the deepest first hit is 107;
- nothing above 107 contributes new marginal cover because the survivor frontier is empty.

The standalone census says:

- all 100 shifts are intrinsically productive;
- all 73 shifts above 107 are intrinsically productive;
- many late layers hit thousands of hard primes independently.

Together they imply the finite decomposition

\[
\boxed{
\text{late-layer marginal silence}
=
\text{overlap with earlier cover},
}
\]

not

\[
\text{late-layer emptiness}.
\]

The next theoretical question is therefore not merely whether a late layer hits anything. It is to characterize **containment and overlap relations among the sets**

\[
H_k(X).
\]

In particular, a finite marginally dead layer `k` invites the question

\[
H_k(X)\subseteq\bigcup_{j<k}H_j(X)?
\]

which is true by construction on the measured finite domain when it contributes no first hit. The research challenge is to determine when such containment follows from a structural arithmetic reason rather than only from finite enumeration.

This connects directly to the existing shadowing/absorption program.

---

## 10. Consequences for the hybrid planner

Standalone strength must not be used to skip a shift. A strong overlapping layer may be redundant only after certain earlier layers, and that finite relationship need not persist outside the measured domain.

The safe use of standalone data is instead:

1. distinguish zero marginal novelty from zero intrinsic strength;
2. identify high-overlap layers for absorption/shadowing theorem searches;
3. condition planner research on both marginal first-hit yield and intrinsic hit density;
4. look for spectrum-specific containment;
5. test whether a small structural basis of layers explains the observed cover without promoting finite containment to a theorem.

The measured hybrid planner therefore retains

```text
must_evaluate_for_exact_cover = true
```

for every shift unless a separate proof removes it.

---

## 11. Preserved provenance and checksums

The canonical artifact is GitHub Actions artifact `9258600538` from run `31928579778`.

Environment metadata records:

```text
source_commit=aa259cebe28beba519197daf550cacab96cad16d
checkout_commit=23915a6974a683b234dfb9fe35301c1206d9513e
Fedora Linux 44 (Container Image)
GCC 16.1.1
Python 3.14.6
```

Checksums inside the preserved artifact:

```text
ENVIRONMENT.txt
  a41edc5d59f1ce4fbc1d81582224d2efdac86d78b9d5eeaf98d710568ae5e7f4

RESEARCH-SUMMARY.json
  661b04b09facdecf56d940445b7194d8b05dc895db87eb9b7fe7ae3cedb90e13

standalone-analysis.json
  d1624083ace344b33e994e2ae08b5de268a8aceb745a8a67bf1a6a8dd163b812

standalone-profile.json
  b7926616d4887a5a67735df5bb34c41dce5804b60da5ec13a2a3ac7f55f47612
```

Artifact ZIP digest:

```text
sha256:04266d1816d340f551f7f07e0198419ccb922f67d4cff87658081a2c0d37406e
```

---

## 12. Reproduction

```sh
make -C research/erdos-straus/cbx.kernel cbx-standalone-i

./centl es cbx standalone-i \
  --hi 10000000 \
  --i-max 400 \
  --segment 1000000 \
  > standalone-profile.json

./centl es cbx analyze-standalone \
  standalone-profile.json \
  --json \
  > standalone-analysis.json
```

---

Erdős-Straus remains open. This census measures finite intrinsic layer strength and overlap; it is not a proof.