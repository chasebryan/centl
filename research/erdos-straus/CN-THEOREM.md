# CN Theorem — Finite Active-Core Escape

**Status:** pairwise-coprime case proved for all finite n; shared-factor C3/C4 certified  
**Date:** 2026-08-15  
**Depends on:** `C1-THEOREM.md`, `C2-THEOREM.md`  
**Claim boundary:** Does not prove Erdős-Straus, López-all-primes, or DSC-P for unconstrained shared-prime clusters of arbitrary geometry. Closes the coprime-tower route and certifies small shared clusters.

---

## Setup

Directly novel candidate. Active fixed-negative layers

\[
\mathcal N^{\mathrm{act}}=\{j_1,\ldots,j_n\},\qquad n\ge 1,
\]

with pullback moduli `q_i > 1` and forbidden sets `R_i` as in C1. Let

\[
S_i = U_i \setminus R_i \ne \emptyset
\]

by Theorem C1 (`U_i` = units mod `q_i`). Put `Q = lcm(q_1,...,q_n)`.

---

## Theorem CN-coprime (all finite n)

If `gcd(q_i, q_j) = 1` for all `i ≠ j`, then a simultaneous reduced escape exists.

### Proof

By C1, each `S_i ≠ ∅`. Choose `a_i ∈ S_i`. The system

\[
s \equiv a_i \pmod{q_i},\qquad i=1,\ldots,n
\]

has a unique solution mod `Q = q_1···q_n` by the Chinese Remainder Theorem. Moreover `gcd(s,Q)=1`. Hence `s` is reduced and avoids every `R_i`. QED.

**Induction form.** The case `n=1` is C1. The case `n=2` is C2-coprime. For `n≥3`, CRT against the product of the first `n−1` moduli (inductively safe) with `a_n ∈ S_n` extends the escape.

---

## Theorem CN-shared (certificates)

When the `q_i` share prime factors, compatibility conditions mod those primes are required.

### Certificate C3 / C4 (tight, admissible)

See `CN-SHARED-THEOREM.md`. On the `73,814` admissible hard candidates through `k ≤ 1500`:

- tight `q ≤ 9` triples: `3,994,891` checks, **0** failures;
- the only shared-pair failures are `21` complementary `q=3` covers in the `205` family, all directly shadowed by layer `10`.

Sampled-`r` C3/C4 scans remain valid as samples. They are not a universal shared-factor theorem. Unrestricted complementary `q=3` covers exist.

### Obstruction pattern

Lift-room peels every layer with `φ(q)/φ(d) > |R|`. The totient-ratio lemma makes this automatic whenever `d < q` and `|R| ≤ 1`. The residual tight cluster is 3-adic. Complementary covers there are either non-admissible or ancestry-absorbed (`205 → 10`). A fully formal proof that every `q=3` layer is an absorbed child of a `q=1` anchor is the remaining shared-CN path.

---

## Corollary — Coprime active cores are DSC-P complete

Any directly novel candidate whose active fixed-negative moduli are pairwise coprime is reduced-realizable:

1. Character-shield extension (parent)
2. Inactive fixed-negative layers safe by direct novelty
3. **CN-coprime** simultaneous escape
4. Fiber reverse (parent)
5. Dirichlet → infinitely many exact-depth primes

---

## Scoreboard

| Result | Status |
|--------|--------|
| C1 | Closed |
| C2-coprime | Closed |
| C2-shared | Certified 0-fail |
| CN-coprime (all n) | **Closed** |
| C3/C4 shared | Tight admissible 0-fail; unrestricted C2-shared false |
| 205-absorption | **Closed** (`CN-SHARED-THEOREM.md`) |
| Arbitrary shared CN | Open (remaining `q=3` families) |
| Universal DSC-P | Open |
| López all primes | Open |
| Erdős-Straus | Open |

---

## Next

1. Formalize shared-factor CN via simultaneous projection of thin two-box pullbacks.
2. Bound `|N^{act}|` in the Class-C residual (parent census: median variable negative towers ~1).
3. If `|N^{act}|` is uniformly bounded or generically pairwise-coprime, DSC-P collapses to closed theorems.
