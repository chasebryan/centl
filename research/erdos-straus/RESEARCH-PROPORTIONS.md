# Research proportions — Type A/B program

**Date:** 2026-08-15  
**Scope:** `research/erdos-straus/` and the active theorem arc toward DSC-P / López / ES

---

## 1. Effort mass by layer

| Layer | Share of deposited theorem mass | Nature |
|-------|----------------------------------|--------|
| Finite certificates (DSC k≤1200/1500, frontiers, selectors) | ~35% | Exact finite theorem-certificates |
| Structural shields (character, signature, multiplicative two-box, fiber peel) | ~25% | Universal lemmas + envelopes |
| Ancestry / quotient rigidity | ~10% | Infinite families, casewise proved |
| C1 / C2 / CN-coprime / lift-room / thinness | ~20% | Local escape theorems |
| Shared-factor residual (q=3 tight cluster) | ~8% | Reduction + range certificates |
| López remainder / composite core / ES wall | ~2% | Named open problems |

**Reading:** The program is heavy on *finite certificates and local structure*, medium on *escape theorems*, light on the *pointwise remainder* that would finish López/ES. That is healthy for a depth-spectrum program and insufficient for a claim of ES.

---

## 2. Closed vs open (logical weight)

### Closed (usable as lemmas)

- Trap cardinality, shadow relation, ancestry form `k=(4s+1)j−s`
- Character-shield completeness; multiplicative coset + two-box geometry
- Fiber peel + bounded selector on frozen k≤1500 bundle (0 unresolved)
- Prime-modulus backbone; density-one Type A/B among primes
- Quotient rigidity for q ∈ {5,9,13,17,21,29}
- **C1** pullback escape
- **CN-coprime** for every finite active-core size
- **Lift-room**, totient-ratio, C2-thin reduction to q=3
- **205 → 10 absorption**; admissible complementary q=3 has 0 novel covers through k≤1500
- DSC-P fragment for pairwise-coprime active moduli

### Open (blocking universal DSC-P / López / ES)

1. **All complementary q=3 families** for every k (only k≤1500 certified)
2. **General q=3 absorption** (every q=3 layer an ancestry child of a q=1 anchor)
3. Shared-factor CN for arbitrary tight clusters beyond lift-room peel
4. Bound on `|N^{act} ∩ tight|` for Class-C residuals
5. López Type A/B for **every** prime (density one ≠ zero exceptions)
6. Composite `n` for full Erdős-Straus

---

## 3. Proportion diagnosis

| Diagnosis | Assessment |
|-----------|------------|
| Over-investment in finite k-bounds? | Mild — k≤1500 is a strong certificate but must not be mistaken for DSC-P |
| Under-investment in López remainder? | Yes — almost no deposited attack on exceptional primes outside Type A/B |
| Shared-factor focus correct? | Yes — after CN-coprime, the only local hole is 3-adic complementary covers |
| Claim discipline | Good — wall files exist; unrestricted C2-shared was corrected when false |

**Net:** The theorem mass is correctly concentrated on the Class-C / active-core escape route. The next dollar of effort should not expand another finite DSC census; it should **remove the k≤1500 cap on q=3 absorption** and **classify base q=3 layers**.

---

## 4. Ordered next moves

1. **General strong q=3 absorption** (this commit) — prove every layer with an `m_i | (m_j/3)` trap-reducing ancestor is novel-impossible when `q_j=3`.
2. Classify **base** q=3 layers (no such ancestor) and whether complementary pairs among them appear on admissible candidates for any k.
3. Peel roomy layers from arbitrary cores; residual = 3/5/7-adic tight.
4. Census `|N^{act}|` structure on Class-C residuals (not only median ~1).
5. López remainder program (separate track).

---

## 5. What “solved” would require

| Goal | Missing |
|------|---------|
| Universal DSC-P | Shared CN for all geometries + all active-core sizes |
| López for all primes | Zero exceptional primes outside Type A/B |
| Erdős-Straus | López + composites |

None of these are implied by the current closed mass alone.
