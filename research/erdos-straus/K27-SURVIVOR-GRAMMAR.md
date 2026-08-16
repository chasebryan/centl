# Exact k27 survivor grammar on h169

**Status:** exact fixed-shift module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k27_survivor_grammar.py`  
**Depends on:** `POST-K23-COMPANION-LADDER.md`, `K31-SURVIVOR-NORMAL-FORM.md`, exact signed-box Type-I/II semantics  
**Claim boundary:** exact theorem for the h169 k27 companion state. It is not a universal shift ceiling, a closed decomposition method, or an Erdős–Straus proof.

---

## 1. Normalize the k27 companion

Write

`p = 169 + 840t`.

Then

`C27 = (p+27)/4 = 49 + 210t = 7E`,

with

`E = 7 + 30t`.

In particular

`E = 1 mod3`.

No prime factor of E is3, so every prime factor of E is a unit modulo27.

The mandatory seed is the single factor7. Its divisor-square mask is

`M0 = {1,7,22} mod27`,

its center is7, and the Type-I target is

`-4^{-1} = 20 mod27`.

For one prime-factor occurrence with residue r modulo27, the exact state transition is

`(M,c) -> ( M*{1,r,r^2}, c*r )`.

Prime powers are represented by repeated occurrences of the same residue, so the transition is exact for arbitrary factorizations of E.

---

## 2. Hits are absorbing and factor order is irrelevant

The transitions commute because both divisor-mask multiplication and center multiplication commute.

More importantly, a signed-box hit can never be repaired by adjoining another prime factor.

- A Type-I witness remains a divisor of the enlarged companion square.
- If d is a Type-II witness for C, then after adjoining residue r, `d*r` is a divisor of `(Cr)^2` and satisfies `d*r = -Cr mod27`.

Therefore the hit set is forward invariant.

This lets us reorder the prime factors of E without changing the final state and analyze all nonresidue occurrences before all quadratic-residue occurrences.

---

## 3. Unit geometry modulo27

The unit group modulo27 is cyclic of order18.

Its quadratic residues are

`QR27 = {1,4,7,10,13,16,19,22,25}`.

Its nonresidues are

`NR27 = {2,5,8,11,14,17,20,23,26}`.

There is a useful h169 coincidence:

- every QR27 unit is `1 mod3`;
- every NR27 unit is `2 mod3`.

Since `E=1 mod3`, the number of NR27 prime-factor occurrences in E, **counted with multiplicity**, must be even.

That hard-class parity condition is the key compression.

---

## 4. Raw exact closure

The complete exact closure from `(M0,7)` under all18 unit residues modulo27 contains

```text
132 states
 88 hits
 44 misses
```

The raw miss set is much richer than the k31 two-mode closure.

However only28 of those misses have the center parity compatible with h169, equivalently center in QR27.

Rather than preserve 28 unrelated masks, separate the factorization into its NR skeleton and QR completion.

---

## 5. Nonresidue skeleton theorem

First delete all QR27 factor occurrences and retain only the NR27 occurrences of E.

Because hits are absorbing, if that NR-only subproduct already hits, the full factorization hits as well.

The three residues

`20,23,26 mod27`

are immediate one-occurrence killers: adjoining any one of them to the seed hits the exact signed box. Thus no k27 survivor can contain a prime-factor occurrence in those residue classes.

Among the remaining six NR residues

`{2,5,8,11,14,17}`,

the complete NR-only survivor counts by occurrence number are

```text
size 0 : 1
size 1 : 6
size 2 : 9
size 3 : 8
size 4 : 6
size 5 : 2
size 6 : 1
size 7 : 0
```

Every NR multiset of size7 hits. Hence every larger NR multiset also hits, because it contains a size7 submultiset and hits are absorbing.

The h169 parity rule removes the odd sizes. Therefore every actual h169 k27 miss has one of exactly **17** NR skeletons:

### size 0

`()`

### size 2

```text
(2,2)
(2,14)
(2,17)
(5,5)
(5,11)
(8,14)
(8,17)
(11,11)
(14,14)
```

### size 4

```text
(2,2,2,14)
(2,2,2,17)
(2,2,14,14)
(2,14,14,14)
(5,5,11,11)
(8,14,14,14)
```

### size 6

`(2,2,2,14,14,14)`

The entries are prime-factor residues modulo27 and multiplicity matters.

This is a range-free exact necessary condition, not a finite prime census.

---

## 6. Seven live QR-completion modes

The 17 skeletons produce12 distinct raw states. Closing those states under the nine QR27 residues gives47 raw states:

```text
28 misses
19 hits
```

Those 47 states minimize, with respect to every possible future QR27 factor residue, to exactly

```text
8 behavioral classes
= 1 absorbing HIT class
+ 7 live survivor modes.
```

Call the live modes

`Q, A, B, C, D, E, F`.

The skeleton-to-mode map is exact.

### Q

```text
()
```

### A

```text
(2,14)
```

### B

```text
(8,17)
(5,11)
(2,2,2,17)
(2,2,14,14)
(8,14,14,14)
(5,5,11,11)
(2,2,2,14,14,14)
```

### C

```text
(2,2)
(8,14)
(2,2,2,14)
```

### D

```text
(2,17)
(14,14)
(2,14,14,14)
```

### E

`(5,5)`

### F

`(11,11)`

---

## 7. Exact QR transition table

For QR prime-factor residues, the entire surviving future is:

| mode | r=1 | r=4 | r=7 | r=10 | r=13 | r=16 | r=19 | r=22 | r=25 |
|---|---|---|---|---|---|---|---|---|---|
| Q | Q | Q | Q | Q | Q | Q | Q | Q | Q |
| A | A | C | D | HIT | HIT | HIT | HIT | HIT | HIT |
| B | B | HIT | HIT | HIT | HIT | HIT | HIT | HIT | HIT |
| C | C | HIT | B | HIT | HIT | HIT | HIT | HIT | HIT |
| D | D | B | HIT | HIT | HIT | HIT | HIT | HIT | HIT |
| E | E | HIT | HIT | HIT | B | HIT | HIT | HIT | HIT |
| F | F | HIT | HIT | HIT | HIT | HIT | HIT | HIT | B |

The HIT state is absorbing.

Because factor transitions commute, this table is an exact factor-support grammar, not an ordering convention.

---

## 8. Equivalent closed-form rules

The transition table can be read without running an automaton.

### Mode Q

Every prime factor of E is QR27. Any QR27 residues and multiplicities are allowed. k27 misses.

### Mode A

After the NR skeleton `(2,14)`, every QR factor residue must lie in

`{1,4,7}`.

Residue4 may occur at most once, residue7 may occur at most once, and both may occur once. Residue1 may occur arbitrarily often.

### Mode B

Every QR factor residue must be1 modulo27.

### Mode C

Every QR factor residue must lie in `{1,7}`, with residue7 occurring at most once.

### Mode D

Every QR factor residue must lie in `{1,4}`, with residue4 occurring at most once.

### Mode E

Every QR factor residue must lie in `{1,13}`, with residue13 occurring at most once.

### Mode F

Every QR factor residue must lie in `{1,25}`, with residue25 occurring at most once.

Together with the 17-skeleton list, these rules are an exact **iff characterization** of h169 k27 miss factorizations in terms of the prime-factor residues of E.

---

## 9. Coupling to k23 and k31

The adjacent companion coordinates are

`C23 = 6B`,

`C27 = 7E`,

`C31 = 10D`,

with

`B=8+35t`,

`E=7+30t`,

`D=5+21t`.

They satisfy

`7E - 6B = 1`,

`10D - 7E = 1`,

`5D - 3B = 1`.

Hence B, E, and D are pairwise coprime.

A simultaneous k23/k27/k31 survivor must therefore satisfy all three independent support systems:

```text
B: every prime factor QR mod23
E: one of the exact seven-mode k27 survivor grammars
D: every prime factor QR mod31
```

while the three pairwise-disjoint cofactors are locked by the affine identities above.

This is now a concrete local survivor machine rather than a loose collection of divisibility observations.

---

## 10. Framework consequence

The live transition after k23 can now be stated exactly for two of the dominant exits:

1. compute the k27 NR skeleton of E;
2. if it violates the 17-skeleton grammar, k27 hits;
3. otherwise apply the seven-mode QR completion rule;
4. if k27 survives, test D at k31;
5. any non-QR prime factor of D forces a k31 hit;
6. only the coupled residual state proceeds deeper.

The remaining research problem is no longer “search k27 and k31.” It is to characterize or eliminate the exact residual intersection

`QR23(B) + G27(E) + QR31(D)`

under the pairwise-coprime affine chain.

That is a genuine transition target for the developing decomposition framework.

Erdős–Straus remains open.
