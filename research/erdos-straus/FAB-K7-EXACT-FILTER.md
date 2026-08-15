# Exact fixed-k=7 filter for Mordell-hard primes

**Status:** proved exact factor-residue classification  
**Date:** 2026-08-15  
**Depends on:** `FAB-FIXED-K-SIGNED-DIVISOR.md`  
**Claim boundary:** this completely classifies when the fixed fab divisor `k=7` succeeds for a Mordell-hard prime. It is one filter, not an all-prime proof.

## 1. Setup

Let `p` be a Mordell-hard prime. Then

\[
p\bmod7\in\{1,2,4\},
\]

so `p` is always a quadratic residue modulo `7`.

Set

\[
\boxed{N_7=\frac{p+7}{4}.}
\]

Because `4^{-1}=2 mod7`,

\[
N_7\equiv2p\pmod7.
\]

Use `3` as a primitive root modulo `7`:

\[
1=3^0,
\quad3=3^1,
\quad2=3^2,
\quad6=3^3,
\quad4=3^4,
\quad5=3^5.
\]

The target signed-product element is

\[
-p\pmod7.
\]

Its discrete-log exponent is:

| `p mod 7` | `N_7 mod 7` | `-p mod 7` | target exponent mod 6 |
|---:|---:|---:|---:|
| 1 | 2 | 6 | 3 |
| 2 | 4 | 5 | 5 |
| 4 | 1 | 3 | 1 |

Thus the target is always an odd exponent, as expected from quadratic character.

By `FAB-FIXED-K-SIGNED-DIVISOR.md`, `k=7` succeeds exactly when that target exponent is a signed sum of the exponents of prime factors of `N_7`, with each prime usable up to its valuation.

Below, “occurrence” counts prime factors with multiplicity.

---

## 2. Cases p = 2 or 4 mod 7

Here the target exponent is `5` or `1`, i.e. `±1 mod6`.

### Immediate successes

A prime factor of `N_7` congruent to

\[
3\text{ or }5\pmod7
\]

has exponent `±1`, so by using that factor in `a` or `b` we hit the target immediately.

If no such factor occurs, the only nonzero exponent types are:

- residues `2,4`: exponent `±2`;
- residue `6`: exponent `3`.

A `6 mod7` factor together with any `2` or `4 mod7` factor gives

\[
3\pm2\equiv1\text{ or }5\pmod6,
\]

so that also solves the target.

Conversely:

- using only residues `1,2,4` produces only even exponents;
- using only residues `1,6` produces only exponents `0` or `3`.

Neither can produce `±1`.

### Theorem A

If

\[
p\equiv2\text{ or }4\pmod7,
\]

then fixed `k=7` succeeds **if and only if** at least one of the following holds:

1. `N_7` has a prime factor `3 or 5 mod7`;
2. `N_7` has both a prime factor `6 mod7` and a prime factor `2 or 4 mod7`.

Equivalently, failure occurs exactly when the prime support of `N_7` lies wholly in one of

\[
\boxed{\{1,2,4\}\pmod7}
\]

or

\[
\boxed{\{1,6\}\pmod7}.
\]

---

## 3. Case p = 1 mod 7

Now the target is

\[
-p\equiv6\pmod7,
\]

which has exponent `3 mod6`.

### A 6 mod7 factor

Any prime factor

\[
r\equiv6\pmod7
\]

already has exponent `3`, so it solves the target by itself.

Hence assume no `6 mod7` factor occurs.

### Mixing a ±1 factor with a ±2 factor

A factor `3 or 5 mod7` contributes `±1`.
A factor `2 or 4 mod7` contributes `±2`.

Choosing signs appropriately gives

\[
\pm1\pm2\equiv3\pmod6.
\]

So the presence of both types solves the target.

### Three ±1 occurrences

Any three occurrences from residue classes `3 or 5 mod7` can each be signed to contribute `+1`, yielding

\[
1+1+1=3\pmod6.
\]

This remains true when several occurrences come from the valuation of the same prime, because the signed exponent may use any integer between `-e` and `e`.

Thus multiplicity at least `3` among the `3/5` classes solves the target.

### Necessity

If none of the three mechanisms above occurs, then:

- there is no exponent-3 factor;
- either there is no odd-exponent (`±1`) factor at all, in which case every signed sum is even;
- or there are at most two `±1` occurrences and no nonzero even (`±2`) factor. Their possible signed sums are among `0,±1,±2`, never `3 mod6`.

Hence no other solution is possible.

### Theorem B

If

\[
p\equiv1\pmod7,
\]

then fixed `k=7` succeeds **if and only if** at least one of:

1. `N_7` has a prime factor `6 mod7`;
2. `N_7` has a prime factor `3 or 5 mod7` and also one `2 or 4 mod7`;
3. the total valuation multiplicity of prime factors `3 or 5 mod7` is at least `3`.

This is an exact classification.

---

## 4. Counterexample consequences

A Mordell-hard prime surviving the `k=7` filter must have a highly restricted factorization of

\[
\frac{p+7}{4}.
\]

Combined with `FAB-HARD-FIRST-FILTERS.md`, any genuine prime counterexample must simultaneously satisfy exact restrictions on

\[
\frac{p+1}{2},
\quad p+2,
\quad\frac{p+3}{4},
\quad\frac{p+7}{4},
\quad\frac{3p+1}{4}.
\]

The first, second, third, and fifth restrictions come from mod `4`, mod `8`, and Eisenstein-splitting filters; the present theorem completely specifies the mod-7 signed-divisor obstruction on the fourth shifted form.

## 5. Why this is useful

The theorem demonstrates that the fixed-k signed-product formulation is not merely computational packaging. For `k=7` it yields a complete human-scale obstruction classification.

The natural next targets are `k=11`, `19`, and other small `3 mod4` primes, followed by a simultaneous theorem showing that the resulting shifted-factor obstruction classes cannot all hold for one Mordell-hard prime.
