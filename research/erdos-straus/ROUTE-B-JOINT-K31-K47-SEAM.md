# Route-B joint k31/k47 mode and 2-adic seam

**Status:** exact product-state coupling inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_route_b_joint_k31_k47_seam.py`  
**Depends on:** `K31-MODE-2ADIC-COUPLING.md`, `ROUTE-B-K47-SURVIVOR-NORMAL-FORM.md`, and `TEN-COFACTOR-ODD-SUPPORT-SEPARATION.md`  
**Claim boundary:** exact implication on realized Route B conditional on simultaneous k31/k47 survival. This is a state-grammar reduction, not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Route-B ancestry

Realized Route B has

`C19 = 1081R`

and the exact parameterization

`t = 705 + 1081u`.

The relevant later cofactors are

```text
C31 = 10D,   D = 5 + 21t
C47 =  6J,   J = 9 + 35t.
```

The landed support theorem gives

`gcd(D,J) = gcd(2,t+1)`.

Because 705 and1081 are both odd,

```text
t even iff u odd
t odd  iff u even.
```

Thus Route-B ancestry already turns parity into a branch-local state coordinate.

## 2. k31 mode pressure from the rational prime2

Conditional on a k31 miss, the exact modes are

`BARE | FULL_QR`.

BARE requires every prime factor of D to lie in

`H31 = {1,5,25} mod31`.

The rational prime2 satisfies

`2 in QR31`

but

`2 notin H31`.

Since D is even exactly when t is odd,

`t odd AND k31 miss => k31_mode = FULL_QR`.

Equivalently

`k31_mode = BARE => t even`.

## 3. k47 mode pressure from the same rational prime2

On Route B, conditional on a k47 miss, the exact modes are

`THIN | FULL_QR`.

The THIN factor-occurrence grammar says that after deleting every prime-factor occurrence congruent to1 modulo47, the remaining multiset must be exactly

`{9}`

or

`{3,3}`.

The rational prime2 has residue2 modulo47. It is a QR47 residue, so its presence does not force a k47 hit, but residue2 is not allowed by the THIN grammar.

Since

`J = 9 + 35t`

is even exactly when t is odd, any odd-t Route-B k47 miss contains the prime-factor occurrence2 and therefore cannot be THIN.

Hence

`t odd AND k47 miss => k47_mode = FULL_QR`.

Equivalently

`k47_mode = THIN => t even`.

## 4. Joint mode/seam theorem

Assume realized Route B survives both k31 and k47.

### Odd sector

If t is odd, then D and J are both even and

`gcd(D,J)=2`.

The shared rational prime2 simultaneously forces

```text
k31_mode = FULL_QR
k47_mode = FULL_QR.
```

Therefore the odd support seam has exactly one possible mode pair:

`(FULL_QR31, FULL_QR47, ODD_SEAM)`.

Equivalently, every odd-sector mode pair containing BARE31 or THIN47 is impossible.

### Even sector

If t is even, then D and J are odd and

`gcd(D,J)=1`.

The factor2 obstruction disappears from both mode grammars. The local theorems therefore do not by themselves eliminate any of the four mode pairs

```text
BARE31    × THIN47
BARE31    × FULL_QR47
FULL_QR31 × THIN47
FULL_QR31 × FULL_QR47.
```

This statement is deliberately non-existential: it says these four pairs are not excluded by the present coupling theorem, not that every pair has an arithmetic realization.

The even sector further splits by t modulo4 into the landed support seams

```text
EVEN_0: gcd(B,L)=4
EVEN_2: gcd(B,L)=2
```

with `gcd(D,J)=1` in both.

## 5. Exact forbidden product states

At the coarse parity level, the naive Cartesian state

`{BARE31,FULL_QR31} × {THIN47,FULL_QR47} × {EVEN,ODD}`

contains eight formal combinations.

The exact arithmetic removes three:

```text
BARE31    × THIN47    × ODD
BARE31    × FULL_QR47 × ODD
FULL_QR31 × THIN47    × ODD.
```

Only

`FULL_QR31 × FULL_QR47 × ODD`

survives in the odd sector.

If the even seam is refined to `EVEN_0 | EVEN_2`, the naive 12-state mode/seam product contracts to nine not-excluded schematic states:

- four mode pairs over EVEN_0;
- four mode pairs over EVEN_2;
- one FULL_QR/FULL_QR pair over ODD.

Again, “not excluded” is not an existence claim.

## 6. Route-parameter form

Because

`t = 705 + 1081u`,

we can state the theorem directly in the Route-B ancestry coordinate:

```text
u even -> t odd
        -> gcd(D,J)=2
        -> k31 FULL_QR and k47 FULL_QR

u odd  -> t even
        -> gcd(D,J)=1
        -> BARE/FULL_QR at k31 and THIN/FULL_QR at k47 remain locally possible.
```

This is an exact branch-local transition grammar.

## 7. BARE phase shadow inside Route B

The k31 BARE support group is H31. Since

`D = 5 + 21t mod31`,

BARE also forces

`t mod31 in {0,19,29}`.

On Route B, `t=705+1081u` reduces to

`t = 23 + 27u mod31`,

so

`k31 BARE => u mod31 in {1,14,29}`.

Combining with the already-proved `u odd` condition gives

`k31 BARE => u mod62 in {1,29,45}`.

This is a mode-conditioned phase refinement, not a converse: those u-classes need not realize BARE.

## 8. Machine consequence

The state coordinates

`k31_mode`, `k47_mode`, `parity`, and `D-J support seam`

cannot be modeled independently on Route B.

The exact grammar can be encoded as

```text
if seam == ODD:
    k31_mode = FULL_QR
    k47_mode = FULL_QR

if k31_mode == BARE or k47_mode == THIN:
    seam = EVEN
    gcd(D,J) = 1
```

This is a stronger product-state reduction than either local normal form alone.

## 9. Bryan Entanglement Cross draft boundary

The in-draft Bryan Entanglement Cross may later annotate this as downward/excavation pressure: the same exact 2-adic edge removes several formal product states at once.

That description is observational only. The factor-support and mode theorems are the proof-bearing objects and are the sole source of pruning permission.

## 10. Next target

The next high-value coupling is k35 branch versus phase. In particular, `3^2 | F` is incompatible with the S7 branch's unique exponent-one `3 mod7` occurrence. That should remove S7 on an exact t modulo9 phase and give another non-Cartesian state rule independent of the 2-adic seam.
