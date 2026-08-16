# Exact k51 phase absorption on h169

**Status:** exact range-free transition module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k51_phase_absorption.py`  
**Depends on:** the post-k23 companion ladder and exact signed-box Type-I/II semantics  
**Claim boundary:** exact h169 congruence theorem at k51. It is not a universal depth bound, a closed decomposition method, or an Erdős–Straus proof.

## 1. Normalize k51

Write

`p = 169 + 840t`.

Then

`C51 = (p+51)/4 = 55 + 210t = 5U`,

where

`U = 11 + 42t`.

The cofactor satisfies

`U = 2 mod3`

and

`U = 11 + 8t mod17`.

Hence

`17 | U  <=>  t = 5 mod17`.

The Type-I target is

`-4^{-1} = 38 mod51`.

## 2. The nonunit phase t=5 is an immediate Type-II hit

If

`t = 5 mod17`,

then `17|U`, so the divisor

`d=17`

is available in `C51^2`.

The hard-class center at that phase is

`C51 = 34 mod51`,

so the exact Type-II target is

`-C51 = 17 mod51`.

Therefore

`t=5 mod17 => k51 Type-II hit via d=17`.

This is factorization-free beyond the forced factor17.

## 3. Exact unit residue-state closure

For every other phase, U is coprime to51. Start from the mandatory seed5:

`M0={1,5,25}`, center5.

Each prime-factor occurrence of U with unit residue r modulo51 applies the exact transition

`(M,c) -> (M*{1,r,r^2}, c*r)`.

The complete closure under all32 units modulo51 contains

```text
1403 states
1159 hits
 244 misses.
```

The hit mechanisms are

```text
Type I only       392
Type II only      225
Type I + Type II  542
miss              244.
```

Repeated residues represent prime powers exactly, so this closure covers arbitrary factorizations of every unit U.

## 4. Exact h169 phase table

The hard-class center is

`C51 = 4 + 6t mod51`,

which has period17 in t.

| t mod17 | C51 mod51 | miss states |
|---:|---:|---:|
| 0 | 4  | 10 |
| 1 | 10 | 8 |
| 2 | 16 | 5 |
| 3 | 22 | 6 |
| 4 | 28 | **0** |
| 5 | 34 | nonunit, forced Type II |
| 6 | 40 | 12 |
| 7 | 46 | **0** |
| 8 | 1  | 8 |
| 9 | 7  | 9 |
| 10 | 13 | 16 |
| 11 | 19 | 9 |
| 12 | 25 | 14 |
| 13 | 31 | 12 |
| 14 | 37 | **0** |
| 15 | 43 | 6 |
| 16 | 49 | 3 |

Thus the unit phases 4, 7, and 14 have no exact miss state.

## 5. Phase-absorption theorem

### Theorem

For

`p=169+840t`,

if

`t mod17 in {4,5,7,14}`,

then the exact k51 signed box hits.

Equivalently, a k51 survivor must satisfy

`t mod17 in {0,1,2,3,6,8,9,10,11,12,13,15,16}`.

In p-coordinates modulo

`840*17 = 14280`,

the absorbed h169 classes are

```text
p =  3529 mod14280
p =  4369 mod14280
p =  6049 mod14280
p = 11929 mod14280.
```

This theorem is range-free. It comes from the forced factor17 phase plus a complete finite residue-state closure, not from a bounded prime census.

## 6. Relation to the universal selector shell

None of these four absorbed phases is explained by the universal trivial-divisor shell using `d in {1,C,C^2}`.

The shell conditions

```text
C=-1
C=0
C=-4^{-1}
C(C+1)=0
4C^2=-1
```

have no h169 solution in the 17 center phases at k51.

Therefore k51 contributes genuinely additional exact-state absorption beyond the cheap selector layer.

The phase `t=5` is nevertheless simple: it is a nontrivial fixed divisor selector `d=17` forced by the composite modulus51.

## 7. Framework role

The local machine now obtains another deterministic contraction:

```text
survive earlier rungs
       |
       v
inspect t mod17
       |
       +-- 4,5,7,14 -> exact k51 decomposition
       |
       `-- 13 residual phases -> continue
```

This can be intersected with the already proved restrictions at k39 and k47 without introducing heuristic pruning.

Erdős–Straus remains open.
