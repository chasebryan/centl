# External-nonresidue shield-ratio census through `p <= 10^7`

**Status:** exact finite theorem-mining signal; replayable falsifier checked in  
**Date:** 2026-08-15  
**Depends on:** `EXTERNAL-NR-M1-SYNCHRONIZATION.md`, `FAB-HARD-FIRST-FILTERS.md`, `external_nr_shield_ratio_probe.py`  
**Claim boundary:** this is finite evidence and a theorem falsifier. It is not a universal existence theorem and is not a proof of Erdős–Straus.

---

## 1. Rule tested

Restrict to Mordell-hard primes that survive all four exact necessary counterexample restrictions in `FAB-HARD-FIRST-FILTERS.md`.

For each such prime `p`, scan primes

\[
\ell\equiv3\pmod4,
\qquad
\left(\frac\ell p\right)=-1,
\]

in increasing order. Put

\[
C=\frac{p+\ell}{4}.
\]

The exact fixed-k divisor-ratio theorem gives a strong sufficient certificate if

\[
-p^{-1}\pmod\ell
\]

lies in the signed divisor-ratio box of `C`.

This census imposes the much stronger restriction that the ratio must use **only the hard-shield primes**:

\[
\boxed{
2^{z_2}3^{z_3}5^{z_5}7^{z_7}
\equiv-p^{-1}\pmod\ell,
}
\]

with

\[
-v_q(C)\le z_q\le v_q(C).
\]

Thus no prime factor of `C` outside `{2,3,5,7}` is permitted in the winning ratio.

---

## 2. Exact finite result

On the hard-prime population through

\[
\boxed{p\le10^7},
\]

the census contains

\[
20,513
\]

Mordell-hard primes in total and

\[
\boxed{2,173}
\]

survivors of the four exact first filters.

Using external primes

\[
\ell\le100,000
\]

and allowing at most the first `300` eligible external primes for each `p`, the exact shield-only search found

\[
\boxed{2,173/2,173}
\]

successful certificates.

There were

\[
\boxed{0}
\]

failures in this finite census.

---

## 3. Hardest observed finite case

The largest first-hit external rank observed was

\[
\boxed{98}.
\]

It occurred at

\[
\boxed{p=4,462,921}.
\]

The successful external prime was

\[
\boxed{\ell=2,459}.
\]

Then

\[
C=\frac{p+\ell}{4}
=1,116,345.
\]

The successful shield ratio had signed exponent vector

\[
(z_2,z_3,z_5,z_7)=(0,1,1,0),
\]

so the winning ratio was simply

\[
\boxed{R=15}.
\]

Equivalently,

\[
\boxed{15p\equiv-1\pmod{2459}.}
\]

Both `3` and `5` divide `C`, so this ratio lies inside the exact allowed signed divisor box.

This example is useful strategically: it demonstrates that the phenomenon is not a hidden fixed finite list of very small external primes. The adaptive external rank can grow substantially while the **internal ratio remains tiny**.

---

## 4. Interpretation

The finite evidence now separates the two jobs extremely cleanly:

1. choose an adaptive external prime `ell` to provide the required nonresidue modulus and force
   \[
   (C/p)=(C/\ell)=-1;
   \]
2. use only the already-frozen hard shield `{2,3,5,7}` inside `C` to place the exact ratio
   \[
   -p^{-1}\pmod\ell.
   \]

The universal theorem suggested by the data is therefore **not** a bounded external-prime theorem. It is the cap-free statement:

> For every Mordell-hard prime surviving the exact preliminary filters, there exists some external prime
> \[
> \ell\equiv3\pmod4,
> \quad
> (\ell/p)=-1,
> \]
> such that the available signed `{2,3,5,7}`-ratio box of
> \[
> C=(p+\ell)/4
> \]
> contains `-p^{-1} mod ell`.

Proving that statement would provide a strong sufficient certificate for every remaining hard prime and would close the all-prime wall after the standard reductions.

---

## 5. Exact arithmetic form of a shield-only hit

Write the signed shield ratio as

\[
R=\frac AB,
\]

where `A,B` are coprime `210`-smooth integers and

\[
AB\mid C.
\]

Then

\[
R\equiv-p^{-1}\pmod\ell
\]

is exactly

\[
\boxed{\ell\mid pA+B.}
\]

The divisibility `AB|C` is exactly

\[
\boxed{\ell\equiv-p\pmod{4AB}.}
\]

Thus every finite hit is a pair of simultaneous exact statements:

\[
\boxed{
\ell\mid pA+B,
\qquad
\ell\equiv-p\pmod{4AB},
}
\]

with `A,B` supported only on `{2,3,5,7}`.

This form should be the starting point for the universal descent: the external prime is not arbitrary; it is simultaneously a prime factor of one tiny-shield linear form and a prescribed residue modulo the shield denominator.

---

## 6. Replay

The checked-in standalone falsifier is

`external_nr_shield_ratio_probe.py`.

A matching replay command is:

```bash
python3 research/erdos-straus/external_nr_shield_ratio_probe.py \
  --limit 10000000 \
  --ell-search-limit 100000 \
  --max-external 300 \
  --first-four-only
```

The script uses only the Python standard library and independently performs prime enumeration, the four preliminary theorem filters, Euler-criterion Legendre symbols, hard-shield valuation extraction, and exact signed-ratio dynamic programming.
