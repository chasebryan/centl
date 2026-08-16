# CBX2 — formulation

**Status:** exact finite formulation of one hunt; not a proof  
**Kernel:** `cbx2.kernel 0.1.0`  
**Production boundary:** `cbis.kernel 1.2.0` remains the letter engine on `main`  
**Sibling:** `cbx.kernel` (PR #230) remains the X-ray / multi-orientation research suite  
**Claim boundary:** Erdős–Straus remains open. A finite letter is not a counterexample. A finite empty letter spectrum is not a proof.

This note records the formulation. It does not replace `LETTER-EQUATION.md`, `HOMING.md`, or the CBX status notes.

---

## 1. Why a second formulation exists

Three surfaces already exist and must stay intact:

1. **cbis 1.2.0** — production stacked hunt `W → I → N → L`, R-homing, live panel. I is *recognition*: `p → k → C`.
2. **cbx 0.1.0 (PR #230)** — independent X-ray of every lane, finite grade `Γ`, and three exact Lane-I orientations, including constructive `k → C → p`.
3. **cbis model-escape (PR #231)** and the routed-shift notes (PR #245, k-class branches) — observers and theorems. Not hunt lanes.

cbis implements the letter equation as a *test on survivors of W*.  
cbx implements the letter equation as a *research instrument* with several binaries.

**cbx2** formulates one process that does both jobs in the order the equation names:

```text
construct I   (k → C → p)
X-ray W, N, L independently
verdict       W → I → N → L
home          only R
```

I is built. W/N/L are measured even when W already solves the prime. The production letter is still the complement of the stacked cover. The number is still `ES-LETTER-v1`.

---

## 2. Finite grade

The finite search is not one scalar K.

```text
Γ = (F, K_I, E_N, A_L)
```

Default:

```text
F = 11, K_I = 400, E_N = 300, A_L = 400
```

`--k-max K` is only the compatibility shortcut `K_I = A_L = K`.

A named run has an immutable grade. Changing Γ requires a new run name or a fresh seed.

---

## 3. Constructive Lane I

For admissible

```text
k ≡ 3 (mod 4),  3 ≤ k ≤ K_I
```

and Mordell-hard class

```text
h ∈ {1, 121, 169, 289, 361, 529} (mod 840)
```

the letter equation forces

```text
C ≡ (h + k) / 4  (mod 210).
```

The engine walks those six C-progressions, forms `p = 4C − k`, and evaluates `δ_k(C)`. Shifts increase, so the first hit is

```text
k_I*(p) = min { k : δ_k((p+k)/4) = 0 }.
```

Cheap gates after `p` is generated (not a target, already hit at smaller k, `gcd(C,k) ≠ 1`) do not change membership or first k.

Recognition `p → k → C` is retained only as `--verify`. Agreement of cover membership and of `k_I*` is a software check, not a new theorem.

---

## 4. Independent X-ray

On every Mordell-hard prime in a window the engine records, independently:

| lane | measure |
| --- | --- |
| W | `4p+1`, `p+4`, then `fab(a,b ≤ F)` on residual R |
| I | already constructed `k_I*` |
| N | external-NR / aligned shifts through `E_N` |
| L | López prime-modulus traps through `A_L` |

A W-hit does not hide I, N, or L. That is the CBX X-ray, kept inside one process.

R is unchanged:

```text
R = { hard p : p+4 ∈ Σ₁ and 4p+1 ∈ Σ₁ }
```

Homing walks `S = p+4` through `Σ₁` and never visits a linear W-hit.

---

## 5. Production verdict

The letter identity is the stacked complement, same as cbis:

```text
LETTER  ⇔  W misses and I misses and N misses and L misses.
```

Finding the prime by constructing I first does not change the stamp. GREAT is not stored.

---

## 6. What this kernel does not do

- It does not write cbis or cbx state.
- It does not add a fifth cover lane.
- It does not consume PR #231 model-escape observers.
- It does not claim a universal K, an adaptive-K law, or Type A/B completeness.
- It does not merge the k=19/23/35/47 class-routing notes into the hunt.

Those remain the work of the open PRs and agent branches listed in the pull request.
