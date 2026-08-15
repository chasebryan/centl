# Pointwise-Primitive q=3 Cover Certificate through k = 100,000

**Status:** exact finite theorem-certificate; independently verified  
**Date:** 2026-08-15  
**Depends on:** `REDUCED-PARAMETER-DOMAIN.md`, `Q3-ABSORPTION.md`, `Q3-WEAK-REDUNDANCY.md`, `Q3-POINTWISE-ABSORPTION.md`, `Q3-NEXT-DIGIT-THEOREM.md`  
**Claim boundary:** this is a finite certificate for the necessary corrected-domain q=3 obstruction. It does **not** prove universal DSC-P, López Type A/B coverage for every prime, or Erdős-Straus.

---

## 1. Exact obstruction tested

For a program candidate

\[
x=r+Ls,
\qquad
L=\operatorname{lcm}(840,4k-1),
\]

the exact Dirichlet reducedness condition is imposed on `x`, not on `s`.

Because

\[
3\mid840\mid L,
\]

the q=3 local parameter domain is the full ring

\[
\boxed{\mathbb Z/3\mathbb Z=\{0,1,2\}.}
\]

A pair of singleton pullbacks forbidding only two classes is therefore **not** a local obstruction.

By strong absorption and pointwise absorption, a directly novel candidate cannot use any q=3 trap witness that reduces into an earlier frozen divisor modulus. The probe removes those witnesses first and asks whether the remaining **pointwise-primitive** q=3 pullbacks cover all three classes.

Thus the finite falsifier attacks the necessary obstruction

\[
\boxed{
\bigcup R_j^{\rm primitive}=\{0,1,2\}.
}
\]

---

## 2. Two independent constructions

Primary:

`q3_primitive_cover_probe.py`

- constructs exact q=3 layers from the valuation shape of `L`;
- reconstructs pointwise-primitive hard-compatible traps;
- solves the affine pullback equation for the forbidden class.

Independent verifier:

`verify_q3_primitive_cover.py`

- constructs `L` directly with `lcm`;
- enumerates exact q=3 moduli as divisors of `3L`, followed by the exact quotient test;
- reconstructs primitive traps by independent parent elimination;
- does **not** solve the pullback equation: it directly evaluates
  \[
  x(a)=r+La,
  \qquad a=0,1,2,
  \]
  against the independently reconstructed primitive trap sets.

The two constructions agree exactly.

---

## 3. Hosted workflow provenance

GitHub Actions:

```text
run id:       31862450106
workflow sha: 945028ab0df6560e829274eef88323e4ec8e378b
artifact id:  9240995862
artifact digest:
sha256:662310e97dbb60042bbcea3db8432797019a1b8860374b6e2d41ab1c96625579
```

Configured frontier:

\[
\boxed{k\le100000.}
\]

The hosted job completed successfully, including primary analysis, independent verification, exact regression checks, SHA-256 freezing, and artifact upload.

---

## 4. Exact finite result

Target depths examined:

```text
99,999
```

Exact q=3 layer occurrences generated across those targets:

```text
479,872
```

q=3 layer occurrences whose layer has at least one pointwise-primitive hard-compatible trap:

```text
68,311
```

Admissible hard Type A/B target candidates requiring primitive-q3 evaluation:

\[
\boxed{3,567,030.}
\]

Full pointwise-primitive q=3 covers:

\[
\boxed{0.}
\]

No tested candidate has primitive union mask `7 = 0b111`.

---

## 5. Complete union-mask histogram

With bit `a` representing forbidden parameter class `a mod 3`:

| mask | occupied classes | candidates |
|---:|:---|---:|
| `0` | none | 3,320,884 |
| `1` | `{0}` | 77,008 |
| `2` | `{1}` | 82,372 |
| `3` | `{0,1}` | 146 |
| `4` | `{2}` | 86,322 |
| `5` | `{0,2}` | 145 |
| `6` | `{1,2}` | 153 |
| `7` | `{0,1,2}` | **0** |

Therefore every candidate in the tested range retains at least one q=3 parameter class after pointwise absorption.

The two-digit cases total only

\[
146+145+153=\boxed{444}
\]

out of the 3,567,030 evaluated candidates.

---

## 6. First two-digit union

The first surviving two-digit primitive union occurs at

```text
k = 6878
h = 121
t = 26787
L = 23109240
r = 17468761
```

and is supplied by

```text
j = 25   -> class 1
j = 646  -> class 0
```

so the union mask is

\[
\boxed{3=0b011.}
\]

Class `2` remains available. This is therefore not a q=3 obstruction.

---

## 7. First candidate with at least three primitive rows

The first candidate carrying at least three pointwise-primitive q=3 rows is

```text
k = 23400
h = 1
t = 92699
L = 78623160
r = 39217081
```

with rows

```text
j = 25   -> class 2
j = 286  -> class 2
j = 754  -> class 2
```

All three hit the **same** next 3-adic digit, giving only

\[
\boxed{4=0b100.}
\]

This is the first visible instance of the stronger alignment phenomenon now under attack.

---

## 8. Independent verifier

The independent direct-evaluation verifier returned:

```text
verdict:            VERIFIED
primary comparison: MATCH
mismatched fields:  []
full covers:         0
```

It reproduced the complete union-mask histogram exactly.

---

## 9. Frozen file digests

Internal artifact SHA-256 manifest:

```text
869ac6ca4613e8371a810f46801047c4b7d3d31b039f8d974f62e061723a95fb  q3-primitive-cover.json
395c5c5df64b9a759350437097209d6bf8d2bb5b60b287182ec0f0531f9dc0e6  q3-primitive-cover-report.md
16dbf99625c582b152eb12dcf13a54028b7f3be359f94a3cc43b8bfadbd0958f  q3-primitive-cover-independent-verifier.json
25e2c472624dbdc44d709933eaaaf56462a0a19ea42e082ae9cf833e1cc35b4e  provenance.txt
```

---

## 10. What changed mathematically

The former q=3 frontier asked whether two complementary singleton pullbacks could cover the unit classes `{1,2}`.

That was based on an unnecessarily strong parameter-unit condition.

The corrected chain is now

\[
\boxed{
\begin{array}{c}
\text{exact Dirichlet domain at }3=\mathbb Z/3\mathbb Z\\
\downarrow\\
\text{strong layers impossible on directly novel candidates}\\
\downarrow\\
\text{weak descendants residue-redundant}\\
\downarrow\\
\text{pointwise nonprimitive witnesses directly shadowed}\\
\downarrow\\
\text{one global next 3-adic digit}\\
\downarrow\\
\text{pointwise-primitive full three-class cover required}.
\end{array}
}
\]

The final necessary obstruction in that chain has now been falsified on every admissible target through `k=100,000`.

---

## 11. Next theorem target

The finite data suggests something stronger than mere noncoverage:

> whenever several genuinely primitive q=3 rows align on one admissible candidate, their next-digit values exhibit severe alignment rather than independent spreading.

The next proof target is therefore an **ancestry-minimal q=3 alignment theorem**: reduce every q=3 witness along divisor ancestry while preserving its digit, then prove that the surviving minimal representatives cannot occupy all three next digits.
