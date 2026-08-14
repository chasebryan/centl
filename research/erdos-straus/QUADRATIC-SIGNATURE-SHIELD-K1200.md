# Full quadratic-signature shield through k = 1200

**Status:** exact finite theorem-certificate result; universal signature-shadow theorem remains open  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this does not prove universal Direct-Shadow Completeness, universal López Type A/B coverage, or the Erdős-Straus conjecture. López 2024 already contains the Type B quadratic-nonresidue fact; see [QUADRATIC-PRIOR-ART-NOTE.md](QUADRATIC-PRIOR-ART-NOTE.md).

This record continues:

- [DIRECT-SHADOW-K1200.md](DIRECT-SHADOW-K1200.md)
- [QUADRATIC-TRAP-SIGNATURE.md](QUADRATIC-TRAP-SIGNATURE.md)
- [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md)
- [QUADRATIC-SIGNATURE-QUOTIENT.md](QUADRATIC-SIGNATURE-QUOTIENT.md)

The purpose is to keep the **full vector of local Legendre signs** rather than collapsing every earlier modulus to the single Jacobi bit.

## 1. Exact local trap-signature quotient

For

\[
m_j=4j-1=\prod_{p\mid m_j}p^{a_p},
\]

let

\[
\chi_j(u)=\left(\left(\frac up\right)\right)_{p\mid m_j}
\]

be the complete local Legendre-sign vector.

If

\[
H_j=\operatorname{span}_{\mathbb F_2}
\{\chi_j(\ell):\ell\text{ prime},\ \ell\mid j\},
\]

then the exact theorem in [QUADRATIC-SIGNATURE-QUOTIENT.md](QUADRATIC-SIGNATURE-QUOTIENT.md) gives

\[
\boxed{
\chi_j(T_j)=\chi_j(-1)+H_j.
}
\]

The analyzer explicitly rechecked this identity against divisor enumeration at every layer in the finite range.

Through `k<=1200`, the quotient dimensions are:

```text
dim Q_j = 1: 845 layers
dim Q_j = 2: 293 layers
dim Q_j = 3:  58 layers
dim Q_j = 4:   4 layers
```

Thus `355/1200` layers already carry more local quadratic information than the Jacobi bit alone.

## 2. Candidatewise restriction

Fix one directly novel target candidate and write

\[
x\equiv r\pmod L,
\qquad
L=\operatorname{lcm}(840,4k-1).
\]

At odd primes dividing `L`, the Legendre signs are fixed by `r`. Every other odd prime appearing in an earlier modulus gives a free sign bit that can be selected by CRT.

For each earlier layer, intersect its trap-signature affine coset with the target's fixed signs.

The resulting unsafe set in the remaining free bits has one of four forms:

1. empty, so the layer is already quadratically safe;
2. full, so that layer is a **direct quadratic-signature obstruction**;
3. effective codimension one, giving one XOR safety equation;
4. effective codimension greater than one, giving a smaller affine forbidden subspace.

The full-signature shield asks whether all these earlier unsafe sets can be avoided simultaneously.

## 3. Exact k <= 1200 result

The frozen candidate bundle contains

\[
41,470
\]

directly novel hard-compatible candidates.

The ordinary Jacobi character shield certifies

```text
30,414 / 41,470 = 73.340%
```

of them independently of the stored sequential avoiding witness.

The full local quadratic-signature shield certifies

```text
30,786 / 41,470 = 74.237%
```

and therefore rescues an additional

\[
\boxed{372}
\]

candidates that the single Jacobi bit cannot certify.

The remaining

\[
\boxed{10,684}
\]

candidates each contain at least one **direct quadratic-signature obstruction**. This is only a coarse-character residual: all of these candidates still possess independently verified exact reduced avoiding progressions from the direct-shadow certificate bundle.

So the residual tells us precisely where quadratic signs cease to be fine enough and exact trap residues must take over.

## 4. The stronger finite collapse

The most striking result is not the extra 372 candidates.

Among every candidate with **no direct quadratic-signature obstruction**, the effective-codimension-one safety equations were consistent:

```text
collective codimension-one inconsistencies: 0
```

Then every higher-codimension unsafe affine set was tested against the codimension-one safety system.

The total was

\[
\boxed{1,566,322}
\]

higher-codimension signature constraints.

And the result was

\[
\boxed{1,566,322/1,566,322}
\]

were contained in the **violation hyperplane of one single codimension-one safety constraint**.

There were

```text
unshadowed higher signature constraints: 0
```

through the entire `k<=1200` candidate bundle.

Thus the full quadratic-signature system exhibited a direct-shadow collapse of its own:

\[
\boxed{
\text{higher-codimension quadratic obstruction}
\Longrightarrow
\text{already shadowed by one codimension-one quadratic obstruction}
}
\]

for every case tested.

This is a finite theorem-certificate statement, not yet a universal theorem.

## 5. Independent recomputation

A second implementation, [`verify_quadratic_signature_shield.py`](verify_quadratic_signature_shield.py), constructs every trap-signature set by **explicitly enumerating the divisors `e|j`** and evaluating the local signatures of `-e` and `-4e`.

It does not use the quotient-coset formula to construct those sets.

The independent recomputation reproduced exactly:

```text
Jacobi shield solved:               30,414
Jacobi residual:                    11,056
full signature shield solved:       30,786
direct signature residual:          10,684
rescued beyond Jacobi:                 372
collective codim-1 inconsistency:        0
higher-codim constraints:        1,566,322
single-shadowed higher constraints:1,566,322
unresolved signature systems:            0
```

The verifier never consults the stored integer or reduced avoiding witness when making the quadratic-signature decision.

## 6. Quadratic-Signature Direct-Shadow Completeness

The finite result suggests a new theorem target.

### QDSC candidate theorem

For a Type A/B target candidate, after fixing the local quadratic signs forced by the target CRT progression:

1. if no earlier layer is a direct quadratic-signature obstruction, then all effective-codimension-one safety equations are jointly consistent;
2. every higher-codimension trap-signature constraint is shadowed by one codimension-one earlier constraint.

If true universally, the full quadratic-signature avoidance problem would collapse to its codimension-one backbone.

That is:

\[
\boxed{
\text{no direct quadratic-signature obstruction}
\Longrightarrow
\text{simultaneous quadratic-signature shield exists}.
}
\]

This is the quadratic-signature analogue of the larger Direct-Shadow Completeness phenomenon.

## 7. Ancestry signal

Proof mining of the shadow sources shows a strong modulus-ancestry pattern. Typical repeated relations include

\[
11\mid187,
\qquad
31\mid403,
\qquad
11\mid451,
\qquad
47\mid611,
\]

corresponding to layer pairs such as

```text
3  -> 47
8  -> 101
3  -> 113
12 -> 153
```

with quotient congruent to `1 mod 4`, exactly the modulus-ancestry shape already present in the ordinary shadow graph.

A separate layer-only scan through `k<=3000` found that almost every higher-codimension quadratic trap-signature layer has a codimension-one modulus ancestor whose trap-signature coset contains its projected signature set. A very small exceptional list remains and is now a proof-mining target rather than evidence for a theorem.

The candidate universal theorem must therefore be proved from arithmetic, not inferred solely from the observed ancestry majority.

## 8. Why this enlarges the diamond

The exact-shadow problem now has another intermediate resolution scale:

\[
\boxed{
\begin{array}{c}
\text{exact Type A/B residues}\\
\downarrow\\
\text{local quadratic signature cosets}\\
\downarrow\\
\text{codimension-one quadratic backbone}\\
\downarrow\\
\text{direct quadratic residual core}\\
\downarrow\\
\text{exact residue geometry}
\end{array}
}
\]

The crucial observation is that collective complexity disappeared again at a coarser but nontrivial resolution: more than 1.5 million higher-codimension constraints added no new obstruction beyond one lower-codimension shadow in the tested range.

That repeated collapse is now one of the strongest clues toward the mechanism behind DSC-P.

## 9. Next attack

The immediate work is:

1. push the signature-shield analyzer into the automated `k<=1500` certificate workflow after the current run is frozen;
2. classify the `10,684` direct quadratic-signature residual candidates by the exact earlier layers causing the obstruction;
3. intersect those residual layers with the fiber shadow kernel;
4. prove a modulus-ancestry criterion for quadratic-signature shadowing;
5. attack the small exceptional higher-codimension layers that lack an obvious codimension-one signature ancestor;
6. determine whether exact trap residues always escape inside the direct quadratic residual unless an exact direct shadow already exists.

The last step is the bridge from QDSC back to universal DSC-P.
