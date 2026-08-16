# Realized k19/k23 survivor coupling

**Status:** exact cross-shift support theorem on the two h=169 pair routes realized by the recursive closure  
**Date:** 2026-08-16  
**Primary classifier:** `classify_k19_k23_realized_survivor_coupling.py`  
**Independent verifier:** `verify_k19_k23_realized_survivor_coupling.py`  
**Depends on:** `K19-REALIZED-PAIR-SURVIVOR-NORMAL-FORM.md`, rigid k23 QR-support theorem, companion identity  
**Claim boundary:** this is a conditional simultaneous-miss theorem on two named routes. The support system is arithmetically realizable and is not itself a contradiction. It does not prove Erdős-Straus.

## 1. The first persistent-state cross-shift intersection

The realized k19 pair survivor theorem compresses each exact k19 miss to

- `FULL_QR`, or
- `BARE`, where the remaining cofactor has prime support entirely `1 mod19`.

The next adjacent Lane-I companion is

`C23 = C19 + 1`.

On hard class h169, k23 has exact class seed6. Both realized pair routes also have

`p mod23 = 4`.

The exact k23 seed-6 closure has49 states and15 misses. At center4 there is exactly one miss state, and its divisor mask is the full quadratic-residue subgroup QR(23).

Therefore, if k23 misses on either route, every prime factor of C23 lies in QR(23).

This lets the k19 survivor signature and the k23 rigid state be coupled without reducing either to a bare character sign.

## 2. Route A: q17+q23 -> k19

The routed k19 companion is

`C19 = 17*23*R = 391R`.

Since

`C23 = C19 + 1`

and h169 gives

`C23 = 6B`,

we have the exact affine identity

`6B - 391R = 1`.

Hence

`gcd(B,R)=1`.

If k19 and k23 both miss, then

- every prime factor of B is a quadratic residue modulo23;
- every prime factor of R is a quadratic residue modulo19;
- if k19 is in BARE mode, every prime factor of R is in fact `1 mod19`;
- B and R have disjoint rational-prime support.

Thus simultaneous survival is carried by two coprime prime populations obeying different local support laws.

## 3. Route B: q23+q47 -> k19

Now

`C19 = 23*47*R = 1081R`.

Again

`C23=6B=C19+1`, 

so

`6B - 1081R = 1`.

Again

`gcd(B,R)=1`.

The same simultaneous-miss support split follows:

- B is QR(23)-supported;
- R is QR(19)-supported;
- BARE k19 sharpens R to prime support `1 mod19`;
- B and R are coprime.

## 4. Why the gcd is exact

The identity

`6B - SR = 1`

with S equal to391 or1081 immediately implies that every common divisor of B and R divides1.

No exceptional overlap prime survives.

This is stronger than the already-landed near-coprime residual atlases where a small exceptional set such as {2,3,13,17} may remain.

On these two pair routes the seed-stripped k19 and k23 residual populations are completely disjoint.

## 5. Support theorem at k23 center4

For k23 and class seed6, the complete exact state closure contains15 miss states.

The center

`p mod23=4`

has exactly one miss state.

Its mask is

`QR(23)={1,2,3,4,6,8,9,12,13,16,18}`.

Therefore a k23 miss at p mod23=4 is not merely positive-character. It is fully QR-rigid:

> every prime factor of C23 is a quadratic residue modulo23.

Because 2 and3 themselves are QR modulo23, the same statement applies to the stripped residual

`B=C23/6`.

## 6. Four exact realized anchors

The independent verifier pins both k19 survivor modes on both routes while also requiring k23 to miss.

### Route A, FULL_QR

`p=3,780,169`

has

`C19=17*23*2417`,

with full QR(19) mask, and k23 also misses with full QR(23) mask.

### Route A, BARE

`p=33,996,649`

has

`C19=17*23*21737`,

where

`21737 = 1 mod19`.

The k19 mask is exactly the seven-element bare route mask.

Also

`C23=2^5*3^5*1093`,

and every stripped B factor is QR modulo23.

### Route B, FULL_QR

`p=592,369`

has

`C19=23*47*137`,

with full QR(19) mask, while k23 also misses in the rigid QR(23) state.

### Route B, BARE

`p=118,637,569`

has

`C19=23*47*27437`,

with

`27437 = 1 mod19`.

The k19 state is bare.

Its adjacent companion is

`C23=2*3*71*69623`,

and the stripped residual

`B=71*69623`

has both prime factors quadratic-residue modulo23.

These anchors demonstrate that neither FULL_QR nor BARE is eliminated merely by the adjacent k23 rigid support condition.

## 7. The resulting compressed cross-shift state

For these two branches, simultaneous k19/k23 survival can be stored losslessly at the level needed for future support propagation as

```text
k19_mode = FULL_QR | BARE
R_support = QR19 | ONE19
B_support = QR23
gcd(B,R) = 1
affine = 6B - S R = 1
```

where

`S=391` or `1081`.

This is dramatically smaller than carrying the Cartesian product of two raw fixed-shift state closures.

## 8. Why this is not yet a contradiction

The four exact prime anchors prove finite realizability of every named mode.

Thus the theorem must not be oversold. Coprimality plus separate QR-support laws do not by themselves force a Lane-I hit.

The value is that they give a compact, exact arithmetic object on which the next independent mechanisms can act.

In particular, the landed periodic-route valuation theorem can now be applied to the already-routed q23 factor while retaining the R/B support split.

## 9. Next target: valuation-aware survivor state

Both routes contain q23 in C19. The periodic q23 route representatives are

`k_n = 19 + 92n`,

with

`C_{k_n}=23(M+n)`.

Here

- Route A: `M=17R`;
- Route B: `M=47R`.

Exactly one n modulo23 produces a q23^2 lift.

The next useful theorem search is therefore to carry

- k19 mode;
- R/B support and coprimality;
- q23 valuation phase;

into the later route representatives and ask when the canonical square divisor `23^2` forces a Type-II target.

That is now a small arithmetic state problem rather than a broad character-routing problem.

Erdős-Straus remains open.
