# Ten-cofactor odd-support separation through k55

**Status:** exact algebraic module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Stack:** child of the five-cofactor support-separation theorem  
**Verifier:** `verify_ten_cofactor_odd_support_separation.py`  
**Claim boundary:** exact support-separation theorem on the two realized h169 k19 routes. This is not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Complete local companion coordinates

On either realized h169 k19 route write

`C19 = SR = 47 + 210t`,

where

- Route A: `S=391=17*23`;
- Route B: `S=1081=23*47`.

The post-k19 companion ladder through k55 is consecutive:

```text
C19 = SR
C23 = SR+1 =  6B
C27 = SR+2 =  7E
C31 = SR+3 = 10D
C35 = SR+4 =  3F
C39 = SR+5 =  2G
C43 = SR+6 =    H
C47 = SR+7 =  6J
C51 = SR+8 =  5K
C55 = SR+9 = 14L
```

Equivalently,

```text
B =  8 + 35t
E =  7 + 30t
D =  5 + 21t
F = 17 + 70t
G = 26 +105t
H = 53 +210t
J =  9 + 35t
K = 11 + 42t
L =  4 + 15t
```

The parent theorem proves `R,B,E,D,F` pairwise coprime. The present theorem extends the support analysis across all ten cofactor reservoirs.

## 2. Main theorem

For either realized route, the **odd parts** of

`R,B,E,D,F,G,H,J,K,L`

are pairwise coprime.

Equivalently:

> no odd rational prime divides two distinct cofactor reservoirs anywhere in the k19..k55 local ladder.

The only possible support recycling is 2-adic, and it is completely explicit:

```text
gcd(B,G) = gcd(2,t)
gcd(G,L) = gcd(2,t)
gcd(D,J) = gcd(2,t+1)
gcd(B,L) = gcd(4,t)
```

Every other pair among the ten cofactors has gcd exactly1.

Thus the complete overlap graph has only four edges, all carrying powers of2:

```text
B --2-- G --2-- L
|              /
+---- <=4 ----+

D --2-- J
```

and there are no odd-support edges at all.

## 3. Why R is disjoint from the full later ladder

For Route A,

`R = 107 + 210u`.

For Route B,

`R = 137 + 210u`.

Hence on both routes R is odd and

`R != 0 mod3,5,7`.

If a prime q divides R and a later cofactor attached to `SR+a`, then q divides both `SR` and `SR+a`, so q divides a.

For `1 <= a <= 9`, every possible odd prime divisor of a lies in `{3,5,7}`. None divides R. Since R is also odd,

`gcd(R,Q)=1`

for every

`Q in {B,E,D,F,G,H,J,K,L}`.

This extends the parent five-reservoir theorem all the way through k55.

## 4. Odd-prime separation among B..L

Let `Q_a=(SR+a)/m_a` and `Q_b=(SR+b)/m_b` be two distinct later cofactors.

If an odd prime q divides both, then q divides

`m_a Q_a = SR+a`

and

`m_b Q_b = SR+b`.

Therefore

`q | (b-a)`.

Because `1 <= a < b <= 9`, any such odd q must be one of

`3,5,7`.

It remains only to rule out simultaneous divisibility by those small primes.

The cofactor residues are:

```text
       mod3       mod5       mod7
B    2+2t          3          1
E      1            2         2t
D      2            t          5
F    2+t            2          3
G      2            1          5
H      2            3          4
J     2t            4          2
K      2          1+2t         4
L      1            4         4+t
```

Only pairs whose offsets differ by a multiple of3,5,or7 need checking. In every such pair, the two zero conditions are incompatible. Therefore no odd prime can occur in two different later cofactors.

## 5. Exact 2-adic seam

Parity is equally rigid:

```text
B even iff t even
E always odd
D even iff t odd
F always odd
G even iff t even
H always odd
J even iff t odd
K always odd
L even iff t even
```

So only the pairs inside `{B,G,L}` and `{D,J}` can share2.

The exact affine identities give sharp gcd bounds:

```text
G - 3B   = 2
7L - G   = 2
7L - 3B  = 4
3J - 5D  = 2
```

Combining those identities with parity yields

```text
gcd(B,G) = 2 if t even, else 1
gcd(G,L) = 2 if t even, else 1
gcd(D,J) = 2 if t odd,  else 1

gcd(B,L) =
  4  if t = 0 mod4
  2  if t = 2 mod4
  1  if t is odd
```

which is exactly the compact formula stated above.

## 6. Framework consequence

The local state should no longer be thought of as several support conditions that might reuse the same lucky primes.

It is a collection of **independent odd-prime reservoirs**:

```text
R | B | E | D | F | G | H | J | K | L
```

with only the explicitly controlled 2-adic seam.

Therefore a simultaneous survivor must satisfy the local support grammars by allocating distinct odd rational primes to distinct companion coordinates.

In particular, constraints already proved at k19, k23, k27, k31, and k35 cannot be silently paid for by the same odd factors, and any later support theorem at k39..k55 will automatically inherit this separation.

This is a structural strengthening of the support-renewal principle: freshness is not merely frequent. Odd support is **globally non-recyclable across the entire ten-coordinate local ladder**.

## 7. Relation to phase-volume contraction

The landed exact phase contraction through k55 and its ancestry-conditioned refinement measure a different coordinate:

- phase contraction restricts the allowed residue class of t;
- support separation restricts how prime factors can be distributed across companion coordinates.

Neither subsumes the other.

Their eventual intersection is the natural candidate framework state:

`phase class × survivor modes × separated support reservoirs × affine coupling`.

That product state is substantially more rigid than any one coordinate alone.

## 8. Bryan Entanglement Cross draft boundary

The developing Bryan Entanglement Cross is not part of this proof predicate.

If that layer lands later, support separation is naturally interpretable as excavation/restriction metadata, while any forced certificate remains constructive/terminal metadata. The arithmetic theorem itself is independent of those annotations.

## 9. Next theorem target

Use the odd-support separation together with the landed support grammars to test **arithmetic realizability of the formal product state**.

The first target should be to prove that selected combinations of

`k27 mode × k31 mode × k35 branch × phase class`

cannot be realized because their required prime-residue reservoirs conflict with the affine companion identities despite being support-disjoint.

That would be a genuine product-state elimination theorem, rather than another local fixed-shift classification.
