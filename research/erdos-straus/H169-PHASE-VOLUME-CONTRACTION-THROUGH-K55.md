# h169 phase-volume contraction through k55

**Status:** proved modular survivor restriction inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_h169_phase_volume_through_k55.py`  
**Depends on:** landed k39 phase absorption, landed universal signed-box selector shell at k43, landed k47 phase absorption, and the exact signed-box state transition law.  
**Claim boundary:** exact necessary conditions for simultaneous survival at the named shifts. The phase-volume quantity is a candidate progress coordinate, not a termination theorem and not an Erdős–Straus proof.

## 1. Why k51 and k55 matter

The finite blocked-phase ancestry audit found first post-k23 hits at

`{27,31,35,39,43,47,55}`

and no first hit at k51 in that specimen.

That absence does **not** make k51 structurally inert. Exact fixed-shift closure shows that k51 eliminates whole h169 phases range-free. k55 does the same.

This is a useful separation between finite first-hit frequency and theorem-level transition structure.

## 2. k51 exact phase absorption

For

`p = 169 + 840t`,

`C51 = (p+51)/4 = 55 + 210t = 5K`,

where

`K = 11 + 42t`.

Modulo51,

`C51 = 4 + 6t`.

The mandatory seed is5. For unit phases, the complete exact residue-state closure from seed5 has

```text
1403 states
1159 hits
 244 misses
```

with

```text
Type I only       392
Type II only      225
Type I + Type II  542
miss              244
```

Filtering by the h169 center gives no possible miss for

`t mod17 in {4,7,14}`.

The remaining absorbed phase

`t=5 mod17`

has `17 | C51`. Then the fixed divisor `d=17` divides `C51^2` and

`d = -C51 mod51`,

so Type II is immediate.

Hence

`k51 miss => t mod17 in {0,1,2,3,6,8,9,10,11,12,13,15,16}`.

Equivalently k51 absorbs

`A51 = {4,5,7,14} mod17`.

None of these four phases is supplied by the universal `d in {1,C,C^2}` shell. Three are full exact-state absorptions and one is the fixed-factor selector `d=17`.

## 3. k55 exact phase absorption

At k55,

`C55 = (p+55)/4 = 56 + 210t = 14L`,

where

`L = 4 + 15t`.

Modulo55,

`C55 = 1 - 10t`.

The mandatory seed is14=2*7. For unit phases, the complete exact residue-state closure from seed14 has

```text
509 states
383 hits
126 misses
```

with

```text
Type I only        84
Type II only       15
Type I + Type II  284
miss              126
```

Filtering by the h169 center gives no possible miss for

`t mod11 in {5,6,7}`.

The phase `t=7` is already the universal shell: `C55=41=-4^(-1) mod55`, so `d=C55` is Type I.

The phase

`t=10 mod11`

has `11 | C55`. Because C55 always contains the fixed factor2, `44=4*11` divides `C55^2`; moreover

`44 = -C55 mod55`.

Thus `d=44` is an immediate Type-II witness.

Therefore

`k55 miss => t mod11 in {0,1,2,3,4,8,9}`,

and k55 absorbs

`A55 = {5,6,7,10} mod11`.

Of these, t=7 is inherited from the universal shell, t=10 is a fixed-factor Type-II selector, and t=5,6 are genuinely state-dependent absorptions.

## 4. Exact phase-volume contraction

The range-free phase restrictions now available in the local h169 ladder are:

```text
shift   phase modulus   survivor phases
k39          13              9
k43          43             40
k47          47             34
k51          17             13
k55          11              7
```

The moduli

`13, 43, 47, 17, 11`

are pairwise coprime. Therefore the Chinese remainder theorem makes the simultaneous phase count multiplicative.

Let

`M = 13*43*47*17*11 = 4,913,051`.

If an h169 integer survives all five named signed boxes, then its parameter t must lie in exactly the product of the five necessary survivor sets, containing

`9*40*34*13*7 = 1,113,840`

residue classes modulo M.

Thus the raw CRT class ratio through these five filters is

`1,113,840 / 4,913,051`.

The numerator and denominator have gcd221, so the same survivor fraction in lowest terms is

`V55 = 5,040 / 22,231`

which is approximately

`0.22671044937249787`.

Equivalently, the named phase theorems exclude

`3,799,211 / 4,913,051`

of the periodic t-space, approximately

`77.32905506275021%`.

This is exact modular arithmetic. It is not a density estimate from sampled primes.

## 5. What V55 is and is not

`V55` is useful as a **candidate progress coordinate** for the developing decomposition framework:

- it is derived entirely from proved transition restrictions;
- adding an independent phase filter can only reduce the survivor fraction;
- it can be tracked without weakening exact signed-box semantics;
- it provides a common quantitative surface across otherwise different local grammars.

But `V55` is **not yet a well-founded termination measure**.

A positive fraction less than1 leaves infinitely many arithmetic progressions. Even a sequence of shrinking phase fractions would require an additional theorem connecting the contraction to finite termination or impossibility of a persistent integer branch.

So the correct status is

`proved phase contraction != proved decomposition termination`.

## 6. Interaction with the richer survivor state

The phase contraction is only one coordinate. A branch surviving through this window must simultaneously satisfy the already-proved non-phase restrictions, including:

- k27 seven-mode survivor grammar;
- k31 BARE/FULL_QR support law;
- k35 J35(F) or S7(F) two-branch theorem;
- k39 survivor phase;
- k43 selector-shell avoidance;
- k47 survivor phase;
- k51 survivor phase;
- k55 survivor phase.

The next machine object should therefore be the intersection

`phase class × k27 mode × k31 mode × k35 branch × residual-support/affine data`.

The objective is to determine whether most formal Cartesian combinations are arithmetically unrealizable.

## 7. Bryan Entanglement Cross draft boundary

The developing Bryan Entanglement Cross is intentionally kept outside the proof predicate in this module.

If the draft later lands, the phase contractions are natural candidates for downward/excavation annotations and terminal certificates for rightward/constructive annotations. Those labels must remain observational/scheduling metadata unless an independent theorem grants stronger semantics.

## 8. Next theorem target

The strongest next step is not another isolated phase count. It is to intersect the exact phase survivor class with the k27/k31/k35 symbolic state and prove one of:

1. whole product-state classes are impossible by CRT/support/affine incompatibility;
2. a remaining product state forces a specific later signed-box selector;
3. the product state contracts under a repeatable transition rule.

Any of those would move the framework from a sequence of local absorbers toward an actual selector machine.
