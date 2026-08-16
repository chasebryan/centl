# Routed residual gcd atlas after multi-source QR saturation

**Status:** exact range-free residual-coupling theorem plus baseline 8-pair/6-triple synergy atlas  
**Date:** 2026-08-16  
**Primary classifier:** `classify_routed_residual_gcd_atlas.py`  
**Independent regression:** `verify_routed_residual_gcd_atlas.py`  
**Depends on:** `MULTISOURCE-QR-SATURATION.md`, class-conditioned seed law, fixed-shift QR-support atlas  
**Claim boundary:** the affine/gcd statements are range-free on every named routed branch. The finite atlas in this document is deliberately scoped to the original 8 pair and 6 triple synergies proved in `MULTISOURCE-QR-SATURATION.md`; it is not a completeness claim for the later recursively expanded source inventory. This does not prove that one of the shifts must hit, does not give a universal shift ceiling, and does not prove Erdős-Straus.

## 1. The missing object after saturation

Multi-source QR saturation turns several routed source factors into a rigid destination condition:

> if the destination still misses, every prime factor of its companion lies in the destination quadratic-residue subgroup.

That does not end the problem. The finite record `p=8,803,369` shows that a remaining cofactor can stay entirely inside the allowed QR support and survive.

The next object is therefore not only the destination support set. It is the arithmetic relation between the **seed-stripped source residuals** and the **seed-stripped saturated destination residual**.

Those residuals are unusually close to coprime.

## 2. General routed-residual identity

Let

`C_j = (p+j)/4`.

Fix a simultaneous routed branch with source shifts `q_i` and destination shift `k`. Let

- `s_i` be the exact class-conditioned mandatory seed in `C_{q_i}`;
- `S` be the combined routed seed in `C_k`;
- `A_i = C_{q_i}/s_i`;
- `R = C_k/S`.

Then, identically,

`C_{q_i} - C_k = (q_i-k)/4`,

so

` s_i A_i - S R = (q_i-k)/4. `

Likewise, for two source residuals,

` s_i A_i - s_j A_j = (q_i-q_j)/4. `

These are exact affine relations, not finite observations.

### Gcd consequence

If `g_i = gcd(s_i,S)`, then on a realized routed branch `g_i` divides `(q_i-k)/4`, and

`gcd(A_i,R)` divides

` |q_i-k| / (4 g_i). `

For two sources, with `g_ij=gcd(s_i,s_j)`,

`gcd(A_i,A_j)` divides

` |q_i-q_j| / (4 g_ij). `

This already reduces a large support-allocation problem to tiny integers.

The classifier goes one step further. Every simultaneous route gives one exact arithmetic progression

`r = r0 + M t`

for `p=840r+h`. Each residual is therefore a linear form in `t`. For two forms

`X(t)=at+b`, `Y(t)=ct+d`,

any common divisor divides the determinant

`|ad-bc|`.

Because divisibility by every divisor of that determinant is periodic modulo the determinant, scanning one complete determinant period gives the exact range-free gcd value set for that residual pair.

## 3. Baseline 8/6 exact atlas

Applying this to the original 8 two-source and 6 three-source QR-saturation synergies proved in `MULTISOURCE-QR-SATURATION.md` gives:

- all **8 of 8 pair synergies** have coprime source residuals;
- **5 of 6 triple synergies** have all source residuals pairwise coprime;
- across every source-source and source-destination residual pair in this baseline atlas, the only nontrivial gcd values that ever occur are

`2, 3, 13, 17`;

- three two-source branches are fully pairwise-coprime triads, including the destination residual:
  - `h=121`, `q19+q23 -> k79`;
  - `h=169`, `q11+q23 -> k19`;
  - `h=529`, `q11+q23 -> k19`.

Thus on those three branches no rational prime can occur in two of the seed-stripped residuals at all.

The later provenance-aware recursive character graph proves additional conditional sources. Those later sources are outside this pinned 8/6 corpus and require a separate expanded residual-coupling pass rather than being silently folded into the counts above.

## 4. Flagship k=19 triad

Take

`h in {169,529}`,

with the simultaneous source residues

`p mod11 = 3`,

`p mod23 = 4`.

The class seeds are

`C11 = 15 A`,

`C23 = 6 B`,

while the two routed factors give

`C19 = 11*23*R = 253 R`.

The companion differences immediately give

`15A - 253R = -2`,

`6B - 253R = 1`,

and therefore

`5A - 2B = -1`.

Consequences:

- `gcd(B,R)=1` from the second identity;
- `gcd(A,B)=1` from the third identity;
- `gcd(A,R)` divides 2 from the first identity, while both `A` and `R` are odd on the hard-prime skeleton, so `gcd(A,R)=1`.

Hence

`gcd(A,B)=gcd(A,R)=gcd(B,R)=1`.

This is range-free on the routed branch.

### Support consequence

If the three fixed shifts all miss, the existing support theorems imply:

- every prime factor of `A` lies in QR(11);
- every prime factor of `B` lies in QR(23);
- every prime factor of `R` lies in QR(19).

The three support obligations are therefore carried by disjoint rational-prime populations.

This is strictly stronger than saying that the three companions independently have positive character support.

## 5. The finite record sits inside the theorem

For

`p = 8,803,369`,

one has

`A = C11/15 = 146,723`,

`B = C23/6 = 366,808`,

`R = C19/253 = 8,699`.

They satisfy

`15*146723 - 253*8699 = -2`,

`6*366808 - 253*8699 = 1`,

`5*146723 - 2*366808 = -1`,

and are pairwise coprime.

The destination residual is exactly the adversarial cofactor from the multi-source saturation note:

`C19 = 11*23*8699`.

Its survival is therefore not caused by a hidden shared rational prime between the q=11, q=23, and k=19 residual channels. The channels are already disjoint.

## 6. A second completely coprime triad

On

`h=121`, `q19+q23 -> k79`,

write

`C19=35A`,

`C23=6B`,

`C79=4370R`.

After dividing the companion-difference identities by their coefficient gcds,

`7A - 874R = -3`,

`3B - 2185R = -7`,

`35A - 6B = -1`.

Here `A=6r+1`, so `3` never divides `A`; and `B=35r+6`, so `7` never divides `B`. Therefore all three residuals are again pairwise coprime.

This gives a second modulus set, QR(19), QR(23), and QR(79), with completely disjoint residual prime support.

## 7. Near-coprime h=121 route into k=31

For

`h=121`, `q19+q47 -> k31`,

write

`C19=35A`, `C47=42B`, `C31=1786R`.

Then

`35A - 1786R = -3`,

`21B - 893R = 2`,

`5A - 6B = -1`.

Since `A=6r+1`, `gcd(A,R)=1`; also `gcd(A,B)=1`. The only possible nontrivial overlap is

`gcd(B,R)=2`.

So even the non-completely-coprime low-shift synergy has only a single exceptional overlap prime.

## 8. Strategic meaning after the recursive expansion

The saturation program has crossed another method boundary.

It is no longer enough to ask whether routed factors fill the destination QR subgroup. On the strongest baseline branches, the source and destination residuals are already forced onto disjoint prime supports. Meanwhile the landed recursive promotion and source-independent repulsion theorems create additional conditional source routes and terminal branches.

The next residual-allocation work should therefore:

1. apply the affine/determinant gcd method to recursive source synergies with exact provenance preserved;
2. intersect residual overlap primes with the landed periodic route valuation ladder;
3. combine residual allocation with source-independent repulsion so a branch is killed as soon as either its center or its rational-prime allocation becomes impossible;
4. retain `p=8,803,369` and its residual `8699` as an adversarial anchor for any proposed strengthening.

The important negative result also remains: a higher-order character inside QR(19) cannot by itself make the k=19 QR-saturated divisor set hit a quadratic-nonresidue target. Its value is in constraining or routing the residual across shifts.

Erdős-Straus remains open.
