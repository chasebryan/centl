# Bryan Entanglement Cross k27/k31 transition theorem

**Status:** exact transition theorem inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_bec_k27_k31_transition.py`  
**Depends on:** `BRYAN-ENTANGLEMENT-CROSS.md`, `K27-SURVIVOR-GRAMMAR.md`, `K31-SURVIVOR-NORMAL-FORM.md`, `POST-K23-COMPANION-LADDER.md`  
**Claim boundary:** this theorem selects the first two live post-k23 transitions on the h169 state using exact factor-support predicates. It is not yet a factorization-free selector, a universal shift ceiling, a termination theorem, or an Erdős–Straus proof.

---

## 1. Setup

Let

`p = 169 + 840t`

and assume the branch is live after k23, so the exact signed box has already missed at k23.

Use the normalized consecutive companions

```text
C23 = 6B,   B = 8 + 35t
C27 = 7E,   E = 7 + 30t
C31 = 10D,  D = 5 + 21t.
```

They satisfy

```text
7E - 6B = 1
10D - 7E = 1
5D - 3B = 1
```

and therefore

```text
gcd(B,E)=gcd(E,D)=gcd(B,D)=1.
```

The post-k23 live BEC path begins at the k27 test.

---

## 2. Exact k27 predicate G27(E)

`K27-SURVIVOR-GRAMMAR.md` gives an exact iff description of k27 misses from the prime-factor residues of E modulo27.

Define

\[
\boxed{G_{27}(E)}
\]

to mean that the factorization of E belongs to that exact survivor grammar.

Concretely:

1. form the multiset of nonresidue prime-factor occurrences modulo27, with multiplicity;
2. it must be one of the seventeen permitted NR skeletons;
3. the quadratic-residue occurrences must satisfy the exact completion rule of the corresponding mode `Q,A,B,C,D,E,F`.

Then the landed theorem is exactly

\[
\boxed{
k27\text{ misses}\iff G_{27}(E).
}
\]

Hence

\[
\boxed{
k27\text{ hits}\iff \neg G_{27}(E).
}
\]

---

## 3. Exact k31 predicate Q31(D)

`K31-SURVIVOR-NORMAL-FORM.md` proves

> k31 misses iff every rational prime factor of D is a nonzero quadratic residue modulo31.

Define

\[
\boxed{Q_{31}(D)}
\]

to mean

```text
for every prime q|D:
    q != 31
    and q mod31 is in QR31.
```

Then

\[
\boxed{
k31\text{ misses}\iff Q_{31}(D),
}
\]

and therefore

\[
\boxed{
k31\text{ hits}\iff \neg Q_{31}(D).
}
\]

---

## 4. Exact BEC selector theorem

The first two live BEC transitions are now selected exactly.

### Theorem

For an h169 branch that is live after k23:

\[
\boxed{
\mathcal P_B=R
\iff
\neg G_{27}(E).
}
\]

That is, the branch propagates immediately right at k27 exactly when E violates the k27 survivor grammar.

If `G27(E)` holds, k27 is an exact miss and contributes one leftward transition. Then

\[
\boxed{
\mathcal P_B=LR
\iff
G_{27}(E)\land\neg Q_{31}(D).
}
\]

Finally,

\[
\boxed{
\mathcal P_B\text{ has prefix }LL
\iff
G_{27}(E)\land Q_{31}(D).
}
\]

So the first live selector is

```text
if not G27(E):
    R at k27
else:
    L at k27
    if not Q31(D):
        R at k31
    else:
        L at k31
        enter the deeper coupled residual
```

This is an exact theorem, not a learned scheduler rule.

---

## 5. Residual after the LL prefix

If both exact survivor predicates hold, the live state has survived k23, k27, and k31.

It therefore carries the simultaneous exact support system

```text
B_support   QR23
E_state     one of the exact k27 live modes Q,A,B,C,D,E,F
D_support   QR31
```

with the affine and coprimality constraints

```text
7E - 6B = 1
10D - 7E = 1
5D - 3B = 1

gcd(B,E)=gcd(E,D)=gcd(B,D)=1.
```

This is the exact arithmetic state represented by the BEC prefix

```text
LL
```

before the machine tests k35.

The BEC word is only the directional summary. The support modes and affine relations are the mathematical payload.

---

## 6. Finite ancestry regression

The q23 full-ancestry specimen contains 148 simultaneous k19/k23 survivors.

The independent verifier replays those exact prefixes and checks the factor-support selectors directly.

It recovers

```text
R       64
LR      64
LL...   20
```

exactly.

Equivalently:

```text
not G27(E)                         64
G27(E) and not Q31(D)              64
G27(E) and Q31(D)                  20
```

The first two predicates therefore explain the dominant 128/148 live exits in that finite specimen without consulting the later first-hit label when making the classification.

The finite counts are regression evidence for the range-free transition theorem, not its proof source.

---

## 7. Why this is stronger than BEC telemetry

The earlier ancestry pilot attached `R`, `LR`, or a deeper `L^jR` word **after** the exact first hit was known.

This theorem reverses that relationship for the first two transitions:

```text
exact arithmetic state
    -> exact factor-support predicate
        -> forced next BEC transition
```

The direction is now predictable from proved arithmetic conditions.

That does not make BEC itself a proof rule. The proof rule is `G27` or `Q31`; BEC is the compact transition name emitted by those theorems.

---

## 8. Current limitation

The selector still inspects exact factor-support information.

It is therefore not yet the stronger object ultimately wanted by the decomposition framework:

```text
small compressed survivor state
    -> choose next shift and certificate
```

without factor enumeration.

The next compression target is to derive `G27(E)` and `Q31(D)` consequences directly from the coupled state

```text
B_support=QR23
7E-6B=1
10D-7E=1
pairwise coprimality
route ancestry
```

or from a still smaller residue/support signature.

---

## 9. Next theorem target

Only the `LL` residual remains after the first two exact selectors.

The natural next question is:

> Which exact k27 survivor modes can coexist with `D_support=QR31` and `B_support=QR23` under the affine chain?

The seven k27 modes are already finite. The k31 condition is already a single exact support law. Their intersection is therefore the correct object to attack before adding another broad search dimension.

In BEC language:

```text
R   is completely selected by not G27(E)
LR  is completely selected by G27(E) and not Q31(D)
LL  is the new exact residual state
```

The next job is to fracture `LL`, not to search blindly past it.

Erdős–Straus remains open.
