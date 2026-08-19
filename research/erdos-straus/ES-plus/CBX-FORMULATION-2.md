# CBX Formulation 2

**Status:** preserved research formulation inside the CBX line  
**Kernel:** `cbx.kernel` remains the sole X-ray research kernel  
**Production boundary:** `cbis.kernel 1.2.0` remains the production ES-LETTER-v1 hunt  
**Claim boundary:** Erdős–Straus remains open. A finite LETTER is not a counterexample, and a finite empty LETTER spectrum is not a proof.

## Purpose

This note preserves the useful conceptual core explored in draft PR #246 without introducing a third overlapping kernel.

CBIS and CBX already contain the required mathematical predicates and exact arithmetic. The useful idea is therefore an **orchestration**, not a new mathematical lane:

```text
construct I   (k -> C -> p)
x-ray W/N/L  independently
verdict       W -> I -> N -> L
home          only residual R
```

The formulation reads the hunt in the order suggested by the constructive Lane-I equation while retaining the production-equivalent stacked verdict.

## 1. Construct Lane I first

For admissible shifts

```text
k == 3 (mod 4)
```

and Mordell-hard class

```text
h in {1, 121, 169, 289, 361, 529} (mod 840),
```

construct compatible companions by

```text
C == (h + k)/4 (mod 210)
p = 4C - k.
```

For a finite Lane-I ceiling `K_I`, increasing shifts recover the first exact hit

```text
k_I*(p) = min { k : delta_k((p+k)/4) = 0 }.
```

This is already represented by CBX's constructive/inverse and shift-major Lane-I research surfaces. Recognition `p -> k -> C` remains the reference orientation for exact cross-checking.

## 2. X-ray the remaining lanes independently

For every Mordell-hard target in the finite domain, measure independently:

- **W**: linear predicates followed by finite `fab` work on residual R;
- **I**: constructed first-hit depth `k_I*`;
- **N**: external-NR / aligned-shift cover through `E_N`;
- **L**: Lopez layers through `A_L`.

A W-hit must not hide I/N/L geometry. This is the existing CBX X-ray principle.

The finite search grade remains

```text
Gamma = (F, K_I, E_N, A_L).
```

## 3. Preserve the production verdict

The search identity remains exactly

```text
LETTER <=> W misses and I misses and N misses and L misses.
```

Constructing Lane I first changes the traversal, not the LETTER definition. It does not add a fifth cover lane and it does not weaken the production-equivalent verdict.

## 4. Home only the residual set

Homing remains restricted to the usual residual R. Formulation 2 does not change the mathematical definition of R and does not replace CBIS homing semantics.

## 5. Preservation invariant

Any future one-process implementation of this formulation must inherit the existing CBX no-skip guarantees:

- an entered target finishes atomically before SIGINT/SIGTERM is honored;
- an interrupted sweep cursor advances only past fully processed targets;
- an interrupted home cursor points to the first unprocessed state;
- state writes are atomic or replay-safe;
- interruption may repeat work, but must never skip candidate work;
- finite runs remain reproducible under an immutable grade.

A traversal that can advance a cursor beyond partially processed work is not acceptable for LETTER search.

## 6. Why this is not `cbx2.kernel`

The draft `cbx2` experiment demonstrated a clean presentation of the equation but duplicated capabilities already present in CBX:

- constructive `k -> C -> p` Lane I;
- independent W/I/N/L instrumentation;
- `Gamma=(F,K_I,E_N,A_L)` grading;
- Pollard-rho arithmetic;
- production-equivalent stacked verdicts;
- ES-LETTER-v1 compatibility.

Keeping a separate permanent kernel would increase maintenance and semantic drift without adding a new theorem or cover family. The formulation is therefore preserved here and should be implemented, if useful, as a CBX orchestration/mode rather than as a sibling kernel.

## 7. Research boundary

This formulation does **not** claim:

- a universal or adaptive Lane-I ceiling;
- Type A/B completeness;
- a new cover lane;
- a proof of Erdős–Straus;
- that finite inverse/recognition agreement is a theorem.

Its value is architectural: it gives a compact way to run the existing exact CBX machinery in constructive-equation order while preserving independent geometry and production semantics.
