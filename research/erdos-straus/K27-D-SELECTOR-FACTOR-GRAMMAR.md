# Exact factor grammar of the k27 D selector

**Status:** exact cross-coordinate refinement inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k27_d_selector_factor_grammar.py`  
**Depends on:** the k27 seven-mode survivor grammar, QR-factor selectors, corrected phase-intersection theorem, and realized Route-B k19/k31 survivor modes.  
**Claim boundary:** exact necessary factor grammar conditional on the stated phase pair and k27 survival. Not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Correct phase pair

Assume

```text
tau17 = 6
tau31 = 7
```

so

`t = 193 mod527`.

For `E=7+30t`, these phases force

```text
17 | E
31 | E.
```

At k27 their residues are

```text
17 mod27 = 17   # nonresidue
31 mod27 = 4    # quadratic residue.
```

The landed phase selectors give

```text
tau17=6 -> k27 NR mode in {B,D}
tau31=7 -> k27 NR mode in {Q,A,D}.
```

Therefore a k27 miss forces

`k27 NR mode = D`.

## 2. D collapses to one exact NR occurrence skeleton

The complete D-mode NR skeletons are

```text
(2,17)
(14,14)
(2,14,14,14).
```

Rational prime17 is known to divide E, so the NR occurrence multiset must contain17.

Only one D skeleton does:

`(2,17)`.

Hence a k27 miss on this phase pair forces the exact NR occurrence grammar

```text
one occurrence 17 mod27
one occurrence 2 mod27
no other NR27 occurrences.
```

In particular

`v17(E)=1`.

The unique residue2 occurrence comes from one rational prime `r` with

`r = 2 mod27`,

and that prime also occurs to exponent exactly1.

## 3. The forced factor31 makes the QR completion rigid

The forced rational prime31 contributes QR residue4.

In the exact k27 transition table,

`D --4--> B`.

Mode B survives only QR residue1:

```text
B --1--> B
B --r--> HIT for r in {4,7,10,13,16,19,22,25}.
```

Therefore:

- the forced factor31 occurs exactly once, so `v31(E)=1`;
- every other QR27 prime-factor occurrence of E is `1 mod27`.

Thus the complete factor grammar is

`E = 17 * 31 * r * A`,

where

```text
r is prime,
r = 2 mod27,
v_r(E)=1,
every prime factor of A is 1 mod27.
```

No factorization of A is otherwise required.

## 4. k27 survival forces tau9=7

Modulo27, the forced non-1 factors contribute

`17 * 4 * 2 = 1 mod27`.

All factors of A are1 mod27. Therefore

`E = 1 mod27`.

But

`E = 7 + 30t = 7 + 3t mod27`.

Hence

`7 + 3t = 1 mod27`,

so

`t = 7 mod9`.

Therefore the exact three-coordinate implication is

```text
tau17=6
tau31=7
k27 miss
    -> k27 mode D
    -> tau9=7.
```

The originally independent tau9 coordinate is no longer free on this state.

## 5. Refined periodic class

Write the correct two-phase CRT class as

`t = 193 + 527n`.

Then

`E = 527(11+30n)`.

The factor grammar requires

`E/527 = 2 mod27`.

Thus

`11+30n = 2 mod27`,

which is equivalent to

`n = 6 mod9`.

Therefore

`t = 3355 mod4743`.

This is the exact periodic class for the surviving D-selector state.

## 6. Route-B ancestry form

On realized Route B,

`t = 705 + 1081u`.

The corrected two-phase selector is

`u = 469 mod527`.

The newly forced `tau9=7` is equivalent on Route B to

`u = 4 mod9`.

Combining them gives

`u = 3631 mod4743`.

So on Route B:

```text
tau17=6
tau31=7
survive k19,k27,k31
    -> k19 FULL_QR
    -> k27 exact factor grammar 17*31*r*A
    -> tau9=7
    -> k31 FULL_QR
    -> u=3631 mod4743.
```

The k19 and k31 FULL_QR conclusions are the already-landed mode consequences of the same phase pair.

## 7. Consequence for k35

Since `tau9=7`, the landed k35 3-adic theorem gives

`v3(F)=1`.

If the k35 survivor state contains the S7 branch, then rational prime3 is necessarily the distinguished S7 factor and

`every prime factor of F/3 is 1 mod7`.

This is conditional support refinement, not a forced choice between J35 and S7.

## 8. Machine consequence

The dependency grammar can strengthen the existing selector from

```text
tau17=6 + tau31=7 -> k27_mode=D
```

to

```text
tau17=6 + tau31=7 + k27 miss:
    k27_mode = D
    tau9 = 7
    v17(E) = 1
    v31(E) = 1
    E = 17*31*r*A
    r prime, r=2 mod27
    support(A) subset {q:q=1 mod27}.
```

This is a genuine propagation rule from phase state into factor-support state.

## 9. Bryan Entanglement Cross / BREC boundary

The phase pair first excavates the seven-mode k27 space to D, then exposes a rigid constructive factor grammar and a new forced phase. That path is a natural candidate for compound directional metadata such as

`↓ -> →`

or a richer BEC/BREC history.

The directional label is not part of the theorem. The exact skeleton and residue transitions above are the sole sources of mathematical force.

## 10. Next target

The exact factor grammar now gives a new surface for support interaction. The next high-value question is whether the forced prime `r=2 mod27` or the 1-mod27 reservoir A can coexist with the already-separated QR23, QR31, k35, and Route-B k47 support reservoirs under the affine companion equations.