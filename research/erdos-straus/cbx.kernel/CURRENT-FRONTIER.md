# cbx.kernel — current frontier ledger

**Purpose:** crash-recovery / handoff ledger for the active CBX research branch.  
**Kernel:** `cbx.kernel 0.1.0`  
**Production boundary:** `cbis.kernel 1.2.0` remains the production ES-LETTER engine.  
**Primary platform:** Fedora-family GNU/Linux.  
**Claim boundary:** Erdős–Straus remains open. CBX finite search and overlap results are research evidence, not a proof.

---

## 1. Why CBX exists

CBX is the X-ray/research companion to cbis.

It keeps the ordinary finite verdict order

```text
W -> I -> N -> L
```

but measures hidden I/N/L structure even when W already solves the prime.

It also transposes Lane I into several exact finite traversal orientations so algorithmic structure can be studied without changing the mathematical predicate.

---

## 2. Finite grade

Use

```text
Gamma = (F, K_I, E_N, A_L)
```

not one scalar K when describing the complete finite CBX search.

Default:

```text
F       11
K_I     400
E_N     300
A_L     400
```

Named perpetual X-ray runs have immutable grades.

`--k-max` is compatibility syntax that sets both `K_I` and `A_L`; it is not the fundamental grade model.

---

## 3. Core implementation

### Perpetual X-ray engine

```text
src/cbx.c
src/cbx_runtime.c
analyze.py
```

Key properties:

- deterministic uint64 Miller–Rabin;
- Pollard-rho factorization;
- W linear/R/fab instrumentation;
- hidden Lane-I/N/L measurements;
- target-atomic stop signals;
- replay-over-skip crash recovery;
- run locks and immutable grades;
- deterministic finite `--iterations` censuses;
- ES-LETTER-v1 identity compatibility with separate finite-grade provenance.

### Lane-I finite engines

```text
cbx-forward-i      p -> k -> C
cbx-inverse        k -> C -> p
cbx-shift-i        k -> p -> C over ordered survivors
cbx-profile-i      ordered frontier/profile
cbx-standalone-i   every k against the full hard-prime universe independently
```

### Analysis / certification tools

```text
bench_i.py
analyze_layers.py
analyze_profile.py
analyze_standalone.py
analyze_overlap.py
analyze_shadow_depth.py
plan_hybrid.py
certify_i.py
```

Experimental native exact cover solver:

```text
src/cbx_shadow_i.c
```

It searches finite earlier-layer set covers through depth four using native bitsets. Keep its conclusions finite unless/until a theorem is proved.

---

## 4. Root command surface

Current public CBX commands include:

```sh
./centl es cbx go
./centl es cbx probe N
./centl es cbx status

./centl es cbx forward-i ...
./centl es cbx inverse ...
./centl es cbx shift-i ...
./centl es cbx profile-i ...
./centl es cbx standalone-i ...

./centl es cbx bench ...
./centl es cbx analyze ...
./centl es cbx analyze-layers ...
./centl es cbx analyze-profile ...
./centl es cbx analyze-standalone ...
./centl es cbx analyze-overlap ...
./centl es cbx analyze-shadow-depth ...
./centl es cbx plan-hybrid ...
./centl es cbx certify-i ...
```

The native depth-four `cbx-shadow-i` solver is currently research-internal until its Fedora artifact validation is complete.

---

## 5. Clean X-ray census

Default grade:

```text
Gamma = (11,400,300,400)
```

Clean deterministic X-ray result:

```text
sweep cursor          234,540,000
hard-prime X-rays     401,752
production letters    0
R/fab targets          102,502
Lane-I observed max   107
record prime           8,803,369
R Lane-I p99           27
```

The empirical proposal

```text
K(p) = ceil(2 log p)
```

fails `244 / 102,502` measured R targets.

Therefore it is already falsified on that finite corpus.

---

## 6. Three-way Lane-I traversal benchmark

Smoke corpus:

```text
p <= 100,000
K_I = 80
hard primes = 273
```

All exact traversals agree on membership and minimal first k.

Finite exact work ratios:

```text
strict C-major factorizations / p-major      20.198020
bounded target-gated C-major / p-major        1.000000
shift-major factorizations / p-major           1.000000
shift-major active visits / p-major             1.000000
```

Shift-major wall time is effectively at parity with p-major on Fedora; small sub/super-one variations are timing noise, not a theorem.

Interpretation:

- naïve inverse construction is exact but expensive;
- target gating removes the expensive factorization waste;
- shift-major keeps k outermost with the same expensive work set as p-major;
- the research target is a hybrid scheduler, not one universally privileged loop order.

---

## 7. Deep ordered Lane-I census through 10M

Exact hard-prime universe:

```text
20,513 Mordell-hard primes
```

All three traversal engines agree exactly on the `p -> k_I*(p)` map.

Result:

```text
covered       20,513
residual       0
```

Productive first-hit shifts:

```text
3,7,11,15,19,23,27,31,35,39,43,47,51,55,59,107
```

Exact first-hit counts:

```text
3      8590
7      4779
11     4463
15      949
19      883
23      541
27       91
31      152
35       17
39       22
43        5
47       15
51        1
55        2
59        2
107       1
```

After k=59 only one finite target remains:

```text
p = 8,803,369
```

It fails

```text
63,67,71,75,79,83,87,91,95,99,103
```

and hits at 107.

The intervening eleven layers are a record-prime gauntlet, not universally dead layers.

Preserved note:

```text
../ES-plus/CBX-LANE-I-DEEP-CENSUS-10M.md
```

---

## 8. Finite minimal Lane-I ceiling

On the 10M hard-prime domain:

```text
K_I^min = 107
```

Reason:

- every hard prime has `k_I*(p) <= 107`;
- `p=8,803,369` has exact first hit 107;
- therefore the previous admissible ceiling 103 is insufficient.

This is a Lane-I coordinate certificate only. It is not automatically the minimum shared cbis K, because cbis feeds K to both I and L and has W/N as well.

Command:

```sh
./centl es cbx certify-i --hi 10000000 --i-max 400 --segment 1000000 --json
```

Preserved note:

```text
../ES-plus/CBX-LANE-I-K-CERTIFICATE-10M.md
```

---

## 9. Standalone layer census through 10M

Standalone mode tests every k independently against all 20,513 hard primes.

For

```text
k = 3,7,...,399
```

there are 100 layers.

Result:

```text
productive standalone layers   100 / 100
zero-hit standalone layers        0
k>107 productive                 73 / 73
```

Strong examples above 107:

```text
k=119   hits 12,345
k=111   hits 10,439
k=191   hits 10,142
k=167   hits  9,818
k=311   hits  9,811
```

Thus

```text
zero first-hit novelty != weak standalone layer
```

Many later layers are strong-but-shadowed.

Preserved note:

```text
../ES-plus/CBX-LANE-I-STANDALONE-10M.md
```

---

## 10. Exact overlap graph through 10M

Exact standalone relation rows:

```text
534,037 (k,p) hit relations
```

Ordered novelty:

```text
novel layers                   16
fully shadowed by prior union 84
```

Exact simple containment results:

```text
T_k subset T_j                         0 cases
T_k subset T_a union T_b               0 cases
```

A two-layer relation observed on the 100K smoke corpus does not survive at 10M.

Greedy earlier-layer cover sizes for k>107:

```text
5 layers    2 targets
6 layers   18 targets
7 layers   35 targets
8 layers   15 targets
9 layers    2 targets
10 layers   1 target
```

Median greedy cover size: `7`.

Strong pairwise overlap remains incomplete. Example:

```text
T_55 covered by T_11 alone: about 78.22%
```

Interpretation: finite shadowing is distributed / many-body.

Preserved note:

```text
../ES-plus/CBX-LANE-I-OVERLAP-10M.md
```

---

## 11. Exact shadow-depth work

`analyze_shadow_depth.py` exhaustively checks exact earlier-layer covers through triples.

A dedicated Fedora research workflow regenerates the 10M standalone relation set and preserves the exact result as an artifact.

`src/cbx_shadow_i.c` is a native bitset solver extending the exact search through depth four. It is intended to close the gap left by greedy five-layer covers:

- if a target has a five-layer greedy cover;
- and the native solver proves no cover of size <=4;
- then the exact finite minimum is five.

Do not promote a finite minimum-set-cover result to a universal signed-box theorem without an independent mathematical proof.

---

## 12. Fedora workflows

Mandatory/smoke:

```text
.github/workflows/cbx-kernel.yml
.github/workflows/cbx-standalone-i.yml
```

Publication-grade/deep:

```text
.github/workflows/cbx-research-census.yml
.github/workflows/cbx-standalone-research.yml
.github/workflows/cbx-shadow-research.yml
.github/workflows/cbx-shadow4-research.yml
.github/workflows/cbx-k-certificate.yml
```

Deep artifacts preserve environment metadata, source/check-out provenance, exact sets/relations, analysis JSON, and SHA-256 manifests.

macOS/Windows are not CBX research targets. Compatibility there is only a natural byproduct.

---

## 13. What has been falsified

Do not resurrect these without new evidence:

1. **K is the whole finite search.** False; use Gamma.
2. **A guessed `2 log p` Lane-I law is sufficient.** False on the measured R corpus.
3. **Naïve C-major inversion is automatically faster.** False on the finite benchmark.
4. **Later first-hit-dead layers are weak.** False; standalone layers above 107 can be very strong.
5. **The 10M shadows collapse to one earlier layer.** False.
6. **The 10M shadows collapse to two earlier layers.** False.
7. **A 100K exact containment should be trusted as structural.** False; the observed pair relation disappeared at 10M.

---

## 14. Immediate theorem frontier

The current useful questions are:

1. What is the exact finite minimum earlier-layer cover size of each fully-shadowed `T_k`?
2. Do any exact three- or four-layer containments survive 10M?
3. Which earlier-layer combinations recur across many later sets?
4. Can recurring combinations be derived from modulus, factor, defect, or spectrum structure?
5. Can the record-prime gauntlet `63..103 -> 107` be explained symbolically?
6. How does `K_I^min(X)` grow on larger exact domains?
7. Can a proved defect/spectrum statement force an actual adaptive `K_I(p)` law?
8. Can proven overlap/containment relations be fed into a hybrid scheduler as mathematical pruning?

The desired end state is not a clever heuristic. It is an exact scheduler whose pruning steps each have a mathematical reason.

---

## 15. Preservation rule

When changing CBX:

- preserve `cbis.kernel` production semantics;
- use named finite grades;
- keep first-hit, frontier, and standalone semantics distinct;
- never convert a finite overlap into a theorem by wording;
- push small checkpoints;
- preserve deep result artifacts with hashes;
- keep a safety branch/checkpoint before large rewrites;
- update this ledger when the research frontier materially changes.

---

**Erdős–Straus remains open. CBX is an exact finite theorem-discovery instrument.**