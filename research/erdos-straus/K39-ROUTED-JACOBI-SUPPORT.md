# Routed k=39 Jacobi-plus factor-support theorem

**Status:** exact fixed-shift finite-group theorem  
**Date:** 2026-08-16  
**Depends on:** `K11-CHARACTER-COMPANION-ROUTING.md`  
**Verifier:** `verify_k39_routed_jacobi_support.py`  
**Claim boundary:** exact on the stated routed fixed-shift branch. It does not prove a universal cover or Erdős-Straus.

## 1. Routed branch

For Mordell-hard primes in

```text
h = 169, 289, or 529 mod 840,
```

a fixed k=11 miss forces

```text
(11/p) = +1.
```

On the route

```text
p mod11 = 5,
```

the character-to-companion routing theorem gives

```text
11 divides C39 = (p+39)/4.
```

The class-conditioned k=39 seed is 2, so the complete routed seed is

```text
22 = 2*11.
```

The exact seed-22 state closure contains

```text
83 states
45 hard-admissible states
9 misses.
```

## 2. The hidden index-two subgroup

The nine misses were first observed to lie entirely on the positive Legendre-13 center branch. A stronger inspection of the complete divisor masks shows that every divisor residue in every miss belongs to the same index-two subgroup of `(Z/39Z)^x`:

```text
1, 2, 4, 5, 8, 10, 11, 16, 20, 22, 25, 32 mod39.
```

This set is exactly the kernel of the Jacobi character

```text
(a/39) = (a/3)(a/13).
```

Thus every exact routed miss-state divisor mask is contained in

```text
J39+ = {a : (a/39)=+1}.
```

The miss centers themselves also lie in J39+.

## 3. Exact factor-support equivalence

Every prime factor q of C39 occurs as an exponent-one divisor residue in the divisor-square box of C39 squared. Therefore, if a routed k=39 miss occurs, every such prime factor must satisfy

```text
(q/39) = +1.
```

Conversely, suppose every prime factor q of C39 satisfies

```text
(q/39) = +1.
```

Then every divisor residue of C39 squared lies in J39+.

The two fixed-shift targets lie in the opposite Jacobi coset. In particular,

```text
(-1/4)/39 = -1,
```

and because C39 is Jacobi-positive on this routed branch,

```text
(-C39)/39 = -1.
```

Neither target can therefore occur in the divisor-square box.

### Theorem

For

```text
h in {169,289,529},
p mod11 = 5,
```

the following are equivalent:

```text
fixed k=39 misses
```

and

```text
every prime factor q of C39 satisfies (q/39)=+1.
```

The earlier corollary

```text
(13/p)=-1 => k=39 hits
```

is only a projection of this stronger support theorem.

## 4. Position in the six-companion wheel

In the wheel

```text
27, 31, 35, 39, 43, 47,
```

the universal seed decomposition gives

```text
C39 = 2*R3.
```

The routed factor 11 therefore satisfies

```text
11 divides R3.
```

The six-companion residual theorem pins 11 to this residual alone because 11 is neither 2 nor 5.

Moreover, 2 itself has Jacobi symbol +1 modulo39. Hence a routed k=39 miss implies

```text
every prime factor of R3 has Jacobi symbol +1 modulo39.
```

So the routed branch now provides both a forced prime location and a full support class for R3.

This mirrors the p mod11=9 routed k=35 result, where factor 11 is pinned to R2 and every prime factor of R2 lies in the Jacobi-plus subgroup modulo35.

## 5. Two-residual route now available

If the k=39 miss additionally has

```text
p mod13 = 4,
```

then the positive 13-character routes factor 13 into C35. Since

```text
C35 = 3*R2,
```

13 is pinned to R2, while 11 remains pinned to R3.

The remaining exact question is then a neighboring-residual support problem:

```text
R2 = 2n+1 has a forced factor 13 and k35 miss constraints,
R3 = 3n+2 has a forced factor 11 and Jacobi-plus support mod39,
2*R3 - 3*R2 = 1,
gcd(R2,R3)=1.
```

This does not yet yield a contradiction, but it is a substantially sharper cross-shift object than independent character signs.

## 6. Reproduction

Run

```sh
python3 research/erdos-straus/verify_k39_routed_jacobi_support.py --json
```

The script recomputes the complete seed-22 closure and verifies every miss divisor mask, every center, the complete Jacobi-plus subgroup, and the Jacobi signs of the fixed-shift targets.

Erdős-Straus remains open.
