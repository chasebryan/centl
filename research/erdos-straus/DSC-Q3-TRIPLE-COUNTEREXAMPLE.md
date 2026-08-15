# Direct-Shadow Completeness counterexample — primitive q=3 triple cover

**Status:** exact counterexample to universal DSC-0 and DSC-P  
**Date:** 2026-08-15  
**Claim boundary:** this falsifies the universal Direct-Shadow Completeness implication and the proposed universal Class-C local-escape route. It does **not** falsify the Erdős-Straus conjecture. In fact the candidate progression below is covered by earlier Type A/B layers, so it supplies no ES counterexample.

Read with:

- `DIRECT-SHADOW-COMPLETENESS.md`
- `Q3-ABSORPTION.md`
- `Q3-WEAK-REDUNDANCY.md`
- `Q3-POINTWISE-ABSORPTION.md`
- `Q3-FIBER-INJECTIVITY.md`
- `Q3-NEXT-DIGIT-NORMAL-FORM.md`

---

## 1. Result

There exists an admissible Mordell-hard Type A/B target candidate that is **not directly shadowed by any single earlier layer**, but is nevertheless covered by the union of three earlier q=3 layers.

Hence

\[
\boxed{
\text{directly novel}
\not\Longrightarrow
\text{not union-shadowed}.
}
\]

Therefore both proposed universal implications

\[
\boxed{\mathrm{DSC\text{-}0}}
\qquad\text{and}\qquad
\boxed{\mathrm{DSC\text{-}P}}
\]

are false.

The counterexample sits inside the active fixed-negative/Class-C geometry: the three covering layers are fixed-only, Jacobi-negative, active, and have q=3.

---

## 2. Constructed target

Take

\[
\boxed{k=15,290,696}.
\]

Then

\[
M=4k-1
=61,162,783
=11\cdot31\cdot83\cdot2161.
\]

Let

\[
\boxed{d=764=4\cdot191}
\]

and

\[
\boxed{D=20,014},
\qquad
k=dD.
\]

Choose the target Type A trap

\[
\boxed{t=-d\pmod M=61,162,019}.
\]

Because

\[
\gcd(M,840)=1,
\]

the target trap is compatible with every Mordell-hard class

\[
H=\{1,121,169,289,361,529\}\pmod{840}.
\]

For the simplest representative choose

\[
\boxed{h=1}.
\]

The candidate progression is

\[
x(s)=r+Ls,
\]

where CRT gives

\[
\boxed{L=\operatorname{lcm}(840,M)=51,376,737,720}
\]

and

\[
\boxed{r=41,284,877,761}.
\]

Thus

\[
r\equiv1\pmod{840},
\qquad
r\equiv61,162,019\pmod{61,162,783}.
\]

---

## 3. The three covering q=3 layers

Use the earlier layers

\[
\boxed{j=25,70,187}.
\]

Their moduli are

\[
m_{25}=99=9\cdot11,
\qquad
m_{70}=279=9\cdot31,
\qquad
m_{187}=747=9\cdot83.
\]

For the target progression:

\[
\gcd(L,99)=33,
\qquad
\gcd(L,279)=93,
\qquad
\gcd(L,747)=249.
\]

Hence all three pullback moduli are exactly

\[
\boxed{q_{25}=q_{70}=q_{187}=3}.
\]

### Layer 25

Modulo `99`,

\[
r\equiv28,
\qquad
L\equiv66.
\]

Therefore the three parameter classes give

\[
28,\ 94,\ 61\pmod{99}.
\]

Since

\[
94\equiv-5\pmod{99},
\qquad 5\mid25,
\]

and the other two lifts are not in `T_25`,

\[
\boxed{R_{25}=\{1\}}.
\]

### Layer 70

Modulo `279`,

\[
r\equiv73,
\qquad
L\equiv93.
\]

The three lifts are

\[
73,\ 166,\ 259\pmod{279}.
\]

Since

\[
259\equiv-20=-4\cdot5\pmod{279},
\qquad 5\mid70,
\]

we get

\[
\boxed{R_{70}=\{2\}}.
\]

### Layer 187

Modulo `747`,

\[
r\equiv730,
\qquad
L\equiv498.
\]

The three lifts are

\[
730,\ 481,\ 232\pmod{747}.
\]

Since

\[
730\equiv-17\pmod{747},
\qquad17\mid187,
\]

we get

\[
\boxed{R_{187}=\{0\}}.
\]

Therefore

\[
\boxed{
R_{25}\cup R_{70}\cup R_{187}
=\{0,1,2\}
=\mathbb Z/3\mathbb Z.
}
\]

Every integer parameter `s` hits at least one earlier Type A/B layer.

So this target candidate is **union-shadowed**.

---

## 4. The cover is pointwise primitive

The three trap atoms used above are exactly the kind left after the strong/weak/pointwise reductions:

- `j=25`: `u=94=-5 mod 99`;
- `j=70`: `u=259=-4*5 mod 279`;
- `j=187`: `u=730=-17 mod 747`.

Each is pointwise primitive relative to every earlier layer whose modulus divides `m_j/3`.

Their residues modulo `9` are

\[
94\equiv4,
\qquad
259\equiv7,
\qquad
730\equiv1
\pmod9.
\]

Thus they occupy the three distinct next 3-adic digits predicted by `Q3-NEXT-DIGIT-NORMAL-FORM.md`.

---

## 5. The three rows are active fixed-negative rows

Their squarefree signatures are

\[
\sigma(99)=e_{11},
\qquad
\sigma(279)=e_{31},
\qquad
\sigma(747)=e_{83},
\]

because the factor `3^2` is square.

All three primes `11,31,83` divide the target modulus `M`, so all three rows are fixed-only in the character-shield sense.

For the chosen target residue,

\[
\left(\frac r{99}\right)=-1,
\qquad
\left(\frac r{279}\right)=-1,
\qquad
\left(\frac r{747}\right)=-1.
\]

Since each has `q_j=3>1`, all three belong to the active fixed-negative core

\[
\boxed{\mathcal N^{\rm act}_{k,r}}.
\]

Thus this is not merely a non-character residual accident. It is a genuine shared Class-C active-core cover.

---

## 6. Direct novelty — exhaustive exact verification

The remaining question is whether some **single** earlier layer directly shadows the target. It does not.

A direct shadow at layer `j` requires

\[
|R_j|=q_j.
\]

Since

\[
|R_j|\le|T_j|\le2\tau(j),
\]

only layers with

\[
q_j\le2\tau(j)
\]

can possibly directly shadow.

Two independent exhaustive implementations were used.

### Verifier A — full j scan + exact divisor-count sieve

For every

\[
1\le j<15,290,696,
\]

a linear divisor-count sieve found

\[
\boxed{\max\tau(j)=504}
\]

(attained at `j=14,414,400`).

Hence any direct shadow must satisfy

\[
q_j\le1008.
\]

The implementation scanned all 15,290,695 earlier layers, retained only those meeting the exact cardinality condition, reconstructed every trap pullback, and found:

```text
possible after q <= 2*tau(j): 297
actual direct shadows:           0
```

The same result holds for each of the six hard classes.

### Verifier B — independent square-root envelope

A separate Python control flow does not use the maximum-tau sieve.

It uses only the elementary bound

\[
\tau(j)\le2\sqrt j,
\]

so a direct shadow must satisfy

\[
q_j\le4\sqrt j<15,642.
\]

It scans all earlier `j` for this coarse necessary condition, obtaining `111,057` candidates; independently factors those `j`, applies the exact `q_j<=2*tau(j)` test, leaving the same

\[
\boxed{297}
\]

possible layers; and reconstructs their exact pullbacks.

Result:

\[
\boxed{0\text{ direct shadows}.}
\]

Therefore the candidate is directly novel but union-shadowed.

---

## 7. How the counterexample was constructed

This was not obtained by blindly scanning fifteen million depths.

The primitive q=3 atoms impose congruences on the target divisor `d`.

Choose:

- row `25`, atom `-5`, giving `d=5 mod 11`;
- row `70`, atom `-4*5`, giving `d=20 mod 31`;
- row `187`, atom `-17`, giving `d=17 mod 83`.

CRT gives

\[
\boxed{
d\equiv764\pmod{11\cdot31\cdot83}
}
\]

with least positive solution `d=764`.

The complementary target factor must satisfy the inverse factor-pair congruences

\[
D\equiv5\pmod{11},
\qquad
D\equiv19\pmod{31},
\qquad
D\equiv11\pmod{83},
\]

whose least positive solution is

\[
\boxed{D=20,014}.
\]

Then

\[
k=dD=15,290,696
\]

and automatically

\[
4k-1
=(11\cdot31\cdot83)\cdot2161.
\]

The q=3 triple cover is therefore a CRT/factor-pair construction arising directly from the primitive next-digit theory.

---

## 8. Consequences for the research architecture

### Falsified

The following universal targets must no longer be used:

\[
\boxed{
\text{direct novelty}\Rightarrow\text{no union shadow}
}
\]

and

\[
\boxed{
\text{direct novelty}\Rightarrow\text{reduced avoiding progression}.
}
\]

In particular:

- universal DSC-0 is false;
- universal DSC-P is false;
- universal shared-CN local escape is false;
- the proposed universal Class-C implication `direct novelty -> local escape` is false.

### Not falsified

The following remain valid within their stated boundaries:

- all frozen finite DSC certificates through `k<=1500`;
- C1 single-layer escape;
- C2-coprime and CN-coprime CRT results;
- strong q=3 absorption;
- weak q=3 redundancy;
- pointwise q=3 absorption;
- q=3 fiber injectivity;
- q=3 next-digit normal form;
- ancestry rigidity theorems;
- character-shield completeness.

The counterexample appears far beyond the previous finite frontier and is fully consistent with those bounded certificates.

---

## 9. Consequence for Erdős-Straus

This counterexample is **not bad news for the Erdős-Straus conjecture itself**.

The target progression is not an uncovered family. It is the opposite: every parameter is caught by one of the earlier Type A/B layers `25,70,187`.

So the lesson is architectural:

> collective Type A/B shadowing is real, and it can be constructive rather than pathological.

The research program should pivot from trying to prove that collective shadows never occur to **classifying and exploiting collective shadows** as an additional coverage mechanism.

That may strengthen the route toward López-all-primes, because a target candidate need not possess an exact-depth realization in order for its primes to be covered by Type A/B; it may instead collapse collectively into earlier covered layers.

---

## 10. New frontier

The immediate replacement for DSC is a **collective-shadow classification program**:

1. classify primitive q=3 triple covers by CRT/factor-pair data;
2. determine when such covers are themselves forced for remaining Type A/B target candidates;
3. combine direct shadows, collective shadows, character shields, and explicit realizations into a complete prime-coverage theorem;
4. attack the López remainder directly rather than requiring every novel candidate to realize an exact-depth prime family.

The universal ES wall remains exactly where it should:

\[
\boxed{\text{López all primes open; Erdős-Straus open}.}
\]
