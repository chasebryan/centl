# k35 survivor branch couples to the 3-adic phase

**Status:** exact product-state coupling inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k35_3adic_branch_coupling.py`  
**Depends on:** `K35-TWO-BRANCH-SURVIVOR-THEOREM.md`  
**Claim boundary:** exact implication on h169 branches surviving k35. This is a branch/valuation state reduction, not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Exact k35 survivor branches

For

`p = 169 + 840t`,

write

`C35 = 3F`,

with

`F = 17 + 70t`.

The landed exact theorem is

`k35 miss <=> J35(F) OR S7(F)`.

The two conditions are:

### J35

Every rational prime q dividing F satisfies

`(q/5)(q/7)=+1`.

Equivalently every q|F lies in the index-two subgroup H35.

### S7

`F=qR`, where q is prime, q=3 mod7, q occurs with exponent exactly1, and every prime factor of R is1 mod7.

Equivalently, among prime-factor occurrences of F, exactly one is3 modulo7 and every other occurrence is1 modulo7.

The branches may overlap.

## 2. The rational prime3 is special

The rational prime3 satisfies

`3 = 3 mod7`.

It also belongs to H35 because

`(3/5)=-1`

and

`(3/7)=-1`,

so their product is +1.

Thus additional powers of3 have opposite effects on the two survivor mechanisms:

- S7 can tolerate the prime3 only as the unique 3-mod7 occurrence and only to exponent1;
- J35 has no obstruction to repeated factors3 because residue3 lies in H35.

This creates an exact valuation-to-branch coupling.

## 3. Exact 3-adic phase of F

Modulo9,

`F = 17 + 70t = 8 + 7t mod9`.

Therefore

`9 | F <=> t = 4 mod9`.

Also

`3 | F <=> t = 1 mod3`.

The three t phases modulo9 with 3|F are

```text
t=1 mod9 : F=6 mod9  -> v3(F)=1
t=4 mod9 : F=0 mod9  -> v3(F)>=2
t=7 mod9 : F=3 mod9  -> v3(F)=1.
```

## 4. S7 is impossible when 9 divides F

Suppose

`t = 4 mod9`.

Then `3^2 | F`. Hence the prime-factor occurrence multiset of F contains rational prime3 at least twice.

Each of those occurrences is `3 mod7`.

But S7 requires exactly one 3-mod7 occurrence, and that occurrence must have exponent exactly1.

Therefore

`t = 4 mod9 => NOT S7(F)`.

Combining with the exact k35 iff theorem gives

`k35 miss AND t=4 mod9 => J35(F)`.

This removes the formal product-state combination

`S7 × (t=4 mod9)`.

No finite census enters the argument.

## 5. The neighboring single-3 phases

Suppose

`t = 1 mod9`

or

`t = 7 mod9`.

Then `v3(F)=1`.

If S7 holds, rational prime3 is already a 3-mod7 occurrence. Since S7 permits exactly one such occurrence, it must be the distinguished exceptional prime q.

Therefore on these phases

`S7(F) => F = 3R`

with

`every rational prime factor of R = 1 mod7`.

So the S7 branch becomes completely explicit whenever 3 divides F to first order.

Symbolically:

```text
t mod9 in {1,7}
AND S7
    -> distinguished q = 3
    -> F/3 has only 1-mod7 prime support.
```

## 6. Complete phase grammar modulo9

The resulting k35 branch/phase grammar is:

```text
t mod3 != 1:
    3 does not divide F;
    S7, if present, uses some prime q != 3 with q=3 mod7.

t mod9 in {1,7}:
    v3(F)=1;
    S7, if present, must use q=3 exactly once.

t mod9 = 4:
    v3(F)>=2;
    S7 impossible;
    k35 miss forces J35.
```

Because J35 and S7 may overlap on other phases, this theorem is not an exclusive global partition. Its exact pruning permission is the one-way implication above.

## 7. Realized-route forms

### Route A

Route A has

`t = 199 + 391u`.

Modulo9,

`t = 1 + 4u`.

Hence

```text
u=3 mod9 -> t=4 mod9 -> S7 impossible; k35 miss forces J35.
```

If Route-A S7 occurs while 3|F, then

```text
u mod9 in {0,6}
```

and the distinguished S7 prime is3.

### Route B

Route B has

`t = 705 + 1081u`.

Modulo9,

`t = 3 + u`.

Hence

```text
u=1 mod9 -> t=4 mod9 -> S7 impossible; k35 miss forces J35.
```

If Route-B S7 occurs while 3|F, then

```text
u mod9 in {4,7}
```

and again the distinguished S7 prime is3.

These are exact ancestry-conditioned phase rules.

## 8. Machine consequence

The k35 branch label and the 3-adic valuation/phase coordinate are not independent.

The exact state grammar can record

```text
if v3(F) >= 2:
    S7 = false
    if k35 misses: J35 = true

if v3(F) == 1 and S7:
    distinguished_S7_prime = 3
    support(F/3) subset {q: q=1 mod7}
```

This is a second species of non-Cartesian state reduction, independent of the k31/k47 2-adic seam coupling.

## 9. Bryan Entanglement Cross draft boundary

The in-draft Bryan Entanglement Cross may later annotate the passage from S7 possibility to forced J35 as downward/excavation followed by a sharpened surviving branch.

That annotation is not proof data. The exact 3-adic valuation and landed k35 iff theorem are the sole source of pruning permission.

## 10. Next target

The next useful intersection is to combine this k35 branch/valuation grammar with the route-conditioned phase state and the k31/k47 mode/seam grammar.

The objective is no longer to enumerate all formal tuples. It is to construct a reduced dependency graph in which phase, valuation, survivor mode, and support edges propagate constraints into one another before any new signed-box search is scheduled.
