# Exact two-branch k35 survivor theorem on h169

**Status:** exact fixed-shift module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k35_two_branch_survivor_theorem.py`  
**Depends on:** `POST-K23-COMPANION-LADDER.md`, `K27-SURVIVOR-GRAMMAR.md`, `K31-SURVIVOR-NORMAL-FORM.md`  
**Claim boundary:** exact h169 theorem at k35. It is not a universal depth bound, a closed decomposition method, or an Erdős–Straus proof.

---

## 1. Normalize k35

Write

`p = 169 + 840t`.

Then

`C35 = (p+35)/4 = 51 + 210t = 3F`,

where

`F = 17 + 70t`.

Therefore

`F = 17 mod35`

for every t.

In particular F is coprime to35, so every rational prime factor of F is a unit modulo35.

The final signed-box center is fixed:

`C35 = 16 mod35`.

The two exact targets are also fixed:

```text
Type I target  = -4^{-1} = 26 mod35
Type II target = -C35     = 19 mod35.
```

Both targets reduce to

`5 mod7`.

This fixed-center feature is what makes k35 collapse sharply.

---

## 2. Exact raw endpoint closure

Start from the mandatory factor3, whose square-divisor mask is

`{1,3,9} mod35`.

Adjoining one prime-factor residue r of F applies the exact transition

`(M,c) -> (M*{1,r,r^2}, c*r)`.

The complete closure under all24 units modulo35 contains

```text
394 raw states.
```

Exactly14 states have the h169 final center

`c=16 mod35`.

Among those14 exact endpoints:

```text
8 hit
6 miss.
```

The six misses split into only two structural branches.

---

## 3. The mod7 safe branch

Reduce the divisor state modulo7.

The mandatory seed is

`M7={1,2,3}`

with center3.

Because

`F=3 mod7`,

the final k35 center modulo7 is2.

There are exactly two reachable endpoint masks with center2:

```text
{1,2,3,4,6}
{1,2,3,4,5,6}.
```

The first omits5. The second is the full unit group.

Since **both exact k35 targets are5 modulo7**, the five-element mask is automatically a miss before modulo5 is even consulted.

The residue transition is completely rigid:

- from the seed, residue1 preserves the seed;
- residue3 is the unique transition into the five-element safe mask;
- from the safe mask, residue1 is the only residue that preserves omission of5;
- every other unit residue introduces5.

Because factor insertion commutes, the mod7 safe branch has an exact factorization description.

### S7 condition

`F = q R`,

where

- q is prime;
- `q = 3 mod7`;
- q occurs to exponent exactly1 in F;
- every rational prime factor of R is `1 mod7`.

R may equal1.

Equivalently, among prime-factor occurrences of F, exactly one is3 modulo7 and every other occurrence is1 modulo7.

Whenever S7 holds, k35 misses.

---

## 4. The character branch

Let

`H35 = {r in (Z/35Z)^* : (r/5)(r/7)=+1}`,

where `(r/5)` and `(r/7)` are Legendre symbols.

Equivalently, H35 consists of unit residues whose quadratic characters modulo5 and modulo7 have the same sign.

Explicitly,

`H35 = {1,3,4,9,11,12,13,16,17,27,29,33}`.

H35 is an index-two subgroup of the24 units modulo35.

The mandatory seed residue3 belongs to H35.

The two exact targets do not:

```text
19 notin H35
26 notin H35.
```

Therefore, if every rational prime factor of F lies in H35, every divisor residue of `C35^2` lies in H35 and both exact targets are excluded.

### J35 condition

For every rational prime q dividing F,

`(q/5)(q/7)=+1`.

Whenever J35 holds, k35 misses.

---

## 5. The unique exceptional endpoint

Of the six exact h169 miss endpoints, five have mod7 projection

`{1,2,3,4,6}`

and therefore lie in the S7 branch.

The remaining miss has full mod7 projection but exact modulo35 mask

`{1,3,4,9,11,12,13,16,17,27,29,33}`.

That mask is exactly H35.

Because every prime factor q of F is itself a divisor of `C35^2`, its residue appears in the final divisor mask. Hence if the final mask is H35, every q dividing F lies in H35.

So the full-projection exception is not a third branch. It is exactly the J35 branch.

---

## 6. Exact iff theorem

### Theorem

For

`p = 169 mod840`

and

`F=(p+35)/12 = 17+70t`,

the exact k35 signed box misses **if and only if** at least one of the following holds:

### J35

Every rational prime factor q of F satisfies

`(q/5)(q/7)=+1`.

### S7

`F=qR` with q prime, `q=3 mod7`, q occurring to exponent1, and every rational prime factor of R congruent to1 modulo7.

Symbolically,

`k35 miss <=> J35(F) OR S7(F)`.

The two branches may overlap.

### Proof of sufficiency

- J35: every divisor residue stays inside subgroup H35 while both exact targets lie outside H35.
- S7: the complete divisor mask modulo7 omits5 while both exact targets equal5 modulo7.

### Proof of necessity

The complete exact center16 closure has only six misses.

- If the mod7 projection omits5, the exact two-state endpoint analysis forces the S7 factor pattern.
- If the mod7 projection contains5, the only miss endpoint is H35 itself. Every prime factor residue of F occurs in the divisor mask, so every prime factor lies in H35, giving J35.

No census or size bound enters the theorem.

---

## 7. Coupling to the local companion chain

The first four post-k23 dynamic cofactors can now be written

```text
C23 =  6B
C27 =  7E
C31 = 10D
C35 =  3F
```

with

```text
B = 8 + 35t
E = 7 + 30t
D = 5 + 21t
F = 17 + 70t.
```

They satisfy

```text
7E - 6B  = 1
10D - 7E = 1
5D - 3B  = 1
F - 2B   = 1
3F - 7E  = 2
3F - 10D = 1.
```

B, E, D, and F are pairwise coprime.

The last statement follows from the identities above, with E and F both odd in the one relation whose gcd can divide2.

Thus a branch surviving k23, k27, k31, and k35 carries four disjoint dynamic supports constrained simultaneously by

```text
B : QR23 support
E : exact k27 seven-mode grammar
D : QR31 support
F : J35 OR S7
```

plus the affine companion identities.

This is a substantially more rigid residual state than the original signed-box search.

---

## 8. Framework consequence

The local candidate machine now has exact decision rules at three consecutive post-k23 rungs:

```text
k27 : finite 17-skeleton + seven-mode survivor grammar
k31 : all prime factors of D must be QR mod31
k35 : J35(F) OR S7(F)
```

A survivor must satisfy all three simultaneously while B,E,D,F remain pairwise coprime and affinely coupled.

The next theorem target is the **intersection**, not another blind shift census:

`QR23(B) ∩ G27(E) ∩ QR31(D) ∩ (J35(F) union S7(F))`.

If that residual product state can be split into finitely many forced exits at k39, k43, k47, and beyond, the candidate framework gains a genuine chained transition mechanism.

Erdős–Straus remains open.
