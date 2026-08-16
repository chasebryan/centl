# Route-B k47 survivor normal form

**Status:** exact route-local module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_route_b_k47_survivor_normal_form.py`  
**Depends on:** realized Route B, exact k23 survivor support, and the landed k47 signed-box semantics  
**Claim boundary:** exact theorem on the realized h169 Route-B branch. It is not a universal decomposition method and not an Erdős–Straus proof.

## 1. Route B fixes the k47 phase

Write

`p = 169 + 840t`.

Realized Route B is

`p mod23 = 4`,

`p mod47 = 28`.

Since `169=28 mod47` and `840=41 mod47` is invertible, the second condition gives

`t = 0 mod47`.

Equivalently the exact route parameter is

`t = 705 + 1081u`.

The post-k23 cofactors are

`C23 = 6B`,  `B=8+35t`,

`C47 = 6J`,  `J=9+35t`.

Therefore

`J = B+1`.

On Route B,

`B = 8 mod47`,

`J = 9 mod47`,

and hence

`C47 = 7 mod47`.

In particular `47` never divides J.

## 2. Exact k47 state at the Route-B center

The mandatory k47 seed is `6=2*3`.

Its exact square-divisor residue mask is

`M6={1,2,3,4,6,9,12,18,36}`

with center6 modulo47.

The complete exact k47 unit-residue closure has

```text
1079 states
196 misses.
```

At the Route-B center

`C47=7 mod47`

there are exactly **two** miss states.

### FULL_QR

The first mask is the complete quadratic-residue set modulo47:

`QR47={1,2,3,4,6,7,8,9,12,14,16,17,18,21,24,25,27,28,32,34,36,37,42}`.

Its size is23.

### THIN

The second mask is

`T47={1,2,3,4,6,7,8,9,12,14,16,18,21,24,27,32,34,36,42}`.

Its size is19.

Equivalently

`T47 = QR47 \ {17,25,28,37}`.

There are no other Route-B k47 miss masks.

## 3. Exact QR-support theorem

The Type-I target at k47 is

`-4^{-1}=35 mod47`.

The Route-B Type-II target is

`-C47=-7=40 mod47`.

Both 35 and40 are quadratic nonresidues modulo47.

The seed primes2 and3 are quadratic residues modulo47.

### Theorem

On realized Route B,

`k47 miss  <=>  every rational prime factor q of J is QR mod47`.

### QR direction

If every q dividing J is QR modulo47, then every divisor of

`C47^2=(6J)^2`

is QR modulo47. Both exact signed-box targets35 and40 are nonresidues, so neither can occur.

Hence k47 misses.

### Converse

The complete exact center-7 closure has only FULL_QR and THIN as misses, and both masks are subsets of QR47.

If a rational prime q dividing J were a quadratic nonresidue modulo47, then q itself is a divisor of `C47^2`, so its residue must occur in the final divisor mask. That mask could not equal either exact miss mask.

Because `47∤J`, there is no zero-residue exception.

Hence every q dividing J must be QR modulo47.

This is an exact iff theorem, not a finite prime census.

## 4. Lossless two-mode compression

Conditional on Route B and a k47 miss, the full signed-box state compresses losslessly to

`k47_mode = THIN | FULL_QR`.

The QR-only closure from the seed has only66 states, and exactly two of them have final center7: THIN and FULL_QR.

So after the QR-support theorem there is no hidden third survivor geometry.

## 5. Exact THIN factor grammar

Prime-factor **occurrences** are counted with multiplicity.

Because a factor transition multiplies the mask by `{1,r,r^2}`, every old mask element remains present. Masks are therefore monotone under factor insertion.

Factor transitions also commute, so occurrences can be reordered without changing the final state.

Among all66 QR-only states, exactly three masks lie inside T47:

1. the seed state `M6`, center6;
2. a 15-element intermediate state, center18;
3. T47 itself, center7.

The only QR transitions that remain inside T47 are

```text
M6   --1--> M6
M6   --3--> intermediate
M6   --9--> T47

intermediate --1--> intermediate
intermediate --3--> T47

T47 --1--> T47.
```

Every other QR residue exits T47 irreversibly.

Therefore:

### THIN theorem

Route-B k47 is THIN iff, after deleting all prime-factor occurrences congruent to1 modulo47, the remaining residue multiset of J is exactly one of

`{9}`

or

`{3,3}`.

Equivalently:

- either exactly one prime-factor occurrence of J is `9 mod47` and every other occurrence is `1 mod47`;
- or exactly two prime-factor occurrences are `3 mod47` and every other occurrence is `1 mod47`.

All multiplicities are literal. For example a prime `q=3 mod47` appearing with exponent2 contributes the `{3,3}` alternative.

## 6. FULL_QR theorem

Conditional on every q|J being QR modulo47 and `J=9 mod47`, every factorization not satisfying the THIN grammar lands in FULL_QR.

Thus the complete route-local classification is

```text
some q|J is NR47          -> k47 hit
all q|J are QR47
    |
    +-- non-1 residues {9} or {3,3} -> THIN miss
    |
    `-- otherwise                   -> FULL_QR miss.
```

## 7. Coupling to k23

The landed k23 theorem on the realized routes gives

`k23 miss => every rational prime factor of B is QR mod23`.

Route B now adds

`k47 miss => every rational prime factor of B+1 is QR mod47`.

Since

`J=B+1`,

we have

`gcd(B,J)=1`.

A simultaneous k23/k47 Route-B survivor therefore carries two consecutive, disjoint support reservoirs:

```text
B     : QR23 support
B + 1 : QR47 support, with THIN | FULL_QR mode.
```

The exact route relation with the k19 residual is

`6B - 1081R = 1`,

hence

`6J - 1081R = 7`.

On Route B, `R=137+210u=4 mod7`, so `gcd(R,J)=1` as well.

## 8. Framework consequence

This is stronger than the coarse k47 phase filter for Route B.

The phase filter says only that `t=0 mod47` is not automatically absorbed. The route-local normal form says exactly what survival at that phase costs:

1. every prime of the new consecutive cofactor `B+1` must lie in QR47;
2. the entire k47 miss state has only two modes;
3. the exceptional THIN mode has a two-pattern factor grammar;
4. the new support is disjoint from both B and R.

That is a genuine compressed transition state for the developing decomposition framework.

The next target is to intersect

`QR23(B)`

with

`QR47(B+1) + {THIN,FULL_QR}`

and the landed k27/k31/k35 support grammars under the affine companion chain, looking for impossible product states or a forced later selector.

Erdős–Straus remains open.
