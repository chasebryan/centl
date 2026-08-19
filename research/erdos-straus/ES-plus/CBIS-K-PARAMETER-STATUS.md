# cbis.kernel 1.2.0 — K parameter status and CB X-ray plan

**Status:** research subnote / implementation plan  
**Date:** 2026-08-15  
**Program:** ES+  
**Kernel under analysis:** `cbis.kernel 1.2.0`  
**Successor research instrument:** `cbx.kernel` — CB X-ray Kernel  
**Claim boundary:** this note does not prove Erdős–Straus, does not prove the ES+ letter spectrum is empty, and does not assert a universal finite bound for K.

---

## 1. Executive finding

`cbis.kernel 1.2.0` is a sound operational letter engine built around two walks and one stacked cover:

\[
\text{Mordell-hard prime}
\longrightarrow W
\longrightarrow I
\longrightarrow N
\longrightarrow L
\longrightarrow \text{LETTER}.
\]

The sweep walks the line of hard primes. The home walk generates the residual

\[
R=\{p:\ p+4\in\Sigma_1,\ 4p+1\in\Sigma_1\},
\]

where both linear W clauses miss. This is the correct place to aim the expensive work.

Version 1.2.0 does not strengthen the mathematical cover relative to 1.1.0. Its main release change is the fixed live panel. The hunt mathematics remains the same.

The important conclusion is that the scalar `K` displayed by `cbis.kernel` is **not the full search grade**, and at the current empirical frontier it is not even the dominant operational bottleneck. The W/fab layer is.

Through the ranges already censused, a substantial fraction of hard primes enters `R`, but the fixed coprime `fab(a,b)` window with `a,b <= 11` finishes every observed member of `R`. Consequently the I/N/L lanes rarely or never receive live survivors in the observed range.

The next research kernel should therefore not weaken W and should not merely raise K. It should look *through* W and measure what I/N/L would have done anyway.

That kernel is named:

> **`cbx.kernel` — CB X-ray Kernel**

`cbis.kernel` remains the production letter engine. `cbx.kernel` is the research instrument.

---

## 2. What K is in cbis.kernel 1.2.0

The implementation defines

```c
#define DEFAULT_KMAX 400ull
```

and allows the operator to override the value with

```text
--k-max K
```

The value is stored in the seed and reused by both the sweep and the home walk.

There is no internal equation that computes K from p, the spectrum, the defect, the lane, or the current frontier. K is presently an operator-supplied constant.

### 2.1 Lane I

Lane I consumes K directly in

```c
in_signed_box_cover(p, K)
```

and checks admissible shifts

\[
k\equiv3\pmod4,
\qquad
3\le k\le K.
\]

For each shift it forms

\[
C_k=\frac{p+k}{4}
\]

and evaluates the signed-box vacancy criterion. A zero vacancy is a genuine Type I or Type II hit.

Thus K in Lane I is a **signed-box shift bound**.

### 2.2 Lane L

Lane L consumes the same scalar in

```c
in_lopez_cover(p, K)
```

but here the loop variable is a López layer index `a` with

\[
1\le a\le K
\]

and prime modulus

\[
m=4a-1.
\]

Therefore K has a different mathematical role in Lane L. At `K=400`, Lane L can inspect prime moduli as large as

\[
4\cdot400-1=1599.
\]

### 2.3 Lane N

Lane N is not controlled by K at all. It uses

```c
#define NR_ELL_MAX 300ull
```

and may deliberately create signed-box shifts `k > K`.

The source correctly describes Lane N as a cover-strengthening lane that may exceed the nominal K bound.

### 2.4 W/fab

W is likewise not governed by K in the implementation. It consists of the two linear clauses and the fixed coprime `fab(a,b)` menu with `a,b <= 11`.

Therefore a run advertised only by `K=400` is underspecified as a reproducible finite-search certificate.

---

## 3. The actual finite search grade

The implementation is more faithfully represented by a search-grade vector

\[
\boxed{
\Gamma=(F,K_I,E_N,A_L)
}
\]

with the current defaults approximately

\[
\boxed{
\Gamma=(11,400,300,400).
}
\]

Here

- `F` is the fab edge, currently `a,b <= 11`;
- `K_I` is the Lane-I signed-box shift bound;
- `E_N` is the Lane-N external nonresidue prime bound;
- `A_L` is the Lane-L López layer bound.

The current program happens to tie

\[
K_I=A_L=K,
\]

but this is an implementation choice rather than a theorem.

A future adaptive design should not assume those coordinates must remain identical.

The grade should also carry the kernel version and any named adaptive rule, so a complete experimental certificate is conceptually

\[
\boxed{
G=(\text{kernel},\text{version},F,K_I,E_N,A_L,\text{rule}).
}
\]

---

## 4. Why K is currently behind W

The W census decomposes W into three genuine covers:

1. the `4p+1` linear identity;
2. the `p+4` linear identity;
3. the fixed `fab(a,b)` menu.

The two linear clauses miss exactly on the residual

\[
R=\{p:\ p+4,4p+1\in\Sigma_1\}.
\]

Finite census through `10^8` found that about 27 percent of Mordell-hard primes reach R, but every observed point of R is subsequently hit by fab. Larger runs have displayed the same qualitative pattern.

Since `cbis.kernel` evaluates W before I/N/L, the scalar K has no opportunity to affect the verdict whenever fab closes the residual first.

This is not a reason to weaken W. Every W clause is a genuine construction, and weakening W would flood the later lanes with primes that are already solved.

The correct response is instrumentation:

> keep the production verdict exactly as it is, but measure the hidden I/N/L behavior even for primes that W has already solved.

---

## 5. Important implementation findings in cbis.kernel 1.2.0

### 5.1 `solve` does not inherit the saved K

The running hunt stores `seed.kmax` and honors `--k-max`, but `cmd_solve()` currently evaluates

```c
in_cover_forward(n, DEFAULT_KMAX)
```

rather than the K stored in the seed or a K supplied to `solve`.

Thus a hunt can run at `K=800` while

```text
cbis solve N
```

still reports the `K=400` verdict.

This is a reproducibility defect in the operator surface. It does not invalidate the stored finite search, but it means `solve` is not presently a faithful query of a non-default hunt grade.

`cbx.kernel` must not inherit this behavior.

### 5.2 ES-LETTER-v1 identifies the event, not the finite grade

The ES-LETTER-v1 identity is computed from

```text
ES-LETTER-v1
rule=unsolved_after_search
n=<prime>
extra=
```

The finite grade is not part of the ID.

That can remain desirable if the content-addressed ID denotes the mathematical event/subject associated with a prime. But it means the exact finite-search certificate must be stored separately.

A prime can in principle survive one finite grade and be killed by a stronger grade. Therefore the new kernel will preserve the ES-LETTER-v1 identity scheme while attaching a distinct, explicit grade record.

### 5.3 Existing letter files can outlive a changed K

`save_letter()` returns immediately when the content-addressed letter file already exists. The file nevertheless contains a printed K value. Changing K on an existing seed does not rewind the sweep and does not rewrite prior letters.

A single directory can therefore become a mixture of findings generated under different finite strengths unless the grade is tracked externally.

`cbx.kernel` will record the grade on every observation and will never treat a mixed-grade corpus as a single homogeneous certificate.

### 5.4 Sweep and home can encounter the same prime

The two walks are intentionally overlapping discovery mechanisms. The content-addressed file prevents duplicate letter files, but the caller can increment `letters_found` even when the file already existed.

The new kernel will distinguish

- observation count;
- unique target count;
- unique letter count.

### 5.5 Home batch endpoint repeats

The current home walk stores `home_S = S1`, and the next batch begins at that same value. With the ordinary step geometry, the endpoint can be revisited.

The new kernel will use a strict next-cursor convention so every generated S is visited once per walk.

### 5.6 Exact factorization has a future frontier

The current factorizer trial-divides using a sieve through roughly `10^6` and then treats the remaining cofactor as one factor. This is safe while the remaining composite cannot contain two prime factors both exceeding the sieve limit, but it is not a general exact 64-bit factorizer.

For an indefinitely growing kernel this becomes a correctness boundary. Because fab can factor quantities on the scale of `11p`, the implementation should be upgraded before the hunt approaches roughly `10^11`.

`cbx.kernel` will use deterministic 64-bit Miller–Rabin together with Pollard rho recursion so factorization remains exact across the full unsigned 64-bit domain supported by the arithmetic.

---

## 6. Why cbis is not yet computationally inverse in Lane I

The ES+ letter equation defines the true inverse orientation:

for each admissible k, generate C with

\[
\delta_k(C)=0,
\]

form

\[
p=4C-k,
\]

and mark the resulting hard primes. The unmarked primes form the finite letter spectrum.

Current `cbis.kernel` recognizes the same set but still begins from p:

\[
p\to k\to C.
\]

Its Lane-I routine is correctly described in the source as the **recognition form** of \(\mathcal C_K\).

This is not a correctness error. It means there is still an unexploited algorithmic inversion available for a later generator-oriented kernel.

`cbx.kernel` begins as an observational successor, not as a replacement for that future fully inverted generator.

---

## 7. The CB X-ray kernel

### 7.1 Purpose

`cbx.kernel` is a separate ES+ research engine whose job is to expose the hidden geometry beneath the production cover.

It does **not** weaken W and does **not** alter `cbis.kernel` letter semantics.

For every target it can record both:

1. the production verdict under the stacked W -> I -> N -> L order;
2. the counterfactual/diagnostic result of each lane independently.

Thus a prime killed immediately by W can still be examined by I, N and L.

### 7.2 First-hit depth measurements

For Lane I define

\[
\boxed{
k_I^*(p)=
\min\{k\equiv3\pmod4:\delta_k((p+k)/4)=0\}.
}
\]

If there is no hit through the configured probe ceiling, record infinity/truncation rather than falsely declaring nonexistence.

For Lane L define the first López layer

\[
\boxed{
a_L^*(p)=
\min\{a:\text{López A/B hits at layer }a\}.
}
\]

For Lane N record the first external nonresidue prime and the realized shift that produces the hit.

For W record

- first linear clause hit, if any;
- membership in R;
- first fab pair in deterministic menu order;
- whether the point is fab-only.

### 7.3 Spectrum stratification

Every observation is tagged by the existing A/B/C hard spectrum. This permits depth distributions such as

\[
P(k_I^*>t\mid\text{spectrum A}),
\]

and comparison against R/fab-only strata.

### 7.4 Factor and defect metadata

Where affordable, observations should record compact structural metadata sufficient to correlate first-hit depth with

- factor count and exponent pattern of \((p+k)/4\);
- signed-box cardinality;
- defect/stabilizer signatures already defined in the ES+ papers;
- external nonresidue mass statistics;
- spectrum and residue information.

The first implementation records the exact depth and basic factor signature. Richer Kneser diagnostics can be layered without changing the observation format major version.

---

## 8. Adaptive K research

No universal theorem currently supplies an equation

\[
K=K(p)
\]

that is guaranteed to capture every prime.

Therefore the production hunt should not silently replace its fixed K by an unproved adaptive rule.

Instead `cbx.kernel` will support named **experimental policies** whose status is explicit.

Candidate families include

\[
K(p)=\lceil c\log p\rceil,
\]

\[
K(p)=\lceil c(\log p)^2\rceil,
\]

spectrum-dependent functions

\[
K(p)=K_{\sigma(p)}(p),
\]

and empirically fitted envelopes derived from observed first-hit depths.

Every adaptive policy must record

- policy name/version;
- realized K for the target;
- global probe ceiling;
- whether the policy verdict is observational or theorem-backed.

An adaptive policy is not promoted to production semantics until a theorem justifies the promotion.

---

## 9. Empirical-to-theorem workflow

The X-ray program deliberately reverses the usual temptation to guess K first.

### Stage 1 — measure

Run I/N/L through W-hit primes and collect the hidden depth distribution.

### Stage 2 — stratify

Condition the distribution on

- A/B/C spectrum;
- R vs non-R;
- fab-only vs linear;
- factor structure;
- defect and stabilizer signatures.

### Stage 3 — fit an envelope

Search for an empirical upper envelope

\[
k_I^*(p)\le f(p,\sigma,\text{defect data})
\]

that is dramatically smaller than an arbitrary fixed ceiling.

### Stage 4 — prove or break

Use the signed-box, Kneser-defect, reciprocity and spectrum theory to either prove the candidate envelope or construct an exact counterexample to it.

### Stage 5 — promote

Only a proved rule becomes eligible to define a future production grade.

---

## 10. Preservation and compatibility rules

1. `cbis.kernel 1.2.0` remains frozen as the current production letter engine.
2. `cbx.kernel` lives in a separate directory and has a separate seed/state/output namespace.
3. X-ray observations are not ES letters.
4. A production-equivalent miss can still be emitted with the existing ES-LETTER-v1 identity, but the complete grade is stored beside it.
5. The X-ray format is append-friendly and content-stable enough to combine results from multiple machines.
6. Every observation records its kernel version and grade.
7. Experimental adaptive policies are explicitly labeled experimental.
8. No finite X-ray census is presented as an Erdős–Straus proof.

---

## 11. Immediate implementation scheme

The first complete `cbx.kernel` implementation should contain:

- exact deterministic 64-bit primality;
- Pollard-rho factorization for exact 64-bit factor decomposition;
- the same Mordell-hard and A/B/C spectrum classifiers;
- W linear, R and fab instrumentation;
- independent Lane-I first-hit search;
- independent Lane-N first-hit search;
- independent Lane-L first-hit search;
- production stacked verdict for comparison;
- explicit grade vector rather than an ambiguous scalar K;
- fixed and experimental adaptive-K policy hooks;
- sweep and R-home walks with non-overlapping cursors;
- deduplicated observation and letter accounting;
- JSONL observation output;
- exact ES-LETTER-v1 compatibility for genuine stacked misses;
- `solve`/`probe` commands that honor the requested or saved grade;
- self-tests covering factorization, primality, known ES targets, cursor behavior and grade semantics;
- a compact dashboard that distinguishes **verdict lanes** from **X-ray lanes**.

The initial implementation may reuse theorem-level routines from cbis, but it must not share writable state with cbis.

---

## 12. Research priority

The immediate mathematical priority is not to increase K blindly.

The high-value experiment is to expose the data currently hidden by W:

\[
\boxed{
\text{measure }k_I^*(p),\ a_L^*(p),\text{ and N-depth even when W already wins.}
}
\]

That dataset can answer whether a natural K law is present at all.

If a low-growth envelope emerges, the defect/spectrum papers provide the machinery with which to attack it theoretically. If no stable envelope emerges, that negative result is itself valuable and prevents the production engine from being built around a misleading adaptive heuristic.

For now:

\[
\boxed{
W/\mathrm{fab}\text{ is the observed operational frontier; K is a research coordinate, not the frontier itself.}
}
\]

---

Erdős–Straus remains open. A finite LETTER is not a counterexample, and a finite empty letter spectrum is not a proof.
