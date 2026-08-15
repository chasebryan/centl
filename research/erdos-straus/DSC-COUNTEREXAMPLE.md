# Counterexample to Direct-Shadow Completeness

**Status:** exact theorem/counterexample; independently verified by two exhaustive constructions  
**Date:** 2026-08-15  
**Consequence:** universal DSC-0 is **false**; universal DSC-P is therefore **false**.  
**Claim boundary:** this does **not** disprove López Type A/B coverage or the Erdős-Straus conjecture. It disproves the proposed collapse of collective shadowing to a single direct shadow.

---

## 1. Statement refuted

The candidatewise Direct-Shadow Completeness conjecture (DSC-0) asserted:

\[
\boxed{
\text{not directly shadowed}
\Longrightarrow
\text{not union-shadowed}.
}
\]

The stronger prime-realization statement DSC-P asserted that every directly novel admissible candidate has a reduced avoiding progression.

The candidate below is directly novel but **every integer parameter is covered by earlier Type A/B layers**.

Therefore

\[
\boxed{\text{DSC-0 is false}}
\]

and, since DSC-P implies DSC-0,

\[
\boxed{\text{DSC-P is false}.}
\]

---

## 2. Constructing the candidate from the three q=3 species

Use three ancestry-minimal pure q=3 rows, one from each modulo-9 factor-pair species.

### Species `(2,5) mod 9`

Layer

\[
j_1=25,
\qquad
m_1=99=9\cdot11.
\]

Use trap

\[
u_1=79=-20\pmod{99}
\]

with factor pair

\[
(w_1,a_1)=(20,5),
\qquad
20\cdot5=100=m_1+1.
\]

### Species `(5,2) mod 9`

Layer

\[
j_2=70,
\qquad
m_2=279=9\cdot31.
\]

Use trap

\[
u_2=265=-14\pmod{279}
\]

with factor pair

\[
(w_2,a_2)=(14,20),
\qquad
14\cdot20=280=m_2+1.
\]

### Species `(8,8) mod 9`

Layer

\[
j_3=187,
\qquad
m_3=747=9\cdot83.
\]

Use trap

\[
u_3=703=-44\pmod{747}
\]

with factor pair

\[
(w_3,a_3)=(44,17),
\qquad
44\cdot17=748=m_3+1.
\]

Each trap is ancestry-minimal: no proper divisor modulus `m_i=4i-1` of its layer modulus catches the trap.

---

## 3. CRT glue in factor-pair coordinates

The target numerator coordinate must satisfy

\[
W\equiv20\pmod{11},
\qquad
W\equiv14\pmod{31},
\qquad
W\equiv44\pmod{83}.
\]

The least positive CRT solution is

\[
\boxed{W=23450}
\]

modulo

\[
11\cdot31\cdot83=28303.
\]

The complementary target coordinate satisfies

\[
A\equiv5\pmod{11},
\qquad
A\equiv20\pmod{31},
\qquad
A\equiv17\pmod{83},
\]

whose least positive solution is

\[
\boxed{A=764}.
\]

These are compatible because each local pair is multiplicatively inverse modulo its shared prime.

Now put

\[
M=WA-1.
\]

Then

\[
\boxed{M=17,915,799}
\]

and

\[
M+1=23,450\cdot764=17,915,800=4\cdot4,478,950.
\]

Therefore the target depth is

\[
\boxed{k=4,478,950.}
\]

Because

\[
764\equiv0\pmod4
\]

and

\[
23,450\mid4,478,950
\]

(the quotient is `191`), `W=23450` is a valid plain Type A/B target trap numerator.

Thus the target trap residue is

\[
\boxed{t=M-W=17,892,349.}
\]

Moreover

\[
\gcd(t,M)=1.
\]

---

## 4. Hard-compatible target progression

Take hard class

\[
\boxed{h=1\pmod{840}.}
\]

Since

\[
M=3\cdot11\cdot31\cdot83\cdot211
\]

one has

\[
\gcd(840,M)=3.
\]

Also

\[
t\equiv1\pmod3,
\]

so the CRT target is admissible.

The canonical progression is

\[
\boxed{x(s)=r+Ls}
\]

with

\[
\boxed{r=1,236,166,681}
\]

and

\[
\boxed{L=\operatorname{lcm}(840,M)=5,016,423,720.}
\]

It satisfies

\[
r\equiv1\pmod{840}
\]

and

\[
r\equiv17,892,349\pmod{17,915,799}.
\]

---

## 5. Exact three-class collective cover

For all three local rows,

\[
q_j=\frac{m_j}{\gcd(L,m_j)}=3.
\]

The exact pullbacks contain:

### Parameter class `s=0 mod 3`

At `j=70`,

\[
\boxed{r\equiv265\pmod{279}}
\]

and `265 in T_70`.

### Parameter class `s=1 mod 3`

At `j=25`,

\[
\boxed{r+L\equiv79\pmod{99}}
\]

and `79 in T_25`.

### Parameter class `s=2 mod 3`

At `j=187`,

\[
\boxed{r+2L\equiv703\pmod{747}}
\]

and `703 in T_187`.

Therefore

\[
\boxed{
R_{70}\cup R_{25}\cup R_{187}
=\{0,1,2\}
=\mathbb Z/3\mathbb Z.
}
\]

Every integer parameter `s` is caught by at least one earlier layer.

Hence the target candidate is **union-shadowed** and has no integer avoiding parameter at all.

---

## 6. Exhaustive proof that the candidate is directly novel

Two independent verifiers checked **every** earlier layer

\[
1\le j<4,478,950.
\]

Total earlier layers:

\[
\boxed{4,478,949.}
\]

### Primary verifier

`dsc_counterexample_probe.cpp`

For each earlier `j`, put

\[
q_j=\frac{4j-1}{\gcd(L,4j-1)}.
\]

A direct shadow requires the pullback to contain every one of the `q_j` parameter classes. Since

\[
|R_j|\le |T_j|\le2\tau(j),
\]

any layer with

\[
q_j>2\tau(j)
\]

is impossible as a direct shadow.

Exact count:

```text
earlier layers:                    4,478,949
pruned by q > 2*tau(j):            4,478,643
remaining pullbacks tested exactly:      306
maximum q among exact tests:               151
direct-shadow sources:                       0
```

### Independent verifier

`verify_dsc_counterexample.py`

This implementation reconstructs the target itself from the three local factor pairs and uses a different first prune:

\[
\tau(j)\le2\lfloor\sqrt j\rfloor
\]

so direct coverage requires

\[
q_j\le4\lfloor\sqrt j\rfloor.
\]

It then reconstructs the **exact** trap set before testing the full pullback.

```text
crude sqrt-bound survivors: 24,795
exact |T_j| survivors:          277
direct-shadow sources:            0
```

Both independent constructions return

\[
\boxed{\texttt{DIRECTLY\_NOVEL\_UNION\_SHADOW}.}
\]

---

## 7. Hosted provenance

GitHub Actions:

```text
run id:       31863463072
workflow sha: 566520c0649b30151c1120c902030c8a758844f2
artifact id:  9241281418
artifact digest:
sha256:021bb1142fdd5b069ee8492b92405d0e3dcad2ada9647f8e22c8af951b175b91
```

Hosted job conclusion: **success**.

Frozen file digests:

```text
806611ac582d5bfb3e8004f2f232faaf297346b1cf17b3c694ec599fdc805fa3  dsc-counterexample-primary.json
f16cb6ccde0c4ac1101a7f1114a44c69c8ba3a1e4d7498cf42cf614427edd7a9  dsc-counterexample-independent-verifier.json
8b6760c3d8e39c2de304dbbe912e8de0eab864501d72de609c7d9d2448615d8f  dsc-counterexample-report.md
65eabdef45ee7e32ce78b2ad27e5ef134aad45a284280b66d90aac8eabb5c55e  provenance.txt
```

---

## 8. Mathematical consequence

This is the exact phenomenon DSC was designed to exclude:

1. no earlier layer covers the candidate individually;
2. several proper earlier layers cover it collectively.

Therefore direct shadowing is **not** a complete obstruction theory for Type A/B exact-depth realizability.

The implication

\[
\text{directly novel}
\Longrightarrow
\text{integer avoiding progression}
\]

is false.

A fortiori the stronger reduced/Dirichlet realization implication is false.

---

## 9. What survives

This result does **not** say a single integer fails Erdős-Straus.

Quite the opposite: every point of this candidate progression is already caught by one of the earlier Type A/B layers `25,70,187`.

The following remain valid and useful:

- Type A/B trap formulas;
- shadow and ancestry theorems;
- exact finite direct-shadow certificates in their stated ranges;
- character/signature/multiplicative/fiber tools;
- CN-coprime CRT statements in their actual hypotheses;
- q=3 absorption and divisor-reduction theorems;
- the exact reduced-domain correction.

What fails is the universal claim that **collective** coverage always collapses to one direct source.

---

## 10. New research direction

The correct architecture must treat an irreducible **collective core** as a first-class object.

For a candidate progression, reduce all earlier pullbacks by:

1. frozen/direct absorption;
2. pointwise divisor descent;
3. duplicate/residue redundancy;
4. fiber peeling;
5. exact local-domain projection.

Then study the minimal surviving family whose union covers the parameter space.

The present counterexample has a minimal collective core of size three:

\[
\boxed{\{j=25,70,187\}.}
\]

Its q=3 factor-pair species are exactly

\[
(2,5),\quad(5,2),\quad(8,8)\pmod9.
\]

So the three-species construction is not forbidden; it is the first explicit irreducible collective shadow beyond the previous finite frontier.

The next objective is **not** to resurrect DSC. It is to classify collective cores and determine whether their structure can be used to prove eventual Type A/B coverage of every prime.
