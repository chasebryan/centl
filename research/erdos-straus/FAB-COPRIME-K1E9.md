# Coprime `fab` Plane through 10^9

**Status:** exact finite theorem-certificate; independently verified  
**Date:** 2026-08-15  
**Depends on:** `FAB-COPRIME-PARITY-PLANE.md` (historical filename; theorem is now the full coprime plane)  
**Prior-art boundary:** the complete `fab` parametrization is due to Bello-Hernández, Benito, Fernández (2026). The finite statement here is a stricter subfamily computation: only coprime `(a,b)` pairs are allowed.  
**Claim boundary:** this is finite evidence and an exact certificate through the stated bound, not a universal proof of Erdős-Straus.

---

## 1. Subsystem tested

For every prime

\[
p\equiv1\pmod4
\]

in the six Mordell-hard classes modulo 840, and every pair

\[
1\le a,b\le11,
\qquad
\gcd(a,b)=1,
\]

the coprime-plane theorem says the original published `fab` conditions are equivalent to the single test

\[
\boxed{
\exists k\mid a+bp:
\quad
k\equiv-p\pmod{4ab}.
}
\]

The primary scanner uses this exact divisor-congruence theorem.

The independent verifier does **not** use the simplification. It enumerates the same coprime parameter pairs, reconstructs every divisor `k|a+bp`, and checks the original published conditions directly:

\[
4b\mid q(p+k),
\qquad
4a\mid pq(p+k),
\qquad
q=\frac{a+bp}{k}.
\]

---

## 2. Hosted provenance

GitHub Actions:

```text
run id:       31864821526
workflow sha: ae0e89847642acb550bbbae467c6b0c569aa00e9
artifact id:  9241686442
artifact digest:
sha256:37537df7a3bc8f3521c31815db101ee285c0d3ebfcc3d4cca823a20e1bc9dd76
```

Configured prime bound:

\[
\boxed{p<10^9.}
\]

Hosted conclusion: **success**.

---

## 3. Exact result

Mordell-hard primes checked:

\[
\boxed{1,587,581.}
\]

Survivors of the coprime parameter window

\[
1\le a,b\le11:
\]

\[
\boxed{0.}
\]

Thus every Mordell-hard prime below one billion has an exact `fab` decomposition using **coprime** parameters at most 11.

No non-coprime `(a,b)` pair is needed anywhere in the certified range.

---

## 4. Minimal parameter-bound histogram

For each prime, define the minimal box radius

\[
C(p)=\min\max(a,b)
\]

among coprime certificates in the tested window.

The exact distribution is:

| `C(p)` | hard primes first covered |
|---:|---:|
| 1 | 776,829 |
| 2 | 592,090 |
| 3 | 198,370 |
| 4 | 15,697 |
| 5 | 4,366 |
| 6 | 169 |
| 7 | 50 |
| 8 | 7 |
| 9 | 2 |
| 10 | **0** |
| 11 | **1** |

The total is

\[
1,587,581.
\]

Only

\[
\boxed{229}
\]

hard primes in the entire range require a parameter above 5.

Only

\[
\boxed{60}
\]

require a parameter above 6.

Only

\[
\boxed{10}
\]

require a parameter above 7.

Only

\[
\boxed{3}
\]

require a parameter above 8.

---

## 5. The unique bound-11 prime

The only prime in the certified range whose minimal coprime parameter bound is 11 is

\[
\boxed{p=84,525,841.}
\]

One exact certificate is

\[
\boxed{(a,b,k,q)=(11,4,71,375,4,737).}
\]

Indeed

\[
11+4p
=71,375\cdot4,737
\]

and

\[
71,375\equiv-p\pmod{176}.
\]

So

\[
4ab=176\mid p+k.
\]

The resulting denominators are given exactly by the coprime-plane formula.

This prime survives every coprime box `a,b<=10` and is killed when the numerator parameter `a=11` is admitted.

---

## 6. Why this is stronger than the published finite statement

The 2026 paper reports that the **full** parameter window

\[
1\le a,b\le11
\]

detects every tested prime `p=1 mod4` below `10^14`.

The result here is different and stricter:

\[
\boxed{
\text{through }10^9,
\text{ the non-coprime portion of that window is completely unnecessary on the Mordell-hard primes.}
}
\]

All certified primes lie in the exact one-congruence coprime subtheory.

---

## 7. Independent verifier

The second implementation evaluates the original `fab` divisibility conditions directly and returned the same finite verdict:

```text
hard primes checked: 1,587,581
survivors:           0
verdict:             ZERO_SURVIVORS
```

This independently checks that the one-congruence theorem has not changed the accepted finite candidate set.

---

## 8. Frozen SHA-256 manifest

```text
e42994d76cd1a92d2a00a070a8182385bc5150179e78c0fa456dbf1dbc1107e3  fab-simplified-primary.json
f668023544c4c1c83f2b0306556df31407924dad281391020e4b746697a26f83  fab-simplified-independent.json
2fd09b1aff01553bb663135b71bac617c75c393108adee98ac436314a29bd866  fab-simplified-report.md
95a7dd71479645b1ee28c9b5f602d8cba7d6a6fc7a7c4a76266ad566380803ba  provenance.txt
```

---

## 9. New theorem target

The finite histogram suggests a much sharper universal question than the full `fab` parametrization:

\[
\boxed{
\text{Does every Mordell-hard prime admit a certificate with }\gcd(a,b)=1?
}
\]

If yes, the entire non-coprime parameter region is unnecessary for proving Erdős-Straus.

An even stronger candidate, motivated but **not** proved by the finite data, is whether some universal small bound on coprime parameters exists. The present computation is insufficient to claim such a bound.

The structurally safer target is first to prove **coprime sufficiency with unbounded parameters**.
