# Prime-index hierarchy for FAB Kneser defects

**Status:** proved corollary of `FAB-KNESER-DIVISOR-DEFECT.md`  
**Date:** 2026-08-15  
**Claim boundary:** sharply bounds the non-power-residue valuation mass in any prime-index fixed-k placement defect. It does not prove that such defects cannot occur for every auxiliary k and therefore does not prove Erdős-Straus.

---

## 1. Setup

Use the notation of `FAB-KNESER-DIVISOR-DEFECT.md`.

For a fixed admissible `k`, write

\[
C=\frac{p+k}{4}=\prod_i r_i^{e_i}
\]

and let `R` be the signed divisor box. Assume the exact target is missed and let

\[
H=\operatorname{Stab}(R).
\]

The Kneser defect budget is

\[
\boxed{
\sum_i
\left(
\min(2e_i+1,\operatorname{ord}_{G_k/H}(r_iH))-1
\right)
\le [G_k:H]-2.
}
\]

---

## 2. Prime quotient index

Assume the stabilizer quotient has odd prime order

\[
\boxed{[G_k:H]=\ell.}
\]

Then every nonidentity element of `G_k/H` has exact order `ell`.

Hence for every prime factor `r_i` lying outside `H`,

\[
\operatorname{ord}(r_iH)=\ell
\]

and its contribution to the defect budget is

\[
\boxed{
\min(2e_i+1,\ell)-1
=\min(2e_i,\ell-1).
}
\]

If

\[
e_i\ge\frac{\ell-1}{2},
\]

then this one factor contributes `ell-1`, already larger than the entire available budget `ell-2`. Therefore every exceptional factor must satisfy

\[
\boxed{e_i\le\frac{\ell-3}{2}.}
\]

In that allowed range its contribution is exactly `2e_i`.

Summing the defect inequality gives

\[
2\sum_{r_i\notin H}e_i
\le\ell-2.
\]

The left side is even, so in fact

\[
\boxed{
\sum_{r_i\notin H}e_i
\le\frac{\ell-3}{2}.
}
\]

---

## 3. Prime-index defect theorem

### Theorem

If a fixed-k FAB signed divisor box misses its target and the stabilizer quotient has odd prime index `ell`, then the total valuation mass of prime factors of `C=(p+k)/4` outside the index-`ell` subgroup is bounded by

\[
\boxed{
\sum_{
 r^e\parallel C,
 r\notin H
}e
\le\frac{\ell-3}{2}.
}
\]

When the ambient unit group is cyclic and `H` is the unique index-`ell` subgroup, this says:

\[
\boxed{
\text{total exponent of prime factors of }C
\text{ that are not }\ell\text{-th-power residues}
\le\frac{\ell-3}{2}.
}
\]

This is a valuation statement, not merely a bound on the number of exceptional distinct primes.

---

## 4. First cases

### ell = 3

\[
\frac{\ell-3}{2}=0.
\]

Therefore every prime factor of `C` lies in the cubic-residue subgroup.

This recovers the cubic-defect theorem.

### ell = 5

\[
\frac{\ell-3}{2}=1.
\]

There is at most one non-fifth-power prime factor, and it must occur to exponent one.

This recovers the fifth-power sparsity theorem.

### ell = 7

\[
\frac{\ell-3}{2}=2.
\]

The complete exceptional valuation mass is at most two. The only possibilities are therefore:

- one exceptional prime to exponent one;
- one exceptional prime to exponent two;
- two distinct exceptional primes, both simple.

Everything else in `C` is a seventh-power residue in the quotient.

### ell = 11

The total exceptional valuation mass is at most four.

Thus even at larger prime defect index, most of the shifted factorization is forced into one high-power residue subgroup.

---

## 5. Contrapositive expansion criterion

The theorem has an immediately useful contrapositive.

Fix an odd prime `ell` dividing the order of the relevant cyclic unit group. If

\[
\boxed{
\sum_{
 r^e\parallel C,
 r\notin G^\ell
}e
>\frac{\ell-3}{2},
}
\]

then **index `ell` cannot be the stabilizer defect of a failed FAB box**.

Thus every independent non-`ell`-power prime factor consumes two units of Kneser room, and enough such factors eliminate that defect index completely.

This turns higher-power residue diversity in the shifted integer into an exact placement weapon.

---

## 6. Relation to external nonresidue descent

At an external nonresidue prime `q=3 mod4`, the shifted integer

\[
C_q=\frac{p+q}{4}
\]

contains a prime factor that is a quadratic nonresidue modulo both `p` and `q`.

If the FAB box at `q` fails with odd prime defect index `ell`, then all but at most `(ell-3)/2` units of prime-factor valuation of `C_q` must nevertheless lie in the `ell`-th-power subgroup modulo `q`.

Therefore a persistent failure along the external-nonresidue factor cycle requires a sequence of shifted factorizations that are simultaneously:

1. quadratic-sign rich enough to carry the nonresidue descent;
2. higher-power-residue sparse enough to remain inside the Kneser budget.

That tension is the next universal obstruction to exploit.
