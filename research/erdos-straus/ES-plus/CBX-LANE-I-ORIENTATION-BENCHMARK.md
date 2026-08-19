# CBX Lane-I orientation benchmark — p-major, C-major, shift-major

**Status:** finite empirical benchmark and exact operation-count comparison  
**Date:** 2026-08-16  
**Program:** ES+  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora-family GNU/Linux  
**Benchmark commit:** `a212197564cecaa89015a3ecd5b4865b7e27d977`  
**Fedora environment:** Fedora 44 container, GCC 16.1.1  
**Claim boundary:** operation counts below are exact for the stated finite corpus. Wall-clock ratios are machine- and run-specific. None is an asymptotic theorem, an adaptive-K theorem, or a proof of Erdős–Straus.

---

## 1. Why three orientations

Lane I asks whether an admissible signed-box shift hits a Mordell-hard prime. CBX now implements three exact finite traversals of the same predicate.

### p-major recognition

\[
\boxed{p\to k\to C=(p+k)/4}
\]

Implemented by `cbx-forward-i`. Each hard prime is the outer subject. Shifts are tried in increasing order until its first hit.

### C-major construction

\[
\boxed{k\to C\to p=4C-k}
\]

Implemented by `cbx-inverse`. The strict baseline factors every compatible C. The default target-gated mode preserves this outer orientation but rejects generated non-target, already-covered, or non-coprime candidates before expensive factorization.

### shift-major survivor traversal

\[
\boxed{k\to p\to C=(p+k)/4}
\]

Implemented by `cbx-shift-i`. The shift is outermost. For each increasing k it walks a compact frontier containing only hard primes not already covered at a smaller shift. Hits are removed from the frontier immediately.

The third form is intentionally neither the original p-major recognizer nor the C-major constructive generator. It tests whether shift batching itself is useful once the exact target universe is known.

---

## 2. Exact equivalence invariant

For the CI corpus

\[
2\le p\le100{,}000,
\qquad K_I=80,
\]

there are exactly

\[
\boxed{273}
\]

Mordell-hard prime targets.

Both non-forward engines run an independent `--verify` pass against p-major Lane-I recognition. The regression gate requires, for every hard prime,

\[
\text{cover membership agreement}
\]

and, when hit,

\[
\text{minimal first-}k\text{ agreement}.
\]

On the stated Fedora and Ubuntu validation corpus:

\[
\boxed{\text{verification mismatches}=0.}
\]

For shift-major, the gate additionally requires

\[
\boxed{
\frac{\text{shift factorizations}}
     {\text{forward factorizations}}
=1
}
\]

and

\[
\boxed{
\frac{\text{shift active visits}}
     {\text{forward shift candidates}}
=1.
}
\]

These equalities are exact finite work-set identities, not timing observations.

---

## 3. Fedora 44 three-repeat microbenchmark

The benchmark harness used

```sh
python3 research/erdos-straus/cbx.kernel/bench_i.py \
  --hi 100000 \
  --i-max 80 \
  --repeat 3 \
  --no-verify
```

with alternating execution order. The ratios below use the median wall time of the three repetitions.

### Strict C-major baseline

The intentionally literal constructive baseline produced

\[
\boxed{
\rho_F^{\rm strict}
=
\frac{\text{strict C-major factorizations}}
     {\text{p-major factorizations}}
=20.198020
}
\]

and

\[
\boxed{
\rho_t^{\rm strict}=12.190308.
}
\]

This decisively falsifies the naïve hypothesis that simply reversing the outer loops makes Lane I faster.

### Target-gated C-major

After generated-target, already-covered, and coprimality gates,

\[
\boxed{
\rho_F^{\rm gated}=1.000000
}
\]

while the raw traversal still enumerated

\[
\boxed{
\rho_C^{\rm gated}
=
\frac{\text{enumerated compatible C}}
     {\text{p-major factorizations}}
=20.198020.
}
\]

The resulting median wall ratio was

\[
\boxed{
\rho_t^{\rm gated}=1.325060.
}
\]

So target gating removed the 20x **expensive arithmetic** waste completely, but the C-major traversal still paid about 32.5% wall-time overhead on this microbenchmark from enumerating cheap candidates that never reach factorization.

### Shift-major survivor frontier

Shift-major produced the exact work identities

\[
\boxed{
\rho_F^{\rm shift}=1.000000,
\qquad
\rho_V^{\rm shift}=1.000000,
}
\]

where `rho_V` compares active shift-major target visits with p-major shift candidates.

Its median Fedora wall ratio was

\[
\boxed{
\rho_t^{\rm shift}=0.992221.
}
\]

That is about 0.8% faster than p-major in this particular microbenchmark. The correct interpretation is **practical parity within timing noise**, not evidence of a universal speedup.

---

## 4. What the benchmark actually teaches us

The useful conclusion is structural, not the tiny timing difference.

### Result A — strict inversion spends work in the wrong place

The 20.198x strict factorization ratio shows that compatible C residue classes alone do not make C-major inversion economical. Most generated C values do not correspond to currently relevant prime targets.

### Result B — target gating perfectly recovers the expensive work set

At this finite corpus, target-gated C-major performs exactly the same number of signed-box factorizations as p-major recognition.

Thus the remaining C-major penalty is not arithmetic depth. It is iterator overhead.

### Result C — shift-major removes that iterator penalty

Shift-major visits exactly the same active `(p,k)` work set as p-major recognition, but transposes its traversal order. The finite wall result lands at parity.

This means the next optimization problem should not be phrased as

> forward or inverse?

The better question is

> which orientation should each portion of the Lane-I work use, and what structure can be shared when k is outermost?

---

## 5. The next algorithmic target

The shift-major form is especially useful because all unresolved targets at one k are visible together. That creates research opportunities that p-major recognition hides:

1. batch or cache factor information for the family
   \[
   C=(p+k)/4;
   \]
2. profile first-hit yield and cost **per shift**;
3. identify shifts whose generated cover density justifies C-major construction;
4. leave sparse/expensive shifts in shift-major or p-major recognition;
5. test defect, spectrum, residue, and factor-pattern gates before Pollard-rho work;
6. build a per-shift scheduler from measured cost rather than declaring one global orientation optimal.

A likely future engine therefore has the shape

\[
\boxed{
\text{hybrid Lane I}
=
\text{generated shifts}
+
\text{shift-major shifts}
+
\text{recognition fallback}.
}
\]

That is an engineering hypothesis to test, not a theorem.

---

## 6. Reproduction

Build all Lane-I research engines:

```sh
make -C research/erdos-straus/cbx.kernel
```

Verify the C-major construction:

```sh
./centl es cbx inverse \
  --hi 100000 \
  --i-max 80 \
  --segment 25000 \
  --verify
```

Verify shift-major:

```sh
./centl es cbx shift-i \
  --hi 100000 \
  --i-max 80 \
  --segment 25000 \
  --verify
```

Run the three-way benchmark:

```sh
python3 research/erdos-straus/cbx.kernel/bench_i.py \
  --hi 100000 \
  --i-max 80 \
  --repeat 3
```

Reproduce the deliberately expensive strict inverse baseline:

```sh
python3 research/erdos-straus/cbx.kernel/bench_i.py \
  --hi 100000 \
  --i-max 80 \
  --repeat 3 \
  --strict-inverse
```

---

Erdős–Straus remains open. These are exact finite cover algorithms and finite benchmarks, not a proof.
