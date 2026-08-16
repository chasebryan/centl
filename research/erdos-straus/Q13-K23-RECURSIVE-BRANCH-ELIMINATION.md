# q13 recursive elimination of the exceptional k=23 branches

**Status:** proved conditional branch-elimination theorem  
**Date:** 2026-08-16  
**Depends on:** `JACOBI-SATURATION-CHARACTER-EXTRACTION.md`, `QR-SATURATING-ROUTED-SEEDS.md`, Lane-I Type-II divisor-square equivalence  
**Primary classifier:** `classify_q13_k23_branch_elimination.py`  
**Independent anchors:** `verify_q13_k23_branch_elimination.py`  
**Claim boundary:** this eliminates two exact subbranches after the q13 extraction. It does not eliminate the positive k=23 centers and does not prove Erdős-Straus.

## 1. The recursive source

The composite Jacobi-saturation theorem produces two conditional q13 character sources.

On hard class h=121:

- p mod47 = 8 routes 47 into C39;
- the routed k=39 seed is Jacobi-saturating;
- if k=39 misses, then `(13/p)=+1`.

On hard class h=289:

- p mod11 = 5 and p mod47 = 8 route 11 and47 into C39;
- the pair seed is Jacobi-saturating;
- if k=39 misses, then `(13/p)=+1`.

Thus q13 is a new conditional source on both branches.

## 2. Route q13 into k=23

For q=13, the k=23 routing condition is

`p mod13 = -23 mod13 = 3`.

Residue 3 is a quadratic residue modulo13, so it is a permitted subbranch of `(13/p)=+1`.

On this subbranch

`13 divides C23`.

Every Mordell-hard prime already has the universal k=23 seed6, so

`6 divides C23`.

Therefore

`78 = 6*13 divides C23`.

The divisors of 78 squared realize exactly the complete nonzero quadratic-residue subgroup modulo23.

Hence seed78 is QR-saturating at k=23.

## 3. Saturation eliminates every negative p mod23 center

Because 78 is QR-saturating, a k=23 miss is possible only when every prime factor of C23 is a quadratic residue modulo23. In particular C23 itself is then a quadratic residue, and therefore p mod23 must be a quadratic residue.

The ordinary seed-6 k=23 closure has exactly two negative-character miss centers:

`p mod23 = 5`

and

`p mod23 = 14`.

Both are therefore impossible after the q13 route supplies seed78.

This already proves the branch elimination. In fact, the two branches admit explicit Type-II divisors.

## 4. Explicit Type-II collision for p mod23=5

The inverse of 4 modulo23 is6. Thus

`C23 mod23 = 6p mod23`.

If

`p mod23 = 5`,

then

`C23 mod23 = 7`.

The Type-II target is

`-C23 mod23 = 16`.

Now

`39 mod23 = 16`.

Also

`39 = 3*13`.

Since 6*13 divides C23, both 3 and13 divide C23, so

`39 divides C23 squared`.

Therefore D=39 is an exact Type-II divisor-square certificate and fixed k=23 hits.

So:

> On either extracted-q13 branch, if p mod13=3 and p mod23=5, k=23 cannot miss.

## 5. Explicit Type-II collision for p mod23=14

If

`p mod23 = 14`,

then

`C23 mod23 = 15`.

The Type-II target is

`-C23 mod23 = 8`.

But

`169 = 13^2 = 8 mod23`.

Since 13 divides C23,

`169 divides C23 squared`.

Thus D=169 is an exact Type-II divisor-square certificate and k=23 hits.

Therefore:

> On either extracted-q13 branch, if p mod13=3 and p mod23=14, k=23 cannot miss.

## 6. Recursive branch-elimination theorem

Combining the two cases gives the range-free conditional result:

> Let p lie on either q13 extraction branch from the composite k=39 theorem. Assume k=39 misses, so `(13/p)=+1`, and refine to the valid source residue p mod13=3. Then 13 is routed into C23 and seed78 becomes mandatory. If k=23 also misses, p mod23 must lie in the quadratic-residue subgroup modulo23. In particular the two exceptional negative k=23 miss residues 5 and14 are impossible.

Equivalently, the branch tree

`k39 miss -> q13 positive -> p mod13=3 -> k23`

has no surviving children with

`p mod23 in {5,14}`.

This is the first recursive route result in the current program where a character extracted from one saturated destination is routed onward and **eliminates** pre-existing miss branches at a second destination.

## 7. Independent prime anchors

The verifier pins one actual prime on each hard-class and exceptional-center combination before the final k=23 collision:

- h=121, p mod23=5: p=15,840,841;
- h=121, p mod23=14: p=21,999,721;
- h=289, p mod23=5: p=327,480,169;
- h=289, p mod23=14: p=62,135,089.

Each prime satisfies

- the relevant origin source residues;
- p mod13=3;
- a genuine k=39 miss;
- 78 divides C23;
- k=23 hits;
- the named D=39 or D=169 is the exact Type-II divisor target.

These finite anchors are regressions, not the proof. The branch-elimination theorem is the range-free divisor argument above.

## 8. What survives

The theorem does not force k=23 to hit on every q13-routed branch. The positive p mod23 centers can still miss when the remaining C23 factorization stays inside QR(23).

The gain is exact pruning:

- ordinary k=23 miss geometry includes two negative-character exceptions;
- after the extracted q13 route p mod13=3, both negative exceptions are gone;
- any remaining k=23 miss is a QR-support node and can be promoted again as a positive q23 character source.

This is the desired recursive pattern:

`composite saturation -> extracted prime character -> routed factor -> prime saturation -> branch elimination / promotion`.

The next search should apply this branch-aware rule to the extracted q17, q37, and q43 sources and test whether their saturation destinations conflict with fixed residues already carried by the branch.

Erdős-Straus remains open.
