# Exact k31 survivor normal form on h169

**Status:** exact fixed-shift module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k31_survivor_normal_form.py`  
**Depends on:** `POST-K23-COMPANION-LADDER.md`, exact signed-box Type-I/II semantics  
**Claim boundary:** exact theorem for the h169 k31 companion state. It is not a universal decomposition theorem and not an Erdős–Straus proof.

---

## 1. h169 normalizes k31 to 10D

Write

`p = 169 + 840t`.

Then

`C31 = (p+31)/4 = 50 + 210t`.

Therefore

`C31 = 10D`

with

`D = 5 + 21t`.

The mandatory seed at k31 is exactly `2*5`.

The post-k23 coordinate is

`C23 = 6B`,

`B = 8 + 35t`.

These cofactors satisfy the exact affine identity

`5D - 3B = 1`.

Hence

`gcd(B,D)=1`.

So a simultaneous k23/k31 survivor automatically carries two disjoint dynamic prime supports connected by a Bézout relation.

---

## 2. Exact seed mask modulo31

The divisors of the mandatory seed square

`10^2 = 2^2*5^2`

produce the residue mask

`M0 = {1,2,4,5,7,10,19,20,25} mod31`.

Its size is9.

The seed center is

`10 mod31`.

Every element of `M0` is a quadratic residue modulo31.

The complete nonzero quadratic-residue set is

`QR31 = {1,2,4,5,7,8,9,10,14,16,18,19,20,25,28}`.

Its size is15.

The Type-I target at k31 is

`-4^{-1} = 23 mod31`,

which is a quadratic nonresidue.

Because `31 = 3 mod4`, `-1` is also a quadratic nonresidue. Thus whenever the companion center is a quadratic residue, the Type-II target `-C31` is a nonresidue.

This makes a QR-only divisor mask a natural miss state.

---

## 3. Exact 75-state closure

Start from `(M0,10)`.

For an additional prime factor with nonzero residue `r mod31`, the exact state transition is

`(M,c) -> (M*{1,r,r^2}, c*r)`.

Repeated transitions also represent higher prime exponents exactly.

The complete closure under all 30 nonzero residues modulo31 contains

```text
75 states
18 misses
57 hits
```

The 18 misses have a strict two-mode normal form.

There are **no intermediate miss masks**.

---

## 4. FULL_QR mode

Fifteen miss states have mask exactly

`QR31`.

There is one such miss at each quadratic-residue center:

`1,2,4,5,7,8,9,10,14,16,18,19,20,25,28`.

For every one of them:

- the Type-I target23 is absent because it is a nonresidue;
- the Type-II target is `-center`, also a nonresidue;
- the full QR31 mask therefore misses both targets.

This is the k31 `FULL_QR` survivor mode.

---

## 5. BARE mode

Exactly three misses retain the original nine-element seed mask `M0`.

Their centers are

`{2,10,19}`.

The stabilizer of `M0` among nonzero residues modulo31 is exactly

`H31 = {1,5,25}`.

Indeed, for a quadratic-residue incoming factor residue r:

- if `r in {1,5,25}`, then `M0*{1,r,r^2}=M0`;
- for every other `r in QR31`, the mask jumps immediately to all of `QR31`.

Multiplication by5 cycles the three BARE centers:

`10 -> 19 -> 2 -> 10`.

Therefore the k31 companion is in BARE mode iff every prime factor of D lies in the residue subgroup

`{1,5,25} mod31`.

---

## 6. Exact k31 miss criterion

The closure gives a sharper theorem.

### Theorem

For h169, with

`C31=10D`,

the exact k31 signed box misses **iff every rational prime factor q of D is a nonzero quadratic residue modulo31**.

Equivalently:

`k31 miss <=> q mod31 in QR31 for every prime q|D`.

A factor q=31 is excluded automatically: if `31|D`, then `31|C31`, and the Type-II target is0 modulo31 with a divisor multiple of31 available, so k31 hits.

### Proof, QR direction

If every prime factor of D is QR31, every divisor of `C31^2` is QR31 because the mandatory seed factors2 and5 are also quadratic residues.

The center `C31` is QR31.

Both exact targets are nonresidues:

- Type I:23;
- Type II:`-C31`.

Hence neither target lies in the divisor mask.

### Proof, converse

The exact 75-state closure exhausts every possible sequence of nonzero prime-factor residues modulo31 beginning from the mandatory seed state.

Every miss state has mask either `M0` or `QR31`; both are contained in QR31.

Therefore a state containing any nonresidue factor residue cannot be a miss.

So any k31 miss forces every prime factor of D to be a quadratic residue modulo31.

This is an exact finite residue-state theorem, not a census inference.

---

## 7. Lossless miss compression

For propagation inside the candidate decomposition framework, the full 75-state closure compresses losslessly to

```text
k31_mode = BARE | FULL_QR
```

with

```text
BARE:
    divisor mask = M0
    center in {2,10,19}
    every q|D has q mod31 in {1,5,25}

FULL_QR:
    divisor mask = QR31
    center in QR31
    every q|D is QR mod31
    at least one factor residue lies outside {1,5,25}
```

The last FULL_QR line is conditional on k31 being a miss. If a nonresidue factor occurs, k31 hits and there is no survivor mode.

---

## 8. Coupling to the k23 survivor

The adjacent h169 companions are

`C23=6B`,

`C31=10D`,

with

`5D-3B=1`.

Thus

`gcd(B,D)=1`.

If k23 and k31 both miss, then:

- every prime factor of B is QR modulo23;
- every prime factor of D is QR modulo31;
- B and D have disjoint rational-prime support;
- the two cofactors obey the exact Bézout relation `5D-3B=1`.

This gives a compact simultaneous-survivor state:

```text
B_support = QR23
D_support = QR31
k31_mode = BARE | FULL_QR
gcd(B,D) = 1
5D - 3B = 1
```

The BARE refinement upgrades `D_support` further to the order-three subgroup `{1,5,25} mod31`.

---

## 9. Coupling to k27

The previous companion is

`C27 = 6B+1`.

Because h169 forces `C27` to be divisible by7, write

`C27 = 7E`,

with

`E = 7 + 30t`.

Then the consecutive-companion ladder gives

`7E - 6B = 1`,

`10D - 7E = 1`.

Hence

`B, E, D`

are pairwise coprime.

This is the next structural target: characterize the larger k27 miss automaton on E, then intersect it with the very rigid k31 QR31 condition on D and the existing k23 QR23 condition on B.

The candidate machine is beginning to carry a chain of pairwise-coprime, affinely coupled survivor cofactors rather than isolated divisibility tests.

---

## 10. Next theorem target

The k31 side is now compressed exactly.

The next attack is k27:

`C27=7E`,

with the simultaneous identities

`7E-6B=1`,

`10D-7E=1`.

The k27 seed closure is richer than k31, so the goal is not to force it into a one-character description prematurely. The correct target is a minimal exact survivor automaton for E that can be coupled to

`B_support=QR23`

and

`D_support=QR31`.

If that intersection collapses the simultaneous k23/k27/k31 survivor states to a small finite family, we will have a genuine local transition engine for the candidate decomposition framework.

Erdős–Straus remains open.
