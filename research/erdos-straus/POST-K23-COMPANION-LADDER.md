# Post-k23 companion ladder and support renewal

**Status:** exact algebraic module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_post_k23_companion_ladder.py`  
**Depends on:** `K19-K23-REALIZED-SURVIVOR-COUPLING.md`, `Q23-BLOCKED-PHASE-ANCESTRY-AUDIT.md`  
**Claim boundary:** exact identities and support-overlap laws on h169 and the two realized k19 routes. This is not yet a universal shift selector or a closed decomposition method.

---

## 1. The coordinate hidden under the ancestry audit

On the hard class

`p = 169 + 840t`, 

the fixed-shift companions at k19 and k23 are

`C19 = (p+19)/4 = 47 + 210t`,

`C23 = (p+23)/4 = 48 + 210t`.

Hence

`C23 = C19 + 1`.

Moreover

`C23 = 6B`

with the exact integer coordinate

`B = 8 + 35t`.

Now enumerate every later admissible shift by

`k_j = 23 + 4j`,  j >= 0.

Then the companion is simply

`C_j := C_{k_j} = (p+k_j)/4 = C23 + j`.

Therefore

`C_j = 6B + j = C19 + j + 1`.

This is the post-k23 **companion ladder**.

The first-hit support found in the ancestry audit

`{27,31,35,39,43,47,55}`

is exactly

`j in {1,2,3,4,5,6,8}`.

The observed k<=55 collapse is thus a statement about the first eight consecutive integers after `6B`.

---

## 2. Exact Euclidean support laws

Because

`C_j = C23 + j`,

Euclid gives

`gcd(C_j, C23) = gcd(j, C23)`.

Likewise, because

`C_j = C19 + j + 1`,

we have

`gcd(C_j, C19) = gcd(j+1, C19)`.

Since `C23=C19+1`,

`gcd(C19,C23)=1`.

Therefore every prime shared by a later companion `C_j` and the already-surviving pair `C19*C23` must divide the tiny integer

`j(j+1)`.

Equivalently:

> if a prime q divides `C_j` and q does not divide `j(j+1)`, then q is absent from both `C19` and `C23`.

This is an exact support-renewal theorem. It is independent of search range and independent of the factorization size of `C_j`.

---

## 3. Hard-class seed structure through k55

For h169,

`C_j = 48 + j + 210t`.

Hence

`gcd(C_j,210) = gcd(48+j,210)`.

For the first eight post-k23 shifts:

| j | k | C_j mod210 | mandatory gcd with210 |
|---:|---:|---:|---:|
| 1 | 27 | 49 | 7 |
| 2 | 31 | 50 | 10 |
| 3 | 35 | 51 | 3 |
| 4 | 39 | 52 | 2 |
| 5 | 43 | 53 | 1 |
| 6 | 47 | 54 | 6 |
| 7 | 51 | 55 | 5 |
| 8 | 55 | 56 | 14 |

This gives each early shift a deterministic seed before any nontrivial factorization is examined.

The same window can be read directly as

`49,50,51,52,53,54,55,56 mod210`.

---

## 4. Exact overlap table with the live k19/k23 state

Because

`C19 = 47 mod210`,

we have

`gcd(C19,210)=1`.

And because

`C23 = 48 + 210t = 6B`,

with `B=8 mod35`, the overlap with the previous two companions is sharply controlled.

For j=1 through8:

### j=1, k27

`gcd(C27,C19)=gcd(2,C19)=1`,

`gcd(C27,C23)=gcd(1,C23)=1`.

So **all prime support of C27 is new** relative to both C19 and C23.

### j=2, k31

`gcd(C31,C19)=gcd(3,C19)=1`,

`gcd(C31,C23)=gcd(2,C23)=2`.

Thus the only inherited rational prime is 2. Every odd prime factor of C31 is new.

### j=3, k35

`gcd(C35,C19)=gcd(4,C19)=1`,

`gcd(C35,C23)=gcd(3,C23)=3`.

Thus the only inherited rational prime is 3.

### j=4, k39

`gcd(C39,C19)=gcd(5,C19)=1`,

`gcd(C39,C23)=gcd(4,C23)`.

Only 2-power support can be inherited.

### j=5, k43

`gcd(C43,C19)=gcd(6,C19)=1`,

`gcd(C43,C23)=gcd(5,C23)=1`.

So **all prime support of C43 is new**.

### j=6, k47

`gcd(C47,C19)=gcd(7,C19)=1`,

`gcd(C47,C23)=gcd(6,C23)=6`.

Only the old primes 2 and3 can be inherited.

### j=7, k51

`gcd(C51,C19)=gcd(8,C19)=1`,

`gcd(C51,C23)=gcd(7,C23)=1`.

So **all prime support of C51 is new**.

The finite ancestry audit found no first hit at k51 despite this total support renewal. Fresh support is therefore not, by itself, a sufficient transition rule.

### j=8, k55

`gcd(C55,C19)=gcd(9,C19)=1`,

`gcd(C55,C23)=gcd(8,C23)`.

Only 2-power support can be inherited.

---

## 5. Route-specific B/R support renewal

The two realized h169 k19 routes have

### Route A

`C19 = 391R = 17*23*R`,

`C23 = 6B`,

`6B - 391R = 1`.

### Route B

`C19 = 1081R = 23*47*R`,

`C23 = 6B`,

`6B - 1081R = 1`.

In both cases

`gcd(B,R)=1`.

For either route the companion ladder gives

`C_j = 6B+j`,

so

`gcd(C_j,B)=gcd(j,B)`.

Using `6B=SR+1`, where S is391 or1081,

`C_j = SR + j + 1`,

hence

`gcd(C_j,R)=gcd(j+1,R)`.

Therefore:

- any prime shared with B must divide j;
- any prime shared with R must divide j+1;
- every prime factor of C_j outside the support of `j(j+1)` is genuinely new relative to both dynamic survivor cofactors B and R.

This is the support-renewal law in the compressed framework coordinates.

---

## 6. Why this matters for a decomposition machine

The full-ancestry audit showed that all 148 simultaneous k19/k23 survivors in the audited prefixes terminate by k55, with 128 already terminating at k27 or k31.

The companion ladder now explains why the next theorem should be local rather than q-adically distant:

```text
live survivor state
    C19 = SR
    C23 = 6B
    6B-SR = 1
        |
        v
C27 = 6B+1
C31 = 6B+2
C35 = 6B+3
C39 = 6B+4
C43 = 6B+5
C47 = 6B+6
C51 = 6B+7
C55 = 6B+8
```

Each step has:

1. a fixed hard-class seed modulo210;
2. an exact bound on inherited prime support;
3. a mostly fresh cofactor whose root geometry can be tested in the full Type-II signed box.

That is a much more natural candidate transition engine than jumping directly from k23 to the distant q23 square-lift destination.

---

## 7. Relation to López

Nothing in the companion-ladder identities assumes López Type A/B.

The live exit is always evaluated in the full exact signed box. The ancestry audit already shows that many actual first exits are mixed or interior-only in Type-II root coordinates.

So the ladder is compatible with the governing hierarchy:

```text
exact survivor state
      -> companion ladder
      -> full signed-box test
      -> Type I / boundary Type II / incomparable Type II / mixed
```

López A/B remains a boundary certificate family, not the transition grammar.

---

## 8. Next theorem target

The highest-value target is now the two-step absorber

`C27 = 6B+1`,

`C31 = 6B+2`,

because k27 and k31 absorb 128 of 148 audited simultaneous survivors.

The desired statement is not a census frequency. It is an implication of the form

`compressed k19/k23 survivor state  =>  k27 hit OR k31 hit`

for a mathematically specified subdomain, with exact fallback conditions for the residual cases.

The support-renewal theorem gives the right variables for that proof attempt: the new prime residues entering `6B+1` and `6B+2`, together with the existing QR23 support on B, the FULL_QR/BARE state on R, and the affine equation `6B-SR=1`.

If such implications can be chained with a well-founded residual state, the candidate framework begins to look like an actual decomposition method.

Erdős–Straus remains open.
