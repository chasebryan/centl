# CBX Lane-I deep census — 10,000,000 at K_I=400

**Status:** preserved exact finite research census  
**Date:** 2026-08-16  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora 44 GNU/Linux  
**Finite domain:** Mordell-hard primes `p <= 10,000,000`  
**Lane-I ceiling:** `K_I = 400`  
**Source commit:** `ac75b35ea7aed0ef8f01a1b6ab71b6e9a7322e57`  
**Checkout merge commit:** `bca4c08aff1e5cee0968954a4668c2efa6f24f12`  
**GitHub Actions run:** `31928371046`  
**Artifact id:** `9258532312`  
**Artifact name:** `cbx-fedora-X10000000-K400-ac75b35ea7aed0ef8f01a1b6ab71b6e9a7322e57`  
**Artifact ZIP digest:** `sha256:a9be223d639176c651a918c0f6a197c1e97e80831e5ce78abe6c7886e9a79d1f`  
**Claim boundary:** all claims below are finite. This note does not prove a universal K bound, an adaptive-K law, asymptotic superiority of an algorithmic orientation, or Erdős–Straus.

---

## 1. Exact finite result

There are exactly

\[
\boxed{20,513}
\]

Mordell-hard prime targets through `10,000,000` in the census domain.

Three independent finite Lane-I traversals were executed:

\[
\text{p-major}: p\to k\to C,
\]

\[
\text{target-gated C-major}: k\to C\to p,
\]

and

\[
\text{shift-major}: k\to p\to C.
\]

Their exact `p -> k_I^*(p)` hit maps were compared independently after execution and agree target-for-target and depth-for-depth.

The result is

\[
\boxed{20,513/20,513\text{ covered}}
\]

with

\[
\boxed{0\text{ Lane-I residuals through }K_I=400.}
\]

Both non-reference traversals also performed their own internal `--verify` pass against p-major recognition and recorded zero mismatches.

The canonical residual file is empty. Its SHA-256 is therefore the standard empty-file digest:

```text
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

Finite empty residual is finite coverage only. It is not a proof of the conjecture.

---

## 2. K=400 does not move the observed finite frontier past 107

Exactly 16 shifts contribute a first hit somewhere in this finite corpus:

\[
\boxed{
3,7,11,15,19,23,27,31,35,39,43,47,51,55,59,107.
}
\]

No shift from `111` through `399` contributes anything because the active frontier is already empty after the hit at 107.

The deepest productive shift remains

\[
\boxed{k_I^*=107.}
\]

The finite first-hit depth quantiles are

\[
\boxed{
\operatorname{p50}=7,
\qquad
\operatorname{p90}=15,
\qquad
\operatorname{p99}=31.
}
\]

Thus, on this finite domain, 99% of Mordell-hard primes are already hit no later than `k=31`, while one exceptional survivor reaches `k=107`.

This does **not** establish 107 as a universal bound.

---

## 3. Exact productive-layer counts

The largest first-hit layers are:

| k | first hits | factorizations | compatible C candidates |
|---:|---:|---:|---:|
| 3 | 8,590 | 20,513 | 71,429 |
| 7 | 4,779 | 11,923 | 71,429 |
| 11 | 4,463 | 7,144 | 71,429 |
| 15 | 949 | 2,681 | 71,429 |
| 19 | 883 | 1,732 | 71,429 |
| 23 | 541 | 849 | 71,429 |
| 31 | 152 | 217 | 71,429 |
| 27 | 91 | 308 | 71,429 |
| 39 | 22 | 48 | 71,429 |
| 35 | 17 | 65 | 71,429 |
| 47 | 15 | 21 | 71,429 |
| 43 | 5 | 26 | 71,429 |

The remaining productive shifts are `51`, `55`, `59`, and `107`.

The early layers dominate raw coverage. Later layers can nevertheless have high conditional efficiency because they act on a tiny survivor frontier. That distinction matters when interpreting per-shift ratios.

---

## 4. Spectrum distribution

Across all 20,513 first hits, the A/B/C totals are nearly balanced:

\[
\boxed{
A=6,857,
\qquad
B=6,854,
\qquad
C=6,802.
}
\]

For the largest early layers:

| k | A | B | C |
|---:|---:|---:|---:|
| 3 | 2,989 | 2,977 | 2,624 |
| 7 | 1,531 | 1,569 | 1,679 |
| 11 | 1,398 | 1,514 | 1,551 |
| 15 | 319 | 297 | 333 |
| 19 | 354 | 219 | 310 |
| 23 | 167 | 182 | 192 |
| 31 | 40 | 55 | 57 |
| 27 | 32 | 22 | 37 |

There is no obvious whole-corpus spectrum monopoly in this finite census. Spectrum-specific behavior remains a useful conditional feature rather than a simple global partition into easy and hard classes.

---

## 5. The one-prime gauntlet

After `k=59`, exactly one target remains unresolved.

It survives each of

\[
63,67,71,75,79,83,87,91,95,99,103
\]

and then first hits at

\[
107.
\]

The unique finite record prime is

\[
\boxed{p=8,803,369.}
\]

Therefore the eleven shifts

\[
\boxed{
63,67,71,75,79,83,87,91,95,99,103
}
\]

are the exact finite **dead-with-factorization** set in this run: each performs one signed-box factorization on the sole remaining target and contributes zero new coverage.

This is not a theorem that those shifts are universally redundant. It is a local vacancy sequence for one finite survivor.

---

## 6. Exact expensive-work equality across orientations

The p-major reference performs exactly

\[
\boxed{45,553}
\]

signed-box factorizations.

The target-gated C-major implementation also performs exactly

\[
\boxed{45,553},
\]

and shift-major performs exactly

\[
\boxed{45,553}.
\]

Hence

\[
\boxed{
\rho_F^{\rm C-major}=1,
\qquad
\rho_F^{\rm shift}=1.
}
\]

Shift-major also has exactly the same number of active `(p,k)` visits as p-major has shift candidates. The two traverse the same expensive finite work set in a different order.

---

## 7. C-major enumeration is the remaining computational tax

Although target gating recovers the exact p-major factorization set, C-major must still enumerate

\[
\boxed{7,142,900}
\]

compatible C candidates across 100 admissible shifts from `3` through `399`.

Relative to the 45,553 expensive factorizations actually needed,

\[
\boxed{
\rho_C
=
\frac{7,142,900}{45,553}
=156.80416218470793.
}
\]

This is the clearest current computational diagnosis:

> target gating solved the expensive-factorization waste, but it did not solve the C-enumeration geometry.

A genuinely faster C-major engine therefore needs additional structure **before** generic enumeration, ideally a way to generate or strongly filter the condition `delta_k(C)=0` itself.

---

## 8. Fedora timing benchmark

The provenance-clean three-repeat medians on this Fedora run were:

```text
p-major      0.101051157 s
C-major      0.138304172 s
shift-major  0.101046738 s
```

Thus

\[
\boxed{
\rho_t^{\rm C-major}=1.368655007087196
}
\]

and

\[
\boxed{
\rho_t^{\rm shift}=0.9999562696743819.
}
\]

The shift-major timing is indistinguishable from p-major for practical purposes. The exact work-set equality is the meaningful result; the tiny sub-1 timing ratio is not treated as evidence of a universal speed advantage.

The C-major penalty is consistent with the 156.8x cheap-candidate enumeration burden.

---

## 9. Why K=400 still matters when the last hit is 107

The run was intentionally performed with

\[
K_I=400,
\]

not merely `107`.

That stronger finite grade establishes that:

1. every hard prime in the finite domain has already hit by 107;
2. the full configured search surface through 399 was available;
3. the active frontier becomes empty after 107, so all larger configured shifts are vacuous in this finite census;
4. the result is therefore not an artifact of stopping the experiment exactly at the observed record.

What it does **not** establish is that a new prime above `10^7` cannot require `k>107`.

The finite statement is

\[
\boxed{
K_{\min}^{\rm obs}(10^7)=107
}
\]

for the stated hard-prime domain and Lane-I definition.

---

## 10. Consequences for the hybrid design

The deep profile changes the engineering question.

The productive set is sparse:

\[
16/100
\]

configured admissible shifts contribute a first hit, and only 27 shifts perform any factorization before the frontier disappears.

However, simply hard-coding the observed productive set would be scientifically invalid outside the measured domain.

The appropriate next layer is a **measured planner**, not an oracle. A hybrid planner should accept a per-shift profile and explicit cost assumptions, then report candidate orientations and sensitivity without changing mathematical semantics.

Useful finite costs include:

- active survivor visits;
- compatible C enumeration count;
- factorizations;
- first-hit yield;
- spectrum-specific yield;
- marginal new cover;
- zero-marginal work.

A future implementation may choose among

\[
\boxed{
\text{C-major generation},
\quad
\text{shift-major traversal},
\quad
\text{p-major recognition}
}
\]

per shift, but any such policy remains an empirical scheduling rule until separately justified.

---

## 11. Preserved provenance and checksums

The canonical artifact is GitHub Actions artifact `9258532312` from run `31928371046`.

Environment metadata records:

```text
source_commit=ac75b35ea7aed0ef8f01a1b6ab71b6e9a7322e57
checkout_commit=bca4c08aff1e5cee0968954a4668c2efa6f24f12
Fedora Linux 44 (Container Image)
GCC 16.1.1
Python 3.14.6
```

Selected artifact checksums:

```text
RESEARCH-SUMMARY.json
  a50e7ac10af426b667c355bab300f1634ed2b6894dacdcb3f688dad602aa68d8

canonical-hits.tsv
  6ff6eacce5c4baa92bda69a530c77a3343994541bf0d6e4e4020bd912f76ed9d

canonical-residuals.txt
  e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

inverse-layers.tsv
  0e933c5b16b3aeb28c2dc28174c6f21bffe35402bf46ff228d1a500e62fa72cd

layer-analysis.json
  0df782b24cd4d08cfd3be3b75ed9f74827026867c6dfaca0754d5803dd2018fa

orientation-benchmark.json
  f3527924edd5abfadcfb3a4178491f54fdc79209fd9afc423af5bfe3cad55047

shift-profile.json
  e498e213315c30a3ed7dbf418d8a56813954cc653446c56c54b5396987b11f18

shift-profile-analysis.json
  bf89cdb0acf32608e05498dee84bceb6d05a7b96f1cdb8c78f6ecdcaea837c73
```

Artifact ZIP digest:

```text
sha256:a9be223d639176c651a918c0f6a197c1e97e80831e5ce78abe6c7886e9a79d1f
```

---

## 12. Reproduction

The research workflow defaults now reproduce this grade:

```text
HI=10000000
I_MAX=400
SEGMENT=1000000
REPEAT=3
```

The constituent commands are equivalent to:

```sh
./centl es cbx inverse \
  --hi 10000000 --i-max 400 --segment 1000000 \
  --verify --layers inverse-layers.tsv \
  --hits inverse-hits.tsv --residuals inverse-residuals.txt

./centl es cbx shift-i \
  --hi 10000000 --i-max 400 --segment 1000000 \
  --verify --hits shift-hits.tsv --residuals shift-residuals.txt

./centl es cbx profile-i \
  --hi 10000000 --i-max 400 --segment 1000000

./centl es cbx forward-i \
  --hi 10000000 --i-max 400

./centl es cbx bench \
  --hi 10000000 --i-max 400 --segment 1000000 --repeat 3
```

The workflow additionally requires exact set/map identity before preserving the artifact.

---

Erdős–Straus remains open. This is a strong finite census, not a proof.