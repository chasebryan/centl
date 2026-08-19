# CBX Lane-I spectrum-conditioned shadow census — 10,000,000 at K_I=400

**Status:** preserved exact finite spectrum-conditioned containment census  
**Date:** 2026-08-16  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora 44 GNU/Linux  
**Finite domain:** Mordell-hard primes `p <= 10,000,000`  
**Lane-I shifts:** `k = 3,7,...,399`  
**Source commit:** `3045b4ea8a37250dc561df5a8b335e22dac3365f`  
**Checkout merge commit:** `f9cf68f5a05a076bfd2e2b24a1a340d9545da66c`  
**GitHub Actions run:** `31929567354`  
**Artifact id:** `9258882222`  
**Artifact name:** `cbx-spectrum-overlap-fedora-X10000000-K400-3045b4ea8a37250dc561df5a8b335e22dac3365f`  
**Artifact ZIP digest:** `sha256:d0e7b395f16607ea22386ceb64e031f3e87f18274537602f93243180340f6800`  
**Claim boundary:** all containments below are exact only for the stated finite prime domain and spectrum slice. They are theorem targets, not universal shadow theorems and not a proof of Erdős–Straus.

---

## 1. Why condition the overlap graph by spectrum

The global finite Lane-I overlap graph through `10^7` has strong collective shadowing but no exact containment of a later layer inside any union of one, two, or three earlier global layers.

The Mordell-hard classes naturally split into three spectra:

\[
A=\{1,121\},\qquad
B=\{169,289\},\qquad
C=\{361,529\}\pmod{840}.
\]

For each shift `k` and spectrum `S`, define

\[
H_{k,S}(X)
=
\{p\in H_k(X):p\bmod840\in S\}.
\]

The question is whether global mixing hides smaller exact shadows inside one spectrum.

---

## 2. Hardened evidence protocol

An earlier Actions notice disagreed with the preserved artifact from the same run. Because that discrepancy made UI notice text untrustworthy, the spectrum research workflow was hardened.

The canonical run used **two independent implementations**:

1. `analyze_spectrum_overlap.py`, the primary analyzer;
2. an independently written integer-bitset verifier inside the workflow that reconstructs the A/B/C hit sets directly from the raw `k<TAB>p` relation and re-searches exact one-, two-, and three-earlier-layer containments.

The workflow refuses to build or upload its summary unless both implementations agree exactly.

For the canonical run, they agree.

The authoritative finite containment counts are

\[
\boxed{
A:(0,0,0),\qquad
B:(0,0,0),\qquad
C:(0,0,1)
}
\]

for exact earlier covers of size one, two, and three respectively.

The contradictory earlier UI notice is therefore retired and is not part of the research record.

---

## 3. The unique spectrum-conditioned small shadow

The only exact spectrum-conditioned containment of depth at most three is

\[
\boxed{
H_{363,C}(10^7)
\subseteq
H_{23,C}(10^7)
\cup
H_{39,C}(10^7)
\cup
H_{59,C}(10^7).
}
\]

The target layer contains exactly

\[
\boxed{|H_{363,C}(10^7)|=163}
\]

hard primes.

No one-earlier-layer or two-earlier-layer cover exists for this target in the conditioned search, so the first exact small cover found has size three.

No corresponding depth-1/2/3 containment exists in spectra A or B.

---

## 4. The triple is irreducibly three-way on the finite domain

Within the 163 target primes of `H_{363,C}`:

\[
|H_{363,C}\cap H_{23,C}|=137,
\]

\[
|H_{363,C}\cap H_{39,C}|=89,
\]

\[
|H_{363,C}\cap H_{59,C}|=117.
\]

The three possible pairs leave residuals:

\[
|H_{363,C}\setminus(H_{23,C}\cup H_{39,C})|=12,
\]

\[
|H_{363,C}\setminus(H_{23,C}\cup H_{59,C})|=4,
\]

\[
|H_{363,C}\setminus(H_{39,C}\cup H_{59,C})|=21.
\]

But the triple closes exactly:

\[
\boxed{
|H_{363,C}\setminus(H_{23,C}\cup H_{39,C}\cup H_{59,C})|=0.
}
\]

Each member supplies targets that the other two do not:

- `k=23` supplies 21 target primes exclusively relative to 39 and 59;
- `k=39` supplies 4 exclusively;
- `k=59` supplies 12 exclusively.

So none of the three can simply be deleted from this finite witness.

---

## 5. Internal overlap geometry

Writing

\[
A'=H_{363,C}\cap H_{23,C},\quad
B'=H_{363,C}\cap H_{39,C},\quad
C'=H_{363,C}\cap H_{59,C},
\]

we have

\[
|A'|=137,\quad |B'|=89,\quad |C'|=117,
\]

\[
|A'\cap B'|=75,
\qquad
|A'\cap C'|=95,
\qquad
|B'\cap C'|=64,
\]

and

\[
|A'\cap B'\cap C'|=54.
\]

The relation is therefore not a near-disjoint partition. It is a highly overlapping three-layer cover whose small residual pieces are nevertheless necessary to close the target.

---

## 6. Spectrum-wide ordered novelty

All 100 configured shifts are nonempty in each of A, B, and C on the finite domain.

The ordered novelty profile differs slightly by spectrum:

### Spectrum A

\[
\boxed{13\text{ novel layers},\quad87\text{ prior-union-shadowed layers}.}
\]

Novel shifts:

```text
3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 59
```

### Spectrum B

\[
\boxed{13\text{ novel layers},\quad87\text{ prior-union-shadowed layers}.}
\]

Novel shifts:

```text
3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 47, 51, 107
```

### Spectrum C

\[
\boxed{14\text{ novel layers},\quad86\text{ prior-union-shadowed layers}.}
\]

Novel shifts:

```text
3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 43, 47, 55, 59
```

All 73 configured layers above 107 are nonempty yet fully shadowed by the prior union within each spectrum on this finite domain.

---

## 7. Strong conditioned pairwise overlaps

Small exact shadows remain rare, but pairwise conditioned coverage can be stronger than in the global graph.

Examples of best earlier single-layer coverage include:

### Spectrum A

- `k=267` covered 80.52% by earlier `k=47`;
- `k=115` covered 80.16% by `k=23`;
- `k=363` covered 77.13% by `k=23`.

### Spectrum B

- `k=155` covered 83.19% by `k=31`;
- `k=231` covered 82.92% by `k=11`;
- `k=55` covered 82.67% by `k=11`.

### Spectrum C

- `k=363` covered 84.05% by `k=23`;
- `k=155` covered 81.98% by `k=31`;
- `k=231` covered 79.89% by `k=11`.

The `k=363` Spectrum-C target is therefore a particularly clean transition point: one earlier layer already explains 137/163 targets, a second nearly closes the set, and exactly one third layer completes it.

---

## 8. The theorem target

The finite relation suggests the symbolic goal

\[
\boxed{
H_{363,C}
\subseteq
H_{23,C}\cup H_{39,C}\cup H_{59,C}
}
\]

without the finite cutoff.

A proof would need to explain why every Spectrum-C prime hit at shift 363 must satisfy at least one of the signed-box hit conditions at shifts 23, 39, or 59.

Useful attack surfaces include:

1. residue/CRT relations linking `363`, `23`, `39`, and `59`;
2. factor-exponent characterizations of the signed boxes at those shifts;
3. reciprocity constraints specific to the two Spectrum-C hard classes `361` and `529 mod 840`;
4. splitting the 163 finite witnesses by which of 23/39/59 closes them;
5. comparing the necessary residue characters with the existing exact `k=23` two-target classification work.

The last point is especially attractive because `k=23` is already a major overlap hub and has independent theorem-oriented classification machinery elsewhere in ES+.

---

## 9. Preserved provenance and checksums

The canonical hardened artifact is GitHub Actions artifact `9258882222` from run `31929567354`.

Environment metadata records:

```text
source_commit=3045b4ea8a37250dc561df5a8b335e22dac3365f
checkout_commit=f9cf68f5a05a076bfd2e2b24a1a340d9545da66c
Fedora Linux 44 (Container Image)
```

Selected SHA-256 values:

```text
INDEPENDENT-VERIFICATION.json
  12d72f766956468976ce28d2c5f8218ff5f7ac5659fcb15718777005ac9fefce

RESEARCH-SUMMARY.json
  bed6d3ea8dd74992570b860c9ca23a920397f0931ef26cbef483b7242b02f66e

spectrum-overlap.json
  a61385a6ae6ed9971bb546460a74f3b3be331e2d5f486c852f3d3b830b924192

standalone-hit-relations.tsv
  dbe0d6ab8bf399ee22d203e7b98b76f115a905ba13e922777e9a11d406b382d4

standalone-profile.json
  2ed5d52850fb239b5dd087557249613b29332eca33df231ea24ab8f4ccf12e43
```

Artifact ZIP digest:

```text
sha256:d0e7b395f16607ea22386ceb64e031f3e87f18274537602f93243180340f6800
```

---

## 10. Reproduction

```sh
./centl es cbx standalone-i \
  --hi 10000000 \
  --i-max 400 \
  --segment 1000000 \
  --sets standalone-hit-relations.tsv \
  > standalone-profile.json

./centl es cbx analyze-spectrum-overlap \
  standalone-hit-relations.tsv \
  --json > spectrum-overlap.json
```

For publication-grade research runs, use the hardened spectrum workflow, which independently recomputes all depth-1/2/3 conditioned containments from the raw relation before it permits artifact upload.

---

Erdős–Straus remains open. This is an exact finite spectrum-conditioned theorem target, not a proof.