# Class-C Census Plan — k ≤ 1500

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** extraction plan (primary artifact not available in this session)  
**Type:** FORMULATION / finite-census design  
**Parent directive:** O2-1 / O2-A  
**Parent evidence:** `../DIRECT-SHADOW-K1500.md`

---

## 1. Scope

Frozen bundle:

```text
run id:       31849103304
artifact id:  9238241616
artifact sha256:
e181a66bec9a8e0d68b4b6b46892b6c71c50ebe8ab64c45944c8c17408c983dd
k_limit:      1500
directly novel candidates: 53,240
```

This note does **not** invent counts. It defines the exact fields to extract when the artifact is available to Operator-02 or when the Coordinator publishes intermediate JSON.

---

## 2. Known parent aggregates (already published)

From `../DIRECT-SHADOW-K1500.md`:

| Quantity | Value |
|----------|------:|
| Directly novel | 53,240 |
| Fiber kernel empty | 26,532 |
| Nonempty residual kernels | 26,708 |
| All nonempty solved by S_64 | 26,708 |
| Max residual prime | 31 |
| Max residual kernel size | 9 |
| Max selector radius | 54 |
| Character shield solvable | 38,658 |
| Character residual | 14,582 |

Kernel-size histogram (parent):

```text
size 0: 26,532
size 2:     28
size 3:  3,996
size 4:      6
size 5:    384
size 6:  1,582
size 7: 20,274
size 9:    438
```

Note: size 1 remains absent; size 4 appears (6 cases) — new relative to the k≤1200 census.

---

## 3. Required per-candidate fields

For each of the 53,240 directly novel candidates:

| Field | Definition |
|-------|------------|
| `k, h, t, r, L` | candidate identity |
| `|N|` | fixed-negative character core size |
| `|N_act|` | active fixed-negative core (q_j > 1) |
| `N_act_layers` | list of j with q_j > 1 and fixed-negative |
| `q_j` for each active j | pullback moduli |
| `val_excess_primes` | primes with v_p(m_j) > v_p(L) |
| `class_A` | subset of val_excess with p|L |
| `class_B` | subset of val_excess with p∤L (even valuation) |
| `fiber_kernel` | residual prime set after augmented fiber peeling |
| `kernel_sourced_by_Nact` | residual primes explained by Class A/B of N_act |
| `kernel_other_source` | residual primes not explained by N_act |
| `sig_dim_active` | local quadratic quotient dim for each active layer |
| `selector_radius` | if nonempty kernel |
| `ancestry_eliminated` | constraints removed by q=5 / q=9 / prime-child theorems before Class-C solver |

---

## 4. Aggregate tables to produce

1. Histogram of `|N|` and `|N_act|`
2. Count of candidates with `|N_act| = 0, 1, 2, …`
3. Among `|N_act| = 1` (C1 population): Class A vs B patterns; residual kernel signatures; selector radii
4. Residual signature multiplicity (update of k≤1200 table; note size-4 appearance and max prime 31)
5. Coverage: fraction of residual kernel primes explained by N_act valuation witnesses
6. Intersection with character residual (14,582) vs fiber-nonempty (26,708)

---

## 5. Interpretation rules (fixed in advance)

- All counts are FINITE OBSERVATION only.
- Empty Class C in the selector sense through k≤1500 is already known (parent: 53,240/53,240 selector-solved).
- This census measures the **active-core / valuation-source structure**, not whether witnesses exist.
- Do not infer a universal theorem from the census.

---

## 6. Blocker

Primary artifact bytes are not available in this Operator-02 session.  
Next action when available: populate the tables above into `CLASS-C-CENSUS-K1500-RESULTS.md` under this container only.
