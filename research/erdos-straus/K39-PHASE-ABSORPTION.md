# Exact k39 phase absorption on h169

**Status:** exact range-free transition module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k39_phase_absorption.py`  
**Depends on:** the landed post-k23 companion ladder and exact signed-box Type-I/II semantics  
**Claim boundary:** exact h169 congruence theorem at k39. It is not a universal shift bound, a closed decomposition method, or an Erdős–Straus proof.

## 1. Normalize k39

Write

`p = 169 + 840t`.

Then

`C39 = (p+39)/4 = 52 + 210t = 2G`,

with

`G = 26 + 105t`.

Modulo3,

`G = 2 mod3`,

so 3 never divides G.

Modulo13,

`G = t mod13`.

Thus the k39 arithmetic splits exactly by the phase

`t mod13`.

The Type-I target is

`-4^{-1} = 29 mod39`.

## 2. Phase t=0 mod13 is an immediate Type-II hit

If

`t = 0 mod13`,

then 13 divides G. Since `G=2 mod3`, write

`G=13H` with `H=2 mod3`.

Then

`C39=26H = 13 mod39`.

Hence the Type-II target is

`-C39 = 26 mod39`.

But 26 divides C39 itself, so it certainly divides `C39^2`.

Therefore

`t=0 mod13 => k39 Type-II hit`,

with the fixed divisor witness

`d=26`.

No factor search is needed in this phase.

## 3. The unit branch

Assume now

`t != 0 mod13`.

Then G is coprime to39. Start from the mandatory factor2, whose square-divisor mask is

`{1,2,4} mod39`,

and adjoin the prime-factor residues of G through the exact transition

`(M,c) -> (M*{1,r,r^2}, c*r)`.

The complete closure under the24 units modulo39 contains

```text
394 exact states
74 misses
320 hits.
```

For h169 the final center is

`C39 = 13 + 15t mod39`.

Each nonzero phase t mod13 selects one exact unit center.

## 4. Exact phase table

The complete endpoint counts are:

| t mod13 | C39 mod39 | endpoint states | misses |
|---:|---:|---:|---:|
| 1 | 28 | 14 | 2 |
| 2 | 4 | 19 | 4 |
| 3 | 19 | 20 | **0** |
| 4 | 34 | 20 | **0** |
| 5 | 10 | 11 | 6 |
| 6 | 25 | 14 | 3 |
| 7 | 1 | 19 | 6 |
| 8 | 16 | 11 | 2 |
| 9 | 31 | 20 | 4 |
| 10 | 7 | 20 | 6 |
| 11 | 22 | 14 | 3 |
| 12 | 37 | 14 | **0** |

Therefore three unit phases have no exact survivor state at all:

`{3,4,12}`.

Together with the direct nonunit phase0 theorem, k39 absorbs four of the thirteen h169 t-phases.

## 5. Phase-absorption theorem

### Theorem

For

`p=169+840t`,

if

`t mod13 in {0,3,4,12}`,

then the exact k39 signed box hits.

Equivalently, any h169 branch surviving k39 must satisfy

`t mod13 in {1,2,5,6,7,8,9,10,11}`.

This is a range-free congruence theorem.

In terms of p modulo

`840*13 = 10920`,

the four absorbed h169 classes are

```text
p =   169 mod10920
p =  2689 mod10920
p =  3529 mod10920
p = 10249 mod10920.
```

## 6. Why this is a transition rule

The previous local modules describe survivor support at k27, k31, and k35. k39 now adds a different kind of exact progress:

```text
survive k27/k31/k35
        |
        v
inspect t mod13
        |
        +-- 0,3,4,12 -> exact k39 decomposition
        |
        `-- nine residual phases -> continue
```

The state space contracts before any deeper factor-support analysis at k39 is needed.

The theorem does not claim the remaining nine phases survive. It says only that they are the only phases in which a k39 miss is arithmetically possible.

## 7. Current local residual state

A branch surviving through k39 must now carry simultaneously:

```text
B : QR23 support
E : exact k27 seven-mode grammar
D : QR31 support
F : J35 OR S7
t mod13 : one of {1,2,5,6,7,8,9,10,11}
```

with the landed pairwise-coprime affine companion chain.

This is the developing decomposition framework behaving as intended: each rung either terminates the branch or compresses its exact survivor state.

Erdős–Straus remains open.
