# Universal signed-box trivial-divisor selectors

**Status:** exact algebraic module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_signed_box_trivial_divisor_selectors.py`  
**Claim boundary:** universal selector identities inside the exact signed box. This is not a complete signed-box criterion and not an Erdős–Straus proof.

## 1. Setup

For an admissible odd shift k, write

`C=(p+k)/4`.

The exact signed-box targets are:

```text
Type I : d | C^2 and 4d = -1 mod k
Type II: d | C^2 and d  = -C mod k.
```

Three divisors require no factorization at all:

`1`, `C`, and `C^2`.

They form a universal selector shell.

## 2. Type-II selectors

### d=1

The condition is

`1 = -C mod k`,

so

`C = -1 mod k`.

### d=C

The condition is

`C = -C mod k`,

or

`2C = 0 mod k`.

Since k is odd, 2 is invertible, hence

`C = 0 mod k`.

### d=C^2

The condition is

`C^2 = -C mod k`,

or

`C(C+1) = 0 mod k`.

For prime k this adds nothing beyond `C=0` and `C=-1`, but for composite k it can create additional CRT-root phases.

## 3. Type-I selectors

### d=1

The condition is

`4 = -1 mod k`,

so k divides5. This is irrelevant to the post-k23 ladder but belongs to the exact shell.

### d=C

The condition is

`4C = -1 mod k`,

so

`C = -4^{-1} mod k`.

### d=C^2

The condition is

`4C^2 = -1 mod k`.

Equivalently

`(2C)^2 = -1 mod k`.

This can produce extra phases only when -1 is a quadratic residue modulo the relevant modulus components.

## 4. Prime k = 3 mod4

Let k>3 be prime with

`k = 3 mod4`.

Then -1 is a quadratic nonresidue modulo k, so

`4C^2 = -1 mod k`

has no solution.

The trivial shell therefore reduces to exactly three center conditions:

```text
C = -1       mod k -> Type II via d=1
C =  0       mod k -> Type II via d=C
C = -4^{-1}  mod k -> Type I  via d=C.
```

These are factorization-free exits.

## 5. k43 example

For h169,

`C43 = 53 + 210t = 10 - 5t mod43`.

Since43 is prime and `43=3 mod4`, the shell gives:

```text
C43=0        -> t=2  mod43
C43=-1       -> t=28 mod43
C43=-4^{-1}  -> t=30 mod43.
```

Thus

`t mod43 in {2,28,30}`

forces an exact k43 decomposition without factoring C43.

The explicit selectors are:

```text
t=2  : Type II, d=C43
t=28 : Type II, d=1
t=30 : Type I,  d=C43.
```

## 6. Type-II root geometry of the shell

The Type-II members of the shell are entirely López-boundary geometry.

### d=1

`d=1`, `C^2/d=C^2` gives

`(s,b,c)=(1,1,C)`,

so `b|c`: López Type A.

### d=C

Write

`C=s u^2`

with s squarefree. Then

`d=s u^2`

and

`C^2/d=s u^2`,

so

`b=c=u`.

This is the diagonal intersection of the two comparable-root sectors.

### d=C^2

`(s,b,c)=(1,C,1)`,

so `c|b`: López Type B.

Therefore this universal selector shell is a **boundary mechanism** inside the larger exact Type-II geometry. It is useful as an early deterministic exit, but it is not the source of the incomparable-root certificates already observed elsewhere in the live ancestry.

## 7. Framework role

The candidate machine can test this shell before any factorization-dependent signed-box logic:

```text
state (p,k,C)
   |
   +-- C=-1       -> Type II d=1
   +-- C=0        -> Type II d=C
   +-- C=-4^{-1}  -> Type I  d=C
   +-- composite-only C(C+1)=0 -> Type II d=C^2
   +-- 4C^2=-1    -> Type I  d=C^2
   `-- otherwise  -> factor-support / full signed-box geometry
```

This is a genuine selector component: deterministic, exact, factorization-free, and compatible with the hierarchy in which López A/B remains a boundary family rather than the governing search space.

Erdős–Straus remains open.
