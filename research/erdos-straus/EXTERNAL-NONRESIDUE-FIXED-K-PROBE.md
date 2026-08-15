# External-nonresidue × hard-shield fixed-k probe

**Status:** exact finite exploratory signal; standalone falsifier checked in  
**Date:** 2026-08-15  
**Depends on:** `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`, `FAB-HARD-NONRESIDUE-BRIDGE.md`, `FAB-MIRROR-CHARACTER-OBSTRUCTION.md`  
**Claim boundary:** this is **not** a universal theorem and **not** a proof of Erdős-Straus. The zero-failure observation below is finite and must remain labelled computational until promoted by a theorem.

---

## 1. Motivation

The mirror-character theorem proves that reflecting a shifted factor whose prime support is already quadratic-residue-safe cannot supply the fixed-k target. Therefore the fixed-k construction must deliberately import external nonresidue support.

For a Mordell-hard prime `p`, call a prime

\[
\ell\ge11
\]

**external** when

\[
\boxed{\left(\frac\ell p\right)=-1.}
\]

The hard shield gives

\[
\left(\frac2p\right)
=
\left(\frac3p\right)
=
\left(\frac5p\right)
=
\left(\frac7p\right)=+1.
\]

This suggests combining one genuinely new nonresidue prime with the existing small shield.

---

## 2. Exact rule tested

For each hard prime `p`:

1. list the first eight primes `ell>=11` with `(ell/p)=-1`;
2. for each such `ell`, try
   \[
   \boxed{k=m\ell,\qquad m\in\{1,3,5,7\},}
   \]
   retaining only `k==3 mod4`;
3. put
   \[
   C=\frac{p+k}{4};
   \]
4. apply the proved fixed-k theorem exactly:
   \[
   \boxed{
   \exists u\mid C^2,\qquad4u\equiv-1\pmod k.
   }
   \]

A hit therefore gives a genuine sufficient Egyptian-fraction certificate. The only non-theorem part is the assertion that this menu always contains a hit.

---

## 3. Exploratory finite result through 10^7

On the six Mordell-hard classes modulo `840`, the exploratory exact run covered

\[
\boxed{20,513/20,513}
\]

hard primes `p<=10^7`.

Observed first-hit multiplier counts were:

```text
m = 1 : 11,935
m = 3 :  6,000
m = 5 :    867
m = 7 :  1,711
```

The successful external-nonresidue rank was heavily front-loaded:

```text
rank 1 : 18,774
rank 2 :  1,458
rank 3 :    216
rank 4 :     46
rank 5 :     12
rank 6 :      6
rank 7 :      1
```

No first hit in this run required the eighth nonresidue, although the checked-in falsifier deliberately keeps an eight-prime menu for margin.

For the successful shifted factor `C=(p+k)/4`, the gcd with the hard shield `105=3*5*7` was distributed as:

```text
gcd(C,105)= 1 : 2,747
             3 : 6,415
             5 : 4,231
             7 :   527
            15 : 6,187
            21 :    35
            35 :   371
```

So most hits acquire a `3` or `5` coordinate, but the mechanism is not merely divisibility by `105`: `2,747` successful cases had `gcd(C,105)=1`.

---

## 4. Why this signal is stronger than another bounded box

The menu is not a generic search over arbitrary `(a,b)`.

It has the specific structural form

\[
\boxed{
\text{external nonresidue}
\times
\text{hard-shield multiplier }\{1,3,5,7\}.
}
\]

The external factor supplies the quadratic sign that the mirror theorem proves is necessary; the multiplier comes entirely from the already-frozen small-prime hard shield.

This makes the observed rule a plausible theorem target rather than a naked numerical cutoff.

---

## 5. Standalone replay

The exact finite falsifier is checked in as

[`external_nr_fixed_k_probe.py`](external_nr_fixed_k_probe.py).

It uses only the Python standard library and independently performs:

- prime enumeration;
- Mordell-hard residue filtering;
- Euler-criterion Legendre symbols;
- exact factorization of `C`;
- exact residue dynamic programming over all divisors of `C^2`.

Recommended replay:

```bash
python3 research/erdos-straus/external_nr_fixed_k_probe.py \
  --limit 10000000 \
  --nr-count 8 \
  --json
```

A hosted/independent replay should be frozen before treating the finite counts as a formal certificate artifact.

---

## 6. The theorem we actually need

The finite observation points to the following sharply stated target.

### External-nonresidue shield-rescue target

For every Mordell-hard prime `p`, there exists an external prime `ell>=11` with

\[
\left(\frac\ell p\right)=-1
\]

and a multiplier

\[
m\in\{1,3,5,7\}
\]

such that

\[
k=m\ell\equiv3\pmod4
\]

and, with

\[
C=\frac{p+k}{4},
\]

the square-divisor box hits the fixed target:

\[
\boxed{
\exists u\mid C^2:
4u\equiv-1\pmod k.
}
\]

Proving this statement would give a pointwise sufficient fab certificate for every Mordell-hard prime. Combined with the classical reductions for the non-hard classes and scaling from prime divisors, it would close Erdős-Straus.

The number `8` from the finite probe is **not** part of the theorem target. It is evidence that the external prime may be chosen very early, not a claimed universal bound.

---

## 7. Immediate proof question

For `k=m ell`, the CRT decomposition of the target separates into:

1. an external `ell` coordinate where `(ell/p)=-1` forces a nontrivial character condition on
   \[
   C=(p+m\ell)/4;
   \]
2. a tiny `m` coordinate supported entirely on `3,5,7`.

The next proof step is therefore to determine whether the divisor-square residue set of `C` can fail simultaneously on both coordinates for **every** external nonresidue `ell`.

That is the present one-shot target.
