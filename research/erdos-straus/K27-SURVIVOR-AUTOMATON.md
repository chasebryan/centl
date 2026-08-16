# Exact h169 k27 survivor automaton

**Status:** proved fixed-shift module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Primary verifier:** `verify_k27_survivor_automaton.py`  
**Depends on:** `POST-K23-COMPANION-LADDER.md`, `K31-SURVIVOR-NORMAL-FORM.md`, exact signed-box Lane-I semantics  
**Claim boundary:** exact h169 fixed-shift state theorem at k27 plus exact behavioral minimization. This is not yet a universal transition theorem, not a universal shift ceiling, and not an Erdős–Straus proof.

---

## 1. Local coordinate

For

`p = 169 + 840t`,

we have

`C27 = (p+27)/4 = 49 + 210t = 7E`,

with

`E = 7 + 30t`.

In particular,

`E = 1 mod3`.

Therefore every rational prime factor of `E` is a unit modulo27. This makes the complete local factor alphabet exactly

`U(27) = {1,2,4,5,7,8,10,11,13,14,16,17,19,20,22,23,25,26}`.

The mandatory seed factor is7.

---

## 2. Exact state transition

Represent a partially accumulated factor state by

`(M,c)`,

where

- `M` is the complete residue mask modulo27 of divisors of the square of the accumulated factor product;
- `c` is the accumulated center modulo27.

The seed state is

`M0 = {1,7,22}`,

`c0 = 7`.

If a new prime-factor occurrence has residue `r in U(27)`, the exact transition is

`M -> M * {1,r,r^2}`,

`c -> c*r`.

This is exact for arbitrary prime powers as repeated applications of the same residue generate the divisor exponents `0..2e` for valuation `e`.

At k27 the two signed-box targets are:

Type I:

`4d = -1 mod27`, hence

`d = 20 mod27`.

Type II:

`d = -c mod27`.

So a state is terminal exactly when either `20 in M` or `-c in M`.

---

## 3. Complete raw closure

Exhausting the exact transition system from `(M0,c0)` under all 18 admissible unit residues gives

```text
raw states    132
misses         44
hits           88
```

The 88 hits split as

```text
Type I only       20
Type II only       6
Type I + Type II  62
```

The 44 misses use **36 distinct divisor masks**.

That last fact is important. k27 does not collapse to the two-mask `BARE | FULL_QR` normal form proved at k31. Any attempt to force k27 into an analogous QR-only support theorem would throw away exact state information that the signed box genuinely uses.

From the seed, exactly three single-residue transitions are immediate hits:

`r in {20,23,26}`.

The remaining residues may still hit or miss after further factor accumulation, so the complete transition object is required.

---

## 4. Absorbing hit theorem

The complete 88-state hit set is closed under every admissible residue transition:

> if an exact reachable k27 state is a hit, adjoining any further prime-factor occurrence with residue in `U(27)` produces another hit.

This is stronger than merely saying that the particular factorization already decomposes. It means the local automaton has a genuine terminal region: once entered, no later factor support can return the state to a miss.

The verifier checks all

`88 * 18 = 1584`

hit-state transitions explicitly.

---

## 5. Behavioral minimization

Raw `(mask,center)` equality is finer than the candidate framework needs. Two states are behaviorally equivalent when, for every future residue word over `U(27)`, they agree on whether the resulting state is a hit or a miss.

Partition refinement of the complete 132-state deterministic automaton gives the exact minimal quotient:

```text
behavioral states          30
survivor classes           29
terminal hit classes        1
```

The quotient-class size histogram is

```text
size  1 : 23 classes
size  2 :  5 classes
size 11 :  1 class
size 88 :  1 class
```

The unique size-88 class is exactly the entire absorbing hit set.

The 29 survivor classes contain all 44 raw misses.

Thus the exact k27 object needed by the developing decomposition framework is not a 132-state raw factor mask and not a one-bit QR character. It is a **30-state finite deterministic machine**.

---

## 6. Contrast with k31

The adjacent k31 theorem gives a radically smaller symbolic state:

```text
k31_mode = BARE | FULL_QR
D_support = QR31
```

By contrast, k27 requires

```text
k27_state = one of 29 survivor classes | TERMINAL
```

This asymmetry is mathematically useful rather than inconvenient.

It tells us the candidate decomposition framework should permit different local compression types:

- symbolic normal forms where the arithmetic collapses completely;
- minimized finite automata where several exact residue configurations remain behaviorally distinct.

Trying to impose one representation on every shift would be a modeling error.

---

## 7. Coupling to the post-k23 ladder

The same h169 coordinate carries

`C23 = 6B`,

`C27 = 7E`,

`C31 = 10D`,

with exact relations

`7E - 6B = 1`,

`10D - 7E = 1`,

`5D - 3B = 1`.

Therefore

`gcd(B,E)=gcd(E,D)=gcd(B,D)=1`.

A simultaneous survivor through k31 must therefore carry at least

```text
B_support   = QR23
k27_state   = one of 29 survivor classes
D_support   = QR31
k31_mode    = BARE | FULL_QR
7E-6B       = 1
10D-7E      = 1
5D-3B       = 1
pairwise gcd(B,E,D) = 1
```

This is now a concrete finite/symbolic product state, not a vague list of observations.

---

## 8. Framework consequence

The live finite ancestry audit showed that k27 and k31 absorb 128 of 148 audited simultaneous k19/k23 survivors.

The exact local mathematics now explains what the surviving branch data must look like after those two shifts:

```text
k19/k23 survivor
        |
        v
k27 30-state automaton
        |
        v
k31 two-mode normal form
        |
        v
residual branch only if both local machines miss
```

The immediate next theorem target is therefore sharper than before:

> intersect the 29 k27 survivor classes with `B_support=QR23`, `D_support=QR31`, `k31_mode=BARE|FULL_QR`, pairwise coprimality, and the three affine relations, then determine which classes are arithmetically realizable and which force a later exact signed-box exit.

A proof that only a proper subset of the 29 classes is compatible with the k23/k31 support laws would be a genuine progress measure for the candidate decomposition framework.

---

## 9. Claim boundary

This module proves:

1. the complete h169 k27 exact residue-state closure;
2. the exact hit/miss counts;
3. the absorbing nature of the full hit set;
4. the exact 30-state minimal behavioral quotient;
5. the affine coupling to k23 and k31.

It does **not** prove that every simultaneous k19/k23 survivor hits at k27 or k31. Explicit survivors through both shifts exist, so such a claim would be false.

The correct next object is the residual product state after both local machines miss.

Erdős–Straus remains open.
