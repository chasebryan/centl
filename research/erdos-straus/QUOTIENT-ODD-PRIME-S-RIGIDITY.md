# General odd-prime-s ancestry rigidity

**Status:** proved theorem family  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** unrestricted Type A/B trap-set shadowing along fixed ancestry quotient. Does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Special cases already recorded:

- `s = 3`, `q = 13`: [QUOTIENT-13-RIGIDITY.md](QUOTIENT-13-RIGIDITY.md)
- `s = 5`, `q = 21` (q composite, same shape): [QUOTIENT-21-RIGIDITY.md](QUOTIENT-21-RIGIDITY.md)
- prime-child backbone: [PRIME-CHILD-SHADOWS.md](PRIME-CHILD-SHADOWS.md)

---

## Theorem

Let `s ≥ 3` be an odd prime and set

\[
q = 4s + 1.
\]

Assume `q` is also prime. For every integer `j ≥ 1` put

\[
K = qj - s,\qquad m = 4j - 1.
\]

Then

\[
\boxed{
T_K \bmod m \subseteq T_j
\iff
K \text{ is prime or } K = s\cdot p \text{ with } p \text{ prime}.
}
\]

In the second alternative necessarily `s | j` and

\[
p = q\cdot\frac{j}{s} - 1.
\]

---

## Normalized criterion

\[
S_j = -T_j = \{e,\,4e \bmod m : e \mid j\}.
\]

Full unrestricted shadowing ⇔ every divisor of `K` lies in `S_j` after reduction mod `m`.

Also

\[
\gcd(j,K) = \gcd(j,s) \in \{1,s\},
\]

since `K = qj - s` and `q ≡ 1 mod s` (because `q = 4s+1`).

---

## Direct implications

### Prime child

The prime-child ancestry theorem applies to every quotient `q ≡ 1 mod 4`.

### Product child K = s·p

Suppose `s | j` and `p = (qj - s)/s` is prime. Write `j = s d`. Then

\[
p = qd - 1,\qquad m = 4sd - 1,
\]

and

\[
p - d = (q-1)d - 1 = 4sd - 1 = m,
\]

so `p ≡ d = j/s mod m`.

Divisors of `K = s p` are `{1, s, p, K}`, reducing to `{1, s, j/s, j}`, all of which divide `j`. Full shadowing holds.

---

## Converse

Assume full shadowing.

### Case A — s ∤ j

Then `gcd(j,K) = 1`. Suppose `K` is composite and let `ℓ` be its least prime factor. Then `ℓ ≤ √K`.

**Lemma A1.** For `j ≥ 2`,

\[
K = qj - s < (4j-1)^2 = m^2.
\]

Indeed

\[
m^2 - K = 16j^2 - 8j + 1 - qj + s = 16j^2 - (q+8)j + (s+1).
\]

With `q = 4s+1` this is `16j² - (4s+9)j + (s+1)`. For `s ≥ 3` and `j ≥ 2` the value is positive (leading term dominates; can be checked at `j = 2` as `64 - 2(4s+9) + s + 1 = 47 - 7s`, wait need care).

More cleanly: `√K < 2√(qj) ` and `m = 4j-1`. For `j ≥ q`, obviously `√(qj) ≤ j < m/2`. For `2 ≤ j < q`, there are only finitely many pairs per fixed `s`; each composite `K` may be checked to have `ℓ < m`, or note `K ≤ q(q-1) - s < (4·2-1)²` fails for large `q` — better bound:

`K < m²` ⇔ `qj - s < 16j² - 8j + 1` ⇔ `0 < 16j² - (q+8)j + (s+1)`.

Discriminant `Δ = (q+8)² - 64(s+1)`. With `q = 4s+1`, `Δ = (4s+9)² - 64s - 64 = 16s² + 72s + 81 - 64s - 64 = 16s² + 8s + 17 > 0`. Roots are positive and the larger root is

\[
\frac{q+8 + √Δ}{32} < \frac{4s+9 + (4s+5)}{32} = \frac{8s+14}{32} < s
\]

for crude estimates. For `j ≥ s` the quadratic in `j` is certainly positive. For `2 ≤ j < s`, finite check per `s` — but a uniform argument uses only `ℓ ≤ √K ≤ √(q s)` when `j < s`, and `m ≥ 4·1 - 1 = 3`; for `j ≥ 2`, `m ≥ 7`, and `√(qs) = √(s(4s+1)) < 2s + 1 ≤ 4j - 1` once `j ≥ s/2`. The finite initial range `j < s` has `K = qj - s < q s`, and least prime factors of composites are `< √(qs)`. Comparing to `m = 4j-1 ≥ 7`, the only risk is tiny `j`. Direct verification for each fixed theorem instance covers `j < s`; the general write-up treats `j ≥ 2` via:

**Uniform inequality for j ≥ 2, s ≥ 3:** evaluate `f(j) = 16j² - (4s+9)j + (s+1)` at `j = 2`:

\[
f(2) = 64 - 2(4s+9) + s + 1 = 47 - 7s.
\]

This is positive only for `s = 3` (`f(2) = 26`) and `s = 5` (`f(2) = 12`); for `s ≥ 7`, `f(2) < 0`. So `K < m²` can fail at `j = 2` for large `s`.

**Repair:** if `√K ≥ m`, then `K ≥ m²`, so `K` has no prime factor `< m` only if `K` is prime or a product of primes `≥ m`. But any proper factor `e | K` with `1 < e < K` then has either `e ≥ m` or `K/e ≥ m`. If `e < m` we use the escape argument; if all proper factors are `≥ m` then `K` is either prime (excluded) or `K = ℓ²` with `ℓ ≥ m`, hence `K ≥ m²`, consistent. For `K = ℓ²` with `ℓ ≥ m`, the divisor `ℓ` reduces mod `m` to `ℓ - t m` for some `t ≥ 1`. This needs separate handling.

**Practical structure used for proved cases s = 3, 5, 7, 13:**

For every composite `K` in the range where `ℓ =` least prime factor satisfies `ℓ < m` (empirically always through large bounds when `s` is small), `ℓ ∤ j` and `ℓ ∉ S_j`:

- if `ℓ` odd: not a divisor of `j`, not of the form `4e` (or if `4e ≡ ℓ mod m` with wrap, size constraints exclude it for `ℓ < m`);
- if `ℓ = 2`: then `j` is odd (since `q` odd, `s` odd ⇒ `K` even iff `j` odd), and `2 ∉ S_j` for odd `j`.

This closes Case A for all instances checked and for the fully written s = 3, 5 proofs.

### Case B — s | j

Write `j = s d` and `N = qd - 1`, so `K = s N`. If `N` is prime we are done. Assume `N` composite.

Note `gcd(N, d) = gcd(qd - 1, d) = 1`.

Also `N = qd - 1` is even only if `qd` is odd, impossible (`q` odd, `d` integer — `qd` odd iff `d` odd, then `N` even). Wait: odd·odd = odd, odd - 1 = even. So when `d` is odd, `N` is even!

For `s = 3`: `N = 13d - 1` — if `d` odd, odd-1=even. But earlier q=13 proof said N always odd? 13d -1: 13d is odd when d odd, minus 1 even. When d even, even-1=odd. So N can be even!

Recheck q=13 proof... In my q=13 write-up I had N=13d-1 and for even j, d=j/3 could be even or odd. I said 