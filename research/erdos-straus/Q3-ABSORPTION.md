# q=3 Strong Absorption

**Status:** theorem  
**Date:** 2026-08-15  
**Depends on:** `CN-SHARED-THEOREM.md` (205→10 special case)  
**Claim boundary:** Kills a large family of complementary q=3 threats on directly novel candidates. Does not classify base q=3 layers. Does not prove DSC-P or Erdős-Straus.

---

## Setup

Layer `j` with `m_j = 4j−1`. Write `q_j = m_j / gcd(L, m_j)`. Interest is the case `q_j = 3`, i.e.

\[
\gcd(L,m_j) = m_j/3,
\]

so `3 ∦` necessarily, but the pullback modulus is exactly `3` and `L` is divisible by every prime-power factor of `m_j` except a residual factor `3`.

---

## Theorem (Strong q=3 absorption)

Let `j > i ≥ 1` satisfy:

1. `m_i | (m_j / 3)`,
2. `T_j \bmod m_i \subseteq T_i` (trap reduction / divisor-child inclusion).

If a candidate progression has `q_j = 3` and `R_j ≠ ∅`, then the progression is **directly shadowed by layer `i`** (in particular it is not directly novel).

### Proof

`q_j = 3` means `gcd(L, m_j) = m_j/3`. Hypothesis (1) gives `m_i | (m_j/3)`, hence `m_i | L`. Therefore

\[
q_i = m_i / \gcd(L,m_i) = 1:
\]

the progression is frozen modulo `m_i`:

\[
x = r + Ls \equiv r \pmod{m_i}\qquad\text{for every }s.
\]

Nonempty `R_j` supplies some parameter with `x ∈ T_j`. Reducing modulo `m_i` and applying (2) yields `x ∈ T_i`. But every point of the progression has the same residue modulo `m_i`, so the whole progression lies in `T_i`. QED.

### Corollary

On any **directly novel** candidate, a layer `j` with a strong absorption ancestor cannot participate in a complementary `q=3` cover.

---

## Special case recovery

For `j = 205`, `m_{205} = 819`, `m_{205}/3 = 273`, and `m_{10} = 39 | 273` with trap reduction `T_{205} \bmod 39 \subseteq T_{10}`. The theorem recovers the parent `205 → 10` absorption.

---

## Census through `j ≤ 1500`

Among layers with `j ≡ 1 (mod 3)` (necessary for `3 | m_j`):

| Class | Count |
|-------|------:|
| Strong absorb (has `i` with `m_i | (m_j/3)` and trap reduction) | 153 |
| Weak only (trap reduction with some `m_i | m_j` but not `| (m_j/3)`) | 114 |
| Base (no trap-reducing ancestor) | 233 |

Every strong-absorb layer is novel-impossible as a `q=3` complementary participant.

---

## Remaining q=3 threat

Complementary covers can only involve:

- **base** layers (no reducing ancestor), and/or
- **weak-only** layers (ancestor exists but may not freeze when `q_j=3`).

Admissible scan through `k ≤ 1500` found the only complementary failures inside the `205` family (strong-absorbed). Extending that scan past 1500 and classifying base/weak pairs is the next finite certificate.

---

## What this is not

- Not a proof that every `q=3` layer is absorbed.
- Not a universal shared-factor CN theorem.
- Not Erdős-Straus.
