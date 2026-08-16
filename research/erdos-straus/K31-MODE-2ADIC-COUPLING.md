# k31 survivor mode controls the 2-adic support seam

**Status:** exact product-state coupling inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k31_mode_2adic_coupling.py`  
**Depends on:** `K31-SURVIVOR-NORMAL-FORM.md` and `TEN-COFACTOR-ODD-SUPPORT-SEPARATION.md`  
**Claim boundary:** exact implication on h169 branches surviving k31. This is a product-state reduction, not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. The two exact k31 miss modes

For `p = 169 + 840t`, write `C31 = 10D`, with `D = 5 + 21t`.

The landed k31 theorem states that a miss occurs exactly when every rational prime factor of D is a nonzero quadratic residue modulo31. Conditional on a miss, the state has exactly two modes:

```text
BARE
FULL_QR
```

with BARE stabilizer `H31 = {1,5,25} mod31`.

Equivalently:

- BARE: every prime factor q of D lies in H31;
- FULL_QR: every prime factor q of D is QR31 and at least one occurrence lies outside H31.

## 2. BARE forces even t

The residue2 is a quadratic residue modulo31, but `2 notin H31`.

Meanwhile `D = 5 + 21t` has parity

```text
D odd  iff t even
D even iff t odd.
```

Therefore, if t is odd, the rational prime2 divides D. Since its residue2 is outside H31, a k31 miss at odd t cannot be BARE.

Hence the exact implication

`k31 BARE => t even`.

Equivalently,

`t odd AND k31 miss => k31 FULL_QR`.

In the odd case the factor2 itself supplies a definite QR31 residue outside the BARE stabilizer. Thus the formal product-state combination `(k31_mode=BARE, t odd)` is arithmetically impossible.

## 3. The landed ten-reservoir 2-adic seam

The local companion cofactors through k55 include

```text
B =  8 + 35t
D =  5 + 21t
G = 26 +105t
J =  9 + 35t
L =  4 + 15t.
```

The ten-cofactor support theorem proves the only nontrivial gcd edges are

```text
gcd(B,G) = gcd(2,t)
gcd(G,L) = gcd(2,t)
gcd(D,J) = gcd(2,t+1)
gcd(B,L) = gcd(4,t).
```

Thus parity determines which side of the local ladder carries the 2-adic overlap.

### Even t

```text
gcd(B,G)=2
gcd(G,L)=2
gcd(D,J)=1

gcd(B,L)=
  4 if t=0 mod4
  2 if t=2 mod4.
```

### Odd t

```text
gcd(B,G)=1
gcd(G,L)=1
gcd(B,L)=1
gcd(D,J)=2.
```

All other cofactor pairs remain coprime in both parity sectors.

## 4. Mode-to-seam theorem

Combining the two exact modules yields:

### BARE sector

If k31 is BARE, then t is even. Therefore the only possible support topology is the even B-G-L seam, with D and J disjoint at2. In particular

`k31 BARE => gcd(D,J)=1`.

### Odd FULL_QR sector

If t is odd and k31 misses, then k31 is necessarily FULL_QR and `gcd(D,J)=2`, while B,G,L are pairwise coprime.

### Even FULL_QR sector

FULL_QR may also occur at even t. In that case it shares the even seam topology with BARE but differs in the exact D-support mode.

So the product state `k31_mode × parity × support_seam` does not form a Cartesian product. The schematic states not excluded by this theorem are

```text
BARE     × EVEN_0   (t=0 mod4)
BARE     × EVEN_2   (t=2 mod4)
FULL_QR  × EVEN_0
FULL_QR  × EVEN_2
FULL_QR  × ODD
```

while `BARE × ODD` is impossible.

The list above is not an existence claim for every remaining tuple. It records exactly what this coupling theorem removes.

## 5. Why this matters to the candidate framework

This is an explicit elimination of a formal product-state combination using two previously independent-looking coordinates.

The state grammar should encode the dependency:

```text
if k31_mode == BARE:
    parity = EVEN
    gcd(D,J) = 1
    seam = EVEN_0 | EVEN_2

if parity == ODD and k31 misses:
    k31_mode = FULL_QR
    gcd(D,J) = 2
    seam = ODD
```

That is a genuine state reduction rule. No finite census is needed to apply it.

## 6. Bryan Entanglement Cross draft boundary

The in-draft Bryan Entanglement Cross may later annotate this theorem as a downward/excavation transition because an apparently independent state space is restricted to a smaller exact grammar.

That directional label is not part of the proof. The arithmetic implication exists independently of BEC and is the only source of pruning permission.

## 7. Next target

The strongest continuation is to find additional non-Cartesian couplings among `k27_mode × k31_mode × k35_branch × route-conditioned phase × support_seam`.

The landed Route-B k47 THIN/FULL_QR normal form is especially promising because its THIN mode also excludes rational prime2, allowing k31 and k47 modes to be coupled on the same Route-B ancestry.